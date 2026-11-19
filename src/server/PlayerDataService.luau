-- PlayerDataService: one place holds every player's state — Cash, income,
-- rebirths, slap power, speed boosts and base locks — so no other service
-- keeps its own copy. Other services read and write through here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local PlayerDataService = {}

local playerData = {}

-- Create a fresh record when a player joins.
function PlayerDataService.createPlayerData(player)
	local data = {
		Cash = GameConfig.START_CASH,
		Rebirths = 0,
		SlapPower = 0,
		SpeedBoostUntil = 0,
		LuckyUntil = 0,
		BaseLockUntil = 0,
		BaseIndex = nil,
		Brainrots = {}, -- slot index -> { CharacterName, Mutation, Income }
		TotalEarned = 0,
		PlaytimeSeconds = 0,
		TotalStealsDefended = 0,
		BestSlapStreak = 0,
		SlapStreak = 0,
		Purchases = 0,
		MagnetUntil = 0,
		ShieldUntil = 0,
		BaseTier = 0,
	}
	playerData[player.UserId] = data
	return data
end

function PlayerDataService.getPlayerData(player)
	return playerData[player.UserId]
end

function PlayerDataService.removePlayerData(player)
	playerData[player.UserId] = nil
end

-- Earnings multiplier: +25% per rebirth, stacking.
function PlayerDataService.getEarningsMultiplier(player)
	local data = PlayerDataService.getPlayerData(player)
	if not data then
		return 1
	end
	return 1 + data.Rebirths * GameConfig.REBIRTH_MULTIPLIER_BONUS
end

-- Total income per second from every brainrot on the player's base.
function PlayerDataService.calculateIncomePerSecond(player)
	local data = PlayerDataService.getPlayerData(player)
	if not data then
		return 0
	end
	local total = 0
	for _, brainrot in pairs(data.Brainrots) do
		total += brainrot.Income
	end
	return math.floor(total * PlayerDataService.getEarningsMultiplier(player))
end

function PlayerDataService.addCash(player, amount)
	local data = PlayerDataService.getPlayerData(player)
	if not data then
		return
	end
	data.Cash += amount
	if amount > 0 then
		data.TotalEarned += amount
	end
end

-- Returns true and deducts, or false when the player cannot afford it.
function PlayerDataService.spendCash(player, amount)
	local data = PlayerDataService.getPlayerData(player)
	if not data or data.Cash < amount then
		return false
	end
	data.Cash -= amount
	return true
end

function PlayerDataService.hasSpeedBoost(player)
	local data = PlayerDataService.getPlayerData(player)
	return data and os.time() < data.SpeedBoostUntil
end

function PlayerDataService.hasLuckyCharm(player)
	local data = PlayerDataService.getPlayerData(player)
	return data and os.time() < data.LuckyUntil
end

function PlayerDataService.isBaseLocked(player)
	local data = PlayerDataService.getPlayerData(player)
	return data and os.time() < data.BaseLockUntil
end

function PlayerDataService.grantSpeedBoost(player, seconds)
	local data = PlayerDataService.getPlayerData(player)
	if data then
		data.SpeedBoostUntil = os.time() + seconds
	end
end

function PlayerDataService.grantLuckyCharm(player, seconds)
	local data = PlayerDataService.getPlayerData(player)
	if data then
		data.LuckyUntil = os.time() + seconds
	end
end

function PlayerDataService.lockBase(player, seconds)
	local data = PlayerDataService.getPlayerData(player)
	if data then
		data.BaseLockUntil = os.time() + seconds
	end
end

-- Rebirth: needs $1,000,000 cash. Resets cash and brainrots, grants a
-- permanent +25% earnings multiplier and a crown for the player's avatar.
function PlayerDataService.tryRebirth(player)
	local data = PlayerDataService.getPlayerData(player)
	if not data then
		return false, "No player data."
	end
	if data.Cash < GameConfig.REBIRTH_CASH_REQUIRED then
		return false, "Need $1,000,000 Cash to rebirth."
	end
	if data.Rebirths >= GameConfig.MAX_REBIRTHS then
		return false, "Max rebirths reached."
	end
	data.Cash = GameConfig.START_CASH
	data.Brainrots = {}
	data.Rebirths += 1
	return true, "Rebirth " .. data.Rebirths .. "! Earnings x" .. (1 + data.Rebirths * GameConfig.REBIRTH_MULTIPLIER_BONUS)
end

-- Give the reborn player a golden crown on their character.
function PlayerDataService.awardRebirthCrown(player)
	local character = player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	if head:FindFirstChild("RebirthCrown") then
		return
	end
	local crown = Instance.new("Part")
	crown.Name = "RebirthCrown"
	crown.Size = Vector3.new(1.6, 0.5, 1.6)
	crown.Position = head.Position + Vector3.new(0, 0.8, 0)
	crown.Color = Color3.fromRGB(255, 215, 0)
	crown.Material = Enum.Material.Neon
	crown.CanCollide = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = crown
	weld.Parent = crown
	crown.Parent = character
end

Players.PlayerRemoving:Connect(function(player)
	PlayerDataService.removePlayerData(player)
end)

-- Magnet active? Belt brainrots are 15% cheaper while it hums.
function PlayerDataService.hasMagnet(player)
	local data = PlayerDataService.getPlayerData(player)
	return data and os.time() < data.MagnetUntil
end

-- Shield active? The next tsunami cannot take this player's cash.
function PlayerDataService.hasShield(player)
	local data = PlayerDataService.getPlayerData(player)
	return data and os.time() < data.ShieldUntil
end

function PlayerDataService.grantMagnet(player, seconds)
	local data = PlayerDataService.getPlayerData(player)
	if data then
		data.MagnetUntil = os.time() + seconds
	end
end

function PlayerDataService.grantShield(player, seconds)
	local data = PlayerDataService.getPlayerData(player)
	if data then
		data.ShieldUntil = os.time() + seconds
	end
end

-- The magnet's belt discount, or 0 when the magnet is not humming.
function PlayerDataService.getMagnetDiscount(player)
	if PlayerDataService.hasMagnet(player) then
		return GameConfig.MAGNET_DISCOUNT
	end
	return 0
end

-- A thief was slapped away from this player's base: one defend for the board.
function PlayerDataService.addStealDefended(player)
	local data = PlayerDataService.getPlayerData(player)
	if data then
		data.TotalStealsDefended += 1
	end
end

-- Record a slap streak: the live streak follows the combo, the best is kept.
function PlayerDataService.noteSlapStreak(player, combo)
	local data = PlayerDataService.getPlayerData(player)
	if not data then
		return
	end
	data.SlapStreak = combo
	if combo > data.BestSlapStreak then
		data.BestSlapStreak = combo
	end
end

-- Playtime ticker: every second in the server adds a second to the record.
function PlayerDataService.startPlaytimeLoop()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local data = PlayerDataService.getPlayerData(player)
				if data then
					data.PlaytimeSeconds += 1
				end
			end
		end
	end)
end

-- A compact stats line for the HUD: playtime, defends, best streak.
function PlayerDataService.getStatsSummary(player)
	local data = PlayerDataService.getPlayerData(player)
	if not data then
		return "No stats yet"
	end
	return "Played " .. data.PlaytimeSeconds .. "s | Defended " .. data.TotalStealsDefended .. " | Best streak x" .. data.BestSlapStreak
end

return PlayerDataService
