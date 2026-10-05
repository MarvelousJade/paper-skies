-- Server-authoritative gliding, gold pickup, and upgrades.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local package=RS:WaitForChild("PaperFlight")
local Config=require(package.Config)
local Flight=require(package.Flight)
local World=require(package.WorldData)
local Economy=require(package.Economy)
local Profiles=require(script.Parent.PaperFlightProfiles)
local remote=package.RaceEvent
local planes=Instance.new("Folder");planes.Name="ActivePaperPlanes";planes.Parent=workspace
local sessions,profiles,aiming,cooldowns,saveModes,budgets={},{},{},{},{},{}
local prefetches={}
local colors={Color3.fromRGB(255,249,228),Color3.fromRGB(125,212,255),Color3.fromRGB(255,183,153),Color3.fromRGB(189,229,160)}
-- Spatial bins keep collection checks local even as the map gains more gold.
local bins={}
local cellSize=128
local function key(x,y,z) return x..":"..y..":"..z end
for _,ring in World.Rings do
 local p=ring.position;local k=key(math.floor(p.X/cellSize),math.floor(p.Y/cellSize),math.floor(p.Z/cellSize))
 bins[k]=bins[k] or {};table.insert(bins[k],ring)
end
local function send(player,kind,data) if player.Parent then remote:FireClient(player,kind,data) end end
local function sync(player,message)
 local p=profiles[player]
 if p then send(player,"Profile",{gold=p.gold,levels=p.levels,color=p.color,best=p.bestDistance,saveMode=saveModes[player],message=message}) end
end
local function restore(player)
 aiming[player]=nil
 local c=player.Character
 if c then
  c:SetAttribute("PaperThrowPose",nil)
  local root=c:FindFirstChild("HumanoidRootPart");local h=c:FindFirstChildOfClass("Humanoid")
  if root then root.Anchored=false end
  if h then h.AutoRotate=true end
 end
end
local function stop(player,message)
 local s=sessions[player];sessions[player]=nil
 if s then
  if workspace.StreamingEnabled then player:RemoveReplicationFocus(s.model.PrimaryPart) end
  s.model:Destroy()
  local p=profiles[player]
  if p then
   local reward=s.gold+math.floor(s.distance/40)
   p.gold+=reward;p.bestDistance=math.max(p.bestDistance,math.floor(s.distance))
   send(player,"Ended",{message=message,gold=reward,distance=s.distance,rings=s.count})
   sync(player)
  end
 else send(player,"Ended",{message=message,gold=0,distance=0,rings=0}) end
 restore(player)
end
-- Kinematic projectiles have no useful assembly velocity for automatic look-ahead.
-- Preload ahead without blocking authoritative simulation or stacking requests.
local function prefetch(player,position)
 if not workspace.StreamingEnabled then return end
 local record=prefetches[player]
 if record and (record.pending or os.clock()-record.time<3) then return end
 record={pending=true,time=os.clock()};prefetches[player]=record
 task.spawn(function()
  if player.Parent then pcall(function() player:RequestStreamAroundAsync(position,3) end) end
  record.pending=false
 end)
end
local function prepare(player)
 if sessions[player] or aiming[player] or not profiles[player] then return end
 local c=player.Character
 local root=c and c:FindFirstChild("HumanoidRootPart");local h=c and c:FindFirstChildOfClass("Humanoid")
 if not root or not h or h.Health<=0 then return end
 c:PivotTo(CFrame.new(Config.ThrowStand));root.Anchored=true;h.AutoRotate=false
 c:SetAttribute("PaperThrowPose","Aiming");aiming[player]=true
 prefetch(player,Config.Launch+Vector3.new(0,-150,-750))
 send(player,"Aiming",{});sync(player)
end
local function finiteBound(value,bound)
 return typeof(value)=="number" and value==value and math.abs(value)<=bound
