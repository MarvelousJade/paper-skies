-- Geometry and discovery-layout checks; run after rebuilding the world.
local package=game.ReplicatedStorage.PaperFlight
local L=require(package.Landscape)
local W=require(package.WorldData)
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={workspace.Terrain,workspace.PaperFlightWorld}
local passed=0
local function check(value,message) assert(value,message);passed+=1 end
for _,t in L.Tunnels do
 local cf=CFrame.lookAt(t.center,t.center+t.normal)
 for _,offset in {Vector3.zero,cf.RightVector*12,-cf.RightVector*12,Vector3.yAxis*5,-Vector3.yAxis*5} do
  check(not workspace:Raycast(t.center-t.normal*t.length/2+offset,t.normal*t.length,params),t.name.." approach must remain open")
 end
end
for _,r in W.Rings do
 check(not workspace:Raycast(r.position-r.normal*16,r.normal*32,params),"Ring "..r.id.." opening is blocked")
 check((Vector2.new(r.position.X+550,r.position.Z-534)).Magnitude>1000,"No reward rail close to launch")
 if r.group:find("Meandering") then check(r.radius==6,"Sky rings must be 12 studs across") end
end
local species={};local hidden=0;local visible=0
for _,a in W.Animals do
 local _,_,mountain=L.height(a.position.X,a.position.Z)
 check(not mountain,"Animals must stay off mountains")
 species[a.species]=true
 check(a.scale==0.62,"Wildlife must use the smaller scale")
 if a.behindPeak then
  hidden+=1;local occluded=false;local launch=Vector3.new(-550,370,534)
  for step=1,19 do local sight=launch:Lerp(a.position+Vector3.yAxis*35,step/20)
   if L.height(sight.X,sight.Z)>sight.Y+50 then occluded=true;break end
  end
  check(occluded,"Rear wildlife must be hidden by a mountain from launch")
 else visible+=1 end
 local cf=CFrame.Angles(0,a.heading,0);local center=a.position+Vector3.yAxis*9
 for _,off in {Vector3.zero,cf.RightVector*3.6,-cf.RightVector*3.6,Vector3.yAxis*1.5,-Vector3.yAxis*1.5} do
  check(not workspace:Raycast(center-cf.LookVector*70+off,cf.LookVector*140,params),"Belly flight corridor blocked: "..a.species..a.id)
 end
end
check(hidden==13 and visible==2,"Only two animals should occupy the introductory valley")
for _,summit in W.Summits do
 local ring
 for _,r in W.Rings do if r.group=="Summit "..summit.peak then ring=r;break end end
 check(ring~=nil,"Every mountain needs a summit reward")
 check(ring.position.Y-summit.position.Y>=10 and ring.position.Y-summit.position.Y<25,"Summit ring must sit close to the tip")
 local cf=CFrame.lookAt(ring.position,ring.position+ring.normal)
 for _,off in {Vector3.zero,cf.RightVector*3.6,-cf.RightVector*3.6,Vector3.yAxis*1.5,-Vector3.yAxis*1.5} do
  check(not workspace:Raycast(ring.position-ring.normal*90+off,ring.normal*180,params),"Summit approach must clear the rock")
 end
end
local kinds=0;for _ in species do kinds+=1 end
check(kinds==5 and #W.Animals==15,"Five animal species must be scattered through the lowlands")
for _,p in {Vector2.new(-700,650),Vector2.new(-400,950),Vector2.new(-550,800)} do
 check(math.abs(L.height(p.X,p.Y)-349)<0.1,"Launch plateau must have a broad flat summit")
end
local previous
for _,r in W.Rings do
 if previous and previous.group==r.group and r.group:find("Meandering") then
  local gap=(r.position-previous.position).Magnitude
  check(gap>25 and gap<48,"Curved sky clusters must stay close together")
 end
 previous=r
end
return string.format("%d geometry and discovery-layout checks passed",passed)
