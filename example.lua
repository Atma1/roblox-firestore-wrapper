local serverScriptService = game:GetService('ServerScriptService')
local dataStoreService = game:GetService('DataStoreService')
local fireStore = require(serverScriptService.fireStore.FireStoreWrapper)
local apiKeysAndLinks = dataStoreService:GetDataStore('apiKeysAndLinks')
local DB_Link, DB_Auth, DB_WebApiKey, DB_RefreshToken  =
apiKeysAndLinks:getAsync('dataBaseLink'), apiKeysAndLinks:getAsync('dataBaseAuthorizationToken'), apiKeysAndLinks:getAsync('webApiKey'), apiKeysAndLinks:getAsync('refreshToken')

--[[

	Definition:

	dataBaseLink: It is firebase firestore database link
	databaseAuthToken: Also known as IdToken it is used to authenticate into the database. it NEEDS to be renewed every give or take 1 hour.
	It can be gained through many ways such as sign in using email.
	webApiKey: The webApikey is used for the request to renew dbauth or used for firebase auth related stuff
	refreshToken: Used to refresh the id token. It is gained when creating new user for firebaseauth using it's rest api as far as i know.

]]--

--[[

	@params {String} dataBaseLink
	@params {String} dataBaseAuthToken
	@params {String} dataBaseWebApiKey
	@params {String} refreshToken

]]--
fireStore:setDataBaseSecrets(DB_Link, DB_Auth, DB_WebApiKey, DB_RefreshToken)

--Every promise will be in its own thread there by if you want it to be in the same thread use the await statement
--Every request is a yielding function if in the same thread

--[[

	POST operation
	Exchange refresh token for a new idToken since every id token expires every 1 hour
	@params {String} dataBaseAuthToken
	@returns {String} id_token

]]

fireStore:exchangeRefreshTokenForAnIdToken(DB_RefreshToken)
	:andThen(function(responseBody)
		local newIdToken = responseBody['id_token']
		fireStore:updatedataBaseIdToken(newIdToken, 'apiKeysAndLinks', 'dataBaseAuthorizationToken')
	end)
	:catch(function(err)
		warn(err)
	end)

--GetCollection will return collection object NOT the entiriety of a collection and its documents
local peterChildColletion = fireStore:getColletion('peter/family/child/')


--[[

	Read operation.
	@params {String} Docpath. simply the document name
	@params {String} mask. OPTIONAL and if not included all the doc's field will be returned
	@returns {Dictionary} the requested document

]]--
peterChildColletion:getDocument('Meg'):await()
	:andThen(function(document)
		print(document)
	end)
	:catch(function(err)
		warn(err)
	end)

--In firestore the type of the fields MUST be specified
--eg. string is stringValue boolean is booleanValue etc

local stewieDocument = {
	['fields'] = {
		['age'] = {
			['integerValue'] = 1
		},
		['education'] = {
			['stringValue'] = 'N/A'
		}
	}
}

--[[
	POST Operation.
	@params {Dictionary} document. the document to be created
	@params {String} mask. OPTIONAL and if not included all the doc's field will be returned
	@returns {Dictionary} the created document with all of its specified fields

]]-- the first param is the document the second is the document name and is optional
local success, response = peterChildColletion:createDocument(stewieDocument, 'Stewie'):await()

if success then
	print(response)
else
	warn(response)
end

--[[
	DELETE operation
	@params {String} docPath. the document name.
	@returns Empty Table
]]--
peterChildColletion:deleteDocument('Meg')
	:catch(function(err)
		warn(err)
	end)

local updatedChrisDocument = {
	['fields'] = {
		['age'] = {
			['integerValue'] = 16
		}
	}
}
--[[
	PATCH operation

	@params {String} docPath. the documentPath or just the docName
	@params {Dictionary} updatedDoc. the updated document
	@params {String} fieldPath. the path to field of the document or just the name of the field
	@params {Boolean} docExist. Wether the doc is in the collection or not
	@params {String} Mask. the field of the doc to be returned. If not included Firestore will return all the doc's fields
	@returns {Dictionary} The updated Document

]]--
peterChildColletion:patchDocument('chris', updatedChrisDocument, 'age', true)
	:andThen(function(updatedDocument)
		print(updatedDocument)
	end)
	:catch(function(err)
		warn(err)
	end)