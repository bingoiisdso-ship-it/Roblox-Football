local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ball = workspace:WaitForChild("MatchFootball")
local Physics = require(RS:WaitForChild("FootballPhysics"))

local SIMULATION_STEPS = 210
local DRAW_EVERY = 3
local MAX_SEGMENTS = math.ceil(SIMULATION_STEPS / DRAW_EVERY) + 1
local UPDATE_RATE = 1 / 30

local ARROW_WIDTH = 0.32
local HEAD_LENGTH = 3.2
local HEAD_WIDTH = 1.5

local COLOR_START = Color3.fromRGB(40, 255, 175)
local COLOR_END = Color3.fromRGB(105, 255, 240)
local TARGET_COLOR = Color3.fromRGB(255, 225, 70)

local old = workspace:FindFirstChild("LocalTrajectoryPreview")
if old then
	old:Destroy()
end

local folder = Instance.new("Folder")
folder.Name = "LocalTrajectoryPreview"
folder.Parent = workspace

local anchor = Instance.new("Part")
anchor.Name = "TrajectoryAnchor"
anchor.Size = Vector3.one
anchor.Anchored = true
anchor.Transparency = 1
anchor.CanCollide = false
anchor.CanTouch = false
anchor.CanQuery = false
anchor.Parent = folder

local function attachment(name)
	local a = Instance.new("Attachment")
	a.Name = name
	a.Parent = anchor
	return a
end

local function makeBeam(name, a0, a1, width, color)
	local beam = Instance.new("Beam")
	beam.Name = name
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.FaceCamera = true
	beam.Width0 = width
	beam.Width1 = width
	beam.Color = ColorSequence.new(color)
	beam.Transparency = NumberSequence.new(0.08)
	beam.LightEmission = 1
	beam.Brightness = 3
	beam.Segments = 1
	beam.Enabled = false
	beam.Parent = folder
	return beam
end

local nodes = {}
local beams = {}

for i = 1, MAX_SEGMENTS + 1 do
	nodes[i] = attachment("PathNode_" .. i)
end

for i = 1, MAX_SEGMENTS do
	local progress = i / MAX_SEGMENTS

	local color = COLOR_START:Lerp(COLOR_END, progress)

	beams[i] = makeBeam(
		"ArrowBody_" .. i,
		nodes[i],
		nodes[i + 1],
		ARROW_WIDTH,
		color
	)
end

local leftNode = attachment("ArrowLeft")
local rightNode = attachment("ArrowRight")
local tipNode = attachment("ArrowTip")

local leftWing = makeBeam(
	"ArrowHeadLeft",
	leftNode,
	tipNode,
	0.48,
	COLOR_END
)

local rightWing = makeBeam(
	"ArrowHeadRight",
	rightNode,
	tipNode,
	0.48,
	COLOR_END
)

leftWing.Width0 = 0.16
leftWing.Width1 = 0.5

rightWing.Width0 = 0.16
rightWing.Width1 = 0.5

local landing = Instance.new("Part")
landing.Name = "LandingTarget"
landing.Shape = Enum.PartType.Cylinder
landing.Size = Vector3.new(3.5, 0.09, 3.5)
landing.Material = Enum.Material.Neon
landing.Color = TARGET_COLOR
landing.Anchored = true
landing.CanCollide = false
landing.CanTouch = false
landing.CanQuery = false
landing.Transparency = 1
landing.Parent = folder

local landingGui = Instance.new("BillboardGui")
landingGui.Size = UDim2.fromOffset(160, 34)
landingGui.StudsOffset = Vector3.new(0, 2, 0)
landingGui.AlwaysOnTop = true
landingGui.Enabled = false
landingGui.Parent = landing

local landingText = Instance.new("TextLabel")
landingText.Size = UDim2.fromScale(1, 1)
landingText.BackgroundColor3 = Color3.fromRGB(15, 28, 30)
landingText.BackgroundTransparency = 0.15
landingText.TextColor3 = Color3.new(1, 1, 1)
landingText.Font = Enum.Font.GothamBold
landingText.TextScaled = true
landingText.Text = "TARGET"
landingText.Parent = landingGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 9)
corner.Parent = landingText

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.RespectCanCollide = true
params.IgnoreWater = true

