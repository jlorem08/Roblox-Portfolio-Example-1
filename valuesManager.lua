--!strict

--[[
	VALUES MANAGER:
	- Generates leaderstats folder (publicly displayed values) per player on join
	- Generates private values folder (non-publicly displayed values) per player on join
	- Apply save data to leaderstats and private values folders using DataManager module
]]

--------------
-- SERVICES --
--------------
local Players = game:GetService("Players")

-----------
-- TYPES --
-----------

---------------
-- CONSTANTS --
---------------
local PlayersManager = {}

local playerDatastoreName = "DevData00"

local modules = script.Parent
local dataManager = require(modules.DataManager)

---------------
-- VARIABLES --
---------------

---------------
-- FUNCTIONS --
---------------

-- Used to generate leaderstats values and private values for a given player, returns newly created folders
local function generateValues(player: Player): (Folder, Folder)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Points"
	cash.Value = 0
	cash.Parent = leaderstats

	local privateValues = Instance.new("Folder")
	privateValues.Name = "PrivateValues"
	privateValues.Parent = player

	local matchPoints = Instance.new("IntValue")
	matchPoints.Name = "MatchPoints"
	matchPoints.Value = 0
	matchPoints.Parent = privateValues

	return leaderstats, privateValues
end

-- Used to handle when player joins the game
local function onPlayerAdded(player: Player)
	print(
		`[{string.upper(script.Name)}]: {player.DisplayName} ({player.Name}, {tostring(player.UserId)}) joined the game.`
	)

	-- generate leaderstats and private value folders + values
	local leaderstats, privateValues = generateValues(player)

	dataManager.retrieveFolderData(playerDatastoreName, tostring(player.UserId), leaderstats)
	--dataManager.retrieveFolderData(playerDatastoreName, tostring(player.UserId), privateValues)
end

-- Used to handle when player leaves the game
local function onPlayerRemoving(player: Player)
	print(
		`[{string.upper(script.Name)}]: {player.DisplayName} ({player.Name} {tostring(player.UserId)}) left the game.`
	)

	local leaderstats = player:FindFirstChild("leaderstats") :: Folder
	local privateValues = player:FindFirstChild("PrivateValues") :: Folder

	if not leaderstats then
		warn(
			`[{string.upper(script.Name)}]: could not find folder leaderstats in player {player.DisplayName} ({player.Name}, {tostring(
				player.UserId
			)}).`
		)
	end

	if not privateValues then
		warn(
			`[{string.upper(script.Name)}]: could not find folder PrivateValues in player {player.DisplayName} ({player.Name}, {tostring(
				player.UserId
			)}).`
		)
	end

	dataManager.setFolderData(playerDatastoreName, tostring(player.UserId), leaderstats)
	--dataManager.setFolderData(playerDatastoreName, tostring(player.UserId), privateValues)
end

-- Used to connect events to functions
function PlayersManager.init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	return true
end

-- Used to start any automatic module logic post-initialization
function PlayersManager.start()
	return true
end

-------------
-- BINDING --
-------------

-------------
-- RUNNING --
-------------

-------------
-- CLOSING --
-------------
return PlayersManager
