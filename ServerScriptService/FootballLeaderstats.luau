local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local SSS = game:GetService("ServerScriptService")

local store = DataStoreService:GetDataStore("FootballStats_v1")

local function ensureEvent(name)
	local event = SSS:FindFirstChild(name)
	if not event then
		event = Instance.new("BindableEvent")
		event.Name = name
		event.Parent = SSS
	end
	return event
end

local goalAward = ensureEvent("FootballAwardGoal")
local winAward = ensureEvent("FootballAwardWin")

local function save(player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end

	local data = {
		Goals = stats.Goals.Value,
		Wins = stats.Wins.Value
	}

	local success, err = pcall(function()
		store:SetAsync("Player_" .. player.UserId, data)
	end)

	if not success then
		warn("Could not save football stats:", err)
	end
end

local function setup(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player

	local goals = Instance.new("IntValue")
	goals.Name = "Goals"
	goals.Parent = stats

	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = stats

	local success, data = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)

	if success and type(data) == "table" then
		goals.Value = tonumber(data.Goals) or 0
		wins.Value = tonumber(data.Wins) or 0
	elseif not success then
		warn("Could not load football stats for", player.Name)
	end
end

Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(save)

for _, player in ipairs(Players:GetPlayers()) do
	if not player:FindFirstChild("leaderstats") then
		setup(player)
	end
end

goalAward.Event:Connect(function(player)
	if typeof(player) ~= "Instance"
		or not player:IsA("Player")
		or player.Parent ~= Players then
		return
	end

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Goals.Value += 1
	end
end)

winAward.Event:Connect(function(player)
	if typeof(player) ~= "Instance"
		or not player:IsA("Player")
		or player.Parent ~= Players then
		return
	end

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Wins.Value += 1
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		save(player)
	end
end)
