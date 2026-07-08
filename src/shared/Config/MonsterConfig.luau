--!strict
-- Monster archetypes. Direct-vector chase (no PathfindingService) by design
-- — see plan risk #5. Each zone in TestArenaConfig with Kind == "Monster"
-- references one of these by Id. Monsters are PERSONAL: each player who
-- enters the zone gets their own private instance of that type, chasing
-- only them, rendered only on their own client (see MonsterService +
-- PersonalMonsterController).

export type MonsterType = {
	Id: string,
	DisplayName: string,
	Color: Color3,
	Size: Vector3,
	ChaseSpeed: number, -- studs/s
	CatchDistance: number, -- studs; monster "catches" the player within this radius
	PenaltyPercent: number, -- fraction of current Speed removed on catch
	KnockbackForce: number,
	TouchDebounce: number, -- seconds before the same monster can catch again
}

local Types: { [string]: MonsterType } = {
	Slime = {
		Id = "Slime",
		DisplayName = "Slime",
		Color = Color3.fromRGB(70, 200, 90),
		Size = Vector3.new(3, 3, 3),
		ChaseSpeed = 12, -- slower than base WalkSpeed (16): easy to outrun once leveled at all
		CatchDistance = 4,
		PenaltyPercent = 0.08,
		KnockbackForce = 35,
		TouchDebounce = 1,
	},
	Wraith = {
		Id = "Wraith",
		DisplayName = "Wraith",
		Color = Color3.fromRGB(20, 20, 25),
		Size = Vector3.new(3, 7, 2),
		ChaseSpeed = 22, -- faster than base WalkSpeed: a real threat until you've leveled up
		CatchDistance = 4,
		PenaltyPercent = 0.2,
		KnockbackForce = 60,
		TouchDebounce = 1.5,
	},
}

local MonsterConfig = {
	Types = Types,
	-- How often the server recomputes/broadcasts each player's personal
	-- monster position. The client tweens between updates over the same
	-- duration, so this trades network chatter against visual smoothness.
	UpdateTickInterval = 0.15,
}

return MonsterConfig
