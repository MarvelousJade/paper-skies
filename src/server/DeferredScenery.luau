-- Server-owned scenery is staged behind mountains until a player approaches.
-- Original models move between storage and Workspace; collision stays authoritative.
local Deferred={RevealRadius=1400,ReleaseRadius=1800,HideDelay=10,PartBudget=900}
function Deferred.new(world,storage)
 local entries={}
 for _,object in storage:GetChildren() do
  table.insert(entries,{object=object,position=object:GetAttribute("StreamingPosition"),
   target=world:WaitForChild(object:GetAttribute("TargetGroup")),cost=math.max(1,#object:GetDescendants()),absent=0})
 end
 local api={Entries=entries}
 function api:Update(positions,dt)
  local queue={};local active=0
  for _,entry in entries do
   local distance=math.huge
   for _,position in positions do distance=math.min(distance,(entry.position-position).Magnitude) end
   if entry.object.Parent==storage then
    if distance<Deferred.RevealRadius then table.insert(queue,{entry=entry,distance=distance}) end
   else
    if distance>Deferred.ReleaseRadius then entry.absent+=dt else entry.absent=0 end
    if entry.absent>=Deferred.HideDelay then entry.object.Parent=storage;entry.absent=0
    else active+=1 end
   end
  end
  table.sort(queue,function(a,b) return a.distance<b.distance end)
  local spent=0
  for _,item in queue do
   local entry=item.entry
   if spent>0 and spent+entry.cost>Deferred.PartBudget then break end
   entry.object.Parent=entry.target;entry.absent=0;spent+=entry.cost;active+=1
  end
  storage:SetAttribute("ActiveModels",active)
  return active,spent
 end
 return api
end
return Deferred
