local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local animationIDs = require(RS:WaitForChild("FootballAnimations"))

local keys = {
	[Enum.KeyCode.Z] = "GKIdle",
	[Enum.KeyCode.X] = "GKDiveLeft",
	[Enum.KeyCode.C] = "GKDiveRight",
	[Enum.KeyCode.V] = "GKRushSmother"
}

local tracks = {}
local currentTrack
local actionToken = 0

local function play(name)
	local track = tracks[name]
	if not track then return end

	actionToken += 1
	local token = actionToken

	if currentTrack then
		currentTrack:Stop(0.05)
	end

	currentTrack = track
	track:Play(0.05, 1, 1)
	track.TimePosition = 0

	if name ~= "GKIdle" then
		track.Stopped:Once(function()
			if token == actionToken then
				play("GKIdle")
			end
		end)
	end
end

local function setup(character)
	actionToken += 1
	table.clear(tracks)
	currentTrack = nil

	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	for _, name in pairs(keys) do
		local id = animationIDs[name]

		if id then
			local animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://" .. tostring(id)

			local track = animator:LoadAnimation(animation)
			track.Priority = Enum.AnimationPriority.Action4
			track.Looped = name == "GKIdle"

			tracks[name] = track
		end
	end
end

if player.Character then
	setup(player.Character)
end

player.CharacterAdded:Connect(setup)

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end

	local name = keys[input.KeyCode]
	if name then
		play(name)
	end
end)
