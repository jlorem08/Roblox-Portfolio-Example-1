--!strict

--[[
	ACTION MANAGER:
	- Manages stamina loss + restoration
	- Verifies stamina requirements on server
	- Manages sprinting
]]

--------------
-- SERVICES --
--------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-----------
-- TYPES --
-----------

---------------
-- CONSTANTS --
---------------
local ActionManager = {}

local remoteEvents = ReplicatedStorage.RemoteEvents
local sprintRemoteEvent = remoteEvents.SprintEvent

local sprintingSpeed = 25
local normalSpeed = 16

local staminaRestoredPerRefresh = 5 -- stamina restored every stamina check refresh
local staminaRefreshRate = 0.5 -- how often stamina checks are issued

local staminaRequiredToSprint = 7.5 -- stamina cost per stamina refresh

---------------
-- VARIABLES --
---------------

---------------
-- FUNCTIONS --
---------------

local function updatePlayerStaminaBar(player: Player, staminaAmt: number)
	local playerGui = player:FindFirstChild("PlayerGui") :: PlayerGui?
	if not playerGui then
		return
	end

	local staminaBarGui = playerGui:FindFirstChild("StaminaUI") :: ScreenGui?
	if not staminaBarGui then
		return
	end

	local mainFrame = staminaBarGui:FindFirstChild("MainFrame") :: Frame?
	if not mainFrame then
		return
	end

	local canvasGroupFrame = mainFrame:FindFirstChild("CanvasGroupFrame") :: Frame?
	if not canvasGroupFrame then
		return
	end

	local staminaBar = canvasGroupFrame:FindFirstChild("StaminaBar") :: Frame?
	if not staminaBar then
		return
	end

	staminaBar:TweenSize(
		UDim2.new(1, 0, staminaAmt / 100, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.5,
		true
	)
end

-- checks if the player is doing anything that takes up stamina, and if they aren't, gives them some stamina.
local function restoreStaminaLoop(player: Player)
	while true do
		task.wait(staminaRefreshRate)

		if player:GetAttribute("Stamina") <= 0 then
			local character = player.Character

			if not character then
				warn(
					`[{string.upper(script.Name)}]: Could not find Character for player {player.DisplayName} ({player.Name}, {tostring(
						player.UserId
					)}), so could not toggle sprinting.`
				)
				return
			end

			local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

			if not humanoid then
				warn(
					`[{string.upper(script.Name)}]: Could not find Humanoid for player {player.DisplayName} ({player.Name}, {tostring(
						player.UserId
					)}), so could not toggle sprinting.`
				)
				return
			end

			humanoid.WalkSpeed = normalSpeed
		end

		if player:GetAttribute("Sprinting") == true then
			local newStamina = math.max(player:GetAttribute("Stamina") - staminaRequiredToSprint, 0)

			player:SetAttribute("Stamina", newStamina)
			updatePlayerStaminaBar(player, newStamina)

			continue
		end

		if player:GetAttribute("Stamina") == 100 then -- make sure this is final check
			continue
		end

		local newStamina = math.min(player:GetAttribute("Stamina") + staminaRestoredPerRefresh, 100)

		player:SetAttribute("Stamina", newStamina)
		updatePlayerStaminaBar(player, newStamina)
	end
end

-- used when player joins, mainly to set attributes on player for action checks.
local function onPlayerAdded(player: Player)
	player:SetAttribute("Sprinting", false)
	player:SetAttribute("Stamina", 100)

	restoreStaminaLoop(player)
end

-- checks if player is able to sprint, and if so, lets them.
function ActionManager.sprint(player: Player, wantsToSprint: boolean)
	local sprinting = player:GetAttribute("Sprinting") :: boolean
	local stamina = player:GetAttribute("Stamina") :: number

	if wantsToSprint == sprinting then
		warn(
			`[{string.upper(script.Name)}]: Player attempting to set sprinting status to it's current status (suspicious behavior).`
		)
	end

	if (stamina < staminaRequiredToSprint) and wantsToSprint then
		return
	end

	player:SetAttribute("Sprinting", wantsToSprint)

	local character = player.Character

	if not character then
		warn(
			`[{string.upper(script.Name)}]: Could not find Character for player {player.DisplayName} ({player.Name}, {tostring(
				player.UserId
			)}), so could not toggle sprinting.`
		)
		return
	end

	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

	if not humanoid then
		warn(
			`[{string.upper(script.Name)}]: Could not find Humanoid for player {player.DisplayName} ({player.Name}, {tostring(
				player.UserId
			)}), so could not toggle sprinting.`
		)
		return
	end

	if wantsToSprint then
		humanoid.WalkSpeed = sprintingSpeed
	else
		humanoid.WalkSpeed = normalSpeed
	end
end

-- Used to connect events to functions
function ActionManager.init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	sprintRemoteEvent.OnServerEvent:Connect(ActionManager.sprint)

	return true
end

-- Used to start any automatic module logic post-initialization
function ActionManager.start()
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
return ActionManager
