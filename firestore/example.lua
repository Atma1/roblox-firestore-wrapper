local serverScriptService = game:GetService('ServerScriptService')
local dataStoreService = game:GetService('DataStoreService')
local fireStore = require(serverScriptService.Folder.FireStoreWrapper)
local apiKeysAndLinks = dataStoreService:GetDataStore('apiKeysAndLinks')
local DB_Link, DB_Auth, DB_WebApiKey, DB_RefreshToken  = 
	apiKeysAndLinks:getAsync('dataBaseLink'), apiKeysAndLinks:getAsync('dataBaseAuthorizationToken'), apiKeysAndLinks:getAsync('webApiKey'), apiKeysAndLinks:getAsync('refreshToken')
local DB = ''

fireStore:setDataBaseSecrets(DB_Link, DB_Auth, DB_WebApiKey, DB_RefreshToken)

fireStore:getFireStore('peter/family')
	:andThen(function(doc)
		print('Succesfully retrive DB from FB')
		DB = doc
		print(DB)
	end)
	:catch(function(err)
		warn('Failed to retrive DB from FB ', err)
end)

fireStore:deleteDocument('peterGriffin/family')
	:andThen(function(doc)
		print('Succesfully deleted the document')
		DB = doc
		print(DB)
	end)
	:catch(function(err)
		warn('Failed to delete the document ', err)
end)