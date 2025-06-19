--!strict

--[[
	ROUND MANAGER:
	- Manages the starting of matches
]]

--------------
-- SERVICES --
--------------
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

-----------
-- TYPES --
-----------
export type gamemode = "Snowball Fight"

---------------
-- CONSTANTS --
---------------
local RoundManager = {}

local modules = script.Parent

local timerManager = require(modules.TimerManager)
local musicManager = require(modules.MusicManager)
local toolManager = require(modules.ToolManager)

local gameLength = 150

local maps = ServerStorage.Maps
local tools = ServerStorage.Tools

local toolsPerMode = { -- index is mode, value is array of tools for that mode
	["Snowball Fight"] = {
		tools.Snowball,
	},
} :: { [gamemode]: { Tool } }

local gameDescriptions = {
	["Snowball Fight"] = "Throw snowballs at others!",
} :: { [gamemode]: string }

local sfx = SoundService.SFX
local whistleBlow = sfx.Whistle

local lobby = workspace.Lobby
local lobbySpawns = lobby.Spawns

---------------
-- VARIABLES --
---------------

---------------
-- FUNCTIONS --
---------------

-- update the match leaderboard for a player based on matchpoints
local function updateMatchLeaderboard(player: Player)
	repeat
		task.wait(1)
	until player:FindFirstChild("PlayerGui") ~= nil

	local playerGui = player:FindFirstChild("PlayerGui") :: PlayerGui?
	if not playerGui then
		return
	end

	repeat
		task.wait(1)
	until playerGui:FindFirstChild("MatchLeaderboard") ~= nil

	local matchLeaderboard = playerGui:FindFirstChild("MatchLeaderboard") :: ScreenGui?
	if not matchLeaderboard then
		print("err")
		return
	end

	local mainFrame = matchLeaderboard:FindFirstChild("MainFrame") :: Frame?
	if not mainFrame then
		return
	end

	local firstPlaceFrame = mainFrame:FindFirstChild("FirstPlace") :: Frame?
	local secondPlaceFrame = mainFrame:FindFirstChild("SecondPlace") :: Frame?
	local thirdPlaceFrame = mainFrame:FindFirstChild("ThirdPlace") :: Frame?

	if not firstPlaceFrame or not secondPlaceFrame or not thirdPlaceFrame then
		return
	end

	local firstPlaceNameLabel = firstPlaceFrame:FindFirstChild("NameLabel") :: TextLabel?
	local secondPlaceNameLabel = secondPlaceFrame:FindFirstChild("NameLabel") :: TextLabel?
	local thirdPlaceNameLabel = thirdPlaceFrame:FindFirstChild("NameLabel") :: TextLabel?

	local firstPlacePointsLabel = firstPlaceFrame:FindFirstChild("PointsLabel") :: TextLabel?
	local secondPlacePointsLabel = secondPlaceFrame:FindFirstChild("PointsLabel") :: TextLabel?
	local thirdPlacePointsLabel = thirdPlaceFrame:FindFirstChild("PointsLabel") :: TextLabel?

	local firstPlacePicture = firstPlaceFrame:FindFirstChild("ProfilePicture") :: ImageLabel?
	local secondPlacePicture = secondPlaceFrame:FindFirstChild("ProfilePicture") :: ImageLabel?
	local thirdPlacePicture = thirdPlaceFrame:FindFirstChild("ProfilePicture") :: ImageLabel?

	if
		not (
			firstPlaceNameLabel
			and secondPlaceNameLabel
			and thirdPlaceNameLabel
			and firstPlacePointsLabel
			and secondPlacePointsLabel
			and thirdPlacePointsLabel
			and firstPlacePicture
			and secondPlacePicture
			and thirdPlacePicture
		)
	then
		return
	end

	local slots = {
		{
			frame = firstPlaceFrame,
			nameLabel = firstPlaceNameLabel,
			pointsLabel = firstPlacePointsLabel,
			picture = firstPlacePicture,
		},
		{
			frame = secondPlaceFrame,
			nameLabel = secondPlaceNameLabel,
			pointsLabel = secondPlacePointsLabel,
			picture = secondPlacePicture,
		},
		{
			frame = thirdPlaceFrame,
			nameLabel = thirdPlaceNameLabel,
			pointsLabel = thirdPlacePointsLabel,
			picture = thirdPlacePicture,
		},
	}

	while true do
		local allPlayerPoints = {} :: { { player: Player, points: number } }

		for _, playerSearching: Player in ipairs(Players:GetPlayers()) do
			local hiddenValues = playerSearching:FindFirstChild("PrivateValues") :: Folder?
			if not hiddenValues then
				continue
			end

			local matchPoints = hiddenValues:FindFirstChild("MatchPoints") :: IntValue?
			if not matchPoints then
				continue
			end

			table.insert(allPlayerPoints, {
				player = playerSearching,
				points = matchPoints.Value,
			})
		end

		table.sort(allPlayerPoints, function(a, b)
			return a.points > b.points
		end)

		for i = 1, 3 do
			local slot = slots[i]
			local data = allPlayerPoints[i]

			if data then
				local player = data.player
				local points = data.points

				slot.nameLabel.Text = player.DisplayName
				slot.pointsLabel.Text = string.format("%d pts", points)

				local success, thumbUrl = pcall(function()
					return Players:GetUserThumbnailAsync(
						player.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size150x150
					)
				end)

				if success then
					slot.picture.Image = thumbUrl
				else
					slot.picture.Image = ""
				end
			else
				slot.nameLabel.Text = "Nobody"
				slot.pointsLabel.Text = ""
				slot.picture.Image = ""
			end
		end

		task.wait(2)
	end
