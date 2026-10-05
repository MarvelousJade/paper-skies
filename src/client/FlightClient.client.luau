-- Mouse-led camera, paper-plane presentation, and exploration HUD.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local SoundService=game:GetService("SoundService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("PaperFlight")
local Config=require(package.Config)
local Flight=require(package.Flight)
local FlightCamera=require(package.FlightCamera)
local cameraMotion=FlightCamera.new()
local World=require(package.WorldData)
local Economy=require(package.Economy)
local remote=package:WaitForChild("RaceEvent")
local camera=workspace.CurrentCamera
local gui=Instance.new("ScreenGui");gui.Name="PaperFlightHUD";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true
gui.Parent=player:WaitForChild("PlayerGui")
local boostHeld=false
local mode="Ready";local yaw=0;local pitch=Config.AimPitch;local cursorFree=false
local profile=Economy.new();local saveMode="Loading progress";local soundEnabled=true
local telemetry={speed=165,boostRemaining=Config.BoostDuration,boosting=false,stalled=false,lift=0,distance=0,gold=0,rings=0,region="Coastal Cliffs",altitude=362}
local originalFov=camera.FieldOfView
local visualPlane,heldPlane,trajectory,smoothedFrame=nil,nil,nil,nil
local dots,hiddenRings,lines={},{},{}
local collectedIds={}
local stick=Vector2.zero;local inputClock=0
local previewClock=0
local function round(object,radius)
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,radius or 7);c.Parent=object
end
local function label(parent,name,text,size,pos,textSize)
 local v=Instance.new("TextLabel");v.Name=name;v.Text=text;v.Size=size;v.Position=pos
 v.BackgroundTransparency=1;v.TextColor3=Color3.new(1,1,1);v.TextStrokeColor3=Color3.fromRGB(45,46,51)
 v.TextStrokeTransparency=0.3;v.Font=Enum.Font.GothamBold;v.TextSize=textSize or 22;v.Parent=parent
 return v
end
local function button(parent,name,text,size,pos,color)
 local v=Instance.new("TextButton");v.Name=name;v.Text=text;v.Size=size;v.Position=pos
 v.BackgroundColor3=color or Color3.fromRGB(46,49,57);v.TextColor3=Color3.new(1,1,1)
 v.TextStrokeTransparency=0.5;v.Font=Enum.Font.GothamBold;v.TextSize=22;v.AutoButtonColor=true;v.Parent=parent
 round(v)
 local stroke=Instance.new("UIStroke");stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 stroke.Color=Color3.fromRGB(29,31,35);stroke.Thickness=2;stroke.Transparency=0.3;stroke.Parent=v
 return v
