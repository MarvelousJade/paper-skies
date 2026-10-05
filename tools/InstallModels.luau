-- GENERATED: run in Studio EDIT mode to install scenery and ambience only.
-- Requires the existing ReplicatedStorage.PaperFlight.Config module.
local parent=game.StarterPlayer.StarterPlayerScripts
local ambience=parent:FindFirstChild("PaperFlightAmbience") or Instance.new("LocalScript")
ambience.Name="PaperFlightAmbience"
ambience.Source=[=[
-- Decorative, local-only glow. A slow four-second cycle keeps the valley calm.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local glows = {}
local function add(instance)
 if instance:IsA("BasePart") then glows[instance] = instance:GetAttribute("PulsePhase") or 0 end
end
for _,instance in CollectionService:GetTagged("PaperFlightGlow") do add(instance) end
CollectionService:GetInstanceAddedSignal("PaperFlightGlow"):Connect(add)
CollectionService:GetInstanceRemovedSignal("PaperFlightGlow"):Connect(function(instance) glows[instance]=nil end)
local elapsed, frameTime = 0, 0
RunService.Heartbeat:Connect(function(dt)
 elapsed += dt; frameTime += dt
 if frameTime < 1/20 then return end
 frameTime = 0
 for part, phase in glows do
  if part:IsDescendantOf(workspace) then
   part.Transparency = 0.12 + 0.26 * (0.5 + 0.5 * math.sin(elapsed * math.pi / 2 + phase))
  end
 end
end)
]=]
ambience.Parent=parent
-- Run in Studio's EDIT mode after installing src/shared/Config.luau.
-- Builds off-tree, then swaps only PaperFlightWorld. Keeps the previous world in ServerStorage.
-- All geometry is editable Roblox parts; no external mesh or texture assets are required.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local Config = require(RS.PaperFlight.Config)
local V, CF = Vector3.new, CFrame.new
local C = {
 grass=Color3.fromRGB(142,180,126), grassLight=Color3.fromRGB(166,197,144),
 grassDark=Color3.fromRGB(105,155,123), rock=Color3.fromRGB(139,157,160),
 rockDark=Color3.fromRGB(104,127,139), sand=Color3.fromRGB(225,208,167),
 stone=Color3.fromRGB(215,204,173), pale=Color3.fromRGB(241,231,199),
 aqua=Color3.fromRGB(111,239,216), water=Color3.fromRGB(94,183,189),
 wood=Color3.fromRGB(153,120,91), leaf=Color3.fromRGB(102,161,132),
 coral=Color3.fromRGB(236,162,139), paper=Color3.fromRGB(255,246,220),
}
local rng = Random.new(70421)
local world = Instance.new("Folder")
world.Name = "PaperFlightWorld"
world:SetAttribute("ArtDirection", "Dream Valley / low-poly pastel adventure")
world:SetAttribute("GeneratorVersion", 1)
local function model(name, parent)
 local m=Instance.new("Model"); m.Name=name; m.Parent=parent or world; return m
end
local function part(parent,name,size,cf,color,material,class)
 local p=Instance.new(class or "Part"); p.Name=name; p.Size=size; p.CFrame=cf
 p.Color=color; p.Material=material or Enum.Material.SmoothPlastic
 p.Anchored=true; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
 p.CanTouch=false; p.Parent=parent; return p
end
local function decor(p)
 p.CanCollide=false; p.CanQuery=false; p.CastShadow=false; return p
end
local function triangle(parent,name,a,b,c,color)
 local ab,ac,bc=b-a,c-a,c-b
 if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
 elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 if bc.Magnitude<0.001 or ac:Cross(ab).Magnitude<0.001 then return end
 local right=ac:Cross(ab).Unit; local back=bc.Unit; local up=back:Cross(right).Unit
 local h=math.abs(ab:Dot(up))
 for _,s in {{(a+b)/2,right,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,-back,math.abs(ac:Dot(back))}} do
  if s[4]>0.001 then part(parent,name,V(0.08,h,s[4]),CFrame.fromMatrix(s[1],s[2],up,s[3]),color,nil,"WedgePart") end
 end
end
local function quad(parent,name,a,b,c,d,color)
 triangle(parent,name,a,b,c,color); triangle(parent,name,a,c,d,color)
