--!strict
local Config = {}
Config.Launch = Vector3.new(-548.6, 362, 530)
Config.ThrowStand = Vector3.new(-550, 360, 534)
Config.MouseSensitivity = 0.0025
Config.MaxAimYaw = math.pi
Config.ThrowDelay = 0.4
-- A fresh hand throw blends into normal climb penalties over its first second.
Config.ThrowClimbEaseDuration = 1.2
Config.ThrowClimbInitialScale = 0.1
Config.AimPitch = math.rad(10)
Config.AimCurveWidth = 0.9
Config.AimCurveEnd = Vector3.new(0,-65,-220)
Config.AimCurveStartHandle = 70
Config.AimCurveEndTangent = Vector3.new(0,-50,-70)
Config.RingTubeThickness = 0.65
Config.ThermalFadeHeight = 220
Config.MaxPitch = math.rad(48)
Config.MinPitch = math.rad(-65)
Config.TurnRate = math.rad(52)
Config.PitchRate = math.rad(42)
Config.Gravity = 36
Config.StallSpeed = 50
Config.RecoverySpeed = 68
Config.ClimbStallRise = 24
Config.StallPitch = math.rad(-32)
Config.StallNoseRate = 1.8
Config.StallSinkMultiplier = 4
Config.TrimPitch = math.rad(-6)
Config.MaxDuration = 240
Config.WorldMin = Vector3.new(-5900,-20,-5600)
Config.WorldMax = Vector3.new(4900,2800,5900)
Config.RingValue = 10
-- Passive flight income stays secondary to collecting exploration rewards.
Config.DistanceGoldStuds = 200
Config.CollectionRadius = 12
Config.RingMargin = 3.6
-- Quiet coin pickup with a softened attack and release, separate from the music mix.
Config.CollectSoundId = "rbxassetid://4612374807"
Config.CollectSoundVolume = 0.18
Config.CollectSoundHighGain = -12
Config.CollectSoundMidGain = -2
Config.CollectSoundDuration = 0.5
Config.CollectSoundAttack = 0.025
Config.CollectSoundRelease = 0.18
Config.CollectSoundPlaybackSpeed = 0.92
-- Original Paper Skies loop, uploaded by the project owner from assets/audio/PaperSkies.wav.
-- Empty disables music without requesting a placeholder or inaccessible asset.
Config.MusicSoundId = "rbxassetid://126932983544303"
Config.MusicVolume = 0.16
Config.BoostDuration = 4.5
-- Gentler forward acceleration keeps boost controllable around scenery.
Config.BoostAcceleration = 45
-- A short release pause makes stamina recovery readable without requiring a glide.
Config.BoostRechargeDelay = 0.35
Config.AltitudeSoftBand = 220
Config.WindSoundId = "rbxassetid://687874741"
-- Costs and performance are game balance values, not claims about real folded designs.
Config.PlaneOrder={"Dart","Lockwing","Delta","Sailwing","Kestrel"}
-- Preserve original starter handling; purchased folds turn progressively faster.
Config.Planes={
 Dart={name="Paper Dart",price=0,launchSpeed=90,maxSpeed=160,drag=0.000376,sink=2.2,handling=1,airCeiling=650,thermalEfficiency=0.7,climbComfort=math.rad(12),climbLoss=70,boostRecharge=0.9,boostAcceleration=45,rank=1},
 Lockwing={name="Lockwing",price=180,launchSpeed=105,maxSpeed=190,drag=0.000342,sink=1.95,handling=1.12,airCeiling=950,thermalEfficiency=0.8,climbComfort=math.rad(16),climbLoss=60,boostRecharge=0.98,boostAcceleration=50,rank=2},
 Delta={name="Delta",price=550,launchSpeed=120,maxSpeed=220,drag=0.000308,sink=1.7,handling=1.25,airCeiling=1300,thermalEfficiency=0.9,climbComfort=math.rad(20),climbLoss=50,boostRecharge=1.05,boostAcceleration=55,rank=3},
 Sailwing={name="Sailwing",price=1400,launchSpeed=135,maxSpeed=250,drag=0.000274,sink=1.45,handling=1.4,airCeiling=1750,thermalEfficiency=1.02,climbComfort=math.rad(24),climbLoss=40,boostRecharge=1.12,boostAcceleration=60,rank=4},
 Kestrel={name="Kestrel",price=3200,launchSpeed=150,maxSpeed=280,drag=0.000239,sink=1.2,handling=1.55,airCeiling=2250,thermalEfficiency=1.15,climbComfort=math.rad(28),climbLoss=30,boostRecharge=1.2,boostAcceleration=65,rank=5},
}
-- Retained for existing profile bonuses; new purchases use named plane types.
Config.Upgrades = {
 Glide = {title="Better folds", description="Less drag and access to higher rising air", baseCost=50, maxLevel=5},
 Launch = {title="Stronger throw", description="More starting speed and height potential", baseCost=60, maxLevel=5},
 Handling = {title="Balanced wings", description="Faster response when turning", baseCost=40, maxLevel=5},
}
-- Kept only so the archived art builder can still rebuild the earlier scene.
Config.Speed=96
Config.RingRadius=19
Config.Course={Vector3.new(0,110,-45),Vector3.new(28,103,-205),Vector3.new(-32,96,-370),Vector3.new(-75,89,-535),Vector3.new(5,82,-700),Vector3.new(0,75,-870)}
return table.freeze(Config)
