--!strict
-- Top-N leaderboard panel: invokes LeaderboardRequest on open and on a slow
-- poll while visible (server serves from its own cache, never hits
-- DataStore per request).

local ClientRoot = script.Parent.Parent.Parent
local Theme = require(ClientRoot.Theme)
local InputController = require(ClientRoot.Controllers.InputController)
local ButtonComponent = require(ClientRoot.Components.ButtonComponent)
local PanelComponent = require(ClientRoot.Components.PanelComponent)

local POLL_INTERVAL = 60

local LeaderboardUI = {}

function LeaderboardUI.Init(screenGui: ScreenGui)
	local _, toggleClicked = ButtonComponent.new({
		Text = "Leaderboard",
		Size = UDim2.fromOffset(140, 40),
		Position = UDim2.fromOffset(16, 280),
		BackgroundColor = Theme.Shop,
		Parent = screenGui,
	})

	local panel, body = PanelComponent.new({
		Title = "Top Speed",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(260, 320),
		AccentColor = Theme.Shop,
		Parent = screenGui,
	})

	local list = Instance.new("Frame")
	list.Size = UDim2.new(1, -16, 1, -16)
	list.Position = UDim2.fromOffset(8, 8)
	list.BackgroundTransparency = 1
	list.Parent = body

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = list

	local function refresh()
		for _, child in list:GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end

		local entries = InputController.RequestLeaderboard()
		for rank, entry in entries do
			local row = Instance.new("TextLabel")
			row.Size = UDim2.new(1, 0, 0, 22)
			row.BackgroundTransparency = 1
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.Font = Enum.Font.GothamMedium
			row.TextScaled = true
			row.TextColor3 = Theme.TextDark
			row.Text = `{rank}. {entry.DisplayName} — {math.floor(entry.LifetimeSpeed)}`
			row.LayoutOrder = rank
			row.Parent = list
		end
	end

	local polling = false
	toggleClicked:Connect(function()
		panel.Visible = not panel.Visible
		if not panel.Visible then
			return
		end

		refresh()

		if not polling then
			polling = true
			task.spawn(function()
				while panel.Visible do
					task.wait(POLL_INTERVAL)
					if panel.Visible then
						refresh()
					end
				end
				polling = false
			end)
		end
	end)
end

return LeaderboardUI
