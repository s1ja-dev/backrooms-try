--!strict
-- Client bootstrap: initializes StateController first (so every remote is
-- already being listened to before any UI needs it), builds the root
-- ScreenGui, then initializes every UI module.

local Players = game:GetService("Players")

local StateController = require(script.Parent.Controllers.StateController)
local PersonalMonsterController = require(script.Parent.Controllers.PersonalMonsterController)

local HUDController = require(script.Parent.UI.HUD.HUDController)
local LevelUpPopup = require(script.Parent.UI.Popups.LevelUpPopup)
local RebirthConfirmUI = require(script.Parent.UI.Popups.RebirthConfirmUI)
local ShopUI = require(script.Parent.UI.Shop.ShopUI)
local LeaderboardUI = require(script.Parent.UI.Leaderboard.LeaderboardUI)
-- StageBoardUI is not wired in for now — the room-grid stage system it
-- travels between is on hold while core mechanics are being tested (see
-- StageService.luau). The module itself is untouched and ready to come back.

local ClientMain = {}

function ClientMain.Start()
	StateController.Init()
	PersonalMonsterController.Init()

	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	HUDController.Init(screenGui)
	LevelUpPopup.Init(screenGui)
	RebirthConfirmUI.Init(screenGui)
	ShopUI.Init(screenGui)
	LeaderboardUI.Init(screenGui)
end

return ClientMain
