--!strict
-- Level purchase: spends currency per LevelConfig's cost curve, maps
-- Level -> Humanoid.WalkSpeed (tangible progression), fires LevelChanged +
-- LevelUpAnnounce.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local LevelConfig = require(ReplicatedStorage.Shared.Config.LevelConfig)

local DataService = require(script.Parent.DataService)
local CurrencyService = require(script.Parent.CurrencyService)

local Types = require(ReplicatedStorage.Shared.Types.Types)
type PlayerProfile = Types.PlayerProfile

local LevelService = {}

local function applyWalkSpeed(player: Player, walkSpeed: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = walkSpeed
	end
end

local function fireLevelChanged(player: Player, profile: PlayerProfile)
	local event = Remotes.GetEvent(NetConstants.LevelChanged)
	event:FireClient(player, {
		Level = profile.Progression.Level,
		WalkSpeed = profile.Progression.WalkSpeedBase,
	})
end

-- Re-applies the profile's current WalkSpeed to a (re)spawned character, so
-- progression survives death/respawn.
function LevelService.ApplyToCharacter(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end
	applyWalkSpeed(player, profile.Progression.WalkSpeedBase)
end

-- Resets Level/WalkSpeed back to base. Used by RebirthService.
function LevelService.ResetToBase(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end

	profile.Progression.Level = 1
	profile.Progression.WalkSpeedBase = LevelConfig.GetWalkSpeedForLevel(1)
	applyWalkSpeed(player, profile.Progression.WalkSpeedBase)

	fireLevelChanged(player, profile)
end

local function grantLevels(player: Player, profile: PlayerProfile, count: number)
	profile.Progression.Level += count
	profile.Progression.WalkSpeedBase = LevelConfig.GetWalkSpeedForLevel(profile.Progression.Level)
	applyWalkSpeed(player, profile.Progression.WalkSpeedBase)

	fireLevelChanged(player, profile)

	local announce = Remotes.GetEvent(NetConstants.LevelUpAnnounce)
	announce:FireClient(player, { NewLevel = profile.Progression.Level })
end

-- Grants `count` levels for free (no currency spent) — used by
-- MonetizationService for the InstantLevels dev product effect.
function LevelService.AddLevels(player: Player, count: number)
	if count <= 0 then
		return
	end

	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end

	grantLevels(player, profile, count)
end

local function onRequestLevelUp(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end

	local cost = LevelConfig.GetCostForLevel(profile.Progression.Level)
	if not CurrencyService.Spend(player, cost) then
		return
	end

	grantLevels(player, profile, 1)
end

function LevelService.Init()
	local requestLevelUp = Remotes.GetEvent(NetConstants.RequestLevelUp)
	requestLevelUp.OnServerEvent:Connect(onRequestLevelUp)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			LevelService.ApplyToCharacter(player)
		end)
	end)
end

return LevelService