end
local action=button(gui,"Launch","Launch! [F]",UDim2.fromOffset(440,80),UDim2.new(0.5,-220,1,-100),Color3.fromRGB(60,208,64))
action.TextSize=42
local gradient=Instance.new("UIGradient");gradient.Rotation=90;gradient.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(170,170,170));gradient.Parent=action
local wallet=button(gui,"Wallet","$0",UDim2.fromOffset(240,48),UDim2.new(0,24,1,-72))
wallet.TextColor3=Color3.fromRGB(76,226,90);wallet.TextSize=32;wallet.TextXAlignment=Enum.TextXAlignment.Left
local padding=Instance.new("UIPadding");padding.PaddingLeft=UDim.new(0,14);padding.Parent=wallet
local plus=label(wallet,"Plus","+",UDim2.fromOffset(36,42),UDim2.new(1,-45,0,2),32)
plus.TextColor3=Color3.fromRGB(255,204,86)
local earned=label(gui,"RunGold","$0",UDim2.fromOffset(500,70),UDim2.new(0.5,-250,0,52),54)
earned.TextColor3=Color3.fromRGB(82,229,91);earned.Visible=false
local distance=label(gui,"RunDistance","",UDim2.fromOffset(540,40),UDim2.new(0.5,-270,0,118),24)
local region=label(gui,"Region","COASTAL CLIFFS",UDim2.fromOffset(550,28),UDim2.new(0.5,-275,0,22),16)
region.TextTransparency=0.15
local speed=label(gui,"Speed","165 SPS",UDim2.fromOffset(280,66),UDim2.new(1,-300,1,-182),52)
speed.TextXAlignment=Enum.TextXAlignment.Right;speed.Visible=false
local condition=label(gui,"AirState","GLIDING",UDim2.fromOffset(350,32),UDim2.new(1,-370,1,-112),24)
condition.TextXAlignment=Enum.TextXAlignment.Right;condition.Visible=false
local bar=Instance.new("Frame");bar.Name="BoostBar";bar.BackgroundColor3=Color3.fromRGB(43,52,65)
bar.Position=UDim2.new(1,-300,1,-66);bar.Size=UDim2.fromOffset(280,10);bar.Parent=gui;round(bar,6);bar.Visible=false
local fill=Instance.new("Frame");fill.BackgroundColor3=Color3.fromRGB(91,166,251);fill.BorderSizePixel=0;fill.Size=UDim2.fromScale(1,1);fill.Parent=bar;round(fill,6)
local boostLabel=label(gui,"BoostRemaining","BOOST 4.5s",UDim2.fromOffset(280,22),UDim2.new(1,-300,1,-46),15)
boostLabel.TextXAlignment=Enum.TextXAlignment.Right;boostLabel.Visible=false
local boostButton=button(gui,"TouchBoost","HOLD BOOST",UDim2.fromOffset(160,50),UDim2.new(1,-185,1,-240),Color3.fromRGB(65,126,209))
boostButton.Visible=false;boostButton.TextSize=18
boostButton.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then boostHeld=true end
end)
local hint=label(gui,"Controls","Mouse - Aim / steer\nF - Launch / throw",UDim2.fromOffset(330,68),UDim2.new(0,24,1,-158),18)
hint.TextXAlignment=Enum.TextXAlignment.Left;hint.TextYAlignment=Enum.TextYAlignment.Bottom
local message=label(gui,"Message","Collect gold. Unlock new planes. Explore higher.",UDim2.new(0.8,0,0,36),UDim2.new(0.1,0,0,165),20)
local reticle=label(gui,"AimReticle","+",UDim2.fromOffset(32,32),UDim2.new(0.5,-16,0.5,-16),32);reticle.Visible=false
local nav=Instance.new("Frame");nav.Name="Menu";nav.BackgroundTransparency=1;nav.Size=UDim2.fromOffset(100,270);nav.Position=UDim2.new(0,24,0.5,-95);nav.Parent=gui
local upgrades=button(nav,"Upgrades","UP\nPlanes",UDim2.fromOffset(86,82),UDim2.fromOffset(0,0))
local customize=button(nav,"Customize","COLOR\nCustomize",UDim2.fromOffset(86,82),UDim2.fromOffset(0,92));customize.TextSize=17
local maps=button(nav,"Map","MAP\nExplore",UDim2.fromOffset(86,82),UDim2.fromOffset(0,184))
local audioToggle=button(gui,"Sound","Sound ON",UDim2.fromOffset(110,32),UDim2.new(1,-130,0,20));audioToggle.TextSize=14
local modal=Instance.new("Frame");modal.Name="Shop";modal.Size=UDim2.fromOffset(570,400);modal.Position=UDim2.new(0.5,-285,0.5,-200)
modal.BackgroundColor3=Color3.fromRGB(39,43,51);modal.Parent=gui;modal.Visible=false;modal.ZIndex=10;round(modal,12)
local heading=label(modal,"Title","PLANE UPGRADES",UDim2.new(1,-80,0,50),UDim2.fromOffset(20,12),28);heading.ZIndex=11;heading.TextXAlignment=Enum.TextXAlignment.Left
local close=button(modal,"Close","X",UDim2.fromOffset(36,36),UDim2.new(1,-50,0,16));close.ZIndex=12
local contents=Instance.new("Frame");contents.BackgroundTransparency=1;contents.Size=UDim2.new(1,-40,1,-85);contents.Position=UDim2.fromOffset(20,70);contents.ZIndex=11;contents.Parent=modal
local modalMode="Upgrades"
local palette={Color3.fromRGB(255,249,228),Color3.fromRGB(125,212,255),Color3.fromRGB(255,183,153),Color3.fromRGB(189,229,160)}
local wind=Instance.new("Sound");wind.Name="PaperFlightWind";wind.SoundId=Config.WindSoundId;wind.Looped=true;wind.Volume=0;wind.Parent=SoundService
-- A small pool allows nearby pickups to overlap without restarting one shared sound.
local chimes={}
local chimeIndex=0
for i=1,4 do
 local s=Instance.new("Sound");s.Name="RingChime"..i;s.SoundId=Config.CollectSoundId
 s.Volume=0.45;s.Parent=SoundService;chimes[i]=s
