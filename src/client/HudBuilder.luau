-- HudBuilder: builds the whole ScreenGui for Brainrot Bazaar.
-- Everything sits clear of the top-left corner, where Roblox's own menu
-- buttons live. Cash and income sit top-centre, the wave timer top-right,
-- the rarity ladder down the left, the shop and rebirth down the right,
-- the leaderboard bottom-right, and notifications across the bottom.

local HudBuilder = {}

local function makeLabel(name, parent, position, size, text, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color
	label.Font = Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 0.4
	label.Parent = parent
	return label
end

local function makePanel(name, parent, position, size, color)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Position = position
	panel.Size = size
	panel.BackgroundColor3 = color
	panel.BackgroundTransparency = 0.25
	panel.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	panel.Parent = parent
	return panel
end

local function makeButton(name, parent, position, size, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = color
	button.Text = text
	button.TextSize = 18
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.SourceSansBold
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	button.Parent = parent
	return button
end

-- Build the full HUD and return every element the client script updates.
function HudBuilder.buildHud(playerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotBazaarGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Parent = playerGui

	-- Top-centre cash bar: the number the player watches most.
	local cashPanel = makePanel("CashPanel", gui, UDim2.new(0.5, -160, 0, 12), UDim2.new(0, 320, 0, 84), Color3.fromRGB(30, 30, 45))
	makeLabel("CashLabel", cashPanel, UDim2.new(0, 0, 0, 4), UDim2.new(1, 0, 0, 44), "$100", 36, Color3.fromRGB(120, 255, 120))
	makeLabel("IncomeLabel", cashPanel, UDim2.new(0, 0, 0, 48), UDim2.new(1, 0, 0, 28), "$0/sec  |  Base 0  |  0 brainrots", 18, Color3.fromRGB(255, 255, 255))

	-- Top-right wave timer: red and urgent when the wave is close.
	local wavePanel = makePanel("WavePanel", gui, UDim2.new(1, -250, 0, 12), UDim2.new(0, 230, 0, 64), Color3.fromRGB(120, 30, 30))
	makeLabel("WaveTitle", wavePanel, UDim2.new(0, 0, 0, 4), UDim2.new(1, 0, 0, 24), "TSUNAMI OF SAUCE", 20, Color3.fromRGB(255, 200, 200))
	makeLabel("WaveTimer", wavePanel, UDim2.new(0, 0, 0, 30), UDim2.new(1, 0, 0, 28), "1:30", 26, Color3.fromRGB(255, 255, 255))

	-- Left rarity ladder: every tier, its colour and its best earner.
	local ladderPanel = makePanel("RarityLadder", gui, UDim2.new(0, 12, 0, 140), UDim2.new(0, 210, 0, 284), Color3.fromRGB(30, 30, 45))
	makeLabel("LadderTitle", ladderPanel, UDim2.new(0, 0, 0, 6), UDim2.new(1, 0, 0, 26), "RARITY LADDER", 20, Color3.fromRGB(255, 220, 80))
	local ladderRows = {
		{ "Common", Color3.fromRGB(200, 200, 200), "Croissant Captain $1/s" },
		{ "Rare", Color3.fromRGB(80, 170, 255), "DJ Toast $8/s" },
		{ "Epic", Color3.fromRGB(180, 90, 255), "Noodle Ninja $60/s" },
		{ "Legendary", Color3.fromRGB(255, 190, 40), "Cheddar Chairman $140/s" },
		{ "Mythic", Color3.fromRGB(255, 70, 90), "Llama Latte $500/s" },
		{ "Brainrot God", Color3.fromRGB(255, 240, 120), "Baguette Baron $1,800/s" },
		{ "Cosmic", Color3.fromRGB(0, 255, 220), "Quantum Quiche $5,000/s" },
	}
	for i, row in ipairs(ladderRows) do
		local y = 36 + (i - 1) * 34
		makeLabel("LadderRow" .. i, ladderPanel, UDim2.new(0, 10, 0, y), UDim2.new(1, -20, 0, 30), row[1] .. " - " .. row[3], 15, row[2])
	end

	-- Right shop panel: four upgrades with prices.
	local shopPanel = makePanel("ShopPanel", gui, UDim2.new(1, -230, 0, 100), UDim2.new(0, 210, 0, 340), Color3.fromRGB(30, 30, 45))
	makeLabel("ShopTitle", shopPanel, UDim2.new(0, 0, 0, 6), UDim2.new(1, 0, 0, 26), "SHOP", 20, Color3.fromRGB(255, 220, 80))
	local shopButtons = {}
	local shopItems = {
		{ Key = "SlapPower", Text = "Slap Power +1 - $500" },
		{ Key = "SpeedBoost", Text = "Speed Boost - $800" },
		{ Key = "LuckyCharm", Text = "Lucky Charm - $1,500" },
		{ Key = "BaseLock", Text = "Base Lock 2 min - $2,500" },
		{ Key = "Magnet", Text = "Cash Magnet 60s - $1,200" },
		{ Key = "Shield", Text = "Sauce Shield 60s - $2,000" },
	}
	for i, item in ipairs(shopItems) do
		local y = 40 + (i - 1) * 48
		shopButtons[item.Key] = makeButton("Shop" .. item.Key, shopPanel, UDim2.new(0, 10, 0, y), UDim2.new(1, -20, 0, 40), item.Text, Color3.fromRGB(60, 120, 200))
	end

	-- Rebirth button under the shop, with a progress bar to $1,000,000.
	local rebirthPanel = makePanel("RebirthPanel", gui, UDim2.new(1, -230, 0, 452), UDim2.new(0, 210, 0, 110), Color3.fromRGB(60, 30, 60))
	makeLabel("RebirthTitle", rebirthPanel, UDim2.new(0, 0, 0, 6), UDim2.new(1, 0, 0, 26), "REBIRTH - $1,000,000", 18, Color3.fromRGB(255, 240, 120))
	local progressBack = Instance.new("Frame")
	progressBack.Name = "RebirthProgressBack"
	progressBack.Position = UDim2.new(0, 10, 0, 38)
	progressBack.Size = UDim2.new(1, -20, 0, 14)
	progressBack.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	progressBack.Parent = rebirthPanel
	local progressFill = Instance.new("Frame")
	progressFill.Name = "RebirthProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBack
	local rebirthButton = makeButton("RebirthButton", rebirthPanel, UDim2.new(0, 10, 0, 60), UDim2.new(1, -20, 0, 40), "REBIRTH (+25% earnings)", Color3.fromRGB(180, 120, 20))

	-- Bottom-right leaderboard.
	local boardPanel = makePanel("LeaderboardPanel", gui, UDim2.new(1, -230, 1, -190), UDim2.new(0, 210, 0, 170), Color3.fromRGB(30, 30, 45))
	makeLabel("BoardTitle", boardPanel, UDim2.new(0, 0, 0, 6), UDim2.new(1, 0, 0, 26), "TOP CASH", 18, Color3.fromRGB(255, 220, 80))
	local boardLabels = {}
	for i = 1, 5 do
		boardLabels[i] = makeLabel("BoardRow" .. i, boardPanel, UDim2.new(0, 10, 0, 34 + (i - 1) * 24), UDim2.new(1, -20, 0, 22), "", 16, Color3.fromRGB(255, 255, 255))
	end

	-- Bottom-centre notification feed.
	local notifyLabel = makeLabel("NotifyLabel", gui, UDim2.new(0.5, -300, 1, -60), UDim2.new(0, 600, 0, 40), "", 20, Color3.fromRGB(255, 255, 255))
	notifyLabel.TextWrapped = true

	-- Slap button, bottom-left, big enough to tap on mobile.
	local slapButton = makeButton("SlapButton", gui, UDim2.new(0, 16, 1, -96), UDim2.new(0, 140, 0, 64), "SLAP! (E)", Color3.fromRGB(220, 60, 60))
	slapButton.TextSize = 26

	-- Wave warning banner, hidden until the countdown hits 10 seconds.
	local warnBanner = makePanel("WaveWarning", gui, UDim2.new(0.5, -260, 0, 110), UDim2.new(0, 520, 0, 60), Color3.fromRGB(180, 20, 20))
	warnBanner.Visible = false
	makeLabel("WaveWarningText", warnBanner, UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 44), "TSUNAMI OF SAUCE INCOMING - RUN TO YOUR BASE!", 22, Color3.fromRGB(255, 255, 255))

	-- Boost strip under the cash bar: live buffs (speed, magnet, shield,
	-- golden window) in one short line.
	local boostPanel = makePanel("BoostPanel", gui, UDim2.new(0.5, -160, 0, 100), UDim2.new(0, 320, 0, 28), Color3.fromRGB(30, 30, 45))
	local boostLabel = makeLabel("BoostLabel", boostPanel, UDim2.new(0, 0, 0, 2), UDim2.new(1, 0, 1, 0), "", 16, Color3.fromRGB(255, 220, 80))

	-- Golden conveyor banner, hidden until a golden window starts.
	local eventBanner = makePanel("EventBanner", gui, UDim2.new(0.5, -260, 0, 180), UDim2.new(0, 520, 0, 44), Color3.fromRGB(160, 110, 10))
	eventBanner.Visible = false
	local goldenTimer = makeLabel("GoldenTimer", eventBanner, UDim2.new(0, 0, 0, 6), UDim2.new(1, 0, 0, 32), "GOLDEN CONVEYOR!", 24, Color3.fromRGB(255, 255, 255))

	-- Stats panel under the ladder: playtime and thief defence record.
	local statsPanel = makePanel("StatsPanel", gui, UDim2.new(0, 12, 0, 436), UDim2.new(0, 210, 0, 64), Color3.fromRGB(30, 30, 45))
	local playtimeLabel = makeLabel("PlaytimeLabel", statsPanel, UDim2.new(0, 10, 0, 6), UDim2.new(1, -20, 0, 24), "Playtime: 0s", 16, Color3.fromRGB(255, 255, 255))
	local defendsLabel = makeLabel("DefendsLabel", statsPanel, UDim2.new(0, 10, 0, 32), UDim2.new(1, -20, 0, 24), "Thieves stopped: 0", 16, Color3.fromRGB(255, 255, 255))

	-- Defenders board, bottom-left above the slap button: top five by
	-- thieves slapped away from their base.
	local defendersPanel = makePanel("DefendersPanel", gui, UDim2.new(0, 16, 1, -290), UDim2.new(0, 210, 0, 170), Color3.fromRGB(30, 30, 45))
	makeLabel("DefendersTitle", defendersPanel, UDim2.new(0, 0, 0, 6), UDim2.new(1, 0, 0, 26), "TOP DEFENDERS", 18, Color3.fromRGB(255, 220, 80))
	local defenderLabels = {}
	for i = 1, 5 do
		defenderLabels[i] = makeLabel("DefenderRow" .. i, defendersPanel, UDim2.new(0, 10, 0, 34 + (i - 1) * 24), UDim2.new(1, -20, 0, 22), "", 16, Color3.fromRGB(255, 255, 255))
	end

	return {
		Gui = gui,
		CashLabel = cashPanel:FindFirstChild("CashLabel"),
		IncomeLabel = cashPanel:FindFirstChild("IncomeLabel"),
		WaveTimer = wavePanel:FindFirstChild("WaveTimer"),
		WavePanel = wavePanel,
		ShopButtons = shopButtons,
		RebirthButton = rebirthButton,
		RebirthProgressFill = progressFill,
		BoardLabels = boardLabels,
		NotifyLabel = notifyLabel,
		SlapButton = slapButton,
		WarnBanner = warnBanner,
		LadderPanel = ladderPanel,
		ShopPanel = shopPanel,
		LeaderboardPanel = boardPanel,
		DefendersPanel = defendersPanel,
		DefenderLabels = defenderLabels,
		EventBanner = eventBanner,
		GoldenTimer = goldenTimer,
		BoostLabel = boostLabel,
		PlaytimeLabel = playtimeLabel,
		DefendsLabel = defendsLabel,
	}
end

return HudBuilder
