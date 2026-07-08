--!strict
-- Speed is earned by moving (running), not clicking. Gain is a FLAT rate
-- per tick while actively moving — deliberately NOT scaled by how far the
-- player actually moved, so a higher WalkSpeed (from leveling up) doesn't
-- also mean a higher currency-earn rate. Leveling still visibly increases
-- WalkSpeed; it just no longer compounds into faster Speed income too.
-- Server-authoritative: the client only ever reports its intent to move via
-- normal input, never a currency amount.

local EconomyConfig = {
	SpeedPerTick = 1, -- flat Speed granted per tick while actively moving
	MovementTickInterval = 0.25, -- seconds between movement samples
	MinMovementThreshold = 0.5, -- studs; below this in a tick, the player counts as stationary (no gain)
	MaxPlausibleStudsPerTick = 40, -- anti-cheat: a jump past this is a teleport/noclip, not real movement — sample dropped
	RunZoneMultiplier = 3,
}

return EconomyConfig
