-- Decorative patches are transmitted as a seed and baked surface heights.
-- Nearby detail is reconstructed in small batches, with a hard per-client budget.
local Scenery=require(script.Parent.Scenery)
local HttpService=game:GetService("HttpService")
local Details={Radius=220,ReleaseRadius=250,MaxPatches=24,BuildsPerUpdate=2}
function Details.new(parent,world)
 local folder=Instance.new("Folder");folder.Name="LocalMeadowDetails";folder.Parent=parent
 local markers,active={},{}
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={workspace.Terrain};params.IgnoreWater=true
 local function add(v)
  if v:IsA("Model") and v.Name=="FlowerPatch" and v:GetAttribute("PatchSeed") then markers[v]=true end
 end
 local function release(marker)
  if active[marker] then active[marker]:Destroy();active[marker]=nil end
 end
 local added=world.DescendantAdded:Connect(add)
 local removed=world.DescendantRemoving:Connect(function(v) markers[v]=nil;release(v) end)
 for _,v in world:GetDescendants() do add(v) end
 local api={Folder=folder}
 function api:Update(eye)
  local count=0
  for marker,model in active do
   local base=marker:GetAttribute("BasePosition")
   local distance=(base-eye).Magnitude
   if not marker:IsDescendantOf(world) or distance>Details.ReleaseRadius then release(marker)
   else
    count+=1;local fade=math.clamp((distance-175)/(Details.Radius-175),0,1)
    for _,p in model:GetChildren() do if p:IsA("BasePart") then p.LocalTransparencyModifier=fade end end
   end
  end
  local candidates={}
  for marker in markers do
   local base=marker:GetAttribute("BasePosition")
   if base and not active[marker] then
    local distance=(base-eye).Magnitude
    if distance<Details.Radius then table.insert(candidates,{marker=marker,distance=distance,base=base}) end
   end
  end
  table.sort(candidates,function(a,b) return a.distance<b.distance end)
  local built=0
  for _,candidate in candidates do
   if count>=Details.MaxPatches or built>=Details.BuildsPerUpdate then break end
   local base,marker=candidate.base,candidate.marker
   local hit=workspace:Raycast(base+Vector3.yAxis*16,-Vector3.yAxis*32,params)
   if not hit then continue end -- Retry naturally when the ground streams in.
   local heights=HttpService:JSONDecode(marker:GetAttribute("PatchHeights"))
   local index=0;local model=Instance.new("Model");model.Name="FlowerDetail"
   Scenery.patch(model,base,function()
    index+=1;return heights[index]
   end,marker:GetAttribute("PatchSeed"))
   local fade=math.clamp((candidate.distance-175)/(Details.Radius-175),0,1)
   for _,p in model:GetChildren() do if p:IsA("BasePart") then p.LocalTransparencyModifier=fade end end
   model.Parent=folder;active[marker]=model;count+=1;built+=1
  end
  folder:SetAttribute("ActivePatches",count)
 end
 function api:Destroy()
  added:Disconnect();removed:Disconnect();folder:Destroy();table.clear(active);table.clear(markers)
 end
 return api
end
return Details
