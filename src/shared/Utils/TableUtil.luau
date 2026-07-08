--!strict
-- Deep copy / reconcile helpers, used mainly for cloning the default profile
-- template so DataStore reads never mutate the shared template table.

local TableUtil = {}

function TableUtil.DeepCopy<T>(source: T): T
	if type(source) ~= "table" then
		return source
	end

	local copy = {}
	for key, value in pairs(source :: any) do
		copy[key] = TableUtil.DeepCopy(value)
	end

	return (copy :: any) :: T
end

-- Fills in any keys missing from `target` (recursively) using `defaults`,
-- without overwriting existing values. Used by ProfileMigrations to
-- backfill new fields onto old saved profiles.
function TableUtil.Reconcile<T>(target: T, defaults: T): T
	for key, defaultValue in pairs(defaults :: any) do
		local targetValue = (target :: any)[key]
		if targetValue == nil then
			(target :: any)[key] = TableUtil.DeepCopy(defaultValue)
		elseif type(defaultValue) == "table" and type(targetValue) == "table" then
			TableUtil.Reconcile(targetValue, defaultValue)
		end
	end
	return target
end

return TableUtil
