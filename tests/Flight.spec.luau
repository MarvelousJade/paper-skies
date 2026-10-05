-- Deterministic flight/economy invariants; run in Studio after installation.
local package=game.ReplicatedStorage.PaperFlight
local Config=require(package.Config)
local Flight=require(package.Flight)
local Economy=require(package.Economy)
local World=require(package.WorldData)
local passed=0
local function check(condition,name) assert(condition,name);passed+=1 end
local stats=Flight.stats()
local function simulate(target,seconds,hz,initial)
 local state=initial or Flight.new(Vector3.new(0,400,0),0,Config.TrimPitch,stats)
 local stalled=false;local peakHeight=state.position.Y
 for _=1,seconds*hz do
  state=Flight.step(state,Flight.aimInput(state,0,target),1/hz,stats)
  stalled=stalled or state.stalled;peakHeight=math.max(peakHeight,state.position.Y)
 end
 return state,stalled,peakHeight
end
local climb,_,climbPeak=simulate(math.rad(40),2,60)
check(climb.speed<stats.launchSpeed-15,"climbing must spend speed")
check(climbPeak>405,"climb initially gains height before a lower-energy stall")
local _,stalled=simulate(math.rad(48),8,60)
check(stalled,"sustained pull-up must stall")
local recovery=simulate(math.rad(-12),6,60,{position=Vector3.new(0,800,0),yaw=0,pitch=0.2,speed=20,stalled=true,bank=0})
check(not recovery.stalled and recovery.speed>Config.RecoverySpeed,"lowering the nose must recover")
local glide=simulate(Config.TrimPitch,6,60)
check(glide.position.Y<400 and glide.position.Y>260,"glide must descend gradually")
local dive=simulate(math.rad(-35),3,60)
check(dive.speed>stats.launchSpeed,"diving must rebuild speed")
local a=simulate(Config.TrimPitch,5,30);local b=simulate(Config.TrimPitch,5,120)
check((a.position-b.position).Magnitude<3,"glide should be stable across timesteps")
check(Flight.stats({Glide=5}).drag<stats.drag,"fold upgrade reduces drag")
check(Flight.stats({Launch=5}).launchSpeed>stats.launchSpeed,"throw upgrade increases starting speed")
check(Flight.segmentDistance(Vector3.zero,Vector3.new(-20,0,0),Vector3.new(20,0,0))==0,"swept pickup cannot tunnel")
check(Flight.segmentDistance(Vector3.new(0,20,0),Vector3.new(-20,0,0),Vector3.new(20,0,0))==20,"distant pickup rejected")
check(Economy.flightReward(0,0)==0,"an unflown run earns no passive gold")
check(Economy.flightReward(0,199.99)==0,"partial distance milestones do not round up")
check(Economy.flightReward(0,200)==1,"the first distance coin requires 200 studs")
check(Economy.flightReward(0,1000)==5,"1000 studs earns five passive coins instead of 25")
check(Economy.flightReward(75,1000)==80,"ring rewards remain intact when distance income is reduced")
local p=Economy.new()
check(not Economy.buy(p,"Glide"),"cannot purchase without gold")
p.gold=50;local bought=Economy.buy(p,"Glide")
check(bought and p.gold==0 and p.levels.Glide==1,"purchase deducts exact server price")
check(not Economy.buy(p,"FakeUpgrade"),"unknown upgrade rejected")
p.levels.Glide=5;p.gold=999
check(not Economy.buy(p,"Glide") and p.gold==999,"max-level purchase cannot deduct gold")
check(World.lift(World.Thermals[1].center+Vector3.new(0,200,0),"Dart")>8 and World.lift(World.Thermals[1].center+Vector3.new(0,200,0),"Dart")<13,"starter updraft must remain gentle")
check(World.lift(Vector3.new(4700,300,-5100))==0,"no invisible lift outside thermals")
check(Flight.crossedRing(Vector3.new(0,0,80),Vector3.new(0,0,-80),Vector3.zero,Vector3.zAxis,29),"high-speed crossing through opening")
check(not Flight.crossedRing(Vector3.new(33,0,80),Vector3.new(33,0,-80),Vector3.zero,Vector3.zAxis,29),"outside ring opening rejected")
check(not Flight.crossedRing(Vector3.new(0,0,80),Vector3.new(0,0,40),Vector3.zero,Vector3.zAxis,29),"approaching ring is not a crossing")
check(not Flight.crossedRing(Vector3.zero,Vector3.zero,Vector3.zero,Vector3.zAxis,29),"stationary ring contact rejected")
local boosted=Flight.new(Vector3.new(0,1000,0),0,Config.TrimPitch,stats)
local used=0
for _=1,360 do
 local nextState=Flight.step(boosted,Vector2.zero,1/60,stats,0,true)
 if nextState.boosting then used+=1/60 end
 boosted=nextState
