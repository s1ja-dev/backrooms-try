--!strict
-- Renders ProductConfig as a row of buy buttons; asks the server to prompt
-- the purchase so productId gets validated before Roblox's purchase UI
-- opens (see MonetizationService.onPromptPurchase). Each tier gets a
-- distinct accent color, matching how reference shop UIs color-code rarity.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProductConfig = require(ReplicatedStorage.Shared.Config.ProductConfig)

local ClientRoot = script.Parent.Parent.Parent
local Theme = require(ClientRoot.Theme)
local InputController = require(ClientRoot.Controllers.InputController)
local ButtonComponent = require(ClientRoot.Components.ButtonComponent)

local TIER_COLORS = { Theme.Success, Theme.Info, Theme.Premium, Theme.Warning }

local ShopUI = {}

function ShopUI.Init(screenGui: ScreenGui)
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Shop"
	backdrop.AnchorPoint = Vector2.new(0.5, 0)
	backdrop.Position = UDim2.new(0.5, 0, 0, 12)
	backdrop.Size = UDim2.fromOffset(584, 80)
	backdrop.BackgroundColor3 = Theme.ChipBackground
	backdrop.BackgroundTransparency = 0.15
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = backdrop

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = backdrop

	for index, product in ProductConfig.Products do
		local _, clicked = ButtonComponent.new({
			Text = `{product.Tier}\n{product.RobuxPrice} R$`,
			Size = UDim2.fromOffset(130, 64),
			LayoutOrder = index,
			Parent = backdrop,
			BackgroundColor = TIER_COLORS[(index - 1) % #TIER_COLORS + 1],
		})

		clicked:Connect(function()
			InputController.PromptPurchase(product.ProductId)
		end)
	end
end

return ShopUI