end
local function cursor(free)
 cursorFree=free
 UIS.MouseBehavior=mode~="Ready" and not free and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
 UIS.MouseIconEnabled=mode=="Ready" or free;reticle.Visible=mode~="Ready" and not free
end
local function renderModal()
 contents:ClearAllChildren()
 if modalMode=="Upgrades" then
  heading.Text="PAPER PLANE HANGAR"
  for i,id in Config.PlaneOrder do
   local def=Config.Planes[id];local owned=profile.ownedPlanes[id];local equipped=profile.planeId==id
   local y=(i-1)*56
   local viewport=Instance.new("ViewportFrame");viewport.Name=id.."Preview";viewport.Size=UDim2.fromOffset(80,52)
   viewport.Position=UDim2.fromOffset(0,y);viewport.BackgroundTransparency=1;viewport.ZIndex=12;viewport.Parent=contents
   viewport.Ambient=Color3.fromRGB(210,216,230);viewport.LightColor=Color3.fromRGB(255,248,230)
   local aircraft=package.PlaneModels[id]:Clone();aircraft.Parent=viewport;aircraft:PivotTo(CFrame.new())
   for _,v in aircraft:GetDescendants() do if v:IsA("Trail") then v.Enabled=false end end
   local eye=Instance.new("Camera");eye.CFrame=CFrame.lookAt(Vector3.new(10,13,-14),Vector3.zero);eye.FieldOfView=45;eye.Parent=viewport;viewport.CurrentCamera=eye
   local name=label(contents,id.."Name",def.name,UDim2.new(1,-205,0,24),UDim2.fromOffset(85,y),20)
   name.ZIndex=12;name.TextXAlignment=Enum.TextXAlignment.Left
   local detail=label(contents,id.."Stats",string.format("%d SPS  |  Rising air to %d",def.launchSpeed,def.airCeiling),UDim2.new(1,-205,0,20),UDim2.fromOffset(85,y+25),13)
   detail.ZIndex=12;detail.TextXAlignment=Enum.TextXAlignment.Left
   local text=equipped and "EQUIPPED" or owned and "EQUIP" or "$"..def.price
   local buy=button(contents,id,text,UDim2.fromOffset(112,43),UDim2.new(1,-112,0,y+4),equipped and Color3.fromRGB(56,116,94) or Color3.fromRGB(63,83,68))
   buy.ZIndex=12;buy.TextSize=16
   buy.Activated:Connect(function() remote:FireServer("Plane",id) end)
  end
  local note=label(contents,"SaveMode",saveMode,UDim2.new(1,0,0,23),UDim2.fromOffset(0,281),13);note.ZIndex=12
 elseif modalMode=="Colors" then
  heading.Text="PAPER COLORS"
  for i,color in palette do
   local b=button(contents,"Color"..i,({"Ivory","Sky","Peach","Sage"})[i],UDim2.fromOffset(240,90),UDim2.fromOffset((i-1)%2*260,math.floor((i-1)/2)*110),color)
   b.ZIndex=12;b.TextColor3=Color3.fromRGB(43,49,55)
   b.Activated:Connect(function() remote:FireServer("Color",i) end)
  end
 else
  heading.Text="EXPLORE THE ARCHIPELAGO"
  for i,area in World.Regions do
   local name=label(contents,area.name,area.name,UDim2.new(1,0,0,30),UDim2.fromOffset(0,(i-1)*40),22)
   name.ZIndex=12;name.TextColor3=area.color;name.TextXAlignment=Enum.TextXAlignment.Left
   local desc=label(contents,"Coords"..i,("X %d  /  Z %d"):format(area.center.X,area.center.Z),UDim2.new(1,0,0,20),UDim2.fromOffset(0,(i-1)*40+24),13)
   desc.ZIndex=12;desc.TextXAlignment=Enum.TextXAlignment.Left
  end
  local tip=label(contents,"Tip","Spiraling air columns lift you. Neon rings mark optional routes.\nYou can explore in any direction.",UDim2.new(1,0,0,60),UDim2.fromOffset(0,250),17);tip.ZIndex=12
 end
