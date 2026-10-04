--!strict
local Config = {}
Config.Launch = Vector3.new(0, 116, 110)
Config.Speed = 68
Config.TurnRate = math.rad(48)
Config.PitchRate = math.rad(35)
Config.MaxPitch = math.rad(28)
Config.RingRadius = 19
Config.MaxDuration = 100
Config.Course = {
 Vector3.new(0,110,-45),
 Vector3.new(28,103,-205),
 Vector3.new(-32,96,-370),
 Vector3.new(-75,89,-535),
 Vector3.new(5,82,-700),
 Vector3.new(0,75,-870),
}
return table.freeze(Config)