end
check(math.abs(used-Config.BoostDuration)<0.03,"boost lasts only its finite duration")
check(boosted.boostRemaining==0 and not boosted.boosting,"held boost cannot run after fuel is empty")
local top=Flight.new(Vector3.new(0,1000,0),0,Config.TrimPitch,stats)
for _=1,270 do top=Flight.step(top,Vector2.zero,1/60,stats,0,true) end
check(top.speed==160 and top.speed==stats.maxSpeed,"starter boost is capped at 160 SPS")
local idle=Flight.step(top,Vector2.zero,0.25,stats,0,false)
check(idle.boostRemaining==top.boostRemaining and not idle.recharging,"short release pause precedes stamina recovery")
local f30=Flight.new(Vector3.new(0,1000,0),0,Config.TrimPitch,stats)
local f120=Flight.new(Vector3.new(0,1000,0),0,Config.TrimPitch,stats)
for _=1,90 do f30=Flight.step(f30,Vector2.zero,1/30,stats,0,true) end
for _=1,360 do f120=Flight.step(f120,Vector2.zero,1/120,stats,0,true) end
check(math.abs(f30.boostRemaining-f120.boostRemaining)<0.0001,"boost duration is timestep-independent")
check(stats.launchSpeed==90 and glide.speed>90 and glide.speed<100,"starter launches at 90 and settles toward its natural glide speed")
local hangar=Economy.new()
check(hangar.planeId=="Dart" and hangar.ownedPlanes.Dart,"new players own and equip the starter")
check(not Economy.selectPlane(hangar,"Kestrel") and hangar.planeId=="Dart","cannot buy without funds")
check(not Economy.selectPlane(hangar,"Fake"),"unknown plane rejected")
hangar.gold=550
check(Economy.selectPlane(hangar,"Delta") and hangar.gold==0 and hangar.planeId=="Delta","plane purchase pays exact price and equips")
check(Economy.selectPlane(hangar,"Delta") and hangar.gold==0,"owned plane does not charge twice")
check(Economy.selectPlane(hangar,"Dart") and hangar.ownedPlanes.Delta,"switching back retains ownership")
local zone=World.Thermals[10]
local low=zone.center+Vector3.yAxis*200
local high=zone.center+Vector3.yAxis*1500
check(World.lift(low,"Dart")<=12.61,"ground uplift is much weaker than the previous 52")
check(World.lift(high,"Dart")==0,"starter air must not carry players to the highest mountain")
check(World.lift(high,"Kestrel")>0,"advanced aircraft can use high altitude air")
check(World.lift(low,"Invalid")==World.lift(low,"Dart"),"invalid type falls back to starter lift")
local previous
for _,id in Config.PlaneOrder do
 local definition=Config.Planes[id];local stats=Flight.stats({},id)
 check(stats.launchSpeed==definition.launchSpeed,"flight uses equipped type attributes")
 check(World.lift(zone.center+Vector3.yAxis*definition.airCeiling,id)==0,"lift tapers fully at aircraft ceiling")
 if previous then
  check(stats.launchSpeed>previous.launchSpeed and stats.maxSpeed>previous.maxSpeed and stats.drag<previous.drag and stats.sink<previous.sink,"higher tier has stronger flight attributes")
 end
 previous=stats
