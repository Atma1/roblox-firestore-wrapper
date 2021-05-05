local serverScriptService = game:GetService('ServerScriptService')
-- local playerService = game:GetService('Players')
local dataStoreService = game:GetService('DataStoreService')
local fireStore = require(serverScriptService.Folder.FireStoreWrapper)
-- local moderationModule = require(serverScriptService.poop.moderationHandler)
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

fireStore:deleteDocument('peter/family')
	:andThen(function(doc)
		print('Succesfully deleted the document')
		DB = doc
		print(DB)
	end)
	:catch(function(err)
		warn('Failed to delete the document ', err)
end)






--playerService.PlayerAdded:Connect(function(player)
--	banModule:isPlayerBanned(player, DB)
--end)

--local autoUpdateDB = coroutine.wrap(function()
--	while true do
--		wait(60)
--		print('Attempting to update.')
--		local success, err = pcall(function()
--			DB = fireStore:updateDB()
--		end)
--		if success then
--			local playersinGame = playerService:GetPlayers()
--			banModule:arePlayersInGameBanned(playersinGame, DB)
--			print('Database was updated.')
--			return
--		elseif err then
--			print('Database faled to update.', err)
--			return
--		end
--	end
--end)
--autoUpdateDB()

--[[	print('Status code: '..response['StatusCode']'.')

local data = {}
for i = 1, 1000 do
	data[i] = i
end
wait(60)
local start = tick()
for i, v in pairs(data) do
	print(i..':'..v)
end
local finish = (tick()-start)
print('finished at'..finish)

function getFireStore()
	local attempts = 0
	local snap
	local doc
		
	local success, err = pcall(function()
		local response = HTTPS:RequestAsync(request)
		print('Status code: '..response['StatusCode']..'.')
		if response['Body'] == '' or response['Success'] == false then
			repeat
				print("Retrying GetAsync request. Attempt " .. tostring(attempts+1) .."/3")
				attempts += 1
				response = HTTPS:RequestAsync(request)
			until attempts >= 3 or (response['Body'] ~= '' and response['Success'] ~= false)
		else
			snap = HTTPS:JSONDecode(response.Body)
			doc = snap['documents']
		end		
	end)
	if err then
		print(err)
		return
	end
	print(success)
	return doc or nil
end
--]]
