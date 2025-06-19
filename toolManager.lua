--!strict

--[[
	TOOL MANAGER:
	- Allows you to manage distribution of tools
	- Gives tools to players when they join game late
	- Allows you to clear every tool
	- Allows you to remove specific tools
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
local ToolManager = {}

local toolModules = { -- name of tool and reference to its required module (should be inside toolmanager module)
	["Snowball"] = require(script.SnowballManager),
} :: { [string]: { ["fire"]: (player: Player, character: Model, tool: Tool) -> () } }

local remoteEvents = ReplicatedStorage.RemoteEvents

local activateSnowTargetEvent = remoteEvents.ActivateSnowTarget
local deactivateSnowTargetEvent = remoteEvents.DeactivateSnowTarget

local equippedRemotes = {
	["Snowball"] = activateSnowTargetEvent,
} :: { [string]: RemoteEvent }

local unequippedRemotes = {
	["Snowball"] = deactivateSnowTargetEvent,
} :: { [string]: RemoteEvent }

---------------
-- VARIABLES --
---------------
local currentTools = {} :: { Tool } -- Tools that should be handed out to players

---------------
-- FUNCTIONS --
---------------

local function onToolActivated(tool: Tool)
	local character = tool.Parent :: Model?
	if not character then
		return
	end

	local player = Players:GetPlayerFromCharacter(character) :: Player?
	if not player then
		return
	end

	local backpack = player:FindFirstChild("Backpack") :: Folder?
	if not backpack then
		return
	end

	local foundModule = toolModules[tool.Name]
	if not foundModule then
		return
	end

	foundModule.fire(player, character, tool)

	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChild("Animator") :: Animator?
	if not animator then
		return
	end

	local activationAnimation = tool:FindFirstChild("ActivationAnim") :: Animation?
	if not activationAnimation then
		return
	end

	local equippedAnimation = tool:FindFirstChild("EquipAnimation") :: Animation?
	if not equippedAnimation then
		return
	end

	local playingTracks = animator:GetPlayingAnimationTracks()

	for _, animationTrack: AnimationTrack in ipairs(playingTracks) do
		if animationTrack.Animation ~= equippedAnimation then
			continue
		end

		animationTrack:Stop()

		break
	end

	local activationAnimationTrack = animator:LoadAnimation(activationAnimation)
	activationAnimationTrack:Play()

	--task.wait(activationAnimationTrack.Length)

	tool.Parent = backpack
end

local function onToolEquipped(tool: Tool)
	local character = tool.Parent :: Model?
	if not character then
		return
	end

	local player = Players:GetPlayerFromCharacter(character) :: Player?
	if not player then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChild("Animator") :: Animator?
	if not animator then
		return
	end

	local equippedAnimation = tool:FindFirstChild("EquipAnimation") :: Animation?
	if not equippedAnimation then
		return
	end

	local equippedAnimationTrack = animator:LoadAnimation(equippedAnimation)
	equippedAnimationTrack:Play()

	if equippedRemotes[tool.Name] then
		equippedRemotes[tool.Name]:FireClient(player)
	end
end

local function onToolUnequipped(tool: Tool)
	local backpack = tool.Parent :: Folder?
	if not backpack then
		return
	end

	local player = backpack.Parent :: Player?
	if not player then
		return
	end

	local character = player.Character :: Model?
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChild("Animator") :: Animator?
	if not animator then
		return
	end

	local equippedAnimation = tool:FindFirstChild("EquipAnimation") :: Animation?
	if not equippedAnimation then
		return
	end

	local playingTracks = animator:GetPlayingAnimationTracks()

	for _, animationTrack: AnimationTrack in ipairs(playingTracks) do
		if animationTrack.Animation ~= equippedAnimation then
			continue
		end

		animationTrack:Stop()

		break
	end

	if unequippedRemotes[tool.Name] then
		unequippedRemotes[tool.Name]:FireClient(player)
	end
end

-- Detect when player joins and give them all current tools
local function onPlayerAdded(player: Player)
	for _, tool in ipairs(currentTools) do
		if not player.Backpack:FindFirstChild(tool.Name) then
			local clonedTool = tool:Clone()

			clonedTool.Parent = player.Backpack

			clonedTool.Activated:Connect(function()
				onToolActivated(clonedTool)
			end)

			clonedTool.Equipped:Connect(function()
				onToolEquipped(clonedTool)
			end)

			clonedTool.Unequipped:Connect(function()
				onToolUnequipped(clonedTool)
			end)
		end
	end
end

-- Add a tool to current tools list and all players inventory.
function ToolManager.add(tool: Tool)
	if not tool:IsA("Tool") then
		warn(
			`[{string.upper(script.Name)}]: Could not add item {tool.Name} to current tools, as item is a {typeof(tool)}.`
		)
		return
	end

	for _, player: Player in ipairs(Players:GetPlayers()) do
		local clonedTool = tool:Clone()
		clonedTool.Parent = player.Backpack

		clonedTool.Activated:Connect(function()
			onToolActivated(clonedTool)
		end)

		clonedTool.Equipped:Connect(function()
			onToolEquipped(clonedTool)
		end)

		clonedTool.Unequipped:Connect(function()
			onToolUnequipped(clonedTool)
		end)
	end

	table.insert(currentTools, tool)
end

-- Remove a tool from current tools list and all players inventory.
function ToolManager.remove(tool: Tool)
	if not tool:IsA("Tool") then
		warn(
			`[{string.upper(script.Name)}]: Could not remove item {tool.Name} from current tools, as item is a {typeof(
				tool
			)}.`
		)
		return
	end

	if table.find(currentTools, tool) then
		for _, player: Player in ipairs(Players:GetPlayers()) do
			local foundTool = player.Backpack:FindFirstChild(tool.Name)

			if foundTool then
				foundTool:Destroy()
			end

			local char = player.Character

			if char then
				local foundTool = char:FindFirstChild(tool.Name)

				if foundTool then
					foundTool:Destroy()
				end
			end
		end

		table.remove(currentTools, table.find(currentTools, tool))
	else
		warn(`[{string.upper(script.Name)}]: Could not remove tool {tool.Name}, as tool was not in current tool array.`)
	end
end

-- Remove all players tools and clear current tools array
function ToolManager.clear()
	for _, player: Player in ipairs(Players:GetPlayers()) do
		local backpack = player.Backpack

		for _, tool in ipairs(backpack:GetChildren()) do
			tool:Destroy()
		end

		local char = player.Character

		if char then
			for _, child in ipairs(char:GetChildren()) do
				if child:IsA("Tool") then
					child:Destroy()
				end
			end
		end
	end

	currentTools = {}
end

-- Used to connect events to functions
function ToolManager.init()
	Players.PlayerAdded:Connect(onPlayerAdded)

	return true
end

-- Used to start any automatic module logic post-initialization
function ToolManager.start()
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
return ToolManager
