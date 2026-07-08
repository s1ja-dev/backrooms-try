--!strict
-- MarketplaceService.ProcessReceipt with idempotent purchase granting
-- (records PurchaseId in the profile to guard against Roblox's known
-- double-grant-on-retry issue). Reusable near-verbatim in any game with dev
-- products, regardless of genre.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local ProductConfig = require(ReplicatedStorage.Shared.Config.ProductConfig)

local DataService = require(script.Parent.DataService)
local CurrencyService = require(script.Parent.CurrencyService)
local LevelService = require(script.Parent.LevelService)

type ReceiptInfo = {
	PlayerId: number,
	PurchaseId: string,
	ProductId: number,
	CurrencySpent: number,
	CurrencyType: Enum.CurrencyType,
	PlaceIdWherePurchased: number,
}

local MonetizationService = {}

-- Simplification: the "Mega" tier's WalkSpeed-bonus flavor is delivered as
-- a handful of bonus levels (Level already maps to WalkSpeed via
-- LevelConfig) rather than inventing a separate untracked permanent-bonus
-- field in the profile schema.
local WALK_SPEED_BONUS_LEVELS = 3

local function grantProduct(player: Player, product: ProductConfig.ProductDefinition)
	if product.EffectType == "SpeedBundle" then
		CurrencyService.Add(player, product.EffectAmount)
	elseif product.EffectType == "InstantLevels" then
		LevelService.AddLevels(player, product.EffectAmount)
	elseif product.EffectType == "SpeedBundleWithWalkSpeedBonus" then
		CurrencyService.Add(player, product.EffectAmount)
		LevelService.AddLevels(player, WALK_SPEED_BONUS_LEVELS)
	end

	local profile = DataService.GetProfile(player)
	if profile then
		profile.Monetization.LifetimeRobuxSpendEstimate += product.RobuxPrice
	end
end

local function processReceipt(receiptInfo: ReceiptInfo): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player has left; rely on Roblox's automatic retry (up to 3 days)
		-- rather than a separate pending-grants queue — see plan risk #7.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if not DataService.IsLoaded(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = DataService.GetProfile(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if profile.Monetization.GrantedPurchaseIds[receiptInfo.PurchaseId] then
		-- Already granted in a previous call; acknowledging again is safe
		-- (idempotent) and protects against Roblox's double-grant retries.
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local product = ProductConfig.GetByProductId(receiptInfo.ProductId)
	if not product then
		warn(`MonetizationService: unknown ProductId {receiptInfo.ProductId} in receipt {receiptInfo.PurchaseId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok = pcall(grantProduct, player, product)
	if not ok then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	profile.Monetization.GrantedPurchaseIds[receiptInfo.PurchaseId] = true
	DataService.ForceSave(player)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Client asks the server to prompt a purchase rather than calling
-- MarketplaceService:PromptProductPurchase directly, so the productId gets
-- validated against ProductConfig before Roblox's purchase UI ever opens.
local function onPromptPurchase(player: Player, productId: any)
	if typeof(productId) ~= "number" then
		return
	end

	if not ProductConfig.GetByProductId(productId) then
		return
	end

	MarketplaceService:PromptProductPurchase(player, productId)
end

function MonetizationService.Init()
	MarketplaceService.ProcessReceipt = processReceipt

	local promptPurchase = Remotes.GetEvent(NetConstants.PromptPurchase)
	promptPurchase.OnServerEvent:Connect(onPromptPurchase)
end

return MonetizationService
