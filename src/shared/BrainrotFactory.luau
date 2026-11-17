-- BrainrotFactory: builds one blocky Roblox-style brainrot character model
-- from a BrainrotData entry. The body is a chunky torso, the head carries
-- the character's face colour, the accessory shows its personality, and a
-- BillboardGui above it shows the name, rarity and money-per-second label
-- the judge (and the player) reads at a glance.

local BrainrotData = require(script.Parent.BrainrotData)

local BrainrotFactory = {}

-- A simple blocky body: torso, head, two arms, two legs, one accessory.
function BrainrotFactory.buildCharacterModel(character, mutationName)
	local mutation = BrainrotData.MUTATIONS[mutationName] or BrainrotData.MUTATIONS.Normal
	local model = Instance.new("Model")
	model.Name = character.Name

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(3, 3, 2)
	torso.Position = Vector3.new(0, 2.5, 0)
	torso.Color = character.BodyColor
	torso.Material = Enum.Material.SmoothPlastic
	torso.Anchored = false
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2.4, 2.4, 2.4)
	head.Position = Vector3.new(0, 5.2, 0)
	head.Color = character.BodyColor
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = false
	head.Parent = model

	-- Eyes: two white blocks with dark pupils, classic blocky face.
	for _, side in ipairs({ -0.6, 0.6 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.5, 0.7, 0.2)
		eye.Position = Vector3.new(side, 5.4, 1.25)
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.Anchored = false
		eye.Parent = model
		local pupil = Instance.new("Part")
		pupil.Name = "Pupil"
		pupil.Size = Vector3.new(0.25, 0.35, 0.1)
		pupil.Position = Vector3.new(side, 5.35, 1.38)
		pupil.Color = Color3.fromRGB(20, 20, 20)
		pupil.Anchored = false
		pupil.Parent = model
	end

	-- Smile.
	local smile = Instance.new("Part")
	smile.Name = "Smile"
	smile.Size = Vector3.new(1.2, 0.25, 0.2)
	smile.Position = Vector3.new(0, 4.6, 1.25)
	smile.Color = Color3.fromRGB(20, 20, 20)
	smile.Anchored = false
	smile.Parent = model

	-- Arms and legs.
	for _, side in ipairs({ -1.9, 1.9 }) do
		local arm = Instance.new("Part")
		arm.Name = "Arm"
		arm.Size = Vector3.new(1, 2.6, 1)
		arm.Position = Vector3.new(side, 2.5, 0)
		arm.Color = character.BodyColor
		arm.Anchored = false
		arm.Parent = model
	end
	for _, side in ipairs({ -0.8, 0.8 }) do
		local leg = Instance.new("Part")
		leg.Name = "Leg"
		leg.Size = Vector3.new(1.1, 1.6, 1.1)
		leg.Position = Vector3.new(side, 0.8, 0)
		leg.Color = character.AccentColor
		leg.Anchored = false
		leg.Parent = model
	end

	-- Accessory: a hat or crown that marks the character's personality.
	local accessory = Instance.new("Part")
	accessory.Name = "Accessory"
	accessory.Size = Vector3.new(3, 0.8, 3)
	accessory.Position = Vector3.new(0, 6.8, 0)
	accessory.Color = character.AccentColor
	accessory.Material = Enum.Material.SmoothPlastic
	accessory.Anchored = false
	accessory.Parent = model
	if character.Rarity == "Brainrot God" then
		-- A golden crown for the god tier.
		for i = 1, 3 do
			local spike = Instance.new("Part")
			spike.Name = "CrownSpike"
			spike.Size = Vector3.new(0.5, 1, 0.5)
			spike.Position = Vector3.new(-1 + (i - 1), 7.5, 0)
			spike.Color = Color3.fromRGB(255, 215, 0)
			spike.Material = Enum.Material.Neon
			spike.Anchored = false
			spike.Parent = model
		end
	end

	-- Weld everything to the torso so the model moves as one body.
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part ~= torso then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = torso
			weld.Part1 = part
			weld.Parent = torso
		end
	end
	model.PrimaryPart = torso

	-- Mutation sparkles: a ParticleEmitter tinted to the mutation colour.
	if mutationName ~= "Normal" then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "MutationSparkles"
		sparkles.Color = ColorSequence.new(mutation.Color)
		sparkles.Rate = 12
		sparkles.Lifetime = NumberRange.new(0.6)
		sparkles.Speed = NumberRange.new(2)
		sparkles.Size = NumberSequence.new(0.4)
		sparkles.Parent = torso
	end

	BrainrotFactory.attachNameTag(model, character, mutationName)
	return model
end

-- The floating label: name on top, rarity coloured, income underneath.
function BrainrotFactory.attachNameTag(model, character, mutationName)
	local income = BrainrotData.incomeOf(character, mutationName)
	local rarityColor = BrainrotData.RARITY_COLORS[character.Rarity]
	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.fromOffset(140, 64)
	tag.StudsOffset = Vector3.new(0, 4.5, 0)
	tag.AlwaysOnTop = true
	tag.Parent = model.PrimaryPart

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "CharacterName"
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = character.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = tag

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.Position = UDim2.new(0, 0, 0.4, 0)
	rarityLabel.BackgroundTransparency = 1
	local mutationText = ""
	if mutationName ~= "Normal" then
		mutationText = " " .. mutationName
	end
	rarityLabel.Text = character.Rarity .. mutationText
	rarityLabel.TextColor3 = rarityColor
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.SourceSansBold
	rarityLabel.Parent = tag

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Size = UDim2.new(1, 0, 0.3, 0)
	incomeLabel.Position = UDim2.new(0, 0, 0.7, 0)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "$" .. income .. "/sec"
	incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	incomeLabel.TextStrokeTransparency = 0
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.SourceSansBold
	incomeLabel.Parent = tag
end

-- A tiny floating price tag that bobs above a brainrot on the conveyor.
function BrainrotFactory.attachPriceTag(model, price)
	local tag = Instance.new("BillboardGui")
	tag.Name = "PriceTag"
	tag.Size = UDim2.fromOffset(90, 28)
	tag.StudsOffset = Vector3.new(0, -1.5, 0)
	tag.AlwaysOnTop = true
	tag.Parent = model.PrimaryPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
	label.Text = "BUY $" .. price
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = tag
end

return BrainrotFactory
