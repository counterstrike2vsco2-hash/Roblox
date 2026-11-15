--!strict
-- RagdollServer.server.luau
-- Authoritative server management for player and dummy ragdolls, ballistic penetration, and combat events

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RagdollModule = require(Shared:WaitForChild("RagdollModule"))
local BloodEngine = require(Shared:WaitForChild("BloodEngine"))
local WeaponConfig = require(Shared:WaitForChild("WeaponConfig"))

-- Create or get RemoteEvents
local function getOrCreateRemote(name: string): RemoteEvent
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end
	return remote :: RemoteEvent
end

local ToggleRagdollRemote = getOrCreateRemote("ToggleRagdoll")
local RequestPushRemote = getOrCreateRemote("RequestPush")
local ShootWeaponRemote = getOrCreateRemote("ShootWeapon")
local OrganHitRemote = getOrCreateRemote("OrganHitEvent")
local ToggleXRayRemote = getOrCreateRemote("ToggleXRay")
local ResetDummyRemote = getOrCreateRemote("ResetDummy")

-- Set up player character when spawned
local function onCharacterAdded(character: Model, player: Player)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

	-- Set up ragdoll joints
	RagdollModule.SetupCharacter(character)

	-- Keep character intact as ragdoll on death
	humanoid.Died:Connect(function()
		RagdollModule.SetRagdoll(character, true, Vector3.new(0, -10, 0))
	end)

	-- Fall impact check: if falling with high downward velocity, trigger ragdoll on hard landing
	local lastVelocityY = 0
	task.spawn(function()
		while character and character.Parent and humanoid.Health > 0 do
			if rootPart and rootPart.Parent then
				local currentVelY = rootPart.AssemblyLinearVelocity.Y
				if lastVelocityY < -65 and currentVelY > -10 then
					-- Hard impact with ground!
					RagdollModule.SetRagdoll(character, true, Vector3.new(0, 5, 0))
					BloodEngine.SpawnBloodParticles(rootPart.Position, Vector3.new(0, 1, 0), 10)
				end
				lastVelocityY = currentVelY
			end
			task.wait(0.1)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(char, player)
	end)
	if player.Character then
		onCharacterAdded(player.Character, player)
	end
end)

-- Handle player [F] key or UI button to toggle ragdoll
ToggleRagdollRemote.OnServerEvent:Connect(function(player, targetCharacter: Model?)
	local charToToggle = targetCharacter or player.Character
	if charToToggle and charToToggle:FindFirstChildOfClass("Humanoid") then
		local humanoid = charToToggle:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			RagdollModule.ToggleRagdoll(charToToggle)
		end
	end
end)

-- Handle Push Tool action
RequestPushRemote.OnServerEvent:Connect(function(player, targetCharacter: Model)
	local playerChar = player.Character
	if not playerChar then return end
	local playerHrp = playerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not playerHrp then return end

	local targetHrp = targetCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not targetHrp or not targetHumanoid or targetHumanoid.Health <= 0 then return end

	-- Check distance
	local dist = (playerHrp.Position - targetHrp.Position).Magnitude
	if dist <= 12 then
		local pushDir = playerHrp.CFrame.LookVector
		local impulse = pushDir * WeaponConfig.PushTool.ImpulseForward + Vector3.new(0, WeaponConfig.PushTool.ImpulseUp, 0)

		-- Force ragdoll on target and fling forward
		RagdollModule.SetRagdoll(targetCharacter, true, impulse)
		targetHumanoid:TakeDamage(5)
		BloodEngine.SpawnBloodParticles(targetHrp.Position, pushDir, 5)
	end
end)

