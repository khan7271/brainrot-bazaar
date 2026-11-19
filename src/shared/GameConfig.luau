-- GameConfig: every number that tunes Brainrot Bazaar lives here, so the
-- whole game's balance can be read (and changed) in one place.

local GameConfig = {}

-- Money
GameConfig.START_CASH = 100
GameConfig.REBIRTH_CASH_REQUIRED = 1000000
GameConfig.REBIRTH_MULTIPLIER_BONUS = 0.25 -- +25% earnings per rebirth
GameConfig.MAX_REBIRTHS = 99

-- Bases: 8 plots around the plaza, 6 brainrot slots each.
GameConfig.BASE_COUNT = 8
GameConfig.SLOTS_PER_BASE = 6
GameConfig.BASE_RADIUS = 52 -- distance from the plaza centre to a base
GameConfig.BASE_LOCK_PRICE = 2500
GameConfig.BASE_LOCK_DURATION = 120 -- seconds of thief-proofing

-- Conveyor: the belt that carries brainrots past the plaza.
GameConfig.CONVEYOR_LENGTH = 120
GameConfig.CONVEYOR_WIDTH = 8
GameConfig.CONVEYOR_SPEED = 6 -- studs per second
GameConfig.SPAWN_INTERVAL = 4 -- seconds between new brainrots
GameConfig.MAX_ON_BELT = 10

-- Thieves: NPC rivals who sneak in and grab brainrots.
GameConfig.THIEF_SPAWN_INTERVAL = 25
GameConfig.THIEF_STEAL_TIME = 6 -- seconds a thief needs at a slot
GameConfig.THIEF_SPEED = 10

-- Tsunami of Sauce: the wave that sweeps the map.
GameConfig.TSUNAMI_INTERVAL = 90 -- seconds between waves
GameConfig.TSUNAMI_WARNING = 10 -- seconds of warning before it hits
GameConfig.TSUNAMI_CASH_DROP_FRACTION = 0.10 -- cash lost when swept away
GameConfig.TSUNAMI_WAVE_SPEED = 30

-- Shop prices.
GameConfig.SHOP = {
	SlapPower = { Name = "Slap Power +1", Price = 500, Description = "Slap thieves harder and further." },
	SpeedBoost = { Name = "Speed Boost", Price = 800, Description = "Run 50% faster for 60 seconds." },
	BaseLock = { Name = "Base Lock (2 min)", Price = 2500, Description = "Thieves cannot touch your base." },
	LuckyCharm = { Name = "Lucky Charm", Price = 1500, Description = "Better mutations for 60 seconds." },
	Magnet = { Name = "Cash Magnet", Price = 1200, Description = "Belt brainrots cost 15% less for 60 seconds." },
	Shield = { Name = "Sauce Shield", Price = 2000, Description = "The next tsunami cannot take your cash (60 seconds)." },
}

-- Slap
GameConfig.SLAP_BASE_POWER = 30
GameConfig.SLAP_RANGE = 12
GameConfig.SLAP_COOLDOWN = 1

-- World layout
GameConfig.PLAZA_RADIUS = 18
GameConfig.SPAWN_POSITION = Vector3.new(0, 5, 60)

-- Golden Conveyor: every few minutes the belt runs gold. Brainrots bought
-- during the golden window earn double, and lucky mutations roll hotter.
GameConfig.GOLDEN_CONVEYOR_INTERVAL = 180 -- seconds between golden windows
GameConfig.GOLDEN_CONVEYOR_DURATION = 30 -- seconds a golden window lasts
GameConfig.GOLDEN_CONVEYOR_MULTIPLIER = 2 -- income multiplier for golden buys

-- Base upgrades: spend cash to bolt extra slots onto your base.
GameConfig.BASE_MAX_TIER = 3
GameConfig.BASE_UPGRADE_PRICES = { 1500, 5000, 15000 } -- tier 1, 2, 3
GameConfig.BASE_UPGRADE_EXTRA_SLOTS = 2 -- slots gained per tier

-- Thief types: a speedy thief is quick but fragile, a disguised thief
-- blends in with the brainrots until it gets close to a slot.
GameConfig.THIEF_TYPES = {
	Normal = { Speed = 10, StealTime = 6, Weight = 60 },
	Speedy = { Speed = 16, StealTime = 4, Weight = 25 },
	Disguised = { Speed = 8, StealTime = 8, Weight = 15 },
}
GameConfig.THIEF_COOLDOWN_AFTER_STEAL = 60 -- seconds a victim is safe after a steal
GameConfig.SPEEDY_THIEF_BOUNTY = 50 -- cash for slapping a speedy thief away

-- Tsunami phases: a distant rumble warns players early, and a short grace
-- period after the wave starts lets slow players escape without a loss.
GameConfig.TSUNAMI_PHASE1_WARNING = 30 -- seconds before the wave: rumble stage
GameConfig.TSUNAMI_GRACE_PERIOD = 3 -- seconds after the wave: no cash lost
GameConfig.TSUNAMI_WAVE_GROWTH = 0.5 -- extra wave speed per wave that has passed
GameConfig.TSUNAMI_MAX_EXTRA_SPEED = 15

-- Magnet and Shield: timed buffs bought in the shop.
GameConfig.MAGNET_DURATION = 60
GameConfig.MAGNET_DISCOUNT = 0.15 -- 15% off belt purchases while the magnet hums
GameConfig.SHIELD_DURATION = 60

-- Slap combos: slaps landed close together build a combo that hits harder.
GameConfig.SLAP_COMBO_WINDOW = 2 -- seconds between slaps to keep the combo
GameConfig.SLAP_COMBO_MAX = 5
GameConfig.SLAP_COMBO_BONUS = 10 -- extra power per combo step

-- Loyalty: every fifth shop purchase is 10% cheaper.
GameConfig.LOYALTY_PURCHASES_FOR_DISCOUNT = 5
GameConfig.LOYALTY_DISCOUNT = 0.10

return GameConfig
