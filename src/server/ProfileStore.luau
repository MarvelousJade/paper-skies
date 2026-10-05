-- Profiles are server-owned. Studio uses isolated in-memory progress.
local RunService=game:GetService("RunService")
local DataStoreService=game:GetService("DataStoreService")
local HttpService=game:GetService("HttpService")
local Economy=require(game.ReplicatedStorage.PaperFlight.Economy)
local Config=require(game.ReplicatedStorage.PaperFlight.Config)
local Store={}
local dataStore=not RunService:IsStudio() and DataStoreService:GetDataStore("PaperFlightProgress_v1") or nil
local owner=game.JobId..HttpService:GenerateGUID(false)
local records={}
local function integer(value,maximum)
 if typeof(value)~="number" or value~=value then return 0 end
 return math.floor(math.clamp(value,0,maximum))
end
local function sanitize(raw)
 local p=Economy.new()
 if typeof(raw)~="table" then return p end
 p.gold=integer(raw.gold,100000000)
 p.bestDistance=integer(raw.bestDistance,10000000)
 p.color=math.clamp(integer(raw.color,4),1,4)
 for key,definition in Config.Upgrades do
  p.levels[key]=integer(typeof(raw.levels)=="table" and raw.levels[key] or 0,definition.maxLevel)
 end
 for _,id in Config.PlaneOrder do
  if typeof(raw.ownedPlanes)=="table" and raw.ownedPlanes[id]==true then p.ownedPlanes[id]=true end
 end
 if typeof(raw.planeId)=="string" and p.ownedPlanes[raw.planeId] then p.planeId=raw.planeId end
 return p
end
Store.sanitize=sanitize -- Pure profile normalization is exposed for migration tests.
function Store.load(player)
 if not dataStore then
  records[player]={profile=Economy.new(),saving=false}
  return records[player].profile,"Studio session"
 end
 local ok,value=pcall(function()
  return dataStore:UpdateAsync(tostring(player.UserId),function(old)
   old=typeof(old)=="table" and old or {}
   if old.owner and old.owner~=owner and (old.lease or 0)>os.time() then return nil end
   return {profile=sanitize(old.profile),owner=owner,lease=os.time()+180,schema=2}
  end)
 end)
 if not ok or not value or value.owner~=owner then return nil,"Could not load progress. Please reconnect." end
 records[player]={profile=sanitize(value.profile),saving=false,lastSuccess=os.clock()}
 return records[player].profile,"Saved online"
end
function Store.save(player,release)
 local record=records[player]
 if not record then return true end
 -- A leaving player waits for any autosave, then writes the newest balance.
 local deadline=os.clock()+12
 while record.saving and os.clock()<deadline do task.wait(0.1) end
 if record.saving then return false end
 if not dataStore then if release then records[player]=nil end; return true end
 record.saving=true
 local success=false
 local snapshot=sanitize(record.profile)
 for attempt=1,3 do
  local ok,result=pcall(function()
   return dataStore:UpdateAsync(tostring(player.UserId),function(old)
    if typeof(old)~="table" or old.owner~=owner then return nil end
    return {profile=snapshot,owner=not release and owner or nil,
     lease=not release and os.time()+180 or 0,schema=2}
   end)
  end)
  if ok and result then success=true;break end
  task.wait(attempt)
 end
 record.saving=false
 if success then record.lastSuccess=os.clock() end
 if release then records[player]=nil end
 return success
end
function Store.expired(player)
 local record=records[player]
 return dataStore and record and os.clock()-(record.lastSuccess or 0)>120
end
return Store
