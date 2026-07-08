--!strict
-- Builds the flat, zoned test arena from TestArenaConfig. Temporary
-- stand-in for the full room-grid Backrooms map (WorldBuilder/RoomTemplates,
-- untouched and still ready to use) while core mechanics — movement-earn,
-- zones, monster variety — are being tested end to end.

local TestArenaConfig = require(script.Parent.Parent.Config.TestArenaConfig)

local TestArena = {}

function TestArena.Build(parent: Instance): Model
	local arena = Instance.new("Model")
	arena.Name = "TestArena"

	for _, zoneLayout in TestArenaConfig.Layout do
		local zone = zoneLayout.Definition

		local floor = Instance.new("Part")
		floor.Name = zone.Id .. "_Floor"
		floor.Anchored = true
		floor.CanCollide = true
		floor.Size = Vector3.new(zone.Size.X, TestArenaConfig.FloorThickness, zone.Size.Z)
		floor.CFrame = CFrame.new(zoneLayout.CenterX, TestArenaConfig.FloorY, 0)
		floor.Color = zone.Color
		floor.Material = Enum.Material.SmoothPlastic
		floor.Parent = arena

		local labelAnchor = Instance.new("Part")
		labelAnchor.Name = zone.Id .. "_Label"
		labelAnchor.Anchored = true
		labelAnchor.CanCollide = false
		labelAnchor.CanTouch = false
		labelAnchor.Transparency = 1
		labelAnchor.Size = Vector3.new(1, 1, 1)
		labelAnchor.CFrame = CFrame.new(zoneLayout.CenterX, TestArenaConfig.FloorY + 8, 0)
		labelAnchor.Parent = arena

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(200, 50)
		billboard.AlwaysOnTop = true
		billboard.Parent = labelAnchor

		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Text = zone.DisplayName
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.TextStrokeTransparency = 0
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.Parent = billboard
	end

	arena.Parent = parent
	return arena
end

return TestArena
