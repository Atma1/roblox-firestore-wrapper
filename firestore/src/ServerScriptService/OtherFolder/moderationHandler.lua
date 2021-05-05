local strngVal = 'stringValue'
local serverScriptService = game:GetService('ServerScriptService')
local webHookHandler = require(serverScriptService.OtherFolder.webHookHandler)
local banHandler = {}

function banHandler:isPlayerBanned(player, DB)
	assert(DB ~= nil, 'Error #1. Expected DB but is empty instead')

local playerID = player.UserId
	for _, docNumber in pairs(DB) do
		if string.match(docNumber['name'], playerID) then
			local fields = docNumber['fields']
			local banReason = fields['banReason'][strngVal]
			local bannedBy = fields['bannedBy'][strngVal]
			player:Kick('\n Unfortunately, it has come to my attention that you are banned.\nReason: '..banReason..'.\nBanned by: '..bannedBy..'.\nAd astra.')
			local banMessage = webHookHandler:createEmbededBanMessage(player, 'while attempting to join the game')
			webHookHandler:sendToWebHook(banMessage, 'POST')
				:catch(function(error)
					warn(error)
				end)
			break
		end
	end
end

function banHandler:arePlayersInGameBanned(players, DB)
	assert(DB ~= nil, 'Error #2. Expected DB but is empty instead')

for _, documents in pairs(DB) do
	for _, player in pairs(players) do
		if string.match(documents['name'], player.UserId) then
			local fields = documents['fields']
			local banreason = fields['banReason'][strngVal]
			local bannedby = fields['bannedBy'][strngVal]
			player:Kick('\n Ban, is that what you want? It is yours my friend.\nReason: '..banreason..'.\nBanned by: '..bannedby..'.')
			local banMessage = webHookHandler:createEmbededBanMessage(player, 'while in game')
			webHookHandler:sendToWebHook(banMessage, 'POST')
			:catch(function(error)
					warn(error)
				end)
			end
		end
	end
end

return banHandler
--[[
			print(y)
			if string.match(docNumber['name'], playerID) then

			end
			return false
--]]
