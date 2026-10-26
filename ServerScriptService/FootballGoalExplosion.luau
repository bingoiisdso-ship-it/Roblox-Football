local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ball = workspace:WaitForChild("MatchFootball")
local goalFolder = workspace:WaitForChild("FootballGoalLines")

local function getEvent(parent, name, className)
	local event = parent:FindFirstChild(name)
	if not event then
		event = Instance.new(className)
		event.Name = name
		event.Parent = parent
	end
	return event
end

local goalStep = getEvent(SSS, "FootballGoalStep", "BindableEvent")
local goalControl = getEvent(SSS, "FootballGoalControl", "BindableEvent")
local goalFX = getEvent(RS, "FootballGoalFX", "RemoteEvent")

local totalGoals = RS:FindFirstChild("TotalFootballGoals")

if not totalGoals then
	totalGoals = Instance.new("IntValue")
	totalGoals.Name = "TotalFootballGoals"
	totalGoals.Parent = RS
end

local RAGDOLL_DURATION = 3.5
local RESET_DELAY = 4.3
local BLAST_HORIZONTAL = 78
local BLAST_VERTICAL = 92
local GOAL_COOLDOWN = 5

local nextGoalAllowed = 0

local function ragdollPlayer(player, origin)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	if character:GetAttribute("GoalRagdolled") then
		return
	end

	character:SetAttribute("GoalRagdolled", true)

	local oldAutoRotate = humanoid.AutoRotate
	local oldRequiresNeck = humanoid.RequiresNeck

	humanoid.RequiresNeck = false
	humanoid.AutoRotate = false

	local container = Instance.new("Folder")
	container.Name = "GoalRagdollConstraints"
	container.Parent = character

	local motors = {}
	local attachments = {}
	local collisionStates = {}

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			collisionStates[part] = part.CanCollide

			if part ~= root
				and part.Name ~= "Handle" then
				part.CanCollide = true
			end
		end
	end

	-- Preserve root-to-body connections.
	-- Convert movable body joints into BallSockets.
	for _, joint in ipairs(character:GetDescendants()) do
		if joint:IsA("Motor6D")
			and joint.Part0
			and joint.Part1
			and joint.Part0 ~= root
			and joint.Part1 ~= root then

			local a0 = Instance.new("Attachment")
			a0.Name = "GoalRagdollA0"
			a0.CFrame = joint.C0
			a0.Parent = joint.Part0

			local a1 = Instance.new("Attachment")
			a1.Name = "GoalRagdollA1"
			a1.CFrame = joint.C1
			a1.Parent = joint.Part1

			local socket = Instance.new("BallSocketConstraint")
			socket.Name = "GoalRagdollSocket"
			socket.Attachment0 = a0
			socket.Attachment1 = a1
			socket.LimitsEnabled = true
			socket.UpperAngle = 75
			socket.TwistLimitsEnabled = true
			socket.TwistLowerAngle = -55
			socket.TwistUpperAngle = 55
			socket.Parent = container

			table.insert(attachments, a0)
			table.insert(attachments, a1)
			table.insert(motors, joint)

			joint.Enabled = false
		end
	end

	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end

	local torso = character:FindFirstChild("Torso") or root

	local outward = Vector3.new(
		root.Position.X - origin.X,
		0,
		root.Position.Z - origin.Z
	)

	if outward.Magnitude < 0.1 then
		outward = Vector3.new(1, 0, 0)
	end

	outward = outward.Unit

	local launchVelocity =
		outward * BLAST_HORIZONTAL
		+ Vector3.new(0, BLAST_VERTICAL, 0)

	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	root.AssemblyLinearVelocity = launchVelocity

	torso:ApplyImpulse(
		launchVelocity * torso.AssemblyMass
	)

	torso:ApplyAngularImpulse(
		Vector3.new(
			math.random(-20, 20),
			math.random(-25, 25),
			math.random(-20, 20)
		) * torso.AssemblyMass
	)

	task.delay(RAGDOLL_DURATION, function()
		if not character.Parent then return end

		for _, joint in ipairs(motors) do
			if joint.Parent then
				joint.Enabled = true
			end
		end

		for _, attachment in ipairs(attachments) do
			if attachment.Parent then
				attachment:Destroy()
			end
		end

		container:Destroy()

		for part, original in pairs(collisionStates) do
			if part.Parent then
				part.CanCollide = original
			end
		end

		if humanoid.Parent and humanoid.Health > 0 then
			root.AssemblyAngularVelocity = Vector3.zero

			local look = root.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)

			if flat.Magnitude > 0.1 then
				root.CFrame = CFrame.lookAt(
					root.Position,
					root.Position + flat.Unit
				)
			end

			humanoid.RequiresNeck = oldRequiresNeck
			humanoid.PlatformStand = false
			humanoid.AutoRotate = oldAutoRotate
			humanoid:ChangeState(
				Enum.HumanoidStateType.GettingUp
			)

			pcall(function()
				root:SetNetworkOwnershipAuto()
			end)
		end

		character:SetAttribute("GoalRagdolled", false)
	end)
