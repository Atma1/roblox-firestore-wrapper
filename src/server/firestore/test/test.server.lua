local serverScriptService = game:GetService('ServerScriptService')
local dataStoreService = game:GetService('DataStoreService')
local Firestore = require(serverScriptService.Server.firestore.FireStoreWrapper2ElectricBoogalo)
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
local firestore = Firestore.new(DB_Link, DB_Auth, DB_WebApiKey, DB_RefreshToken)

-- --Every promise will be in its own thread there by if you want it to be in the same thread use the await statement
-- --Every request is a yielding function if in the same thread

-- --[[

-- 	POST operation
-- 	Exchange refresh token for a new idToken since every id token expires every 1 hour
-- 	@params {String} dataBaseAuthToken
-- 	@returns {String} id_token

-- ]]

-- firestore:refreshIdToken(DB_RefreshToken)
-- 	:andThen(function(responseBody)
-- 		local newIdToken = responseBody['id_token']
-- 		apiKeysAndLinks:SetAsync('dataBaseAuthorizationToken', newIdToken)
-- 		firestore:updatedataBaseIdToken(newIdToken)
-- 		local bar = apiKeysAndLinks:getAsync('dataBaseAuthorizationToken')
-- 		local foo = newIdToken
-- 		if foo == bar then
-- 			print('same')
-- 		else
-- 			print('not smae')
-- 		end
-- 	end)
-- 	:catch(function(err)
-- 		warn(err)
-- 	end)

-- --GetCollection will return collection object NOT the entiriety of a collection and its documents
local peterChildColletion = firestore:getCollection('peter/family/child/')


-- -- -- --[[

-- -- -- 	Read operation.
-- -- -- 	@params {String} Docpath. simply the document name
-- -- -- 	@params {String} mask. OPTIONAL and if not included all the doc's field will be returned
-- -- -- 	@returns {Dictionary} the requested document

-- -- -- ]]--
-- peterChildColletion:getAllDocuments()
-- 	:andThen(function(documents)
-- 		print(documents)
-- 	end)
-- 	:catch(function(err)
-- 		warn(err)
-- 	end)

-- --In firestore the type of the fields MUST be specified
-- --eg. string is stringValue boolean is booleanValue etc

-- local brianDocument = {
-- 	['fields'] = {
-- 		['age'] = {
-- 			['integerValue'] = 8
-- 		},
-- 		['education'] = {
-- 			['stringValue'] = 'N/A'
-- 		}
-- 	}
-- }

-- --[[
-- 	POST Operation.
-- 	@params {Dictionary} document. the document to be created
--	@params {String} documentName. OPTIONAL the name of the doucment. if not included firestore will generate random id as the document name
-- 	@params {String} mask. OPTIONAL and if not included all the doc's field will be returned
-- 	@returns {Dictionary} the created document with all of its specified fields

-- ]]-- the first param is the document the second is the document name and is optional
-- local success, response = peterChildColletion:createDocument(brianDocument, 'Brian'):await()

-- if success then
-- 	print(response)
-- else
-- 	warn(response)
-- end

-- --[[
-- 	DELETE operation
-- 	@params {String} docPath. the document name.
-- 	@returns Empty Table
-- ]]--
peterChildColletion:deleteDocument('FeHMsDxq1ShOamLJ3FuY')
	:catch(function(err)
		warn(err)
	end)

-- local updatedChrisDocument = {
-- 	['fields'] = {
-- 		['age'] = {
-- 			['integerValue'] = 17
-- 		}
-- 	}
-- }
-- --[[
-- 	PATCH operation

-- 	@params {String} docPath. the documentPath or just the docName
-- 	@params {Dictionary} updatedDoc. the updated document
-- 	@params {String} fieldPath. the path to field of the document or just the name of the field
-- 	@params {Boolean} docExist. Wether the doc is in the collection or not. if False firestore will generate a new document
-- 	@params {String} Mask. OPTIONAL the field of the doc to be returned. If not included Firestore will return all the doc's fields
-- 	@returns {Dictionary} The updated Document

-- ]]--
-- peterChildColletion:patchDocument('chris', updatedChrisDocument, 'age', true)
-- 	:andThen(function(updatedDocument)
-- 		print(updatedDocument)
-- 	end)
-- 	:catch(function(err)
-- 		warn(err)
-- 	end)