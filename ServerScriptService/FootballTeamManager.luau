local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RS = game:GetService("ReplicatedStorage")

local system = workspace:WaitForChild("FootballLobbySystem")
local lobbySpawn = system:WaitForChild("FootballLobbySpawn")
local positions = system:WaitForChild("PositionSpawns")

local remotes = RS:WaitForChild("FootballMenuRemotes")
local getData = remotes:WaitForChild("GetLobbyData")
local joinPosition = remotes:WaitForChild("JoinPosition")
local returnLobby = remotes:WaitForChild("ReturnToLobby")

local MAX_PLAYERS = 11

local ROLES = {
	"GK", "LB", "LCB", "RCB", "RB",
	"LCM", "CM", "RCM", "LW", "ST", "RW"
}

local TEAM_NAMES = {"Red FC", "Blue FC"}

local assignments = {}
local occupied = {
	["Red FC"] = {},
	["Blue FC"] = {}
}

local function countTeam(teamName)
	local count = 0
	for _, assignment in pairs(assignments) do
		if assignment.Team == teamName then
			count += 1
		end
	end
	return count
end

local function isValidRole(role)
	return table.find(ROLES, role) ~= nil
end

local function getSnapshot()
	local data = {
		MaxPlayers = MAX_PLAYERS,
		Teams = {},
		Roles = ROLES
	}

	for _, teamName in ipairs(TEAM_NAMES) do
		local used = {}

		for role, player in pairs(occupied[teamName]) do
			if player and player.Parent == Players then
				used[role] = player.DisplayName
			end
		end

		data.Teams[teamName] = {
			Count = countTeam(teamName),
			Occupied = used
		}
	end

	return data
end

getData.OnServerInvoke = function()
	return getSnapshot()
end

local function clearAssignment(player)
	local old = assignments[player]

	if old then
		if occupied[old.Team][old.Role] == player then
			occupied[old.Team][old.Role] = nil
		end
		assignments[player] = nil
	end

	player:SetAttribute("FootballPosition", nil)
end

local function teleport(player)
	local character = player.Character
	if not character then return end

	local root = character:WaitForChild("HumanoidRootPart", 8)
	if not root then return end

	local assignment = assignments[player]
	local target

	if assignment then
		local teamFolder = positions:FindFirstChild(assignment.Team)
		target = teamFolder and teamFolder:FindFirstChild(assignment.Role)
	end

	target = target or lobbySpawn
	local teleportFX = RS:WaitForChild("FootballTeleportFX")

	if assignment then
		teleportFX:FireClient(player, "Cover", "ENTERING THE PITCH")
		task.wait(0.65)
	end
	-- Avoid fighting the spawn process
	task.wait(0.15)

	if player.Character ~= character then return end

	local destination = target.Position + Vector3.new(0, 3, 0)

	local cf

	if assignment then
		cf = target.CFrame + Vector3.new(0, 3, 0)
	else
		cf = CFrame.new(destination)
	end

	character:PivotTo(cf)

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	if assignment then
		task.wait(0.25)
		teleportFX:FireClient(player, "Reveal")
	end
end

local function sendToLobby(player)
	clearAssignment(player)

	player.Team = nil
	player.Neutral = true
	player:SetAttribute("FootballInLobby", true)

	task.spawn(teleport, player)
end

local function join(player, teamName, role)
	if typeof(teamName) ~= "string"
		or typeof(role) ~= "string" then
		return
	end

	if not occupied[teamName] or not isValidRole(role) then
		return
	end

	local team = Teams:FindFirstChild(teamName)
	local teamFolder = positions:FindFirstChild(teamName)

	if not team or not teamFolder
		or not teamFolder:FindFirstChild(role) then
		return
	end

	local old = assignments[player]

	if old and old.Team == teamName
		and old.Role == role then
		return
	end

	if countTeam(teamName) >= MAX_PLAYERS
		and (not old or old.Team ~= teamName) then
		return
	end

	local holder = occupied[teamName][role]

	if holder and holder ~= player
		and holder.Parent == Players then
		return
	end

	clearAssignment(player)

	assignments[player] = {
		Team = teamName,
		Role = role
	}

	occupied[teamName][role] = player

	player.Team = team
	player.Neutral = false
	player:SetAttribute("FootballPosition", role)
	player:SetAttribute("FootballInLobby", false)

	task.spawn(teleport, player)
end

joinPosition.OnServerEvent:Connect(join)
returnLobby.OnServerEvent:Connect(sendToLobby)

local function setupPlayer(player)
	-- Everyone begins without a team
	player.Team = nil
	player.Neutral = true
	player:SetAttribute("FootballInLobby", true)

	player.CharacterAdded:Connect(function()
		task.spawn(teleport, player)
	end)

	if player.Character then
		task.spawn(teleport, player)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	clearAssignment(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end)