end
local function openModal(which) modalMode=which;modal.Visible=true;cursor(true);renderModal() end
upgrades.Activated:Connect(function() openModal("Upgrades") end);wallet.Activated:Connect(function() openModal("Upgrades") end)
customize.Activated:Connect(function() openModal("Colors") end);maps.Activated:Connect(function() openModal("Map") end)
close.Activated:Connect(function() modal.Visible=false;if mode~="Ready" then cursor(false) end end)
audioToggle.Activated:Connect(function() soundEnabled=not soundEnabled;audioToggle.Text=soundEnabled and "Sound ON" or "Sound OFF" end)
local function cleanPreview()
 if heldPlane then heldPlane:Destroy();heldPlane=nil end
 if trajectory then trajectory:Destroy();trajectory=nil end
 table.clear(dots)
end
local function colorPlane(model)
 for _,p in model:GetDescendants() do if p:IsA("BasePart") then p.Color=palette[profile.color]:Lerp(Color3.fromRGB(105,128,145),p:GetAttribute("FoldShade") or 0) end end
end
local function preview()
 cleanPreview()
 heldPlane=package.PlaneModels[profile.planeId]:Clone();heldPlane.Name="HeldPaperPlane";heldPlane:ScaleTo(0.2);heldPlane.Parent=camera;colorPlane(heldPlane)
 for _,v in heldPlane:GetDescendants() do if v:IsA("Trail") then v.Enabled=false end end
 trajectory=Instance.new("Folder");trajectory.Name="ThrowTrajectory";trajectory.Parent=camera
 local previous
 for i=1,25 do
  local p=Instance.new("Part");p.Name="AimAnchor";p.Size=Vector3.one*0.1
  p.Transparency=1;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=trajectory;dots[i]=p
  local anchor=Instance.new("Attachment");anchor.Parent=p
  if previous then
   local beam=Instance.new("Beam");beam.Name="ContinuousAimCurve"
   beam.Attachment0=previous;beam.Attachment1=anchor;beam.Width0=0.3;beam.Width1=0.3
   beam.FaceCamera=true;beam.Color=ColorSequence.new(Color3.fromRGB(83,255,144))
   beam.Transparency=NumberSequence.new(0.08);beam.LightEmission=1;beam.Segments=1;beam.Parent=trajectory
  end
  previous=anchor
 end
end
local function restoreRings()
 for _,p in hiddenRings do if p.Parent then p.LocalTransparencyModifier=0 end end
 table.clear(hiddenRings);table.clear(collectedIds)
end
workspace.DescendantAdded:Connect(function(part)
 if not part:IsA("BasePart") and not part:IsA("BillboardGui") then return end
 local ring=part.Parent
 if ring and collectedIds[ring:GetAttribute("RingId")] then
  if part:IsA("BasePart") then part.LocalTransparencyModifier=1;table.insert(hiddenRings,part)
  else part.Enabled=false end
 end
end)
local function requestAction()
 if mode=="Ready" then remote:FireServer("Aim")
 elseif mode=="Aiming" then remote:FireServer("Launch",yaw,pitch)
 elseif mode=="Flying" then remote:FireServer("Reset") end
