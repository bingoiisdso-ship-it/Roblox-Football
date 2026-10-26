local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Physics = require(RS:WaitForChild("FootballPhysics"))
local ball = workspace:WaitForChild("MatchFootball")

local remote = RS:FindFirstChild("FootballAction")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "FootballAction"
	remote.Parent = RS
end

local SSS = game:GetService("ServerScriptService")
local goalStep = SSS:WaitForChild("FootballGoalStep")
local goalControl = SSS:WaitForChild("FootballGoalControl")

local marker = ball:FindFirstChild("OwnershipMarker")

if not marker then
	marker = Instance.new("BillboardGui")
	marker.Name = "OwnershipMarker"
	marker.Size = UDim2.fromOffset(130, 30)
	marker.StudsOffset = Vector3.new(0, 1.8, 0)
	marker.AlwaysOnTop = true
	marker.Parent = ball
end

local label = marker:FindFirstChild("OwnerLabel")

if not label then
	label = Instance.new("TextLabel")
	label.Name = "OwnerLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = marker
end

local CLAIM_DISTANCE = 3.5
local STEAL_DISTANCE = 2.5
local STEAL_COOLDOWN = 1.1

local flightAngle = 0

local BALL_OFFSET = CFrame.new(0, -2, -2.1)

local owner = nil
local weld = nil

local state = "Stopped"
local velocity = Vector3.zero
local spin = 0
local rolledDistance = 0

local lastClaim = 0
local blockedUntil = 0
local lastAction = {}

local castParams = RaycastParams.new()
castParams.FilterType = Enum.RaycastFilterType.Exclude
castParams.RespectCanCollide = true
castParams.IgnoreWater = true

local function getRoot(player)
	if not player then return nil end

	local char = player.Character
	if not char then return nil end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")

	if not humanoid or humanoid.Health <= 0 then
		return nil
	end

	return root
end

local function updateMarker()
	ball:SetAttribute(
		"OwnerUserId",
		owner and owner.UserId or 0
	)

	marker.Enabled = owner ~= nil
	label.Text = owner and owner.DisplayName or ""
end

local function removeWeld()
	if weld then
		weld:Destroy()
		weld = nil
	end
end

local function release()
	removeWeld()

	owner = nil
	state = "Stopped"
	velocity = Vector3.zero
	spin = 0
	rolledDistance = 0

	ball.Anchored = true
	ball.CanCollide = false
	ball.CanTouch = false
	ball.CanQuery = true
	ball.Massless = false

	updateMarker()
end

local function claim(player)
	if player:GetAttribute("FootballInLobby") ~= false then
		return
	end

	local root = getRoot(player)
	if not root then return end

	removeWeld()

	owner = player
	lastClaim = os.clock()

	state = "Owned"
	velocity = Vector3.zero
	spin = 0
	rolledDistance = 0

	ball.Anchored = false
	ball.Massless = true
	ball.CanCollide = false
	ball.CanTouch = false

	ball.AssemblyLinearVelocity = Vector3.zero
	ball.AssemblyAngularVelocity = Vector3.zero

	ball.CFrame = root.CFrame * BALL_OFFSET

	weld = Instance.new("Weld")
	weld.Name = "FootballWeld"
	weld.Part0 = root
	weld.Part1 = ball
	weld.C0 = BALL_OFFSET
	weld.C1 = CFrame.identity
	weld.Parent = ball

	castParams.FilterDescendantsInstances = {
		ball,
		player.Character
	}

	updateMarker()
end

local function shoot(player, action, look, curve, angle)
	if owner ~= player then return end

	local root = getRoot(player)
	if not root then return end

	local settings = Physics.Shots[action]
	if not settings then return end

	local now = os.clock()

	if now - (lastAction[player] or 0) < 0.35 then
		return
	end

	if typeof(look) ~= "Vector3"
		or look.Magnitude < 0.5
		or look.Magnitude > 1.5 then
		look = root.CFrame.LookVector
	end

	if typeof(curve) ~= "number"
		or curve ~= curve
		or math.abs(curve) > 100 then
		curve = 0
	end

	if typeof(angle) ~= "number"
		or angle ~= angle
		or math.abs(angle) > 360 then
		angle = settings.Angle
	end

	lastAction[player] = now

	ball:SetAttribute("LastShooterUserId", player.UserId)

	local launchVelocity, launchSpin =
		Physics.GetLaunch(action, look, curve, angle)

	-- Save the exact launch position before removing weld
	local launchPosition =
		Physics.LaunchPosition(ball.Position, look)

	removeWeld()

	owner = nil
	updateMarker()

	ball.Anchored = true
	ball.CanCollide = false
	ball.Massless = false
	ball.Position = launchPosition

	velocity = launchVelocity
	spin = launchSpin

	flightAngle = math.clamp(
		angle,
		settings.MinAngle,
		settings.MaxAngle
	)

	state = "Flying"
	rolledDistance = 0
	blockedUntil = now + 0.7

	-- Ignore the shooter during initial ball flight
	castParams.FilterDescendantsInstances = {
		ball,
		player.Character
	}
