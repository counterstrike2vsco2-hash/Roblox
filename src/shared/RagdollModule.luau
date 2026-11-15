--!strict
-- RagdollModule.luau
-- Comprehensive, high-performance R15 and R6 Ragdoll System for Roblox
-- Inspired by Project C.A.R.L. and Ragdoll Engine physics

local RagdollModule = {}

-- Joint angle limit presets for natural anatomical movement
local JOINT_LIMITS: { [string]: { upperAngle: number, twistLower: number, twistUpper: number } } = {
	["Neck"] = { upperAngle = 35, twistLower = -30, twistUpper = 30 },
	["Waist"] = { upperAngle = 40, twistLower = -35, twistUpper = 35 },
	["LeftShoulder"] = { upperAngle = 80, twistLower = -60, twistUpper = 60 },
	["RightShoulder"] = { upperAngle = 80, twistLower = -60, twistUpper = 60 },
	["LeftElbow"] = { upperAngle = 80, twistLower = -10, twistUpper = 80 },
	["RightElbow"] = { upperAngle = 80, twistLower = -10, twistUpper = 80 },
	["LeftWrist"] = { upperAngle = 40, twistLower = -40, twistUpper = 40 },
	["RightWrist"] = { upperAngle = 40, twistLower = -40, twistUpper = 40 },
	["LeftHip"] = { upperAngle = 55, twistLower = -40, twistUpper = 40 },
	["RightHip"] = { upperAngle = 55, twistLower = -40, twistUpper = 40 },
	["LeftKnee"] = { upperAngle = 85, twistLower = -10, twistUpper = 85 },
	["RightKnee"] = { upperAngle = 85, twistLower = -10, twistUpper = 85 },
	["LeftAnkle"] = { upperAngle = 30, twistLower = -30, twistUpper = 30 },
	["RightAnkle"] = { upperAngle = 30, twistLower = -30, twistUpper = 30 },
	-- Fallbacks for R6 joints
	["Left Shoulder"] = { upperAngle = 80, twistLower = -60, twistUpper = 60 },
	["Right Shoulder"] = { upperAngle = 80, twistLower = -60, twistUpper = 60 },
	["Left Hip"] = { upperAngle = 55, twistLower = -40, twistUpper = 40 },
	["Right Hip"] = { upperAngle = 55, twistLower = -40, twistUpper = 40 },
}

-- Default limit if joint name is unlisted
local DEFAULT_LIMIT = { upperAngle = 60, twistLower = -45, twistUpper = 45 }

