-- Exploration-world rebuild. Prior part-based worlds are archived before the swap.
-- Terrain is generated only inside this game's authored archipelago footprint.
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local Lighting=game:GetService("Lighting")
local Config=require(RS.PaperFlight.Config)
local World=require(RS.PaperFlight.WorldData)
local Landscape=require(RS.PaperFlight.Landscape)
local V,CF=Vector3.new,CFrame.new
local rng=Random.new(70421)
local folder=Instance.new("Folder");folder.Name="PaperFlightWorld"
local function model(name,parent)
 local m=Instance.new("Model");m.Name=name;m.Parent=parent or folder;return m
end
local function part(parent,name,size,cf,color,material,class)
 local p=Instance.new(class or "Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color
 p.Material=material or Enum.Material.SmoothPlastic;p.Anchored=true;p.CanTouch=false
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
local function decor(p) p.CanCollide=false;p.CanQuery=false;return p end
local function triangle(parent,name,a,b,c,color)
 local ab,ac,bc=b-a,c-a,c-b
 if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
 elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 if bc.Magnitude<0.001 or ac:Cross(ab).Magnitude<0.001 then return end
 local right=ac:Cross(ab).Unit;local back=bc.Unit;local up=back:Cross(right).Unit
 local h=math.abs(ab:Dot(up))
 for _,s in {{(a+b)/2,right,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,-back,math.abs(ac:Dot(back))}} do
  if s[4]>0.001 then part(parent,name,V(0.075,h,s[4]),CFrame.fromMatrix(s[1],s[2],up,s[3]),color,nil,"WedgePart") end
 end
end
local function quad(parent,name,a,b,c,d,col)
 triangle(parent,name,a,b,c,col);triangle(parent,name,a,c,d,col)
end
local function beam(parent,name,a,b,width,col)
 return part(parent,name,V(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),col)
end
local function shell(parent,name,cf,size,color)
 local m=model(name,parent);local rings={};local n=16;local bands=5
 for j=1,bands-1 do
  rings[j]={};local latitude=-math.pi/2+j/bands*math.pi
  for i=1,n do local a=(i-1)/n*math.pi*2
   rings[j][i]=cf:PointToWorldSpace(V(math.cos(a)*math.cos(latitude)*size.X/2,math.sin(latitude)*size.Y/2,math.sin(a)*math.cos(latitude)*size.Z/2))
  end
 end
 for i=1,n do local k=i%n+1
  local shade=color:Lerp(Color3.fromRGB(172,151,94),0.04+0.05*(i%3))
  triangle(m,"FoldedFacet",cf:PointToWorldSpace(V(0,-size.Y/2,0)),rings[1][k],rings[1][i],shade)
  for j=1,#rings-1 do quad(m,"FoldedFacet",rings[j][i],rings[j][k],rings[j+1][k],rings[j+1][i],shade) end
  triangle(m,"FoldedFacet",rings[#rings][i],rings[#rings][k],cf:PointToWorldSpace(V(0,size.Y/2,0)),shade)
 end
 return m
end
-- Generate a continuous height field, rather than overlapping spherical bumps.
local terrain=workspace.Terrain
local backups=SS:FindFirstChild("PaperFlightBackups") or Instance.new("Folder")
backups.Name="PaperFlightBackups";backups.Parent=SS
if not terrain:GetAttribute("PaperArchipelagoV2") then
 if terrain:GetAttribute("PaperArchipelagoV1") and not backups:FindFirstChild("TerrainBeforeV2") then
  local saved=terrain:CopyRegion(Region3int16.new(Vector3int16.new(-650,-150,-1000),Vector3int16.new(650,225,400)))
  saved.Name="TerrainBeforeV2";saved.Parent=backups
 end
 -- Clear only the previous authored footprint; preserve unrelated terrain outside it.
 for x=-2600,2600-1,512 do for z=-4000,1600-1,512 do for y=-32,900-1,512 do
  local size=V(math.min(512,2600-x),math.min(512,900-y),math.min(512,1600-z))
  terrain:FillBlock(CF(V(x,y,z)+size/2),size,Enum.Material.Air)
 end end;task.wait() end
 local chunk=256;local cells=64;local completed=0
 for x0=-4352,4096,chunk do for z0=-7424,1280,chunk do
  local heights,surfaces={},{};local low,high=math.huge,-math.huge
  for ix=1,cells do
   heights[ix]={};surfaces[ix]={}
   local x=x0+(ix-0.5)*4
   for iz=1,cells do
    local z=z0+(iz-0.5)*4
    local h,rock=Landscape.height(x,z)
    heights[ix][iz]=h;low=math.min(low,h);high=math.max(high,h)
    local patch=math.noise(x/140,z/160)>0.28
    surfaces[ix][iz]=h<17 and Enum.Material.Sand or (rock or patch) and Enum.Material.Rock or Enum.Material.Grass
   end
  end
  if high>-12 then
   local bottom=math.max(-32,math.floor(low/4)*4-4)
   local top=math.ceil(high/4)*4+4
   -- Fill the uniform interior in one operation, then write only the changing surface band.
   if bottom>-32 then
    terrain:FillBlock(CF(x0+chunk/2,(bottom-32)/2,z0+chunk/2),V(chunk,bottom+32,chunk),Enum.Material.Rock)
   end
   local materials,occupancy={},{}
   local ny=(top-bottom)/4
   for ix=1,cells do
    materials[ix]={};occupancy[ix]={}
    for iy=1,ny do
     local mats,occ=table.create(cells),table.create(cells)
     local y=bottom+(iy-1)*4
     for iz=1,cells do
      local amount=math.clamp((heights[ix][iz]-y)/4,0,1)
      mats[iz]=amount>0 and surfaces[ix][iz] or Enum.Material.Air;occ[iz]=amount
     end
     materials[ix][iy]=mats;occupancy[ix][iy]=occ
    end
   end
   terrain:WriteVoxels(Region3.new(V(x0,bottom,z0),V(x0+chunk,top,z0+chunk)),4,materials,occupancy)
  end
  completed+=1;terrain:SetAttribute("PaperBuildProgress",completed.."/1190 terrain tiles")
  if completed%8==0 then task.wait() end
 end end
 -- Carve actual open corridors through terrain, including both ends of each mountain.
 for _,tunnel in Landscape.Tunnels do
  for offset=-tunnel.length/2,tunnel.length/2,20 do
   terrain:FillBall(tunnel.center+tunnel.normal*offset,tunnel.radius,Enum.Material.Air)
  end
 end
 terrain:SetAttribute("PaperArchipelagoV2",true)
end
terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(73,143,105))
terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(112,116,125))
terrain:SetMaterialColor(Enum.Material.Sand,Color3.fromRGB(214,197,160))
-- Flat water and smooth grass match the reference's broad, readable surfaces.
pcall(function() terrain.Decoration=false end)
local sea=model("Sea")
-- Roblox caps individual Part dimensions, so use aligned tiles for the full ocean.
for x=-5000,5000,2000 do for z=-7800,2200,2000 do
 local water=part(sea,"Water",V(2000,12,2000),CF(x,-7,z),Color3.fromRGB(101,151,186),Enum.Material.SmoothPlastic)
 water.Reflectance=0.08
end end
local terrainParams=RaycastParams.new();terrainParams.FilterType=Enum.RaycastFilterType.Include;terrainParams.FilterDescendantsInstances={terrain}
local function ground(x,z) return Landscape.height(x,z) end
local trees=model("Woodlands")
local function crown(parent,center,size,color)
 local top=center+V(0,size.Y/2,0);local bottom=center-V(0,size.Y/2,0)
 local points={center+V(-size.X/2,0,-size.Z/2),center+V(size.X/2,0,-size.Z/2),center+V(size.X/2,0,size.Z/2),center+V(-size.X/2,0,size.Z/2)}
 for i=1,4 do local n=i%4+1
  triangle(parent,"CanopyFold",top,points[i],points[n],color)
  triangle(parent,"CanopyFold",bottom,points[n],points[i],color:Lerp(Color3.fromRGB(37,75,60),0.15))
 end
end
local function treeAt(x,z,index)
 local y,rock=ground(x,z)
 if y<3 or y>180 or rock or (V(x,0,z)-V(-550,0,580)).Magnitude<200 then return end
 local tree=model("Tree",trees);tree.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local h=rng:NextNumber(28,49)
 local brown=Color3.fromRGB(99,78,63)
 if y<22 then
  -- Slender palms on sand; folded fronds have a clear silhouette from above.
  local base=V(x,y,z);local bend=V(x+4,y+h*0.55,z+2);local tip=V(x+8,y+h,z+1)
  beam(tree,"Trunk",base,bend,2.8,brown);beam(tree,"Trunk",bend,tip,2.1,brown)
  for j=1,7 do
   local a=j*math.pi*2/7
   local radial=V(math.cos(a),0,math.sin(a));local side=V(-radial.Z,0,radial.X)*4
   local mid=tip+radial*11+V(0,3,0);local finish=tip+radial*24-V(0,6,0)
   triangle(tree,"PalmFrond",tip,mid+side,finish,Color3.fromRGB(53,126,79))
   triangle(tree,"PalmFrond",tip,finish,mid-side,Color3.fromRGB(68,151,88))
  end
 elseif index%3==0 then
  part(tree,"Trunk",V(3,h*0.65,3),CF(x,y+h*0.325,z),brown,Enum.Material.Wood)
  crown(tree,V(x,y+h*0.59,z),V(h*0.44,h*1.04,h*0.44),Color3.fromRGB(36,87,68))
 else
  local tip=V(x+3,y+h*0.72,z)
  beam(tree,"Trunk",V(x,y,z),tip,3.2,brown)
  beam(tree,"Branch",V(x+1,y+h*0.4,z),tip+V(-8,-2,3),1.7,brown)
  crown(tree,tip,V(h*0.92,h*0.43,h*0.73),Color3.fromRGB(42+index%4*5,117+index%3*7,79))
 end
end
for i=1,760 do
 treeAt(rng:NextNumber(-3800,3800),rng:NextNumber(-7150,1050),i)
end
-- A few nearby groves keep the introductory valley visually grounded.
for i=1,100 do treeAt(rng:NextNumber(-1250,600),rng:NextNumber(-1750,150),i) end
local deck=model("LaunchCliff")
part(deck,"StoneDeck",V(110,8,125),CF(-550,353,586),Color3.fromRGB(132,142,152),Enum.Material.Slate)
for _,x in {-606,-494} do
 part(deck,"Rail",V(2,5,85),CF(x,363,590),Color3.fromRGB(92,72,49),Enum.Material.Wood)
 for _,z in {550,590,630} do part(deck,"Post",V(4,11,4),CF(x,360,z),Color3.fromRGB(82,61,42),Enum.Material.Wood) end
end
local pad=part(deck,"ThrowPad",V(14,0.25,14),CF(-550,357.2,534),Color3.fromRGB(105,244,211),Enum.Material.Neon)
for _,x in {-577,-523} do
 local crate=part(deck,"SupplyCrate",V(11,11,11),CF(x,362.5,612),Color3.fromRGB(111,83,53),Enum.Material.WoodPlanks)
 for _,off in {-4.6,4.6} do part(deck,"CrateBand",V(0.7,11.2,11.2),crate.CFrame*CF(off,0,0),Color3.fromRGB(153,121,76),Enum.Material.Wood) end
end
local sign=part(deck,"Instructions",V(35,12,1),CF(-550,374,638),Color3.fromRGB(42,54,61),Enum.Material.Wood)
local surface=Instance.new("SurfaceGui");surface.Face=Enum.NormalId.Front;surface.PixelsPerStud=35;surface.Parent=sign
local text=Instance.new("TextLabel");text.BackgroundTransparency=1;text.Size=UDim2.fromScale(1,1);text.Font=Enum.Font.GothamBold;text.TextSize=55
text.Text="PAPER SKIES\nCollect gold. Catch rising air.\nF TO LAUNCH";text.TextColor3=Color3.fromRGB(239,238,219);text.Parent=surface
local rings=Instance.new("Folder");rings.Name="Rings";rings.Parent=folder
for _,ring in World.Rings do
 local m=model("Ring"..ring.id,rings);m:SetAttribute("RingId",ring.id);m:SetAttribute("Trail",ring.group)
 m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local cf=CFrame.lookAt(ring.position,ring.position+ring.normal)
 -- Thin, open neon hoops: the middle contains no physical or invisible collision part.
 for j=1,48 do
  local a=(j-1)/48*math.pi*2;local b=j/48*math.pi*2
  local pa=cf:PointToWorldSpace(V(math.cos(a)*ring.radius,math.sin(a)*ring.radius,0))
  local pb=cf:PointToWorldSpace(V(math.cos(b)*ring.radius,math.sin(b)*ring.radius,0))
  local segment=decor(beam(m,"NeonArc",pa,pb,0.9,ring.color));segment.Material=Enum.Material.Neon
 end
end
local currents=model("ThermalMarkers")
for _,zone in World.Thermals do
 local y=ground(zone.center.X,zone.center.Z)
 for j=1,18 do
  local a=j*0.65;local pos=zone.center+V(math.cos(a)*zone.radius*0.38,y+10+j*16,math.sin(a)*zone.radius*0.38)
  local p=decor(part(currents,"RisingAir",V(0.3,6,0.3),CF(pos)*CFrame.Angles(0,0,-0.3),Color3.fromRGB(207,244,230),Enum.Material.Neon));p.Transparency=0.58
 end
end
local animals=model("PaperAnimals")
local function lion(name,origin,scale,heading)
 local m=model(name,animals);local cf=CF(origin)*CFrame.Angles(0,heading,0)
 local function p(v) return cf:PointToWorldSpace(v*scale) end
 local yellow=Color3.fromRGB(246,212,96);local pale=Color3.fromRGB(255,234,146)
 shell(m,"FoldedTorso",cf*CF(0,13*scale,0),V(13,12,24)*scale,yellow)
 shell(m,"FoldedHead",cf*CF(0,23*scale,-16*scale),V(12,12,10)*scale,pale)
 for i=1,20 do local a=i/20*math.pi*2;local b=(i+1)/20*math.pi*2
  local top=V(math.cos(a)*10,23+math.sin(a)*10,-13)
  local next=V(math.cos(b)*10,23+math.sin(b)*10,-13)
  local innerA=V(math.cos(a)*5,23+math.sin(a)*5,-18)
  local innerB=V(math.cos(b)*5,23+math.sin(b)*5,-18)
  local ridge=V(math.cos((a+b)/2)*8,23+math.sin((a+b)/2)*8,-20)
  triangle(m,"ManeFold",p(top),p(next),p(ridge),yellow)
  triangle(m,"ManeFold",p(next),p(innerB),p(ridge),pale)
  triangle(m,"ManeFold",p(innerB),p(innerA),p(ridge),yellow)
  triangle(m,"ManeFold",p(innerA),p(top),p(ridge),pale)
 end
 for _,x in {-4.5,4.5} do for _,z in {-8,8} do
  local top=V(x,13,z);local bottom=V(x*1.13,1,z-1)
  local t={top+V(-2,0,-2),top+V(2,0,-2),top+V(2,0,2),top+V(-2,0,2)}
  local b={bottom+V(-1,0,-2),bottom+V(1,0,-2),bottom+V(1,0,1),bottom+V(-1,0,1)}
  for k=1,4 do local n=k%4+1;quad(m,"LegFold",p(t[k]),p(t[n]),p(b[n]),p(b[k]),k%2==0 and yellow or pale) end
 end end
 for _,side in {-1,1} do
  triangle(m,"Ear",p(V(side*3,27,-15)),p(V(side*6,33,-15)),p(V(side*6,26,-18)),yellow)
  decor(part(m,"Eye",V(0.6,0.9,0.4)*scale,CF(p(V(side*3.2,24,-20.5))),Color3.fromRGB(70,58,39)))
 end
 triangle(m,"Nose",p(V(-1.5,22,-22)),p(V(1.5,22,-22)),p(V(0,20.5,-22)),Color3.fromRGB(112,82,43))
 local tail={V(0,16,11),V(0,13,21),V(0,16,28),V(0,21,30)}
 for i=1,#tail-1 do
  quad(m,"TailFold",p(tail[i]+V(-0.8,0,0)),p(tail[i]+V(0.8,0,0)),p(tail[i+1]+V(0.4,0,0)),p(tail[i+1]+V(-0.4,0,0)),pale)
 end
 m.WorldPivot=cf;m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;m:SetAttribute("Style","Folded paper");return m
end
lion("GoldenPaperLion",V(760,ground(760,-750),-750),4.2,-0.5)
lion("PaperLionCub",V(930,ground(930,-630),-630),1.6,-0.2)
local function crane(origin,scale,heading)
 local m=model("OrigamiCrane",animals);local cf=CF(origin)*CFrame.Angles(0,heading,0)
 local function p(v) return cf:PointToWorldSpace(v*scale) end
 local ivory=Color3.fromRGB(250,244,224);local shadow=Color3.fromRGB(218,224,212)
 for _,side in {-1,1} do
  triangle(m,"WingFold",p(V(0,7,0)),p(V(side*20,15,4)),p(V(side*4,5,10)),ivory)
  triangle(m,"UnderFold",p(V(0,7,0)),p(V(side*4,5,10)),p(V(0,3,9)),shadow)
  triangle(m,"Neck",p(V(0,7,0)),p(V(side*1,19,-4)),p(V(side*1,10,-1)),ivory)
  triangle(m,"Beak",p(V(side*1,19,-4)),p(V(0,17,-13)),p(V(0,17,-3)),shadow)
  triangle(m,"Tail",p(V(0,7,6)),p(V(side*1,19,18)),p(V(0,4,10)),ivory)
 end
end
crane(V(-1120,ground(-1120,-1200)+6,-1200),3.2,0.8)
crane(V(160,ground(160,-2950)+20,-2950),4,-0.4)
-- Preserve the prior world and generated asset experiment for later inspection.
-- The terrain snapshot and prior scenery are retained together.
local old=workspace:FindFirstChild("PaperFlightWorld");if old then old.Name="BeforeExploration_"..os.time();old.Parent=backups end
local candidate=workspace:FindFirstChild("PaperLion");if candidate then candidate.Name="GeneratedLionCandidate";candidate.Parent=backups end
folder.Parent=workspace
local spawn=workspace:FindFirstChildOfClass("SpawnLocation")
if spawn then spawn.CFrame=CF(Config.ThrowStand);spawn.Transparency=1;spawn.CanCollide=false;spawn.Duration=0 end
local base=workspace:FindFirstChild("Baseplate");if base then base.Transparency=1;base.CanCollide=false;base.CanQuery=false end
Lighting.ClockTime=16.4;Lighting.Brightness=2.4;Lighting.Ambient=Color3.fromRGB(127,146,159);Lighting.OutdoorAmbient=Color3.fromRGB(161,178,184)
-- Keep a single atmosphere; the default and earlier art effects otherwise obscure the valley.
for _,effect in Lighting:GetChildren() do
 if (effect:IsA("Atmosphere") and effect.Name~="PaperAtmosphere")
  or (effect:IsA("BloomEffect") and effect.Name~="PaperBloom")
  or effect:IsA("DepthOfFieldEffect") then effect.Parent=backups end
end
local bloom=Lighting:FindFirstChild("PaperBloom") or Instance.new("BloomEffect")
bloom.Name="PaperBloom";bloom.Intensity=0.18;bloom.Size=20;bloom.Threshold=1.4;bloom.Parent=Lighting
local color=Lighting:FindFirstChild("PaperColor") or Instance.new("ColorCorrectionEffect")
color.Name="PaperColor";color.Brightness=0;color.Contrast=0.06;color.Saturation=0.08;color.TintColor=Color3.new(1,1,1);color.Parent=Lighting
local atmosphere=Lighting:FindFirstChild("PaperAtmosphere") or Instance.new("Atmosphere");atmosphere.Name="PaperAtmosphere"
atmosphere.Density=0.17;atmosphere.Haze=0.55;atmosphere.Glare=0.3;atmosphere.Color=Color3.fromRGB(203,221,240);atmosphere.Parent=Lighting
local clouds=terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds");clouds.Cover=0.48;clouds.Density=0.35;clouds.Color=Color3.fromRGB(249,238,219);clouds.Parent=terrain
workspace.CurrentCamera.CFrame=CFrame.lookAt(V(-950,600,920),V(-400,140,-500))
terrain:SetAttribute("PaperBuildProgress","Complete")
return string.format("Exploration world: %d neon rings, six regions, three fly-through rock passages.",#World.Rings)
