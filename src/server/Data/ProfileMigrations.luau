--!strict
-- Ordered list of migration functions keyed by version. Currently a stub —
-- SchemaVersion 1 is the only version that has ever existed — but
-- DataService always runs loaded profiles through here, so a future
-- breaking schema change has a clear, tested place to land without
-- touching load/save logic itself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local ProfileTemplate = require(script.Parent.ProfileTemplate)

local Types = require(ReplicatedStorage.Shared.Types.Types)
type PlayerProfile = Types.PlayerProfile

local ProfileMigrations = {}

-- migrations[n] transforms a profile from SchemaVersion n to n+1. Run in
-- order starting from the profile's own SchemaVersion.
local migrations: { [number]: (profile: PlayerProfile) -> () } = {}

function ProfileMigrations.Apply(profile: PlayerProfile): PlayerProfile
	for version = profile.SchemaVersion + 1, ProfileTemplate.SchemaVersion do
		local migrate = migrations[version - 1]
		if migrate then
			migrate(profile)
		end
		profile.SchemaVersion = version
	end

	-- Backfill any additive fields introduced without a dedicated migration,
	-- using the current template as the source of truth. Never overwrites
	-- existing values.
	TableUtil.Reconcile(profile, ProfileTemplate.New())

	return profile
end

return ProfileMigrations
