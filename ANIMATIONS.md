# Football animation library

Edit [FootballAnimations.lua](./FootballAnimations.lua) and replace each `rbxassetid://0` with the animation ID published from Roblox Studio's Animation Editor.

**Priorities:** Idle = Idle; Walk, Run, Sprint = Movement; Pass, Kick, PowerShot, Tackle, Celebrate = Action.

## Use in Roblox Studio

1. Create a **ModuleScript** in `ReplicatedStorage` named `FootballAnimations`.
2. Copy the contents of `FootballAnimations.lua` into that ModuleScript.
3. Load an animation using your custom character's `Animator`:

```lua
local ids = require(game.ReplicatedStorage.FootballAnimations)
local animator = character.Humanoid.Animator

local animation = Instance.new("Animation")
animation.AnimationId = ids.Idle

local track = animator:LoadAnimation(animation)
track.Looped = true
track:Play()
```

Your custom character must be rigged with Motor6Ds, have an Animator, and use the same joint names as the model used to create the animation. Roblox animation assets remain on Roblox; this repository stores their IDs and related code.
