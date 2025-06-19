--!strict

--[[
	GAME MANAGER:
	- Uses modules to manage the game loop.
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
local GameManager = {}

local lobbyLength = 15

local modules = script.Parent

local roundManager = require(modules.RoundManager)
local musicManager = require(modules.MusicManager)
local timerManager = require(modules.TimerManager)

type gamemode = roundManager.gamemode

---------------
-- VARIABLES --
---------------

---------------
-- FUNCTIONS --
---------------

local function selectGamemode(): gamemode
	-- TODO: Add voting for gamemode
	return "Snowball Fight"
end

local function selectMap(): string
	-- TODO: Add voting for map
	return "Snowdyn"
end

-- start the game up
function GameManager.operate()
	while true do -- establish a game loop
		task.spawn(timerManager.startCountdown, lobbyLength, "Vote for a map!")
		task.spawn(musicManager.play, "Lobby", true, 5)

		task.wait(lobbyLength)

		roundManager.startRound(selectMap(), selectGamemode())
	end
end

-- Used to connect events to functions
function GameManager.init()
	return true
end

-- Used to start any automatic module logic post-initialization
function GameManager.start()
	task.spawn(GameManager.operate)

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
return GameManager