end
local function launch(player,yaw,pitch)
 if not finiteBound(yaw,Config.MaxAimYaw) or not finiteBound(pitch,math.pi/2) or pitch<Config.MinPitch or pitch>Config.MaxPitch then return end
 if sessions[player] or not aiming[player] or not profiles[player] then return end
 if os.clock()-(cooldowns[player] or -10)<0.8 then return end
 local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
 if not h or h.Health<=0 then return end
 cooldowns[player]=os.clock();aiming[player]=nil;c:SetAttribute("PaperThrowPose","Throwing")
 local model=package.Plane:Clone();model.Name="Plane_"..player.UserId;model:ScaleTo(0.65)
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 for _,part in model:GetDescendants() do
  if part:IsA("BasePart") then part.Color=colors[profiles[player].color] end
 end
 model.Parent=planes
 local stats=Flight.stats(profiles[player].levels)
 local state=Flight.new(Config.Launch,yaw,pitch,stats)
 model:PivotTo(Flight.frame(state))
 if workspace.StreamingEnabled then player:AddReplicationFocus(model.PrimaryPart) end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={workspace.PaperFlightWorld,workspace.Terrain}
 sessions[player]={model=model,state=state,stats=stats,params=params,input=Vector2.zero,boostHeld=false,
  elapsed=0,countdown=Config.ThrowDelay,lastInput=os.clock(),lastPacket=0,notify=0,
  gold=0,count=0,collected={},distance=0,ringPosition=Config.Launch}
 send(player,"Thrown",{seconds=Config.ThrowDelay,yaw=yaw,pitch=pitch})
end
local function collect(player,s,a,b)
 local radius=Config.CollectionRadius
 local lo=Vector3.new(math.min(a.X,b.X),math.min(a.Y,b.Y),math.min(a.Z,b.Z))-Vector3.one*radius
 local hi=Vector3.new(math.max(a.X,b.X),math.max(a.Y,b.Y),math.max(a.Z,b.Z))+Vector3.one*radius
 for x=math.floor(lo.X/cellSize),math.floor(hi.X/cellSize) do
  for y=math.floor(lo.Y/cellSize),math.floor(hi.Y/cellSize) do
   for z=math.floor(lo.Z/cellSize),math.floor(hi.Z/cellSize) do
    for _,ring in bins[key(x,y,z)] or {} do
     if not s.collected[ring.id] and Flight.crossedRing(a,b,ring.position,ring.normal,ring.radius-3) then
      s.collected[ring.id]=true;s.gold+=ring.value;s.count+=1
      send(player,"Ring",{id=ring.id,value=ring.value})
     end
    end
   end
  end
 end
end
remote.OnServerEvent:Connect(function(player,action,x,y,boost)
 -- A token bucket bounds all requests, including UI and malformed messages.
 local now=os.clock();local budget=budgets[player] or {tokens=60,time=now};budgets[player]=budget
 budget.tokens=math.min(60,budget.tokens+(now-budget.time)*35);budget.time=now
 if budget.tokens<1 then return end;budget.tokens-=1
 if action=="Sync" then sync(player)
 elseif action=="Aim" then prepare(player)
 elseif action=="Launch" then launch(player,x,y)
 elseif action=="Reset" then stop(player,"Run banked. Ready for another throw.")
 elseif action=="Upgrade" then
  if sessions[player] or not profiles[player] or typeof(x)~="string" then return end
  local _,message=Economy.buy(profiles[player],x);sync(player,message)
 elseif action=="Color" then
  if profiles[player] and not sessions[player] and finiteBound(x,4) and x%1==0 and x>=1 then profiles[player].color=x;sync(player) end
 elseif action=="Input" then
  local s=sessions[player]
  if not s or not finiteBound(x,1) or not finiteBound(y,1) or now-s.lastPacket<1/30 or (boost~=nil and typeof(boost)~="boolean") then return end
  s.lastPacket=now;s.lastInput=now;s.input=Vector2.new(x,y);s.boostHeld=boost==true
 end
end)
local function register(player)
 local profile,saveMode=Profiles.load(player)
 if not player.Parent then Profiles.save(player,true);return end
 if not profile then player:Kick(saveMode);return end
 profiles[player]=profile;saveModes[player]=saveMode
 local stats=Instance.new("Folder");stats.Name="leaderstats";stats.Parent=player
 local gold=Instance.new("IntValue");gold.Name="Gold";gold.Parent=stats
 local best=Instance.new("IntValue");best.Name="BestDistance";best.Parent=stats
 local function characterAdded(character)
  local root=character:WaitForChild("HumanoidRootPart")
  if player.Character==character then
   character:PivotTo(CFrame.new(Config.ThrowStand));restore(player)
   prefetch(player,Config.Launch+Vector3.new(0,-150,-750))
   character:WaitForChild("Humanoid").Died:Once(function() stop(player,"Ready for another throw.") end)
  end
 end
 player.CharacterAdded:Connect(characterAdded)
 player.CharacterRemoving:Connect(function() if sessions[player] or aiming[player] then stop(player,"Character reset.") end end)
 if player.Character then task.spawn(characterAdded,player.Character) end
 sync(player)
