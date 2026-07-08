--!strict
-- Forwards player intent to the server, which re-validates/debounces
-- authoritatively. Client-side debounce here is purely a UX nicety — it
-- never carries amounts, only requests.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local InputController = {}

-- Speed is earned by running (MovementService, server-side) — no click
-- request to forward here anymore.

function InputController.RequestLevelUp()
	Remotes.GetEvent(NetConstants.RequestLevelUp):FireServer()
end

function InputController.RequestRebirth()
	Remotes.GetEvent(NetConstants.RequestRebirth):FireServer()
end

function InputController.RequestStageTravel(stageId: string)
	Remotes.GetEvent(NetConstants.RequestStageTravel):FireServer(stageId)
end

function InputController.PromptPurchase(productId: number)
	Remotes.GetEvent(NetConstants.PromptPurchase):FireServer(productId)
end

function InputController.RequestLeaderboard(): { any }
	return Remotes.GetFunction(NetConstants.LeaderboardRequest):InvokeServer()
end

return InputController
