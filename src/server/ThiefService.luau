-- ThiefService: NPC rival thieves. Every so often a shady blocky figure
-- sneaks in from the edge of the map, walks to a random player's base,
-- and tries to grab a brainrot. Players slap the thief away (SlapService)
-- or buy a base lock to keep thieves out entirely. A thief that finishes
-- its steal runs off with the brainrot and despawns.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local BrainrotFactory = require(Shared:WaitForChild("BrainrotFactory"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlayerDataService = require(script.Parent.PlayerDataService)
local BaseService = require(script.Parent.BaseService)

local ThiefService = {}

local thieves = {} -- model -> { TargetPlayer, Slot, StealStartedAt, Type }
local thiefFolder = nil
local lastStolenAt = {} -- userId -> os.time of the last steal against them

function ThiefService.init()
	thiefFolder = Instance.new("Folder")
	thiefFolder.Name = "Thieves"
	thiefFolder.Parent = workspace
end

-- Build one sneaky thief: dark hoodie, mask, and a sack for the loot.
function ThiefService.buildThiefModel()
	local model = Instance.new("Model")
	model.Name = "SneakyThief"
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2.6, 2.6, 1.6)
	torso.Position = Vector3.new(0, 2.3, 0)
	torso.Color = Color3.fromRGB(40, 40, 50)
	torso.Anchored = false
	torso.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2)
	head.Position = Vector3.new(0, 4.6, 0)
	head.Color = Color3.fromRGB(220, 180, 140)
	head.Anchored = false
	head.Parent = model
	local mask = Instance.new("Part")
	mask.Name = "Mask"
	mask.Size = Vector3.new(1.8, 0.7, 0.3)
	mask.Position = Vector3.new(0, 4.7, 1.05)
	mask.Color = Color3.fromRGB(20, 20, 20)
	mask.Anchored = false
	mask.Parent = model
	local sack = Instance.new("Part")
	sack.Name = "LootSack"
	sack.Size = Vector3.new(1.6, 1.6, 1.6)
	sack.Position = Vector3.new(1.8, 2.3, -0.6)
	sack.Color = Color3.fromRGB(150, 110, 60)
	sack.Anchored = false
	sack.Parent = model
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part ~= torso then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = torso
			weld.Part1 = part
			weld.Parent = torso
		end
	end
	model.PrimaryPart = torso
	-- Humanoid so the thief can walk with a simple MoveTo.
	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = GameConfig.THIEF_SPEED
	humanoid.Parent = model
	return model
end

