-- Brainrot Bazaar: server entry point.
-- Builds the 3D world, creates the RemoteEvents the client talks through,
-- gives each joining player a base and starting cash, and starts every
-- service loop: the conveyor, the thieves, the sauce tsunami, income,
-- the shop, slapping and the leaderboard.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local FormatMoney = require(Shared:WaitForChild("FormatMoney"))

local WorldBuilder = require(script.Parent.WorldBuilder)
local PlayerDataService = require(script.Parent.PlayerDataService)
local BaseService = require(script.Parent.BaseService)
local ConveyorService = require(script.Parent.ConveyorService)
local ThiefService = require(script.Parent.ThiefService)
local TsunamiService = require(script.Parent.TsunamiService)
local ShopService = require(script.Parent.ShopService)
local SlapService = require(script.Parent.SlapService)
local LeaderboardService = require(script.Parent.LeaderboardService)

print("Brainrot Bazaar server starting...")

-- RemoteEvents the client uses. Created here so the client can always
-- WaitForChild them, even if it loads before the services start.
local function createRemoteEvent(name)
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = ReplicatedStorage
	return event
end

createRemoteEvent("NotifyPlayer")
createRemoteEvent("TsunamiEvent")
createRemoteEvent("SlapEvent")
createRemoteEvent("LeaderboardUpdate")
createRemoteEvent("HudUpdate")
createRemoteEvent("BuyShopItem")
createRemoteEvent("RequestRebirth")
createRemoteEvent("RequestSlap")

-- Build the world first: plaza, conveyor, eight bases, decorations.
local world = WorldBuilder.buildWorld()
print("Bazaar world built: " .. #world.Plots .. " base plots around the plaza.")

BaseService.init(world)
ConveyorService.init(world)
ThiefService.init()
TsunamiService.init(world)
ShopService.bindRemotes()
SlapService.bindRemotes()

-- Send the HUD its numbers twice a second: cash, income, wave timer,
-- base lock state and rebirth progress.
local function sendHudUpdate(player)
	local data = PlayerDataService.getPlayerData(player)
	if not data then
		return
	end
	local event = ReplicatedStorage:FindFirstChild("HudUpdate")
	if not event then
		return
	end
	event:FireClient(player, {
		Cash = data.Cash,
		IncomePerSecond = PlayerDataService.calculateIncomePerSecond(player),
		Rebirths = data.Rebirths,
		SlapPower = data.SlapPower,
		BaseIndex = data.BaseIndex or 0,
		BaseLocked = PlayerDataService.isBaseLocked(player),
		SpeedBoost = PlayerDataService.hasSpeedBoost(player),
		LuckyCharm = PlayerDataService.hasLuckyCharm(player),
		SecondsUntilWave = TsunamiService.getSecondsUntilWave(),
		WaveActive = TsunamiService.isWaveActive(),
		BrainrotCount = BaseService.countBrainrots(player),
		RebirthProgress = math.min(1, data.Cash / GameConfig.REBIRTH_CASH_REQUIRED),
	})
end

local function onPlayerAdded(player)
	PlayerDataService.createPlayerData(player)
	local baseIndex = BaseService.assignBase(player)
	print(player.Name .. " joined Brainrot Bazaar, base " .. tostring(baseIndex))
	local notify = ReplicatedStorage:FindFirstChild("NotifyPlayer")
	task.spawn(function()
		task.wait(2)
		if notify then
			notify:FireClient(player, "Welcome to Brainrot Bazaar! Click a brainrot on the conveyor to buy it.")
		end
	end)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		ShopService.applyWalkSpeed(player)
		local data = PlayerDataService.getPlayerData(player)
		if data and data.Rebirths > 0 then
			PlayerDataService.awardRebirthCrown(player)
		end
	end)
end

local function onPlayerRemoving(player)
	BaseService.freeBase(player)
	PlayerDataService.removePlayerData(player)
	print(player.Name .. " left Brainrot Bazaar.")
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Start every loop.
BaseService.startIncomeLoop()
ConveyorService.startBeltLoop()
ThiefService.startThiefLoop()
TsunamiService.startWaveLoop()
LeaderboardService.startLeaderboardLoop()

-- HUD sync loop.
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, player in ipairs(Players:GetPlayers()) do
			sendHudUpdate(player)
		end
	end
end)

print("Brainrot Bazaar server ready. The conveyor is rolling!")
