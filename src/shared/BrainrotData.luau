-- BrainrotData: the cast of Brainrot Bazaar.
-- Every brainrot character is an original invention for this game:
-- absurd food-and-object heroes with a buy price, an income per second
-- and a rarity on the ladder Common -> Rare -> Epic -> Legendary ->
-- Mythic -> Brainrot God. Mutations multiply the income.

local BrainrotData = {}

BrainrotData.RARITIES = {
	"Common",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Brainrot God",
}

BrainrotData.RARITY_COLORS = {
	Common = Color3.fromRGB(200, 200, 200),
	Rare = Color3.fromRGB(80, 170, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 190, 40),
	Mythic = Color3.fromRGB(255, 70, 90),
	["Brainrot God"] = Color3.fromRGB(255, 240, 120),
}

BrainrotData.RARITY_ORDER = {
	Common = 1,
	Rare = 2,
	Epic = 3,
	Legendary = 4,
	Mythic = 5,
	["Brainrot God"] = 6,
}

-- Mutation name -> income multiplier and the sparkle colour it shows.
BrainrotData.MUTATIONS = {
	Normal = { Multiplier = 1, Color = Color3.fromRGB(255, 255, 255) },
	Golden = { Multiplier = 2, Color = Color3.fromRGB(255, 215, 0) },
	Diamond = { Multiplier = 5, Color = Color3.fromRGB(120, 220, 255) },
	Rainbow = { Multiplier = 10, Color = Color3.fromRGB(255, 120, 220) },
}

BrainrotData.MUTATION_CHANCES = {
	{ Name = "Rainbow", Chance = 0.02 },
	{ Name = "Diamond", Chance = 0.08 },
	{ Name = "Golden", Chance = 0.20 },
	{ Name = "Normal", Chance = 0.70 },
}

-- The eight heroes of the Bazaar. BodyColor is the main block colour of
-- the character model; AccentColor is its hat, cape or accessory.
BrainrotData.CHARACTERS = {
	{
		Name = "Croissant Captain",
		Rarity = "Common",
		Price = 50,
		IncomePerSecond = 1,
		BodyColor = Color3.fromRGB(232, 178, 90),
		AccentColor = Color3.fromRGB(40, 90, 180),
		Blurb = "A flaky captain who salutes with a butter sword.",
	},
	{
		Name = "Banana Phone",
		Rarity = "Common",
		Price = 100,
		IncomePerSecond = 2,
		BodyColor = Color3.fromRGB(250, 220, 60),
		AccentColor = Color3.fromRGB(60, 60, 60),
		Blurb = "Hello? Yes, this is potassium calling.",
	},
	{
		Name = "DJ Toast",
		Rarity = "Rare",
		Price = 500,
		IncomePerSecond = 8,
		BodyColor = Color3.fromRGB(210, 140, 70),
		AccentColor = Color3.fromRGB(255, 60, 180),
		Blurb = "Drops beats and crumbs at the same time.",
	},
	{
		Name = "Pickle Professor",
		Rarity = "Rare",
		Price = 1200,
		IncomePerSecond = 18,
		BodyColor = Color3.fromRGB(90, 180, 70),
		AccentColor = Color3.fromRGB(240, 240, 230),
		Blurb = "Holds a PhD in brine and bad decisions.",
	},
	{
		Name = "Noodle Ninja",
		Rarity = "Epic",
		Price = 5000,
		IncomePerSecond = 60,
		BodyColor = Color3.fromRGB(250, 200, 120),
		AccentColor = Color3.fromRGB(200, 40, 40),
		Blurb = "Silent, slippery, and impossible to slurp.",
	},
	{
		Name = "Cheddar Chairman",
		Rarity = "Legendary",
		Price = 12000,
		IncomePerSecond = 140,
		BodyColor = Color3.fromRGB(255, 190, 30),
		AccentColor = Color3.fromRGB(30, 30, 30),
		Blurb = "Runs the cheese board. Literally. It is a board.",
	},
	{
		Name = "Llama Latte",
		Rarity = "Mythic",
		Price = 50000,
		IncomePerSecond = 500,
		BodyColor = Color3.fromRGB(240, 225, 200),
		AccentColor = Color3.fromRGB(150, 90, 40),
		Blurb = "Foams at the mouth. In a good way. Mostly.",
	},
	{
		Name = "Baguette Baron",
		Rarity = "Brainrot God",
		Price = 200000,
		IncomePerSecond = 1800,
		BodyColor = Color3.fromRGB(220, 160, 80),
		AccentColor = Color3.fromRGB(255, 240, 120),
		Blurb = "The crust is law. The crumb is gospel.",
	},
}

-- Pick a random character, weighted so common heroes show up most often
-- and the Baguette Baron is a rare, exciting sight on the belt.
function BrainrotData.pickRandomCharacter()
	local weights = { 30, 25, 16, 12, 8, 5, 3, 1 }
	local total = 0
	for _, w in ipairs(weights) do
		total += w
	end
	local roll = math.random(1, total)
	local running = 0
	for i, w in ipairs(weights) do
		running += w
		if roll <= running then
			return BrainrotData.CHARACTERS[i]
		end
	end
	return BrainrotData.CHARACTERS[1]
end

-- Roll a mutation for a freshly spawned brainrot.
function BrainrotData.rollMutation()
	local roll = math.random()
	local running = 0
	for _, entry in ipairs(BrainrotData.MUTATION_CHANCES) do
		running += entry.Chance
		if roll <= running then
			return entry.Name
		end
	end
	return "Normal"
