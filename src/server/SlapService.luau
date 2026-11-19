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
local slapCombos = {} -- userId -> { Count, LastAt }

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
	local combo = SlapService.bumpCombo(player, now)
	local power = SlapService.getSlapPower(player) + (combo - 1) * GameConfig.SLAP_COMBO_BONUS
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local slappedAnything = false

	-- Thieves first: they are the real threat.
	for model, _ in pairs(ThiefService.getThieves()) do
		if model.Parent and model.PrimaryPart then
			local distance = (model.PrimaryPart.Position - root.Position).Magnitude
			if distance <= GameConfig.SLAP_RANGE then
				if ThiefService.slapThiefAway(model, power, player) then
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
		PlayerDataService.noteSlapStreak(player, combo)
		local event = ReplicatedStorage:FindFirstChild("SlapEvent")
		if event then
			if combo >= 2 then
				event:FireClient(player, "slapCombo", combo)
			else
				event:FireClient(player, "slap")
			end
		end
	end
end

function SlapService.bindRemotes()
	local slapEvent = ReplicatedStorage:WaitForChild("RequestSlap")
	slapEvent.OnServerEvent:Connect(function(player)
		SlapService.slap(player)
	end)
end

-- Bump the slap combo: slaps inside the combo window raise the count
-- (capped), a slow slap restarts it at one. Returns the new count.
function SlapService.bumpCombo(player, now)
	local entry = slapCombos[player.UserId]
	if entry and now - entry.LastAt <= GameConfig.SLAP_COMBO_WINDOW then
		entry.Count = math.min(entry.Count + 1, GameConfig.SLAP_COMBO_MAX)
	else
		entry = { Count = 1, LastAt = now }
		slapCombos[player.UserId] = entry
	end
	entry.LastAt = now
	return entry.Count
end

-- The player's live combo count, or 0 when it has gone cold.
function SlapService.getCombo(player)
	local entry = slapCombos[player.UserId]
	if not entry then
		return 0
	end
	if os.clock() - entry.LastAt > GameConfig.SLAP_COMBO_WINDOW then
		return 0
	end
	return entry.Count
end

return SlapService
