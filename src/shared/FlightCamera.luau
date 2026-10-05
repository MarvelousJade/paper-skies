--!strict
-- Presentation only: neither camera movement nor FOV changes the server's flight speed.
local Camera = {}
export type State = {age:number,fov:number,distance:number}
function Camera.new(): State
 return {age=0,fov=65,distance=17}
end
function Camera.step(state:State,dt:number,boosting:boolean): State
 local age=state.age+math.max(0,dt)
 local throwPulse=math.sin(math.pi*math.clamp(age/1.4,0,1))
 -- Half-strength boost zoom keeps the speed cue comfortable during exploration.
 local fov=70+math.max(throwPulse*10,boosting and 7 or 0)
 local distance=29+math.max(throwPulse*9,boosting and 5.5 or 0)
 local blend=1-math.exp(-7*math.max(0,dt))
 return {age=age,fov=state.fov+(fov-state.fov)*blend,distance=state.distance+(distance-state.distance)*blend}
end
return Camera
