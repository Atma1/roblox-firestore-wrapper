local serverScriptService = game:GetService('ServerScriptService')
local Promise = require(serverScriptService.Server.firestore.lib.Promise)
local https = require(serverScriptService.Server.firestore.lib.http)
local requestObject = require(serverScriptService.Server.firestore.lib.RequestObject)
local Firestore = {}
Firestore.__index = Firestore

function Firestore.new(dataBaseLink:string, dataBaseIdToken:string , firebaseWebApiKey:string, refreshToken:string)
    local self = {}
    self.dataBaseLink = dataBaseLink
	self.dataBaseIdToken = dataBaseIdToken
    self.firebaseWebApiKey = firebaseWebApiKey
    self.firestoreAuthRefreshToken = refreshToken
    self.refreshTokenLink = 'https://securetoken.googleapis.com/v1/token'
    self.anonymousSignInLink = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp'
    return setmetatable(self, Firestore)
end

function Firestore:updatedataBaseIdToken(updatedToken:string)
    self.dataBaseIdToken = updatedToken
    print('dataBaseAuthToken has been updated')
end

function Firestore:anonymousSignIn()

	local Request = requestObject.new(self.anonymousSignInLink, 'POST')

	return Promise.new(function(resolve, reject)
		local response = https.request(Request.Method, Request.Url, {
			query={ key=self.fireBaseWebApiKey }
		})

		if response.ok then
			resolve(response:json(response['Body']))
		else
			reject(response)
		end
	end)
end

function Firestore:refreshIdToken(refreshToken:string)
	local Request = requestObject.new(self.refreshTokenLink, 'POST')
	Request:setBody({
		grant_type = "refresh_token",
		refresh_token = refreshToken
	})
	Request:setHeaders({['Content-Type'] = 'application/x-www-form-urlencoded'})
	Request:setQuery({ key = self.firebaseWebApiKey })

	return Promise.new(function(resolve, reject)
		local response = https.request('POST', self.refreshTokenLink, {
			data=Request.Body, headers=Request.Headers, query=Request.Query,
		})

		if response.ok then
			resolve(response:json(response['Body']))
		else
			reject(response)
		end
	end)
end

function Firestore:getCollection(collectionPath:string)
	local Collection = Firestore.new(self.dataBaseLink, self.dataBaseIdToken, self.fireBaseWebApiKey, self.firestoreAuthRefreshToken)
	Collection.collectionPathUrl = Collection.dataBaseLink..collectionPath

	function Collection:request(method:string, url:string, queryParams, requestBody)
		local Request = requestObject.new(url, method)
		Request:setAuthorization('Bearer '..self.dataBaseIdToken)
		Request:setBody(requestBody or false)
		Request:setQuery(queryParams or false)

		return Promise.new(function(resolve, reject)
			local response = https.request(method, url, {
					headers=Request.Headers, data=Request.Body, query=Request.Query
			})
			if response.ok then
				resolve(response:json(response['Body']))
			else
				reject(response)
			end
		end)
	end

	function Collection:getAllDocuments()
		return self:request('GET', self.collectionPathUrl)
	end

	function Collection:getDocument(documentPath:string, mask)
		return self:request('GET', self.collectionPathUrl..documentPath, mask or {})
	end

	function Collection:createDocument(document, documentName:string, mask)
		assert(document ~=nil, 'The document must not be empty.')

		local query = {
			documentId = documentName or {},
			mask = mask or {}
		}
		return self:request('POST', self.collectionPathUrl, query, document)
	end

	function Collection:deleteDocument(documentPath:string)
		return self:request('DELETE', self.collectionPathUrl..documentPath)
	end

	function Collection:patchDocument(documentPath:string, updatedDoc, updateMask:string, docExist:boolean, mask)
		assert(updatedDoc ~=nil, 'The document must not be empty.')
		assert(updateMask ~= nil, 'Update mask must not be empty')
		assert(docExist ~= nil, 'docExist must not be empty')
		local query = {
			mask = mask or {},
			['updateMask.fieldPaths'] = updateMask,
			['currentDocument.exists'] = docExist or {}
		}
		return self:request('PATCH', self.collectionPathUrl..documentPath, query, updatedDoc)
	end
	return Collection
end
return Firestore