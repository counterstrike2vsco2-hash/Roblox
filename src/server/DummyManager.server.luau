--!strict
-- DummyManager.server.luau
-- Spawns, rigs, and manages anatomical R15 Dummies (Project C.A.R.L. style) with internal organs and ProximityPrompts

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RagdollModule = require(Shared:WaitForChild("RagdollModule"))

local DummyManager = {}

-- Helper to create an R15 body part
local function createPart(name: string, size: Vector3, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = true
	part.Parent = parent
	return part
end

-- Helper to create Motor6D
local function createMotor(name: string, part0: BasePart, part1: BasePart, c0: CFrame, c1: CFrame, parent: Instance): Motor6D
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = c0
	motor.C1 = c1
	motor.Parent = parent
	return motor
end

-- Build full R15 anatomical dummy
function DummyManager.CreateCarlDummy(spawnCFrame: CFrame, name: string?): Model
	local dummy = Instance.new("Model")
	dummy.Name = name or "C.A.R.L. (Anatomy Dummy)"
	dummy:SetAttribute("IsDummy", true)
	dummy:SetAttribute("SpawnPosition", spawnCFrame.Position)

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = 2.0
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = dummy

	local skinColor = Color3.fromRGB(230, 225, 215) -- Project C.A.R.L. mannequin tone

	-- HumanoidRootPart
	local hrp = createPart("HumanoidRootPart", Vector3.new(2, 2, 1), skinColor, dummy)
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.CFrame = spawnCFrame
	dummy.PrimaryPart = hrp

	-- LowerTorso & UpperTorso
	local lowerTorso = createPart("LowerTorso", Vector3.new(2, 0.8, 1), skinColor, dummy)
	lowerTorso.CFrame = spawnCFrame * CFrame.new(0, -0.6, 0)

	local upperTorso = createPart("UpperTorso", Vector3.new(2, 1.6, 1), skinColor, dummy)
	upperTorso.CFrame = spawnCFrame * CFrame.new(0, 0.6, 0)

	-- Head
	local head = createPart("Head", Vector3.new(1.2, 1.2, 1.2), skinColor, dummy)
	head.CFrame = spawnCFrame * CFrame.new(0, 2.0, 0)
	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	headMesh.Parent = head

	-- C.A.R.L. Visor / Markings (Dark line across face)
	local visorDecal = Instance.new("Decal")
	visorDecal.Name = "FaceMark"
	visorDecal.Face = Enum.NormalId.Front
	visorDecal.Texture = "rbxassetid://1212882264"
	visorDecal.Parent = head

	-- Limbs
	local lUpperArm = createPart("LeftUpperArm", Vector3.new(0.8, 1.1, 0.8), skinColor, dummy)
	local lLowerArm = createPart("LeftLowerArm", Vector3.new(0.8, 1.1, 0.8), skinColor, dummy)
	local lHand = createPart("LeftHand", Vector3.new(0.8, 0.4, 0.8), skinColor, dummy)

	local rUpperArm = createPart("RightUpperArm", Vector3.new(0.8, 1.1, 0.8), skinColor, dummy)
	local rLowerArm = createPart("RightLowerArm", Vector3.new(0.8, 1.1, 0.8), skinColor, dummy)
	local rHand = createPart("RightHand", Vector3.new(0.8, 0.4, 0.8), skinColor, dummy)

	local lUpperLeg = createPart("LeftUpperLeg", Vector3.new(0.8, 1.2, 0.8), skinColor, dummy)
	local lLowerLeg = createPart("LeftLowerLeg", Vector3.new(0.8, 1.2, 0.8), skinColor, dummy)
	local lFoot = createPart("LeftFoot", Vector3.new(0.8, 0.4, 0.8), skinColor, dummy)

	local rUpperLeg = createPart("RightUpperLeg", Vector3.new(0.8, 1.2, 0.8), skinColor, dummy)
	local rLowerLeg = createPart("RightLowerLeg", Vector3.new(0.8, 1.2, 0.8), skinColor, dummy)
	local rFoot = createPart("RightFoot", Vector3.new(0.8, 0.4, 0.8), skinColor, dummy)

	-- Motor6D Joints
	createMotor("Root", hrp, lowerTorso, CFrame.new(0, 0, 0), CFrame.new(0, 0, 0), lowerTorso)
	createMotor("Waist", lowerTorso, upperTorso, CFrame.new(0, 0.4, 0), CFrame.new(0, -0.8, 0), upperTorso)
	createMotor("Neck", upperTorso, head, CFrame.new(0, 0.8, 0), CFrame.new(0, -0.6, 0), head)

	-- Left Arm
	createMotor("LeftShoulder", upperTorso, lUpperArm, CFrame.new(-1.3, 0.6, 0), CFrame.new(0, 0.55, 0), lUpperArm)
	createMotor("LeftElbow", lUpperArm, lLowerArm, CFrame.new(0, -0.55, 0), CFrame.new(0, 0.55, 0), lLowerArm)
	createMotor("LeftWrist", lLowerArm, lHand, CFrame.new(0, -0.55, 0), CFrame.new(0, 0.2, 0), lHand)

	-- Right Arm
	createMotor("RightShoulder", upperTorso, rUpperArm, CFrame.new(1.3, 0.6, 0), CFrame.new(0, 0.55, 0), rUpperArm)
	createMotor("RightElbow", rUpperArm, rLowerArm, CFrame.new(0, -0.55, 0), CFrame.new(0, 0.55, 0), rLowerArm)
	createMotor("RightWrist", rLowerArm, rHand, CFrame.new(0, -0.55, 0), CFrame.new(0, 0.2, 0), rHand)

	-- Left Leg
	createMotor("LeftHip", lowerTorso, lUpperLeg, CFrame.new(-0.5, -0.4, 0), CFrame.new(0, 0.6, 0), lUpperLeg)
	createMotor("LeftKnee", lUpperLeg, lLowerLeg, CFrame.new(0, -0.6, 0), CFrame.new(0, 0.6, 0), lLowerLeg)
	createMotor("LeftAnkle", lLowerLeg, lFoot, CFrame.new(0, -0.6, 0), CFrame.new(0, 0.2, 0), lFoot)

	-- Right Leg
	createMotor("RightHip", lowerTorso, rUpperLeg, CFrame.new(0.5, -0.4, 0), CFrame.new(0, 0.6, 0), rUpperLeg)
	createMotor("RightKnee", rUpperLeg, rLowerLeg, CFrame.new(0, -0.6, 0), CFrame.new(0, 0.6, 0), rLowerLeg)
	createMotor("RightAnkle", rLowerLeg, rFoot, CFrame.new(0, -0.6, 0), CFrame.new(0, 0.2, 0), rFoot)

	----------------------------------------------------------------------
	-- PROJECT C.A.R.L. INTERNAL ANATOMICAL ORGANS
	----------------------------------------------------------------------
	local function createOrgan(organName: string, size: Vector3, color: Color3, parentLimb: BasePart, offset: Vector3): Part
		local organ = Instance.new("Part")
		organ.Name = organName
		organ.Size = size
		organ.Color = color
		organ.Material = Enum.Material.Neon
		organ.CanCollide = false
		organ.Transparency = 0.8 -- translucent by default, becomes visible in X-Ray!
		organ:SetAttribute("IsOrgan", true)
		organ.CFrame = parentLimb.CFrame * CFrame.new(offset)
		organ.Parent = dummy

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = parentLimb
		weld.Part1 = organ
		weld.Parent = organ

		return organ
	end

	-- Brain inside Head
	createOrgan("Brain", Vector3.new(0.7, 0.6, 0.7), Color3.fromRGB(220, 80, 100), head, Vector3.new(0, 0.1, 0))

	-- Heart inside UpperTorso
	createOrgan("Heart", Vector3.new(0.5, 0.5, 0.4), Color3.fromRGB(180, 10, 20), upperTorso, Vector3.new(-0.25, 0.1, -0.1))

	-- Lungs
	createOrgan("LeftLung", Vector3.new(0.4, 0.8, 0.4), Color3.fromRGB(200, 110, 130), upperTorso, Vector3.new(-0.45, 0.2, 0))
	createOrgan("RightLung", Vector3.new(0.4, 0.8, 0.4), Color3.fromRGB(200, 110, 130), upperTorso, Vector3.new(0.45, 0.2, 0))

	-- Spine running through Torso
	createOrgan("Spine", Vector3.new(0.3, 1.4, 0.3), Color3.fromRGB(240, 240, 240), upperTorso, Vector3.new(0, 0, 0.25))

	-- Stomach
	createOrgan("Stomach", Vector3.new(0.6, 0.5, 0.5), Color3.fromRGB(160, 60, 60), lowerTorso, Vector3.new(0, 0, -0.1))

	----------------------------------------------------------------------
	-- OVERHEAD BILLBOARD GUI (STATUS & ANATOMY INFO)
	----------------------------------------------------------------------
	local bb = Instance.new("BillboardGui")
	bb.Name = "StatusGui"
	bb.Size = UDim2.new(5, 0, 1.8, 0)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = head
	bb.Parent = head

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = bb

	local uicorner = Instance.new("UICorner")
	uicorner.CornerRadius = UDim.new(0, 6)
	uicorner.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.35, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = dummy.Name
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextScaled = true
	titleLabel.Parent = frame

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Name = "HpLabel"
	hpLabel.Size = UDim2.new(1, 0, 0.3, 0)
	hpLabel.Position = UDim2.new(0, 0, 0.35, 0)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text = "HP: 100/100 | СТАТУС: В НОРМЕ"
	hpLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
	hpLabel.Font = Enum.Font.GothamMedium
	hpLabel.TextScaled = true
	hpLabel.Parent = frame

	local ragdollLabel = Instance.new("TextLabel")
	ragdollLabel.Name = "RagdollLabel"
	ragdollLabel.Size = UDim2.new(1, 0, 0.3, 0)
	ragdollLabel.Position = UDim2.new(0, 0, 0.68, 0)
	ragdollLabel.BackgroundTransparency = 1
	ragdollLabel.Text = "[F/E: РЭГДОЛЛ] [R: ВОССТАНОВИТЬ]"
	ragdollLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
	ragdollLabel.Font = Enum.Font.Gotham
	ragdollLabel.TextScaled = true
	ragdollLabel.Parent = frame

	-- Update status GUI on health change or ragdoll toggle
	local function updateGui()
		if humanoid.Health <= 0 then
			hpLabel.Text = "☠️ МЕРТВ (ПОЛНЫЙ РЭГДОЛЛ)"
			hpLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
		else
			local isRag = RagdollModule.IsRagdolled(dummy)
			hpLabel.Text = string.format("HP: %d/100 | %s", math.floor(humanoid.Health), isRag and "🌀 РЭГДОЛЛ" or "🧍 СТОИТ")
			hpLabel.TextColor3 = isRag and Color3.fromRGB(255, 140, 50) or Color3.fromRGB(100, 255, 120)
		end
	end

	humanoid.HealthChanged:Connect(updateGui)
	local isRagVal = dummy:FindFirstChild("IsRagdolled") :: BoolValue?
	if isRagVal then
		isRagVal.Changed:Connect(updateGui)
	end

	----------------------------------------------------------------------
	-- PROXIMITY PROMPTS FOR INTERACTION
	----------------------------------------------------------------------
	-- [E] Toggle Ragdoll
	local togglePrompt = Instance.new("ProximityPrompt")
	togglePrompt.Name = "ToggleRagdollPrompt"
	togglePrompt.ActionText = "Переключить рэгдолл"
	togglePrompt.ObjectText = dummy.Name
	togglePrompt.KeyboardKeyCode = Enum.KeyCode.E
	togglePrompt.HoldDuration = 0
	togglePrompt.MaxActivationDistance = 12
	togglePrompt.RequiresLineOfSight = false
	togglePrompt.Parent = upperTorso

	togglePrompt.Triggered:Connect(function(player)
		RagdollModule.ToggleRagdoll(dummy)
		updateGui()
	end)

	-- [R] Revive / Reset Dummy
	local resetPrompt = Instance.new("ProximityPrompt")
	resetPrompt.Name = "ResetDummyPrompt"
	resetPrompt.ActionText = "Восстановить / Оживить"
	resetPrompt.ObjectText = dummy.Name
	resetPrompt.KeyboardKeyCode = Enum.KeyCode.R
	resetPrompt.HoldDuration = 0.5
	resetPrompt.MaxActivationDistance = 12
	resetPrompt.RequiresLineOfSight = false
	resetPrompt.Parent = upperTorso

	resetPrompt.Triggered:Connect(function(player)
		humanoid.Health = humanoid.MaxHealth
		RagdollModule.SetRagdoll(dummy, false)
		hrp.CFrame = spawnCFrame
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		updateGui()
	end)

	-- Set up ragdoll physics constraints
	RagdollModule.SetupCharacter(dummy)

	dummy.Parent = Workspace
	return dummy
end

-- Initialize default dummies in testing arena
task.spawn(function()
	task.wait(1)

	-- 1. Main C.A.R.L. Anatomy Dummy on the shooting range pedestal
	DummyManager.CreateCarlDummy(CFrame.new(0, 5, -25), "C.A.R.L. (Лабораторный Манекен)")

	-- 2. Dummy at the top of Stunt Stairs (ready to tumble down!)
	DummyManager.CreateCarlDummy(CFrame.new(35, 34, -15), "Манекен (Вершина Лестницы)")

	-- 3. Dummy at the top of Mega Ramp
	DummyManager.CreateCarlDummy(CFrame.new(-35, 28, -15), "Манекен (Вершина Горки)")
end)

return DummyManager
