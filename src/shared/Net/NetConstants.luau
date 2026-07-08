--!strict
-- String identifiers for every remote. Kept separate from Remotes.luau so
-- both server and client can reference names without pulling in the
-- Instance-creation logic.

local NetConstants = {
	-- Speed is earned by moving (MovementService), not a click request.
	CurrencyChanged = "CurrencyChanged",

	RequestLevelUp = "RequestLevelUp",
	LevelChanged = "LevelChanged",
	LevelUpAnnounce = "LevelUpAnnounce",

	RequestRebirth = "RequestRebirth",
	RebirthChanged = "RebirthChanged",

	RequestStageTravel = "RequestStageTravel",
	StageChanged = "StageChanged",

	-- Fired only to the owning player: their personal monster's current
	-- state/position (see MonsterService + PersonalMonsterController).
	PersonalMonsterUpdate = "PersonalMonsterUpdate",
	MonsterHit = "MonsterHit",

	PromptPurchase = "PromptPurchase",

	LeaderboardRequest = "LeaderboardRequest",

	ProfileReady = "ProfileReady",
}

return NetConstants
