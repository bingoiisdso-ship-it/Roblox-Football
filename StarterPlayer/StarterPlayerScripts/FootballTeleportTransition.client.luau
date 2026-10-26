local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TS = game:GetService("TweenService")

local player = Players.LocalPlayer
local event = RS:WaitForChild("FootballTeleportFX")

local gui = Instance.new("ScreenGui")
gui.Name = "FootballTeleportTransition"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = player:WaitForChild("PlayerGui")

local screen = Instance.new("Frame")
screen.Size = UDim2.fromScale(1, 1)
screen.Position = UDim2.fromScale(-1, 0)
screen.BackgroundColor3 = Color3.fromRGB(5, 17, 28)
screen.BorderSizePixel = 0
screen.Parent = gui

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 15, 27)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(13, 69, 62)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 24, 40))
})
gradient.Rotation = 25
gradient.Parent = screen

local ball = Instance.new("TextLabel")
ball.AnchorPoint = Vector2.new(0.5, 0.5)
ball.Position = UDim2.fromScale(0.5, 0.37)
ball.Size = UDim2.fromOffset(110, 110)
ball.BackgroundTransparency = 1
ball.Text = "⚽"
ball.TextScaled = true
ball.Parent = screen

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.56)
title.Size = UDim2.fromScale(0.9, 0.12)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "BACK TO KICKOFF"
title.TextColor3 = Color3.fromRGB(240, 255, 250)
title.TextScaled = true
title.Parent = screen

local titleLimit = Instance.new("UITextSizeConstraint")
titleLimit.MaxTextSize = 42
titleLimit.Parent = title

local subtitle = Instance.new("TextLabel")
subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
subtitle.Position = UDim2.fromScale(0.5, 0.65)
subtitle.Size = UDim2.fromScale(0.85, 0.06)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamMedium
subtitle.Text = "GET READY FOR THE NEXT PLAY"
subtitle.TextColor3 = Color3.fromRGB(115, 220, 195)
subtitle.TextScaled = true
subtitle.Parent = screen

local subLimit = Instance.new("UITextSizeConstraint")
subLimit.MaxTextSize = 17
subLimit.Parent = subtitle

local busy = false

local function tween(object, properties, duration)
	local animation = TS:Create(
		object,
		TweenInfo.new(
			duration,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		properties
	)
	animation:Play()
	return animation
end

event.OnClientEvent:Connect(function(action, message)
	if action == "Cover" then
		busy = true

		title.Text = message or "BACK TO KICKOFF"

		screen.Position = UDim2.fromScale(-1, 0)

		tween(screen, {
			Position = UDim2.fromScale(0, 0)
		}, 0.5)

	elseif action == "Reveal" then
		if not busy then return end

		tween(screen, {
			Position = UDim2.fromScale(1, 0)
		}, 0.55)

		task.delay(0.6, function()
			screen.Position = UDim2.fromScale(-1, 0)
			busy = false
		end)
	end
end)
