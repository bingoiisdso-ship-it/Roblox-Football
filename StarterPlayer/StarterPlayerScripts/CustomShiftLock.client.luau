local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TOGGLE_KEY = Enum.KeyCode.LeftControl

local SHOULDER_OFFSET = Vector3.new(1.65, 0.35, 0)
local CAMERA_SMOOTHNESS = 7
local ROTATION_SMOOTHNESS = 9
local DOT_SIZE = 5

local enabled = false
local currentOffset = Vector3.zero

local humanoid
local root

local gui = Instance.new("ScreenGui")
gui.Name = "FootballShiftLockUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

local dot = Instance.new("Frame")
dot.Name = "AimDot"
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromOffset(DOT_SIZE, DOT_SIZE)
dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
dot.BackgroundTransparency = 1
dot.BorderSizePixel = 0
dot.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = dot

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 0, 0)
stroke.Thickness = 1
stroke.Transparency = 1
stroke.Parent = dot

local dotTween
local strokeTween

local function animateDot(show)
	if dotTween then dotTween:Cancel() end
	if strokeTween then strokeTween:Cancel() end

	local info = TweenInfo.new(
		0.35,
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out
	)

	dotTween = TweenService:Create(dot, info, {
		BackgroundTransparency = show and 0 or 1,
		Size = show
			and UDim2.fromOffset(DOT_SIZE, DOT_SIZE)
			or UDim2.fromOffset(2, 2)
	})

	strokeTween = TweenService:Create(stroke, info, {
		Transparency = show and 0.35 or 1
	})

	dotTween:Play()
	strokeTween:Play()
end

local function setupCharacter(character)
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")

	humanoid.AutoRotate = true
	humanoid.CameraOffset = Vector3.zero

	enabled = false
	currentOffset = Vector3.zero

	animateDot(false)
end

player.CharacterAdded:Connect(setupCharacter)

if player.Character then
	setupCharacter(player.Character)
end

local function toggleShiftLock()
	enabled = not enabled

	if humanoid then
		humanoid.AutoRotate = not enabled
	end

	animateDot(enabled)

	if not enabled then
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
	end
end

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == TOGGLE_KEY then
		toggleShiftLock()
	end
end)

RunService:BindToRenderStep(
	"UltraSmoothFootballShiftLock",
	Enum.RenderPriority.Camera.Value - 1,
	function(dt)
		if not humanoid or not root then return end
		if humanoid.Health <= 0 then return end

		local camera = workspace.CurrentCamera
		if not camera then return end

		local cameraAlpha =
			1 - math.exp(-CAMERA_SMOOTHNESS * dt)

		local rotationAlpha =
			1 - math.exp(-ROTATION_SMOOTHNESS * dt)

		local targetOffset =
			enabled and SHOULDER_OFFSET or Vector3.zero

		currentOffset = currentOffset:Lerp(
			targetOffset,
			cameraAlpha
		)

		humanoid.CameraOffset = currentOffset

		if enabled then
			UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
			UIS.MouseIconEnabled = false

			local look = camera.CFrame.LookVector
			local flatLook = Vector3.new(
				look.X,
				0,
				look.Z
			)

			if flatLook.Magnitude > 0.01 then
				local targetRotation = CFrame.lookAt(
					root.Position,
					root.Position + flatLook.Unit
				)

				root.CFrame = root.CFrame:Lerp(
					targetRotation,
					rotationAlpha
				)
			end
		end
	end
)

print("Ultra Smooth Football Shift Lock Ready!")
