--!strict
-- Top-level HUD: currency/level readouts, current-zone readout (computed
-- locally from the player's own position — TestArenaConfig is shared data,
-- no server round-trip needed for a cosmetic label), level-up button.
-- Subscribes to StateController only for server-authoritative state — never
-- touches remotes directly.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LevelConfig = require(ReplicatedStorage.Shared.Config.LevelConfig)
local TestArenaConfig = require(ReplicatedStorage.Shared.Config.TestArenaConfig)

local ClientRoot = script.Parent.Parent.Parent
local Theme = require(ClientRoot.Theme)
local StateController = require(ClientRoot.Controllers.StateController)
local InputController = require(ClientRoot.Controllers.InputController)
local ButtonComponent = require(ClientRoot.Components.ButtonComponent)
local CurrencyLabel = require(script.Parent.CurrencyLabel)

local ZONE_POLL_INTERVAL = 0.25
local PUNCH_UP_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local PUNCH_SETTLE_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local FLOAT_UP_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local HUDController = {}

local function formatNumber(value: number): string
	return tostring(math.floor(value))
end

-- Quick scale-bounce on the stat number itself, reusing the ButtonComponent
-- hover/click convention of animating a UIScale rather than Size so the
-- surrounding UIListLayout never reflows.
local function punchScale(scale: UIScale)
	TweenService:Create(scale, PUNCH_UP_INFO, { Scale = 1.3 }):Play()
	task.delay(PUNCH_UP_INFO.Time, function()
		TweenService:Create(scale, PUNCH_SETTLE_INFO, { Scale = 1 }):Play()
	end)
end

-- Floating "+N" that rises and fades next to the Speed tile — the actual
-- "pribavka" feedback the movement-earning loop needs to feel alive.
local function spawnFloatingGain(tile: Frame, amount: number)
	local floatLabel = Instance.new("TextLabel")
	floatLabel.Name = "FloatingGain"
	floatLabel.AnchorPoint = Vector2.new(0, 0.5)
	floatLabel.Position = UDim2.new(1, 8, 0.5, 0)
	floatLabel.Size = UDim2.fromOffset(56, 26)
	floatLabel.BackgroundTransparency = 1
	floatLabel.Text = `+{formatNumber(amount)}`
	floatLabel.Font = Enum.Font.GothamBlack
	floatLabel.TextScaled = true
	floatLabel.TextColor3 = Theme.Success
	floatLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	floatLabel.TextStrokeTransparency = 0.4
	floatLabel.ZIndex = 5
	floatLabel.Parent = tile

	local startPosition = floatLabel.Position
	TweenService:Create(floatLabel, FLOAT_UP_INFO, {
		Position = startPosition + UDim2.fromOffset(0, -22),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()

	task.delay(FLOAT_UP_INFO.Time, function()
		floatLabel:Destroy()
	end)
end

local function startZonePolling(zoneValueLabel: TextLabel)
	task.spawn(function()
		while true do
			task.wait(ZONE_POLL_INTERVAL)

			local character = Players.LocalPlayer.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local zoneLayout = TestArenaConfig.GetZoneAt((rootPart :: BasePart).Position)
				zoneValueLabel.Text = if zoneLayout then zoneLayout.Definition.DisplayName else "—"
			end
		end
	end)
end

function HUDController.Init(screenGui: ScreenGui)
	local root = Instance.new("Frame")
	root.Name = "HUD"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = screenGui

	local statsList = Instance.new("Frame")
	statsList.Name = "Stats"
	statsList.Size = UDim2.fromOffset(200, 176)
	statsList.Position = UDim2.fromOffset(16, 16)
	statsList.BackgroundTransparency = 1
	statsList.Parent = root

	local statsLayout = Instance.new("UIListLayout")
	statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statsLayout.Padding = UDim.new(0, 8)
	statsLayout.Parent = statsList

	local speedTile, speedValueLabel, speedValueScale = CurrencyLabel.new({
		Caption = "Speed",
		AccentColor = Theme.Success,
		LayoutOrder = 1,
		Parent = statsList,
	})
	local _, levelValueLabel = CurrencyLabel.new({
		Caption = "Level",
		AccentColor = Theme.Info,
		LayoutOrder = 2,
		Parent = statsList,
	})
	local _, zoneValueLabel = CurrencyLabel.new({
		Caption = "Zone",
		AccentColor = Theme.Warning,
		LayoutOrder = 3,
		Parent = statsList,
	})

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Size = UDim2.fromOffset(220, 24)
	hint.Position = UDim2.fromOffset(16, 200)
	hint.BackgroundTransparency = 1
	hint.Text = "Run to earn Speed!"
	hint.TextColor3 = Theme.TextMuted
	hint.TextStrokeColor3 = Color3.new(0, 0, 0)
	hint.TextStrokeTransparency = 0.6
	hint.Font = Enum.Font.GothamBold
	hint.TextScaled = true
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Parent = root

	local actions = Instance.new("Frame")
	actions.Name = "Actions"
	actions.Size = UDim2.fromOffset(180, 56)
	actions.AnchorPoint = Vector2.new(1, 1)
	actions.Position = UDim2.new(1, -16, 1, -16)
	actions.BackgroundTransparency = 1
	actions.Parent = root

	local levelUpButton, levelUpClicked = ButtonComponent.new({
		Text = "Level Up",
		Size = UDim2.fromOffset(180, 48),
		BackgroundColor = Theme.Info,
		Parent = actions,
	})
	levelUpClicked:Connect(InputController.RequestLevelUp)

	local previousSpeed: number? = nil

	local function refreshCurrency(data: { Speed: number })
		local delta = if previousSpeed then data.Speed - previousSpeed else 0
		speedValueLabel.Text = formatNumber(data.Speed)

		if delta > 0 then
			punchScale(speedValueScale)
			spawnFloatingGain(speedTile, delta)
		end

		previousSpeed = data.Speed
	end

	local function refreshLevel(data: { Level: number })
		levelValueLabel.Text = tostring(data.Level)
		local cost = LevelConfig.GetCostForLevel(data.Level)
		levelUpButton.Text = `Level Up ({formatNumber(cost)})`
	end

	StateController.Ready:Connect(function(state: StateController.Snapshot)
		refreshCurrency(state.Currency)
		refreshLevel(state.Progression)
	end)
	StateController.CurrencyChanged:Connect(refreshCurrency)
	StateController.LevelChanged:Connect(refreshLevel)

	local currentState = StateController.State
	if currentState then
		refreshCurrency(currentState.Currency)
		refreshLevel(currentState.Progression)
	end

	startZonePolling(zoneValueLabel)
end

return HUDController
