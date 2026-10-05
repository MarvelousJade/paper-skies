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
 local state=initial or Flight.new(Vector3.new(0,800,0),0,Config.TrimPitch,stats)
 local stalled=false
 for _=1,seconds*hz do
  state=Flight.step(state,Flight.aimInput(state,0,target),1/hz,stats)
  stalled=stalled or state.stalled
 end
 return state,stalled
end
local climb=simulate(math.rad(40),2,60)
check(climb.speed<stats.launchSpeed-15,"climbing must spend speed")
check(climb.position.Y>800,"climb initially gains height")
local _,stalled=simulate(math.rad(48),8,60)
check(stalled,"sustained pull-up must stall")
local recovery=simulate(math.rad(-12),6,60,{position=Vector3.new(0,800,0),yaw=0,pitch=0.2,speed=20,stalled=true,bank=0})
check(not recovery.stalled and recovery.speed>Config.RecoverySpeed,"lowering the nose must recover")
local glide=simulate(Config.TrimPitch,6,60)
check(glide.position.Y<800 and glide.position.Y>660,"glide must descend gradually")
local dive=simulate(math.rad(-35),3,60)
check(dive.speed>stats.launchSpeed,"diving must rebuild speed")
local a=simulate(Config.TrimPitch,5,30);local b=simulate(Config.TrimPitch,5,120)
check((a.position-b.position).Magnitude<3,"glide should be stable across timesteps")
check(Flight.stats({Glide=5}).drag<stats.drag,"fold upgrade reduces drag")
check(Flight.stats({Launch=5}).launchSpeed>stats.launchSpeed,"throw upgrade increases starting speed")
check(Flight.segmentDistance(Vector3.zero,Vector3.new(-20,0,0),Vector3.new(20,0,0))==0,"swept pickup cannot tunnel")
check(Flight.segmentDistance(Vector3.new(0,20,0),Vector3.new(-20,0,0),Vector3.new(20,0,0))==20,"distant pickup rejected")
local p=Economy.new()
check(not Economy.buy(p,"Glide"),"cannot purchase without gold")
p.gold=50;local bought=Economy.buy(p,"Glide")
check(bought and p.gold==0 and p.levels.Glide==1,"purchase deducts exact server price")
check(not Economy.buy(p,"FakeUpgrade"),"unknown upgrade rejected")
p.levels.Glide=5;p.gold=999
check(not Economy.buy(p,"Glide") and p.gold==999,"max-level purchase cannot deduct gold")
check(World.lift(World.Thermals[1].center+Vector3.new(0,200,0))>20,"thermal lifts at center")
check(World.lift(Vector3.new(2700,300,1300))==0,"no invisible lift outside thermals")
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
for _=1,180 do top=Flight.step(top,Vector2.zero,1/60,stats,0,true) end
check(top.speed==Config.MaxSpeed,"base plane reaches 250 SPS with boost")
local idle=Flight.step(top,Vector2.zero,0.25,stats,0,false)
check(idle.boostRemaining==top.boostRemaining,"releasing boost preserves remaining fuel")
local f30=Flight.new(Vector3.new(0,1000,0),0,Config.TrimPitch,stats)
local f120=Flight.new(Vector3.new(0,1000,0),0,Config.TrimPitch,stats)
for _=1,90 do f30=Flight.step(f30,Vector2.zero,1/30,stats,0,true) end
for _=1,360 do f120=Flight.step(f120,Vector2.zero,1/120,stats,0,true) end
check(math.abs(f30.boostRemaining-f120.boostRemaining)<0.0001,"boost duration is timestep-independent")
check(glide.speed>140 and glide.speed<170,"ordinary glide remains near 150 SPS")
return string.format("%d flight, pickup, and upgrade assertions passed",passed)
