-- SlapService: the slap. Players click (or press E) to slap nearby thieves
-- and rival players. A slapped thief is knocked flying and despawns; a
-- slapped rival is shoved backwards. Slap power grows with shop upgrades.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlayerDataService = require(script.Parent.PlayerDataService)
local ThiefService = require(script.Parent.ThiefService)

local SlapService = {}

local lastSlapAt = {} -- userId -> os.clock of last slap

function SlapService.getSlapPower(player)
	local data = PlayerDataService.getPlayerData(player)
	local level = data and data.SlapPower or 0
	return GameConfig.SLAP_BASE_POWER + level * 15
end

-- Slap everything slappable in front of the player.
function SlapService.slap(player)
	local now = os.clock()
	if lastSlapAt[player.UserId] and now - lastSlapAt[player.UserId] < GameConfig.SLAP_COOLDOWN then
		return
	end
	lastSlapAt[player.UserId] = now
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local power = SlapService.getSlapPower(player)
	local slappedAnything = false

	-- Thieves first: they are the real threat.
	for model, _ in pairs(ThiefService.getThieves()) do
		if model.Parent and model.PrimaryPart then
			local distance = (model.PrimaryPart.Position - root.Position).Magnitude
			if distance <= GameConfig.SLAP_RANGE then
				if ThiefService.slapThiefAway(model, power) then
					slappedAnything = true
					local notify = ReplicatedStorage:FindFirstChild("NotifyPlayer")
					if notify then
						notify:FireClient(player, "SLAPPED the thief away! Your base is safe.")
					end
				end
			end
		end
	end

	-- Rival players get shoved backwards with a body velocity.
	for _, other in ipairs(game:GetService("Players"):GetPlayers()) do
		if other ~= player and other.Character then
			local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local distance = (otherRoot.Position - root.Position).Magnitude
				if distance <= GameConfig.SLAP_RANGE then
					local direction = (otherRoot.Position - root.Position).Unit
					local push = Instance.new("BodyVelocity")
					push.Velocity = direction * power + Vector3.new(0, power * 0.5, 0)
					push.MaxForce = Vector3.new(10000, 10000, 10000)
					push.Parent = otherRoot
					task.delay(0.4, function()
						push:Destroy()
					end)
					slappedAnything = true
				end
			end
		end
	end

	-- A little visual: a slap sound cue the client can hear via the event.
	if slappedAnything then
		local event = ReplicatedStorage:FindFirstChild("SlapEvent")
		if event then
			event:FireClient(player, "slap")
		end
	end
end

function SlapService.bindRemotes()
	local slapEvent = ReplicatedStorage:WaitForChild("RequestSlap")
	slapEvent.OnServerEvent:Connect(function(player)
		SlapService.slap(player)
	end)
end

return SlapService
