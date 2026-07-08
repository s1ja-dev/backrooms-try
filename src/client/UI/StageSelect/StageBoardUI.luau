--!strict
-- Stage board: renders every StageConfig entry. Implemented stages are
-- clickable travel buttons once unlocked; the 3 reserved future stages
-- render greyed-out with their unlock requirement — driven entirely by the
-- IsImplemented flag in config, no special-casing here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StageConfig = require(ReplicatedStorage.Shared.Config.StageConfig)

local ClientRoot = script.Parent.Parent.Parent
local StateController = require(ClientRoot.Controllers.StateController)
local InputController = require(ClientRoot.Controllers.InputController)
local ButtonComponent = require(ClientRoot.Components.ButtonComponent)

local UNLOCKED_COLOR = Color3.fromRGB(60, 90, 60)
local LOCKED_COLOR = Color3.fromRGB(70, 55, 40)
local FUTURE_COLOR = Color3.fromRGB(50, 50, 55)

local StageBoardUI = {}

function StageBoardUI.Init(screenGui: ScreenGui)
	local _, toggleClicked = ButtonComponent.new({
		Text = "Stages",
		Size = UDim2.fromOffset(140, 40),
		Position = UDim2.fromOffset(16, 296),
		Parent = screenGui,
		BackgroundColor = Color3.fromRGB(150, 110, 40),
	})

	local panel = Instance.new("Frame")
	panel.Name = "StageBoardPanel"
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, 16, 0.5, 0)
	panel.Size = UDim2.fromOffset(260, 360)
	panel.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	panel.Visible = false
	panel.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local list = Instance.new("Frame")
	list.Size = UDim2.new(1, -16, 1, -16)
	list.Position = UDim2.fromOffset(8, 8)
	list.BackgroundTransparency = 1
	list.Parent = panel

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = list

	local unlockedIds: { [string]: boolean } = {}
	local rows: { [string]: TextButton } = {}

	for index, stage in StageConfig.Stages do
		local label = if stage.IsImplemented
			then `{stage.DisplayName} (Lv. {stage.UnlockLevel})`
			else `{stage.DisplayName} — Coming Soon (Lv. {stage.UnlockLevel})`

		local button, clicked = ButtonComponent.new({
			Text = label,
			Size = UDim2.new(1, 0, 0, 40),
			LayoutOrder = index,
			Parent = list,
			BackgroundColor = if stage.IsImplemented then LOCKED_COLOR else FUTURE_COLOR,
		})

		rows[stage.Id] = button

		clicked:Connect(function()
			if stage.IsImplemented and unlockedIds[stage.Id] then
				InputController.RequestStageTravel(stage.Id)
				panel.Visible = false
			end
		end)
	end

	local function refreshUnlocked(unlockedStageIds: { string })
		unlockedIds = {}
		for _, id in unlockedStageIds do
			unlockedIds[id] = true
		end

		for _, stage in StageConfig.Stages do
			local button = rows[stage.Id]
			if button and stage.IsImplemented then
				button.BackgroundColor3 = if unlockedIds[stage.Id] then UNLOCKED_COLOR else LOCKED_COLOR
			end
		end
	end

	StateController.Ready:Connect(function(state: StateController.Snapshot)
		refreshUnlocked(state.Stages.UnlockedStageIds)
	end)
	StateController.StageChanged:Connect(function(data: { UnlockedStageIds: { string } })
		refreshUnlocked(data.UnlockedStageIds)
	end)

	toggleClicked:Connect(function()
		panel.Visible = not panel.Visible
	end)
end

return StageBoardUI
