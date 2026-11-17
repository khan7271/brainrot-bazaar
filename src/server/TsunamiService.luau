-- TsunamiService: the Tsunami of Sauce. Every 90 seconds a warning sounds
-- and a giant red sauce wave sweeps in from the north river across the
-- whole map. Players must dash back inside their base safe zone before it
-- arrives; anyone caught outside is swept back to spawn and drops 10% of
-- their cash. Bases are the only safe ground.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlayerDataService = require(script.Parent.PlayerDataService)
local BaseService = require(script.Parent.BaseService)

local TsunamiService = {}

local tsunamiWall = nil
local secondsUntilWave = GameConfig.TSUNAMI_INTERVAL
local waveActive = false

function TsunamiService.init(world)
	tsunamiWall = world.TsunamiWall
end

function TsunamiService.getSecondsUntilWave()
	return secondsUntilWave
end

function TsunamiService.isWaveActive()
	return waveActive
end

-- Is this player standing inside their own base plot right now?
function TsunamiService.isPlayerInSafeZone(player)
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local baseIndex = BaseService.getBaseIndex(player)
	if not baseIndex then
		return false
	end
	local plot = BaseService.getPlot(baseIndex)
	if not plot then
		return false
	end
	local pad = plot.Plot:FindFirstChild("BasePad")
	if not pad then
		return false
	end
	local offset = root.Position - pad.Position
	return math.abs(offset.X) <= 11 and math.abs(offset.Z) <= 9
end

-- Sweep every player outside a safe zone back to spawn with a cash drop.
function TsunamiService.sweepPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		if not TsunamiService.isPlayerInSafeZone(player) then
			local data = PlayerDataService.getPlayerData(player)
			if data then
				local lost = math.floor(data.Cash * GameConfig.TSUNAMI_CASH_DROP_FRACTION)
				data.Cash -= lost
				local event = ReplicatedStorage:FindFirstChild("NotifyPlayer")
				if event then
					event:FireClient(player, "The sauce wave swept you away! You dropped $" .. lost .. ".")
				end
			end
			local character = player.Character
			if character then
				local root = character:FindFirstChild("HumanoidRootPart")
				if root then
					root.CFrame = CFrame.new(GameConfig.SPAWN_POSITION)
				end
			end
		else
			local event = ReplicatedStorage:FindFirstChild("NotifyPlayer")
			if event then
				event:FireClient(player, "Safe! Your base shielded you from the sauce wave.")
			end
		end
	end
end

-- Animate the wall rolling across the map, then slide it back north.
function TsunamiService.animateWave()
	waveActive = true
	local event = ReplicatedStorage:FindFirstChild("TsunamiEvent")
	if event then
		event:FireAllClients("start")
	end
	task.spawn(function()
		local startZ = -120
		local endZ = 110
		local distance = endZ - startZ
		local duration = distance / GameConfig.TSUNAMI_WAVE_SPEED
		local steps = 60
		for i = 1, steps do
			local z = startZ + distance * (i / steps)
			tsunamiWall.Position = Vector3.new(0, 10, z)
			task.wait(duration / steps)
		end
		TsunamiService.sweepPlayers()
		-- Slide the wall back home out of sight.
		for i = 1, steps do
			local z = endZ - distance * (i / steps)
			tsunamiWall.Position = Vector3.new(0, 10, z)
			task.wait(0.02)
		end
		waveActive = false
		if event then
			event:FireAllClients("end")
		end
	end)
end

-- The countdown loop: warn, then fire the wave, then reset the timer.
function TsunamiService.startWaveLoop()
	task.spawn(function()
		while true do
			secondsUntilWave = GameConfig.TSUNAMI_INTERVAL
			while secondsUntilWave > 0 do
				task.wait(1)
				secondsUntilWave -= 1
				if secondsUntilWave == GameConfig.TSUNAMI_WARNING then
					local event = ReplicatedStorage:FindFirstChild("NotifyPlayer")
					local warnEvent = ReplicatedStorage:FindFirstChild("TsunamiEvent")
					if warnEvent then
						warnEvent:FireAllClients("warning")
					end
					for _, player in ipairs(Players:GetPlayers()) do
						if event then
							event:FireClient(player, "TSUNAMI OF SAUCE in 10 seconds! Run to your base!")
						end
					end
				end
			end
			TsunamiService.animateWave()
			task.wait(8)
		end
	end)
end

return TsunamiService
