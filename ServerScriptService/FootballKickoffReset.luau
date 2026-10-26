local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local event = RS:WaitForChild("FootballTeleportFX")
local system = workspace:WaitForChild("FootballLobbySystem")
local positions = system:WaitForChild("PositionSpawns")

local resetEvent = SSS:FindFirstChild("FootballResetPlayers")
if not resetEvent then
	resetEvent = Instance.new("BindableEvent")
	resetEvent.Name = "FootballResetPlayers"
	resetEvent.Parent = SSS
end

local busy = false

local function getMarker(player)
	local team = player.Team
	local role = player:GetAttribute("FootballPosition")

	if not team or type(role) ~= "string" then
		return nil
	end

	local folder = positions:FindFirstChild(team.Name)
	return folder and folder:FindFirstChild(role)
end

local function teleportPlayer(player)
	local marker = getMarker(player)
	if not marker then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then return end

	-- Restore movement after ragdoll
	humanoid.PlatformStand = false
	humanoid.Sit = false
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

	-- Stop ragdoll velocity
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	character:PivotTo(marker.CFrame + Vector3.new(0, 3, 0))

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

resetEvent.Event:Connect(function()
	if busy then return end
	busy = true

	local activePlayers = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("FootballInLobby") == false
			and getMarker(player) then
			table.insert(activePlayers, player)
		end
	end

	-- Cover screens
	for _, player in ipairs(activePlayers) do
		event:FireClient(player, "Cover", "BACK TO KICKOFF")
	end

	task.wait(0.65)

	-- Teleport once the screen is covered
	for _, player in ipairs(activePlayers) do
		teleportPlayer(player)
	end

	task.wait(0.4)

	-- Reveal screens
	for _, player in ipairs(activePlayers) do
		event:FireClient(player, "Reveal")
	end

	busy = false
end)
