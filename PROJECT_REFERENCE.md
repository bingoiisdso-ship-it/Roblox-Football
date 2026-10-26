# Roblox Football — Script Backup

These are snapshots of the scripts supplied in ChatGPT on 2026-10-26, organized by their Roblox Studio Explorer locations. GitHub is a reference backup; edits here do not automatically synchronize into Roblox Studio.

## ReplicatedStorage
- `FootballAnimations.luau`
- `FootballPhysics.luau`

## ServerScriptService
- `FootballGoalExplosion.luau`
- `FootballKickoffReset.luau`
- `FootballLeaderstats.luau`
- `FootballPossession.luau`
- `FootballTeamManager.luau`

## StarterPlayer / StarterCharacterScripts
- `FootballController.client.luau`
- `FootballStamina.client.luau`

## StarterPlayer / StarterPlayerScripts
- `CustomShiftLock.client.luau`
- `FootballCameraEffects.client.luau`
- `FootballGoalUI.client.luau`
- `FootballTeleportTransition.client.luau`
- `FootballTrajectory.client.luau`
- `GKAnimationTesterClient.client.luau`
- `DisableDefaultAnimate.client.luau`

## Not yet backed up
Scripts visible in Explorer but not supplied as source: `FootballMainMenu`. Any other unshared scripts, assets, map geometry, models, GUI instances, or Studio configuration are not backed up.

## Important snapshot discrepancy
The provided `FootballAnimations.luau` table does **not** include the goalkeeper keys used by `GKAnimationTesterClient`. IDs mentioned in chat (not automatically applied to that module):
- GKIdle: 116440487584848
- GKDiveLeft: 127597550224069
- GKDiveRight: 86914752333075
- GKRushSmother: 125748550712210

The supplied Tackle ID in the animation module is 114761654584881.

## Runtime structure
- `workspace.MatchFootball`
- `workspace.FootballPitch`
- `workspace.FootballGoalLines`
- `workspace.FootballLobbySystem.FootballLobbySpawn`
- `workspace.FootballLobbySystem.PositionSpawns["Red FC"|"Blue FC"][role]`
- `ReplicatedStorage.FootballMenuRemotes` with `GetLobbyData`, `JoinPosition`, `ReturnToLobby`
- `ReplicatedStorage.FootballTeleportFX` and `FootballGoalFX`
- `ServerScriptService.FootballGoalStep`, `FootballGoalControl`, `FootballResetPlayers` are created/used as BindableEvents.

The scripts are backups of user-provided source, not independently tested or modified fixes.
