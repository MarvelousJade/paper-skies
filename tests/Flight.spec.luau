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
check(top.speed==Config.MaxSpeed,"base plane reaches 250 SPS with boost")
local idle=Flight.step(top,Vector2.zero,0.25,stats,0,false)
check(idle.boostRemaining==top.boostRemaining,"release delay prevents immediate recharge")
local f30=Flight.new(Vector3.new(0,1000,0),0,Config.TrimPitch,stats)
local f120=Flight.new(Vector3.new(0,1000,0),0,Config.TrimPitch,stats)
for _=1,90 do f30=Flight.step(f30,Vector2.zero,1/30,stats,0,true) end
for _=1,360 do f120=Flight.step(f120,Vector2.zero,1/120,stats,0,true) end
check(math.abs(f30.boostRemaining-f120.boostRemaining)<0.0001,"boost duration is timestep-independent")
check(stats.launchSpeed==100 and glide.speed>95 and glide.speed<105,"starter launch and ordinary glide remain near 100 SPS")
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
  check(stats.launchSpeed>previous.launchSpeed and stats.drag<previous.drag and stats.sink<previous.sink,"higher tier has stronger flight attributes")
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

-- Recharge tests use an in-envelope height; altitude pressure has its own fixtures below.
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
local delayed=coast(drained("Dart"),0.75,60,stats,false)
check(delayed.boostRemaining==0,"stable glide waits before recharge")
local recharge=coast(drained("Dart"),3,60,stats,false)
check(math.abs(recharge.boostRemaining-(3-Config.BoostRechargeDelay)*stats.boostRecharge)<0.001 and recharge.recharging,"stable glide refills stamina at the aircraft rate")
local full=coast(drained("Dart"),12,60,stats,false)
check(full.boostRemaining==Config.BoostDuration and not full.recharging,"recharge stops at capacity")
local reused=Flight.step(recharge,Vector2.zero,0.1,stats,0,true)
check(reused.boosting and reused.boostRemaining<recharge.boostRemaining and reused.boostRest==0,"recovered stamina powers another boost and resets delay")
local r30=coast(drained("Dart"),3,30,stats,false)
local r120=coast(drained("Dart"),3,120,stats,false)
check(math.abs(r30.boostRemaining-r120.boostRemaining)<0.0001,"recharge delay and rate are timestep-independent")
local steep=drained("Dart");steep.pitch=math.rad(20)
steep=Flight.step(steep,Vector2.new(0,0.1),0.1,stats,0,false)
check(steep.boostRemaining==0 and steep.boostRest==0,"pulling uphill cannot recharge stamina")
local falling=drained("Dart");falling.speed=20;falling.stalled=true
falling=Flight.step(falling,Vector2.zero,0.1,stats,0,false)
check(falling.boostRemaining==0,"a stall cannot recharge stamina")
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

return string.format("%d flight, pickup, upgrade, and camera assertions passed",passed)