end
local function shade(color,n) return color:Lerp(n>0 and Color3.new(1,1,1) or Color3.new(0,0,0),math.abs(n)) end
local function peak(parent,name,origin,width,height,depth,color,sides)
 local m=model(name,parent); local n=sides or 7; local apex=origin+V(width*0.08,height,-depth*0.08)
 for i=1,n do
  local a,b=(i-1)*math.pi*2/n,i*math.pi*2/n
  local p=origin+V(math.cos(a)*width/2,0,math.sin(a)*depth/2)
  local q=origin+V(math.cos(b)*width/2,0,math.sin(b)*depth/2)
  triangle(m,"Facet",p,q,apex,shade(color,math.sin(a+0.6)*0.1))
  triangle(m,"Base",origin,q,p,color)
 end
 m.WorldPivot=CF(origin); return m
end
local function blob(parent,name,cf,size,color,n)
 local m=model(name,parent); n=n or 8
 local rings={}; local levels={{-0.38,0.64},{0,1},{0.34,0.72}}
 for j,l in levels do
  rings[j]={}
  for i=1,n do local a=2*math.pi*(i-1)/n
   rings[j][i]=cf:PointToWorldSpace(V(math.cos(a)*size.X/2*l[2],l[1]*size.Y,math.sin(a)*size.Z/2*l[2]))
  end
 end
 for i=1,n do
  local k=i%n+1; local col=shade(color,math.sin(i*2.7)*0.07)
  triangle(m,"Facet",cf:PointToWorldSpace(V(0,-size.Y/2,0)),rings[1][k],rings[1][i],col)
  for j=1,2 do quad(m,"Facet",rings[j][i],rings[j][k],rings[j+1][k],rings[j+1][i],col) end
  triangle(m,"Facet",rings[3][i],rings[3][k],cf:PointToWorldSpace(V(0,size.Y/2,0)),shade(col,0.06))
 end
 m.WorldPivot=cf; return m
