-- Migrate existing trees without changing sites, heights, headings, or species.
local world=workspace.PaperFlightWorld
local Scenery=require(game.ReplicatedStorage.PaperFlight.Scenery)
local count=0;local replacements={}
local checkFolder=workspace:FindFirstChild("SceneryConversionCheck")
if checkFolder then checkFolder:Destroy() end
checkFolder=Instance.new("Folder");checkFolder.Name="SceneryConversionCheck";checkFolder.Parent=workspace
for _,parent in {world.Woodlands,game.ServerStorage.PaperDeferredWorld} do
 for _,old in parent:GetChildren() do
  local kind=old:GetAttribute("SceneryKind")
  if not ({Broadleaf=true,CherryBlossom=true,Birch=true,Pine=true,Palm=true})[kind] then continue end
  if old:GetAttribute("MeshOptimized") then continue end
  local origin=old:GetAttribute("BasePosition");local branch
  for _,p in old:GetChildren() do if p.Name=="Branch" and (not branch or p.Size.X>branch.Size.X) then branch=p end end
  assert(branch,"Tree needs a trunk")
  local h=branch.Size.X/(({Palm=.075,Pine=.07,Birch=.055})[kind] or .13)
  local heading
  if kind=="Pine" then
   local facet=assert(old:FindFirstChild("PineFacet"));local d=facet.CFrame.RightVector
   heading=math.atan2(d.Z,d.X)-math.pi/6
  else
   local direction=branch.CFrame.LookVector
   -- First branch points along local +X on birch/palm, and -X on broadleaf/cherry.
   heading=math.atan2(direction.X,direction.Z)-((kind=="Palm" or kind=="Birch") and math.pi/2 or -math.pi/2)
  end
  local fresh=Instance.new("Model");fresh.Name=old.Name;fresh.ModelStreamingMode=old.ModelStreamingMode
  for key,value in old:GetAttributes() do fresh:SetAttribute(key,value) end
  Scenery.tree(fresh,origin,h,kind,heading)
  fresh.Parent=checkFolder
  -- Validate structural dimensions independently of the old overlapping wedge shells.
  -- Convex crown collision deliberately fills the shell; flight-route tests cover clearance.
  local available={}
  for _,p in fresh:GetChildren() do if p.Name=="Branch" then table.insert(available,p) end end
  for _,p in old:GetChildren() do if p.Name=="Branch" then
   local found
   for index,q in available do
    if (p.Position-q.Position).Magnitude<.05 and (p.Size-q.Size).Magnitude<.05 then found=index;break end
   end
   assert(found,"Tree migration changed an original trunk or branch: "..kind)
   table.remove(available,found)
  end end
  assert(#available==0,"Tree migration added unexpected branches")
  table.insert(replacements,{old=old,fresh=fresh,parent=parent})
 end
end
-- Validate every replacement before touching the authored trees.
local backup=Instance.new("Folder");backup.Name="BeforeMeshTreeMigration";backup.Archivable=false;backup.Parent=game.ServerStorage
for _,item in replacements do
 item.old.Parent=backup;item.fresh.Parent=item.parent;count+=1
end
checkFolder:Destroy()
return string.format("%d trees converted with original species, dimensions and sites",count)
