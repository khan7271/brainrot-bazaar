-- Brainrot Bazaar: client entry point.
-- Builds the HUD (cash, income, wave timer, rarity ladder, shop, rebirth,
-- leaderboard, notifications, slap button), listens to the server's
-- RemoteEvents, and sends slap / shop / rebirth requests back. The 3D
-- world itself is built by the server; this script only draws the
-- ScreenGui over it. HUD text stays clear of the top-left corner, where
-- Roblox's own menu buttons sit.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FormatMoney = require(Shared:WaitForChild("FormatMoney"))
local HudBuilder = require(script.Parent.HudBuilder)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local hud = HudBuilder.buildHud(playerGui)

-- RemoteEvents the server created in init.server.luau.
local notifyEvent = ReplicatedStorage:WaitForChild("NotifyPlayer")
local tsunamiEvent = ReplicatedStorage:WaitForChild("TsunamiEvent")
local slapEvent = ReplicatedStorage:WaitForChild("SlapEvent")
local leaderboardEvent = ReplicatedStorage:WaitForChild("LeaderboardUpdate")
local hudUpdateEvent = ReplicatedStorage:WaitForChild("HudUpdate")
local buyShopItemEvent = ReplicatedStorage:WaitForChild("BuyShopItem")
local requestRebirthEvent = ReplicatedStorage:WaitForChild("RequestRebirth")
local requestSlapEvent = ReplicatedStorage:WaitForChild("RequestSlap")

-- Show a notification for a few seconds, then fade it out.
local notifyToken = 0
local function showNotification(message)
	notifyToken += 1
	local token = notifyToken
	hud.NotifyLabel.Text = message
	task.delay(5, function()
		if token == notifyToken then
			hud.NotifyLabel.Text = ""
		end
	end)
end

-- Every HUD number the server sends, twice a second.
hudUpdateEvent.OnClientEvent:Connect(function(state)
	hud.CashLabel.Text = FormatMoney.formatCash(state.Cash)
	local lockText = ""
	if state.BaseLocked then
		lockText = "  |  BASE LOCKED"
	end
	local boostText = ""
	if state.SpeedBoost then
		boostText = "  |  SPEED!"
	end
	hud.IncomeLabel.Text = FormatMoney.formatIncome(state.IncomePerSecond)
		.. "  |  Base " .. state.BaseIndex
		.. "  |  " .. state.BrainrotCount .. " brainrots"
		.. lockText .. boostText
	if state.WaveActive then
		hud.WaveTimer.Text = "WAVE!"
		hud.WavePanel.BackgroundColor3 = Color3.fromRGB(200, 20, 20)
	elseif state.SecondsUntilWave <= 10 then
		hud.WaveTimer.Text = FormatMoney.formatTimer(state.SecondsUntilWave) .. " RUN!"
		hud.WavePanel.BackgroundColor3 = Color3.fromRGB(200, 60, 20)
	else
		hud.WaveTimer.Text = FormatMoney.formatTimer(state.SecondsUntilWave)
		hud.WavePanel.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
	end
	hud.RebirthProgressFill.Size = UDim2.new(math.clamp(state.RebirthProgress, 0, 1), 0, 1, 0)
end)

-- Leaderboard rows, top five by cash.
leaderboardEvent.OnClientEvent:Connect(function(cashBoard, rebirthBoard)
	for i = 1, 5 do
		local entry = cashBoard[i]
		if entry then
			hud.BoardLabels[i].Text = i .. ". " .. entry.Name .. " - " .. FormatMoney.formatCash(entry.Score)
		else
			hud.BoardLabels[i].Text = ""
		end
	end
end)

notifyEvent.OnClientEvent:Connect(function(message)
	showNotification(message)
end)

-- Tsunami lifecycle: warning banner on, wave banner off when it ends.
tsunamiEvent.OnClientEvent:Connect(function(stage)
	if stage == "warning" then
		hud.WarnBanner.Visible = true
	elseif stage == "start" then
		hud.WarnBanner.Visible = false
		showNotification("THE TSUNAMI OF SAUCE IS HERE! Get to your base!")
	elseif stage == "end" then
		hud.WarnBanner.Visible = false
	end
end)

slapEvent.OnClientEvent:Connect(function(action)
	if action == "slap" then
		showNotification("SLAP!")
	end
end)

-- Shop buttons send the item key to the server, which checks the price.
for itemKey, button in pairs(hud.ShopButtons) do
	button.MouseButton1Click:Connect(function()
		buyShopItemEvent:FireServer(itemKey)
	end)
end

hud.RebirthButton.MouseButton1Click:Connect(function()
	requestRebirthEvent:FireServer()
end)

-- Slap: the big button, or the E key via ContextActionService so it works
-- even when Roblox's default camera scripts eat the arrow keys.
local function onSlapAction(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		requestSlapEvent:FireServer()
	end
	return Enum.ContextActionResult.Pass
end
ContextActionService:BindAction("BrainrotSlap", onSlapAction, false, Enum.KeyCode.E)
hud.SlapButton.MouseButton1Click:Connect(function()
	requestSlapEvent:FireServer()
end)

-- Keep the camera over the shoulder of the player's character, looking
-- down the conveyor toward the plaza, as a third-person 3D game should.
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Custom

showNotification("Welcome to Brainrot Bazaar! Click a brainrot on the conveyor to buy it.")
print("Brainrot Bazaar client ready.")
