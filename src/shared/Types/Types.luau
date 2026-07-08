--!strict
-- Shared type aliases used across server/client modules. Stage/Product types
-- are colocated with and exported from their own Config modules instead
-- (StageConfig.StageDefinition, ProductConfig.ProductDefinition) since they
-- travel together with the data that defines them.

export type PlayerProfile = {
	SchemaVersion: number,
	Currency: {
		Speed: number,
		LifetimeSpeed: number,
	},
	Progression: {
		Level: number,
		WalkSpeedBase: number,
	},
	Rebirth: {
		RebirthCount: number,
		RebirthMultiplier: number,
	},
	Stages: {
		UnlockedStageIds: { string },
		CurrentStageId: string,
	},
	Monetization: {
		GrantedPurchaseIds: { [string]: boolean },
		LifetimeRobuxSpendEstimate: number,
	},
	Stats: {
		TotalMonsterHits: number,
		FirstJoinedAt: number,
		LastSavedAt: number,
	},
}

return {}
