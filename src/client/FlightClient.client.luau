--!strict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("PaperFlight")
local Config=require(package.Config)
local remote=package.RaceEvent
local camera=workspace.CurrentCamera
local gui=Instance.new("ScreenGui")
gui.Name="PaperFlightHUD"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.Parent=player:WaitForChild("PlayerGui")
local function corner(object,radius)
 local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,radius or 12); c.Parent=object
end
local function label(parent,text,size,pos,font)
 local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Size=size; l.Position=pos
 l.Font=font or Enum.Font.Gotham; l.Text=text; l.TextColor3=Color3.fromRGB(237,245,248)
 l.TextSize=16; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=parent; return l
end
local card=Instance.new("Frame"); card.Name="FlightPanel"
card.Size=UDim2.new(0,340,0,234); card.Position=UDim2.new(0,24,0,65)
card.BackgroundColor3=Color3.fromRGB(13,29,42); card.BackgroundTransparency=0.08; card.Parent=gui; corner(card,16)
local stroke=Instance.new("UIStroke"); stroke.Color=Color3.fromRGB(64,95,110); stroke.Transparency=0.4; stroke.Parent=card
label(card,"P A P E R   /   F L I G H T",UDim2.new(1,-36,0,25),UDim2.fromOffset(18,16),Enum.Font.GothamBold).TextSize=19
label(card,"COASTAL RUN   •   TIME TRIAL",UDim2.new(1,-36,0,22),UDim2.fromOffset(18,47)).TextColor3=Color3.fromRGB(102,211,211)
local status=label(card,"Ready on the launch deck",UDim2.new(1,-36,0,26),UDim2.fromOffset(18,78))
local timer=label(card,"00.00",UDim2.new(0,170,0,47),UDim2.fromOffset(18,105),Enum.Font.GothamBold); timer.TextSize=38
local progress=label(card,"RINGS  0 / 6",UDim2.new(0,130,0,30),UDim2.fromOffset(190,118),Enum.Font.GothamBold)
local best=label(card,"SESSION BEST  —",UDim2.new(1,-36,0,20),UDim2.fromOffset(18,156)); best.TextSize=12; best.TextColor3=Color3.fromRGB(156,181,194)
local function button(name,text,x,width,color)
 local b=Instance.new("TextButton"); b.Name=name; b.Text=text; b.Font=Enum.Font.GothamBold; b.TextSize=14
 b.TextColor3=Color3.fromRGB(9,31,40); b.BackgroundColor3=color; b.Size=UDim2.fromOffset(width,40); b.Position=UDim2.fromOffset(x,184)
 b.Parent=card; corner(b,10); return b
end
local launch=button("Launch","LAUNCH  [SPACE]",18,192,Color3.fromRGB(119,237,216))
local reset=button("Reset","RESET  [R]",220,102,Color3.fromRGB(208,224,234))
local help=Instance.new("Frame"); help.AnchorPoint=Vector2.new(0.5,1); help.Position=UDim2.new(0.5,0,1,-24); help.Size=UDim2.new(0.88,0,0,42)
help.BackgroundColor3=Color3.fromRGB(13,29,42); help.BackgroundTransparency=0.16; help.Parent=gui; corner(help)
local controls=label(help,"A / D  STEER     W / S  CLIMB / DIVE     SPACE  LAUNCH     R  RESET",UDim2.new(1,-24,1,0),UDim2.fromOffset(12,0),Enum.Font.GothamMedium)
controls.TextXAlignment=Enum.TextXAlignment.Center; controls.TextSize=13
local targetLabel=label(gui,"",UDim2.fromOffset(190,34),UDim2.fromOffset(0,0),Enum.Font.GothamBold)
targetLabel.TextXAlignment=Enum.TextXAlignment.Center; targetLabel.BackgroundTransparency=0.15; targetLabel.BackgroundColor3=Color3.fromRGB(13,29,42); corner(targetLabel)
local flying=false
local countdownEnd=0
local nextRing=1
local elapsed=0
local lastTelemetry=0
local inputClock=0
local held={}
local stick=Vector2.zero
local smoothedFrame=nil
local visualPlane=nil
local originalFov=camera.FieldOfView
local function requestLaunch() remote:FireServer("Launch") end
local function requestReset() remote:FireServer("Reset") end
launch.Activated:Connect(requestLaunch); reset.Activated:Connect(requestReset)
UIS.InputBegan:Connect(function(input,processed)
 if processed then return end
 held[input.KeyCode]=true
 if input.KeyCode==Enum.KeyCode.Space or input.KeyCode==Enum.KeyCode.ButtonA then requestLaunch() end
 if input.KeyCode==Enum.KeyCode.R or input.KeyCode==Enum.KeyCode.ButtonB then requestReset() end
end)
UIS.InputEnded:Connect(function(input) held[input.KeyCode]=nil end)
UIS.WindowFocusReleased:Connect(function() table.clear(held); stick=Vector2.zero end)
UIS.InputChanged:Connect(function(input)
 if input.KeyCode==Enum.KeyCode.Thumbstick1 then stick=Vector2.new(input.Position.X,input.Position.Y) end
end)
-- Touch buttons share the same axes as keyboard/gamepad.
local touchHeld={}
local function touchAction(name,state)
 touchHeld[name]=state==Enum.UserInputState.Begin
 return Enum.ContextActionResult.Sink
