-- Two small, fixed-seed discoveries among six groves; leave the other four dry.
local world=workspace.PaperFlightWorld
local terrain=workspace.Terrain
local V=Vector3.new
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={terrain};params.IgnoreWater=true
local count=0
for _,group in {1,3} do
 local center=assert(world.Woodlands:GetAttribute("ForestPond"..group),"Run grove spacing before pond dressing")
 local key="PaperForestPondV1_"..group
 if terrain:GetAttribute(key) then count+=1;continue end
 local waterY=math.huge
 for i=0,11 do
  local angle=i*math.pi/6
  local hit=workspace:Raycast(V(center.X+math.cos(angle)*48,center.Y+40,center.Z+math.sin(angle)*40),V(0,-100,0),params)
  assert(hit,"Pond shoreline must lie on existing terrain")
  waterY=math.min(waterY,hit.Position.Y-1)
 end
 local region=Region3.new(V(center.X-52,waterY-16,center.Z-44),V(center.X+52,waterY+20,center.Z+44)):ExpandToGrid(4)
 local materials,occupancy=terrain:ReadVoxels(region,4)
 local minimum=region.CFrame.Position-region.Size/2
 -- Only this small basin is changed. Keep a session-only undo snapshot.
 local backup=game.ServerStorage:FindFirstChild("PaperFlightBackups")
 if backup then
  local first=minimum/4;local last=(minimum+region.Size)/4-Vector3.one
  local saved=terrain:CopyRegion(Region3int16.new(Vector3int16.new(first.X,first.Y,first.Z),Vector3int16.new(last.X,last.Y,last.Z)))
  saved.Name=key;saved.Parent=backup
 end
 for ix=1,#materials do for iz=1,#materials[ix][1] do
  local x,z=minimum.X+(ix-.5)*4,minimum.Z+(iz-.5)*4
  local u,v=(x-center.X)/48,(z-center.Z)/40
  local angle=math.atan2(v,u)
  local radius=math.sqrt(u*u+v*v)/(1+.035*math.sin(angle*3+group))
  if radius>=1 then continue end
  local surface
  for iy=#materials[ix],1,-1 do
   if occupancy[ix][iy][iz]>0 then surface=minimum.Y+(iy-1+occupancy[ix][iy][iz])*4;break end
  end
  assert(surface,"Pond basin must have a solid floor")
  local blend=math.clamp((radius-.55)/.45,0,1)
  blend=blend*blend*(3-2*blend)
  local floorY=(waterY-6)*(1-blend)+surface*blend
  for iy=1,#materials[ix] do
   local bottom=minimum.Y+(iy-1)*4
   if bottom>=floorY then
    local water=math.clamp((waterY-bottom)/4,0,1)
    materials[ix][iy][iz]=water>0 and Enum.Material.Water or Enum.Material.Air
    occupancy[ix][iy][iz]=water
   elseif bottom+4>floorY then
    materials[ix][iy][iz]=radius<.7 and Enum.Material.Ground or Enum.Material.LeafyGrass
    occupancy[ix][iy][iz]=math.clamp((floorY-bottom)/4,0,1)
   end
  end
 end end
 -- Clear existing solid channels before writing water into the basin.
 terrain:FillRegion(region,4,Enum.Material.Air)
 terrain:WriteVoxels(region,4,materials,occupancy)
 terrain:SetAttribute(key,true);count+=1
end
return string.format("%d shallow forest ponds, four dry groves; terrain water and grassy banks",count)
