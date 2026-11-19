-- ShopService: the shop and the rebirth altar. Players spend Cash on slap
-- power, speed boosts, lucky charms and base locks, and rebirth at the
-- altar once they hold $1,000,000. All purchases go through RemoteEvents
-- the client fires; every price is checked again on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlayerDataService = require(script.Parent.PlayerDataService)
local BaseService = require(script.Parent.BaseService)

local ShopService = {}

-- Buy one shop item by its key in GameConfig.SHOP.
function ShopService.buyItem(player, itemKey)
	local item = GameConfig.SHOP[itemKey]
	if not item then
		return false, "That item does not exist."
	end
	local data = PlayerDataService.getPlayerData(player)
	if not data then
		return false, "No player data."
	end
	local price = ShopService.getEffectivePrice(player, item)
	if data.Cash < price then
		return false, "Not enough Cash for " .. item.Name .. "."
	end
	if not PlayerDataService.spendCash(player, price) then
		return false, "Could not pay."
	end
	data.Purchases += 1
	if itemKey == "SlapPower" then
		data.SlapPower += 1
		return true, "Slap Power is now level " .. data.SlapPower .. "!"
	elseif itemKey == "SpeedBoost" then
		PlayerDataService.grantSpeedBoost(player, 60)
		ShopService.applyWalkSpeed(player)
		return true, "Speed Boost active for 60 seconds!"
	elseif itemKey == "LuckyCharm" then
		PlayerDataService.grantLuckyCharm(player, 60)
		return true, "Lucky Charm active: better mutations for 60 seconds!"
	elseif itemKey == "BaseLock" then
		PlayerDataService.lockBase(player, GameConfig.BASE_LOCK_DURATION)
		local baseIndex = BaseService.getBaseIndex(player)
		if baseIndex then
			BaseService.setLockGateVisible(baseIndex, true)
			task.delay(GameConfig.BASE_LOCK_DURATION, function()
				BaseService.setLockGateVisible(baseIndex, false)
			end)
		end
		return true, "Base Lock active for 2 minutes! Thieves cannot enter."
	elseif itemKey == "Magnet" then
		PlayerDataService.grantMagnet(player, GameConfig.MAGNET_DURATION)
		return true, "Cash Magnet active for 60 seconds! Belt brainrots are 15% cheaper."
	elseif itemKey == "Shield" then
		PlayerDataService.grantShield(player, GameConfig.SHIELD_DURATION)
		return true, "Sauce Shield active for 60 seconds! The next tsunami cannot take your cash."
	end
	return true, "Bought " .. item.Name .. "."
end

-- Set the player's walk speed from their boost state.
function ShopService.applyWalkSpeed(player)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if PlayerDataService.hasSpeedBoost(player) then
		humanoid.WalkSpeed = 24
	else
		humanoid.WalkSpeed = 16
	end
end

-- Rebirth: resets cash and brainrots, grants +25% earnings and a crown.
function ShopService.tryRebirth(player)
	local ok, message = PlayerDataService.tryRebirth(player)
	if not ok then
		return false, message
	end
	BaseService.clearBase(player)
	PlayerDataService.awardRebirthCrown(player)
	return true, message
end

-- Wire the RemoteEvents the client uses to buy and rebirth.
function ShopService.bindRemotes()
	local buyEvent = ReplicatedStorage:WaitForChild("BuyShopItem")
	buyEvent.OnServerEvent:Connect(function(player, itemKey)
		local ok, message = ShopService.buyItem(player, itemKey)
		local notify = ReplicatedStorage:FindFirstChild("NotifyPlayer")
		if notify then
			notify:FireClient(player, message)
		end
	end)
	local rebirthEvent = ReplicatedStorage:WaitForChild("RequestRebirth")
	rebirthEvent.OnServerEvent:Connect(function(player)
		local ok, message = ShopService.tryRebirth(player)
		local notify = ReplicatedStorage:FindFirstChild("NotifyPlayer")
		if notify then
			notify:FireClient(player, message)
		end
	end)
	local upgradeEvent = ReplicatedStorage:WaitForChild("BuyBaseUpgrade")
	upgradeEvent.OnServerEvent:Connect(function(player)
		local ok, message = BaseService.buyBaseUpgrade(player)
		local notify = ReplicatedStorage:FindFirstChild("NotifyPlayer")
		if notify then
			notify:FireClient(player, message)
		end
	end)
end

-- Loyalty price: the fifth, tenth, fifteenth... purchase is 10% cheaper,
-- so regular shoppers get a break. Counted from purchases already made.
function ShopService.getEffectivePrice(player, item)
	local data = PlayerDataService.getPlayerData(player)
	if data and data.Purchases % GameConfig.LOYALTY_PURCHASES_FOR_DISCOUNT == GameConfig.LOYALTY_PURCHASES_FOR_DISCOUNT - 1 then
		return math.floor(item.Price * (1 - GameConfig.LOYALTY_DISCOUNT))
	end
	return item.Price
end

return ShopService
