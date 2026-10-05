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
 local passage=r.position
 check(not workspace:Raycast(passage-r.normal*16,r.normal*32,params),"Ring "..r.id.." opening is blocked")
 check((Vector2.new(r.position.X+550,r.position.Z-534)).Magnitude>1000,"No reward rail close to launch")
 if r.group:find("Meandering") then check(r.radius==12,"Sky rings must be 24 studs across") end
end
local species={};local hidden=0;local visible=0
local roster={Bear=true,SilverFox=true,Turtle=true,Raccoon=true,CandyCat=true,Gorilla=true,Mammoth=true}
for _,a in W.Animals do
 local _,_,mountain=L.height(a.position.X,a.position.Z)
 check(not mountain,"Animals must stay off mountains")
 species[a.species]=true
 local model=workspace.PaperFlightWorld.PaperAnimals:FindFirstChild(a.species..a.id)
 check(roster[a.species] and model and model:GetAttribute("ReferenceStyle")=="LayeredBlock","Every encounter must use a reference model; no legacy animals")
 check(a.scale==0.62,"Wildlife must use the smaller scale")
 if a.behindPeak then
  hidden+=1;local occluded=false;local launch=Vector3.new(-550,370,534)
  for step=1,19 do local sight=launch:Lerp(a.position+Vector3.yAxis*35,step/20)
   if L.height(sight.X,sight.Z)>sight.Y+50 then occluded=true;break end
  end
  check(occluded,"Rear wildlife must be hidden by a mountain from launch")
 else visible+=1 end
 local cf=CFrame.Angles(0,a.heading,0);local center=a.position+Vector3.yAxis*18
 local direction=cf.RightVector
 for _,off in {Vector3.zero,cf.LookVector*3.6,-cf.LookVector*3.6,Vector3.yAxis*1.5,-Vector3.yAxis*1.5} do
  check(not workspace:Raycast(center-direction*70+off,direction*140,params),"Belly flight corridor blocked: "..a.species..a.id)
 end
end
check(hidden==13 and visible==2,"Only two field animals complement thirteen hidden encounters")
for _,summit in W.Summits do
 local ring
 for _,r in W.Rings do if r.group=="Summit "..summit.peak then ring=r;break end end
 check(ring~=nil,"Every mountain needs a summit reward")
 check(ring.position.Y-summit.position.Y>=17 and ring.position.Y-summit.position.Y<32,"Summit ring must sit close to the tip")
 local cf=CFrame.lookAt(ring.position,ring.position+ring.normal)
 for _,off in {Vector3.zero,cf.RightVector*3.6,-cf.RightVector*3.6,Vector3.yAxis*1.5,-Vector3.yAxis*1.5} do
  check(not workspace:Raycast(ring.position-ring.normal*90+off,ring.normal*180,params),"Summit approach must clear the rock")
 end
end
local kinds=0;for _ in species do kinds+=1 end
check(kinds==7 and #W.Animals==15,"Seven animal species must be scattered through the lowlands")
for _,p in {Vector2.new(-700,380),Vector2.new(-400,700),Vector2.new(-550,534)} do
 check(math.abs(L.height(p.X,p.Y)-349)<0.1,"Launch plateau must have a broad flat summit")
end
local previous
for _,r in W.Rings do
 if previous and previous.group==r.group and r.group:find("Meandering") then
  local gap=(r.position-previous.position).Magnitude
  check(gap>23 and gap<26,"Curved sky clusters must stay close together")
 end
 previous=r
end
-- Sample the full ring rim and a plane-width passage, not just the center.
for _,ring in W.Rings do
 local frame=CFrame.lookAt(ring.position,ring.position+ring.normal)
 local rimRadius=ring.radius+require(package.Config).RingTubeThickness/2+0.1
 for i=0,11 do
  local angle=i*math.pi/6
  local offset=frame.RightVector*math.cos(angle)*rimRadius+Vector3.yAxis*math.sin(angle)*rimRadius
  check(not workspace:Raycast(ring.position+offset-ring.normal,ring.normal*2,params),"Doubled ring rim intersects scenery: "..ring.id)
 end
end
for _,animal in W.Animals do
 local found
 for _,ring in W.Rings do
  if ring.animalId==animal.id then found=ring;break end
 end
 check(found~=nil,"Every animal needs a complete ring reward")
 local side=CFrame.Angles(0,animal.heading,0).RightVector
 check(math.abs(found.normal:Dot(side))>0.999,"Animal rewards must face sideways")
 local crossing=found.position
 check(require(package.Flight).crossedRing(crossing-side*30,crossing+side*30,found.position,found.normal,found.radius-require(package.Config).RingMargin),"A side-on belly flight must earn the belly reward")
 local model=workspace.PaperFlightWorld.Rings:FindFirstChild("Ring"..found.id)
 check(#model:GetChildren()==48,"Animal reward displays a complete ring")
end
local forward=0;local trails={}
for _,a in W.Animals do
 if a.forwardMeadow then forward+=1;check(a.position.Z<0 and a.position.Y<110,"Visible wildlife belongs in the forward field") end
end
for _,r in W.Rings do if r.group:find("Meandering") then trails[r.group]=(trails[r.group] or 0)+1 end end
local trailCount=0
for _,count in trails do
 trailCount+=1
 check(count==10,"Each connected sky trail contains ten pickups")
end
check(forward==2,"Keep exactly two open-field animals")
check(trailCount==31,"Keep twenty-four existing trails plus seven high trails")
local highCount=0;local highGroups={}
for _,ring in W.Rings do if ring.highSky then
 highCount+=1;highGroups[ring.group]=true
 check(ring.position.Y>=470 and ring.position.Y<2100,"High sky trails must be elevated but below the top plane's ceiling")
 check(ring.position.Y-L.height(ring.position.X,ring.position.Z)>=59,"High sky rings need clear air above the slope")
end end
local highTrailCount=0;for _ in highGroups do highTrailCount+=1 end
check(highCount==70 and highTrailCount==7,"Every mountain gets a ten-ring high trail")
local bearings={};local front,back,left,right=0,0,0,0
for _,peak in L.Peaks do
 local dx,dz=peak.x+550,peak.z-534
 table.insert(bearings,math.atan2(dz,dx))
 if dz<0 then front+=1 else back+=1 end
 if dx<0 then left+=1 else right+=1 end
end
table.sort(bearings)
check(front>=3 and back>=3 and left>=3 and right>=3,"mountains must surround the start")
for i,a in bearings do
 local b=bearings[i%#bearings+1];if i==#bearings then b+=math.pi*2 end
 check(b-a<math.rad(75),"no large empty sector around spawn")
end
for _,r in W.Rings do
 if r.group:find("^Summit ") then
  local model=workspace.PaperFlightWorld.Rings:FindFirstChild("Ring"..r.id)
  check(model.ModelStreamingMode==Enum.ModelStreamingMode.Persistent,"summit rewards must remain loaded at distance")
  check(model:FindFirstChild("SummitBeacon")~=nil,"summit reward needs a distant halo")
 end
end
local F=require(package.Flight);local C=require(package.Config)
for i=0,7 do
 local yaw=i*math.pi/4;local state=F.new(C.Launch,yaw,C.AimPitch,F.stats());local clear=true
 for tick=1,180 do
  local next=F.step(state,F.aimInput(state,yaw,C.AimPitch),1/60,F.stats(),W.lift(state.position,"Dart"))
  if workspace:Raycast(state.position,next.position-state.position,params) then clear=false;break end
  state=next
 end
 check(clear,"default throw must clear plateau in all directions")
end
return string.format("%d geometry and discovery-layout checks passed",passed)
