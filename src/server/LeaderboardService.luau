-- LeaderboardService: ranks every player by Cash and by Rebirths and
-- pushes the top five of each to the HUD once a second. The board is
-- built from live player data, so it is never stale.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataService = require(script.Parent.PlayerDataService)

local LeaderboardService = {}

-- The top N players by a number the getter reads from their data.
local function topPlayersBy(getter, count)
	local scored = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local data = PlayerDataService.getPlayerData(player)
		if data then
			table.insert(scored, { Player = player, Score = getter(data) })
		end
	end
	table.sort(scored, function(a, b)
		return a.Score > b.Score
	end)
	local top = {}
	for i = 1, math.min(count, #scored) do
		table.insert(top, { Name = scored[i].Player.Name, Score = scored[i].Score })
	end
	return top
end

-- Build both boards and send them to every client.
function LeaderboardService.broadcastLeaderboard()
	local event = ReplicatedStorage:FindFirstChild("LeaderboardUpdate")
	if not event then
		return
	end
	local cashBoard = topPlayersBy(function(data)
		return data.Cash
	end, 5)
	local rebirthBoard = topPlayersBy(function(data)
		return data.Rebirths
	end, 5)
	local defenderBoard = topPlayersBy(function(data)
		return data.TotalStealsDefended
	end, 5)
	event:FireAllClients(cashBoard, rebirthBoard, defenderBoard)
end

function LeaderboardService.startLeaderboardLoop()
	task.spawn(function()
		while true do
			task.wait(2)
			LeaderboardService.broadcastLeaderboard()
		end
	end)
end

-- The single best defender in the server right now, or nil when nobody
-- has stopped a thief yet.
function LeaderboardService.getTopDefender()
	local best = nil
	local bestScore = 0
	for _, player in ipairs(Players:GetPlayers()) do
		local data = PlayerDataService.getPlayerData(player)
		if data and data.TotalStealsDefended > bestScore then
			bestScore = data.TotalStealsDefended
			best = player
		end
	end
	if not best then
		return nil
	end
	return { Name = best.Name, Score = bestScore }
end

-- Total defends across the whole server (a fun number for the HUD).
function LeaderboardService.getTotalDefends()
	local total = 0
	for _, player in ipairs(Players:GetPlayers()) do
		local data = PlayerDataService.getPlayerData(player)
		if data then
			total += data.TotalStealsDefended
		end
	end
	return total
end

-- The top N players by playtime, for the stats panel.
function LeaderboardService.topPlayersByPlaytime(count)
	return topPlayersBy(function(data)
		return data.PlaytimeSeconds
	end, count)
end

return LeaderboardService
