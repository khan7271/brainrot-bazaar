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
	event:FireAllClients(cashBoard, rebirthBoard)
end

function LeaderboardService.startLeaderboardLoop()
	task.spawn(function()
		while true do
			task.wait(2)
			LeaderboardService.broadcastLeaderboard()
		end
	end)
end

return LeaderboardService
