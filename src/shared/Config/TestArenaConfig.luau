--!strict
-- Flat, zoned test arena used while the full Backrooms room-grid map
-- (StageConfig/WorldBuilder) is on hold. Each zone is a simple AABB the
-- server (and client, for cosmetic display) checks positions against — no
-- walls, easy to walk between zones while testing mechanics.

export type ZoneKind = "Spawn" | "Run" | "Monster"

export type ZoneDefinition = {
	Id: string,
	DisplayName: string,
	Kind: ZoneKind,
	Size: Vector3, -- footprint; only X/Z are used for layout and bounds
	Color: Color3,
	MonsterType: string?, -- key into MonsterConfig.Types, required when Kind == "Monster"
}

export type ZoneLayout = {
	Definition: ZoneDefinition,
	CenterX: number,
	MinX: number,
	MaxX: number,
	MinZ: number,
	MaxZ: number,
}

local TestArenaConfig = {}

TestArenaConfig.FloorThickness = 1
-- Matches StageConfig's own z-fight-avoidance offset above the scaffold
-- Baseplate (y = 0).
TestArenaConfig.FloorY = 1

local Zones: { ZoneDefinition } = {
	{
		Id = "spawn",
		DisplayName = "Spawn",
		Kind = "Spawn",
		Size = Vector3.new(40, 0, 40),
		Color = Color3.fromRGB(140, 140, 150),
	},
	{
		Id = "run_track",
		DisplayName = "Run Track",
		Kind = "Run",
		Size = Vector3.new(80, 0, 40),
		Color = Color3.fromRGB(80, 160, 220),
	},
	{
		Id = "slime_pit",
		DisplayName = "Slime Pit",
		Kind = "Monster",
		Size = Vector3.new(60, 0, 40),
		Color = Color3.fromRGB(60, 120, 60),
		MonsterType = "Slime",
	},
	{
		Id = "wraith_den",
		DisplayName = "Wraith Den",
		Kind = "Monster",
		Size = Vector3.new(60, 0, 40),
		Color = Color3.fromRGB(40, 30, 45),
		MonsterType = "Wraith",
	},
}

TestArenaConfig.Zones = Zones

-- Zones are placed side by side along X, centered on the world origin, with
-- a small gap between each.
local GAP = 6

local function buildLayout(): { ZoneLayout }
	local totalWidth = -GAP
	for _, zone in Zones do
		totalWidth += zone.Size.X + GAP
	end

	local cursor = -totalWidth / 2
	local layout: { ZoneLayout } = {}

	for _, zone in Zones do
		local minX = cursor
		local maxX = cursor + zone.Size.X

		table.insert(layout, {
			Definition = zone,
			CenterX = (minX + maxX) / 2,
			MinX = minX,
			MaxX = maxX,
			MinZ = -zone.Size.Z / 2,
			MaxZ = zone.Size.Z / 2,
		})

		cursor = maxX + GAP
	end

	return layout
end

TestArenaConfig.Layout = buildLayout()

function TestArenaConfig.GetZoneAt(position: Vector3): ZoneLayout?
	for _, zoneLayout in TestArenaConfig.Layout do
		if
			position.X >= zoneLayout.MinX
			and position.X <= zoneLayout.MaxX
			and position.Z >= zoneLayout.MinZ
			and position.Z <= zoneLayout.MaxZ
		then
			return zoneLayout
		end
	end
	return nil
end

return TestArenaConfig
