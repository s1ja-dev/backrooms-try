--!strict
-- Transient "Level Up!" popup. Subscribes only to LevelUpAnnounced —
-- deliberately decoupled from LevelChanged/state-sync so celebratory FX
-- can never get tangled with state rendering. Rendered as a chunky colored
-- badge (not bare floating text) to match the reference "reward" callouts.

local TweenService = game:GetService("TweenService")

local ClientRoot = script.Parent.Parent.Parent
local Theme = require(ClientRoot.Theme)
local StateController = require(ClientRoot.Controllers.StateController)

local LevelUpPopup = {}

function LevelUpPopup.Init(screenGui: ScreenGui)
	local badge = Instance.new("Frame")
	badge.Name = "LevelUpBadge"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(0.5, 0.4)
	badge.Size = UDim2.fromOffset(320, 70)
	badge.BackgroundColor3 = Theme.Warning
	badge.BackgroundTransparency = 1
	badge.BorderSizePixel = 0
	badge.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = badge

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Theme.Darken(Theme.Warning, 0.55)
	stroke.Transparency = 1
	stroke.Parent = badge

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Theme.TextLight
	label.TextTransparency = 1
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.5
	label.Text = ""
	label.Parent = badge

	StateController.LevelUpAnnounced:Connect(function(data: { NewLevel: number })
		label.Text = `Level Up! ({data.NewLevel})`
		badge.BackgroundTransparency = 0
		stroke.Transparency = 0
		label.TextTransparency = 0
		badge.Position = UDim2.fromScale(0.5, 0.4)

		TweenService:Create(badge, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5, 0.32),
		}):Play()

		task.delay(1.1, function()
			TweenService:Create(badge, TweenInfo.new(0.4), {
				BackgroundTransparency = 1,
			}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
			TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		end)
	end)
end

return LevelUpPopup
