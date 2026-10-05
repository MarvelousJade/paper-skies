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
-- Orbit height is independent of a steep upward aim. The old full-direction
-- offset put the camera below the launch deck at maximum pitch.
function Camera.frame(position:Vector3,direction:Vector3,distance:number,params:RaycastParams,side:number?): CFrame
 local horizontal=Vector3.new(direction.X,0,direction.Z)
 horizontal=horizontal.Magnitude>0.001 and horizontal.Unit or Vector3.new(0,0,-1)
 local right=horizontal:Cross(Vector3.yAxis)
 local height=math.clamp(7-direction.Y*distance*0.35,5,18)
 local desired=position-horizontal*distance+Vector3.yAxis*height+right*(side or 0)
 local origin=position+Vector3.yAxis*2.5
 local offset=desired-origin
 -- A volume sweep protects the near plane, not just the camera's center ray.
 local hit=workspace:Spherecast(origin,2,offset,params)
 if hit then desired=origin+offset.Unit*math.max(0,hit.Distance-0.5) end
 -- Look a little ahead while keeping the aircraft visible during steep climbs.
 return CFrame.lookAt(desired,position+direction*8)
end
return Camera
