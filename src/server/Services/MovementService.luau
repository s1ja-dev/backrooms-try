--!strict
-- Grants a FLAT Speed amount per tick while the player is actively moving,
-- sampled on a fixed tick (not every Heartbeat, to keep this cheap).
-- Deliberately NOT proportional to distance covered: a higher WalkSpeed
-- (from leveling up) must not also mean a higher earn rate, or progression
-- would compound on itself. Boosted inside "Run" zones. Anti-cheat: an
-- implausible per-tick jump (teleport/noclip) is dropped instead of
-- trusting it. This is the "earn" half of the incremental trio for this
-- game — CurrencyService itself is genre-agnostic and doesn't know or care
-- that movement is the source.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local TestArenaConfig = require(ReplicatedStorage.Shared.Config.TestArenaConfig)

local DataService = require(script.Parent.DataService)
local CurrencyService = require(script.Parent.CurrencyService)

local MovementService = {}

local lastPosition: { [Player]: Vector3 } = {}

local function trackPlayer(player: Player)
	task.spawn(function()
		while player:IsDescendantOf(Players) do
			task.wait(EconomyConfig.MovementTickInterval)

			local character = player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			if not rootPart or not DataService.IsLoaded(player) then
				continue
			end

			local currentPosition = (rootPart :: BasePart).Position
			local previousPosition = lastPosition[player]
			lastPosition[player] = currentPosition

			if not previousPosition then
				continue
			end

			local distance = (currentPosition - previousPosition).Magnitude
			if distance > EconomyConfig.MaxPlausibleStudsPerTick then
				-- Implausible jump (teleport/noclip) — drop the sample entirely,
				-- don't reward it.
				continue
			end
			if distance < EconomyConfig.MinMovementThreshold then
				-- Standing still (or near enough): no gain, regardless of WalkSpeed.
				continue
			end

			local zoneLayout = TestArenaConfig.GetZoneAt(currentPosition)
			local multiplier = if zoneLayout and zoneLayout.Definition.Kind == "Run"
				then EconomyConfig.RunZoneMultiplier
				else 1

			CurrencyService.Add(player, EconomyConfig.SpeedPerTick * multiplier)
		end
	end)
end

function MovementService.Init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			-- Reset the baseline so a respawn/teleport doesn't get read as a
			-- single giant (and rejected) movement sample.
			lastPosition[player] = nil
		end)
		trackPlayer(player)
	end)

	for _, player in Players:GetPlayers() do
		trackPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		lastPosition[player] = nil
	end)
end

return MovementService
