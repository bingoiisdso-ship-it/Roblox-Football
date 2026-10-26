local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local head = character:WaitForChild("Head")

local MAX_STAMINA = 100
local DRAIN_RATE = 18
local REGEN_RATE = 14
local REGEN_DELAY = 0.8

local WALK_SPEED = 16
local SPRINT_SPEED = 20

local stamina = MAX_STAMINA
local holdingSprint = false
local exhausted = false
local lastSprint = 0

local gui = Instance.new("BillboardGui")
gui.Name = "StaminaBar"
gui.Adornee = head
gui.Size = UDim2.fromOffset(110, 15)
gui.StudsOffset = Vector3.new(0, 3.3, 0)
gui.AlwaysOnTop = true
gui.MaxDistance = 80
gui.Parent = character

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(12, 19, 26)
background.BackgroundTransparency = 1
background.BorderSizePixel = 0
background.Parent = gui

Instance.new("UICorner", background).CornerRadius = UDim.new(1, 0)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 105, 120)
stroke.Thickness = 1
stroke.Transparency = 1
stroke.Parent = background

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 3)
padding.PaddingRight = UDim.new(0, 3)
padding.PaddingTop = UDim.new(0, 3)
padding.PaddingBottom = UDim.new(0, 3)
padding.Parent = background

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = Color3.fromRGB(45, 225, 155)
fill.BackgroundTransparency = 1
fill.BorderSizePixel = 0
fill.Parent = background

Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 188, 210)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 240, 150))
})
gradient.Parent = fill

local visible = false
local displayStamina = MAX_STAMINA

local function setVisible(show)
	if visible == show then return end
	visible = show

	local info = TweenInfo.new(0.25, Enum.EasingStyle.Quad)

	TweenService:Create(background, info, {
		BackgroundTransparency = show and 0.2 or 1
	}):Play()

	TweenService:Create(stroke, info, {
		Transparency = show and 0.2 or 1
	}):Play()

	TweenService:Create(fill, info, {
		BackgroundTransparency = show and 0 or 1
	}):Play()
end

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		holdingSprint = true
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		holdingSprint = false
	end
end)

RunService.Heartbeat:Connect(function(dt)
	if humanoid.Health <= 0 then return end

	local moving = humanoid.MoveDirection.Magnitude > 0.05
	local sprinting = holdingSprint and moving and not exhausted
		and stamina > 0

	if sprinting then
		stamina = math.max(0, stamina - DRAIN_RATE * dt)
		lastSprint = os.clock()

		if stamina <= 0 then
			exhausted = true
		end
	elseif os.clock() - lastSprint >= REGEN_DELAY then
		stamina = math.min(MAX_STAMINA, stamina + REGEN_RATE * dt)

		if stamina >= 35 then
			exhausted = false
		end
	end

	humanoid.WalkSpeed = sprinting and SPRINT_SPEED or WALK_SPEED
	character:SetAttribute("IsSprinting", sprinting)

	displayStamina += (stamina - displayStamina)
		* (1 - math.exp(-12 * dt))

	fill.Size = UDim2.fromScale(
		math.clamp(displayStamina / MAX_STAMINA, 0, 1),
		1
	)

	if stamina < 25 then
		gradient.Enabled = false
		fill.BackgroundColor3 = Color3.fromRGB(255, 85, 95)
	else
		gradient.Enabled = true
	end

	local shouldShow = sprinting or stamina < 99.9
	setVisible(shouldShow)
end)