end
local function beam(parent,name,a,b,width,color)
 return part(parent,name,V(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color)
end
local function glow(p,phase)
 decor(p); p.Material=Enum.Material.Neon; p:SetAttribute("PulsePhase",phase or 0)
 CollectionService:AddTag(p,"PaperFlightGlow"); return p
end
local function tree(parent,pos,scale,variant)
 local m=model(variant==1 and "CoralCanopy" or "SageCypress",parent)
 part(m,"Trunk",V(2.6,13,2.6)*scale,CF(pos+V(0,6,0)*scale),C.wood)
 local col=variant==1 and C.coral or C.leaf
 if variant==1 then blob(m,"FacetedCanopy",CF(pos+V(0,17,0)*scale),V(23,18,20)*scale,col,6)
 else
  peak(m,"LowerCrown",pos+V(0,8,0)*scale,19*scale,24*scale,19*scale,col,6)
  peak(m,"UpperCrown",pos+V(0,19,0)*scale,13*scale,19*scale,13*scale,shade(col,0.1),6)
 end
 m.WorldPivot=CF(pos); return m
end
-- A broad sculpted island with individually shaded triangular terrain facets.
local terrain=model("Terrain")
local ocean=part(terrain,"QuietSea",V(4200,5,4200),CF(0,-8,-400),C.water)
ocean.Reflectance=0.06
local land=model("MeadowIsland",terrain)
local n=24; local inner,outer,shore={},{},{}
for i=1,n do
 local a=(i-1)*math.pi*2/n; local irregular=1+rng:NextNumber(-0.09,0.09)
 inner[i]=V(math.cos(a)*200,34+rng:NextNumber(-3,3),-405+math.sin(a)*540)
 outer[i]=V(math.cos(a)*360*irregular,17+rng:NextNumber(-3,3),-405+math.sin(a)*760*irregular)
 shore[i]=V(outer[i].X*1.045,-5,-405+(outer[i].Z+405)*1.035)
end
for i=1,n do local k=i%n+1
 triangle(land,"Meadow",V(0,34,-405),inner[i],inner[k],shade(C.grass,rng:NextNumber(-0.045,0.05)))
 quad(land,"MeadowSlope",inner[i],outer[i],outer[k],inner[k],shade(C.grass,rng:NextNumber(-0.09,0.08)))
 quad(land,"SandstoneCoast",outer[i],shore[i],shore[k],outer[k],C.sand)
end
-- A ribbon of water below the flight route, with sandy banks and stepping stones.
local river=model("TurquoiseRiver",terrain)
local riverPoints={V(-210,35,190),V(-148,35,30),V(-175,35,-140),V(-126,35,-300),V(-172,35,-455),V(-117,35,-630),V(-158,35,-800),V(-190,27,-1040)}
for i=1,#riverPoints-1 do local a,b=riverPoints[i],riverPoints[i+1]
 local cf=CFrame.lookAt((a+b)/2,b)
 part(river,"SandBank",V(37,1.1,(b-a).Magnitude+18),cf*CF(0,-0.9,0),C.sand)
 local water=part(river,"Water",V(27,0.45,(b-a).Magnitude+20),cf,C.water); water.Reflectance=0.07
end
local mountains=model("MountainRange",terrain)
for i,entry in {
 {-330,30,125,210,225,250},{330,25,70,250,290,300},
 {-355,20,-185,230,270,310},{345,20,-310,220,225,280},
 {-330,17,-525,250,305,285},{350,15,-665,245,255,300},
 {-300,10,-905,245,250,240},{265,12,-1000,240,275,280},
 {0,0,-1210,370,340,270},
} do
 local x,y,z,w,h,d=table.unpack(entry)
 peak(mountains,"Mountain"..i,V(x,y,z),w,h,d,i%2==0 and C.rock or C.rockDark)
 peak(mountains,"GreenFoothill"..i,V(x,y,z+50),w*1.1,h*0.43,d*1.1,C.grassDark)
 peak(mountains,"PaleSummit"..i,V(x+w*0.058,y+h*0.72,z-d*0.058),w*0.28,h*0.28,d*0.28,C.pale)
end
-- Mountain shell: the empty tunnel is actual open space, with a continuous roof.
local cave=model("MountainTunnel")
local caveX,caveFloor,front,back=15,35,-83,-285
local profile={V(-64,0,0),V(-64,77,0),V(-47,111,0),V(-24,133,0),V(24,133,0),V(47,111,0),V(64,77,0),V(64,0,0)}
for i=1,#profile-1 do
 local a,b=profile[i],profile[i+1]; local middle=(a+b)/2
 local cf=CF(caveX+middle.X,caveFloor+middle.Y,(front+back)/2)*CFrame.Angles(0,0,math.atan2(b.Y-a.Y,b.X-a.X))
 part(cave,"TunnelVault",V((b-a).Magnitude+4,22,front-back),cf,shade(C.rockDark,i*0.014))
end
part(cave,"TunnelFloor",V(146,5,front-back),CF(caveX,caveFloor-2.5,(front+back)/2),C.sand)
for _,z in {front,back} do
 for i=1,#profile-1 do local a,b=profile[i],profile[i+1]; local middle=(a+b)/2
  part(cave,"PortalStone",V((b-a).Magnitude+2,28,14),CF(caveX+middle.X,caveFloor+middle.Y,z)*CFrame.Angles(0,0,math.atan2(b.Y-a.Y,b.X-a.X)),shade(C.rock,i%3*0.035))
 end
end
peak(cave,"MountainAboveTunnel",V(caveX,181,-181),183,126,252,C.grassDark,8)
peak(cave,"WestButtress",V(-103,32,-188),145,190,265,C.rock,7)
peak(cave,"EastButtress",V(133,32,-182),145,209,270,C.grassDark,7)
peak(cave,"TopFacet",V(23,265,-192),51,42,71,C.grassLight,7)
for i,z in {-104,-150,-205,-260} do
 for _,side in {-1,1} do
  local crystal=peak(cave,"AquaCrystal",V(caveX+side*53,39,z),7,16+i%2*5,7,C.aqua,5)
  for _,p in crystal:GetDescendants() do if p:IsA("BasePart") then glow(p,i*0.6) end end
 end
end
cave.WorldPivot=CF(caveX,caveFloor,(front+back)/2)
cave:SetAttribute("ClearWidthStuds",100); cave:SetAttribute("ClearHeightStuds",118)
-- Ancient open arches, with inset turquoise runes and broken side monuments.
local function ruin(name,center,radius,phase)
 local m=model(name); local ground=34; local spring=center.Y
 for _,side in {-1,1} do
  local x=center.X+side*(radius+8)
  part(m,"Foundation",V(28,7,30),CF(x,ground+3.5,center.Z),C.stone)
  local shaft=part(m,"Pillar",V(14,spring-ground-7,19),CF(x,(spring+ground+7)/2,center.Z),C.stone)
  for j=0,3 do
   part(m,"StoneJoint",V(15,1.1,20),CF(x,ground+12+j*(spring-ground-15)/4,center.Z),shade(C.stone,-0.1))
  end
  for j=0,2 do
   glow(part(m,"PillarRune",V(1.4,6,0.22),CF(x,ground+20+j*10,center.Z+9.65)*CFrame.Angles(0,0,j%2==0 and 0.6 or -0.6),C.aqua),phase+j*0.25)
  end
  part(m,"MossCap",V(17,1.8,22),CF(x,spring,center.Z),C.grassDark)
 end
 local segments=9
 for i=1,segments do local a=(i-0.5)*math.pi/segments
  local pos=center+V(math.cos(a)*(radius+8),math.sin(a)*(radius+8),0)
  local cf=CF(pos)*CFrame.Angles(0,0,a-math.pi/2)
  part(m,"ArchStone",V((radius+8)*math.pi/segments+0.9,16,22),cf,shade(C.stone,i%3*0.035))
  glow(part(m,"ArchRune",V(2.4,5,0.3),cf*CF(0,0,11.2),C.aqua),phase+i*0.1)
 end
 local keystone=center+V(0,radius+10,12)
 glow(part(m,"FloatingSigil",V(7,7,1.2),CF(keystone+V(0,17,0))*CFrame.Angles(0,0,math.pi/4),C.aqua),phase)
 for i=1,5 do
  local side=i%2==0 and 1 or -1
  part(m,"FallenStone",V(10+i,6,11),CF(center.X+side*(radius+25+i*4),ground+3,center.Z+15-i*11)*CFrame.Angles(0,i*0.8,0.14),C.stone)
 end
 m.WorldPivot=CF(center.X,ground,center.Z)
 m:SetAttribute("PassageWidthStuds",radius*2); return m
end
local arch=ruin("SunkenSanctuary",Config.Course[4],31,0)
local finishArch=ruin("SunGate",Config.Course[6],34,1.7)
local ruins=model("RuinedCourtyard")
for i=1,7 do
 local side=i%2==0 and 1 or -1; local x=-75+side*(67+i%3*13); local z=-485-i*19
 local h=24+(i%3)*12
 part(ruins,"ColumnFoot",V(18,5,18),CF(x,37,z),C.stone)
 part(ruins,"BrokenColumn",V(10,h,10),CF(x,39+h/2,z)*CFrame.Angles(0,i*0.2,0),shade(C.stone,-0.025))
 part(ruins,"Moss",V(11,2,11),CF(x,40+h,z),C.grassDark)
end
-- A gentle long-neck dinosaur straddles the third checkpoint.
local dinosaur=model("WillowbackDinosaur")
local d=V(-32,35,-370)
local skin=Color3.fromRGB(136,181,159)
blob(dinosaur,"FacetedBody",CF(d+V(0,118,0)),V(150,55,86),skin,10)
blob(dinosaur,"CreamBelly",CF(d+V(0,103,0)),V(131,22,67),C.sand,8)
for _,x in {-47,47} do for _,z in {-30,30} do
 part(dinosaur,"ColumnLeg",V(22,119,23),CF(d+V(x,60.5,z))*CFrame.Angles(0,0,-x/1400),skin)
 blob(dinosaur,"RoundFoot",CF(d+V(x*1.04,7,z)),V(28,15,31),skin,6)
 for toe=-1,1 do part(dinosaur,"Toe",V(4,3.5,5),CF(d+V(x*1.04+toe*6,4,z+15)),C.pale) end
end end
local neck={V(51,127,0),V(72,155,0),V(79,184,0),V(79,211,0)}
for i=1,#neck-1 do
 local a,b=d+neck[i],d+neck[i+1]
 blob(dinosaur,"NeckSegment"..i,CFrame.lookAt((a+b)/2,b)*CFrame.Angles(math.pi/2,0,0),V(28-i*3,(b-a).Magnitude+13,30-i*3),skin,7)
end
blob(dinosaur,"FriendlyHead",CF(d+V(90,215,0)),V(43,27,30),shade(skin,0.08),8)
blob(dinosaur,"Muzzle",CF(d+V(108,210,0)),V(23,17,28),shade(skin,0.16),6)
for _,z in {-14,14} do
 decor(part(dinosaur,"Eye",V(4.8,6,1.2),CF(d+V(92,220,z)),Color3.fromRGB(55,76,73)))
 decor(part(dinosaur,"EyeSparkle",V(1.5,1.7,1.4),CF(d+V(93,221.5,z)),C.pale))
 decor(part(dinosaur,"Blush",V(7,3,0.8),CF(d+V(96,213,z*1.03)),C.coral))
 beam(dinosaur,"Smile",d+V(105,207,z*0.92),d+V(116,208,z*0.8),0.75,Color3.fromRGB(84,119,100))
end
local tail={V(-61,116,0),V(-91,109,0),V(-117,93,0),V(-145,86,0)}
for i=1,#tail-1 do local a,b=d+tail[i],d+tail[i+1]
 blob(dinosaur,"TailSegment"..i,CFrame.lookAt((a+b)/2,b)*CFrame.Angles(math.pi/2,0,0),V(26-i*6,(b-a).Magnitude+8,26-i*6),skin,6)
end
for i=1,8 do
 peak(dinosaur,"GoldenBackPlate",d+V(-58+i*14,143-math.abs(4-i)*1.3,0),12,10,10,C.sand,4)
end
dinosaur.WorldPivot=CF(d); dinosaur:SetAttribute("BellyClearanceStuds",92)
-- A second giant animal: an ancient meadow tortoise with a faceted shell.
-- Legs sit well outside the ring; shell underside is above the flying corridor.
local turtle=model("MeadowTortoise")
local t=V(5,35,-700)
blob(turtle,"FacetedShell",CF(t+V(0,125,0)),V(146,76,112),Color3.fromRGB(114,161,139),10)
blob(turtle,"WarmPlastron",CF(t+V(0,101,0)),V(131,20,98),C.sand,8)
for _,x in {-62,62} do for _,z in {-32,32} do
 local p=part(turtle,"SturdyLeg",V(22,126,25),CF(t+V(x,63,z))*CFrame.Angles(0,0,-x/700),Color3.fromRGB(166,189,145))
 blob(turtle,"Foot",CF(t+V(x*1.06,7,z)),V(32,15,33),Color3.fromRGB(166,189,145),6)
 for j=-1,1 do part(turtle,"IvoryToe",V(4,4,5),CF(t+V(x*1.06+j*7,5,z+16)),C.pale) end
end end
blob(turtle,"Neck",CF(t+V(77,99,0)),V(34,30,35),Color3.fromRGB(166,189,145),6)
blob(turtle,"FriendlyHead",CF(t+V(99,102,0)),V(40,31,38),Color3.fromRGB(182,201,155),7)
for _,z in {-17,17} do
 local eye=part(turtle,"Eye",V(5,6,1),CF(t+V(105,108,z)),Color3.fromRGB(56,76,74)); decor(eye)
 decor(part(turtle,"EyeSparkle",V(1.6,1.6,1.2),CF(t+V(106,109.5,z)),C.pale))
 beam(turtle,"Smile",t+V(110,98,z*0.9),t+V(119,101,z*0.75),0.8,Color3.fromRGB(98,122,99))
end
peak(turtle,"Tail",t+V(-82,84,0),34,17,15,Color3.fromRGB(166,189,145),5)
for i=1,5 do
 local a=i*math.pi*2/5
 blob(turtle,"ShellScute",CF(t+V(math.cos(a)*37,156,math.sin(a)*27)),V(29,4,26),shade(C.grassDark,i*0.02),5)
end
tree(turtle,t+V(-14,163,0),0.9,2)
turtle.WorldPivot=CF(t); turtle:SetAttribute("BellyClearanceStuds",90)
-- Launch mesa, wooden deck, and a display of the same plane used in flight.
local launch=model("LaunchMesa")
blob(launch,"Cliff",CF(0,46,180),V(198,120,175),C.rock,10)
blob(launch,"Meadow",CF(0,98,180),V(202,15,181),C.grassLight,10)
local deck=part(launch,"LaunchDeck",V(46,3,62),CF(0,108,125),C.wood,Enum.Material.WoodPlanks)
for _,x in {-24,24} do
 part(launch,"DeckRail",V(1,4,62),CF(x,112,125),C.pale)
 for _,z in {98,125,154} do part(launch,"DeckPost",V(2,18,2),CF(x,100,z),C.wood) end
end
for i=1,4 do decor(part(launch,"RunwayStripe",V(1,0.08,6),CF(0,109.55,105+i*10),C.pale)) end
local sign=part(launch,"WelcomeSign",V(28,13,1),CF(0,121,154),Color3.fromRGB(65,98,99))
local surface=Instance.new("SurfaceGui"); surface.Face=Enum.NormalId.Front; surface.PixelsPerStud=40; surface.Parent=sign
local title=Instance.new("TextLabel"); title.Size=UDim2.fromScale(1,1); title.BackgroundTransparency=1
title.Text="PAPER / FLIGHT\nDREAM VALLEY\n\n"..(Config.ThrowStand and "AIM / CLICK TO THROW" or "SPACE TO LAUNCH"); title.Font=Enum.Font.GothamBold; title.TextSize=65; title.TextColor3=C.pale; title.Parent=surface
-- Sparse groves and rocks frame the course; the center flight path stays open.
local foliage=model("ValleyFoliage")
for i=1,39 do
 local side=i%2==0 and 1 or -1
 local pos=V(side*rng:NextNumber(200,265),25,rng:NextNumber(-990,110))
 tree(foliage,pos,rng:NextNumber(0.6,1.4),i%5==0 and 1 or 2)
end
for i=1,14 do
 local side=i%2==0 and 1 or -1; local pos=V(side*rng:NextNumber(120,240),32,rng:NextNumber(-1000,50))
 blob(foliage,"RiverStone",CF(pos)*CFrame.Angles(0,i,0),V(15,12,19)*rng:NextNumber(0.7,1.5),C.rock,5)
end
tree(launch,V(-54,105,194),1.2,1); tree(launch,V(50,105,215),1.4,2)
-- Ring names and centers remain compatible with the existing server and client.
local checkpoints=Instance.new("Folder"); checkpoints.Name="Checkpoints"; checkpoints.Parent=world
for i,center in Config.Course do
 local ring=model("Ring"..i,checkpoints)
 for segment=1,32 do local a=segment/32*math.pi*2
  local p=part(ring,"Arc",V(0.65,2*math.pi*Config.RingRadius/32+0.15,0.65),CF(center+V(math.cos(a)*Config.RingRadius,math.sin(a)*Config.RingRadius,0))*CFrame.Angles(0,0,a),C.aqua,Enum.Material.Neon)
  decor(p)
 end
 local anchor=decor(part(ring,"Marker",V(1,1,1),CF(center+V(0,24,0)),C.pale)); anchor.Transparency=1
 local billboard=Instance.new("BillboardGui"); billboard.Size=UDim2.fromOffset(160,40); billboard.MaxDistance=300; billboard.Parent=anchor
 local text=Instance.new("TextLabel"); text.Size=UDim2.fromScale(1,1); text.BackgroundTransparency=1; text.Font=Enum.Font.GothamBold; text.TextSize=25
 text.Text=i==#Config.Course and "FINISH" or string.format("%02d",i); text.TextColor3=C.pale; text.Parent=billboard
end
local plane=model("Plane",nil); plane.Parent=nil
local keel=part(plane,"Fold",V(0.14,1.15,9),CF(0,-0.4,0),Color3.fromRGB(196,216,204),nil,"WedgePart")
plane.PrimaryPart=keel
-- Explicit triangles meet at the nose (-Z); slight dihedral creates the paper fold.
triangle(plane,"LeftWing",V(0,0,-4.5),V(-5.5,0.45,4.5),V(0,0,3.0),C.paper)
triangle(plane,"RightWing",V(0,0,-4.5),V(0,0,3.0),V(5.5,0.45,4.5),Color3.fromRGB(234,241,219))
triangle(plane,"LeftFold",V(0,0,-4.5),V(-1.05,0.1,4.1),V(0,-0.8,4.1),Color3.fromRGB(222,211,177))
triangle(plane,"RightFold",V(0,0,-4.5),V(0,-0.8,4.1),V(1.05,0.1,4.1),Color3.fromRGB(235,224,191))
for _,p in plane:GetDescendants() do if p:IsA("BasePart") then decor(p) end end
for _,x in {-5,5} do
 local a=Instance.new("Attachment"); a.Position=V(x,0.8,4); a.Parent=keel
 local b=Instance.new("Attachment"); b.Position=V(x,0.95,4); b.Parent=keel
 local trail=Instance.new("Trail"); trail.Attachment0=a; trail.Attachment1=b; trail.Lifetime=0.7; trail.MinLength=0.2
 trail.Color=ColorSequence.new(C.pale); trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,1)}); trail.Parent=keel
