--!strict
-- Developer product table. ProductId is a distinct negative placeholder in
-- every entry (real Roblox product IDs are always positive, so these can
-- never collide with a real one) — the place isn't published yet, so these
-- must be swapped for real Developer Product IDs from the Creator Dashboard
-- before MonetizationService can grant anything for real (see plan risk #8).
-- Previously every entry shared ProductId = 0, which made GetByProductId
-- resolve every tier to whichever came first in the list — distinct
-- placeholders avoid that regardless of publish status.

export type ProductEffectType = "SpeedBundle" | "InstantLevels" | "SpeedBundleWithWalkSpeedBonus"

export type ProductDefinition = {
	Tier: string,
	ProductId: number,
	RobuxPrice: number,
	EffectType: ProductEffectType,
	EffectAmount: number,
}

local Products: { ProductDefinition } = {
	{
		Tier = "Small",
		ProductId = -1, -- TODO: replace with real Developer Product ID (3 R$)
		RobuxPrice = 3,
		EffectType = "SpeedBundle",
		EffectAmount = 50,
	},
	{
		Tier = "Medium",
		ProductId = -2, -- TODO: replace with real Developer Product ID (145 R$)
		RobuxPrice = 145,
		EffectType = "SpeedBundle",
		EffectAmount = 3000,
	},
	{
		Tier = "Large",
		ProductId = -3, -- TODO: replace with real Developer Product ID (289 R$)
		RobuxPrice = 289,
		EffectType = "InstantLevels",
		EffectAmount = 10,
	},
	{
		Tier = "Mega",
		ProductId = -4, -- TODO: replace with real Developer Product ID (579 R$)
		RobuxPrice = 579,
		EffectType = "SpeedBundleWithWalkSpeedBonus",
		EffectAmount = 8000,
	},
}

local ProductConfig = {
	Products = Products,
}

function ProductConfig.GetByProductId(productId: number): ProductDefinition?
	for _, product in Products do
		if product.ProductId == productId then
			return product
		end
	end
	return nil
end

return ProductConfig
