--!strict
local Config = require(script.Parent.Config)
export type Stats = {launchSpeed:number, drag:number, sink:number, turnRate:number,
 climbComfort:number, climbLoss:number, airCeiling:number, boostRecharge:number}
export type State = {position:Vector3, yaw:number, pitch:number, speed:number, stalled:boolean, bank:number,
 boostRemaining:number?, boosting:boolean?, recharging:boolean?, age:number?, boostRest:number?}
local Flight = {}
function Flight.stats(levels: {[string]:number}?,planeId:string?): Stats
 local l=levels or {};local plane=Config.Planes[planeId or "Dart"] or Config.Planes.Dart
 return {launchSpeed=plane.launchSpeed+(l.Launch or 0)*6, drag=plane.drag*(1-0.085*(l.Glide or 0)),
  sink=plane.sink*(1-0.07*(l.Glide or 0)), turnRate=Config.TurnRate*plane.handling*(1+0.08*(l.Handling or 0)),
  climbComfort=plane.climbComfort,climbLoss=plane.climbLoss,airCeiling=plane.airCeiling,boostRecharge=plane.boostRecharge}
end
function Flight.new(position:Vector3, yaw:number, pitch:number, stats:Stats): State
 return {position=position,yaw=yaw,pitch=pitch,speed=stats.launchSpeed,stalled=false,bank=0,
  boostRemaining=Config.BoostDuration,boosting=false,recharging=false,age=0,boostRest=0}
end
function Flight.step(state:State, steer:Vector2, dt:number, stats:Stats?, updraft:number?, boostHeld:boolean?): State
 local settings=stats or Flight.stats()
 local step=math.max(0,dt)
 -- Missing age means established flight, so partial/legacy states get no fresh throw bonus.
 local age=state.age or Config.ThrowClimbEaseDuration
 local progress=math.clamp((age+step*0.5)/Config.ThrowClimbEaseDuration,0,1)
 local blend=progress*progress*(3-2*progress)
 local climbScale=Config.ThrowClimbInitialScale+(1-Config.ThrowClimbInitialScale)*blend
 local speed=state.speed
 local stalled=state.stalled
 -- Pulling up raises the speed needed to retain lift. Recovery has a separate threshold.
 local stallThreshold=Config.StallSpeed+math.max(0,math.sin(state.pitch))*Config.ClimbStallRise*climbScale
 if speed<stallThreshold then stalled=true end
 if stalled and speed>Config.RecoverySpeed and state.pitch<0 then stalled=false end
 local pitch=state.pitch
 if stalled then
  -- A stalled paper plane drops its nose even while the player continues pulling up.
  pitch += (Config.StallPitch-pitch)*(1-math.exp(-Config.StallNoseRate*step))
 else
  pitch=math.clamp(pitch+steer.Y*Config.PitchRate*step,Config.MinPitch,Config.MaxPitch)
  if math.abs(steer.Y)<0.01 then pitch+=(Config.TrimPitch-pitch)*(1-math.exp(-0.65*step)) end
 end
 local authority=math.clamp(speed/65,0.25,1)
 local yaw=state.yaw-steer.X*settings.turnRate*authority*step
 local bank=state.bank+(-steer.X*0.62-state.bank)*(1-math.exp(-5*step))
 -- These are soft energy costs, not angle/altitude clamps. Better folds tolerate steeper climbs.
 local excessClimb=math.max(0,pitch-settings.climbComfort)/math.rad(30)
 local altitudeLoad=math.clamp((state.position.Y-settings.airCeiling)/Config.AltitudeSoftBand,0,3)
 local climbDrag=settings.climbLoss*excessClimb*excessClimb*climbScale
 local drag=settings.drag*speed*speed + math.abs(steer.X)*1.9 + climbDrag + altitudeLoad*8
 local remaining=math.clamp(state.boostRemaining or 0,0,Config.BoostDuration)
 local used=boostHeld and math.min(step,remaining) or 0
 local acceleration=-Config.Gravity*math.sin(pitch)-drag
 speed=math.clamp(speed+acceleration*step+Config.BoostAcceleration*used,12,Config.MaxSpeed)
 local direction=(CFrame.Angles(0,yaw,0)*CFrame.Angles(pitch,0,0)).LookVector
 local sink=settings.sink+(Config.StallSpeed/math.max(speed,12))^2*(stalled and Config.StallSinkMultiplier or 1)+altitudeLoad*10
 local position=state.position+(direction*speed+Vector3.new(0,(updraft or 0)-sink,0))*step
 -- Recovery starts after a short released interval, regardless of flight attitude.
 -- Integrate only time beyond the delay, including ticks that straddle its end.
 local oldRest=state.boostRest or 0
 local rest=not boostHeld and oldRest+step or 0
 local recoveryTime=not boostHeld and math.max(0,rest-Config.BoostRechargeDelay)-math.max(0,oldRest-Config.BoostRechargeDelay) or 0
 local restored=recoveryTime*settings.boostRecharge
 local afterUse=math.max(0,remaining-used)
 local fuel=math.min(Config.BoostDuration,afterUse+restored)
 return {position=position,yaw=yaw,pitch=pitch,speed=speed,stalled=stalled,bank=bank,
  boostRemaining=fuel,boosting=used>0,recharging=fuel>afterUse,age=age+step,boostRest=rest}
end
-- Drop a stale upward aim after a stall so recovery leads into a glide instead
-- of immediately pulling up and stalling again. Intentional dive aims are retained.
function Flight.settleAim(pitch:number,stalled:boolean): number
 return stalled and math.min(pitch,Config.TrimPitch) or pitch
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
