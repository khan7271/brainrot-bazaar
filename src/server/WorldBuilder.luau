-- WorldBuilder: builds the whole 3D world of Brainrot Bazaar in code.
-- Baseplate, central plaza with a fountain, the conveyor belt, eight
-- player base plots around the plaza, lamps, trees, clouds, a sauce
-- river and the sky lighting. Nothing is placed by hand in Studio:
-- every part below is created here at runtime, so the place file only
-- needs this module and Rojo to rebuild the world.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local WorldBuilder = {}

local function makePart(name, size, position, color, material, anchored)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = anchored == nil and true or anchored
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function makeWedge(name, size, position, color)
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Size = size
	wedge.Position = position
	wedge.Color = color
	wedge.Material = Enum.Material.SmoothPlastic
	wedge.Anchored = true
	return wedge
end

function WorldBuilder.buildBaseplate(folder)
	local plate = makePart("Baseplate", Vector3.new(300, 2, 300), Vector3.new(0, -1, 0), Color3.fromRGB(110, 190, 90), Enum.Material.Grass)
	plate.CanCollide = true
	plate.Parent = folder
	-- Chequered plaza ground: alternating tiles make the centre readable.
	for gx = -2, 2 do
		for gz = -2, 2 do
			local tileColor = Color3.fromRGB(240, 225, 200)
			if (gx + gz) % 2 == 0 then
				tileColor = Color3.fromRGB(225, 200, 160)
			end
			local tile = makePart("PlazaTile", Vector3.new(8, 0.4, 8), Vector3.new(gx * 8, 0.2, gz * 8), tileColor, Enum.Material.SmoothPlastic)
			tile.Parent = folder
		end
	end
end

function WorldBuilder.buildPlaza(folder)
	-- Central fountain: the meeting point of the plaza.
	local basin = Instance.new("Part")
	basin.Name = "FountainBasin"
	basin.Shape = Enum.PartType.Cylinder
	basin.Size = Vector3.new(4, 10, 10)
	basin.CFrame = CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90))
	basin.Color = Color3.fromRGB(150, 150, 160)
	basin.Material = Enum.Material.Concrete
	basin.Anchored = true
	basin.Parent = folder

	local water = Instance.new("Part")
	water.Name = "FountainWater"
	water.Shape = Enum.PartType.Cylinder
	water.Size = Vector3.new(3, 8, 8)
	water.CFrame = CFrame.new(0, 2.4, 0) * CFrame.Angles(0, 0, math.rad(90))
	water.Color = Color3.fromRGB(60, 170, 255)
	water.Material = Enum.Material.Neon
	water.Transparency = 0.25
	water.Anchored = true
	water.CanCollide = false
	water.Parent = folder

	local spout = makePart("FountainSpout", Vector3.new(1, 4, 1), Vector3.new(0, 4, 0), Color3.fromRGB(150, 150, 160), Enum.Material.Concrete)
	spout.Parent = folder

	local sign = WorldBuilder.makeSign("BRAINROT BAZAAR", Vector3.new(0, 14, -24), Color3.fromRGB(255, 190, 40))
	sign.Parent = folder
end

