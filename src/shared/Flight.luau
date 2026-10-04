--!strict
local Config = require(script.Parent.Config)
export type State = {position: Vector3, yaw: number, pitch: number}
local Flight = {}
function Flight.step(state: State, steer: Vector2, dt: number): State
 local yaw = state.yaw - steer.X * Config.TurnRate * dt
 local pitch = math.clamp(state.pitch + steer.Y * Config.PitchRate * dt, -Config.MaxPitch, Config.MaxPitch)
 -- Pitch relaxes toward a gentle glide when the pilot releases vertical input.
 if math.abs(steer.Y) < 0.01 then
  pitch += (-0.035 - pitch) * (1 - math.exp(-2 * dt))
 end
 local frame = CFrame.Angles(0,yaw,0) * CFrame.Angles(pitch,0,0)
 local speed = Config.Speed * (1 - 0.22 * math.sin(pitch))
 return {position = state.position + frame.LookVector * speed * dt, yaw = yaw, pitch = pitch}
end
function Flight.frame(state: State, bank: number): CFrame
 return CFrame.new(state.position) * CFrame.Angles(0,state.yaw,0) * CFrame.Angles(state.pitch,0,bank)
end
-- Swept crossing catches a ring even when the plane moves across it between frames.
function Flight.crossed(a: Vector3, b: Vector3, center: Vector3): boolean
 if a.Z < center.Z or b.Z > center.Z or a.Z == b.Z then return false end
 local t = (center.Z-a.Z)/(b.Z-a.Z)
 local p = a:Lerp(b,t)
 return Vector2.new(p.X-center.X,p.Y-center.Y).Magnitude <= Config.RingRadius
end
return Flight