end
action.Activated:Connect(requestAction)
UIS.InputBegan:Connect(function(input,processed)
 if processed then return end
 if input.KeyCode==Enum.KeyCode.F or input.KeyCode==Enum.KeyCode.E or input.KeyCode==Enum.KeyCode.ButtonA then requestAction() end
 if input.UserInputType==Enum.UserInputType.MouseButton1 and mode=="Aiming" and not cursorFree then requestAction() end
 if input.KeyCode==Enum.KeyCode.R or input.KeyCode==Enum.KeyCode.ButtonB then remote:FireServer("Reset") end
 if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.Q then if mode~="Ready" then cursor(not cursorFree) end end
 if (input.KeyCode==Enum.KeyCode.Space or input.KeyCode==Enum.KeyCode.ButtonR2) and mode=="Flying" then boostHeld=true end
end)
-- Consume Space during flight so holding boost does not queue an avatar jump.
CAS:BindActionAtPriority("PaperBoost",function(_,state)
 if mode=="Ready" then return Enum.ContextActionResult.Pass end
 if state==Enum.UserInputState.Begin then boostHeld=mode=="Flying"
 elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then boostHeld=false end
 return Enum.ContextActionResult.Sink
end,false,3000,Enum.KeyCode.Space,Enum.KeyCode.ButtonR2)
UIS.InputEnded:Connect(function(input)
 if input.KeyCode==Enum.KeyCode.Space or input.KeyCode==Enum.KeyCode.ButtonR2
  or input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then boostHeld=false end
end)
local function rotate(delta)
 yaw=(yaw-delta.X*Config.MouseSensitivity+math.pi)%(math.pi*2)-math.pi
 if mode=="Aiming" then yaw=math.clamp(yaw,-Config.MaxAimYaw,Config.MaxAimYaw) end
 pitch=math.clamp(pitch-delta.Y*Config.MouseSensitivity,Config.MinPitch,Config.MaxPitch)
end
UIS.InputChanged:Connect(function(input,processed)
 if input.KeyCode==Enum.KeyCode.Thumbstick1 then stick=Vector2.new(input.Position.X,input.Position.Y) end
 if input.UserInputType==Enum.UserInputType.Touch and not processed and mode~="Ready" then rotate(Vector2.new(input.Delta.X,input.Delta.Y)) end
end)
UIS.WindowFocusReleased:Connect(function() stick=Vector2.zero;boostHeld=false;cursor(true) end)
-- Procedural presentation supports both classic Motor6D and current constraint rigs.
-- Remove our previous layer before Animator evaluation, then add it after evaluation.
local poseLayers={}
RunService.PreAnimation:Connect(function()
 for joint,base in poseLayers do if joint.Parent then joint.Transform=base end end
 table.clear(poseLayers)
end)
local poseStarts={}
RunService.PreSimulation:Connect(function()
 for _,other in Players:GetPlayers() do
  local character=other.Character
  local state=character and character:GetAttribute("PaperThrowPose")
  if not character or not state then poseStarts[other]=nil; continue end
  local record=poseStarts[other]
  if not record or record.state~=state or record.character~=character then
   record={state=state,character=character,started=os.clock()}; poseStarts[other]=record
  end
  local shoulder=math.rad(75)
  local elbow=math.rad(10)
  if state=="Throwing" then
   local t=os.clock()-record.started
   shoulder=t<Config.ThrowDelay and math.rad(75-105*math.clamp(t/Config.ThrowDelay,0,1))
    or math.rad(-30)*(1-math.clamp((t-Config.ThrowDelay)/0.35,0,1))
   elbow=0
  end
  for _,joint in character:GetDescendants() do
   if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then
    local angle
    if joint.Name=="RightShoulder" or joint.Name=="Right Shoulder" then angle=shoulder end
    if joint.Name=="RightElbow" then angle=elbow end
    if angle then
     poseLayers[joint]=joint.Transform
     joint.Transform=joint.Transform*CFrame.Angles(angle,0,0)
    end
   end
  end
 end
end)
Players.PlayerRemoving:Connect(function(other) poseStarts[other]=nil end)


local function updateHud()
 wallet.Text="$"..profile.gold
 local flying=mode=="Flying" or mode=="Countdown"
 nav.Visible=not flying;wallet.Visible=not flying;speed.Visible=flying;condition.Visible=flying;bar.Visible=flying;boostLabel.Visible=flying;boostButton.Visible=flying and UIS.TouchEnabled
 earned.Visible=flying or telemetry.gold>0
 if mode=="Ready" then action.Text="Launch! [F]";action.BackgroundColor3=Color3.fromRGB(62,211,68)
 elseif mode=="Aiming" then action.Text="Throw! [F]";action.BackgroundColor3=Color3.fromRGB(231,60,57)
 else action.Text="End Run [F]";action.BackgroundColor3=Color3.fromRGB(220,56,53) end
 hint.Text=flying and "Shift - Unlock mouse\nSpace - Hold to boost" or "Mouse - Aim / steer\nF - Launch / throw"
