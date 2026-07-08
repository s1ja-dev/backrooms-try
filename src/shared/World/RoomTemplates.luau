--!strict
-- Small library of room-shape generator functions that WorldBuilder
-- composes. Plain Parts only (no CSG/Union) for performance and easy
-- editing in Studio.

local PaletteConfig = require(script.Parent.Parent.Config.PaletteConfig)

type StagePalette = PaletteConfig.StagePalette

local RoomTemplates = {}

local WALL_THICKNESS = 1
local DOOR_WIDTH = 8

local function createPart(
	size: Vector3,
	cframe: CFrame,
	palette: StagePalette,
	colorKey: "Wall" | "Floor" | "Ceiling",
	parent: Instance
): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = palette[colorKey]
	part.Material = palette.Material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

export type OpenSides = {
	North: boolean,
	South: boolean,
	East: boolean,
	West: boolean,
}

-- Builds one room cell: floor, ceiling, and 4 walls. Walls on `openSides`
-- are split into two flanking segments with a door-width gap instead of a
-- single solid part, so the grid reads as connected rooms/corridors.
function RoomTemplates.CreateBoxRoom(
	parent: Instance,
	center: Vector3,
	roomSize: Vector3,
	palette: StagePalette,
	openSides: OpenSides
): Model
	local room = Instance.new("Model")
	room.Name = "Room"

	local halfX = roomSize.X / 2
	local halfZ = roomSize.Z / 2
	local height = roomSize.Y

	createPart(Vector3.new(roomSize.X, WALL_THICKNESS, roomSize.Z), CFrame.new(center), palette, "Floor", room)

	createPart(
		Vector3.new(roomSize.X, WALL_THICKNESS, roomSize.Z),
		CFrame.new(center + Vector3.new(0, height, 0)),
		palette,
		"Ceiling",
		room
	)

	local function buildWall(axisIsX: boolean, sign: number, isOpen: boolean)
		local wallCenter = if axisIsX
			then center + Vector3.new(sign * halfX, height / 2, 0)
			else center + Vector3.new(0, height / 2, sign * halfZ)

		-- axisIsX walls face East/West and run along Z; the others face
		-- North/South and run along X.
		local fullLength = if axisIsX then roomSize.Z else roomSize.X
		local rotation = if axisIsX then CFrame.Angles(0, math.rad(90), 0) else CFrame.new()
		local offsetAxis = if axisIsX then Vector3.new(0, 0, 1) else Vector3.new(1, 0, 0)

		if not isOpen then
			createPart(Vector3.new(fullLength, height, WALL_THICKNESS), CFrame.new(wallCenter) * rotation, palette, "Wall", room)
			return
		end

		local segmentLength = (fullLength - DOOR_WIDTH) / 2
		if segmentLength <= 0 then
			return
		end

		for _, offsetSign in { -1, 1 } do
			local offset = offsetSign * (DOOR_WIDTH / 2 + segmentLength / 2)
			local segmentCenter = wallCenter + offsetAxis * offset
			createPart(
				Vector3.new(segmentLength, height, WALL_THICKNESS),
				CFrame.new(segmentCenter) * rotation,
				palette,
				"Wall",
				room
			)
		end
	end

	buildWall(true, 1, openSides.East)
	buildWall(true, -1, openSides.West)
	buildWall(false, 1, openSides.North)
	buildWall(false, -1, openSides.South)

	room.Parent = parent
	return room
end

return RoomTemplates