-- Pick a random player who has brainrots and whose base is not locked.
function ThiefService.pickVictim()
	local candidates = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if BaseService.countBrainrots(player) > 0 and not PlayerDataService.isBaseLocked(player) and ThiefService.getStealCooldownLeft(player) <= 0 then
			table.insert(candidates, player)
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[math.random(1, #candidates)]
end

-- Send one thief into the map.
function ThiefService.spawnThief()
	local victim = ThiefService.pickVictim()
	if not victim then
		return
	end
	local data = PlayerDataService.getPlayerData(victim)
	if not data then
		return
	end
	-- Choose a random occupied slot on the victim's base.
	local occupied = {}
	for slot, _ in pairs(data.Brainrots) do
		table.insert(occupied, slot)
	end
	local slot = occupied[math.random(1, #occupied)]
	local baseIndex = BaseService.getBaseIndex(victim)
	local plot = BaseService.getPlot(baseIndex)
	if not plot then
		return
	end
	local thiefType = ThiefService.pickThiefType()
	local model = ThiefService.buildThiefModelForType(thiefType)
	model:PivotTo(CFrame.new(math.random(-90, 90), 3, 85))
	model.Parent = thiefFolder
	thieves[model] = { TargetPlayer = victim, Slot = slot, StealStartedAt = nil, Type = thiefType }
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid:MoveTo(plot.Slots[slot])
	-- Warn the victim so they can run back and slap the thief.
	local event = ReplicatedStorage:FindFirstChild("NotifyPlayer")
	if event then
		event:FireClient(victim, "A thief is sneaking to your base! Slap them away!")
	end
end

-- A thief that reached its slot starts its steal timer; when it finishes,
-- the brainrot is gone and the thief runs off the map.
function ThiefService.updateThieves()
	for model, thief in pairs(thieves) do
		if not model.Parent then
			thieves[model] = nil
		else
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local baseIndex = BaseService.getBaseIndex(thief.TargetPlayer)
			local plot = baseIndex and BaseService.getPlot(baseIndex)
			if not plot then
				ThiefService.removeThief(model)
			else
				local slotPos = plot.Slots[thief.Slot]
				local distance = (model.PrimaryPart.Position - slotPos).Magnitude
				if distance < 4 then
					local stealTime = GameConfig.THIEF_TYPES[thief.Type].StealTime
					if not thief.StealStartedAt then
						thief.StealStartedAt = os.clock()
					elseif os.clock() - thief.StealStartedAt >= stealTime then
						lastStolenAt[thief.TargetPlayer.UserId] = os.time()
						local stolen = BaseService.removeBrainrotFromSlot(thief.TargetPlayer, thief.Slot)
						if stolen then
							local event = ReplicatedStorage:FindFirstChild("NotifyPlayer")
							if event then
								event:FireClient(thief.TargetPlayer, "A thief stole your " .. stolen.CharacterName .. "!")
							end
						end
						ThiefService.removeThief(model)
					end
				elseif humanoid then
					humanoid:MoveTo(slotPos)
				end
			end
		end
	end
end

-- Remove a thief: called when it is slapped away or after a steal.
function ThiefService.removeThief(model)
	thieves[model] = nil
	if model.Parent then
		model:Destroy()
	end
end

-- SlapService calls this: knock a thief flying and despawn it.
function ThiefService.slapThiefAway(model, slapPower, slapper)
	local entry = thieves[model]
	if not entry then
		return false
	end
	if slapper then
		PlayerDataService.addStealDefended(slapper)
		if entry.Type == "Speedy" then
			PlayerDataService.addCash(slapper, GameConfig.SPEEDY_THIEF_BOUNTY)
			local notify = ReplicatedStorage:FindFirstChild("NotifyPlayer")
			if notify then
				notify:FireClient(slapper, "Speedy thief bounty! +$" .. GameConfig.SPEEDY_THIEF_BOUNTY)
			end
		end
	end
	local torso = model.PrimaryPart
	if torso then
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = Vector3.new(math.random(-1, 1) * slapPower, slapPower * 0.8, slapPower)
		bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
		bodyVelocity.Parent = torso
		task.delay(0.5, function()
			ThiefService.removeThief(model)
		end)
	else
		ThiefService.removeThief(model)
	end
	return true
end

function ThiefService.getThieves()
	return thieves
end

function ThiefService.startThiefLoop()
	task.spawn(function()
		while true do
			task.wait(GameConfig.THIEF_SPAWN_INTERVAL)
			ThiefService.spawnThief()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			ThiefService.updateThieves()
		end
	end)
end

-- Pick a thief type by weight: most are normal, some speedy, a few disguised.
function ThiefService.pickThiefType()
	local roll = math.random(1, 100)
	local running = 0
	local order = { "Normal", "Speedy", "Disguised" }
	for _, typeName in ipairs(order) do
		running += GameConfig.THIEF_TYPES[typeName].Weight
		if roll <= running then
			return typeName
		end
	end
	return "Normal"
end

-- Build a thief of one type: speedy thieves wear red and run fast,
-- disguised thieves borrow a brainrot's colours to blend into the belt.
function ThiefService.buildThiefModelForType(typeName)
	local model = ThiefService.buildThiefModel()
	local torso = model:FindFirstChild("Torso")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local info = GameConfig.THIEF_TYPES[typeName] or GameConfig.THIEF_TYPES.Normal
	if humanoid then
		humanoid.WalkSpeed = info.Speed
	end
	if typeName == "Speedy" and torso then
		torso.Color = Color3.fromRGB(200, 40, 40)
		local bolt = Instance.new("Part")
		bolt.Name = "LightningBolt"
		bolt.Size = Vector3.new(0.5, 1.4, 0.5)
		bolt.Position = torso.Position + Vector3.new(0, 1.8, 0)
		bolt.Color = Color3.fromRGB(255, 220, 80)
		bolt.Material = Enum.Material.Neon
		bolt.Anchored = false
		bolt.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = bolt
		weld.Parent = torso
	elseif typeName == "Disguised" and torso then
		local disguise = BrainrotData.CHARACTERS[math.random(1, 4)]
		torso.Color = disguise.BodyColor
		local hat = Instance.new("Part")
		hat.Name = "DisguiseHat"
		hat.Size = Vector3.new(2.4, 0.6, 2.4)
		hat.Position = torso.Position + Vector3.new(0, 2.6, 0)
		hat.Color = disguise.AccentColor
		hat.Anchored = false
		hat.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = hat
		weld.Parent = torso
	end
	model.Name = typeName .. "Thief"
	return model
end

-- Seconds until a player can be targeted again after being stolen from.
function ThiefService.getStealCooldownLeft(player)
	local last = lastStolenAt[player.UserId]
	if not last then
		return 0
	end
	return math.max(0, GameConfig.THIEF_COOLDOWN_AFTER_STEAL - (os.time() - last))
end

return ThiefService