-- A floating text sign made from a part plus a SurfaceGui billboard.
function WorldBuilder.makeSign(text, position, color)
	local board = makePart("SignBoard", Vector3.new(24, 5, 1), position, Color3.fromRGB(40, 40, 60), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.AlwaysOnTop = true
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = gui
	return board
end

function WorldBuilder.buildConveyor(folder)
	local length = GameConfig.CONVEYOR_LENGTH
	local width = GameConfig.CONVEYOR_WIDTH
	local belt = makePart("ConveyorBelt", Vector3.new(length, 1, width), Vector3.new(0, 1, -30), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
	belt.Parent = folder
	-- Moving chevrons painted on the belt so its motion reads at a glance.
	for i = 1, 12 do
		local x = -length / 2 + i * 10
		local stripe = makePart("BeltStripe", Vector3.new(4, 0.2, width - 1), Vector3.new(x, 1.6, -30), Color3.fromRGB(255, 190, 40), Enum.Material.Neon)
		stripe.CanCollide = false
		stripe.Parent = folder
	end
	-- Side rails keep the brainrots visibly on the belt.
	for _, side in ipairs({ -1, 1 }) do
		local rail = makePart("ConveyorRail", Vector3.new(length, 1.5, 0.6), Vector3.new(0, 1.8, -30 + side * (width / 2 + 0.3)), Color3.fromRGB(200, 60, 60), Enum.Material.Metal)
		rail.Parent = folder
	end
	-- End gates where brainrots roll in and out.
	for _, x in ipairs({ -length / 2, length / 2 }) do
		local gate = makePart("ConveyorGate", Vector3.new(1, 8, width + 2), Vector3.new(x, 5, -30), Color3.fromRGB(255, 120, 40), Enum.Material.Neon)
		gate.CanCollide = false
		gate.Parent = folder
	end
end

-- One base plot: a coloured pad, a back wall, a lock gate and six slots.
-- Returns the folder holding the plot and a list of slot positions.
function WorldBuilder.buildBasePlot(folder, index, ownerName)
	local angle = (index - 1) * (math.pi * 2 / GameConfig.BASE_COUNT)
	local cx = math.cos(angle) * GameConfig.BASE_RADIUS
	local cz = math.sin(angle) * GameConfig.BASE_RADIUS
	local plot = Instance.new("Folder")
	plot.Name = "BasePlot" .. index
	plot.Parent = folder

	local padColors = {
		Color3.fromRGB(255, 100, 100),
		Color3.fromRGB(100, 160, 255),
		Color3.fromRGB(100, 220, 120),
		Color3.fromRGB(255, 200, 60),
		Color3.fromRGB(200, 120, 255),
		Color3.fromRGB(255, 140, 200),
		Color3.fromRGB(120, 230, 230),
		Color3.fromRGB(255, 150, 60),
	}
	local pad = makePart("BasePad", Vector3.new(20, 1, 16), Vector3.new(cx, 0.5, cz), padColors[index], Enum.Material.SmoothPlastic)
	pad.Parent = plot

	-- Back wall so a base reads as a little shop front from the plaza.
	local wall = makePart("BaseWall", Vector3.new(20, 8, 1), Vector3.new(cx, 4, cz) + Vector3.new(-math.cos(angle) * 0, 0, 0), padColors[index], Enum.Material.SmoothPlastic)
	wall.CFrame = CFrame.new(cx, 4, cz) * CFrame.Angles(0, -angle + math.pi / 2, 0) * CFrame.new(0, 0, -7.5)
	wall.Parent = plot

	local sign = WorldBuilder.makeSign("BASE " .. index, Vector3.new(cx, 11, cz), Color3.fromRGB(255, 255, 255))
	sign.CFrame = CFrame.new(cx, 11, cz) * CFrame.Angles(0, -angle + math.pi, 0)
	sign.Parent = plot

	-- Six slots in two rows of three, facing the plaza.
	local slots = {}
	for row = 1, 2 do
		for col = 1, 3 do
			local offset = Vector3.new((col - 2) * 5, 0, (row - 1.5) * 5)
			local rotated = CFrame.Angles(0, -angle, 0) * offset
			local slotPos = Vector3.new(cx, 1, cz) + rotated
			local slot = makePart("Slot" .. ((row - 1) * 3 + col), Vector3.new(4, 0.4, 4), slotPos, Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
			slot.Transparency = 0.5
			slot.CanCollide = false
			slot.Parent = plot
			table.insert(slots, slotPos + Vector3.new(0, 1, 0))
		end
	end

	-- Lock gate: turns red and solid while the base lock is active.
	local gate = makePart("LockGate", Vector3.new(20, 6, 0.6), Vector3.new(cx, 3.5, cz), Color3.fromRGB(255, 60, 60), Enum.Material.Neon)
	gate.CFrame = CFrame.new(cx, 3.5, cz) * CFrame.Angles(0, -angle + math.pi / 2, 0) * CFrame.new(0, 0, 7.5)
	gate.Transparency = 0.85
	gate.CanCollide = false
	gate.Parent = plot

	return plot, slots, gate
end

function WorldBuilder.buildDecorations(folder)
	-- Lamp posts ringing the plaza.
	for i = 1, 8 do
		local angle = (i - 1) * (math.pi / 4)
		local x = math.cos(angle) * 26
		local z = math.sin(angle) * 26
		local pole = makePart("LampPole" .. i, Vector3.new(0.6, 7, 0.6), Vector3.new(x, 3.5, z), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
		pole.Parent = folder
		local lamp = makePart("LampLight" .. i, Vector3.new(1.6, 1.6, 1.6), Vector3.new(x, 7.4, z), Color3.fromRGB(255, 240, 150), Enum.Material.Neon)
		lamp.CanCollide = false
		lamp.Parent = folder
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 240, 150)
		light.Range = 18
		light.Brightness = 1
		light.Parent = lamp
	end
	-- Blocky trees at the map corners.
	for _, corner in ipairs({ { -70, -70 }, { 70, -70 }, { -70, 70 }, { 70, 70 }, { -90, 0 }, { 90, 0 } }) do
		local trunk = makePart("TreeTrunk", Vector3.new(2, 6, 2), Vector3.new(corner[1], 3, corner[2]), Color3.fromRGB(140, 90, 40), Enum.Material.Wood)
		trunk.Parent = folder
		local leaves = makePart("TreeLeaves", Vector3.new(7, 6, 7), Vector3.new(corner[1], 9, corner[2]), Color3.fromRGB(60, 180, 80), Enum.Material.SmoothPlastic)
		leaves.Parent = folder
	end
	-- A sauce river along the north edge: the tsunami's home.
	local river = makePart("SauceRiver", Vector3.new(300, 0.6, 10), Vector3.new(0, 0.4, -95), Color3.fromRGB(230, 60, 40), Enum.Material.Neon)
	river.Transparency = 0.2
	river.CanCollide = false
	river.Parent = folder
	-- Blocky clouds drifting overhead.
	for i = 1, 5 do
		local cloud = makePart("Cloud" .. i, Vector3.new(18, 4, 10), Vector3.new(-80 + i * 40, 45, -40 + i * 8), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
		cloud.CanCollide = false
		cloud.Parent = folder
	end
end

function WorldBuilder.buildLighting()
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(120, 120, 140)
	lighting.Brightness = 2
	lighting.GlobalShadows = true
	lighting.Outlines = false
	lighting.Technology = Enum.Technology.Future
	lighting.ClockTime = 14
	local sun = Instance.new("Sky")
	sun.CelestialBodiesShown = true
	sun.Parent = lighting
end

-- Build everything and return the base plots table the services use.
function WorldBuilder.buildWorld()
	local workspace = game:GetService("Workspace")
	local folder = Instance.new("Folder")
	folder.Name = "BazaarWorld"
	folder.Parent = workspace

	WorldBuilder.buildBaseplate(folder)
	WorldBuilder.buildPlaza(folder)
	WorldBuilder.buildConveyor(folder)
	WorldBuilder.buildDecorations(folder)
	WorldBuilder.buildLighting()

	local plots = {}
	for i = 1, GameConfig.BASE_COUNT do
		local plot, slots, gate = WorldBuilder.buildBasePlot(folder, i, "Base " .. i)
		plots[i] = { Plot = plot, Slots = slots, Gate = gate }
	end

	-- The tsunami wall: hidden far north until a wave starts.
	local wall = makePart("TsunamiWall", Vector3.new(300, 20, 4), Vector3.new(0, 10, -120), Color3.fromRGB(230, 60, 40), Enum.Material.Neon)
	wall.Transparency = 0.3
	wall.CanCollide = false
	wall.Parent = folder

	return { Folder = folder, Plots = plots, TsunamiWall = wall }
end

return WorldBuilder
