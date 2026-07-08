--!strict
-- Single client-side cache of server-pushed state + Signals for UI to
-- subscribe to. UI modules never touch remotes directly — everything flows
-- through here. Remotes -> StateController -> UI (render-only) is the one
-- direction data moves on the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local Signal = require(ReplicatedStorage.Shared.Classes.Signal)

-- Named Snapshot (not State) to avoid colliding with the StateController.State
-- *value* field below — Luau resolves type-position vs value-position uses
-- of the same name fine, but a distinct name is less confusing to read.
export type Snapshot = {
	Currency: { Speed: number, LifetimeSpeed: number },
	Progression: { Level: number, WalkSpeedBase: number },
	Rebirth: { RebirthCount: number, RebirthMultiplier: number },
	Stages: { UnlockedStageIds: { string }, CurrentStageId: string },
}

local StateController = {}

StateController.State = nil :: Snapshot?

StateController.Ready = Signal.new()
StateController.CurrencyChanged = Signal.new()
StateController.LevelChanged = Signal.new()
StateController.LevelUpAnnounced = Signal.new()
StateController.RebirthChanged = Signal.new()
StateController.StageChanged = Signal.new()
StateController.MonsterHit = Signal.new()

function StateController.Init()
	Remotes.GetEvent(NetConstants.ProfileReady).OnClientEvent:Connect(function(snapshot: Snapshot)
		StateController.State = snapshot
		StateController.Ready:Fire(snapshot)
	end)

	Remotes.GetEvent(NetConstants.CurrencyChanged).OnClientEvent:Connect(function(data: any)
		local state = StateController.State
		if state then
			state.Currency = data
		end
		StateController.CurrencyChanged:Fire(data)
	end)

	Remotes.GetEvent(NetConstants.LevelChanged).OnClientEvent:Connect(function(data: any)
		local state = StateController.State
		if state then
			state.Progression = data
		end
		StateController.LevelChanged:Fire(data)
	end)

	Remotes.GetEvent(NetConstants.LevelUpAnnounce).OnClientEvent:Connect(function(data: any)
		StateController.LevelUpAnnounced:Fire(data)
	end)

	Remotes.GetEvent(NetConstants.RebirthChanged).OnClientEvent:Connect(function(data: any)
		local state = StateController.State
		if state then
			state.Rebirth = data
		end
		StateController.RebirthChanged:Fire(data)
	end)

	Remotes.GetEvent(NetConstants.StageChanged).OnClientEvent:Connect(function(data: any)
		local state = StateController.State
		if state then
			state.Stages = data
		end
		StateController.StageChanged:Fire(data)
	end)

	Remotes.GetEvent(NetConstants.MonsterHit).OnClientEvent:Connect(function(data: any)
		StateController.MonsterHit:Fire(data)
	end)
end

return StateController
