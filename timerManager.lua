--!strict

--[[
	TIMER MANAGER:
	- Manages top-of-screen timer
	- Optionally displays task that is the reason for the timer
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
local TimerManager = {}

---------------
-- VARIABLES --
---------------
local currentTimeRemaining: number? = nil
local currentTask: string? = nil

---------------
-- FUNCTIONS --
---------------

-- used when a player joins, activates the timer for that player as well.
local function onPlayerAdded(player: Player)
	player.CharacterAdded:Wait() -- give time for some stuff to load

	if not currentTimeRemaining then
		return
	end

	for i = currentTimeRemaining, 1, -1 do
		local playerUi = player:FindFirstChild("PlayerGui") :: PlayerGui?
		if not playerUi then
			return
		end

		local timerGui = playerUi:FindFirstChild("Timer") :: ScreenGui?
		if not timerGui then
			return
		end

		local mainFrame = timerGui:FindFirstChild("MainFrame") :: Frame?
		if not mainFrame then
			return
		end

		local timeRemainingLabel = mainFrame:FindFirstChild("TimeRemainingLabel") :: TextLabel?
		if not timeRemainingLabel then
			return
		end

		local currentTaskLabel = mainFrame:FindFirstChild("CurrentTaskLabel") :: TextLabel?
		if not currentTaskLabel then
			return
		end

		mainFrame.Visible = true
		timeRemainingLabel.Text = tostring(currentTimeRemaining)
		currentTaskLabel.Text = currentTask :: string

		task.wait(1)
	end

	local playerUi = player:FindFirstChild("PlayerGui") :: PlayerGui?
	if not playerUi then
		return
	end

	local timerGui = playerUi:FindFirstChild("Timer") :: ScreenGui?
	if not timerGui then
		return
	end

	local mainFrame = timerGui:FindFirstChild("MainFrame") :: Frame?
	if not mainFrame then
		return
	end

	mainFrame.Visible = false
end

-- used to start a countdown for all players
function TimerManager.startCountdown(countdownLength: number, taskName: string?)
	currentTask = taskName

	for i = countdownLength, 1, -1 do
		currentTimeRemaining = i

		for _, player: Player in ipairs(Players:GetPlayers()) do
			local playerUi = player:FindFirstChild("PlayerGui") :: PlayerGui?
			if not playerUi then
				continue
			end

			local timerGui = playerUi:FindFirstChild("Timer") :: ScreenGui?
			if not timerGui then
				continue
			end

			local mainFrame = timerGui:FindFirstChild("MainFrame") :: Frame?
			if not mainFrame then
				continue
			end

			local timeRemainingLabel = mainFrame:FindFirstChild("TimeRemainingLabel") :: TextLabel?
			if not timeRemainingLabel then
				continue
			end

			local currentTaskLabel = mainFrame:FindFirstChild("CurrentTaskLabel") :: TextLabel?
			if not currentTaskLabel then
				return
			end

			mainFrame.Visible = true
			timeRemainingLabel.Text = tostring(currentTimeRemaining)
			currentTaskLabel.Text = currentTask :: string
		end

		task.wait(1)
	end

	for _, player: Player in ipairs(Players:GetPlayers()) do
		local playerUi = player:FindFirstChild("PlayerGui") :: PlayerGui?
		if not playerUi then
			continue
		end

		local timerGui = playerUi:FindFirstChild("Timer") :: ScreenGui?
		if not timerGui then
			continue
		end

		local mainFrame = timerGui:FindFirstChild("MainFrame") :: Frame?
		if not mainFrame then
			continue
		end

		mainFrame.Visible = false
	end
end

-- Used to connect events to functions
function TimerManager.init()
	Players.PlayerAdded:Connect(onPlayerAdded)

	return true
end

-- Used to start any automatic module logic post-initialization
function TimerManager.start()
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
return TimerManager
