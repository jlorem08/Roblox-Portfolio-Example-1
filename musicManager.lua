--!strict

--[[
	MUSIC MANAGER:
	- allows you to play a playlist of music (folder in SoundService -> Playlists)
	- allows you to stop any playing music from a playlist
	- gives the ability to smoothly fade into or out of music.
]]

--------------
-- SERVICES --
--------------
local SoundService = game:GetService("SoundService")

-----------
-- TYPES --
-----------
type PlaylistThreadMap = { [string]: thread }

---------------
-- CONSTANTS --
---------------
local MusicManager = {}

local playlists = SoundService.Playlists

---------------
-- VARIABLES --
---------------
local activeSongs: { [string]: Sound } = {}
local playlistThreads: PlaylistThreadMap = {}

---------------
-- FUNCTIONS --
---------------

-- Returns a random sound from the given playlist folder.
local function getRandomSongFromPlaylist(playlist: Folder): Sound
	local songs = playlist:GetChildren() :: { Sound }
	local randomIndex = math.random(1, #songs)

	return songs[randomIndex] :: Sound
end

-- Returns a random sound from the playlist that isn't the currently playing sound.
local function getNonRepeatedRandomSong(playlist: Folder, playlistName: string): Sound?
	local songs = playlist:GetChildren() :: { Sound }

	if #songs < 2 then
		warn(`[{string.upper(script.Name)}]: Playlist {playlistName} has fewer than 2 songs.`)
		return nil
	end

	local current = activeSongs[playlistName]
	local pick: Sound = getRandomSongFromPlaylist(playlist)

	-- Prevent repetition
	while pick == current do
		pick = getRandomSongFromPlaylist(playlist)
	end

	return pick
end

-- Starts playing songs from the specified playlist, optionally with smooth transitions. (WILL YIELD THREAD)
function MusicManager.play(playlistName: string, smoothTransition: boolean, transitionLength: number?)
	if playlistThreads[playlistName] then
		warn(`[MUSIC MANAGER]: Playlist "{playlistName}" is already playing.`)
		return
	end

	local playlist = playlists:FindFirstChild(playlistName) :: Folder?
	if not playlist then
		warn(`[MUSIC MANAGER]: Playlist "{playlistName}" not found.`)
		return
	end

	local thread = task.spawn(function()
		while true do
			local song = getNonRepeatedRandomSong(playlist, playlistName)
			if not song then
				return
			end

			local originalVolume = song.Volume
			local fadeSteps = 20
			local stepTime = (transitionLength or 3) / fadeSteps

			if smoothTransition then
				song.Volume = 0
				song:Play()
				activeSongs[playlistName] = song

				for i = 1, fadeSteps do
					song.Volume = (i / fadeSteps) * originalVolume
					task.wait(stepTime)
				end

				task.wait(math.max(song.TimeLength - (transitionLength or 3), 0))

				for i = 1, fadeSteps do
					song.Volume = ((fadeSteps - i) / fadeSteps) * originalVolume
					task.wait(stepTime)
				end

				song:Stop()
				song.Volume = originalVolume
			else
				song:Play()
				activeSongs[playlistName] = song
				song.Ended:Wait()
			end
		end
	end)

	playlistThreads[playlistName] = thread
end

-- Stops playback of the specified playlist, optionally fading out smoothly.
function MusicManager.stop(playlistName: string, smoothTransition: boolean, transitionLength: number?)
	local playlist = playlists:FindFirstChild(playlistName)
	if not playlist then
		warn(`[MUSIC MANAGER]: Cannot stop "{playlistName}", playlist not found.`)
		return
	end

	if playlistThreads[playlistName] then
		task.cancel(playlistThreads[playlistName])
		playlistThreads[playlistName] = nil
	end

	local song = activeSongs[playlistName]
	activeSongs[playlistName] = nil

	if not song or not song:IsDescendantOf(playlist) then
		return
	end

	local originalVolume = song.Volume
	local fadeSteps = 20
	local stepTime = (transitionLength or 3) / fadeSteps

	if smoothTransition then
		for i = 1, fadeSteps do
			song.Volume = ((fadeSteps - i) / fadeSteps) * originalVolume
			task.wait(stepTime)
		end
	end

	song:Stop()
	song.Volume = originalVolume
end

-- Used to connect events to functions
function MusicManager.init()
	return true
end

-- Used to start any automatic module logic post-initialization
function MusicManager.start()
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
return MusicManager
