local HTTPS = game:GetService('HttpService')
local promiseService = require(script.Parent.Parent.poop.Promise)

local fireStore = {}

fireStore.dataBaseLink = ''
fireStore.dataBaseAuthorizationToken = ''
fireStore.webApiKey = ''
fireStore.refreshToken = ''
fireStore.refreshTokenLink = 'https://securetoken.googleapis.com/v1/token?key='
fireStore.anonymousSignInLink = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key='

-- grab the whole collection from DB
function fireStore:getFireStore(docPath:string)

local request = self:createRequest(self.dataBaseLink..docPath, 'GET')

return promiseService.new(function(resolve, reject)
		local response = HTTPS:RequestAsync(request)
		if response.Success then
			local snap = HTTPS:JSONDecode(response.Body)
			local doc = snap['documents']
			resolve(doc)
		else
			reject(response)
		end
	end)
end

-- Init the FB by grabbing the whole collection
function fireStore:init()

	local request = self:createRequest(self.dataBaseLink, 'GET')

	self.getFireStore(request)
		:andThen(function(doc)
			print('Succesfully retrive DB from FB')
			return(doc)
		end)
		:catch(function(err)
			return warn('Failed to retrive DB from FB', err)
	end)
end

-- Update the old DB retrieved from FB to the new one
function fireStore:updateDB()

	local request = self:createRequest(self.dataBaseLink, 'GET')

	self.getFireStore(request)
		:andThen(function(doc)
			print('Succesfully updated the DB')
			return(doc)
		end)
		:catch(function(err)
			return warn('Failed to update DB '..err)
	end)
end

-- Create a request object
function fireStore:createRequest(endPoint:string, method:string)

	local request = {
		Url = endPoint,
		Method = method,
		Headers = {
			['Content-Type'] = 'application/json',
			['Authorization'] = 'Bearer '..self.dataBaseAuthorizationToken
		},
	}
	return request
end

-- Delete document
function fireStore:deleteDocument(documentPath:string)

	local request = self:createRequest(documentPath, 'DELETE')

	return promiseService.new(function(resolve, reject)
		local response = HTTPS:RequestAsync(request)
		if response.Success then
			resolve('Doc deleted')
		else
			reject(response)
		end
	end)
end

-- Sign in to FB Auth anonymously. result from request is idToken, refreshToken, token expiresIn
function fireStore:anonymousSignIn()

	local request = self:createRequest(self.anonymousSignInLink..self.webApiKey, 'POST')

	return promiseService.new(function(resolve, reject)
		local response = HTTPS:RequestAsync(request)
		if response.Success then
			resolve(HTTPS:JSONDecode(response['Body']))
		else
			reject(response.error)
		end
	end)
end

-- exchange refresh token to refresh id token when it expires
function fireStore:exchangeRefreshTokenForAnIdToken(refreshToken:string)

	local request = self:createRequest(self.refreshTokenLink..self.webApiKey, 'POST')

	local requestHeader = request['Headers']
	requestHeader['Content-Type'] = 'application/x-www-form-urlencoded'
	request['Body'] = {
		['grant_type'] = 'refresh_token',
		['refresh_token'] = refreshToken,
	}

	return promiseService.new(function(resolve, reject)
		local response = HTTPS:RequestAsync(request)
		if response.Success then
			local encodedResponse = HTTPS:JSONDecode(response['Body'])
			local refreshedIdToken = encodedResponse['id_token']
			resolve(refreshedIdToken)
		else
			reject(response)
		end
	end)
end

-- setting necessary things up
function fireStore:setDataBaseSecrets(
	dataBaseLink:string, dataBaseAuthorizationToken:string , fireStoreWebApiKey:string, refreshToken:string
	)
	self.dataBaseLink = dataBaseLink
	self.dataBaseAuthorizationToken = dataBaseAuthorizationToken
	self.webApiKey = fireStoreWebApiKey
	self.refreshToken = refreshToken
end

return fireStore