end
local Store=require(game.ServerScriptService.PaperFlightProfiles)
local saved=Store.sanitize({gold=42,ownedPlanes={Dart=true,Delta=true,Fake=true},planeId="Delta"})
check(saved.planeId=="Delta" and saved.ownedPlanes.Delta and not saved.ownedPlanes.Fake,"profile normalization preserves valid ownership only")
local invalid=Store.sanitize({ownedPlanes={Delta="true"},planeId="Delta"})
check(invalid.planeId=="Dart" and invalid.ownedPlanes.Dart and not invalid.ownedPlanes.Delta,"unowned equipped type falls back safely")
local legacy=Store.sanitize({gold=123,levels={Glide=2,Launch=1,Handling=0}})
check(legacy.gold==123 and legacy.levels.Glide==2 and legacy.planeId=="Dart","legacy profiles retain gold and previous bonuses")
for _,id in Config.PlaneOrder do
 local model=package.PlaneModels:FindFirstChild(id)
 check(model and model.PrimaryPart and model:GetAttribute("PlaneType")==id,"every aircraft type has a matching model")
end

-- Stamina recovery follows released input, independently of flight attitude.
local function drained(id)
 local s=Flight.new(Vector3.new(0,400,0),0,Config.TrimPitch,Flight.stats({},id))
 s.boostRemaining=0
 return s
end
local function coast(s,seconds,hz,settings,held)
 for _=1,math.floor(seconds*hz+0.5) do s=Flight.step(s,Vector2.zero,1/hz,settings,0,held) end
 return s
end
local emptyHeld=coast(drained("Dart"),10,60,stats,true)
check(emptyHeld.boostRemaining==0 and not emptyHeld.boosting,"holding empty boost cannot regenerate or pulse")
local firstRelease=coast(drained("Dart"),1/60,60,stats,false)
check(firstRelease.boostRemaining==0 and not firstRelease.recharging,"first released tick begins the short recovery pause")
local waiting=coast(drained("Dart"),0.3,60,stats,false)
check(waiting.boostRemaining==0,"no recovery before the pause ends")
local acrossDelay=Flight.step(waiting,Vector2.zero,0.1,stats,0,false)
check(math.abs(acrossDelay.boostRemaining-0.045)<0.0001,"a tick across 0.35 seconds recharges only its eligible fraction")
local recharge=coast(drained("Dart"),3,60,stats,false)
check(math.abs(recharge.boostRemaining-(3-Config.BoostRechargeDelay)*stats.boostRecharge)<0.001 and recharge.recharging,"released input refills stamina at the aircraft rate")
local full=coast(drained("Dart"),12,60,stats,false)
check(full.boostRemaining==Config.BoostDuration and not full.recharging,"recharge stops at capacity")
local reused=Flight.step(recharge,Vector2.zero,0.1,stats,0,true)
check(reused.boosting and reused.boostRemaining<recharge.boostRemaining,"recovered stamina powers another boost and stops recharging")
local r30=coast(drained("Dart"),3,30,stats,false)
local r120=coast(drained("Dart"),3,120,stats,false)
check(math.abs(r30.boostRemaining-r120.boostRemaining)<0.0001,"recharge is timestep-independent")
local steep=drained("Dart");steep.pitch=math.rad(20)
steep=Flight.step(steep,Vector2.new(0,0.1),0.4,stats,0,false)
check(steep.boostRemaining>0 and steep.recharging,"stamina also recovers while climbing with boost released")
local falling=drained("Dart");falling.speed=20;falling.stalled=true
falling=Flight.step(falling,Vector2.zero,0.4,stats,0,false)
check(falling.boostRemaining>0 and falling.recharging,"released stamina recovers during a stall")
local refilled=coast(drained("Dart"),5.35,60,stats,false)
check(math.abs(refilled.boostRemaining-Config.BoostDuration)<0.001,"starter refills in five seconds after the brief release pause")
local almostFull=drained("Dart");almostFull.boostRemaining=Config.BoostDuration-0.01;almostFull.boostRest=Config.BoostRechargeDelay
almostFull=Flight.step(almostFull,Vector2.zero,0.1,stats,0,false)
check(almostFull.boostRemaining==Config.BoostDuration,"recovery cannot overflow the bar")
local restart=Flight.step(recharge,Vector2.zero,1/60,stats,0,true)
check(restart.boosting and not restart.recharging and restart.boostRemaining<recharge.boostRemaining and restart.boostRest==0,"pressing boost immediately switches from recovery to spending")
local unchanged=Flight.step(drained("Dart"),Vector2.zero,0,stats,0,false)
check(unchanged.boostRemaining==0 and not unchanged.recharging,"zero elapsed time grants no stamina")
local upgraded=Flight.stats({},"Kestrel")
local fastRecharge=coast(drained("Kestrel"),3,60,upgraded,false)
check(fastRecharge.boostRemaining>recharge.boostRemaining,"better aircraft recover stamina faster")
local function climbTrial(id,hz)
 local settings=Flight.stats({},id)
 local s=Flight.new(Vector3.new(0,350,0),0,math.rad(10),settings)
 local firstStall=nil;local minimumPitch=math.huge
 for i=1,4*hz do
  s=Flight.step(s,Flight.aimInput(s,0,math.rad(24)),1/hz,settings)
  if s.stalled then firstStall=firstStall or i/hz;minimumPitch=math.min(minimumPitch,s.pitch) end
 end
 return s,firstStall,minimumPitch
