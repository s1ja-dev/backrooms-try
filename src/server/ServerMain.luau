--!strict
-- Orchestrates service initialization order and the shared Remotes-folder
-- bootstrap. This is the only module that knows about every service —
-- individual services never require each other's siblings beyond their
-- direct dependencies.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local DataService = require(script.Parent.Services.DataService)
local CurrencyService = require(script.Parent.Services.CurrencyService)
local MovementService = require(script.Parent.Services.MovementService)
local LevelService = require(script.Parent.Services.LevelService)
local RebirthService = require(script.Parent.Services.RebirthService)
local StageService = require(script.Parent.Services.StageService)
local MonsterService = require(script.Parent.Services.MonsterService)
local MonetizationService = require(script.Parent.Services.MonetizationService)
local LeaderboardService = require(script.Parent.Services.LeaderboardService)

local ServerMain = {}

function ServerMain.Start()
	-- Touching any remote up front forces the whole Remotes folder to be
	-- created before any service could otherwise race to create it lazily.
	Remotes.GetEvent(NetConstants.ProfileReady)

	DataService.Init()
	CurrencyService.Init()
	MovementService.Init()
	LevelService.Init()
	RebirthService.Init()
	StageService.Init()
	MonsterService.Init()
	MonetizationService.Init()
	LeaderboardService.Init()
end

return ServerMain
