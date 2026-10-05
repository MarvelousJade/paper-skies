-- Edit-time, repeatable release preparation; gameplay geometry is preserved.
local RF=game:GetService("ReplicatedFirst")
local SS=game:GetService("ServerStorage")
local world=assert(workspace:FindFirstChild("PaperFlightWorld"),"Build the exploration world first")
local deferred=SS:FindFirstChild("PaperDeferredWorld") or Instance.new("Folder")
deferred.Name="PaperDeferredWorld";deferred.Parent=SS
for _,object in deferred:GetChildren() do
 object.Parent=assert(world:FindFirstChild(object:GetAttribute("TargetGroup")))
end
-- Validate migration inputs before removing any decorative geometry.
for _,patch in world.MeadowAccents:GetChildren() do
 if patch:GetAttribute("SceneryKind")=="MeadowPatch" then
  assert(patch:GetAttribute("PatchSeed") and patch:GetAttribute("PatchHeights"),"Rebuild meadow accents with baked patch data first")
 end
end
local excluded=0
local backups=SS:FindFirstChild("PaperFlightBackups")
if backups then
 excluded=#backups:GetDescendants()+1
 backups.Archivable=false
 backups:SetAttribute("ReleaseNote","Session-only development backups; omitted from saves/publishes. Previous published versions and Git preserve prior work.")
end
local early=RF:FindFirstChild("PaperEarlyWorld") or Instance.new("Folder")
early.Name="PaperEarlyWorld";early.Parent=RF
local vista=world:FindFirstChild("DistantLandscape")
if vista then
 local prior=early:FindFirstChild("DistantLandscape");if prior then prior:Destroy() end
 vista.ModelStreamingMode=Enum.ModelStreamingMode.Default;vista.Parent=early
end
assert(early:FindFirstChild("DistantLandscape"),"Missing early mountain silhouettes")
local markers=early:FindFirstChild("SummitMarkers") or Instance.new("Folder")
markers.Name="SummitMarkers";markers.Parent=early;markers:ClearAllChildren()
for _,ring in world.Rings:GetChildren() do
 local anchor=ring:FindFirstChild("SummitBeaconAnchor")
 local beacon=ring:FindFirstChild("SummitBeacon")
 if anchor and beacon then
  local marker=Instance.new("Model");marker.Name=ring.Name
  local copy=anchor:Clone();copy:ClearAllChildren();copy.Parent=marker
  local halo=beacon:Clone();halo.Adornee=copy;halo.Parent=marker;marker.Parent=markers
 end
end
local removed,patches=0,0
for _,patch in world.MeadowAccents:GetChildren() do
 if patch:GetAttribute("SceneryKind")=="MeadowPatch" then
  patches+=1
  for _,p in patch:GetChildren() do if p:IsA("BasePart") and p.Name~="DetailAnchor" then p:Destroy();removed+=1 end end
  local anchor=patch:FindFirstChild("DetailAnchor") or Instance.new("Part")
  anchor.Name="DetailAnchor";anchor.Size=Vector3.new(20,3,20)
  anchor.Position=patch:GetAttribute("BasePosition");anchor.Transparency=1;anchor.Anchored=true
  anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CastShadow=false;anchor.Parent=patch
  patch.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 end
end
-- Stage only the far, lower side of each peak. Summit routes/rewards stay available.
local package=game.ReplicatedStorage.PaperFlight
local Landscape=require(package.Landscape);local Config=require(package.Config);local World=require(package.WorldData)
local function behindMountain(position)
 for i,peak in Landscape.Peaks do
  local away=Vector2.new(peak.x-Config.ThrowStand.X,peak.z-Config.ThrowStand.Z).Unit
  local offset=Vector2.new(position.X-peak.x,position.Z-peak.z)
  local along=offset:Dot(away);local side=math.abs(offset.X*away.Y-offset.Y*away.X)
  if along>math.min(peak.rx,peak.rz)*0.18 and along<math.max(peak.rx,peak.rz)*2.5
   and side<math.max(peak.rx,peak.rz)*1.25 and position.Y<peak.h*0.72 then return i end
 end
end
local deferredParts=0
for _,groupName in {"Woodlands","MeadowAccents","PaperAnimals","Rings"} do
 for _,object in world[groupName]:GetChildren() do
  local position=object:GetAttribute("BasePosition");local peak
  if groupName=="PaperAnimals" then
   local animal=World.Animals[object:GetAttribute("AnimalId")]
   position=animal.position;peak=animal.behindPeak
  elseif groupName=="Rings" then
   local ring=World.Rings[object:GetAttribute("RingId")]
   local animal=ring and ring.animalId and World.Animals[ring.animalId]
   if animal then position=ring.position;peak=animal.behindPeak end
  elseif position then peak=behindMountain(position) end
  if peak then
   object:SetAttribute("TargetGroup",groupName);object:SetAttribute("StreamingPosition",position)
   object:SetAttribute("DeferredPeak",peak);object.Parent=deferred
   for _,p in object:GetDescendants() do if p:IsA("BasePart") then deferredParts+=1 end end
  end
 end
end
return string.format("Release prep: %d backup instances excluded; %d meadow patches compacted; %d decorative parts removed; early skyline %d instances; %d rear models (%d parts) deferred",excluded,patches,removed,#early:GetDescendants(),#deferred:GetChildren(),deferredParts)