end

-- used to load all players
local function resetAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		player:LoadCharacter()
	end
end

-- used to set each players match points to 0 & disable match leaderboard
local function setMatchPointsZero()
	for _, player: Player in ipairs(Players:GetPlayers()) do
		local values = player:FindFirstChild("PrivateValues") :: Folder?
		if not values then
			continue
		end

		local matchPoints = values:FindFirstChild("MatchPoints") :: IntValue?
		if not matchPoints then
			continue
		end

		matchPoints.Value = 0

		local playerGui = player:FindFirstChild("PlayerGui") :: PlayerGui?
		if not playerGui then
			continue
		end

		local matchLeaderboard = playerGui:FindFirstChild("MatchLeaderboard") :: ScreenGui?
		if not matchLeaderboard then
			continue
		end

		local mainFrame = matchLeaderboard:FindFirstChild("MainFrame") :: Frame?
		if not mainFrame then
			continue
		end

		mainFrame.Visible = false
	end
end

local function enableMatchLeaderboard()
	for _, player: Player in ipairs(Players:GetPlayers()) do
		local playerGui = player:FindFirstChild("PlayerGui") :: PlayerGui?
		if not playerGui then
			continue
		end

		local matchLeaderboard = playerGui:FindFirstChild("MatchLeaderboard") :: ScreenGui?
		if not matchLeaderboard then
			continue
		end

		local mainFrame = matchLeaderboard:FindFirstChild("MainFrame") :: Frame?
		if not mainFrame then
			continue
		end

		mainFrame.Visible = true
	end
end

local function flyMatchBanner(mapName: string, gameMode: gamemode)
	task.spawn(task.wait, 1)

	for _, player: Player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			local playerGui = player:FindFirstChild("PlayerGui") :: PlayerGui?
			if not playerGui then
				return
			end

			local matchBanner = playerGui:FindFirstChild("MatchTitle") :: ScreenGui
			if not matchBanner then
				return
			end

			local mainFrame = matchBanner:FindFirstChild("MainFrame") :: Frame
			if not mainFrame then
				return
			end

			local gameDescriptionLabel = mainFrame:FindFirstChild("GameDescriptionLabel") :: TextLabel
			if not gameDescriptionLabel then
				return
			end

			local gameTitleLabel = mainFrame:FindFirstChild("GameTitleLabel") :: TextLabel
			if not gameTitleLabel then
				return
			end

			gameTitleLabel.Text = mapName .. " | " .. gameMode
			gameDescriptionLabel.Text = gameDescriptions[gameMode]

			mainFrame:TweenPosition(UDim2.new(0, 0, 0.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 1, true)

			task.wait(1.75)

			mainFrame:TweenPosition(UDim2.new(0, 0, 1.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 1, true)

			task.wait(2)

			mainFrame.Position = UDim2.new(0, 0, -0.5, 0)
		end)
	end
end

-- used to start a new round on a map (given its name) and with special game rules (given the gamemode)
function RoundManager.startRound(mapName: string, gameMode: gamemode)
	local map = maps:FindFirstChild(mapName)

	if not map then
		warn(`[{string.upper(script.Name)}]: Could not find map with name {mapName}.`)
		return
	end

	whistleBlow:Play()
	flyMatchBanner(mapName, gameMode)
	enableMatchLeaderboard()

	task.spawn(musicManager.stop, "Lobby", true, 2)
	task.spawn(musicManager.play, mapName, true, 5)

	task.spawn(timerManager.startCountdown, gameLength, mapName .. "<br />" .. gameMode)

	-- start loading map
	local clonedMap = map:Clone()
	clonedMap.Parent = workspace

	-- disable lobby spawns
	for _, spawnLocation: SpawnLocation in ipairs(lobbySpawns:GetChildren() :: { SpawnLocation }) do
		spawnLocation.Enabled = false
	end

	-- enable new map spawns
	for _, spawnLocation: SpawnLocation in ipairs(clonedMap:FindFirstChild("Spawns"):GetChildren() :: { SpawnLocation }) do
		spawnLocation.Enabled = true
	end

	-- reset all players
	resetAllPlayers()

	-- give all players proper tools
	local toolsToGive = toolsPerMode[gameMode]

	for _, tool: Tool in ipairs(toolsToGive) do
		toolManager.add(tool)
	end

	task.wait(gameLength)

	whistleBlow:Play()

	-- re-enable lobby spawns
	for _, spawnLocation: SpawnLocation in ipairs(lobbySpawns:GetChildren() :: { SpawnLocation }) do
		spawnLocation.Enabled = true
	end

	for _, spawnLocation: SpawnLocation in ipairs(clonedMap:FindFirstChild("Spawns"):GetChildren() :: { SpawnLocation }) do
		spawnLocation.Enabled = false
	end

	toolManager.remove(tools.Snowball)

	task.spawn(musicManager.stop, mapName, true, 2)

	-- send players back to lobby, clean up map
	clonedMap:Destroy()
	resetAllPlayers()
	setMatchPointsZero()
end

-- Used to connect events to functions
function RoundManager.init(): boolean
	return true
end

-- Used to start any automatic module logic post-initialization
function RoundManager.start(): boolean
	for _, player in ipairs(Players:GetPlayers()) do
		updateMatchLeaderboard(player)
	end

	Players.PlayerAdded:Connect(updateMatchLeaderboard)

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
return RoundManager
