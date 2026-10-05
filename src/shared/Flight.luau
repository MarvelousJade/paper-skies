--!strict
local Config = require(script.Parent.Config)
export type Stats = {launchSpeed:number, drag:number, sink:number, turnRate:number}
export type State = {position:Vector3, yaw:number, pitch:number, speed:number, stalled:boolean, bank:number, boostRemaining:number?, boosting:boolean?}
local Flight = {}
function Flight.stats(levels: {[string]:number}?): Stats
 local l=levels or {}
 return {launchSpeed=165+(l.Launch or 0)*6, drag=0.000165*(1-0.085*(l.Glide or 0)),
  sink=2.2*(1-0.07*(l.Glide or 0)), turnRate=Config.TurnRate*(1+0.08*(l.Handling or 0))}
end
function Flight.new(position:Vector3, yaw:number, pitch:number, stats:Stats): State
 return {position=position,yaw=yaw,pitch=pitch,speed=stats.launchSpeed,stalled=false,bank=0,boostRemaining=Config.BoostDuration,boosting=false}
end
function Flight.step(state:State, steer:Vector2, dt:number, stats:Stats?, updraft:number?, boostHeld:boolean?): State
 local settings=stats or Flight.stats()
 local speed=state.speed
 local stalled=state.stalled
 -- Hysteresis prevents rapid flickering between a stall and normal flight.
 if speed<Config.StallSpeed then stalled=true end
 if stalled and speed>Config.RecoverySpeed and state.pitch<0 then stalled=false end
 local pitch=state.pitch
 if stalled then
  -- A stalled paper plane loses lift and drops its nose, even if the pilot pulls up.
  pitch += (math.rad(-52)-pitch)*(1-math.exp(-2.8*dt))
 else
  pitch=math.clamp(pitch+steer.Y*Config.PitchRate*dt,Config.MinPitch,Config.MaxPitch)
  if math.abs(steer.Y)<0.01 then pitch+=(Config.TrimPitch-pitch)*(1-math.exp(-0.65*dt)) end
 end
 local authority=math.clamp(speed/65,0.25,1)
 local yaw=state.yaw-steer.X*settings.turnRate*authority*dt
 local bank=state.bank+(-steer.X*0.62-state.bank)*(1-math.exp(-5*dt))
 -- Unboosted flight trades height for speed. The optional boost has a finite, server-owned budget.
 local drag=settings.drag*speed*speed + math.abs(steer.X)*1.9
 local remaining=state.boostRemaining or 0
 local used=boostHeld and math.min(math.max(dt,0),remaining) or 0
 local acceleration=-Config.Gravity*math.sin(pitch)-drag
 local boostImpulse=Config.BoostAcceleration*used
 speed=math.clamp(speed+acceleration*dt+boostImpulse,12,Config.MaxSpeed)
 local direction=(CFrame.Angles(0,yaw,0)*CFrame.Angles(pitch,0,0)).LookVector
 local sink=settings.sink+(Config.StallSpeed/math.max(speed,12))^2*(stalled and 8 or 1.0)
 local position=state.position+(direction*speed+Vector3.new(0,(updraft or 0)-sink,0))*dt
 return {position=position,yaw=yaw,pitch=pitch,speed=speed,stalled=stalled,bank=bank,boostRemaining=math.max(0,remaining-used),boosting=used>0}
end
function Flight.aimInput(state:State, yaw:number, pitch:number): Vector2
 local difference=(yaw-state.yaw+math.pi)%(2*math.pi)-math.pi
 return Vector2.new(math.clamp(-difference*3.2/Config.TurnRate,-1,1),
  math.clamp((pitch-state.pitch)*3.2/Config.PitchRate,-1,1))
end
function Flight.frame(state:State): CFrame
 return CFrame.new(state.position)*CFrame.Angles(0,state.yaw,0)*CFrame.Angles(state.pitch,0,state.bank)
end
function Flight.segmentDistance(point:Vector3,a:Vector3,b:Vector3): number
 local delta=b-a
 if delta:Dot(delta)<0.000001 then return (point-a).Magnitude end
 local t=math.clamp((point-a):Dot(delta)/delta:Dot(delta),0,1)
 return (point-a:Lerp(b,t)).Magnitude
end
-- Crossing the ring's plane through its opening pays; touching its rim does not.
function Flight.crossedRing(a:Vector3,b:Vector3,center:Vector3,normal:Vector3,radius:number): boolean
 local from=(a-center):Dot(normal)
 local to=(b-center):Dot(normal)
 if (from>0 and to>0) or (from<0 and to<0) or math.abs(from-to)<0.00001 then return false end
 local hit=a:Lerp(b,from/(from-to))-center
 return (hit-normal*hit:Dot(normal)).Magnitude<=radius
end
return Flight
