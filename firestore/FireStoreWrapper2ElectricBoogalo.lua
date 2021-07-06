local serverScriptService = game:GetService('ServerScriptService')
local Promise = require(serverScriptService.fireStore.lib.Promise)
local https = require(serverScriptService.fireStore.lib.http)
local fireStore = {}
fireStore.__index = fireStore
local collection = {}
collection.__index = collection

function fireStore.new(dataBaseLink:string, dataBaseIdToken:string , fireBaseWebApiKey:string, refreshToken:string)
    local self = {}
    setmetatable(self, fireStore)
    self.dataBaseLink = dataBaseLink
    self.dataBaseIdToken = dataBaseIdToken
    self.fireBaseWebApiKey = fireBaseWebApiKey
    self.fireStoreAuthRefreshToken = refreshToken
    self.refreshTokenLink = 'https://securetoken.googleapis.com/v1/token'
    self.anonymousSignInLink = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp'
    return self
end

function fireStore:newRequestObject(endPoint:string, method:string)
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

function fireStore:updatedataBaseIdToken(updatedToken:string)
    self.dataBaseIdToken = updatedToken
    print('dataBaseAuthToken has been updated')
end

function fireStore:anonymousSignIn()

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

function fireStore:refreshIdToken(refreshToken:string)

	local payload = {
		grant_type = "refresh_token",
		refresh_token = refreshToken
	}
	local requestHeader = { ['Content-Type'] = 'application/x-www-form-urlencoded' }
	local requestQuery = { key = self.webApiKey}

	return Promise.new(function(resolve, reject)
		local response = https.request('POST', self.refreshTokenLink, {
			data=payload, headers=requestHeader, query=requestQuery,
		})

		if response.ok then
			resolve(response:json(response['Body']))
		else
			reject(response)
		end
	end)
end

function fireStore:Collection(collectionPath:string)
	local fireStoreCollection = {}
    setmetatable(fireStoreCollection, collection)
	fireStoreCollection.collectionPathUrl = collectionPath
    return collection
end

function collection:Request(method:string, url:string, searchQuery, requestBody)
	local request = fireStore:newRequestObject(self.collectionPathUrl..url, method)

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
	local request = fireStore:newRequestObject(self.collectionPathUrl, 'GET')
	return self:Request(request.Method)
end

function collection:getDocument(documentPath:string, mask:string)
	local request = fireStore:newRequestObject(self.collectionPathUrl..documentPath, 'GET')
	return self:Request(request.Method, documentPath, mask or {})
end

function collection:createDocument(document, documentName:string, mask:string)
	assert(document ~=nil, 'The document must not be empty.')

	local query = {
		documentName = documentName or nil,
		mask = mask or nil
	}
	local request = fireStore:createRequestObject(self.collectionPathUrl, 'POST')
	return self:Request(request.Method, request.Url, query, document)
end

function collection:deleteDocument(documentPath:string)
	local request = fireStore:createRequestObject(self.collectionPathUrl..documentPath, 'DELETE')
	return self:Request(request.Method, request.Url)
end

function collection:patchDocument(documentPath:string, updatedDoc, updateMask:string, docExist:boolean, mask:string)
	assert(updatedDoc ~=nil, 'The document must not be empty.')
	assert(updateMask ~= nil, 'Update mask must not be empty')
	assert(updateMask ~= nil, 'docExist must not be empty')
	local query = {
		mask = mask or nil,
		['updateMask.fieldPaths']=updateMask,
		['currentDocument.exists']=docExist or {}
	}
	local request = fireStore:createRequestObject(self.collectionPathUrl..documentPath, 'POST')
	return self:Request(request.Method, request.Url, query, updatedDoc)
end