end

local function tackle(player)
	local root = getRoot(player)
	if not root then return end

	local now = os.clock()

	if now - (lastAction[player] or 0) < 1 then
		return
	end

	lastAction[player] = now

	if not owner or owner == player then return end

	local targetRoot = getRoot(owner)

	if targetRoot
		and (root.Position - targetRoot.Position).Magnitude <= 5 then
		claim(player)
	end
end

remote.OnServerEvent:Connect(function(
	player,
	command,
	action,
	look,
	curve,
	angle
)
	if command == "Tackle" then
		tackle(player)
	elseif command == "Shoot" then
		shoot(player, action, look, curve, angle)
	end
end)

local function resetBall()
	release()

	ball:SetAttribute("LastShooterUserId", 0)

	local pitch = workspace:FindFirstChild("FootballPitch")

	if pitch then
		local cf, size

		if pitch:IsA("BasePart") then
			cf, size = pitch.CFrame, pitch.Size
		else
			cf, size = pitch:GetBoundingBox()
		end

		ball.Position =
			cf.Position + Vector3.new(0, size.Y / 2 + 2, 0)
	end

	castParams.FilterDescendantsInstances = {ball}
end

resetBall()

local accumulator = 0

RunService.Heartbeat:Connect(function(dt)
	if owner and not getRoot(owner) then
		release()
	end

	accumulator = math.min(
		accumulator + dt,
		Physics.STEP * 8
	)

	while accumulator >= Physics.STEP do
		accumulator -= Physics.STEP

		if state == "Flying" then
			local nextPosition
			local nextVelocity
			local nextSpin
			local nextState

			local previousBallPosition = ball.Position

			nextPosition, nextVelocity, nextSpin, nextState =
				Physics.StepFlight(
					ball.Position,
					velocity,
					spin,
					ball.Size.X / 2,
					castParams,
					flightAngle
				)

			ball.Position = nextPosition

			velocity = nextVelocity
			spin = nextSpin
			state = nextState

			goalStep:Fire(previousBallPosition, nextPosition)

		elseif state == "Rolling" then
			local oldPosition = ball.Position

			local nextPosition
			local nextVelocity
			local newDistance
			local nextState

			nextPosition, nextVelocity, newDistance, nextState =
				Physics.StepRoll(
					oldPosition,
					velocity,
					rolledDistance,
					ball.Size.X / 2,
					castParams
				)

			local movement = Vector3.new(
				nextPosition.X - oldPosition.X,
				0,
				nextPosition.Z - oldPosition.Z
			)

			-- Visually rotate while rolling
			if movement.Magnitude > 0.001 then
				local axis = Vector3.yAxis:Cross(movement.Unit)

				ball.CFrame =
					CFrame.new(nextPosition)
					* CFrame.fromAxisAngle(
						axis,
						movement.Magnitude / (ball.Size.X / 2)
					)
					* ball.CFrame.Rotation
			else
				ball.Position = nextPosition
			end

			velocity = nextVelocity
			rolledDistance = newDistance
			state = nextState

			goalStep:Fire(oldPosition, ball.Position)
		end
	end

	if ball.Position.Y < -80 then
		resetBall()
		return
	end

	if state == "Flying" then return end
	if os.clock() < blockedUntil then return end

	local nearest = nil
	local closestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= owner then
			local root = getRoot(player)

			if root then
				local distance =
					(root.Position - ball.Position).Magnitude

				if distance < closestDistance then
					closestDistance = distance
					nearest = player
				end
			end
		end
	end

	if nearest then
		if not owner and closestDistance <= CLAIM_DISTANCE then
			claim(nearest)

		elseif owner
			and os.clock() - lastClaim >= STEAL_COOLDOWN
			and closestDistance <= STEAL_DISTANCE then

			claim(nearest)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastAction[player] = nil

	if owner == player then
		release()
	end
end)

goalControl.Event:Connect(function(command)
	if command == "Freeze" then
		release()
		blockedUntil = os.clock() + 6

	elseif command == "Reset" then
		resetBall()
		blockedUntil = os.clock() + 0.8
	end
end)
