-- ReplicatedStorage > FootballPhysics
-- ModuleScript

local Physics = {}

Physics.STEP = 1 / 60

Physics.Shots = {
	Pass = {
		Speed = 78,
		Angle = 0,
		MinAngle = 0,
		MaxAngle = 18
	},

	Kick = {
		Speed = 170,
		Angle = 0,
		MinAngle = 0,
		MaxAngle = 30
	},

	PowerShot = {
		Speed = 220,
		Angle = 0,
		MinAngle = 0,
		MaxAngle = 34
	}
}

Physics.CURVE_FORCE = 105
Physics.AIR_DRAG = 0.06

Physics.ROLL_FRICTION = 13
Physics.MAX_ROLL_DISTANCE = 110
Physics.STOP_SPEED = 0.7

Physics.LOW_SHOT_GRAVITY = 0.018

function Physics.GetGravityScale(angle)
	local charge = math.clamp(
		(angle or 0) / 16,
		0,
		1
	)

	return Physics.LOW_SHOT_GRAVITY
		+ (1 - Physics.LOW_SHOT_GRAVITY)
		* (charge ^ 1.4)
end

function Physics.GetFlatDirection(look)
	local flat = Vector3.new(look.X, 0, look.Z)

	if flat.Magnitude < 0.001 then
		return Vector3.new(0, 0, -1)
	end

	return flat.Unit
end

function Physics.GetLaunch(action, look, spin, angle)
	local settings = Physics.Shots[action]
	if not settings then return nil end

	local flat = Physics.GetFlatDirection(look)

	local degrees = math.clamp(
		angle or settings.Angle,
		settings.MinAngle,
		settings.MaxAngle
	)

	local radians = math.rad(degrees)

	local direction =
		flat * math.cos(radians)
		+ Vector3.yAxis * math.sin(radians)

	return direction * settings.Speed,
		math.clamp(spin or 0, -1, 1)
end

function Physics.LaunchPosition(ballPosition, look)
	local flat = Physics.GetFlatDirection(look)

	return ballPosition
		+ flat * 0.85
		+ Vector3.new(0, 0.35, 0)
end

function Physics.StepFlight(position, velocity, spin, radius, params, shotAngle)
	local dt = Physics.STEP

	local horizontal = Vector3.new(
		velocity.X, 0, velocity.Z
	)

	local sideways = Vector3.zero

	if horizontal.Magnitude > 0.01 then
		sideways = Vector3.new(
			-horizontal.Z, 0, horizontal.X
		).Unit
	end

	local speedFactor = math.clamp(
		horizontal.Magnitude / 135,
		0.35,
		1.6
	)

	local gravityScale = Physics.GetGravityScale(shotAngle)

	local acceleration =
		Vector3.new(
			0,
			-workspace.Gravity * gravityScale,
			0
		)
		+ sideways
		* spin
		* Physics.CURVE_FORCE
		* speedFactor
	- velocity * Physics.AIR_DRAG

	local nextVelocity = velocity + acceleration * dt
	local displacement = nextVelocity * dt

	local hit

	if displacement.Magnitude > 0.0001 then
		hit = workspace:Spherecast(
			position,
			radius * 0.98,
			displacement,
			params
		)

		if not hit then
			hit = workspace:Raycast(
				position,
				displacement,
				params
			)
		end
	end

	if not hit then
		return position + displacement,
			nextVelocity,
			spin,
			"Flying",
			nil
	end

	local contactPosition =
		hit.Position + hit.Normal * (radius + 0.035)

	-- A solid net barrier catches the ball
	if hit.Instance:GetAttribute("FootballNet") == true then
		return contactPosition,
			Vector3.zero,
			0,
			"Stopped",
			hit
	end

	-- Ground contact starts rolling
	if hit.Normal.Y > 0.65 then
		local horizontal = Vector3.new(
			nextVelocity.X,
			0,
			nextVelocity.Z
		)

		local rollingVelocity = Vector3.zero

		if horizontal.Magnitude > 0.1 then
			local rollSpeed = math.clamp(
				horizontal.Magnitude * 0.82,
				14,
				58
			)

			rollingVelocity = horizontal.Unit * rollSpeed
		end

		return contactPosition,
			rollingVelocity,
			0,
			"Rolling",
			hit
	end

	-- Goalpost or another wall: bounce
	local dot = math.min(nextVelocity:Dot(hit.Normal), 0)

	local reflected =
		(nextVelocity - 2 * dot * hit.Normal) * 0.32

	if reflected.Magnitude < 8 then
		return contactPosition,
			Vector3.zero,
			0,
			"Stopped",
			hit
	end

	return contactPosition,
		reflected,
		spin * 0.25,
		"Flying",
		hit
end

function Physics.StepRoll(position, velocity, distance, radius, params)
	local dt = Physics.STEP

	local horizontal = Vector3.new(
		velocity.X, 0, velocity.Z
	)

	local speed = horizontal.Magnitude
	local remaining = Physics.MAX_ROLL_DISTANCE - distance

	if speed < Physics.STOP_SPEED or remaining <= 0 then
		return position, Vector3.zero, distance, "Stopped"
	end

	local direction = horizontal.Unit

	local newSpeed = math.max(
		0,
		speed - Physics.ROLL_FRICTION * dt
	)

	-- Slow down smoothly near maximum rolling distance
	local allowedSpeed = math.sqrt(
		2 * Physics.ROLL_FRICTION * remaining
	)

	newSpeed = math.min(newSpeed, allowedSpeed)

	local moveDistance = math.min(
		newSpeed * dt,
		remaining
	)

	local displacement = direction * moveDistance

	-- Stop against goal-net walls
	local wallHit = workspace:Spherecast(
		position,
		radius * 0.9,
		displacement,
		params
	)

	if wallHit and wallHit.Normal.Y < 0.55 then
		return wallHit.Position
			+ wallHit.Normal * (radius + 0.035),
			Vector3.zero,
			distance,
			"Stopped"
	end

	local nextPosition = position + displacement

	-- Follow the ground surface
	local ground = workspace:Raycast(
		nextPosition + Vector3.new(0, 2, 0),
		Vector3.new(0, -7, 0),
		params
	)

	if not ground or ground.Normal.Y < 0.55 then
		return position, Vector3.zero, distance, "Stopped"
	end

	nextPosition = Vector3.new(
		nextPosition.X,
		ground.Position.Y + radius + 0.035,
		nextPosition.Z
	)

	local totalDistance = distance + moveDistance

	if newSpeed < Physics.STOP_SPEED
		or totalDistance >= Physics.MAX_ROLL_DISTANCE then
		return nextPosition,
			Vector3.zero,
			totalDistance,
			"Stopped"
	end

	return nextPosition,
		direction * newSpeed,
		totalDistance,
		"Rolling"
end

return Physics
