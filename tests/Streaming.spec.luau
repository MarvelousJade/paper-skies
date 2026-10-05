-- Run in Edit after OptimizeWorld. These are deterministic regressions, not network timings.
local RF=game.ReplicatedFirst;local SS=game.ServerStorage;local world=workspace.PaperFlightWorld
local passed=0
local function check(v,message) assert(v,message);passed+=1 end
local V=require(RF.PaperSurfaceVisibility)
local D=require(game.ServerScriptService.PaperDeferredScenery)
local Details=require(game.ReplicatedStorage.PaperFlight.MeadowDetails)
local Scenery=require(game.ReplicatedStorage.PaperFlight.Scenery)
local early=RF.PaperEarlyWorld
check(#early.DistantLandscape:GetChildren()==126,"All mountain silhouette tiles are ready in ReplicatedFirst")
check(#early.SummitMarkers:GetChildren()==9,"All nine summit goals are included in early content")
check(#early:GetDescendants()<800,"Bound early download size")
check(not SS.PaperFlightBackups.Archivable,"Development snapshots cannot ship in the release")
check(SS.PaperDeferredWorld.Archivable,"Deferred playable content must be saved")
local vista=Instance.new("Folder");local tile=Instance.new("Model");tile.Parent=vista
tile:SetAttribute("Center",Vector3.new(0,100,0))
local part=Instance.new("Part");part.Position=Vector3.new(10,100,0);part.Parent=tile
local present=false;local partial=false
local fake={Raycast=function(_,origin)
 if not present or (partial and origin.X>0) then return nil end
 return {Position=Vector3.new(origin.X,105,origin.Z)}
end}
local visible=V.new(vista,workspace.Terrain,fake)
visible:Update(Vector3.new(0,110,0));check(part.LocalTransparencyModifier==0,"Missing terrain must never hide the near skyline")
present=true;partial=true;visible:Update(Vector3.new(0,110,0))
check(part.LocalTransparencyModifier==0,"Partially loaded terrain cannot hide a whole tile")
partial=false;visible:Update(Vector3.new(0,110,0))
check(part.LocalTransparencyModifier==1,"Complete nearby terrain replaces the proxy")
present=false;visible:Update(Vector3.new(0,110,0))
check(part.LocalTransparencyModifier==0,"Terrain eviction restores the fallback")
visible:Update(Vector3.new(4000,110,0));check(part.LocalTransparencyModifier==0,"Distant skyline remains visible")
vista:Destroy()
local storage=SS.PaperDeferredWorld
local manager=D.new(world,storage)
local total=#manager.Entries
check(total>250,"Rear scenery is staged outside Workspace")
local animalCount=0
for _,entry in manager.Entries do
 if entry.object:GetAttribute("TargetGroup")=="PaperAnimals" then animalCount+=1 end
 check(entry.object:GetAttribute("TargetGroup")~="Rings" or not entry.object:FindFirstChild("SummitBeacon"),"Summit goals must never be deferred")
end
check(animalCount==7,"One rear animal per mountain waits for approach")
local active=manager:Update({},0.1);check(active==0,"No observers means no initial rear scenery")
local positions={}
for _,entry in manager.Entries do table.insert(positions,entry.position) end
local ok,result=xpcall(function()
 for i=1,100 do
  local _,spent=manager:Update(positions,0.1)
  check(spent<=D.PartBudget,"Arrival batches obey the server part budget")
 end
 check(storage:GetAttribute("ActiveModels")==total,"All regions can activate for multiple simultaneous observers")
 local second=positions[#positions]
 for _=1,110 do manager:Update({second},0.1) end
 for _,entry in manager.Entries do
  if (entry.position-second).Magnitude<D.RevealRadius then check(entry.object.Parent==entry.target,"One observer leaving cannot unload another observer's nearby scenery") end
 end
 for _=1,100 do manager:Update(positions,0.1) end
 local first
 local patches=0
 for _,marker in world.MeadowAccents:GetChildren() do
  if marker:GetAttribute("SceneryKind")~="MeadowPatch" then continue end
  patches+=1;first=first or marker
  check(#marker:GetChildren()==1 and marker:FindFirstChild("DetailAnchor")~=nil,"Meadow patches replicate one non-colliding anchor")
  local heights=game.HttpService:JSONDecode(marker:GetAttribute("PatchHeights"))
  check(#heights==18,"Baked patch must contain every surface height")
  local index=0;local model=Instance.new("Model")
  Scenery.patch(model,marker:GetAttribute("BasePosition"),function() index+=1;return heights[index] end,marker:GetAttribute("PatchSeed"))
  check(#model:GetChildren()==81,"Local reconstruction preserves full flower and grass detail")
  for _,p in model:GetChildren() do check(not p.CanCollide and not p.CanQuery,"Local decoration cannot change flight collisions") end
  model:Destroy()
 end
 check(patches==332,"All authored meadow patches are retained")
 local details=Details.new(workspace,world)
 local success,err=xpcall(function()
  local eye=first:GetAttribute("BasePosition")+Vector3.yAxis*6
  details:Update(eye)
  check(details.Folder:GetAttribute("ActivePatches")<=2,"First frame builds only a small batch")
  for _=1,30 do details:Update(eye) end
  check(details.Folder:GetAttribute("ActivePatches")>0,"Flowers appear when approaching the actual ground")
  check(#details.Folder:GetDescendants()<=Details.MaxPatches*82,"Client detail memory remains bounded")
  details:Update(Vector3.new(20000,5000,20000))
  check(#details.Folder:GetChildren()==0,"Distant flower geometry is released")
  for _=1,30 do details:Update(eye) end
  check(details.Folder:GetAttribute("ActivePatches")>0,"Flowers return on revisiting")
 end,debug.traceback)
 details:Destroy();check(not details.Folder.Parent,"Client detail cleanup releases its folder")
 assert(success,err)
 for _=1,110 do manager:Update({},0.1) end
 check(#storage:GetChildren()==total,"Unobserved scenery returns to storage after the delay")
 return string.format("%d startup, deferred scenery, multiplayer proximity, and detail checks passed",passed)
end,debug.traceback)
-- Restore the authored staging state even after a failure.
for _,entry in manager.Entries do entry.object.Parent=storage end
storage:SetAttribute("ActiveModels",0)
assert(ok,result)
return result
