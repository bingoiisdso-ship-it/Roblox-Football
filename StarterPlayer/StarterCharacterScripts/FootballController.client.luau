-- FOOTBALL CONTROLLER
-- Hold to raise shot height
-- A/D only curves while held

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

local animations = require(RS:WaitForChild("FootballAnimations"))
local Physics = require(RS:WaitForChild("FootballPhysics"))
local remote = RS:WaitForChild("FootballAction")

-- SETTINGS
local FULL_CHARGE_TIME = 3.2
local CURVE_SMOOTHNESS = 4

local tracks = {}

for name, id in pairs(animations) do
	local assetId = tostring(id)

	if assetId ~= "0" and assetId ~= "rbxassetid://0" then
		local animation = Instance.new("Animation")

		animation.AnimationId =
			assetId:find("rbxassetid://", 1, true)
			and assetId
			or "rbxassetid://" .. assetId

		local track = animator:LoadAnimation(animation)

		if name == "Idle" then
			track.Priority = Enum.AnimationPriority.Idle
			track.Looped = true

		elseif name == "Walk"
			or name == "Run"
			or name == "Sprint" then

			track.Priority = Enum.AnimationPriority.Movement
			track.Looped = true
		else
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = false
		end

		tracks[name] = track
	end
end

local currentTrack
local acting = false

local aiming = nil
local aimStarted = 0

local curve = 0
local angle = 0

local keys = {
	[Enum.KeyCode.F] = "Kick",
	[Enum.KeyCode.E] = "Pass",
	[Enum.KeyCode.R] = "PowerShot"
}

local function play(name, speed)
	local track = tracks[name]

	if name == "Sprint" and not track then
		track = tracks.Run
	end

	if not track then return end

	if currentTrack == track and track.IsPlaying then
		track:AdjustSpeed(speed or 1)
		return
	end

	if currentTrack then
		currentTrack:Stop(0.12)
	end

	currentTrack = track
	track:Play(0.12)
	track:AdjustSpeed(speed or 1)
end

local function updateMovement()
	if acting then return end

	if humanoid.MoveDirection.Magnitude < 0.05 then
		play("Idle")

	elseif character:GetAttribute("IsSprinting") then
		play("Sprint", 1.2)

	elseif humanoid.WalkSpeed <= 10 then
		play("Walk")

	else
		play("Run")
	end
end

local function performAction(name, shotCurve, shotAngle)
	if acting then return end
	acting = true

	local track = tracks[name]

	if track then
		play(name)
	end

	if name == "Tackle" then
		remote:FireServer("Tackle")
	else
		local camera = workspace.CurrentCamera

		if camera then
			remote:FireServer(
				"Shoot",
				name,
				camera.CFrame.LookVector,
				shotCurve or 0,
				shotAngle or 0
			)
		end
	end

	if track then
		local connection
		local finished = false

		local function finish()
			if finished then return end
			finished = true

			if connection then
				connection:Disconnect()
			end

			acting = false
			currentTrack = nil
			updateMovement()
		end

		connection = track.Stopped:Connect(finish)

		task.delay(
			math.max(track.Length, 0.8) + 0.5,
			finish
		)
	else
		task.delay(0.45, function()
			acting = false
		end)
	end
end

local function calculateAngle()
	if not aiming then return 0 end

	local settings = Physics.Shots[aiming]

	local holdTime = os.clock() - aimStarted

	local progress = math.clamp(
		holdTime / FULL_CHARGE_TIME,
		0,
		1
	)

	local eased = progress ^ 1.35

	return settings.MinAngle
		+ (settings.MaxAngle - settings.MinAngle)
		* eased
end

local function getCurveDirection()
	local left =
		UIS:IsKeyDown(Enum.KeyCode.A)
		or UIS:IsKeyDown(Enum.KeyCode.Left)

	local right =
		UIS:IsKeyDown(Enum.KeyCode.D)
		or UIS:IsKeyDown(Enum.KeyCode.Right)

	if left == right then
		return 0
	elseif left then
		return -1
	else
		return 1
	end
end

local function startAim(action)
	if acting or aiming then return end

	local ball = workspace:FindFirstChild("MatchFootball")

	if not ball then return end

	if ball:GetAttribute("OwnerUserId") ~= player.UserId then
		return
	end

	aiming = action
	aimStarted = os.clock()

	angle = 0
	curve = 0

	character:SetAttribute("AimingAction", action)
	character:SetAttribute("AimingAngle", 0)
	character:SetAttribute("AimingCurve", 0)
end

local function stopAim(action)
	if aiming ~= action then return end

	angle = calculateAngle()

	if getCurveDirection() == 0 then
		curve = 0
	end

	local finalAngle = angle
	local finalCurve = curve

	aiming = nil

	character:SetAttribute("AimingAction", "")
	character:SetAttribute("AimingAngle", 0)
	character:SetAttribute("AimingCurve", 0)

	performAction(action, finalCurve, finalAngle)
end

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end

	local action = keys[input.KeyCode]

	if action then
		startAim(action)

	elseif input.KeyCode == Enum.KeyCode.Q then
		if not aiming then
			performAction("Tackle")
		end
	end
end)

UIS.InputEnded:Connect(function(input)
	local action = keys[input.KeyCode]

	if action then
		stopAim(action)
	end
end)

character:SetAttribute("AimingAction", "")
character:SetAttribute("AimingCurve", 0)
character:SetAttribute("AimingAngle", 0)

RunService.RenderStepped:Connect(function(dt)
	if aiming then
		angle = calculateAngle()

		local direction = getCurveDirection()

		if direction == 0 then
			curve = 0
		else
			curve += (direction - curve)
				* math.min(
					CURVE_SMOOTHNESS * dt,
					1
				)
		end

		character:SetAttribute("AimingAngle", angle)
		character:SetAttribute("AimingCurve", curve)
	end

	updateMovement()
end)

-- Play slide tackle once before Idle
local startupTrack = tracks.Tackle

if startupTrack then
	acting = true

	startupTrack.Looped = false
	startupTrack:Play(0.1)

	startupTrack.Stopped:Once(function()
		acting = false
		currentTrack = nil
		updateMovement()
	end)

	task.delay(2, function()
		if acting and startupTrack.IsPlaying then
			startupTrack:Stop(0.15)
		end
	end)
else
	play("Idle")
end
