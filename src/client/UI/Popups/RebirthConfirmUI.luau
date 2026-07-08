--!strict
-- Rebirth confirm dialog: a persistent "Rebirth" button opens a
-- confirmation panel previewing the multiplier gain (reads RebirthConfig
-- directly — safe client-side, it's just numbers) before firing
-- RequestRebirth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RebirthConfig = require(ReplicatedStorage.Shared.Config.RebirthConfig)

local ClientRoot = script.Parent.Parent.Parent
local Theme = require(ClientRoot.Theme)
local StateController = require(ClientRoot.Controllers.StateController)
local InputController = require(ClientRoot.Controllers.InputController)
local ButtonComponent = require(ClientRoot.Components.ButtonComponent)
local PanelComponent = require(ClientRoot.Components.PanelComponent)

local RebirthConfirmUI = {}

function RebirthConfirmUI.Init(screenGui: ScreenGui)
	local _, openClicked = ButtonComponent.new({
		Text = "Rebirth",
		Size = UDim2.fromOffset(140, 40),
		Position = UDim2.fromOffset(16, 232),
		BackgroundColor = Theme.Premium,
		Parent = screenGui,
	})

	local panel, body = PanelComponent.new({
		Title = "Rebirth",
		Size = UDim2.fromOffset(320, 200),
		AccentColor = Theme.Premium,
		Parent = screenGui,
	})

	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.Size = UDim2.new(1, -20, 0, 96)
	message.Position = UDim2.fromOffset(10, 8)
	message.BackgroundTransparency = 1
	message.TextWrapped = true
	message.TextColor3 = Theme.TextDark
	message.Font = Enum.Font.GothamMedium
	message.TextScaled = true
	message.Parent = body

	local _, confirmClicked = ButtonComponent.new({
		Text = "Confirm Rebirth",
		Size = UDim2.fromOffset(280, 44),
		Position = UDim2.fromOffset(20, 106),
		BackgroundColor = Theme.Premium,
		Parent = body,
	})

	local _, cancelClicked = ButtonComponent.new({
		Text = "Cancel",
		Size = UDim2.fromOffset(280, 30),
		Position = UDim2.fromOffset(20, 152),
		BackgroundColor = Theme.ChipBackground,
		Parent = body,
	})

	local currentRebirthCount = 0

	local function openPanel()
		local nextMultiplier = RebirthConfig.ComputeMultiplier(currentRebirthCount + 1)
		message.Text = `Rebirth resets your Speed and Level, but permanently sets your earn multiplier to x{string.format(
			"%.1f",
			nextMultiplier
		)}. Requires Level {RebirthConfig.RequiredLevel}.`
		panel.Visible = true
	end

	openClicked:Connect(openPanel)
	confirmClicked:Connect(function()
		InputController.RequestRebirth()
		panel.Visible = false
	end)
	cancelClicked:Connect(function()
		panel.Visible = false
	end)

	StateController.RebirthChanged:Connect(function(data: { RebirthCount: number })
		currentRebirthCount = data.RebirthCount
	end)

	StateController.Ready:Connect(function(state: StateController.Snapshot)
		currentRebirthCount = state.Rebirth.RebirthCount
	end)
end

return RebirthConfirmUI