end
plane:PivotTo(CF(0,0,0))
local display=plane:Clone(); display.Name="PaperPlaneDisplay"; display.Parent=launch
display:ScaleTo(1.8); display:PivotTo(CF(-40,116,159)*CFrame.Angles(0,0.4,-0.12))
local old=workspace:FindFirstChild("PaperFlightWorld")
if old then
 local backups=SS:FindFirstChild("PaperFlightBackups") or Instance.new("Folder")
 backups.Name="PaperFlightBackups"; backups.Parent=SS
 old.Name="World_"..tostring(os.time()); old.Parent=backups
end
world.Parent=workspace
local oldPlane=RS.PaperFlight:FindFirstChild("Plane")
if oldPlane then oldPlane:Destroy() end
plane.Parent=RS.PaperFlight
-- Keep reusable, origin-centered assets alongside the complete arranged scene.
local library=SS:FindFirstChild("PaperFlightAssets")
if library then library:Destroy() end
library=Instance.new("Folder"); library.Name="PaperFlightAssets"; library.Parent=SS
for _,source in {cave,dinosaur,turtle,arch,finishArch,mountains.Mountain1,foliage:FindFirstChild("SageCypress"),foliage:FindFirstChild("CoralCanopy"),plane} do
 if source then
  local copy=source:Clone(); copy:PivotTo(CF(0,0,0)); copy.Parent=library
 end
