-- FormatMoney: small text helpers shared by the server and the HUD so
-- cash, income and timers always read the same way on both sides.

local FormatMoney = {}

-- 1234567 -> "$1,234,567". Handles the big rebirth numbers gracefully.
function FormatMoney.formatCash(amount)
	local n = math.floor(amount + 0.5)
	local negative = n < 0
	n = math.abs(n)
	local text = tostring(n)
	local grouped = ""
	while #text > 3 do
		grouped = "," .. string.sub(text, -3) .. grouped
		text = string.sub(text, 1, -4)
	end
	grouped = text .. grouped
	if negative then
		return "-$" .. grouped
	end
	return "$" .. grouped
end

-- 90 -> "1:30", 8 -> "0:08".
function FormatMoney.formatTimer(seconds)
	seconds = math.max(0, math.floor(seconds + 0.5))
	local minutes = math.floor(seconds / 60)
	local rest = seconds % 60
	if rest < 10 then
		return minutes .. ":0" .. rest
	end
	return minutes .. ":" .. rest
end

-- "$12/sec" style income label.
function FormatMoney.formatIncome(perSecond)
	return FormatMoney.formatCash(perSecond) .. "/sec"
end

-- 1500 -> "1.5K", 2500000 -> "2.5M", 1200000000 -> "1.2B", 999 -> "999".
function FormatMoney.formatCompact(amount)
	local n = math.abs(amount)
	local suffixes = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, entry in ipairs(suffixes) do
		local value, suffix = entry[1], entry[2]
		if n >= value then
			local scaled = amount / value
			local rounded = math.floor(scaled * 10 + 0.5) / 10
			return string.format("%.1f%s", rounded, suffix)
		end
	end
	return tostring(math.floor(amount + 0.5))
end

-- 3661 -> "1h 01m", 90 -> "1m 30s", 45 -> "45s".
function FormatMoney.formatTime(totalSeconds)
	totalSeconds = math.max(0, math.floor(totalSeconds + 0.5))
	local hours = math.floor(totalSeconds / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local seconds = totalSeconds % 60
	if hours > 0 then
		if minutes < 10 then
			return hours .. "h 0" .. minutes .. "m"
		end
		return hours .. "h " .. minutes .. "m"
	elseif minutes > 0 then
		if seconds < 10 then
			return minutes .. "m 0" .. seconds .. "s"
		end
		return minutes .. "m " .. seconds .. "s"
	else
		return seconds .. "s"
	end
end

-- 0.256 -> "25.6%".
function FormatMoney.formatPercent(fraction)
	return string.format("%.1f%%", fraction * 100)
end

-- 1 -> "1st", 2 -> "2nd", 3 -> "3rd", 4 -> "4th", 11 -> "11th", 21 -> "21st".
function FormatMoney.formatOrdinal(n)
	local lastTwo = n % 100
	if lastTwo >= 11 and lastTwo <= 13 then
		return n .. "th"
	end
	local last = n % 10
	if last == 1 then
		return n .. "st"
	elseif last == 2 then
		return n .. "nd"
	elseif last == 3 then
		return n .. "rd"
	else
		return n .. "th"
	end
end

return FormatMoney
