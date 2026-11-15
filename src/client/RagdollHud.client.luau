--!strict
-- RagdollHud.client.luau
-- Displays controls helper, ragdoll status badge, X-Ray toggle button, and Project C.A.R.L. organ hit notifications

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local OrganHitRemote = ReplicatedStorage:WaitForChild("OrganHitEvent") :: RemoteEvent
local ToggleRagdollRemote = ReplicatedStorage:WaitForChild("ToggleRagdoll") :: RemoteEvent
local ToggleXRayRemote = ReplicatedStorage:WaitForChild("ToggleXRay") :: RemoteEvent

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RagdollHudGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

----------------------------------------------------------------------
-- TOP TITLE BANNER
----------------------------------------------------------------------
local topBanner = Instance.new("Frame")
topBanner.Name = "TopBanner"
topBanner.Size = UDim2.new(0, 480, 0, 42)
topBanner.Position = UDim2.new(0.5, -240, 0, 12)
topBanner.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
topBanner.BackgroundTransparency = 0.25
topBanner.BorderSizePixel = 0
topBanner.Parent = screenGui

local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 8)
bannerCorner.Parent = topBanner

local bannerStroke = Instance.new("UIStroke")
bannerStroke.Color = Color3.fromRGB(0, 180, 255)
bannerStroke.Thickness = 1.5
bannerStroke.Transparency = 0.4
bannerStroke.Parent = topBanner

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "PROJECT C.A.R.L. // ROBLOX RAGDOLL ENGINE"
titleText.TextColor3 = Color3.fromRGB(240, 245, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 16
titleText.Parent = topBanner

----------------------------------------------------------------------
-- CONTROLS & STATUS CARD (LEFT SIDE)
----------------------------------------------------------------------
local card = Instance.new("Frame")
card.Name = "ControlsCard"
card.Size = UDim2.new(0, 290, 0, 210)
card.Position = UDim2.new(0, 16, 0.5, -105)
card.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
card.BackgroundTransparency = 0.2
card.BorderSizePixel = 0
card.Parent = screenGui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 8)
cardCorner.Parent = card

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = Color3.fromRGB(80, 90, 110)
cardStroke.Thickness = 1
cardStroke.Transparency = 0.5
cardStroke.Parent = card

local cardTitle = Instance.new("TextLabel")
cardTitle.Size = UDim2.new(1, -20, 0, 26)
cardTitle.Position = UDim2.new(0, 10, 0, 8)
cardTitle.BackgroundTransparency = 1
cardTitle.Text = "⚙️ УПРАВЛЕНИЕ И СТАТУС"
cardTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
cardTitle.Font = Enum.Font.GothamBold
cardTitle.TextSize = 14
cardTitle.TextXAlignment = Enum.TextXAlignment.Left
cardTitle.Parent = card

-- [F] Ragdoll Button
local fButton = Instance.new("TextButton")
fButton.Name = "RagdollButton"
fButton.Size = UDim2.new(1, -20, 0, 36)
fButton.Position = UDim2.new(0, 10, 0, 38)
fButton.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
fButton.BorderSizePixel = 0
fButton.Text = "🌀 [F] ТВОЙ РЭГДОЛЛ: ВЫКЛ"
fButton.TextColor3 = Color3.fromRGB(100, 255, 120)
fButton.Font = Enum.Font.GothamBold
fButton.TextSize = 13
fButton.Parent = card

local fCorner = Instance.new("UICorner")
fCorner.CornerRadius = UDim.new(0, 6)
fCorner.Parent = fButton

fButton.MouseButton1Click:Connect(function()
	ToggleRagdollRemote:FireServer()
end)

