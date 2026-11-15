--!strict
-- MapBuilder.server.luau
-- Builds the Ragdoll & Ballistics Testing Laboratory (Stunt Stairs, Mega Ramp, Trampoline, Kinetic Spinner)

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local MapBuilder = {}

local function createPart(name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function MapBuilder.BuildLab()
	local mapFolder = Workspace:FindFirstChild("RagdollLabMap")
	if mapFolder then
		return -- Map already built
	end

	mapFolder = Instance.new("Folder")
	mapFolder.Name = "RagdollLabMap"
	mapFolder.Parent = Workspace

	----------------------------------------------------------------------
	-- 1. BASEPLATE & MAIN ARENA FLOOR
	----------------------------------------------------------------------
	local baseplate = createPart("LabFloor", Vector3.new(512, 10, 512), Vector3.new(0, -5, 0), Color3.fromRGB(28, 30, 36), Enum.Material.Concrete, mapFolder)

	-- Grid texture on floor
	local texture = Instance.new("Texture")
	texture.Texture = "rbxassetid://6372755229" -- Grid texture
	texture.Face = Enum.NormalId.Top
	texture.StudsPerTileU = 8
	texture.StudsPerTileV = 8
	texture.Transparency = 0.6
	texture.Parent = baseplate

	----------------------------------------------------------------------
	-- 2. SPAWN PLATFORM
	----------------------------------------------------------------------
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "LabSpawn"
	spawnLoc.Size = Vector3.new(16, 1, 16)
	spawnLoc.Position = Vector3.new(0, 0.5, 15)
	spawnLoc.Anchored = true
	spawnLoc.CanCollide = true
	spawnLoc.Color = Color3.fromRGB(45, 50, 60)
	spawnLoc.Material = Enum.Material.SmoothPlastic
	spawnLoc.Duration = 0
	spawnLoc.Parent = mapFolder

	local spawnDecal = Instance.new("Decal")
	spawnDecal.Face = Enum.NormalId.Top
	spawnDecal.Texture = "rbxassetid://1212882264"
	spawnDecal.Parent = spawnLoc

	-- Neon border for spawn
	createPart("SpawnBorder", Vector3.new(16.4, 0.4, 16.4), Vector3.new(0, 0.3, 15), Color3.fromRGB(0, 180, 255), Enum.Material.Neon, mapFolder)

	----------------------------------------------------------------------
	-- 3. THE STUNT STAIRS (30 STEPS TALL)
	----------------------------------------------------------------------
	local stairsFolder = Instance.new("Folder")
	stairsFolder.Name = "StuntStairs"
	stairsFolder.Parent = mapFolder

	local startX = 35
	local startZ = 15
	local stepWidth = 12
	local stepDepth = 2.2
	local stepHeight = 1.05
	local numSteps = 30

	for i = 1, numSteps do
		local y = i * stepHeight
		local z = startZ - (i * stepDepth)
		local stepColor = (i % 2 == 0) and Color3.fromRGB(50, 55, 65) or Color3.fromRGB(40, 44, 52)
		local step = createPart("Step_" .. i, Vector3.new(stepWidth, stepHeight, stepDepth), Vector3.new(startX, y - (stepHeight / 2), z), stepColor, Enum.Material.Metal, stairsFolder)

		-- Yellow warning stripes on step edge
		if i % 5 == 0 then
			createPart("StairStripe_" .. i, Vector3.new(stepWidth, 0.1, 0.4), Vector3.new(startX, y + 0.05, z + (stepDepth / 2) - 0.2), Color3.fromRGB(240, 180, 20), Enum.Material.Neon, stairsFolder)
		end
	end

	-- Top Observation Platform
	local topPlatform = createPart("StairsTopPlatform", Vector3.new(16, 2, 14), Vector3.new(startX, numSteps * stepHeight - 1, startZ - (numSteps * stepDepth) - 7), Color3.fromRGB(35, 40, 48), Enum.Material.Metal, stairsFolder)

	-- Platform railing with open tumble exit facing stairs
	createPart("RailBack", Vector3.new(16, 4, 1), topPlatform.Position + Vector3.new(0, 3, -7), Color3.fromRGB(200, 200, 200), Enum.Material.SmoothPlastic, stairsFolder)
	createPart("RailLeft", Vector3.new(1, 4, 14), topPlatform.Position + Vector3.new(-8, 3, 0), Color3.fromRGB(200, 200, 200), Enum.Material.SmoothPlastic, stairsFolder)
	createPart("RailRight", Vector3.new(1, 4, 14), topPlatform.Position + Vector3.new(8, 3, 0), Color3.fromRGB(200, 200, 200), Enum.Material.SmoothPlastic, stairsFolder)

	----------------------------------------------------------------------
	-- 4. THE MEGA SLIDE / RAMP
	----------------------------------------------------------------------
	local rampFolder = Instance.new("Folder")
	rampFolder.Name = "MegaRamp"
	rampFolder.Parent = mapFolder

	local rampX = -35
	local rampTopPos = Vector3.new(rampX, 26, -20)
	local rampBottomPos = Vector3.new(rampX, 1, 15)

	-- Slide surface (Angled WedgePart)
	local rampWedge = Instance.new("WedgePart")
	rampWedge.Name = "SlideWedge"
	rampWedge.Size = Vector3.new(14, 26, 40)
	rampWedge.CFrame = CFrame.new(rampX, 13, -2.5) * CFrame.Angles(0, math.pi, 0)
	rampWedge.Anchored = true
	rampWedge.Color = Color3.fromRGB(0, 120, 215)
	rampWedge.Material = Enum.Material.Ice -- Super slippery for maximum ragdoll sliding!
	rampWedge.Parent = rampFolder

	-- Top staging platform for ramp
	createPart("RampTopPlatform", Vector3.new(16, 2, 12), rampTopPos + Vector3.new(0, -1, -8), Color3.fromRGB(40, 45, 55), Enum.Material.Metal, rampFolder)

	-- Jump kicker at bottom of slide
	local kicker = Instance.new("WedgePart")
	kicker.Name = "SlideKicker"
	kicker.Size = Vector3.new(14, 3, 6)
	kicker.CFrame = CFrame.new(rampX, 1.5, 20)
	kicker.Anchored = true
	kicker.Color = Color3.fromRGB(255, 140, 0)
	kicker.Material = Enum.Material.SmoothPlastic
	kicker.Parent = rampFolder

	----------------------------------------------------------------------
	-- 5. SUPER TRAMPOLINE / LAUNCHPAD
	----------------------------------------------------------------------
	local trampoline = createPart("SuperTrampoline", Vector3.new(18, 1.2, 18), Vector3.new(0, 0.6, -55), Color3.fromRGB(0, 255, 180), Enum.Material.Neon, mapFolder)

	local bounceCooldown = false
	trampoline.Touched:Connect(function(hit)
		if bounceCooldown then return end
		local char = hit:FindFirstAncestorOfClass("Model")
		if char and char:FindFirstChildOfClass("Humanoid") then
			bounceCooldown = true
			task.delay(0.25, function() bounceCooldown = false end)

			local hrp = char:FindFirstChild("HumanoidRootPart") or hit
			if hrp and hrp:IsA("BasePart") then
				-- Fling into air with huge upward velocity!
				hrp.AssemblyLinearVelocity = Vector3.new(math.random(-10, 10), 95, math.random(-25, -10))

				-- Create flash effect
				local flash = Instance.new("PointLight")
				flash.Color = Color3.fromRGB(0, 255, 200)
				flash.Range = 25
				flash.Brightness = 10
				flash.Parent = trampoline
				TweenService:Create(flash, TweenInfo.new(0.5), { Brightness = 0 }):Play()
				game:GetService("Debris"):AddItem(flash, 0.6)
			end
		end
	end)

	-- Trampoline Frame
	createPart("TrampolineBorder", Vector3.new(20, 1.5, 20), Vector3.new(0, 0.5, -55), Color3.fromRGB(20, 25, 30), Enum.Material.Metal, mapFolder)

	----------------------------------------------------------------------
	-- 6. KINETIC SWEEPER / SPINNER (KNOCKS PLAYERS & DUMMIES OVER)
	----------------------------------------------------------------------
	local spinnerFolder = Instance.new("Folder")
	spinnerFolder.Name = "KineticSpinner"
	spinnerFolder.Parent = mapFolder

	local spinnerCenter = Vector3.new(0, 1, -100)

	-- Spinner circular ring arena
	createPart("SpinnerArena", Vector3.new(45, 1, 45), spinnerCenter, Color3.fromRGB(35, 38, 45), Enum.Material.Concrete, spinnerFolder)

	-- Rotating Pillar
	local post = createPart("SpinnerPost", Vector3.new(3, 4, 3), spinnerCenter + Vector3.new(0, 2, 0), Color3.fromRGB(180, 30, 30), Enum.Material.Metal, spinnerFolder)

	-- Rotating Bar
	local bar = Instance.new("Part")
	bar.Name = "SweeperBar"
	bar.Size = Vector3.new(38, 1.8, 1.8)
	bar.Position = spinnerCenter + Vector3.new(0, 2, 0)
	bar.Anchored = true
	bar.CanCollide = true
	bar.Color = Color3.fromRGB(255, 200, 30)
	bar.Material = Enum.Material.Neon
	bar.Parent = spinnerFolder

	-- Rotate continuously
	task.spawn(function()
		local angle = 0
		while bar and bar.Parent do
			angle = (angle + 1.8) % 360
			bar.CFrame = CFrame.new(spinnerCenter + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.rad(angle), 0)
			task.wait(0.03)
		end
	end)

	----------------------------------------------------------------------
	-- 7. SHOOTING RANGE BENCH & TARGET MARKERS
	----------------------------------------------------------------------
	local shootingFolder = Instance.new("Folder")
	shootingFolder.Name = "ShootingRange"
	shootingFolder.Parent = mapFolder

	-- Pedestal for C.A.R.L. Dummy
	createPart("CarlPedestal", Vector3.new(8, 1, 8), Vector3.new(0, 0.5, -25), Color3.fromRGB(50, 55, 65), Enum.Material.Metal, shootingFolder)
	createPart("PedestalGlow", Vector3.new(8.4, 0.2, 8.4), Vector3.new(0, 0.2, -25), Color3.fromRGB(255, 60, 60), Enum.Material.Neon, shootingFolder)

	-- Shooting stall counter / bench
	createPart("FiringBench", Vector3.new(16, 3, 3), Vector3.new(0, 1.5, -5), Color3.fromRGB(40, 45, 52), Enum.Material.WoodPlanks, shootingFolder)

	print("[Server] Ragdoll Testing Lab Map generated.")
end

-- Generate map on server start
MapBuilder.BuildLab()

return MapBuilder
