--!strict
-- Data-driven stage list: 3 active Backrooms zones + 3 reserved future zones
-- (IsImplemented = false, no Layout/Palette). Adding a real 4th stage later
-- is just flipping IsImplemented and filling in Layout/Palette/SpawnAnchor —
-- zero new code required in WorldBuilder/StageService.

local PaletteConfig = require(script.Parent.PaletteConfig)

export type StagePalette = PaletteConfig.StagePalette

export type StageLayout = {
	RoomGridSize: Vector2,
	RoomSize: Vector3,
	CorridorWidth: number,
}

export type StageDefinition = {
	Id: string,
	DisplayName: string,
	IsImplemented: boolean,
	UnlockLevel: number,
	Origin: CFrame,
	Palette: StagePalette?,
	Layout: StageLayout?,
	SpawnAnchor: CFrame?,
	MonsterSpawnPoints: { CFrame }?,
}

-- Stages are laid out far apart along X so their geometry never overlaps.
local STAGE_SPACING = 400

-- Y = 1 (not 0) so room floors sit just above the scaffold Baseplate's top
-- surface (y=0) instead of exactly coplanar with it, which would z-fight.
local function originFor(index: number): CFrame
	return CFrame.new(index * STAGE_SPACING, 1, 0)
end

local DEFAULT_LAYOUT: StageLayout = {
	RoomGridSize = Vector2.new(4, 4),
	RoomSize = Vector3.new(24, 10, 24),
	CorridorWidth = 8,
}

-- Matches WorldBuilder's own grid-centering math: the far corner room's
-- center, so the default monster spawn point actually lands inside the
-- built grid instead of past its outer wall.
local DEFAULT_CELL_SPACING = DEFAULT_LAYOUT.RoomSize.X + DEFAULT_LAYOUT.CorridorWidth
local DEFAULT_GRID_CORNER = (DEFAULT_LAYOUT.RoomGridSize.X - 1) * DEFAULT_CELL_SPACING / 2

local Stages: { StageDefinition } = {
	{
		Id = "yellow_rooms",
		DisplayName = "Yellow Rooms",
		IsImplemented = true,
		UnlockLevel = 1,
		Origin = originFor(0),
		Palette = PaletteConfig.YellowRooms,
		Layout = DEFAULT_LAYOUT,
		SpawnAnchor = originFor(0) * CFrame.new(0, 5, 0),
		MonsterSpawnPoints = { originFor(0) * CFrame.new(DEFAULT_GRID_CORNER, 5, DEFAULT_GRID_CORNER) },
	},
	{
		Id = "flooded_corridors",
		DisplayName = "Flooded Corridors",
		IsImplemented = true,
		UnlockLevel = 10,
		Origin = originFor(1),
		Palette = PaletteConfig.FloodedCorridors,
		Layout = DEFAULT_LAYOUT,
		SpawnAnchor = originFor(1) * CFrame.new(0, 5, 0),
		MonsterSpawnPoints = { originFor(1) * CFrame.new(DEFAULT_GRID_CORNER, 5, DEFAULT_GRID_CORNER) },
	},
	{
		Id = "offices",
		DisplayName = "Offices",
		IsImplemented = true,
		UnlockLevel = 20,
		Origin = originFor(2),
		Palette = PaletteConfig.Offices,
		Layout = DEFAULT_LAYOUT,
		SpawnAnchor = originFor(2) * CFrame.new(0, 5, 0),
		MonsterSpawnPoints = { originFor(2) * CFrame.new(DEFAULT_GRID_CORNER, 5, DEFAULT_GRID_CORNER) },
	},
	{
		Id = "parking_garage",
		DisplayName = "Parking Garage",
		IsImplemented = false,
		UnlockLevel = 35,
		Origin = originFor(3),
	},
	{
		Id = "pools",
		DisplayName = "Pools",
		IsImplemented = false,
		UnlockLevel = 50,
		Origin = originFor(4),
	},
	{
		Id = "laboratory",
		DisplayName = "Laboratory",
		IsImplemented = false,
		UnlockLevel = 70,
		Origin = originFor(5),
	},
}

local StageConfig = {
	Stages = Stages,
	DefaultStageId = "yellow_rooms",
}

function StageConfig.GetById(stageId: string): StageDefinition?
	for _, stage in Stages do
		if stage.Id == stageId then
			return stage
		end
	end
	return nil
end

function StageConfig.GetImplementedStages(): { StageDefinition }
	local implemented = {}
	for _, stage in Stages do
		if stage.IsImplemented then
			table.insert(implemented, stage)
		end
	end
	return implemented
end

return StageConfig