end

local function createBlast(position)
	local effectFolder = Instance.new("Folder")
	effectFolder.Name = "GoalMegaExplosion"
	effectFolder.Parent = workspace

	Debris:AddItem(effectFolder, 5)

	local colors = {
		Color3.fromRGB(255, 200, 45),
		Color3.fromRGB(0, 255, 200),
		Color3.fromRGB(255, 85, 120)
	}

	for i = 1, 3 do
		local sphere = Instance.new("Part")
		sphere.Name = "GoalShockwave"
		sphere.Shape = Enum.PartType.Ball
		sphere.Material = Enum.Material.Neon
		sphere.Color = colors[i]
		sphere.Size = Vector3.new(3, 3, 3)
		sphere.CFrame = CFrame.new(position)
		sphere.Anchored = true
		sphere.CanCollide = false
		sphere.CanTouch = false
		sphere.CanQuery = false
		sphere.Transparency = 0.25
		sphere.Parent = effectFolder

		TweenService:Create(
			sphere,
			TweenInfo.new(
				0.65 + i * 0.18,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.Out
			),
			{
				Size = Vector3.new(
					65 + i * 35,
					65 + i * 35,
					65 + i * 35
				),
				Transparency = 1
			}
		):Play()
	end

	local emitterPart = Instance.new("Part")
	emitterPart.Name = "GoalFireworks"
	emitterPart.Size = Vector3.one
	emitterPart.Position = position
	emitterPart.Anchored = true
	emitterPart.Transparency = 1
	emitterPart.CanCollide = false
	emitterPart.CanQuery = false
	emitterPart.Parent = effectFolder

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(
		colors[1],
		colors[2]
	)
	emitter.LightEmission = 1
	emitter.Lifetime = NumberRange.new(0.9, 1.8)
	emitter.Speed = NumberRange.new(45, 105)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 3
	emitter.Rate = 0
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Parent = emitterPart

	emitter:Emit(230)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 235, 160)
	light.Brightness = 14
	light.Range = 65
	light.Parent = emitterPart

	TweenService:Create(
		light,
		TweenInfo.new(1),
		{Brightness = 0}
	):Play()
end

local function triggerGoal(goalLine)
	if os.clock() < nextGoalAllowed then
		return
	end

	nextGoalAllowed = os.clock() + GOAL_COOLDOWN

	local shooterId = ball:GetAttribute("LastShooterUserId")
	local scorer = shooterId and Players:GetPlayerByUserId(shooterId)

	local scorerName = scorer and scorer.DisplayName or "UNKNOWN PLAYER"

	totalGoals.Value += 1

	if scorer then
		local awardGoal = SSS:FindFirstChild("FootballAwardGoal")

		if awardGoal then
			awardGoal:Fire(scorer)
		end
	end

	local blastPosition = goalLine.Position

	goalControl:Fire("Freeze")

	createBlast(blastPosition)

	for _, player in ipairs(Players:GetPlayers()) do
		ragdollPlayer(player, blastPosition)
	end

	goalFX:FireAllClients({
		Scorer = scorerName,
		GoalCount = totalGoals.Value,
		GoalName = goalLine:GetAttribute("GoalName") or "GOAL"
	})

	print("GOOOOOAL! Scored by:", scorerName)

	task.delay(4.3, function()
		goalControl:Fire("Reset")

		local resetPlayers = SSS:WaitForChild("FootballResetPlayers")
		resetPlayers:Fire()
	end)
end

goalStep.Event:Connect(function(previousPosition, nextPosition)
	if os.clock() < nextGoalAllowed then return end
	if ball:GetAttribute("OwnerUserId") ~= 0 then return end

	if typeof(previousPosition) ~= "Vector3"
		or typeof(nextPosition) ~= "Vector3" then
		return
	end

	for _, line in ipairs(goalFolder:GetChildren()) do
		if line:IsA("BasePart") then
			local before = line.CFrame:PointToObjectSpace(
				previousPosition
			)

			local after = line.CFrame:PointToObjectSpace(
				nextPosition
			)

			if before.Z < 0 and after.Z >= 0 then
				local fraction =
					-before.Z / (after.Z - before.Z)

				local crossing = before:Lerp(after, fraction)

				if math.abs(crossing.X) <= line.Size.X / 2
					and math.abs(crossing.Y) <= line.Size.Y / 2 then

					triggerGoal(line)
					break
				end
			end
		end
	end
end)
