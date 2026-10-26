local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local NORMAL_FOV = 70
local SPRINT_FOV = 82
local FOV_SMOOTHNESS = 7

local BOB_SPEED = 11
local BOB_AMOUNT = 0.045

local SHAKE_DURATION = 0.55
local SHAKE_STRENGTH = 0.16

local humanoid
local sprinting = false
local bobTime = 0
local shakeEnd = 0
local shakeStart = 0

local function setupCharacter(character)
	humanoid = character:WaitForChild("Humanoid")
	sprinting = false
	bobTime = 0
	shakeEnd = 0
end

player.CharacterAdded:Connect(setupCharacter)

if player.Character then
	setupCharacter(player.Character)
end

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		sprinting = true
	elseif input.KeyCode == Enum.KeyCode.Q then
		shakeStart = os.clock()
		shakeEnd = shakeStart + SHAKE_DURATION
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		sprinting = false
	end
end)

RunService:BindToRenderStep(
	"FootballCameraEffects",
	Enum.RenderPriority.Camera.Value + 1,
	function(dt)
		camera = workspace.CurrentCamera
		if not camera or not humanoid or humanoid.Health <= 0 then
			return
		end

		local moving = humanoid.MoveDirection.Magnitude > 0.05
		local grounded = humanoid.FloorMaterial ~= Enum.Material.Air

		local isSprinting = player.Character
			and player.Character:GetAttribute("IsSprinting") == true

		local targetFOV = isSprinting and 78 or NORMAL_FOV

		local alpha = 1 - math.exp(-FOV_SMOOTHNESS * dt)

		camera.FieldOfView +=
			(targetFOV - camera.FieldOfView) * alpha

		local bobOffset = Vector3.zero

		if moving and grounded then
			bobTime += dt * (sprinting and 15 or BOB_SPEED)

			local bobX = math.sin(bobTime) * BOB_AMOUNT
			local bobY = math.abs(math.cos(bobTime)) * BOB_AMOUNT

			bobOffset = Vector3.new(bobX, bobY, 0)
		else
			bobTime = 0
		end

		local shakeOffset = Vector3.zero
		local now = os.clock()

		if now < shakeEnd then
			local remaining = (shakeEnd - now) / SHAKE_DURATION
			local strength = SHAKE_STRENGTH * remaining

			local elapsed = now - shakeStart
			local x = math.noise(elapsed * 35, 0) * strength
			local y = math.noise(0, elapsed * 35) * strength

			shakeOffset = Vector3.new(x, y, 0)
		end

		camera.CFrame *= CFrame.new(bobOffset + shakeOffset)
	end
)

print("Football camera effects loaded!")
