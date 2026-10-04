--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local package = RS:WaitForChild("PaperFlight")
local Config = require(package.Config)
local Flight = require(package.Flight)
local remote = package.RaceEvent
local template = package.Plane
local planes = Instance.new("Folder")
planes.Name = "ActivePaperPlanes"
planes.Parent = workspace
local sessions = {}
local cooldown = {}
local bests = {}
local function send(player, status, data)
 remote:FireClient(player, status, data)
end
local function restore(player)
 local character = player.Character
 if character then
  local root = character:FindFirstChild("HumanoidRootPart")
  local humanoid = character:FindFirstChildOfClass("Humanoid")
  if root then root.Anchored = false end
  if humanoid then humanoid.AutoRotate = true end
  for _, part in character:GetDescendants() do
   if part:IsA("BasePart") then
    local original = part:GetAttribute("PaperOriginalTransparency")
    if original ~= nil then part.Transparency = original; part:SetAttribute("PaperOriginalTransparency",nil) end
   end
  end
  character:PivotTo(CFrame.new(Config.Launch + Vector3.new(0,3,15)))
 end
end
local function stop(player, status, message)
 local session = sessions[player]
 if not session then return end
 sessions[player] = nil
 session.model:Destroy()
 restore(player)
 send(player,status,{message=message, time=session.elapsed, best=bests[player.UserId]})
end
local function launch(player)
 local now = os.clock()
 if now - (cooldown[player] or -10) < 1 then return end
 cooldown[player] = now
 if sessions[player] then stop(player,"Ready","Ready for another flight") end
 local character = player.Character
 local root = character and character:FindFirstChild("HumanoidRootPart")
 local humanoid = character and character:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health <= 0 then return end
 root.Anchored = true
 humanoid.AutoRotate = false
 for _, part in character:GetDescendants() do
  if part:IsA("BasePart") then part:SetAttribute("PaperOriginalTransparency",part.Transparency); part.Transparency=1 end
 end
 local model = template:Clone()
 model.Name = "Plane_"..player.UserId
 model.Parent = planes
 model:PivotTo(CFrame.new(Config.Launch))
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={workspace.PaperFlightWorld}
 sessions[player] = {raycast=params, model=model, state={position=Config.Launch,yaw=0,pitch=0}, input=Vector2.zero,
  next=1, elapsed=0, countdown=2, lastInput=now, lastPacket=0, notify=0}
 send(player,"Countdown",{seconds=2})
end
remote.OnServerEvent:Connect(function(player, action, x, y)
 if action == "Launch" then launch(player)
 elseif action == "Reset" then stop(player,"Ready","Flight reset")
 elseif action == "Input" then
  local s = sessions[player]
  if not s or typeof(x)~="number" or typeof(y)~="number" then return end
  if x~=x or y~=y or math.abs(x)>1 or math.abs(y)>1 then return end
  local now=os.clock()
  if now-s.lastPacket < 1/30 then return end
  s.lastPacket=now; s.lastInput=now; s.input=Vector2.new(x,y)
 end
end)
local function register(player)
 player.CharacterRemoving:Connect(function()
  local s=sessions[player]
  if s then sessions[player]=nil; s.model:Destroy(); send(player,"Ready",{message="Character reset"}) end
 end)
 player.CharacterAdded:Connect(function(character)
  character:WaitForChild("HumanoidRootPart")
  task.wait(0.1)
  if player.Character==character then restore(player) end
 end)
end
Players.PlayerAdded:Connect(register)
for _,p in Players:GetPlayers() do register(p) end
Players.PlayerRemoving:Connect(function(player)
 local s=sessions[player]
 if s then s.model:Destroy() end
 sessions[player]=nil; cooldown[player]=nil; bests[player.UserId]=nil
end)
local accumulator=0
local step=1/60
RunService.Heartbeat:Connect(function(dt)
 accumulator += math.min(dt,0.25)
 while accumulator >= step do
  accumulator-=step
  for player,s in sessions do
   if s.countdown>0 then
    s.countdown-=step
    if s.countdown<=0 then send(player,"Flying",{next=1}) end
    continue
   end
   s.elapsed+=step
   if os.clock()-s.lastInput>0.5 then s.input=Vector2.zero end
   local old=s.state.position
   s.state=Flight.step(s.state,s.input,step)
   local new=s.state.position
   local hit=workspace:Raycast(old,new-old,s.raycast)
   if hit or new.Y<5 or math.abs(new.X)>650 or new.Z < -1000 or s.elapsed>Config.MaxDuration then
    stop(player,"Crashed","Flight ended — launch to try again")
    continue
   end
   s.model:PivotTo(Flight.frame(s.state,-s.input.X*0.35))
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   if root then root.CFrame=CFrame.new(new+Vector3.new(0,-4,0)) end
   local target=Config.Course[s.next]
   if Flight.crossed(old,new,target) then
    s.next+=1
    if s.next>#Config.Course then
     local best=bests[player.UserId]
     bests[player.UserId]=best and math.min(best,s.elapsed) or s.elapsed
     stop(player,"Finished","Course complete!")
     continue
    end
    send(player,"Checkpoint",{next=s.next,time=s.elapsed})
   elseif old.Z>=target.Z and new.Z<target.Z then
    stop(player,"Missed","Missed checkpoint "..s.next.." — try again")
    continue
   end
   s.notify+=step
   if s.notify>=0.1 then s.notify=0; send(player,"Telemetry",{time=s.elapsed,next=s.next,speed=Config.Speed*(1-0.22*math.sin(s.state.pitch))}) end
  end
 end
end)
print("Paper Flight server ready: server-authoritative flight, six swept checkpoints.")

