--!strict
-- Per-zone color/material constants, consumed by WorldBuilder (parts) and
-- optionally by UI modules for stage-themed accents.

export type StagePalette = {
	Wall: Color3,
	Floor: Color3,
	Ceiling: Color3,
	Material: Enum.Material,
}

local PaletteConfig = {
	YellowRooms = {
		Wall = Color3.fromRGB(196, 173, 88),
		Floor = Color3.fromRGB(184, 160, 74),
		Ceiling = Color3.fromRGB(210, 190, 110),
		Material = Enum.Material.Concrete,
	} :: StagePalette,

	FloodedCorridors = {
		Wall = Color3.fromRGB(90, 104, 110),
		Floor = Color3.fromRGB(45, 74, 84),
		Ceiling = Color3.fromRGB(70, 82, 88),
		Material = Enum.Material.Concrete,
	} :: StagePalette,

	Offices = {
		Wall = Color3.fromRGB(196, 188, 172),
		Floor = Color3.fromRGB(140, 130, 116),
		Ceiling = Color3.fromRGB(220, 216, 206),
		Material = Enum.Material.SmoothPlastic,
	} :: StagePalette,
}

return PaletteConfig
