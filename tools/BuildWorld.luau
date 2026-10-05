-- Build only the named PaperFlight containers; leave unrelated project content intact.
local RS=game:GetService("ReplicatedStorage")
local Lighting=game:GetService("Lighting")
local world=workspace:FindFirstChild("PaperFlightWorld")
if world then world:Destroy() end
world=Instance.new("Folder"); world.Name="PaperFlightWorld"; world.Parent=workspace
local function part(name,size,cf,color,material,parent)
 local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color
 p.Material=material or Enum.Material.SmoothPlastic; p.Anchored=true; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=parent or world; return p
end
local colors={rock=Color3.fromRGB(71,92,99),grass=Color3.fromRGB(83,137,101),sand=Color3.fromRGB(214,195,151),wood=Color3.fromRGB(115,90,64)}
local ocean=part("Ocean",Vector3.new(2600,4,3000),CFrame.new(0,-2,-450),Color3.fromRGB(39,120,151),Enum.Material.Glass)
ocean.Transparency=0.2; ocean.Reflectance=0.18
local random=Random.new(381)
local function island(name,pos,radius,height)
 local model=Instance.new("Model"); model.Name=name; model.Parent=world
 local rock=part("Cliff",Vector3.new(radius*2,height,radius*1.6),CFrame.new(pos.X,height/2-8,pos.Z),colors.rock,Enum.Material.Slate,model)
 rock.Shape=Enum.PartType.Cylinder; rock.CFrame=CFrame.new(pos.X,height/2-8,pos.Z)*CFrame.Angles(0,0,math.pi/2)
 rock.Size=Vector3.new(height,radius*2,radius*1.6)
 local grass=part("Meadow",Vector3.new(5,radius*2,radius*1.6),CFrame.new(pos.X,height-6,pos.Z)*CFrame.Angles(0,0,math.pi/2),colors.grass,Enum.Material.Grass,model)
 grass.Shape=Enum.PartType.Cylinder
 for i=1,14 do
  local angle=random:NextNumber(0,math.pi*2)
  local distance=random:NextNumber(0.25,0.85)*radius
  local x=pos.X+math.cos(angle)*distance; local z=pos.Z+math.sin(angle)*distance*0.75
  local h=random:NextNumber(9,17)
  part("TreeTrunk",Vector3.new(2,h,2),CFrame.new(x,height-4+h/2,z),colors.wood,Enum.Material.Wood,model)
  local crown=part("TreeCrown",Vector3.new(12,14,12),CFrame.new(x,height-4+h+4,z),Color3.fromRGB(48,106+random:NextInteger(0,25),83),Enum.Material.Grass,model)
  crown.Shape=Enum.PartType.Ball
 end
 for i=1,8 do
  local b=part("Rock",Vector3.new(random:NextNumber(8,19),random:NextNumber(8,18),random:NextNumber(8,19)),
   CFrame.new(pos.X+random:NextNumber(-radius*0.6,radius*0.6),height-3,pos.Z+random:NextNumber(-radius*0.5,radius*0.5))*CFrame.Angles(0,random:NextNumber(0,6),0),colors.rock,Enum.Material.Slate,model)
 end
 return model
end
island("LaunchIsland",Vector3.new(0,0,180),100,104)
island("WestIsland",Vector3.new(-180,0,-260),80,39)
island("EastIsland",Vector3.new(175,0,-440),110,46)
island("FinishIsland",Vector3.new(0,0,-955),105,45)
for i=1,8 do
 local side=i%2==0 and 1 or -1
 local x=side*random:NextNumber(350,550); local z=-i*150+180
 local h=random:NextNumber(85,170)
 for j=1,3 do
  local a=(j-1)*math.pi*2/3
  local wedge=Instance.new("WedgePart"); wedge.Name="RockyPeak"; wedge.Anchored=true
  wedge.Size=Vector3.new(95,h,150)
  wedge.CFrame=CFrame.new(x+math.cos(a)*24,h/2-8,z+math.sin(a)*24)*CFrame.Angles(0,a,0)
  wedge.Color=colors.rock:Lerp(Color3.fromRGB(105,121,119),(j-1)*0.12); wedge.Material=Enum.Material.Slate; wedge.Parent=world
 end
 local foot=part("RockyShore",Vector3.new(190,55,185),CFrame.new(x,5,z),colors.rock,Enum.Material.Slate)
 foot.Shape=Enum.PartType.Ball
end
local deck=part("LaunchDeck",Vector3.new(46,3,62),CFrame.new(0,108,125),colors.wood,Enum.Material.WoodPlanks)
for _,x in {-24,24} do
 part("DeckRail",Vector3.new(1,4,62),CFrame.new(x,112,125),Color3.fromRGB(202,211,201),Enum.Material.Wood)
 for _,z in {98,125,154} do part("DeckPost",Vector3.new(2,18,2),CFrame.new(x,100,z),colors.wood,Enum.Material.Wood) end
