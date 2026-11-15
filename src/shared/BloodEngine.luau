--!strict
-- BloodEngine.luau
-- Physics-based Blood Splatters, Arterial Fountains, Organ Penetration, and Decals
-- Inspired by Project C.A.R.L. and Advanced Blood Engine

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local BloodEngine = {}

-- Organ damage and effect definitions
export type OrganHitResult = {
	hitOrgan: boolean,
	organName: string?,
	damage: number,
	isFatal: boolean,
	forceRagdoll: boolean,
	message: string?,
	color: Color3,
}

local ORGAN_DATA: { [string]: { damage: number, isFatal: boolean, forceRagdoll: boolean, message: string, color: Color3 } } = {
	["Brain"] = {
		damage = 100,
		isFatal = true,
		forceRagdoll = true,
		message = "🎯 HEADSHOT: МОЗГ УНИЧТОЖЕН!",
		color = Color3.fromRGB(255, 60, 60),
	},
	["Heart"] = {
		damage = 80,
		isFatal = true,
		forceRagdoll = true,
		message = "❤️ ПРОБИТИЕ СЕРДЦА: АРТЕРИАЛЬНОЕ КРОВОТЕЧЕНИЕ!",
		color = Color3.fromRGB(220, 20, 20),
	},
	["Spine"] = {
		damage = 60,
		isFatal = false,
		forceRagdoll = true,
		message = "🦴 ПОЗВОНОЧНИК СЛОМАН: ПАРАЛИЧ!",
		color = Color3.fromRGB(255, 170, 50),
	},
	["LeftLung"] = {
		damage = 45,
		isFatal = false,
		forceRagdoll = true,
		message = "🫁 ЛЕВОЕ ЛЕГКОЕ ПРОБИТО!",
		color = Color3.fromRGB(220, 100, 120),
	},
	["RightLung"] = {
		damage = 45,
		isFatal = false,
		forceRagdoll = true,
		message = "🫁 ПРАВОЕ ЛЕГКОЕ ПРОБИТО!",
		color = Color3.fromRGB(220, 100, 120),
	},
	["Stomach"] = {
		damage = 35,
		isFatal = false,
		forceRagdoll = true,
		message = "🩸 БРЮШНОЕ РАНЕНИЕ!",
		color = Color3.fromRGB(180, 50, 50),
	},
}

-- Checks if a ray penetrates any internal organs inside the target character
function BloodEngine.CheckOrganPenetration(character: Model, rayOrigin: Vector3, rayDirection: Vector3): OrganHitResult
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.FilterType = RaycastFilterType.Include
	raycastParams.IgnoreWater = true

	-- Cast ray through character to detect any organ hitboxes
	local result = Workspace:Raycast(rayOrigin, rayDirection * 10, raycastParams)
	if result and result.Instance then
		local hitPart = result.Instance
		local organName = hitPart.Name

		-- Check if it matches an organ
		if ORGAN_DATA[organName] then
			local data = ORGAN_DATA[organName]
			return {
				hitOrgan = true,
				organName = organName,
				damage = data.damage,
				isFatal = data.isFatal,
				forceRagdoll = data.forceRagdoll,
				message = data.message,
				color = data.color,
			}
		end
	end

	-- Also check proximity to organs inside character if ray hit a body part
	local organs = {}
	for _, child in character:GetChildren() do
		if child:IsA("BasePart") and child:GetAttribute("IsOrgan") then
			table.insert(organs, child)
		end
	end

	-- Secondary penetration check against organ bounding boxes
	for _, organ in organs do
		local organPos = organ.Position
		local toOrgan = organPos - rayOrigin
		local projection = toOrgan:Dot(rayDirection.Unit)
		if projection > 0 and projection < rayDirection.Magnitude + 5 then
			local closestPoint = rayOrigin + rayDirection.Unit * projection
			local distance = (closestPoint - organPos).Magnitude
			local maxRadius = (organ.Size.Magnitude / 2) + 0.3
			if distance <= maxRadius then
				local data = ORGAN_DATA[organ.Name] or {
					damage = 40,
					isFatal = false,
					forceRagdoll = true,
					message = "🩸 ВНУТРЕННИЙ ОРГАН ПОВРЕЖДЕН!",
					color = Color3.fromRGB(200, 30, 30),
				}
				return {
					hitOrgan = true,
					organName = organ.Name,
					damage = data.damage,
					isFatal = data.isFatal,
					forceRagdoll = data.forceRagdoll,
					message = data.message,
					color = data.color,
				}
			end
		end
	end

	return {
		hitOrgan = false,
		organName = nil,
		damage = 25,
		isFatal = false,
		forceRagdoll = false,
		message = nil,
		color = Color3.fromRGB(150, 20, 20),
	}
end

