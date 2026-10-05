-- Keep a skyline fallback until the detailed terrain is actually present.
local Visibility={}
function Visibility.fade(distance,covered)
 if not covered then return 0 end
 return 1-math.clamp((distance-1100)/550,0,1)
end
function Visibility.new(vista,terrain,world)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={terrain};params.IgnoreWater=true
 local tiles={}
 for _,tile in vista:GetChildren() do
  local center=tile:GetAttribute("Center")
  if center then
   local parts={};local samples={}
   for i=1,9 do local sample=tile:GetAttribute("Sample"..i);if sample then table.insert(samples,sample) end end
   local bakedCoverage=#samples>0
   if not bakedCoverage then table.insert(samples,center) end
   for _,p in tile:GetDescendants() do
    if p:IsA("BasePart") then
     table.insert(parts,p)
     if not bakedCoverage then table.insert(samples,p.Position) end
    end
   end
   table.insert(tiles,{center=center,parts=parts,samples=samples,fade=-1})
  end
 end
 local api={}
 function api:Update(eye)
  for _,tile in tiles do
   local distance=(tile.center-eye).Magnitude
   local covered=false
   if distance<1650 then
    covered=true
    for _,sample in tile.samples do
     local hit=world:Raycast(sample+Vector3.yAxis*3000,-Vector3.yAxis*6000,params)
     if not hit or hit.Position.Y<sample.Y-12 then covered=false;break end
    end
   end
   local fade=Visibility.fade(distance,covered)
   if fade~=tile.fade then
    tile.fade=fade
    for _,p in tile.parts do p.LocalTransparencyModifier=fade end
   end
  end
 end
 return api
end
return Visibility
