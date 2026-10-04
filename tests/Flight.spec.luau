-- Run from Studio's command bar after installing PaperFlight.
local package=game.ReplicatedStorage.PaperFlight
local Flight=require(package.Flight)
local Config=require(package.Config)
local count=0
local function check(condition,message)
 assert(condition,message); count+=1
end
local center=Vector3.new(0,100,0)
check(Flight.crossed(Vector3.new(0,100,50),Vector3.new(0,100,-50),center),"swept crossing")
check(not Flight.crossed(Vector3.new(30,100,50),Vector3.new(30,100,-50),center),"outside radius")
check(not Flight.crossed(Vector3.new(0,100,-50),Vector3.new(0,100,50),center),"backward crossing")
check(not Flight.crossed(Vector3.new(0,100,50),Vector3.new(0,100,50),center),"stationary segment")
local function simulate(hz)
 local state={position=Config.Launch,yaw=0,pitch=0}
 for _=1,hz*2 do state=Flight.step(state,Vector2.new(0.25,0.2),1/hz) end
 return state
end
local coarse,fine=simulate(30),simulate(120)
check((coarse.position-fine.position).Magnitude<2,"flight is consistent across step sizes")
local state={position=Config.Launch,yaw=0,pitch=0}
for _=1,600 do state=Flight.step(state,Vector2.new(0,1),1/60) end
check(math.abs(state.pitch-Config.MaxPitch)<0.001,"climb pitch clamp")
local straight=Flight.step({position=Config.Launch,yaw=0,pitch=0},Vector2.zero,1/60)
check(straight.position.Z<Config.Launch.Z,"forward direction")
return string.format("%d flight/checkpoint assertions passed",count)

