--!strict
-- Small numeric helpers shared by Level/Rebirth/Monster config formulas.

local MathUtil = {}

function MathUtil.Clamp(value: number, min: number, max: number): number
	if value < min then
		return min
	elseif value > max then
		return max
	end
	return value
end

function MathUtil.Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

function MathUtil.Round(value: number): number
	return math.floor(value + 0.5)
end

return MathUtil