end
remote.OnClientEvent:Connect(function(kind,data)
 if kind=="Profile" then
  local changed=profile.planeId~=data.planeId
  profile.gold=data.gold;profile.levels=data.levels;profile.planeId=data.planeId or "Dart";profile.ownedPlanes=data.ownedPlanes or {Dart=true};profile.color=data.color;saveMode=data.saveMode
  wallet.Text="$"..data.gold;if data.message then message.Text=data.message end
  if heldPlane then if changed then preview() else colorPlane(heldPlane) end end
  if modal.Visible then renderModal() end
 elseif kind=="Aiming" then
  mode="Aiming";boostHeld=false;yaw=0;pitch=Config.AimPitch;modal.Visible=false
  telemetry.gold=0;earned.Text="$0";distance.Text="";message.Text="Aim the green path, then click to throw."
  camera.CameraType=Enum.CameraType.Scriptable;preview();cursor(false)
 elseif kind=="Thrown" then
  mode="Countdown";cameraMotion=FlightCamera.new();smoothedFrame=nil;restoreRings();cleanPreview();message.Text="";cursor(false)
  telemetry.gold=0;telemetry.distance=0;telemetry.boostRemaining=Config.BoostDuration;telemetry.boosting=false;telemetry.recharging=false;telemetry.speed=Flight.stats(profile.levels,profile.planeId).launchSpeed;wind:Play()
 elseif kind=="Flying" then mode="Flying"
 elseif kind=="Telemetry" then
  telemetry=data;earned.Text="$"..data.gold
  distance.Text=string.format("%d studs  |  %d rings",data.distance,data.rings)
  region.Text=string.upper(data.region)
 elseif kind=="Ring" then
  if collectedIds[data.id] then return end
  collectedIds[data.id]=true
  if soundEnabled then
   chimeIndex=chimeIndex%#chimes+1
   local chime=chimes[chimeIndex];chime.PlaybackSpeed=1+(data.id%4)*0.045;chime:Play()
  end
  local folder=workspace:FindFirstChild("PaperFlightWorld")
  local rings=folder and folder:FindFirstChild("Rings")
  local ring=rings and rings:FindFirstChild("Ring"..data.id)
  if ring then
   for _,p in ring:GetDescendants() do
    if p:IsA("BasePart") then p.LocalTransparencyModifier=1;table.insert(hiddenRings,p)
    elseif p:IsA("BillboardGui") then p.Enabled=false end
   end
  end
 elseif kind=="Ended" then
  mode="Ready";boostHeld=false;telemetry.gold=data.gold;earned.Text="+$"..data.gold
  distance.Text=string.format("%d studs explored",data.distance)
  message.Text=data.message;cleanPreview()
  if visualPlane then visualPlane:Destroy();visualPlane=nil end
  wind:Stop();wind.Volume=0
  camera.CameraType=Enum.CameraType.Custom;camera.FieldOfView=originalFov
  local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid");if h then camera.CameraSubject=h end
  cursor(true);restoreRings()
 end
 updateHud()
end)
-- Streaks are local presentation geometry and never participate in collision.
local random=Random.new(42)
for i=1,26 do
 local p=Instance.new("Part");p.Name="WindStreak";p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
 p.Material=Enum.Material.Neon;p.Color=Color3.fromRGB(225,241,250);p.Transparency=1;p.Parent=camera
 lines[i]={part=p,x=(i%2==0 and 1 or -1)*random:NextNumber(6,22),y=random:NextNumber(-12,16),z=random:NextNumber(-65,-8)}
