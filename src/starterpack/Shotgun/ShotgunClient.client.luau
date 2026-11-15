--!strict
-- ShotgunClient.client.luau
-- 8-pellet high spread shotgun with heavy kinetic blast impulse

local Tool = script.Parent :: Tool
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local ShootRemote = ReplicatedStorage:WaitForChild("ShootWeapon") :: RemoteEvent

local cooldown = false

local function createTracer(startPos: Vector3, endPos: Vector3)
	local p0 = Instance.new("Part")
	p0.Size = Vector3.new(0.1, 0.1, 0.1)
	p0.Position = startPos
	p0.Anchored = true
	p0.CanCollide = false
	p0.Transparency = 1
	p0.Parent = Workspace

	local p1 = Instance.new("Part")
	p1.Size = Vector3.new(0.1, 0.1, 0.1)
	p1.Position = endPos
	p1.Anchored = true
	p1.CanCollide = false
	p1.Transparency = 1
	p1.Parent = Workspace

	local att0 = Instance.new("Attachment")
	att0.Parent = p0
	local att1 = Instance.new("Attachment")
	att1.Parent = p1

	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 180, 50), Color3.fromRGB(255, 60, 20))
	beam.Width0 = 0.25
	beam.Width1 = 0.1
	beam.FaceCamera = true
	beam.Parent = p0

	Debris:AddItem(p0, 0.15)
	Debris:AddItem(p1, 0.15)
end

Tool.Activated:Connect(function()
	if cooldown then return end
	local character = LocalPlayer.Character
	if not character then return end
	local handle = Tool:FindFirstChild("Handle") :: BasePart?
	if not handle then return end

	cooldown = true
	task.delay(0.85, function()
		cooldown = false
	end)

	local sound = handle:FindFirstChildOfClass("Sound")
	if sound then
		sound:Play()
	end

	local mouse = LocalPlayer:GetMouse()
	local targetPos = mouse.Hit.Position
	local startPos = handle.Position
	local baseDir = (targetPos - startPos).Unit

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.FilterType = RaycastFilterType.Exclude

	-- Fire 8 spread pellets
	for _ = 1, 8 do
		local spread = Vector3.new(
			(math.random() - 0.5) * 0.12,
			(math.random() - 0.5) * 0.12,
			(math.random() - 0.5) * 0.12
		)
		local pelletDir = (baseDir + spread).Unit

		local hitPos = startPos + pelletDir * 120
		local result = Workspace:Raycast(startPos, pelletDir * 120, raycastParams)
		if result then
			hitPos = result.Position
		end
		createTracer(startPos, hitPos)

		ShootRemote:FireServer("Shotgun", startPos, pelletDir)
	end
end)
