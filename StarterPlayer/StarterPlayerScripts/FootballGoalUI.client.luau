local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remote = RS:WaitForChild("FootballGoalFX")

local gui = Instance.new("ScreenGui")
gui.Name = "FootballGoalUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = player:WaitForChild("PlayerGui")

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(255, 235, 160)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = gui

local activeBanner
local shakeUntil = 0

RunService:BindToRenderStep(
	"FootballGoalCameraShake",
	Enum.RenderPriority.Camera.Value + 2,
	function()
		local remaining = shakeUntil - os.clock()

		if remaining <= 0 then return end

		local camera = workspace.CurrentCamera
		if not camera then return end

		local power = math.min(1, remaining / 1.2)
		local t = os.clock()

		local x = math.sin(t * 80) * 0.17 * power
		local y = math.cos(t * 95) * 0.14 * power
		local roll = math.sin(t * 55) * math.rad(1.3) * power

		camera.CFrame *= CFrame.new(x, y, 0)
			* CFrame.Angles(0, 0, roll)
	end
)

local function makeText(parent, name, content, y, height, color, size)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, -24, 0, height)
	label.Position = UDim2.new(0, 12, 0, y)
	label.BackgroundTransparency = 1
	label.Text = content
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color
	label.TextScaled = true
	label.Parent = parent

	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = size
	limit.MinTextSize = 12
	limit.Parent = label

	return label
end

remote.OnClientEvent:Connect(function(data)
	shakeUntil = os.clock() + 1.5

	flash.BackgroundTransparency = 0.23

	TweenService:Create(
		flash,
		TweenInfo.new(0.7, Enum.EasingStyle.Quad),
		{BackgroundTransparency = 1}
	):Play()

	if activeBanner then
		activeBanner:Destroy()
	end

	local banner = Instance.new("Frame")
	banner.Name = "GoalBanner"
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.fromScale(0.5, -0.3)
	banner.Size = UDim2.new(0.86, 0, 0, 195)
	banner.BackgroundColor3 = Color3.fromRGB(9, 22, 30)
	banner.BackgroundTransparency = 0.05
	banner.Rotation = -5
	banner.Parent = gui

	activeBanner = banner

	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = Vector2.new(680, 195)
	sizeLimit.Parent = banner

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 22)
	corner.Parent = banner

	local outline = Instance.new("UIStroke")
	outline.Color = Color3.fromRGB(65, 255, 180)
	outline.Thickness = 3
	outline.Parent = banner

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(
			0, Color3.fromRGB(10, 42, 53)
		),
		ColorSequenceKeypoint.new(
			1, Color3.fromRGB(9, 17, 32)
		)
	})
	gradient.Rotation = 25
	gradient.Parent = banner

	makeText(
		banner,
		"GoalTitle",
		"GOOOOOOOAL!",
		8, 94,
		Color3.fromRGB(105, 255, 190),
		72
	)

	makeText(
		banner,
		"Scorer",
		tostring(data.Scorer) .. " SCORED!",
		100, 38,
		Color3.fromRGB(255, 255, 255),
		28
	)

	makeText(
		banner,
		"Total",
		"TOTAL GOALS: " .. tostring(data.GoalCount),
		142, 27,
		Color3.fromRGB(255, 220, 85),
		20
	)

	TweenService:Create(
		banner,
		TweenInfo.new(
			0.65,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Position = UDim2.fromScale(0.5, 0.27),
			Rotation = 0
		}
	):Play()

	task.delay(3.1, function()
		if not banner.Parent then return end

		TweenService:Create(
			banner,
			TweenInfo.new(
				0.55,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.In
			),
			{
				Position = UDim2.fromScale(0.5, -0.3),
				Rotation = 5
			}
		):Play()

		task.delay(0.6, function()
			if banner.Parent then
				banner:Destroy()
			end
		end)
	end)
end)