-- [X] X-Ray Button
local xButton = Instance.new("TextButton")
xButton.Name = "XRayButton"
xButton.Size = UDim2.new(1, -20, 0, 32)
xButton.Position = UDim2.new(0, 10, 0, 80)
xButton.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
xButton.BorderSizePixel = 0
xButton.Text = "👁️ [X] РЕНТГЕН ОРГАНОВ C.A.R.L."
xButton.TextColor3 = Color3.fromRGB(255, 200, 80)
xButton.Font = Enum.Font.GothamBold
xButton.TextSize = 12
xButton.Parent = card

local xCorner = Instance.new("UICorner")
xCorner.CornerRadius = UDim.new(0, 6)
xCorner.Parent = xButton

xButton.MouseButton1Click:Connect(function()
	ToggleXRayRemote:FireServer()
end)

-- Instruction list label
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 80)
infoLabel.Position = UDim2.new(0, 10, 0, 120)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "• [F] — Включить / встать из рэгдолла\n• [E] на манекене — Уронить / поднять\n• [R] на манекене — Восстановить HP\n• [1, 2, 3] — Пистолет, Дробовик, Толчок"
infoLabel.TextColor3 = Color3.fromRGB(180, 190, 205)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 11
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Parent = card

-- Monitor player ragdoll state to update button badge
task.spawn(function()
	while true do
		local char = LocalPlayer.Character
		if char then
			local isRag = char:FindFirstChild("IsRagdolled") :: BoolValue?
			if isRag and isRag.Value then
				fButton.Text = "🌀 [F] ТВОЙ РЭГДОЛЛ: АКТИВЕН"
				fButton.TextColor3 = Color3.fromRGB(255, 120, 50)
				fButton.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
			else
				fButton.Text = "🧍 [F] ТВОЙ РЭГДОЛЛ: ВЫКЛ (СТОИТ)"
				fButton.TextColor3 = Color3.fromRGB(100, 255, 120)
				fButton.BackgroundColor3 = Color3.fromRGB(30, 45, 35)
			end
		end
		task.wait(0.2)
	end
end)

----------------------------------------------------------------------
-- CRITICAL ORGAN HIT POPUP NOTIFICATIONS (PROJECT C.A.R.L. STYLE)
----------------------------------------------------------------------
local toastContainer = Instance.new("Frame")
toastContainer.Name = "ToastContainer"
toastContainer.Size = UDim2.new(0, 400, 0, 200)
toastContainer.Position = UDim2.new(0.5, -200, 0.2, 0)
toastContainer.BackgroundTransparency = 1
toastContainer.Parent = screenGui

OrganHitRemote.OnClientEvent:Connect(function(organData)
	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(1, 0, 0, 40)
	toast.Position = UDim2.new(0, 0, 0, 0)
	toast.BackgroundColor3 = Color3.fromRGB(25, 15, 15)
	toast.BackgroundTransparency = 0.2
	toast.BorderSizePixel = 0
	toast.Parent = toastContainer

	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0, 6)
	toastCorner.Parent = toast

	local toastStroke = Instance.new("UIStroke")
	toastStroke.Color = organData.color or Color3.fromRGB(255, 50, 50)
	toastStroke.Thickness = 1.5
	toastStroke.Parent = toast

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = organData.message or "КРИТИЧЕСКОЕ ПОПАДАНИЕ!"
	label.TextColor3 = organData.color or Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 14
	label.Parent = toast

	-- Animate popup
	toast.Position = UDim2.new(0, 0, 0, -20)
	toast.BackgroundTransparency = 1
	label.TextTransparency = 1

	local popIn = TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 0.2,
	})
	local labelFade = TweenService:Create(label, TweenInfo.new(0.25), { TextTransparency = 0 })
	popIn:Play()
	labelFade:Play()

	-- Fade out after 2.5 seconds
	task.delay(2.5, function()
		if toast and toast.Parent then
			local fadeOut = TweenService:Create(toast, TweenInfo.new(0.4), {
				Position = UDim2.new(0, 0, 0, -30),
				BackgroundTransparency = 1,
			})
			TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				toast:Destroy()
			end)
		end
	end)
end)

print("[Client] Ragdoll HUD loaded.")