-- Handle Weapon Fire (Pistols, Shotguns, etc.)
ShootWeaponRemote.OnServerEvent:Connect(function(player, weaponName: string, rayOrigin: Vector3, rayDirection: Vector3)
	local playerChar = player.Character
	if not playerChar then return end

	local config = WeaponConfig[weaponName] or WeaponConfig.Pistol
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { playerChar }
	raycastParams.FilterType = RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true

	local result = Workspace:Raycast(rayOrigin, rayDirection * config.Range, raycastParams)
	if result and result.Instance then
		local hitPart = result.Instance
		local hitPos = result.Position
		local hitNormal = result.Normal

		-- Find if hit a character
		local targetModel = hitPart:FindFirstAncestorOfClass("Model")
		local targetHumanoid = targetModel and targetModel:FindFirstChildOfClass("Humanoid")

		if targetModel and targetHumanoid and targetHumanoid.Health > 0 then
			-- Check organ penetration
			local organResult = BloodEngine.CheckOrganPenetration(targetModel, hitPos, rayDirection)

			local damage = config.Damage or 25
			local forceRagdoll = false

			if organResult.hitOrgan then
				damage = organResult.damage
				forceRagdoll = organResult.forceRagdoll

				-- Send notification to shooter client for HUD combat text
				OrganHitRemote:FireClient(player, organResult)

				-- Arterial fountain if heart was hit
				if organResult.organName == "Heart" then
					local torso = targetModel:FindFirstChild("UpperTorso") or hitPart
					if torso:IsA("BasePart") then
						BloodEngine.CreateArterialFountain(torso, 4)
					end
				end
			elseif hitPart.Name == "Head" then
				damage = damage * (config.HeadshotMultiplier or 2)
				forceRagdoll = true
				OrganHitRemote:FireClient(player, {
					hitOrgan = true,
					organName = "Head",
					message = "🎯 ВЫСТРЕЛ В ГОЛОВУ! (HEADSHOT)",
					color = Color3.fromRGB(255, 80, 80),
					damage = damage,
				})
			end

			-- Apply damage
			targetHumanoid:TakeDamage(damage)

			-- Trigger ragdoll if lethal, fatal organ, or heavy blast
			if forceRagdoll or targetHumanoid.Health <= 0 or weaponName == "Shotgun" then
				local impulseVector = rayDirection.Unit * config.ImpulseForce + Vector3.new(0, 10, 0)
				RagdollModule.SetRagdoll(targetModel, true, impulseVector)
			end

			-- Spawn blood FX
			BloodEngine.SpawnBloodParticles(hitPos, hitNormal, 18)
			BloodEngine.CreateSurfaceSplatters(hitPos, rayDirection, 5)

			-- If heavily damaged or ragdolled, spawn floor puddle
			local floorRay = Workspace:Raycast(hitPos, Vector3.new(0, -10, 0))
			if floorRay then
				BloodEngine.CreateBloodPuddle(floorRay.Position, 2.5)
			end
		else
			-- Hit environmental surface (wall/floor/box)
			BloodEngine.CreateSurfaceSplatters(hitPos, rayDirection, 2)
		end
	end
end)

-- Handle X-Ray mode toggle for Dummies (sets skin transparency to show internal organs)
local isXRayActive = false
ToggleXRayRemote.OnServerEvent:Connect(function(player)
	isXRayActive = not isXRayActive
	for _, desc in Workspace:GetDescendants() do
		if desc:IsA("Model") and desc:GetAttribute("IsDummy") then
			for _, part in desc:GetChildren() do
				if part:IsA("BasePart") then
					if part:GetAttribute("IsOrgan") then
						-- Organ always visible
						part.Transparency = isXRayActive and 0.1 or 0.8
					else
						-- Skin part
						part.Transparency = isXRayActive and 0.65 or 0
					end
				end
			end
		end
	end
end)

-- Handle Dummy Reset / Revive
ResetDummyRemote.OnServerEvent:Connect(function(player, dummyModel: Model)
	if dummyModel and dummyModel:FindFirstChildOfClass("Humanoid") then
		local humanoid = dummyModel:FindFirstChildOfClass("Humanoid") :: Humanoid
		humanoid.Health = humanoid.MaxHealth
		RagdollModule.SetRagdoll(dummyModel, false)

		local rootPart = dummyModel:FindFirstChild("HumanoidRootPart") :: BasePart?
		local originalPos = dummyModel:GetAttribute("SpawnPosition") :: Vector3?
		if rootPart and originalPos then
			rootPart.CFrame = CFrame.new(originalPos)
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero
		end
	end
end)

print("[Server] Ragdoll Server initialized successfully.")
