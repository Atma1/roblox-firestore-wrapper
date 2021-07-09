local serverScriptService = game:GetService('ServerScriptService')
local Promise = require(serverScriptService.Server.firestore.lib.Promise)
local https = require(serverScriptService.Server.firestore.lib.http)
local requestObject = require(serverScriptService.Server.firestore.RequestObject)
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

	local Request = requestObject.new(self.anonymousSignInLink, 'POST', self.dataBaseIdToken)

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

	local data = {
		grant_type = "refresh_token",
		refresh_token = refreshToken
	}
	local requestHeader = { ['Content-Type'] = 'application/x-www-form-urlencoded' }
	local requestQuery = { key = self.webApiKey }

	return Promise.new(function(resolve, reject)
		local response = https.request('POST', self.refreshTokenLink, {
			data=data, headers=requestHeader, query=requestQuery,
		})

		if response.ok then
			resolve(response:json(response['Body']))
		else
			reject(response)
		end
	end)
end

function Firestore:getCollection(collectionPath:string)
	local collection = Firestore.new(self.dataBaseLink, self.dataBaseIdToken, self.fireBaseWebApiKey, self.firestoreAuthRefreshToken)
	collection.collectionPathUrl = collection.dataBaseLink..collectionPath

	function collection:request(method:string, url:string, queryParams, requestBody)
		local Request = requestObject.new(url, method, self.dataBaseIdToken)

		return Promise.new(function(resolve, reject)
			local response = https.request(method, url, {
					headers=Request.Headers, data=requestBody or {}, query=queryParams or {}
			})
			if response.ok then
				resolve(response:json(response['Body']))
			else
				reject(response)
			end
		end)
	end

	function collection:getAllDocuments()
		return self:request('GET', self.collectionPathUrl)
	end

	function collection:getDocument(documentPath:string, mask:string)
		return self:request('GET', self.collectionPathUrl..documentPath, mask or {})
	end

	function collection:createDocument(document, documentName:string, mask:string)
		assert(document ~=nil, 'The document must not be empty.')

		local query = {
			documentName = documentName or {},
			mask = mask or {}
		}
		return self:request('POST', self.collectionPathUrl, query, document)
	end

	function collection:deleteDocument(documentPath:string)
		return self:request('DELETE', self.collectionPathUrl..documentPath)
	end

	function collection:patchDocument(documentPath:string, updatedDoc:table, updateMask:string, docExist:boolean, mask:string)
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
	return collection
end
return Firestore