end
local weak,weakStall,nose=climbTrial("Dart",60)
local strong,strongStall=climbTrial("Kestrel",60)
check(weakStall~=nil and (strongStall==nil or strongStall>weakStall+0.5),"starter stalls on a sustained modest climb before the advanced aircraft")
check(nose<0,"continued pull-up still produces a nose drop after stall")
check(strong.position.Y>weak.position.Y+20,"better aircraft gain more height before their later stall")
local _,stall30=climbTrial("Dart",30);local _,stall120=climbTrial("Dart",120)
check(stall30 and stall120 and math.abs(stall30-stall120)<0.1,"stall onset stays close across simulation timesteps")
local low=Flight.new(Vector3.new(0,400,0),0,0,stats)
local high=Flight.new(Vector3.new(0,950,0),0,0,stats)
low=coast(low,2,60,stats,false);high=coast(high,2,60,stats,false)
check(high.speed<low.speed and high.position.Y-950<low.position.Y-400,"above-envelope flight spends more energy and sinks faster")
local overshoot=Flight.new(Vector3.new(0,stats.airCeiling+1,0),0,math.rad(15),stats)
overshoot=Flight.step(overshoot,Vector2.new(0,0.01),1/60,stats)
check(overshoot.position.Y>stats.airCeiling+1,"altitude limit stays soft and permits momentum overshoot")
local function glideRange(id)
 local settings=Flight.stats({},id)
 local s=Flight.new(Vector3.new(0,350,0),0,0,settings)
 local distance=0
 for _=1,120*60 do
  local next=Flight.step(s,Flight.aimInput(s,0,0),1/60,settings)
  distance+=(Vector3.new(next.position.X,0,next.position.Z)-Vector3.new(s.position.X,0,s.position.Z)).Magnitude
  s=next;if s.position.Y<=20 then break end
 end
 return distance
end
check(glideRange("Kestrel")>glideRange("Dart")*1.2,"upgraded glide efficiency creates substantially longer practical range")
local Camera=require(package.FlightCamera)
local function cameraStep(s,seconds,hz,boosting)
 for _=1,math.floor(seconds*hz+0.5) do s=Camera.step(s,1/hz,boosting) end
 return s