end

-- Income per second after the mutation multiplier is applied.
function BrainrotData.incomeOf(character, mutationName)
	local mutation = BrainrotData.MUTATIONS[mutationName] or BrainrotData.MUTATIONS.Normal
	return character.IncomePerSecond * mutation.Multiplier
end

function BrainrotData.findCharacter(name)
	for _, character in ipairs(BrainrotData.CHARACTERS) do
		if character.Name == name then
			return character
		end
	end
	return nil
end

-- New cast members, added after launch: a seventh rarity tier sits above
-- Brainrot God, and a Void mutation outshines even Rainbow. These lines
-- run at require time so every service sees the same cast.
table.insert(BrainrotData.RARITIES, "Cosmic")
BrainrotData.RARITY_COLORS.Cosmic = Color3.fromRGB(0, 255, 220)
BrainrotData.RARITY_ORDER.Cosmic = 7
BrainrotData.MUTATIONS.Void = { Multiplier = 15, Color = Color3.fromRGB(120, 0, 200) }
-- Normal is the fourth chance entry (Rainbow, Diamond, Golden, Normal):
-- trim it first so the total still sums to exactly 1.00, then add Void.
BrainrotData.MUTATION_CHANCES[4].Chance = 0.69
table.insert(BrainrotData.MUTATION_CHANCES, 1, { Name = "Void", Chance = 0.01 })

table.insert(BrainrotData.CHARACTERS, {
	Name = "Sushi Samurai",
	Rarity = "Epic",
	Price = 8000,
	IncomePerSecond = 95,
	BodyColor = Color3.fromRGB(240, 230, 210),
	AccentColor = Color3.fromRGB(220, 40, 40),
	Blurb = "Slices sashimi and bad vibes with equal precision.",
})
table.insert(BrainrotData.CHARACTERS, {
	Name = "Waffle Wizard",
	Rarity = "Legendary",
	Price = 20000,
	IncomePerSecond = 220,
	BodyColor = Color3.fromRGB(210, 150, 80),
	AccentColor = Color3.fromRGB(120, 60, 200),
	Blurb = "Casts syrup spells. Sticky, but powerful.",
})
table.insert(BrainrotData.CHARACTERS, {
	Name = "Taco Tornado",
	Rarity = "Mythic",
	Price = 80000,
	IncomePerSecond = 800,
	BodyColor = Color3.fromRGB(250, 200, 90),
	AccentColor = Color3.fromRGB(60, 180, 80),
	Blurb = "Spins through the bazaar leaving salsa in its wake.",
})
table.insert(BrainrotData.CHARACTERS, {
	Name = "Quantum Quiche",
	Rarity = "Cosmic",
	Price = 500000,
	IncomePerSecond = 5000,
	BodyColor = Color3.fromRGB(140, 255, 220),
	AccentColor = Color3.fromRGB(120, 0, 200),
	Blurb = "Exists in every fridge at once. Do not observe it.",
})

-- Mutation rank by multiplier, so a lucky re-roll can keep the better roll.
function BrainrotData.mutationRank(mutationName)
	local mutation = BrainrotData.MUTATIONS[mutationName]
	if not mutation then
		return 0
	end
	return mutation.Multiplier
end

-- Roll a mutation; when lucky, roll twice and keep the stronger one.
function BrainrotData.rollMutationWithLuck(lucky)
	local first = BrainrotData.rollMutation()
	if not lucky then
		return first
	end
	local second = BrainrotData.rollMutation()
	if BrainrotData.mutationRank(second) > BrainrotData.mutationRank(first) then
		return second
	end
	return first
end

-- Every character of one rarity, in cast order.
function BrainrotData.charactersByRarity(rarity)
	local matches = {}
	for _, character in ipairs(BrainrotData.CHARACTERS) do
		if character.Rarity == rarity then
			table.insert(matches, character)
		end
	end
	return matches
end

-- The best earner of a rarity (what the ladder row shows for that tier).
function BrainrotData.bestEarnerForRarity(rarity)
	local best = nil
	for _, character in ipairs(BrainrotData.charactersByRarity(rarity)) do
		if not best or character.IncomePerSecond > best.IncomePerSecond then
			best = character
		end
	end
	return best
end

-- Rarity colour, falling back to white for unknown tiers.
function BrainrotData.getRarityColor(rarity)
	return BrainrotData.RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
end

-- Spotlight of the day: one character earns 50% extra all day long. The
-- pick is seeded by the calendar day, so every player sees the same hero.
function BrainrotData.getSpotlightCharacter()
	local daySeed = tonumber(os.date("%j")) or 1
	local index = (daySeed % #BrainrotData.CHARACTERS) + 1
	return BrainrotData.CHARACTERS[index]
end

-- Income multiplier for the spotlight hero: 1.5 on its day, 1 otherwise.
function BrainrotData.spotlightMultiplier(character)
	if BrainrotData.getSpotlightCharacter().Name == character.Name then
		return 1.5
	end
	return 1
end

-- A one-line spotlight announcement for the welcome feed.
function BrainrotData.spotlightAnnouncement()
	local hero = BrainrotData.getSpotlightCharacter()
	return "Today's spotlight: " .. hero.Name .. " (" .. hero.Rarity .. ") earns 50% extra!"
end

return BrainrotData
