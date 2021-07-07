local serverScriptService = game:GetService('ServerScriptService')
local Promise = require(serverScriptService.fireStore.lib.Promise)
local https = require(serverScriptService.fireStore.lib.http)
local firestore = {}
firestore.__index = firestore
local collection = {}
collection.__index = collection

function firestore.new(dataBaseLink:string, dataBaseIdToken:string , fireBaseWebApiKey:string, refreshToken:string)
    local self = {}
	self.dataBaseLink = dataBaseLink
    self.dataBaseIdToken = dataBaseIdToken
    self.fireBaseWebApiKey = fireBaseWebApiKey
    self.fireStoreAuthRefreshToken = refreshToken
    self.refreshTokenLink = 'https://securetoken.googleapis.com/v1/token'
    self.anonymousSignInLink = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp'
    return setmetatable(self, firestore)
end

function firestore:newRequestObject(endPoint:string, method:string)
    local request = {
		Url = endPoint,
		Method = method,
		Headers = {
			['Content-Type'] = 'application/json',
			['Authorization'] = 'Bearer '..self.dataBaseIdToken
		},
	}
	return request
end

function firestore:updatedataBaseIdToken(updatedToken:string)
    self.dataBaseIdToken = updatedToken
    print('dataBaseAuthToken has been updated')
end

function firestore:anonymousSignIn()

	local request = self:newRequestObject(self.anonymousSignInLink, 'POST')

	return Promise.new(function(resolve, reject)
		local response = https.request(request.Method, request.Url, {
			query={ key=self.fireBaseWebApiKey }
		})

		if response.ok then
			resolve(response:json(response['Body']))
		else
			reject(response)
		end
	end)
end

function firestore:refreshIdToken(refreshToken:string)

	local data = {
		grant_type = "refresh_token",
		refresh_token = refreshToken
	}
	local requestHeader = { ['Content-Type'] = 'application/x-www-form-urlencoded' }
	local requestQuery = { key = self.webApiKey}

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

function firestore:Collection(collectionPath:string)
	local fireStoreCollection = {}
	fireStoreCollection.collectionPathUrl = collectionPath
    return setmetatable(fireStoreCollection, collection)
end

function collection:request(method:string, url:string, searchQuery:table, requestBody:table)
	local request = firestore:newRequestObject(url, method)

	return Promise.new(function(resolve, reject)
		local response = https.request(request.Method, request.Url, {
				headers=request.Headers, data=requestBody or {}, query=searchQuery or {}
		})
		if response.ok then
			resolve(response:json(response))
		else
			reject(response)
		end
	end)
end

function collection:getAllDocuments()
	local request = firestore:newRequestObject(self.collectionPathUrl, 'GET')
	return self:request(request.Method)
end

function collection:getDocument(documentPath:string, mask:string)
	local request = firestore:newRequestObject(self.collectionPathUrl..documentPath, 'GET')
	return self:request(request.Method, request.Url, mask or {})
end

function collection:createDocument(document:table, documentName:string, mask:string)
	assert(document ~=nil, 'The document must not be empty.')

	local query = {
		documentName = documentName or {},
		mask = mask or {}
	}
	local request = firestore:createRequestObject(self.collectionPathUrl, 'POST')
	return self:request(request.Method, request.Url, query, document)
end

function collection:deleteDocument(documentPath:string)
	local request = firestore:createRequestObject(self.collectionPathUrl..documentPath, 'DELETE')
	return self:request(request.Method, request.Url)
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
	local request = firestore:createRequestObject(self.collectionPathUrl..documentPath, 'POST')
	return self:request(request.Method, request.Url, query, updatedDoc)
end