-- Create burst of blood particles at hit position
function BloodEngine.SpawnBloodParticles(position: Vector3, normal: Vector3, intensity: number?)
	local count = intensity or 15

	local emitterPart = Instance.new("Part")
	emitterPart.Name = "BloodEmitter"
	emitterPart.Size = Vector3.new(0.2, 0.2, 0.2)
	emitterPart.Position = position
	emitterPart.Anchored = true
	emitterPart.CanCollide = false
	emitterPart.Transparency = 1
	emitterPart.Parent = Workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(130, 0, 0), Color3.fromRGB(90, 0, 0))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	emitter.Texture = "rbxassetid://241594419" -- Smooth circle particle
	emitter.Lifetime = NumberRange.new(0.4, 0.9)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(8, 22)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Acceleration = Vector3.new(0, -45, 0)
	emitter.Parent = emitterPart

	-- Orient emitter along normal
	emitterPart.CFrame = CFrame.lookAt(position, position + normal)
	emitter:Emit(count)

	Debris:AddItem(emitterPart, 1.5)
end

-- Spawn blood splatters on surfaces nearby
function BloodEngine.CreateSurfaceSplatters(origin: Vector3, direction: Vector3, count: number?)
	local splatterCount = count or 4
	local filter = RaycastParams.new()
	filter.FilterType = RaycastFilterType.Exclude
	filter.IgnoreWater = true

	for _ = 1, splatterCount do
		-- Random spray angle
		local randDir = (direction + Vector3.new(
			(math.random() - 0.5) * 1.2,
			(math.random() - 0.5) * 1.2,
			(math.random() - 0.5) * 1.2
		)).Unit

		local rayResult = Workspace:Raycast(origin, randDir * 12, filter)
		if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
			local hitPos = rayResult.Position
			local hitNormal = rayResult.Normal

			-- Create small blood decal part
			local splatter = Instance.new("Part")
			splatter.Name = "BloodSplatter"
			local size = math.random(8, 18) / 10
			splatter.Size = Vector3.new(size, 0.05, size)
			splatter.CFrame = CFrame.lookAt(hitPos + hitNormal * 0.02, hitPos + hitNormal) * CFrame.Angles(math.pi / 2, 0, math.random() * math.pi)
			splatter.Anchored = true
			splatter.CanCollide = false
			splatter.Material = Enum.Material.Glass
			splatter.Color = Color3.fromRGB(110, 0, 0)
			splatter.Transparency = 0.15
			splatter.CastShadow = false
			splatter.Parent = Workspace

			-- Fade out and remove after 20 seconds
			task.delay(18, function()
				if splatter and splatter.Parent then
					local tween = TweenService:Create(splatter, TweenInfo.new(2), { Transparency = 1 })
					tween:Play()
					tween.Completed:Connect(function()
						splatter:Destroy()
					end)
				end
			end)
		end
	end
end

-- Create expanding puddle of blood on the floor under a body
function BloodEngine.CreateBloodPuddle(groundPosition: Vector3, maxRadius: number?)
	local targetSize = maxRadius or 3.5

	local puddle = Instance.new("Part")
	puddle.Name = "BloodPuddle"
	puddle.Size = Vector3.new(0.2, 0.02, 0.2)
	puddle.Position = groundPosition + Vector3.new(0, 0.02, 0)
	puddle.Anchored = true
	puddle.CanCollide = false
	puddle.Material = Enum.Material.Glass
	puddle.Color = Color3.fromRGB(120, 0, 0)
	puddle.Transparency = 0.2
	puddle.CastShadow = false
	puddle.Shape = Enum.PartType.Cylinder
	-- Orient cylinder flat on ground
	puddle.CFrame = CFrame.new(puddle.Position) * CFrame.Angles(0, 0, math.pi / 2)
	puddle.Parent = Workspace

	-- Expand over 4 seconds
	local tween = TweenService:Create(puddle, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.02, targetSize, targetSize)
	})
	tween:Play()

	-- Clean up after 30 seconds
	Debris:AddItem(puddle, 30)
end

-- Create arterial blood spray fountain from a ruptured heart or vessel
function BloodEngine.CreateArterialFountain(attachmentParent: BasePart, duration: number?)
	local streamDuration = duration or 3.5

	local att = Instance.new("Attachment")
	att.Name = "ArterialAttachment"
	att.Parent = attachmentParent

	local fountain = Instance.new("ParticleEmitter")
	fountain.Name = "ArterialSpray"
	fountain.Color = ColorSequence.new(Color3.fromRGB(150, 0, 0), Color3.fromRGB(100, 0, 0))
	fountain.Size = NumberSequence.new(0.2, 0.4)
	fountain.Texture = "rbxassetid://241594419"
	fountain.Lifetime = NumberRange.new(0.5, 0.8)
	fountain.Rate = 35
	fountain.Speed = NumberRange.new(12, 18)
	fountain.SpreadAngle = Vector2.new(15, 15)
	fountain.Acceleration = Vector3.new(0, -35, 0)
	fountain.Parent = att

	-- Stop after duration
	task.delay(streamDuration, function()
		if fountain and fountain.Parent then
			fountain.Enabled = false
			Debris:AddItem(att, 1)
		end
	end)
end

return BloodEngine
