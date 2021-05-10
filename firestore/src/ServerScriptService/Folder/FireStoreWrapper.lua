local serverScriptService = game:GetService('ServerScriptService')
local Promise = require(serverScriptService.OtherFolder.Promise)
local https = require(serverScriptService.http)
local fireStore = {}

fireStore.dataBaseLink = ''
fireStore.dataBaseIdToken = ''
fireStore.webApiKey = ''
fireStore.refreshToken = ''
fireStore.refreshTokenLink = 'https://securetoken.googleapis.com/v1/token'
fireStore.anonymousSignInLink = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp'

-- setting necessary things up
function fireStore:setDataBaseSecrets(
	dataBaseLink:string, dataBaseIdToken:string , fireBaseWebApiKey:string, refreshToken:string
	)
	self.dataBaseLink = dataBaseLink
	self.dataBaseIdToken = dataBaseIdToken
	self.webApiKey = fireBaseWebApiKey
	self.refreshToken = refreshToken
end

-- Create a request object
function fireStore:createRequest(endPoint:string, method:string)

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

-- grab the whole collection from DB
function fireStore:getFireStore(collectionPath:string)

local request = self:createRequest(self.dataBaseLink..collectionPath, 'GET')

	return Promise.new(function(resolve, reject)
		local response = https.request(request.Method, request.Url, {
			headers=request.Headers
		})

		if response.ok then
			local collection = response:json()
			resolve(collection)
		else
			reject(response.status_code, response.message)
		end
	end)
end

-- Get document

function fireStore:getDocument(documentPath:string)
	local request = self:createRequest(self.dataBaseLink..documentPath, 'GET')

	return Promise.new(function(resolve, reject)
		local response = https.request(request.Method, request.Url, {
			headers=request.Headers
		})

		if response.ok then
			resolve(response:json(response['Body']))
		else
			reject(response.status_code, response)
		end
	end)
end

-- create document. docname is optional and if left out firestore will create generate random id for the doc name
function fireStore:createDocument(documentCollectionId:string, updatedDocument, documentName:string)
	local request = self:createRequest(self.dataBaseLink..documentCollectionId, 'POST')

	return Promise.new(function(resolve, reject)
		local response = https.request(request.Method, request.Url, {
			headers=request.Headers, data=updatedDocument, query = documentName or nil
		})

		if response.ok then
			resolve(response.status_code)
		else
			reject(response.status_code, response.messsage)
		end
	end)
end

-- Delete document
function fireStore:deleteDocument(documentPath:string)

	local request = self:createRequest(self.dataBaseLink..documentPath, 'DELETE')

	return Promise.new(function(resolve, reject)
		local response = https.request(request.Method, request.Url, {
			headers = request.Headers
		})

		if response.ok then
			resolve(response.status_code)
		else
			reject(response.status_code, response)
		end
	end)
end

function fireStore:updateDocument(documentPath:string, query)
	local request = self:createRequest(self.dataBaseLink..documentPath, 'PATCH')

	return Promise.new(function(resolve, reject)
		local response = https.request(request.Method, request.Url, {
			headers=request.Headers, query = query or {}
		})
		if response.ok then
			resolve(response)
		else
			reject(response.status_code, response)
		end
	end)
end

function fireStore:updatedataBaseIdToken(updatedToken:string)
	self.dataBaseIdToken = updatedToken
	print('dataBaseAuthToken has been updated')
end

-- Sign in to FB Auth anonymously. result from request is idToken, refreshToken, token expiresIn
function fireStore:anonymousSignIn()

	local request = self:createRequest(self.anonymousSignInLink, 'POST')

	return Promise.new(function(resolve, reject)
		local response = https.request(request.Method, request.Url, {
			query={ key = self.webApiKey}
		})

		if response.ok then
			resolve(response:json(response['Body']))
		else
			reject(response.status_code, response.message)
		end
	end)
end

-- exchange refresh token to refresh id token when it expires
function fireStore:exchangeRefreshTokenForAnIdToken(refreshToken:string)

	local payload = {
		grant_type = "refresh_token",
		refresh_token = refreshToken
	}
	local requestHeader = { ['Content-Type'] = 'application/x-www-form-urlencoded' }
	local requestQuery = { key = self.webApiKey}

	return Promise.new(function(resolve, reject)
		local response = https.request('POST', self.refreshTokenLink, {
			data=payload, headers=requestHeader, query=requestQuery
		})

		if response.ok then
			local decodedResponse = response:json()
			local idToken = decodedResponse['id_token']
			self:updatedataBaseIdToken(idToken)
			resolve()
		else
			reject(response.status_code, response.message)
		end
	end)
end

return fireStore
