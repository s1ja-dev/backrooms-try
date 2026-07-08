--!strict
-- Sole owner of Speed-currency mutations (Add/Spend). Applies
-- RebirthMultiplier on gains, fires CurrencyChanged. Earn source is
-- MovementService (running); this module doesn't care where gains come
-- from. Together with LevelService/RebirthService this is the earn ->
-- spend-to-level -> prestige-reset trio reusable in any incremental/idle
-- game.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local DataService = require(script.Parent.DataService)
local LeaderboardService = require(script.Parent.LeaderboardService)

local CurrencyService = {}

local function fireCurrencyChanged(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end

	local event = Remotes.GetEvent(NetConstants.CurrencyChanged)
	event:FireClient(player, {
		Speed = profile.Currency.Speed,
		LifetimeSpeed = profile.Currency.LifetimeSpeed,
	})
end

-- Adds `amount` (pre-multiplier raw earn) to the player's Speed currency,
-- applying their RebirthMultiplier. Returns the actual amount credited.
function CurrencyService.Add(player: Player, amount: number): number
	local profile = DataService.GetProfile(player)
	if not profile or amount <= 0 then
		return 0
	end

	local credited = amount * profile.Rebirth.RebirthMultiplier
	profile.Currency.Speed += credited
	profile.Currency.LifetimeSpeed += credited

	fireCurrencyChanged(player)
	LeaderboardService.MaybeUpdate(player)

	return credited
end

-- Attempts to spend `amount` of currency. Returns false without mutating
-- anything if the player can't afford it.
function CurrencyService.Spend(player: Player, amount: number): boolean
	local profile = DataService.GetProfile(player)
	if not profile or amount <= 0 then
		return false
	end

	if profile.Currency.Speed < amount then
		return false
	end

	profile.Currency.Speed -= amount
	fireCurrencyChanged(player)

	return true
end

function CurrencyService.GetSpeed(player: Player): number
	local profile = DataService.GetProfile(player)
	return if profile then profile.Currency.Speed else 0
end

function CurrencyService.Init() end

return CurrencyService
