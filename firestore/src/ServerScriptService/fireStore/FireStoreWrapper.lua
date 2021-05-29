local serverScriptService = game:GetService('ServerScriptService')
local dataStoreService = game:GetService('DataStoreService')
local Promise = require(serverScriptService.fireStore.lib.Promise)
local https = require(serverScriptService.fireStore.lib.http)
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
function fireStore:createRequestObject(endPoint:string, method:string)

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

function fireStore:updatedataBaseIdToken(updatedToken:string, dataStoreName:string, dataStoreKey:string)

	local setDataStore = Promise.promisify(function(token, dsname, dskey)
		local ds = dataStoreService:GetDataStore(dsname)
		ds:setAsync(dskey, token)
		return token
	end)

	setDataStore(updatedToken, dataStoreName, dataStoreKey)
	:andThen(function(token)
		self.dataBaseIdToken = token
		print('dataBaseAuthToken has been updated')
	end)
	:catch(function(err)
		warn(err)
	end)
end

-- Sign in to FB Auth anonymously. result from request is idToken, refreshToken, token expiresIn
function fireStore:anonymousSignIn()

	local request = self:createRequestObject(self.anonymousSignInLink, 'POST')

	return Promise.new(function(resolve, reject)
		local response = https.request(request.Method, request.Url, {
			query={ key=self.webApiKey }
		})

		if response.ok then
			resolve(response:json(response['Body']))
		else
			reject(response.status_code, response.message)
		end
	end)
end

-- exchange refresh token to refresh id token. used when it expires
function fireStore:exchangeRefreshTokenForAnIdToken(refreshToken:string)

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
			local decodedResponse = response:json()
			resolve(decodedResponse)
		else
			reject(response)
		end
	end)
end

-- return a collection object from DB
function fireStore:getColletion(collectionPath:string)

	local url = self.dataBaseLink..collectionPath
	local collection = {}

		function collection:Request(method:string, docPath:string, requestBody, searchQuery:string)
			local request = fireStore:createRequestObject(url..docPath, method)
			
			return Promise.new(function(resolve, reject)
				local response = https.request(request.Method, request.Url, {
						headers=request.Headers, data=requestBody or {}, query=searchQuery or {}
				})
				if response.ok then
					resolve(response:json())
				else
					reject(response)
				end
			end)
		end


		-- Get document
		-- mask is the field of the doc to return. if not specified fireStore will return all doc's fields
		function collection:getDocument(documentPath:string, mask:string)
			local request = fireStore:createRequestObject(url..documentPath, 'GET')

			return Promise.new(function(resolve, reject)
				local response = https.request(request.Method, request.Url, {
					headers=request.Headers, query = mask or {}
				})

				if response.ok then
					resolve(response:json(response['Body']))
				else
					reject(response)
				end
			end)
		end

		-- create document. docname is optional and if left out fireStore will create generate random id for the doc name
		-- mask is the field of the doc to return. if not specified fireStore will return all doc's fields
		function collection:createDocument(documentInstance:Instance, documentName:string, mask:string)
			assert(documentInstance ~=nil, 'The document must not be empty.')

			local request = fireStore:createRequestObject(url, 'POST')

			return Promise.new(function(resolve, reject)
				local response = https.request(request.Method, request.Url, {
					headers=request.Headers, data=documentInstance, query = {
						documentId = documentName or {}, mask = mask or {}
					}
				})

				if response.ok then
					resolve(response:json())
				else
					reject(response)
				end
			end)
		end

		-- Delete document
		function collection:deleteDocument(documentPath:string)

			local request = fireStore:createRequestObject(url..documentPath, 'DELETE')

			return Promise.new(function(resolve, reject)
				local response = https.request(request.Method, request.Url, {
					headers = request.Headers
				})

				if response.ok then
					resolve(response.status_code)
				else
					reject(response)
				end
			end)
		end

		--updatemask is location of the field to be updated.
		function collection:patchDocument(documentPath:string, updatedDoc, updateMask:string, docExist:boolean, mask:string)
			assert(updateMask ~= nil, 'The update mask must not be empty.')
			assert(updatedDoc ~= nil, 'Updated doc must not be empty')

			local request = fireStore:createRequestObject(url..documentPath, 'PATCH')

			return Promise.new(function(resolve, reject)
				local response = https.request(request.Method, request.Url, {
					headers=request.Headers, data=updatedDoc, query ={
						['updateMask.fieldPaths']=updateMask, ['currentDocument.exists']=docExist or {},
						mask=mask or {}
					}
				})

				if response.ok then
					resolve(response:json())
				else
					reject(response)
				end
			end)
		end
	return collection
	end
return fireStore
