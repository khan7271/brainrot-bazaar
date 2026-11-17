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
}

-- Slap
GameConfig.SLAP_BASE_POWER = 30
GameConfig.SLAP_RANGE = 12
GameConfig.SLAP_COOLDOWN = 1

-- World layout
GameConfig.PLAZA_RADIUS = 18
GameConfig.SPAWN_POSITION = Vector3.new(0, 5, 60)

return GameConfig