end
local throwView=cameraStep(Camera.new(),0.7,60,false)
check(throwView.fov>75 and throwView.distance>33,"throw briefly widens FOV and pulls camera back")
local normalView=cameraStep(throwView,3,60,false)
check(math.abs(normalView.fov-70)<0.01 and math.abs(normalView.distance-29)<0.01,"throw effect returns to normal flight view")
local boostView=cameraStep(normalView,1,60,true)
check(math.abs(boostView.fov-77)<0.02 and math.abs(boostView.distance-34.5)<0.02,"active boost settles at the reduced zoom target")
local firstRelease=Camera.step(boostView,1/60,false)
check(firstRelease.fov<boostView.fov and firstRelease.fov>70,"boost release eases back instead of snapping")
local releasedView=cameraStep(firstRelease,2,60,false)
check(math.abs(releasedView.fov-70)<0.01 and math.abs(releasedView.distance-29)<0.01,"released boost returns to normal regardless of residual speed")
local c30=cameraStep(Camera.new(),0.7,30,false);local c120=cameraStep(Camera.new(),0.7,120,false)
check(math.abs(c30.fov-c120.fov)<0.3 and math.abs(c30.distance-c120.distance)<0.3,"throw framing is stable across frame rates")
local restarted=Camera.new()
check(restarted.age==0 and restarted.fov==65,"each new throw resets camera effect state")

-- Fresh throws have a brief soft transition; ordinary flight still loses lift.
local function steepThrow(hz,age)
 local s=Flight.new(Vector3.new(0,350,0),0,Config.MaxPitch,stats)
 if age then s.age=age end
 local firstStall;local maxY=s.position.Y;local early
 for i=1,2*hz do
  s=Flight.step(s,Flight.aimInput(s,0,Config.MaxPitch),1/hz,stats)
  if i==math.floor(hz*0.1) then early=s end
  if s.stalled then firstStall=firstStall or i/hz end
  maxY=math.max(maxY,s.position.Y)
 end
 return firstStall,maxY-350,early,s
end
local freshStall,freshHeight,early,fresh=steepThrow(60)
local normalStall,normalHeight=steepThrow(60,10)
check(freshStall>0.4 and freshStall>normalStall+0.3,"steep throw gets time to leave the hand before stalling")
check(early.speed<stats.launchSpeed and early.speed>stats.launchSpeed*0.85,"throw keeps initial momentum but gravity still spends speed")
check(freshHeight>normalHeight+15 and freshHeight<90,"throw grace gives a small launch arc, not mountain-scale free height")
check(freshStall<1.5 and fresh.pitch<0,"continued steep launch eventually stalls and drops its nose")
check(math.abs(fresh.age-2)<0.0001,"simulation time consumes the throw transition once")
local t30,h30=steepThrow(30);local t120,h120=steepThrow(120)
check(math.abs(t30-t120)<0.06 and math.abs(h30-h120)<3,"throw transition remains consistent across tick rates")
local established=Flight.new(Vector3.new(0,400,0),0,math.rad(24),stats)
established.age=Config.ThrowClimbEaseDuration
local longFlight=table.clone(established);longFlight.age=40
local legacyFlight=table.clone(established);legacyFlight.age=nil
local normalStep=Flight.step(established,Vector2.zero,1/60,stats)
local lateStep=Flight.step(longFlight,Vector2.zero,1/60,stats)
local legacyStep=Flight.step(legacyFlight,Vector2.zero,1/60,stats)
check(normalStep.speed==lateStep.speed and normalStep.pitch==lateStep.pitch,"ordinary physics fully resumes after the transition")
check(legacyStep.speed==lateStep.speed and legacyStep.stalled==lateStep.stalled,"states without launch age do not acquire fresh throw assistance")
local boostedLate=Flight.step(longFlight,Vector2.zero,1/60,stats,0,true)
check(boostedLate.age>40 and boostedLate.boostRemaining<longFlight.boostRemaining,"boost spends fuel without restarting the throw transition")
local lowEnergy=Flight.new(Vector3.new(0,400,0),0,Config.MaxPitch,stats);lowEnergy.speed=20
check(Flight.step(lowEnergy,Vector2.zero,1/60,stats).stalled,"launch assistance cannot keep an already slow plane flying")

