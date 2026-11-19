-- ConveyorService: the belt that carries brainrots past the plaza.
-- Spawns a new random brainrot every few seconds, slides it along the
-- belt, and lets players buy it by clicking it (a ClickDetector). A bought
-- brainrot walks off the belt to the buyer's base; one nobody buys rolls
-- off the far end and despawns.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local BrainrotFactory = require(Shared:WaitForChild("BrainrotFactory"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlayerDataService = require(script.Parent.PlayerDataService)
local BaseService = require(script.Parent.BaseService)

local ConveyorService = {}

local beltItems = {} -- model -> { Character, Mutation, Price }
local beltFolder = nil
local goldenActive = false
local goldenEndsAt = 0
local serverStartAt = 0

function ConveyorService.init(world)
	serverStartAt = os.clock()
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "ConveyorBrainrots"
	beltFolder.Parent = workspace
end

-- Roll a fresh brainrot onto the start of the belt.
function ConveyorService.spawnBrainrotOnBelt()
	if #beltItems >= GameConfig.MAX_ON_BELT then
		return
	end
	local character = BrainrotData.pickRandomCharacter()
	local mutationName = BrainrotData.rollMutation()
	if goldenActive then
		mutationName = BrainrotData.rollMutationWithLuck(true)
	end
	local model = BrainrotFactory.buildCharacterModel(character, mutationName)
	BrainrotFactory.attachPriceTag(model, character.Price)
	if goldenActive then
		BrainrotFactory.attachGoldenGlow(model)
	end
	-- Start at the west end of the belt.
	model:PivotTo(CFrame.new(-GameConfig.CONVEYOR_LENGTH / 2 + 4, 3, -30))
	model.Parent = beltFolder
	beltItems[model] = {
		Character = character,
		Mutation = mutationName,
		Price = character.Price,
	}

	-- Click to buy: the whole model is clickable through its torso.
	local clicker = Instance.new("ClickDetector")
	clicker.MaxActivationDistance = 40
	clicker.Parent = model.PrimaryPart
	clicker.MouseClick:Connect(function(player)
		ConveyorService.tryBuyBrainrot(player, model)
	end)
end

-- A player clicked a brainrot on the belt: charge them and send it home.
function ConveyorService.tryBuyBrainrot(player, model)
	local entry = beltItems[model]
	if not entry then
		return
	end
	local data = PlayerDataService.getPlayerData(player)
	if not data then
		return
	end
	local price = entry.Price
	if PlayerDataService.hasMagnet(player) then
		price = math.floor(price * (1 - GameConfig.MAGNET_DISCOUNT))
	end
	if data.Cash < price then
		ConveyorService.notify(player, "Not enough Cash! " .. entry.Character.Name .. " costs $" .. price .. ".")
		return
	end
	if not BaseService.findFreeSlot(player) then
		ConveyorService.notify(player, "Your base is full! Sell or rebirth first.")
		return
	end
	if not PlayerDataService.spendCash(player, price) then
		return
	end
	beltItems[model] = nil
	if model.Parent then
		model:Destroy()
	end
	local incomeMultiplier = BrainrotData.spotlightMultiplier(entry.Character)
	if goldenActive then
		incomeMultiplier = incomeMultiplier * GameConfig.GOLDEN_CONVEYOR_MULTIPLIER
	end
	local ok, message = BaseService.placeBrainrot(player, entry.Character, entry.Mutation, incomeMultiplier)
	ConveyorService.notify(player, message)
end

-- Tell one player something in their chat/HUD feed.
function ConveyorService.notify(player, message)
	local event = ReplicatedStorage:FindFirstChild("NotifyPlayer")
	if event then
		event:FireClient(player, message)
	end
end

-- Slide every brainrot along the belt; despawn ones that roll off the end.
function ConveyorService.startBeltLoop()
	task.spawn(function()
		while true do
			local dt = task.wait(0.1)
			local toRemove = {}
			for model, _ in pairs(beltItems) do
				if not model.Parent then
					table.insert(toRemove, model)
				else
					local pivot = model:GetPivot()
					local nextX = pivot.Position.X + ConveyorService.getCurrentSpeed() * dt
					if nextX > GameConfig.CONVEYOR_LENGTH / 2 then
						table.insert(toRemove, model)
					else
						model:PivotTo(CFrame.new(nextX, pivot.Position.Y, pivot.Position.Z))
					end
				end
			end
			for _, model in ipairs(toRemove) do
				beltItems[model] = nil
				if model.Parent then
					model:Destroy()
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(GameConfig.SPAWN_INTERVAL)
			ConveyorService.spawnBrainrotOnBelt()
		end
	end)
end

-- How many brainrots are on the belt right now (shown on the HUD).
function ConveyorService.getBeltCount()
	local count = 0
	for _ in pairs(beltItems) do
		count += 1
	end
	return count
end

-- Is the belt running gold right now?
function ConveyorService.isGoldenActive()
	return goldenActive
end

-- Seconds left in the golden window, or 0 when it is not running.
function ConveyorService.getGoldenSecondsLeft()
	if not goldenActive then
		return 0
	end
	return math.max(0, math.floor(goldenEndsAt - os.clock()))
end

-- Belt speed grows as the server ages: +1 stud/s every two minutes, up
-- to +4, so late-game belts feel busier than the opening minutes.
function ConveyorService.getCurrentSpeed()
	local elapsed = os.clock() - serverStartAt
	local bonus = math.min(4, math.floor(elapsed / 120))
	return GameConfig.CONVEYOR_SPEED + bonus
end

-- Tell every player in the server the same message.
function ConveyorService.notifyAll(message)
	local event = ReplicatedStorage:FindFirstChild("NotifyPlayer")
	if not event then
		return
	end
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		event:FireClient(player, message)
	end
end

-- The golden conveyor loop: every few minutes the belt runs gold for a
-- short window. Buys during the window earn double and roll lucky.
function ConveyorService.startGoldenEventLoop()
	task.spawn(function()
		while true do
			task.wait(GameConfig.GOLDEN_CONVEYOR_INTERVAL)
			goldenActive = true
			goldenEndsAt = os.clock() + GameConfig.GOLDEN_CONVEYOR_DURATION
			local event = ReplicatedStorage:FindFirstChild("GoldenConveyorEvent")
			if event then
				event:FireAllClients("start")
			end
			ConveyorService.notifyAll("GOLDEN CONVEYOR! Brainrots bought now earn DOUBLE for " .. GameConfig.GOLDEN_CONVEYOR_DURATION .. " seconds!")
			task.wait(GameConfig.GOLDEN_CONVEYOR_DURATION)
			goldenActive = false
			if event then
				event:FireAllClients("end")
			end
			ConveyorService.notifyAll("The golden conveyor has cooled down. Next window in " .. math.floor(GameConfig.GOLDEN_CONVEYOR_INTERVAL / 60) .. " minutes.")
		end
	end)
end

-- Golden window state for the HUD sync in init.server.luau.
function ConveyorService.getGoldenState()
	return {
		Active = goldenActive,
		SecondsLeft = ConveyorService.getGoldenSecondsLeft(),
	}
end

return ConveyorService
