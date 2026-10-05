--!strict
local Config = {}
Config.Launch = Vector3.new(-548.6, 362, 530)
Config.ThrowStand = Vector3.new(-550, 360, 534)
Config.MouseSensitivity = 0.0025
Config.MaxAimYaw = math.pi
Config.ThrowDelay = 0.4
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
Config.StallSpeed = 54
Config.RecoverySpeed = 76
Config.TrimPitch = math.rad(-6)
Config.MaxDuration = 240
Config.WorldMin = Vector3.new(-5900,-20,-5600)
Config.WorldMax = Vector3.new(4900,2800,5900)
Config.RingValue = 10
-- Passive flight income stays secondary to collecting exploration rewards.
Config.DistanceGoldStuds = 200
Config.CollectionRadius = 12
Config.RingMargin = 3.6
Config.CollectSoundId = "rbxassetid://111940732857414"
Config.CollectSoundVolume = 0.35
Config.CollectSoundDuration = 0.45
-- Original Paper Skies loop, uploaded by the project owner from assets/audio/PaperSkies.wav.
-- Empty disables music without requesting a placeholder or inaccessible asset.
Config.MusicSoundId = "rbxassetid://126932983544303"
Config.MusicVolume = 0.16
Config.BoostDuration = 4.5
Config.BoostAcceleration = 65
Config.BoostRechargeDelay = 0.85
Config.BoostRechargePitch = math.rad(5)
Config.AltitudeSoftBand = 220
Config.MaxSpeed = 250
Config.WindSoundId = "rbxassetid://687874741"
-- Costs and performance are game balance values, not claims about real folded designs.
Config.PlaneOrder={"Dart","Lockwing","Delta","Sailwing","Kestrel"}
Config.Planes={
 Dart={name="Paper Dart",price=0,launchSpeed=165,drag=0.000165,sink=2.2,handling=1,airCeiling=650,thermalEfficiency=0.7,climbComfort=math.rad(12),climbLoss=110,boostRecharge=0.6,rank=1},
 Lockwing={name="Lockwing",price=180,launchSpeed=172,drag=0.00015,sink=1.95,handling=1.06,airCeiling=950,thermalEfficiency=0.8,climbComfort=math.rad(16),climbLoss=95,boostRecharge=0.65,rank=2},
 Delta={name="Delta",price=550,launchSpeed=180,drag=0.000135,sink=1.7,handling=1.13,airCeiling=1300,thermalEfficiency=0.9,climbComfort=math.rad(20),climbLoss=80,boostRecharge=0.7,rank=3},
 Sailwing={name="Sailwing",price=1400,launchSpeed=188,drag=0.00012,sink=1.45,handling=1.2,airCeiling=1750,thermalEfficiency=1.02,climbComfort=math.rad(24),climbLoss=65,boostRecharge=0.78,rank=4},
 Kestrel={name="Kestrel",price=3200,launchSpeed=198,drag=0.000105,sink=1.2,handling=1.28,airCeiling=2250,thermalEfficiency=1.15,climbComfort=math.rad(28),climbLoss=50,boostRecharge=0.85,rank=5},
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