-- Full feedback-loop regression: stale aim previously caused repeated climb/stall cycles.
for _,boostSeconds in {0,3} do
 local s=Flight.new(Vector3.new(0,350,0),0,math.rad(24),stats)
 local aim=math.rad(24);local stalls=0
 for i=1,12*60 do
  -- Match the client's 10 Hz telemetry-driven clearing of stale upward aim.
  if i%6==0 then aim=Flight.settleAim(aim,s.stalled) end
  local next=Flight.step(s,Flight.aimInput(s,0,aim),1/60,stats,0,i<=boostSeconds*60)
  if next.stalled and not s.stalled then stalls+=1 end
  s=next
 end
 check(stalls==1,"a held upward aim must not restart a climb/stall cycle after recovery")
 check(not s.stalled and s.speed>Config.RecoverySpeed,"plane settles into a moving glide after its stall")
 check(s.pitch<0 and s.pitch>math.rad(-12),"recovered plane settles into shallow glide instead of diving indefinitely")
end
local level=Flight.new(Vector3.new(0,400,0),0,0,stats)
local powered=Flight.step(level,Vector2.zero,0.1,stats,0,true)
local unpowered=Flight.step(level,Vector2.zero,0.1,stats,0,false)
check(powered.pitch==unpowered.pitch and powered.speed>unpowered.speed,"boost adds forward speed without pitching up")
local release=Flight.step(powered,Vector2.zero,0.1,stats,0,false)
check(release.speed>powered.speed-2,"boost release preserves momentum rather than resetting speed")
check(Flight.settleAim(math.rad(-25),true)==math.rad(-25),"stall recovery preserves an intentional dive aim")
local freshControl=Flight.new(Vector3.new(0,400,0),0,Config.TrimPitch,stats)
local directed=Flight.step(freshControl,Flight.aimInput(freshControl,0,math.rad(20)),0.1,stats)
check(directed.pitch>freshControl.pitch,"the player can deliberately pitch up again after recovery")
-- Each equipped plane owns its speed limit; boost and dives respect that limit.
-- Isolate boost from drag/gravity: each purchased plane adds more forward impulse.
local previousImpulse=0
for _,id in Config.PlaneOrder do
 local settings=Flight.stats({},id)
 local start=Flight.new(Vector3.new(0,400,0),0,0,settings);start.speed=90
 local on=Flight.step(start,Vector2.zero,0.1,settings,0,true)
 local off=Flight.step(start,Vector2.zero,0.1,settings,0,false)
 local impulse=on.speed-off.speed
 check(impulse>previousImpulse,"Purchased plane boost must accelerate more strongly than the previous tier")
 previousImpulse=impulse
end
local expectedCaps={Dart=160,Lockwing=190,Delta=220,Sailwing=250,Kestrel=280}
for _,id in Config.PlaneOrder do
 local settings=Flight.stats({},id)
 check(settings.maxSpeed==expectedCaps[id],"Equipped plane receives its advertised top speed")
 local s=Flight.new(Vector3.new(0,400,0),0,Config.TrimPitch,settings)
 for i=1,270 do
  s=Flight.step(s,Vector2.zero,1/60,settings,0,true)
  check(s.speed<=settings.maxSpeed,"Boost cannot exceed the equipped plane limit")
 end
 check(s.speed==settings.maxSpeed,"Every tier can reach its top speed within a full boost bar")
 s.pitch=math.rad(-55)
 for i=1,60 do
  s=Flight.step(s,Vector2.new(0,-0.1),1/60,settings,0,true)
  check(s.speed<=settings.maxSpeed,"A dive cannot bypass the plane limit")
 end
 local maxed=Flight.stats({Launch=5,Glide=5},id)
 local upgraded=Flight.new(Vector3.new(0,400,0),0,Config.TrimPitch,maxed)
 for i=1,270 do upgraded=Flight.step(upgraded,Vector2.zero,1/60,maxed,0,true) end
 check(upgraded.speed==settings.maxSpeed,"Legacy bonuses preserve each plane's top speed")
end
check(Flight.stats({},"Invalid").maxSpeed==160,"Invalid type falls back to the starter cap")
return string.format("%d flight, pickup, upgrade, and camera assertions passed",passed)
