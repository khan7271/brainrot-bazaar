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

return FormatMoney
