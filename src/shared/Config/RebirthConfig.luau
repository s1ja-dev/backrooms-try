--!strict
-- Rebirth gate + permanent multiplier formula. Linear curve chosen over an
-- exponential/logarithmic one for transparency and portfolio-readability —
-- easy to retune by changing MultiplierPerRebirth alone.

local RebirthConfig = {
	RequiredLevel = 25,
	MultiplierPerRebirth = 0.5,
}

function RebirthConfig.ComputeMultiplier(rebirthCount: number): number
	return 1 + rebirthCount * RebirthConfig.MultiplierPerRebirth
end

return RebirthConfig
