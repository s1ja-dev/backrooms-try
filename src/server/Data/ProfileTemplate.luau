--!strict
-- Default profile shape + current schema version. DataService clones this
-- for new players; ProfileMigrations.luau reconciles it onto old saves.

local StageConfig = require(game:GetService("ReplicatedStorage").Shared.Config.StageConfig)

local Types = require(game:GetService("ReplicatedStorage").Shared.Types.Types)
type PlayerProfile = Types.PlayerProfile

local SCHEMA_VERSION = 1

local function newTemplate(): PlayerProfile
	return {
		SchemaVersion = SCHEMA_VERSION,
		Currency = {
			Speed = 0,
			LifetimeSpeed = 0,
		},
		Progression = {
			Level = 1,
			WalkSpeedBase = 16,
		},
		Rebirth = {
			RebirthCount = 0,
			RebirthMultiplier = 1.0,
		},
		Stages = {
			UnlockedStageIds = { StageConfig.DefaultStageId },
			CurrentStageId = StageConfig.DefaultStageId,
		},
		Monetization = {
			GrantedPurchaseIds = {},
			LifetimeRobuxSpendEstimate = 0,
		},
		Stats = {
			TotalMonsterHits = 0,
			FirstJoinedAt = 0,
			LastSavedAt = 0,
		},
	}
end

return {
	SchemaVersion = SCHEMA_VERSION,
	New = newTemplate,
}
