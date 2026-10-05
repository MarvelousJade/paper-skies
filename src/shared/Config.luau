--!strict
local Config = {}
Config.Launch = Vector3.new(-548.6, 362, 530)
Config.ThrowStand = Vector3.new(-550, 360, 534)
Config.MouseSensitivity = 0.0025
Config.MaxAimYaw = math.rad(80)
Config.ThrowDelay = 0.4
Config.MaxPitch = math.rad(48)
Config.MinPitch = math.rad(-65)
Config.TurnRate = math.rad(52)
Config.PitchRate = math.rad(42)
Config.Gravity = 36
Config.StallSpeed = 54
Config.RecoverySpeed = 76
Config.TrimPitch = math.rad(-6)
Config.MaxDuration = 240
Config.WorldMin = Vector3.new(-4700,-20,-7800)
Config.WorldMax = Vector3.new(4700,1800,2000)
Config.RingValue = 10
Config.CollectionRadius = 80
Config.BoostDuration = 4.5
Config.BoostAcceleration = 65
Config.MaxSpeed = 250
Config.WindSoundId = "rbxassetid://687874741"
Config.Upgrades = {
 Glide = {title="Better folds", description="Less drag and a slower descent", baseCost=50, maxLevel=5},
 Launch = {title="Stronger throw", description="More starting speed and height potential", baseCost=60, maxLevel=5},
 Handling = {title="Balanced wings", description="Faster response when turning", baseCost=40, maxLevel=5},
}
-- Kept only so the archived art builder can still rebuild the earlier scene.
Config.Speed=96
Config.RingRadius=19
Config.Course={Vector3.new(0,110,-45),Vector3.new(28,103,-205),Vector3.new(-32,96,-370),Vector3.new(-75,89,-535),Vector3.new(5,82,-700),Vector3.new(0,75,-870)}
return table.freeze(Config)
