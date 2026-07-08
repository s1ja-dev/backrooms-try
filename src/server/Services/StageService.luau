--!strict
-- TEMPORARY: builds the flat TestArena (see shared/World/TestArena.luau)
-- instead of the full Backrooms room-grid (StageConfig/WorldBuilder/
-- RoomTemplates — untouched, ready to swap back in) while core mechanics
-- (movement-earn, zones, monster variety) are being tested end to end. See
-- the plan file for the room-grid-based version this replaces.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestArena = require(ReplicatedStorage.Shared.World.TestArena)
local TestArenaConfig = require(ReplicatedStorage.Shared.Config.TestArenaConfig)

local StageService = {}

local function teleportToSpawn(player: Player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	local spawnZone = TestArenaConfig.Layout[1]
	if spawnZone then
		rootPart.CFrame = CFrame.new(spawnZone.CenterX, TestArenaConfig.FloorY + 5, 0)
	end
end

function StageService.Init()
	TestArena.Build(Workspace)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.defer(teleportToSpawn, player)
		end)
	end)
end

return StageService