end
local function resize()
 local w=camera.ViewportSize.X
 local factor=math.clamp(w/1300,0.55,1)
 for _,object in {action,nav,wallet,modal,speed,condition,bar,boostLabel,boostButton,hint,earned,distance} do
  local scale=object:FindFirstChildOfClass("UIScale") or Instance.new("UIScale");scale.Scale=factor;scale.Parent=object
 end
 action.AnchorPoint=Vector2.new(0.5,1);action.Position=UDim2.new(0.5,0,1,-20)
 modal.AnchorPoint=Vector2.new(0.5,0.5);modal.Position=UDim2.fromScale(0.5,0.5)
 earned.AnchorPoint=Vector2.new(0.5,0);earned.Position=UDim2.new(0.5,0,0,52)
 distance.AnchorPoint=Vector2.new(0.5,0);distance.Position=UDim2.new(0.5,0,0,112)
 speed.AnchorPoint=Vector2.new(1,1);speed.Position=UDim2.new(1,-20,1,-116*factor)
 condition.AnchorPoint=Vector2.new(1,1);condition.Position=UDim2.new(1,-20,1,-80*factor)
 bar.AnchorPoint=Vector2.new(1,1);bar.Position=UDim2.new(1,-20,1,-56*factor)
 boostLabel.AnchorPoint=Vector2.new(1,1);boostLabel.Position=UDim2.new(1,-20,1,-27*factor)
 wallet.AnchorPoint=Vector2.new(0,1);wallet.Position=UDim2.new(0,24,1,-24)
 hint.AnchorPoint=Vector2.new(0,1);hint.Position=UDim2.new(0,24,1,-86*factor)
