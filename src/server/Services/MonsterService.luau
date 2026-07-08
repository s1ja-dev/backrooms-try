--!strict
-- PERSONAL, ALWAYS-VISIBLE monsters: each player gets their own private
-- monster for every "Monster" zone in the map (see PersonalMonsterController
-- on the client, which renders a client-only Part — never replicated to the
-- server or other clients, so nobody else ever sees it). Unlike a
-- destroy-on-exit design, the monster is spawned once and always rendered,
-- visible from anywhere — but it only "activates" (chases, can catch) while
-- that specific player is standing inside its zone's rectangular bounds.
-- Leaving the zone snaps it straight back to its home spot (the zone
-- center) instead of following. Catch detection is a server-side distance
-- check each tick (there's no physical Part on the server to generate
-- Touched events against). No death/respawn — a catch knocks back and costs
-- a percentage of Speed.
--
-- "Zone" here is a TestArenaConfig rectangle standing in for a Stage while
-- the room-grid map is on hold (see plan) — the same per-(player, zone)
-- state shape generalizes directly to per-(player, Stage) once that's back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local MonsterConfig = require(ReplicatedStorage.Shared.Config.MonsterConfig)
local TestArenaConfig = require(ReplicatedStorage.Shared.Config.TestArenaConfig)

local DataService = require(script.Parent.DataService)
local CurrencyService = require(script.Parent.CurrencyService)

type MonsterType = MonsterConfig.MonsterType
type ZoneLayout = TestArenaConfig.ZoneLayout

type ZoneMonsterState = {
	ZoneLayout: ZoneLayout,
	MonsterType: MonsterType,
	HomePosition: Vector3,
	Position: Vector3,
	IsActive: boolean,
	CaughtUntil: number,
}

local MonsterService = {}

-- All "Monster" zones, resolved once at Init from TestArenaConfig.
local monsterZones: { ZoneLayout } = {}

-- states[player][zoneId] = that player's private monster for that zone.
local states: { [Player]: { [string]: ZoneMonsterState } } = {}

local function homePosition(zoneLayout: ZoneLayout): Vector3
	return Vector3.new(zoneLayout.CenterX, TestArenaConfig.FloorY + 3, 0)
end

local function fireUpdate(player: Player, state: ZoneMonsterState, teleport: boolean)
	Remotes.GetEvent(NetConstants.PersonalMonsterUpdate):FireClient(player, {
		ZoneId = state.ZoneLayout.Definition.Id,
		MonsterTypeId = state.MonsterType.Id,
		Position = state.Position,
		Teleport = teleport,
	})
end

local function initPlayerStates(player: Player)
	local playerStates: { [string]: ZoneMonsterState } = {}

	for _, zoneLayout in monsterZones do
		local zone = zoneLayout.Definition
		local monsterType = if zone.MonsterType then MonsterConfig.Types[zone.MonsterType] else nil
		if monsterType then
			local home = homePosition(zoneLayout)
			local state: ZoneMonsterState = {
				ZoneLayout = zoneLayout,
				MonsterType = monsterType,
				HomePosition = home,
				Position = home,
				IsActive = false,
				CaughtUntil = 0,
			}
			playerStates[zone.Id] = state
			fireUpdate(player, state, true)
		end
	end

	states[player] = playerStates
end

local function handleCatch(player: Player, rootPart: BasePart, state: ZoneMonsterState)
	local penalty = CurrencyService.GetSpeed(player) * state.MonsterType.PenaltyPercent
	CurrencyService.Spend(player, penalty)

	local profile = DataService.GetProfile(player)
	if profile then
		profile.Stats.TotalMonsterHits += 1
	end

	local away = rootPart.Position - state.Position
	local knockbackDirection = if away.Magnitude > 0.01 then away.Unit else Vector3.new(0, 0, 1)
	rootPart.AssemblyLinearVelocity += knockbackDirection * state.MonsterType.KnockbackForce

	Remotes.GetEvent(NetConstants.MonsterHit):FireClient(player, {
		PenaltyAmount = penalty,
		RemainingSpeed = CurrencyService.GetSpeed(player),
	})

	state.CaughtUntil = os.clock() + state.MonsterType.TouchDebounce
end

local function tickZoneMonster(player: Player, rootPart: BasePart, currentZoneLayout: ZoneLayout?, state: ZoneMonsterState, deltaTime: number)
	local isInThisZone = currentZoneLayout == state.ZoneLayout

	if not isInThisZone then
		if state.IsActive then
			-- Player just left: snap straight back home instead of following.
			state.IsActive = false
			state.Position = state.HomePosition
			fireUpdate(player, state, true)
		end
		return
	end

	if not state.IsActive then
		-- Just entered this zone: activate, but skip the catch check this
		-- tick (grace period) so walking in doesn't instantly catch you.
		state.IsActive = true
		fireUpdate(player, state, false)
		return
	end

	if os.clock() >= state.CaughtUntil then
		local playerPosition = rootPart.Position
		local toPlayer = playerPosition - state.Position
		local distance = toPlayer.Magnitude

		if distance <= state.MonsterType.CatchDistance then
			handleCatch(player, rootPart, state)
			state.Position = state.HomePosition
		elseif distance > 0.01 then
			local step = math.min(state.MonsterType.ChaseSpeed * deltaTime, distance)
			state.Position += toPlayer.Unit * step
		end
	end

	fireUpdate(player, state, false)
end

local function tickPlayer(player: Player, deltaTime: number)
	local playerStates = states[player]
	if not playerStates then
		return
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local currentZoneLayout = TestArenaConfig.GetZoneAt((rootPart :: BasePart).Position)
	if currentZoneLayout and currentZoneLayout.Definition.Kind ~= "Monster" then
		currentZoneLayout = nil
	end

	for _, state in playerStates do
		tickZoneMonster(player, rootPart :: BasePart, currentZoneLayout, state, deltaTime)
	end
end

local function trackPlayer(player: Player)
	initPlayerStates(player)

	task.spawn(function()
		local lastTick = os.clock()
		while player:IsDescendantOf(Players) do
			task.wait(MonsterConfig.UpdateTickInterval)
			local now = os.clock()
			local deltaTime = now - lastTick
			lastTick = now

			if DataService.IsLoaded(player) then
				tickPlayer(player, deltaTime)
			end
		end
	end)
end

function MonsterService.Init()
	for _, zoneLayout in TestArenaConfig.Layout do
		if zoneLayout.Definition.Kind == "Monster" then
			table.insert(monsterZones, zoneLayout)
		end
	end

	Players.PlayerAdded:Connect(trackPlayer)
	for _, player in Players:GetPlayers() do
		trackPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return MonsterService