-- Set up attachments, ball sockets, and collision constraints for a character
function RagdollModule.SetupCharacter(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Mark as having ragdoll setup
	if character:FindFirstChild("RagdollConstraints") then return end

	local constraintFolder = Instance.new("Folder")
	constraintFolder.Name = "RagdollConstraints"
	constraintFolder.Parent = character

	local isRagdolledValue = character:FindFirstChild("IsRagdolled")
	if not isRagdolledValue then
		local val = Instance.new("BoolValue")
		val.Name = "IsRagdolled"
		val.Value = false
		val.Parent = character
	end

	-- Prevent character from breaking joints on death (keeps body intact as ragdoll!)
	humanoid.BreakJointsOnDeath = false

	-- Scan all Motor6Ds
	for _, desc in character:GetDescendants() do
		if desc:IsA("Motor6D") then
			local motor = desc :: Motor6D
			local part0 = motor.Part0
			local part1 = motor.Part1

			-- Ignore Root joint (keeps HumanoidRootPart anchored to LowerTorso so camera follows)
			if motor.Name == "Root" or motor.Name == "RootJoint" then
				continue
			end

			if part0 and part1 then
				-- Attachment 0
				local att0 = Instance.new("Attachment")
				att0.Name = "RagdollAtt0_" .. motor.Name
				att0.CFrame = motor.C0
				att0.Parent = part0

				-- Attachment 1
				local att1 = Instance.new("Attachment")
				att1.Name = "RagdollAtt1_" .. motor.Name
				att1.CFrame = motor.C1
				att1.Parent = part1

				-- BallSocketConstraint
				local socket = Instance.new("BallSocketConstraint")
				socket.Name = "RagdollSocket_" .. motor.Name
				socket.Attachment0 = att0
				socket.Attachment1 = att1
				socket.LimitsEnabled = true
				socket.TwistLimitsEnabled = true

				local limits = JOINT_LIMITS[motor.Name] or DEFAULT_LIMIT
				socket.UpperAngle = limits.upperAngle
				socket.TwistLowerAngle = limits.twistLower
				socket.TwistUpperAngle = limits.twistUpper
				socket.Restitution = 0.15
				socket.Enabled = false
				socket.Parent = constraintFolder

				-- NoCollisionConstraint between adjacent parts
				local noCol = Instance.new("NoCollisionConstraint")
				noCol.Name = "NoCol_" .. part0.Name .. "_" .. part1.Name
				noCol.Part0 = part0
				noCol.Part1 = part1
				noCol.Parent = constraintFolder
			end
		end
	end

	-- Also disable collision between limbs and Torso/RootPart to avoid self-flinging
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if rootPart then
		for _, part in character:GetChildren() do
			if part:IsA("BasePart") and part ~= rootPart then
				local noCol = Instance.new("NoCollisionConstraint")
				noCol.Name = "RootNoCol_" .. part.Name
				noCol.Part0 = rootPart
				noCol.Part1 = part
				noCol.Parent = constraintFolder
			end
		end
	end
end

-- Checks if character is currently ragdolled
function RagdollModule.IsRagdolled(character: Model): boolean
	local val = character:FindFirstChild("IsRagdolled") :: BoolValue?
	return val ~= nil and val.Value == true
end

-- Toggle ragdoll on or off
function RagdollModule.ToggleRagdoll(character: Model, impulse: Vector3?): boolean
	local current = RagdollModule.IsRagdolled(character)
	RagdollModule.SetRagdoll(character, not current, impulse)
	return not current
end

-- Set ragdoll state explicitly
function RagdollModule.SetRagdoll(character: Model, enable: boolean, impulse: Vector3?)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local constraintsFolder = character:FindFirstChild("RagdollConstraints")
	if not constraintsFolder then
		RagdollModule.SetupCharacter(character)
		constraintsFolder = character:FindFirstChild("RagdollConstraints")
	end

	local isRagdolledVal = character:FindFirstChild("IsRagdolled") :: BoolValue?
	if isRagdolledVal then
		isRagdolledVal.Value = enable
	end

	if enable then
		-- ENABLE RAGDOLL
		humanoid.AutoRotate = false

		-- Stop playing animations
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in animator:GetPlayingAnimationTracks() do
				track:Stop(0.1)
			end
		end

		-- Switch humanoid state
		humanoid.PlatformStand = true
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)

		-- Disable Motor6D joints and enable BallSockets
		for _, desc in character:GetDescendants() do
			if desc:IsA("Motor6D") then
				if desc.Name ~= "Root" and desc.Name ~= "RootJoint" then
					desc.Enabled = false
				end
			end
		end

		if constraintsFolder then
			for _, constraint in constraintsFolder:GetChildren() do
				if constraint:IsA("BallSocketConstraint") then
					constraint.Enabled = true
				end
			end
		end

		-- Set part collisions: body parts collide, root part does not
		if rootPart then
			rootPart.CanCollide = false
		end

		for _, part in character:GetChildren() do
			if part:IsA("BasePart") and part ~= rootPart then
				-- Skip invisible organ hitboxes
				if not part:GetAttribute("IsOrgan") then
					part.CanCollide = true
				end
			end
		end

		-- Apply optional physics impulse (e.g. from gunshot or shove)
		if impulse then
			local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or rootPart
			if torso and torso:IsA("BasePart") then
				torso:ApplyImpulse(impulse * torso.AssemblyMass)
			end
		end

	else
		-- DISABLE RAGDOLL (GET UP)
		if humanoid.Health <= 0 then
			-- Dead characters cannot get up
			return
		end

		-- Disable BallSockets and re-enable Motor6D joints
		if constraintsFolder then
			for _, constraint in constraintsFolder:GetChildren() do
				if constraint:IsA("BallSocketConstraint") then
					constraint.Enabled = false
				end
			end
		end

		for _, desc in character:GetDescendants() do
			if desc:IsA("Motor6D") then
				desc.Enabled = true
			end
		end

		-- Reset part collisions
		if rootPart then
			rootPart.CanCollide = true
		end

		for _, part in character:GetChildren() do
			if part:IsA("BasePart") and part ~= rootPart then
				part.CanCollide = false
			end
		end

		-- Smooth getup recovery
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true

		if rootPart then
			-- Slightly elevate to avoid clipping through floor
			local currentPos = rootPart.Position
			local look = rootPart.CFrame.LookVector
			local flatLook = Vector3.new(look.X, 0, look.Z).Unit
			if flatLook.Magnitude == 0 or flatLook ~= flatLook then
				flatLook = Vector3.new(0, 0, -1)
			end
			rootPart.CFrame = CFrame.new(currentPos + Vector3.new(0, 2.5, 0), currentPos + Vector3.new(0, 2.5, 0) + flatLook)
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero
		end

		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

return RagdollModule
