-- Regression for a maximum-angle throw landing back on the old wide plateau.
local P=game.ReplicatedStorage.PaperFlight
local F=require(P.Flight);local C=require(P.Config);local Camera=require(P.FlightCamera)
local L=require(P.Landscape);local W=require(P.WorldData)
local passed=0
local function check(value,message) assert(value,message);passed+=1 end
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={workspace.Terrain,workspace.PaperFlightWorld};params.IgnoreWater=true
local minimumCameraClearance=math.huge
for _,degrees in {10,30,48} do for bearing=0,7 do
 local yaw=bearing*math.pi/4;local pitch=math.rad(degrees)
 local direction=(CFrame.Angles(0,yaw,0)*CFrame.Angles(pitch,0,0)).LookVector
 local s=F.new(C.Launch,yaw,pitch,F.stats());local motion=Camera.new()
 for i=0,180 do
  if i%6==0 then
   local cf=Camera.frame(s.position,direction,motion.distance,params)
   check(cf.Position.Y>s.position.Y,"Upward aim must never orbit underneath the aircraft")
   local down=workspace:Raycast(cf.Position+Vector3.yAxis*40,-Vector3.yAxis*300,params)
   if down then
    local clearance=cf.Position.Y-down.Position.Y
    minimumCameraClearance=math.min(minimumCameraClearance,clearance)
    check(clearance>2,"Launch camera stays above terrain and deck")
   end
   local sight=s.position+Vector3.yAxis*2.5
   check(not workspace:Raycast(sight,cf.Position-sight,params),"Camera view cannot pass through launch scenery")
  end
  if i==180 then break end
  local next=F.step(s,F.aimInput(s,yaw,pitch),1/60,F.stats(),W.lift(s.position,"Dart"))
  local hit=workspace:Raycast(s.position,next.position-s.position,params)
  check(not hit,string.format("%d degree throw hits launch scenery at %.2fs, bearing %d",degrees,i/60,bearing))
  s=next;motion=Camera.step(motion,1/60,false)
 end
end end
for _,pitch in {C.MinPitch,C.MaxPitch} do for bearing=0,7 do
 local dir=(CFrame.Angles(0,bearing*math.pi/4,0)*CFrame.Angles(pitch,0,0)).LookVector
 local focus=C.ThrowStand+Vector3.yAxis*2
 local cf=Camera.frame(focus,dir,17,params,-3)
 check(cf.Position.Y>focus.Y,"Aiming camera stays above the standing player at pitch limits")
end end
check(L.height(-550,534)==349,"Keep original launch height")
for _,p in {Vector2.new(-700,534),Vector2.new(-400,534),Vector2.new(-550,370),Vector2.new(-550,700)} do
 check(L.height(p.X,p.Y)<120,"Former broad plateau is now open lowland")
 local hit=workspace:Raycast(Vector3.new(p.X,420,p.Y),Vector3.new(0,-500,0),params)
 check(hit and hit.Position.Y<125,"Old high terrain voxels must be removed too")
end
-- A wall behind the plane should shorten follow distance instead of clipping.
local fixture=Instance.new("Part");fixture.Name="CameraCollisionFixture";fixture.Anchored=true
fixture.Size=Vector3.new(30,50,4);fixture.Position=Vector3.new(6000,800,6015);fixture.Parent=workspace
local success,result=xpcall(function()
 local onlyWall=RaycastParams.new();onlyWall.FilterType=Enum.RaycastFilterType.Include;onlyWall.FilterDescendantsInstances={fixture}
 local cf=Camera.frame(Vector3.new(6000,800,6000),Vector3.new(0,0,-1),38,onlyWall)
 check(cf.Position.Z<6011,"Camera sweep stops before its near plane clips a wall")
 check(not workspace:Raycast(Vector3.new(6000,802.5,6000),cf.Position-Vector3.new(6000,802.5,6000),onlyWall),"Resolved camera has clear sight to its target")
end,debug.traceback)
fixture:Destroy();assert(success,result)
return string.format("%d launch/camera checks passed; minimum sampled camera clearance %.2f studs",passed,minimumCameraClearance)