end
local spawn=workspace:FindFirstChildOfClass("SpawnLocation")
if spawn then spawn.CFrame=CF(0,111,142); spawn.Size=V(6,1,6); spawn.Transparency=1; spawn.CanCollide=false; spawn.Neutral=true; spawn.Duration=0 end
local base=workspace:FindFirstChild("Baseplate")
if base then base.Transparency=1; base.CanCollide=false; base.CanQuery=false end
Lighting.ClockTime=15.7; Lighting.Brightness=2.4
Lighting.Ambient=Color3.fromRGB(155,163,169); Lighting.OutdoorAmbient=Color3.fromRGB(173,183,176)
Lighting.EnvironmentDiffuseScale=0.65; Lighting.EnvironmentSpecularScale=0.3
local atmosphere=Lighting:FindFirstChild("PaperAtmosphere") or Instance.new("Atmosphere")
atmosphere.Name="PaperAtmosphere"; atmosphere.Density=0.19; atmosphere.Offset=0.1
atmosphere.Color=Color3.fromRGB(228,237,225); atmosphere.Decay=Color3.fromRGB(169,190,193); atmosphere.Glare=0.15; atmosphere.Haze=1.0; atmosphere.Parent=Lighting
local bloom=Lighting:FindFirstChild("PaperBloom") or Instance.new("BloomEffect")
bloom.Name="PaperBloom"; bloom.Intensity=0.18; bloom.Size=24; bloom.Threshold=1.3; bloom.Parent=Lighting
local grading=Lighting:FindFirstChild("PaperColor") or Instance.new("ColorCorrectionEffect")
grading.Name="PaperColor"; grading.Saturation=0.04; grading.Contrast=0.03; grading.TintColor=Color3.fromRGB(255,249,237); grading.Parent=Lighting
workspace.CurrentCamera.CFrame=CFrame.lookAt(V(760,670,590),V(0,75,-365))
return "Dream Valley built. Previous world preserved in ServerStorage.PaperFlightBackups."
