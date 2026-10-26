local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function disableAnimate(character)
	local function check(child)
		if child.Name == "Animate"
			and child:IsA("LocalScript") then
			child.Enabled = false
			child:Destroy()
		end
	end

	for _, child in ipairs(character:GetChildren()) do
		check(child)
	end

	character.ChildAdded:Connect(check)
end

player.CharacterAdded:Connect(disableAnimate)

if player.Character then
	disableAnimate(player.Character)
end
