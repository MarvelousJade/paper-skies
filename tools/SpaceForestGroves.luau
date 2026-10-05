-- Preserve scattered trees and the six existing grove sites; spread grove crowns apart.
local world=workspace.PaperFlightWorld
local trees=world.Woodlands
local storage=game.ServerStorage:FindFirstChild("PaperDeferredWorld")
-- Work against the complete authored scenery, even after release preparation.
if storage then for _,object in storage:GetChildren() do object.Parent=world[object:GetAttribute("TargetGroup")] end end
local package=game.ReplicatedStorage.PaperFlight
local Landscape=require(package.Landscape);local World=require(package.WorldData)
local V=Vector3.new
local groups,occupied={},{}
for _,tree in trees:GetChildren() do
 local group=tree:GetAttribute("ForestCluster")
 if group then groups[group]=groups[group] or {};table.insert(groups[group],tree)
 else table.insert(occupied,tree:GetAttribute("BasePosition")) end
end
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={workspace.Terrain}
local replacements={}
for group=1,6 do
 local previous=assert(groups[group],"Missing existing forest grove")
 local center=trees:GetAttribute("ForestCenter"..group)
 if not center then
  center=Vector3.zero;for _,tree in previous do center+=tree:GetAttribute("BasePosition") end
  center/=#previous;trees:SetAttribute("ForestCenter"..group,center)
 end
 -- Two offset clearings keep ponds away from existing scattered trees and flowers.
 local pondOffset=({[1]=V(-20,0,100),[3]=V(-100,0,20)})[group]
 local pond=pondOffset and center+pondOffset
 if pond then trees:SetAttribute("ForestPond"..group,pond) end
 local random=Random.new(61403+group*173);local fresh={}
 for attempt=1,1200 do
  if #fresh==14 then break end
  local angle=random:NextNumber(0,math.pi*2);local radius=math.sqrt(random:NextNumber())*190
  local x,z=center.X+math.cos(angle)*radius,center.Z+math.sin(angle)*radius
  if pond and Vector2.new(x-pond.X,z-pond.Z).Magnitude<66 then continue end
  local y,rock=Landscape.height(x,z)
  if y<3 or y>980 or rock then continue end
  local hit=workspace:Raycast(V(x,y+24,z),V(0,-64,0),params)
  if not hit or hit.Normal.Y<0.68 then continue end
  local base=hit.Position;local allowed=true
  for _,other in occupied do if Vector2.new(x-other.X,z-other.Z).Magnitude<65 then allowed=false;break end end
  if not allowed then continue end
  for _,animal in World.Animals do if Vector2.new(x-animal.position.X,z-animal.position.Z).Magnitude<105 then allowed=false;break end end
  if not allowed then continue end
  for _,ring in World.Rings do
   local offset=base-ring.position;local along=offset:Dot(ring.normal)
   if math.abs(along)<110 and (offset-ring.normal*along).Magnitude<70 then allowed=false;break end
  end
  if not allowed then continue end
  local original=previous[#fresh%#previous+1]
  local clone=original:Clone();local oldBase=clone:GetAttribute("BasePosition")
  clone:PivotTo(CFrame.new(base-oldBase)*clone:GetPivot())
  clone:SetAttribute("BasePosition",base);clone:SetAttribute("Elevation",base.Y)
  clone:SetAttribute("ForestSpacing",65)
  table.insert(fresh,clone);table.insert(occupied,base)
 end
 assert(#fresh==14,"Could not place fourteen well-spaced trees in grove "..group)
 replacements[group]=fresh
end
for group,fresh in replacements do
 for _,tree in groups[group] do tree:Destroy() end
 for _,tree in fresh do tree.Parent=trees end
end
return "Six open groves: 14 trees each, 65-stud minimum trunk spacing, 190-stud planting radius"
