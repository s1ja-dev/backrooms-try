--!strict
-- Single source of truth for RemoteEvent/RemoteFunction instances. The
-- server creates them on boot; the client only ever looks them up (waits
-- for them to exist, never creates). No ad-hoc Instance.new("RemoteEvent")
-- anywhere else in the codebase — this is the only reusable piece any other
-- Roblox project would want verbatim regardless of genre.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NetConstants = require(script.Parent.NetConstants)

type RemoteKind = "RemoteEvent" | "RemoteFunction"

local REMOTE_KINDS: { [string]: RemoteKind } = {
	-- Speed is earned by moving (MovementService), not a click request.
	[NetConstants.CurrencyChanged] = "RemoteEvent",

	[NetConstants.RequestLevelUp] = "RemoteEvent",
	[NetConstants.LevelChanged] = "RemoteEvent",
	[NetConstants.LevelUpAnnounce] = "RemoteEvent",

	[NetConstants.RequestRebirth] = "RemoteEvent",
	[NetConstants.RebirthChanged] = "RemoteEvent",

	[NetConstants.RequestStageTravel] = "RemoteEvent",
	[NetConstants.StageChanged] = "RemoteEvent",

	[NetConstants.PersonalMonsterUpdate] = "RemoteEvent",
	[NetConstants.MonsterHit] = "RemoteEvent",

	[NetConstants.PromptPurchase] = "RemoteEvent",

	[NetConstants.LeaderboardRequest] = "RemoteFunction",

	[NetConstants.ProfileReady] = "RemoteEvent",
}

local Remotes = {}

local folder: Folder? = nil

local function getFolder(): Folder
	if folder then
		return folder
	end

	if RunService:IsServer() then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "Remotes"

		for name, kind in REMOTE_KINDS do
			local instance = Instance.new(kind)
			instance.Name = name
			instance.Parent = newFolder
		end

		newFolder.Parent = ReplicatedStorage
		folder = newFolder
		return newFolder
	end

	local existing = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	folder = existing
	return existing
end

function Remotes.GetEvent(name: string): RemoteEvent
	return getFolder():WaitForChild(name) :: RemoteEvent
end

function Remotes.GetFunction(name: string): RemoteFunction
	return getFolder():WaitForChild(name) :: RemoteFunction
end

return Remotes
