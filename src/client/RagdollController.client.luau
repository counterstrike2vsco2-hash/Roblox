--!strict
-- RagdollController.client.luau
-- Handles player input for [F] Ragdoll Toggle, [X] X-Ray Mode, and Camera Tracking

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ToggleRagdollRemote = ReplicatedStorage:WaitForChild("ToggleRagdoll") :: RemoteEvent
local ToggleXRayRemote = ReplicatedStorage:WaitForChild("ToggleXRay") :: RemoteEvent

local debounce = false

-- Function to request ragdoll toggle
local function requestRagdollToggle()
	if debounce then return end
	debounce = true
	task.delay(0.35, function()
		debounce = false
	end)

	ToggleRagdollRemote:FireServer()
end

-- Listen for keyboard inputs
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- [F] Key: Toggle Ragdoll for self
	if input.KeyCode == Enum.KeyCode.F then
		requestRagdollToggle()
	end

	-- [X] Key: Toggle X-Ray Organ View on Dummies
	if input.KeyCode == Enum.KeyCode.X then
		ToggleXRayRemote:FireServer()
	end
end)

-- Bind custom event for UI clicks
local BindableToggle = Instance.new("BindableEvent")
BindableToggle.Name = "ClientToggleRagdoll"
BindableToggle.Parent = script

BindableToggle.Event:Connect(function()
	requestRagdollToggle()
end)

print("[Client] RagdollController loaded. Press [F] to Ragdoll!")