end
for i=1,4 do part("RunwayStripe",Vector3.new(1,0.08,6),CFrame.new(0,109.55,105+i*10),Color3.fromRGB(241,233,197)) end
local spawn=workspace:FindFirstChildOfClass("SpawnLocation")
if spawn then spawn.CFrame=CFrame.new(0,111,142); spawn.Size=Vector3.new(6,1,6); spawn.Transparency=1; spawn.CanCollide=false; spawn.Neutral=true; spawn.Duration=0 end
local base=workspace:FindFirstChild("Baseplate")
if base then base.Transparency=1; base.CanCollide=false; base.CanQuery=false end
local sign=part("WelcomeSign",Vector3.new(28,13,1),CFrame.new(0,121,154),Color3.fromRGB(13,29,42))
local surface=Instance.new("SurfaceGui"); surface.Face=Enum.NormalId.Front; surface.PixelsPerStud=40; surface.Parent=sign
local title=Instance.new("TextLabel"); title.Size=UDim2.fromScale(1,1); title.BackgroundTransparency=1; title.Text="PAPER / FLIGHT\nCOASTAL RUN\n\nAIM - CLICK TO THROW"
title.Font=Enum.Font.GothamBold; title.TextSize=70; title.TextColor3=Color3.fromRGB(119,237,216); title.Parent=surface
local checkpoints=Instance.new("Folder"); checkpoints.Name="Checkpoints"; checkpoints.Parent=world
local Config=require(RS.PaperFlight.Config)
for i,center in Config.Course do
 local ring=Instance.new("Model"); ring.Name="Ring"..i; ring.Parent=checkpoints
 for segment=1,40 do
  local angle=segment/40*math.pi*2
  local pos=center+Vector3.new(math.cos(angle)*Config.RingRadius,math.sin(angle)*Config.RingRadius,0)
  local p=part("Arc",Vector3.new(1.1,2*math.pi*Config.RingRadius/40+0.2,1.1),CFrame.new(pos)*CFrame.Angles(0,0,angle),Color3.fromRGB(99,228,218),Enum.Material.Neon,ring)
  p.CanCollide=false; p.CanQuery=false; p.CanTouch=false
 end
 local anchor=part("Marker",Vector3.one,CFrame.new(center+Vector3.new(0,24,0)),Color3.new(1,1,1),nil,ring)
 anchor.Transparency=1; anchor.CanCollide=false; anchor.CanQuery=false
 local billboard=Instance.new("BillboardGui"); billboard.Size=UDim2.fromOffset(160,40); billboard.AlwaysOnTop=false; billboard.MaxDistance=400; billboard.Parent=anchor
 local text=Instance.new("TextLabel"); text.Size=UDim2.fromScale(1,1); text.BackgroundTransparency=1; text.Font=Enum.Font.GothamBold; text.TextSize=25
 text.Text=i==#Config.Course and "FINISH" or string.format("%02d",i); text.TextColor3=Color3.fromRGB(255,239,190); text.Parent=billboard
end
local package=RS.PaperFlight
local previous=package:FindFirstChild("Plane"); if previous then previous:Destroy() end
local plane=Instance.new("Model"); plane.Name="Plane"; plane.Parent=package
-- Thin wedges provide a folded paper silhouette without external assets.
local function wedge(name,size,cf,color)
 local w=Instance.new("WedgePart"); w.Name=name; w.Size=size; w.CFrame=cf; w.Anchored=true; w.CanCollide=false; w.CanTouch=false; w.CanQuery=false
 w.Material=Enum.Material.SmoothPlastic; w.Color=color; w.Parent=plane; return w
end
local keel=wedge("Fold",Vector3.new(0.18,1.4,9),CFrame.new(0,0,0),Color3.fromRGB(219,230,237))
plane.PrimaryPart=keel
-- Wedge height is rotated into the horizontal plane to form triangular wings.
wedge("LeftWing",Vector3.new(0.12,5.5,9),CFrame.new(-2.75,0.2,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(245,247,237))
wedge("RightWing",Vector3.new(0.12,5.5,9),CFrame.new(2.75,0.2,0)*CFrame.Angles(0,0,-math.pi/2),Color3.fromRGB(232,241,242))
plane:PivotTo(CFrame.new(0,0,0))
for _,x in {-4.5,4.5} do
 local a=Instance.new("Attachment"); a.Position=Vector3.new(x,0,3); a.Parent=keel
 local b=Instance.new("Attachment"); b.Position=Vector3.new(x,0.15,3); b.Parent=keel
 local trail=Instance.new("Trail"); trail.Attachment0=a; trail.Attachment1=b; trail.Lifetime=0.65; trail.MinLength=0.2
 trail.Color=ColorSequence.new(Color3.fromRGB(210,255,249)); trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.45),NumberSequenceKeypoint.new(1,1)}); trail.Parent=keel
end
Lighting.ClockTime=16.2; Lighting.Brightness=2.5
Lighting.Ambient=Color3.fromRGB(117,144,159); Lighting.OutdoorAmbient=Color3.fromRGB(145,164,169)
local atmosphere=Lighting:FindFirstChild("PaperAtmosphere") or Instance.new("Atmosphere")
atmosphere.Name="PaperAtmosphere"; atmosphere.Density=0.22; atmosphere.Offset=0.1; atmosphere.Color=Color3.fromRGB(205,228,236); atmosphere.Decay=Color3.fromRGB(111,153,170); atmosphere.Parent=Lighting
local bloom=Lighting:FindFirstChild("PaperBloom") or Instance.new("BloomEffect"); bloom.Name="PaperBloom"; bloom.Intensity=0.2; bloom.Size=20; bloom.Threshold=1.5; bloom.Parent=Lighting
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(170,180,260),Vector3.new(0,90,-170))
return "Built coastal course, launch deck, six rings, and paper plane template."