end
Players.PlayerAdded:Connect(register);for _,p in Players:GetPlayers() do task.spawn(register,p) end
Players.PlayerRemoving:Connect(function(player)
 if sessions[player] or aiming[player] then stop(player,"Run ended.") end
 Profiles.save(player,true)
 profiles[player]=nil;saveModes[player]=nil;budgets[player]=nil;cooldowns[player]=nil;prefetches[player]=nil
end)
task.spawn(function()
 while true do
  task.wait(60)
  for player in profiles do task.spawn(function()
   local ok=Profiles.save(player,false)
   if not ok and Profiles.expired(player) then
    stop(player,"Saving unavailable.");player:Kick("Progress could not be saved. Please reconnect.")
   end
  end) end
 end
end)
game:BindToClose(function()
 local remaining=0
 for player in profiles do
  remaining+=1;task.spawn(function()
   if sessions[player] then stop(player,"Run ended.") end
   Profiles.save(player,true);remaining-=1
  end)
 end
 local deadline=os.clock()+25
 while remaining>0 and os.clock()<deadline do task.wait(0.1) end
end)
local accumulator=0;local fixed=1/60
RunService.Heartbeat:Connect(function(dt)
 accumulator+=math.min(dt,0.25)
 while accumulator>=fixed do
  accumulator-=fixed
  for player,s in sessions do
   if s.countdown>0 then s.countdown-=fixed
    if s.countdown<=0 then send(player,"Flying",{}) end
    continue
   end
   s.elapsed+=fixed
   if os.clock()-s.lastInput>0.5 then s.input=Vector2.zero;s.boostHeld=false end
   local old=s.state.position
   local lift=World.lift(old)
   s.state=Flight.step(s.state,s.input,fixed,s.stats,lift,s.boostHeld)
   local pos=s.state.position
   local hit=workspace:Raycast(old,pos-old,s.params)
   local out=pos.X<Config.WorldMin.X or pos.X>Config.WorldMax.X or pos.Z<Config.WorldMin.Z or pos.Z>Config.WorldMax.Z
   if hit or pos.Y<0 or out or s.elapsed>Config.MaxDuration then
    stop(player,hit and "Landed! Gold collected." or "Run complete. Gold collected.");continue
   end
   s.distance+=(pos-old).Magnitude
   s.model:PivotTo(Flight.frame(s.state))
   s.notify+=fixed
   if s.notify>=0.1 then
    s.notify=0;collect(player,s,s.ringPosition,pos);s.ringPosition=pos
    prefetch(player,pos+Flight.frame(s.state).LookVector*650-Vector3.new(0,90,0))
    send(player,"Telemetry",{gold=s.gold+math.floor(s.distance/40),rings=s.count,distance=s.distance,
     speed=s.state.speed,stalled=s.state.stalled,lift=lift,boostRemaining=s.state.boostRemaining,boosting=s.state.boosting,region=World.region(pos),altitude=pos.Y,
     pitch=s.state.pitch,yaw=s.state.yaw,position=pos})
   end
  end
 end
 for player,p in profiles do
  local stats=player:FindFirstChild("leaderstats")
  if stats then stats.Gold.Value=p.gold;stats.BestDistance.Value=p.bestDistance end
 end
end)
print("Paper Flight exploration ready: gliding, stalls, gold, and upgrades.")
