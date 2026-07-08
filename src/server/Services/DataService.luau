--!strict
-- DataStoreService wrapper: pcall+retry load, staggered autosave, save on
-- PlayerRemoving and BindToClose. Reusable near-verbatim in any Roblox game
-- needing player persistence — the retry/BindToClose/autosave pattern is
-- genre-agnostic.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local ProfileTemplate = require(script.Parent.Parent.Data.ProfileTemplate)
local ProfileMigrations = require(script.Parent.Parent.Data.ProfileMigrations)

local Types = require(ReplicatedStorage.Shared.Types.Types)
type PlayerProfile = Types.PlayerProfile

local STORE_NAME = "PlayerProfiles_v1"
local RETRY_BACKOFF_SECONDS = { 1, 3, 6 }
local AUTOSAVE_INTERVAL = 120
local BIND_TO_CLOSE_BUDGET = 25

local DataService = {}

-- GetDataStore itself throws if the place isn't published and Studio Access
-- to API Services isn't enabled — pcall it so that testing locally without
-- either degrades to "no persistence" instead of crashing the entire server
-- bootstrap (every other service requires this module).
local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn(
			`DataService: DataStore unavailable ({result}) — running without persistence. Enable "Studio Access to API Services" in Game Settings, or publish the place, to test saving.`
		)
	end
end

local activeProfiles: { [Player]: PlayerProfile } = {}
local loadedPlayers: { [Player]: boolean } = {}

local function profileKey(userId: number): string
	return `Player_{userId}`
end

-- Runs `attempt` once, then retries on failure using RETRY_BACKOFF_SECONDS.
-- Returns (success, result-or-error).
local function withRetry<T>(attempt: () -> T): (boolean, T | string)
	local ok, result = pcall(attempt)
	if ok then
		return true, result
	end

	for _, waitSeconds in RETRY_BACKOFF_SECONDS do
		task.wait(waitSeconds)
		ok, result = pcall(attempt)
		if ok then
			return true, result
		end
	end

	return false, result :: string
end

local function loadProfile(player: Player): PlayerProfile
	if not store then
		local profile = ProfileTemplate.New()
		profile.Stats.FirstJoinedAt = os.time()
		return profile
	end

	local key = profileKey(player.UserId)

	local ok, result = withRetry(function()
		return (store :: DataStore):GetAsync(key)
	end)

	local profile: PlayerProfile
	if ok and result ~= nil then
		profile = ProfileMigrations.Apply(result :: PlayerProfile)
	else
		if not ok then
			warn(`DataService: failed to load profile for {player.Name} after retries, starting fresh: {result}`)
		end
		profile = ProfileTemplate.New()
		profile.Stats.FirstJoinedAt = os.time()
	end

	return profile
end

local function saveProfile(player: Player, profile: PlayerProfile): boolean
	if not store then
		return false
	end

	local key = profileKey(player.UserId)
	profile.Stats.LastSavedAt = os.time()

	local ok, err = withRetry(function()
		(store :: DataStore):SetAsync(key, profile)
	end)

	if not ok then
		warn(`DataService: failed to save profile for {player.Name} after retries: {err}`)
	end

	return ok
end

function DataService.GetProfile(player: Player): PlayerProfile?
	return activeProfiles[player]
end

function DataService.IsLoaded(player: Player): boolean
	return loadedPlayers[player] == true
end

function DataService.ForceSave(player: Player)
	local profile = activeProfiles[player]
	if profile then
		saveProfile(player, profile)
	end
end

local function onPlayerAdded(player: Player)
	local profile = loadProfile(player)

	if not player:IsDescendantOf(Players) then
		-- Player left while their profile was loading; nothing to attach to.
		return
	end

	activeProfiles[player] = profile
	loadedPlayers[player] = true

	local profileReady = Remotes.GetEvent(NetConstants.ProfileReady)
	profileReady:FireClient(player, {
		Currency = profile.Currency,
		Progression = profile.Progression,
		Rebirth = profile.Rebirth,
		Stages = profile.Stages,
	})

	-- Autosave loop; naturally staggered across players by join time.
	task.spawn(function()
		while activeProfiles[player] do
			task.wait(AUTOSAVE_INTERVAL)
			if activeProfiles[player] then
				saveProfile(player, activeProfiles[player])
			end
		end
	end)
end

local function onPlayerRemoving(player: Player)
	local profile = activeProfiles[player]
	if profile then
		saveProfile(player, profile)
	end
	activeProfiles[player] = nil
	loadedPlayers[player] = nil
end

function DataService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	game:BindToClose(function()
		local start = os.clock()
		local pending = 0

		for player, profile in activeProfiles do
			pending += 1
			task.spawn(function()
				saveProfile(player, profile)
				pending -= 1
			end)
		end

		while pending > 0 and os.clock() - start < BIND_TO_CLOSE_BUDGET do
			task.wait(0.1)
		end
	end)
end

return DataService
