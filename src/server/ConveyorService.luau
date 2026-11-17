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

function ConveyorService.init(world)
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
	local model = BrainrotFactory.buildCharacterModel(character, mutationName)
	BrainrotFactory.attachPriceTag(model, character.Price)
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
	if data.Cash < entry.Price then
		ConveyorService.notify(player, "Not enough Cash! " .. entry.Character.Name .. " costs $" .. entry.Price .. ".")
		return
	end
	if not BaseService.findFreeSlot(player) then
		ConveyorService.notify(player, "Your base is full! Sell or rebirth first.")
		return
	end
	if not PlayerDataService.spendCash(player, entry.Price) then
		return
	end
	beltItems[model] = nil
	if model.Parent then
		model:Destroy()
	end
	local ok, message = BaseService.placeBrainrot(player, entry.Character, entry.Mutation)
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
					local nextX = pivot.Position.X + GameConfig.CONVEYOR_SPEED * dt
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

return ConveyorService
