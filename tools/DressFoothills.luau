-- Give the four small tunnel hills grassy crowns without changing their collision shape.
local package=game.ReplicatedStorage.PaperFlight
local Landscape=require(package.Landscape)
local Scenery=require(package.Scenery)
local world=workspace.PaperFlightWorld
local terrain=workspace.Terrain
local V=Vector3.new
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={terrain}
local function ground(x,z)
 local height=Landscape.height(x,z)
 local hit=workspace:Raycast(V(x,height+24,z),V(0,-64,0),params)
 assert(hit,"Foothill crown must have terrain beneath its vegetation")
 return hit.Position.Y
end
-- Clear only this tool's previous decorations, including staged rear-side copies.
for _,parent in {world.Woodlands,world.MeadowAccents,game.ServerStorage:FindFirstChild("PaperDeferredWorld")} do
 if parent then for _,object in parent:GetChildren() do if object:GetAttribute("FoothillCrown") then object:Destroy() end end end
end
local painted,treeCount,patchCount=0,0,0
for index,spur in Landscape.Spurs do
 local bottom=Landscape.baseHeight(spur.x,spur.z)
 local region=Region3.new(V(spur.x-spur.rx,bottom-8,spur.z-spur.rz),V(spur.x+spur.rx,bottom+spur.h+24,spur.z+spur.rz)):ExpandToGrid(4)
 local materials,occupancy=terrain:ReadVoxels(region,4)
 local minimum=region.CFrame.Position-region.Size/2
 for ix=1,#materials do for iz=1,#materials[ix][1] do
  local x,z=minimum.X+(ix-0.5)*4,minimum.Z+(iz-0.5)*4
  local u,v=(x-spur.x)/spur.rx,(z-spur.z)/spur.rz
  local angle=math.atan2(v,u)
  -- Broad green crown with uneven fingers down the shoulders and a few rocky breaks.
  local edge=0.66+0.09*math.sin(angle*3+index)+0.06*math.noise(x/42,z/48)
  local radius=math.sqrt(u*u+v*v)
  local rockyBreak=radius>0.32 and math.noise(x/24+index*3,z/28)>0.38
  if radius<edge and not rockyBreak then
   local surface
   for iy=#materials[ix],1,-1 do if occupancy[ix][iy][iz]>0 then surface=iy;break end end
   if surface then
    for iy=surface,math.max(1,surface-2),-1 do
     if occupancy[ix][iy][iz]>0 and materials[ix][iy][iz]==Enum.Material.Rock then
      materials[ix][iy][iz]=Enum.Material.LeafyGrass;painted+=1
     end
    end
   end
  end
 end end
 -- Occupancies are passed through untouched: the tunnel and flight clearance stay intact.
 terrain:WriteVoxels(region,4,materials,occupancy)
 for i,spot in {{-0.25,0.09,29,"Broadleaf"},{0.26,-0.12,25,"Birch"},{0.07,0.35,23,"CherryBlossom"}} do
  local x,z=spur.x+spot[1]*spur.rx,spur.z+spot[2]*spur.rz
  local tree=Instance.new("Model");tree.Name="FoothillTree";tree.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  tree:SetAttribute("FoothillCrown",index);tree:SetAttribute("Elevation",ground(x,z))
  Scenery.tree(tree,V(x,ground(x,z),z),spot[3],spot[4],index*1.4+i)
  tree.Parent=world.Woodlands;treeCount+=1
 end
 for i,spot in {{-0.1,-0.26},{0.29,0.2},{-0.35,0.29}} do
  local x,z=spur.x+spot[1]*spur.rx,spur.z+spot[2]*spur.rz
  local patch=Instance.new("Model");patch.Name="FlowerPatch";patch.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  patch:SetAttribute("FoothillCrown",index)
  Scenery.patch(patch,V(x,ground(x,z),z),ground,150000+index*100+i)
  patch.Parent=world.MeadowAccents;patchCount+=1
 end
end
terrain:SetAttribute("PaperFoothillCrownsV1",true)
return string.format("Grassy foothill crowns: %d material cells painted, %d trees, %d flower/grass patches; terrain occupancy unchanged",painted,treeCount,patchCount)