end
for _,entry in ipairs({{"PFLeft","LEFT",Enum.KeyCode.Left},{"PFRight","RIGHT",Enum.KeyCode.Right},{"PFUp","CLIMB",Enum.KeyCode.Up},{"PFDown","DIVE",Enum.KeyCode.Down}}) do
 CAS:BindAction(entry[1],touchAction,true,entry[3]); CAS:SetTitle(entry[1],entry[2])
end
CAS:SetPosition("PFLeft",UDim2.new(0,50,1,-160))
CAS:SetPosition("PFRight",UDim2.new(0,145,1,-160))
CAS:SetPosition("PFUp",UDim2.new(1,-145,1,-220))
CAS:SetPosition("PFDown",UDim2.new(1,-145,1,-120))
if UIS.TouchEnabled then controls.Text="TOUCH ARROWS  STEER / CLIMB / DIVE     •     TAP LAUNCH TO START" end
local function recolorRings()
 for i=1,#Config.Course do
  local ring=workspace.PaperFlightWorld.Checkpoints:FindFirstChild("Ring"..i)
  if ring then for _,p in ring:GetChildren() do
   if p:IsA("BasePart") then p.Color=i<nextRing and Color3.fromRGB(51,113,119) or i==nextRing and Color3.fromRGB(255,204,108) or Color3.fromRGB(99,228,218) end
  end end
 end
end
remote.OnClientEvent:Connect(function(kind,data)
 if kind=="Countdown" then
  flying=true; nextRing=1; elapsed=0; timer.Text="00.00"; countdownEnd=os.clock()+data.seconds; smoothedFrame=nil
  camera.CameraType=Enum.CameraType.Scriptable; launch.Text="RELAUNCH [SPACE]"; recolorRings()
 elseif kind=="Flying" then countdownEnd=0; status.Text="Fly through the golden ring"
 elseif kind=="Checkpoint" then nextRing=data.next; recolorRings(); status.Text="Checkpoint cleared!"
 elseif kind=="Telemetry" then elapsed=data.time; lastTelemetry=os.clock(); nextRing=data.next
 elseif kind=="Finished" or kind=="Crashed" or kind=="Missed" or kind=="Ready" then
  flying=false; countdownEnd=0; status.Text=data.message or "Ready"; elapsed=data.time or 0
  if visualPlane then visualPlane:Destroy(); visualPlane=nil end
  timer.Text=string.format("%05.2f",elapsed); targetLabel.Visible=false
  if kind=="Finished" then nextRing=#Config.Course+1; recolorRings() end
  if data.best then best.Text=string.format("SESSION BEST  %.2f s",data.best) end
  camera.CameraType=Enum.CameraType.Custom; camera.FieldOfView=originalFov
  local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if humanoid then camera.CameraSubject=humanoid end
  launch.Text="LAUNCH  [SPACE]"
 end
 progress.Text=string.format("RINGS  %d / %d",math.min(nextRing-1,#Config.Course),#Config.Course)
end)
local scale=Instance.new("UIScale"); scale.Parent=card
local function resize()
 scale.Scale=math.clamp(camera.ViewportSize.X/1000,0.65,1)
end
resize(); camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
RunService.RenderStepped:Connect(function(dt)
 inputClock+=dt
 if flying and inputClock>=1/15 then
  inputClock=0
  local x=(held[Enum.KeyCode.D] and 1 or 0)-(held[Enum.KeyCode.A] and 1 or 0)+(touchHeld.PFRight and 1 or 0)-(touchHeld.PFLeft and 1 or 0)
  local y=(held[Enum.KeyCode.W] and 1 or 0)-(held[Enum.KeyCode.S] and 1 or 0)+(touchHeld.PFUp and 1 or 0)-(touchHeld.PFDown and 1 or 0)
  if stick.Magnitude>0.15 then x=stick.X; y=stick.Y end
  remote:FireServer("Input",math.clamp(x,-1,1),math.clamp(y,-1,1))
 end
 if not flying then return end
 if countdownEnd>0 then status.Text="Launching in "..math.max(1,math.ceil(countdownEnd-os.clock()))
 else timer.Text=string.format("%05.2f",elapsed+math.clamp(os.clock()-lastTelemetry,0,0.2)) end
 local folder=workspace:FindFirstChild("ActivePaperPlanes")
 local plane=folder and folder:FindFirstChild("Plane_"..player.UserId)
 if not plane then return end
 if not visualPlane then
  visualPlane=package.Plane:Clone(); visualPlane.Name="LocalFlightVisual"; visualPlane.Parent=camera
  for _,part in plane:GetDescendants() do
   if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end
   if part:IsA("Trail") then part.Enabled=false end
  end
 end
 local frame=plane:GetPivot()
 smoothedFrame=smoothedFrame and smoothedFrame:Lerp(frame,1-math.exp(-15*dt)) or frame
 visualPlane:PivotTo(smoothedFrame)
 local pos=smoothedFrame.Position
 local direction=smoothedFrame.LookVector
 local desired=CFrame.lookAt(pos-direction*28+Vector3.new(0,10,0),pos+direction*35)
 camera.CFrame=camera.CFrame:Lerp(desired,1-math.exp(-8*dt))
 camera.FieldOfView=74
 local target=Config.Course[nextRing]
 if target then
  local point,onScreen=camera:WorldToViewportPoint(target)
  targetLabel.Visible=onScreen
  targetLabel.Position=UDim2.fromOffset(point.X-95,point.Y-48)
  targetLabel.Text=string.format("RING %d  •  %d m",nextRing,math.floor((target-pos).Magnitude))
 end
end)
print("Paper Flight client ready.")

