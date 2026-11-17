-- BaseService: owns the eight base plots. Assigns the first free plot to
-- each joining player, tracks which brainrot sits in which slot, ticks
-- income into Cash every second, and removes a brainrot when a thief
-- steals it or a rebirth clears the base.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local BrainrotFactory = require(Shared:WaitForChild("BrainrotFactory"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlayerDataService = require(script.Parent.PlayerDataService)

local BaseService = {}

local plots = {} -- index -> { Slots, Gate, Owner, Models }
local plotByOwner = {}

function BaseService.init(world)
	plots = world.Plots
	for i, plot in ipairs(plots) do
		plot.Owner = nil
		plot.Models = {}
	end
end

-- Give the joining player the first unclaimed plot.
function BaseService.assignBase(player)
	for i, plot in ipairs(plots) do
		if not plot.Owner then
			plot.Owner = player
			plotByOwner[player.UserId] = i
			local data = PlayerDataService.getPlayerData(player)
			if data then
				data.BaseIndex = i
			end
			return i
		end
	end
	return nil
end

function BaseService.getBaseIndex(player)
	return plotByOwner[player.UserId]
end

function BaseService.getPlot(index)
	return plots[index]
end

function BaseService.freeBase(player)
	local index = plotByOwner[player.UserId]
	if index and plots[index] then
		plots[index].Owner = nil
		for _, model in pairs(plots[index].Models) do
			if model and model.Parent then
				model:Destroy()
			end
		end
		plots[index].Models = {}
	end
	plotByOwner[player.UserId] = nil
end

-- First empty slot number on the player's base, or nil when full.
function BaseService.findFreeSlot(player)
	local data = PlayerDataService.getPlayerData(player)
	if not data then
		return nil
	end
	for slot = 1, GameConfig.SLOTS_PER_BASE do
		if not data.Brainrots[slot] then
			return slot
		end
	end
	return nil
end

-- Place a bought brainrot on the player's base and build its model there.
function BaseService.placeBrainrot(player, character, mutationName)
	local index = BaseService.getBaseIndex(player)
	if not index then
		return false, "You have no base yet."
	end
	local slot = BaseService.findFreeSlot(player)
	if not slot then
		return false, "Your base is full!"
	end
	local data = PlayerDataService.getPlayerData(player)
	local income = BrainrotData.incomeOf(character, mutationName)
	data.Brainrots[slot] = {
		CharacterName = character.Name,
		Mutation = mutationName,
		Income = income,
	}
	local plot = plots[index]
	local model = BrainrotFactory.buildCharacterModel(character, mutationName)
	local slotPos = plot.Slots[slot]
	model:PivotTo(CFrame.new(slotPos))
	model.Parent = plot.Plot
	plot.Models[slot] = model
	return true, character.Name .. " is earning " .. income .. "/sec on your base!"
end

-- Remove the brainrot from a slot (stolen, or cleared by a rebirth).
-- Returns the removed record so the thief can carry it away.
function BaseService.removeBrainrotFromSlot(player, slot)
	local data = PlayerDataService.getPlayerData(player)
	if not data then
		return nil
	end
	local record = data.Brainrots[slot]
	if not record then
		return nil
	end
	data.Brainrots[slot] = nil
	local index = BaseService.getBaseIndex(player)
	if index and plots[index] and plots[index].Models[slot] then
		plots[index].Models[slot]:Destroy()
		plots[index].Models[slot] = nil
	end
	return record
end

-- Clear every brainrot from a player's base (used by rebirth).
function BaseService.clearBase(player)
	local data = PlayerDataService.getPlayerData(player)
	if not data then
		return
	end
	for slot, _ in pairs(data.Brainrots) do
		BaseService.removeBrainrotFromSlot(player, slot)
	end
end

-- Show or hide the red lock gate on a base.
function BaseService.setLockGateVisible(index, visible)
	local plot = plots[index]
	if plot and plot.Gate then
		plot.Gate.Transparency = visible and 0.3 or 0.85
		plot.Gate.CanCollide = visible
	end
end

-- Every second: each brainrot earns its income into its owner's Cash.
function BaseService.startIncomeLoop()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
				local income = PlayerDataService.calculateIncomePerSecond(player)
				if income > 0 then
					PlayerDataService.addCash(player, income)
				end
			end
		end
	end)
end

-- Count how many brainrots sit on a player's base (for thieves to target).
function BaseService.countBrainrots(player)
	local data = PlayerDataService.getPlayerData(player)
	if not data then
		return 0
	end
	local count = 0
	for _ in pairs(data.Brainrots) do
		count += 1
	end
	return count
end

return BaseService