end
resize();camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
RunService:BindToRenderStep("PaperFlightCamera",Enum.RenderPriority.Camera.Value+1,function(dt)
 local flying=mode=="Flying"
 local intensity=flying and math.clamp((telemetry.speed-80)/170,0,1) or 0
 wind.Volume=soundEnabled and (flying and 0.08+intensity*0.38 or 0) or 0
 wind.PlaybackSpeed=0.75+math.clamp(telemetry.speed/250,0,1)*0.65
 for _,line in lines do
  line.z+=dt*telemetry.speed*1.4;if line.z>0 then line.z=-65 end
  line.part.Transparency=intensity>0.02 and 1-intensity*0.48 or 1
  line.part.Size=Vector3.new(0.028,0.028,2+intensity*8)
  line.part.CFrame=camera.CFrame*CFrame.new(line.x,line.y,line.z)
 end
 if mode=="Ready" then return end
 if not cursorFree then
  UIS.MouseBehavior=Enum.MouseBehavior.LockCenter;rotate(UIS:GetMouseDelta())
  if stick.Magnitude>0.15 then rotate(Vector2.new(stick.X*dt*420,-stick.Y*dt*330)) end
 end
 local aimFrame=CFrame.Angles(0,yaw,0)*CFrame.Angles(pitch,0,0)
 local direction=aimFrame.LookVector
 if mode=="Aiming" then
  local c=player.Character;local hand=c and (c:FindFirstChild("RightHand") or c:FindFirstChild("Right Arm"))
  if heldPlane then heldPlane:PivotTo(CFrame.new((hand and hand.Position or Config.Launch)+direction*0.8)*aimFrame) end
  previewClock+=dt
  if previewClock>1/30 then
   previewClock=0;local stats=Flight.stats(profile.levels,profile.planeId);local state=Flight.new(Config.Launch,yaw,pitch,stats)
   for i=1,#dots do
    if i>1 then for _=1,6 do state=Flight.step(state,Flight.aimInput(state,yaw,pitch),1/60,stats,World.lift(state.position,profile.planeId)) end end
    dots[i].Position=(i==1 and heldPlane) and heldPlane:GetPivot().Position or state.position
   end
  end
  local focus=Config.ThrowStand+Vector3.new(0,2,0)
  camera.CFrame=CFrame.lookAt(focus-direction*17+Vector3.new(-3,4,0),focus+direction*80);camera.FieldOfView=65
  return
 end
 local folder=workspace:FindFirstChild("ActivePaperPlanes");local plane=folder and folder:FindFirstChild("Plane_"..player.UserId)
 if not plane then return end
 if not visualPlane then
  visualPlane=package.PlaneModels[profile.planeId]:Clone();visualPlane.Name="LocalFlightVisual";visualPlane:ScaleTo(0.65);visualPlane.Parent=camera;colorPlane(visualPlane)
  for _,p in plane:GetDescendants() do
   if p:IsA("BasePart") then p.LocalTransparencyModifier=1 end
   if p:IsA("Trail") then p.Enabled=false end
  end
 end
 local frame=plane:GetPivot();smoothedFrame=smoothedFrame and smoothedFrame:Lerp(frame,1-math.exp(-16*dt)) or frame
 visualPlane:PivotTo(smoothedFrame)
 inputClock+=dt
 if flying and inputClock>=1/15 then
  inputClock=0
  local state={position=frame.Position,yaw=math.atan2(-frame.LookVector.X,-frame.LookVector.Z),pitch=math.asin(frame.LookVector.Y),speed=telemetry.speed,stalled=telemetry.stalled,bank=0}
  local input=Flight.aimInput(state,yaw,pitch);remote:FireServer("Input",input.X,input.Y,boostHeld)
 end
 if flying or mode=="Countdown" then
  local pos=smoothedFrame.Position
  -- Release immediately targets normal framing; the spring-like smoothing prevents a snap.
  cameraMotion=FlightCamera.step(cameraMotion,dt,boostHeld and telemetry.boosting==true)
  camera.CFrame=CFrame.lookAt(pos-direction*cameraMotion.distance+Vector3.new(0,5,0),pos+direction*70)
  camera.FieldOfView=cameraMotion.fov
  speed.Text=string.format("%d SPS",telemetry.speed)
  condition.Text=telemetry.stalled and "STALL - LOWER THE NOSE" or telemetry.lift>3 and "RISING AIR" or telemetry.boosting and "BOOSTING" or "GLIDING"
  condition.TextColor3=telemetry.stalled and Color3.fromRGB(255,127,83) or Color3.fromRGB(208,220,227)
  local fuel=telemetry.boostRemaining or 0
  fill.Size=UDim2.fromScale(math.clamp(fuel/Config.BoostDuration,0,1),1)
  fill.BackgroundColor3=telemetry.boosting and Color3.fromRGB(117,235,255) or telemetry.recharging and Color3.fromRGB(115,231,158) or Color3.fromRGB(91,166,251)
  local boostStatus=telemetry.recharging and "RECHARGING" or fuel>=Config.BoostDuration-0.01 and "BOOST READY"
   or boostHeld and fuel<=0.01 and "RELEASE BOOST"
   or not boostHeld and not telemetry.boosting and "GLIDE TO RECHARGE" or "BOOST"
  boostLabel.Text=string.format("%s  %.1fs",boostStatus,fuel)
  boostButton.Text=telemetry.boosting and "BOOSTING" or "HOLD BOOST"
 end
end)
-- Coarse distant terrain stays visible beyond streamed detail, without loading every tree.
task.spawn(function()
 local world=workspace:WaitForChild("PaperFlightWorld")
 local vista=world:WaitForChild("DistantLandscape")
 local tiles={}
 for _,tile in vista:GetChildren() do
  local center=tile:GetAttribute("Center")
  if center then table.insert(tiles,{center=center,parts=tile:GetDescendants()}) end
 end
 while gui.Parent do
  local eye=camera.CFrame.Position
  for _,tile in tiles do
   local d=(tile.center-eye).Magnitude
   local fade=1-math.clamp((d-1100)/550,0,1)
   for _,p in tile.parts do if p:IsA("BasePart") then p.LocalTransparencyModifier=fade end end
  end
  task.wait(0.5)
 end
end)
-- Distant summit halos keep a readable angular size while the actual opening stays small.
task.spawn(function()
 local world=workspace:WaitForChild("PaperFlightWorld")
 local rings=world:WaitForChild("Rings")
 while gui.Parent do
  for _,ring in rings:GetChildren() do
   local beacon=ring:FindFirstChild("SummitBeacon")
   local anchor=ring:FindFirstChild("SummitBeaconAnchor")
   if beacon and anchor then
    local distance=(camera.CFrame.Position-anchor.Position).Magnitude
    beacon.Enabled=distance>300 and not collectedIds[ring:GetAttribute("RingId")]
   end
  end
  task.wait(0.15)
 end
end)
updateHud();remote:FireServer("Sync")
print("Exploration HUD and wind presentation ready.")