local function hide()
	for _, beam in ipairs(beams) do
		beam.Enabled = false
	end

	leftWing.Enabled = false
	rightWing.Enabled = false

	landing.Transparency = 1
	landingGui.Enabled = false
end

local function setNode(node, worldPosition)
	node.Position = anchor.CFrame:PointToObjectSpace(
		worldPosition
	)
end

local function showArrow(path, camera)
	local count = math.min(#path - 1, MAX_SEGMENTS)

	for i, beam in ipairs(beams) do
		beam.Enabled = i <= count

		if i <= count then
			setNode(nodes[i], path[i])
			setNode(nodes[i + 1], path[i + 1])
		end
	end

	if count < 1 then
		leftWing.Enabled = false
		rightWing.Enabled = false
		return
	end

	local tip = path[count + 1]
	local previous = path[count]

	local tangent = tip - previous

	if tangent.Magnitude < 0.001 then
		return
	end

	tangent = tangent.Unit

	local right = camera.CFrame.RightVector

	local base = tip - tangent * HEAD_LENGTH

	local leftPoint = base - right * HEAD_WIDTH
	local rightPoint = base + right * HEAD_WIDTH

	setNode(leftNode, leftPoint)
	setNode(rightNode, rightPoint)
	setNode(tipNode, tip)

	leftWing.Enabled = true
	rightWing.Enabled = true
end

local function targetOrientation(position, normal)
	local reference =
		math.abs(normal:Dot(Vector3.yAxis)) > 0.9
		and Vector3.xAxis
		or Vector3.yAxis

	local right = reference:Cross(normal).Unit
	local back = right:Cross(normal).Unit

	return CFrame.fromMatrix(
		position + normal * 0.1,
		right,
		normal,
		back
	)
end

local lastUpdate = 0

RunService.RenderStepped:Connect(function()
	local now = os.clock()

	if now - lastUpdate < UPDATE_RATE then
		return
	end

	lastUpdate = now

	local character = player.Character
	local camera = workspace.CurrentCamera

	if not character or not camera then
		hide()
		return
	end

	local action = character:GetAttribute("AimingAction")
	local curve = character:GetAttribute("AimingCurve") or 0
	local angle = character:GetAttribute("AimingAngle") or 0

	if not Physics.Shots[action]
		or ball:GetAttribute("OwnerUserId") ~= player.UserId then

		hide()
		return
	end

	local look = camera.CFrame.LookVector

	local position = Physics.LaunchPosition(
		ball.Position,
		look
	)

	local startPosition = position

	local velocity, spin = Physics.GetLaunch(
		action,
		look,
		curve,
		angle
	)

	params.FilterDescendantsInstances = {
		character,
		ball,
		folder
	}

	anchor.CFrame = CFrame.new(startPosition)

	local path = {position}

	local impact = nil
	local impactNormal = Vector3.yAxis

	for step = 1, SIMULATION_STEPS do
		local nextPosition
		local nextVelocity
		local nextSpin
		local nextState
		local hit

		nextPosition, nextVelocity, nextSpin, nextState, hit =
			Physics.StepFlight(
				position,
				velocity,
				spin,
				ball.Size.X / 2,
				params,
				angle
			)

		if step % DRAW_EVERY == 0 then
			table.insert(path, nextPosition)
		end

		position = nextPosition
		velocity = nextVelocity
		spin = nextSpin

		if nextState == "Rolling"
			or nextState == "Stopped" then

			if hit then
				impact = hit.Position
				impactNormal = hit.Normal
			else
				impact = nextPosition
			end

			table.insert(path, nextPosition)

			break
		end
	end

	if not impact then
		table.insert(path, position)
	end

	showArrow(path, camera)

	if impact then
		local distance = Vector3.new(
			impact.X - startPosition.X,
			0,
			impact.Z - startPosition.Z
		).Magnitude

		landing.CFrame = targetOrientation(
			impact,
			impactNormal
		)

		local pulse = math.sin(now * 5) * 0.12

		landing.Size = Vector3.new(
			3.5 + pulse,
			0.09,
			3.5 + pulse
		)

		landing.Transparency = 0.15
		landingGui.Enabled = true

		landingText.Text = string.format(
			"TARGET • %.0f STUDS",
			distance
		)
	else
		landing.Transparency = 1
		landingGui.Enabled = false
	end
end)
