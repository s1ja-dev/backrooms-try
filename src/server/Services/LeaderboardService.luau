--!strict
-- OrderedDataStore-backed leaderboard: throttled writes, cached top-N read
-- refreshed on a timer so LeaderboardRequest never hits the DataStore
-- directly. Reusable near-verbatim in any game with a competitive/ranked
-- stat (kills, wins, currency, time).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local DataService = require(script.Parent.DataService)

local STORE_NAME = "SpeedLeaderboard_v1"
local TOP_N = 10
local REFRESH_INTERVAL = 60
local WRITE_THROTTLE_SECONDS = 30
local WRITE_THROTTLE_DELTA_FRACTION = 0.05

type LeaderboardEntry = {
	UserId: number,
	DisplayName: string,
	LifetimeSpeed: number,
}

local LeaderboardService = {}

-- Same "throws if unpublished/no Studio API access" hazard as DataService —
-- pcall it so an unpublished place degrades to "no leaderboard" instead of
-- crashing the whole server bootstrap.
local store: OrderedDataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetOrderedDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn(`LeaderboardService: OrderedDataStore unavailable ({result}) — leaderboard will stay empty.`)
	end
end

local lastWrittenValue: { [Player]: number } = {}
local lastWriteAt: { [Player]: number } = {}

local cachedTop: { LeaderboardEntry } = {}

local function refreshCache()
	if not store then
		return
	end

	local ok, pages = pcall(function()
		return (store :: OrderedDataStore):GetSortedAsync(false, TOP_N)
	end)

	if not ok then
		warn(`LeaderboardService: GetSortedAsync failed: {pages}`)
		return
	end

	local page = (pages :: DataStorePages):GetCurrentPage()
	local top: { LeaderboardEntry } = {}

	for _, entry in page do
		local userId = tonumber(entry.key) or 0
		local nameOk, displayName = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)

		table.insert(top, {
			UserId = userId,
			DisplayName = if nameOk then displayName else `Player_{userId}`,
			LifetimeSpeed = entry.value,
		})
	end

	cachedTop = top
end

-- Throttled write: only actually hits SetAsync if enough time has passed or
-- the value moved meaningfully, so normal play doesn't spam the store.
function LeaderboardService.MaybeUpdate(player: Player)
	if not store then
		return
	end

	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end

	local value = math.floor(profile.Currency.LifetimeSpeed)
	local now = os.clock()

	local previousValue = lastWrittenValue[player]
	local previousWriteAt = lastWriteAt[player] or 0

	local movedEnough = not previousValue
		or previousValue == 0
		or math.abs(value - previousValue) / math.max(previousValue, 1) >= WRITE_THROTTLE_DELTA_FRACTION
	local enoughTimePassed = now - previousWriteAt >= WRITE_THROTTLE_SECONDS

	if not movedEnough and not enoughTimePassed then
		return
	end

	lastWrittenValue[player] = value
	lastWriteAt[player] = now

	task.spawn(function()
		local ok, err = pcall(function()
			(store :: OrderedDataStore):SetAsync(tostring(player.UserId), value)
		end)
		if not ok then
			warn(`LeaderboardService: SetAsync failed for {player.Name}: {err}`)
		end
	end)
end

local function onLeaderboardRequest(_player: Player): { LeaderboardEntry }
	return cachedTop
end

function LeaderboardService.Init()
	local requestFunction = Remotes.GetFunction(NetConstants.LeaderboardRequest)
	requestFunction.OnServerInvoke = onLeaderboardRequest

	task.spawn(function()
		while true do
			refreshCache()
			task.wait(REFRESH_INTERVAL)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastWrittenValue[player] = nil
		lastWriteAt[player] = nil
	end)
end

return LeaderboardService
