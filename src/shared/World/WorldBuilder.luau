--!strict
-- Procedural room-grid generator: given a StageDefinition (with Layout +
-- Palette), builds a Model of primitive-part rooms into a parent Instance.
-- Runs once server-side per active stage at boot. Reusable for any
-- low-art-budget indoor-level game — swap the palette/layout, get a new set
-- of rooms for free, no new code.

local StageConfig = require(script.Parent.Parent.Config.StageConfig)
local RoomTemplates = require(script.Parent.RoomTemplates)

type StageDefinition = StageConfig.StageDefinition

local WorldBuilder = {}

function WorldBuilder.Build(stage: StageDefinition, parent: Instance): Model
	assert(stage.Layout, `Stage '{stage.Id}' has no Layout — cannot build (IsImplemented should be false)`)
	assert(stage.Palette, `Stage '{stage.Id}' has no Palette — cannot build (IsImplemented should be false)`)

	local layout = stage.Layout :: StageConfig.StageLayout
	local palette = stage.Palette :: StageConfig.StagePalette

	local stageModel = Instance.new("Model")
	stageModel.Name = stage.Id

	local cellSpacing = layout.RoomSize.X + layout.CorridorWidth
	local gridWidth, gridDepth = layout.RoomGridSize.X, layout.RoomGridSize.Y

	-- Center the grid on the stage Origin.
	local halfSpanX = (gridWidth - 1) * cellSpacing / 2
	local halfSpanZ = (gridDepth - 1) * cellSpacing / 2

	for row = 0, gridDepth - 1 do
		for column = 0, gridWidth - 1 do
			local localOffset = CFrame.new(column * cellSpacing - halfSpanX, 0, row * cellSpacing - halfSpanZ)
			local cellCenter = (stage.Origin * localOffset).Position

			local openSides = {
				East = column < gridWidth - 1,
				West = column > 0,
				North = row < gridDepth - 1,
				South = row > 0,
			}

			local room = RoomTemplates.CreateBoxRoom(stageModel, cellCenter, layout.RoomSize, palette, openSides)
			room.Name = `Room_{row}_{column}`
		end
	end

	stageModel.Parent = parent
	return stageModel
end

return WorldBuilder
