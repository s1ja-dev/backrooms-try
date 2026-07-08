--!strict
-- Rebirth: validates the level threshold, resets Currency/Level/WalkSpeed,
-- recomputes the permanent multiplier. LifetimeSpeed and Stats are NOT
-- reset — they persist for leaderboard/history.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local RebirthConfig = require(ReplicatedStorage.Shared.Config.RebirthConfig)

local DataService = require(script.Parent.DataService)
local LevelService = require(script.Parent.LevelService)

local RebirthService = {}

local function fireRebirthChanged(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end

	local event = Remotes.GetEvent(NetConstants.RebirthChanged)
	event:FireClient(player, {
		RebirthCount = profile.Rebirth.RebirthCount,
		Multiplier = profile.Rebirth.RebirthMultiplier,
	})
end

-- The actual business logic, exposed publicly (not just wired to the
-- remote) so it's directly testable and so a future non-remote trigger
-- (an NPC "rebirth altar", a console command, ...) can call it too. Returns
-- false without mutating anything if the player hasn't met the threshold.
function RebirthService.PerformRebirth(player: Player): boolean
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end

	if profile.Progression.Level < RebirthConfig.RequiredLevel then
		return false
	end

	profile.Currency.Speed = 0
	profile.Rebirth.RebirthCount += 1
	profile.Rebirth.RebirthMultiplier = RebirthConfig.ComputeMultiplier(profile.Rebirth.RebirthCount)

	LevelService.ResetToBase(player)
	fireRebirthChanged(player)

	return true
end

function RebirthService.Init()
	local requestRebirth = Remotes.GetEvent(NetConstants.RequestRebirth)
	requestRebirth.OnServerEvent:Connect(function(player: Player)
		RebirthService.PerformRebirth(player)
	end)
end

return RebirthService
