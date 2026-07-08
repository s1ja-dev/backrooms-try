--!strict
-- Renders the local player's personal monsters as client-only Parts —
-- created here, so they are never replicated to the server or other clients
-- (the standard Roblox trick for "only I can see this"). One monster per
-- zone, spawned once and always visible; snaps instantly (no tween) when
-- the server says `Teleport = true` (entering/leaving a zone), tweens
-- smoothly between ordinary position updates otherwise. Purely cosmetic:
-- catch/penalty is decided server-side in MonsterService.

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local MonsterConfig = require(ReplicatedStorage.Shared.Config.MonsterConfig)

type UpdatePayload = {
	ZoneId: string,
	MonsterTypeId: string,
	Position: Vector3,
	Teleport: boolean,
}

local PersonalMonsterController = {}

local parts: { [string]: Part } = {}
local tweens: { [string]: Tween } = {}

local function createPart(monsterType: MonsterConfig.MonsterType, position: Vector3): Part
	local part = Instance.new("Part")
	part.Name = "PersonalMonster_" .. monsterType.DisplayName
	part.Shape = Enum.PartType.Block
	part.Size = monsterType.Size
	part.Color = monsterType.Color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanQuery = false
	part.Anchored = true
	part.CFrame = CFrame.new(position)
	part.Parent = Workspace
	return part
end

local function onUpdate(data: UpdatePayload)
	local monsterType = MonsterConfig.Types[data.MonsterTypeId]
	if not monsterType then
		return
	end

	local existingTween = tweens[data.ZoneId]
	if existingTween then
		existingTween:Cancel()
		tweens[data.ZoneId] = nil
	end

	local part = parts[data.ZoneId]
	if not part then
		parts[data.ZoneId] = createPart(monsterType, data.Position)
		return
	end

	if data.Teleport then
		part.CFrame = CFrame.new(data.Position)
		return
	end

	local tween = TweenService:Create(
		part,
		TweenInfo.new(MonsterConfig.UpdateTickInterval, Enum.EasingStyle.Linear),
		{ CFrame = CFrame.new(data.Position) }
	)
	tweens[data.ZoneId] = tween
	tween:Play()
end

function PersonalMonsterController.Init()
	Remotes.GetEvent(NetConstants.PersonalMonsterUpdate).OnClientEvent:Connect(onUpdate)
end

return PersonalMonsterController
