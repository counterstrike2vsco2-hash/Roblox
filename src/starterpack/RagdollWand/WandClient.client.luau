--!strict
-- WandClient.client.luau
-- Magic testing wand to click and toggle ragdoll on any dummy or player

local Tool = script.Parent :: Tool
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local ToggleRagdollRemote = ReplicatedStorage:WaitForChild("ToggleRagdoll") :: RemoteEvent
local RequestPushRemote = ReplicatedStorage:WaitForChild("RequestPush") :: RemoteEvent

Tool.Activated:Connect(function()
	local mouse = LocalPlayer:GetMouse()
	local targetPart = mouse.Target
	if not targetPart then return end

	local targetModel = targetPart:FindFirstAncestorOfClass("Model")
	if targetModel and targetModel:FindFirstChildOfClass("Humanoid") then
		-- Toggle ragdoll on targeted character
		ToggleRagdollRemote:FireServer(targetModel)
	end
end)
