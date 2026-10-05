-- Validate the complete authored layout, including staged rear scenery.
local staged=game.ServerStorage:FindFirstChild("PaperDeferredWorld")
local stagedObjects=staged and staged:GetChildren() or {}
for _,object in stagedObjects do object.Parent=workspace.PaperFlightWorld[object:GetAttribute("TargetGroup")] end
local success,result=xpcall(function()
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
 local passage=r.passagePosition or r.position
 check(not workspace:Raycast(passage-r.normal*16,r.normal*32,params),"Ring "..r.id.." opening is blocked")
 check((Vector2.new(r.position.X+550,r.position.Z-534)).Magnitude>1000,"No reward rail close to launch")
 if r.group:find("Meandering") then check(r.radius==12,"Sky rings must be 24 studs across") end
end
local species={};local hidden=0;local visible=0
local mountainEncounters={};local mountainSpecies={}
local roster={Bear=true,SilverFox=true,Turtle=true,Raccoon=true,CandyCat=true,Gorilla=true,Mammoth=true}
for _,a in W.Animals do
 local _,_,mountain=L.height(a.position.X,a.position.Z)
 check(not mountain,"Animals must stay off mountains")
 species[a.species]=true
 local model=workspace.PaperFlightWorld.PaperAnimals:FindFirstChild(a.species..a.id)
 check(roster[a.species] and model and model:GetAttribute("ReferenceStyle")=="LayeredBlock","Every encounter must use a reference model; no legacy animals")
 check(a.scale==0.62,"Wildlife must use the smaller scale")
 check((model:GetPivot().Position-a.position).Magnitude<.05,"Actual wildlife geometry must match its authored encounter and streaming position")
 local groundParams=RaycastParams.new();groundParams.FilterType=Enum.RaycastFilterType.Include;groundParams.FilterDescendantsInstances={workspace.Terrain}
 for _,foot in model:GetChildren() do
  if foot.Name=="RoundedPaw" or foot.Name=="RearFoot" or foot.Name=="MammothFoot" then
   local hit=workspace:Raycast(foot.Position+Vector3.yAxis*30,-Vector3.yAxis*60,groundParams)
   check(hit and math.abs(foot.Position.Y-foot.Size.Y/2-hit.Position.Y)<1.2,"Animal paws must meet the rendered terrain")
  end
 end
 if a.behindPeak then
  check(L.Peaks[a.behindPeak]~=nil,"Wildlife must reference a real mountain")
  check(not mountainEncounters[a.behindPeak],"Only one animal may belong behind each mountain")
  check(not mountainSpecies[a.species],"Each mountain discovery must have a different species")
  mountainEncounters[a.behindPeak]=a;mountainSpecies[a.species]=true
  local peak=L.Peaks[a.behindPeak]
  local axis=Vector2.new(peak.x+550,peak.z-534)
  local offset=Vector2.new(a.position.X+550,a.position.Z-534)
  check(offset:Dot(axis.Unit)>axis.Magnitude+math.min(peak.rx,peak.rz)*0.7,"Animal must be beyond its assigned mountain from launch")
  hidden+=1;local occluded=false;local launch=Vector3.new(-550,370,534)
  for step=1,19 do local sight=launch:Lerp(a.position+Vector3.yAxis*35,step/20)
   if L.height(sight.X,sight.Z)>sight.Y+50 then occluded=true;break end
  end
  check(occluded,"Rear wildlife must be hidden by a mountain from launch")
 else visible+=1 end
 local cf=CFrame.Angles(0,a.heading,0);local center=a.position+Vector3.yAxis*a.passageY
 local direction=cf.RightVector
 for _,off in {Vector3.zero,cf.LookVector*3.6,-cf.LookVector*3.6,Vector3.yAxis*1.5,-Vector3.yAxis*1.5} do
  check(not workspace:Raycast(center-direction*70+off,direction*140,params),"Belly flight corridor blocked: "..a.species..a.id)
 end
end
check(hidden==7 and visible==2,"Seven unique mountain discoveries complement two field animals")
for index in L.Peaks do check(mountainEncounters[index]~=nil,"Every mountain needs one hidden animal") end
for _,summit in W.Summits do
 local ring
 for _,r in W.Rings do if r.id==summit.ringId then ring=r;break end end
 check(ring~=nil,"Every mountain needs a summit reward")
 check(ring.position.Y-summit.position.Y>=17 and ring.position.Y-summit.position.Y<32,"Summit ring must sit close to the tip")
 local cf=CFrame.lookAt(ring.position,ring.position+ring.normal)
 for _,off in {Vector3.zero,cf.RightVector*3.6,-cf.RightVector*3.6,Vector3.yAxis*1.5,-Vector3.yAxis*1.5} do
  check(not workspace:Raycast(ring.position-ring.normal*90+off,ring.normal*180,params),"Summit approach must clear the rock")
 end
end
local kinds=0;for _ in species do kinds+=1 end
check(kinds==7 and #W.Animals==9,"Seven mountain species plus two established field encounters")
check(#workspace.PaperFlightWorld.PaperAnimals:GetChildren()==9,"Remove duplicate animal models from the world")
for _,p in {Vector2.new(-580,500),Vector2.new(-520,570),Vector2.new(-550,534)} do
 check(math.abs(L.height(p.X,p.Y)-349)<0.1,"Compact launch plateau retains a flat standing area")
end
local previous
for _,r in W.Rings do
 if previous and previous.group==r.group and r.group:find("Meandering") then
  local gap=(r.position-previous.position).Magnitude
  check(gap>23 and gap<26,"Curved sky clusters must stay close together")
 end
 previous=r
end
-- Full circles clear scenery; ground arcs deliberately continue beneath terrain.
local animalParams=RaycastParams.new();animalParams.FilterType=Enum.RaycastFilterType.Include
animalParams.FilterDescendantsInstances={workspace.PaperFlightWorld.PaperAnimals}
-- Check the complete rim against animals, and its exposed section against scenery.
for _,ring in W.Rings do
 local frame=CFrame.lookAt(ring.position,ring.position+ring.normal)
 local rimRadius=ring.radius+require(package.Config).RingTubeThickness/2+0.1
 for i=0,11 do
  local angle=i*math.pi/6
  local offset=frame.RightVector*math.cos(angle)*rimRadius+frame.UpVector*math.sin(angle)*rimRadius
  local point=ring.position+offset
  local filter=ring.groundArc and point.Y<L.height(point.X,point.Z)+2 and animalParams or params
  check(not workspace:Raycast(point-ring.normal,ring.normal*2,filter),"Ring rim intersects scenery: "..ring.id)
 end
end
for _,animal in W.Animals do
 local found
 for _,ring in W.Rings do
  if ring.animalId==animal.id then found=ring;break end
 end
 check(found~=nil,"Every animal needs a ring reward")
 local side=CFrame.Angles(0,animal.heading,0).RightVector
 check(math.abs(found.normal:Dot(side))>0.999,"Animal rewards must face sideways")
 local crossing=found.passagePosition or found.position
 check(require(package.Flight).crossedRing(crossing-side*30,crossing+side*30,found.position,found.normal,found.radius-require(package.Config).RingMargin),"A side-on belly flight must earn the belly reward")
 local model=workspace.PaperFlightWorld.Rings:FindFirstChild("Ring"..found.id)
 check(#model:GetChildren()==48,"Animal reward keeps continuous round tubing")
 if animal.bodyDrop>0 then
  check(found.groundArc and found.radius==18 and found.position.Y<=animal.position.Y,"Short animals use a wide half-circle or smaller ground arc")
  local shape=workspace.PaperFlightWorld.PaperAnimals:FindFirstChild(animal.species..animal.id)
  local legs=0
  for _,part in shape:GetChildren() do if part.Name=="RoundLeg" then
   legs+=1
   check(part.Size.X<30,"Short-stanced leg should no longer be a tall pillar")
  end end
  check(legs==4,"Lowered quadrupeds retain four rounded legs")
  check(require(package.Flight).crossedRing(crossing-side*70,crossing+side*70,found.position,found.normal,found.radius-require(package.Config).RingMargin),"Exposed ground arc remains collectible")
 end
end
local forward,rear=0,0;local trails={}
for _,a in W.Animals do
 if a.forwardMeadow then forward+=1;check(a.position.Z<0 and a.position.Y<110,"Visible wildlife belongs in the forward field") end
 if a.rearMeadow then
  rear+=1
  check(a.species=="Turtle" and a.position.Z>require(package.Config).Launch.Z+1000 and a.position.Y<110,"The turtle belongs in the rear lowland field")
  for _,offset in {Vector2.new(45,0),Vector2.new(-45,0),Vector2.new(0,55),Vector2.new(0,-55)} do
   local height,_,mountain=L.height(a.position.X+offset.X,a.position.Z+offset.Y)
   check(not mountain and math.abs(height-a.position.Y)<2.5,"Rear turtle needs a flat footprint")
  end
 end
end
for _,r in W.Rings do if r.group:find("Meandering") then trails[r.group]=(trails[r.group] or 0)+1 end end
local trailCount=0
for _,count in trails do
 trailCount+=1
 check(count==10,"Each connected sky trail contains ten pickups")
end
check(forward==1 and rear==1,"Split the two field animals between front and back of launch")
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
  check(r.value>=60 and r.value<=120,"Summit discoveries award 60-120 gold by altitude")
  local light=model.SummitBeaconAnchor:FindFirstChild("SummitLight")
  check(light and light.Enabled and light.Brightness==2,"Summit reward casts a warm local glow")
  local glows,motes=0,0
  for _,v in model:GetDescendants() do
   if v.Name=="SummitGlow" then glows+=1;check(not v.CanCollide and not v.CanQuery,"Summit glow cannot obstruct collection") end
   if v:IsA("ParticleEmitter") then motes+=1 end
  end
  check(glows==48 and motes==8,"Summit rewards need continuous glow and sparse rim sparkles")
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
-- Scenery must keep a bounded instance count and small accents on rendered terrain.
local woodland=workspace.PaperFlightWorld.Woodlands
local treeKinds={};local trees=woodland:GetChildren()
check(#trees>550 and #trees<1000,"Add substantially more trees while bounding authored scenery")
for _,tree in trees do
 local kind=tree:GetAttribute("SceneryKind");treeKinds[kind]=(treeKinds[kind] or 0)+1
 check(tree:GetAttribute("ArtStyle")=="BrightFaceted","Every tree uses the coherent faceted style")
 check(tree:GetAttribute("MeshOptimized") and #tree:GetChildren()<=30,"Trees use compact solid crowns, not wedge shells")
end
check(treeKinds.CherryBlossom>0 and treeKinds.CherryBlossom<#trees/4,"Blossoms remain accents among green trees")
check(treeKinds.Broadleaf and treeKinds.Birch and treeKinds.Pine and treeKinds.Palm,"Keep varied tree silhouettes")
local terrainOnly=RaycastParams.new();terrainOnly.FilterType=Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances={workspace.Terrain}
local patches,stones=0,0
for _,accent in workspace.PaperFlightWorld.MeadowAccents:GetChildren() do
 if accent:GetAttribute("SceneryKind")=="Stone" then stones+=1
 else
  patches+=1
  for _,v in accent:GetChildren() do
   check(not v.CanCollide and not v.CanQuery,"Tiny flowers and grass must not obstruct flight")
   if v.Name=="FlowerCenter" then
    local hit=workspace:Raycast(v.Position+Vector3.yAxis*12,-Vector3.yAxis*24,terrainOnly)
    check(hit and v.Position.Y-hit.Position.Y>0.2 and v.Position.Y-hit.Position.Y<0.8,"Flowers follow visible terrain rather than the buried height field")
   end
  end
 end
end
check(patches>150 and patches<=360 and stones>70 and stones<=200,"Bound meadow coverage and keep stones sparse")
local secondary=0;local maxReward=0
for _,s in W.Summits do
 if s.secondary then secondary+=1 end
 maxReward=math.max(maxReward,W.Rings[s.ringId].value)
end
check(secondary==2 and maxReward==120,"Both double peaks gain a second tip; highest summit pays 120")
check(#W.MountainRoutes==3,"Ridge ascent, spiral climb and plateau loop are present")
for _,route in W.MountainRoutes do
 check(#route.ids>=25,"Mountain routes need consecutive pickups")
 for i,id in route.ids do
  local ring=W.Rings[id]
  check(ring.value==10 and ring.radius==12,"Mountain route pickups keep ordinary gold and size")
  check(F.crossedRing(ring.position-ring.normal*30,ring.position+ring.normal*30,ring.position,ring.normal,ring.radius-C.RingMargin),"Tilted mountain ring remains collectible")
  local nextId=route.ids[i+1] or (route.closed and route.ids[1])
  if nextId then
   local nextRing=W.Rings[nextId];local delta=nextRing.position-ring.position
   if not route.closed then check(delta.Y>=-0.01,"Climbing routes must not reverse downhill into gullies") end
   check(delta.Magnitude>20 and delta.Magnitude<29,"Mountain pickups stay evenly spaced")
   check(ring.normal:Dot(delta.Unit)>0.75,"Ring opening follows the route tangent")
   for step=0,4 do
    local point=ring.position:Lerp(nextRing.position,step/4)
    check(not workspace:Raycast(point-Vector3.yAxis*3,Vector3.yAxis*6,params),"Flight segment stays above terrain")
   end
  end
 end
end
local clusters={}
for _,tree in trees do
 local cluster=tree:GetAttribute("ForestCluster")
 if cluster then clusters[cluster]=clusters[cluster] or {};table.insert(clusters[cluster],tree:GetAttribute("BasePosition")) end
end
-- Check spacing from every other tree, including the original grove anchor.
for _,tree in trees do
 if not tree:GetAttribute("ForestCluster") then continue end
 local base=tree:GetAttribute("BasePosition")
 for _,other in trees do
  if other==tree then continue end
  local b=other:GetAttribute("BasePosition")
  check(Vector2.new(base.X-b.X,base.Z-b.Z).Magnitude>=64.9,"Grove trunks stay at least 65 studs from every other tree")
 end
end
local clusterCount=0
for _,positions in clusters do
 clusterCount+=1
 check(#positions==14,"Each open grove keeps fourteen trees")
 for _,position in positions do
  local neighbor=math.huge
  for _,other in positions do if other~=position then neighbor=math.min(neighbor,(position-other).Magnitude) end end
  check(neighbor>=64.9 and neighbor<140,"Grove trees have breathing room while remaining grouped")
 end
end
check(clusterCount==6,"Six loose groves complement scattered trees")
return string.format("%d geometry and discovery-layout checks passed",passed)

end,debug.traceback)
for _,object in stagedObjects do object.Parent=staged end
assert(success,result)
return result
