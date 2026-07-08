--!strict
-- Level cost curve + WalkSpeed-per-level mapping.
-- cost(n) = BaseCost * CostGrowth^(n-1), rounded down.
-- WalkSpeed(n) = BaseWalkSpeed + (n-1) * WalkSpeedPerLevel, capped at MaxWalkSpeed.

local LevelConfig = {
	BaseCost = 10,
	CostGrowth = 1.12,

	BaseWalkSpeed = 16,
	WalkSpeedPerLevel = 0.75,
	MaxWalkSpeed = 60,
}

function LevelConfig.GetCostForLevel(level: number): number
	return math.floor(LevelConfig.BaseCost * LevelConfig.CostGrowth ^ (level - 1))
end

function LevelConfig.GetWalkSpeedForLevel(level: number): number
	local walkSpeed = LevelConfig.BaseWalkSpeed + (level - 1) * LevelConfig.WalkSpeedPerLevel
	return math.min(walkSpeed, LevelConfig.MaxWalkSpeed)
end

return LevelConfig
