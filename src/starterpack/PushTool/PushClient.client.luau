--!strict
-- PushClient.client.luau
-- Client tool script for pushing other players and dummies into ragdoll

local Tool = script.Parent :: Tool
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local RequestPushRemote = ReplicatedStorage:WaitForChild("RequestPush") :: RemoteEvent

local cooldown = false

Tool.Activated:Connect(function()
	if cooldown then return end
	local character = LocalPlayer.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	cooldown = true
	task.delay(0.8, function()
		cooldown = false
	end)

	-- Find target in front of player
	local rayOrigin = hrp.Position
	local rayDirection = hrp.CFrame.LookVector * 8

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.FilterType = RaycastFilterType.Exclude

	local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result and result.Instance then
		local targetModel = result.Instance:FindFirstAncestorOfClass("Model")
		if targetModel and targetModel:FindFirstChildOfClass("Humanoid") then
			RequestPushRemote:FireServer(targetModel)
		end
	end
end)
