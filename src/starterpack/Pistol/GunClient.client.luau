--!strict
-- GunClient.client.luau
-- Ballistic raycast weapon with bullet tracer beams, muzzle flash, and sound

local Tool = script.Parent :: Tool
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local ShootRemote = ReplicatedStorage:WaitForChild("ShootWeapon") :: RemoteEvent

local cooldown = false

-- Create visual bullet tracer beam
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
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 220, 100), Color3.fromRGB(255, 100, 30))
	beam.Width0 = 0.15
	beam.Width1 = 0.05
	beam.Texture = "rbxassetid://131070686"
	beam.TextureSpeed = 0
	beam.FaceCamera = true
	beam.Parent = p0

	Debris:AddItem(p0, 0.12)
	Debris:AddItem(p1, 0.12)
end

Tool.Activated:Connect(function()
	if cooldown then return end
	local character = LocalPlayer.Character
	if not character then return end
	local handle = Tool:FindFirstChild("Handle") :: BasePart?
	if not handle then return end

	cooldown = true
	task.delay(0.2, function()
		cooldown = false
	end)

	local mouse = LocalPlayer:GetMouse()
	local targetPos = mouse.Hit.Position
	local startPos = handle.Position
	local direction = (targetPos - startPos).Unit

	-- Muzzle flash sound
	local sound = handle:FindFirstChildOfClass("Sound")
	if sound then
		sound:Play()
	end

	-- Visual tracer
	local hitPos = startPos + direction * 250
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.FilterType = RaycastFilterType.Exclude

	local result = Workspace:Raycast(startPos, direction * 250, raycastParams)
	if result then
		hitPos = result.Position
	end
	createTracer(startPos, hitPos)

	-- Fire authoritative server shoot event
	ShootRemote:FireServer("Pistol", startPos, direction)
end)
