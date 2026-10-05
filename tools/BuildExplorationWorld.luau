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
local function shell(parent,name,cf,size,color,segments,latitudes)
 local m=model(name,parent);local rings={};local n=segments or 16;local bands=latitudes or 5
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
if not terrain:GetAttribute("PaperArchipelagoV4") then
 -- Previous V2 terrain is reproducible from commit 5fd61e2; preserve the existing snapshot.
 -- Only clear the authored world bounds, in bounded operations.
 for x=-5376,4864-1,512 do for z=-8960,2816-1,512 do for y=-32,2304-1,512 do
  local size=V(math.min(512,4864-x),math.min(512,2304-y),math.min(512,2816-z))
  terrain:FillBlock(CF(V(x,y,z)+size/2),size,Enum.Material.Air)
 end end;task.wait() end
 local chunk=256;local cells=64;local completed=0
 for x0=-5376,4608,chunk do for z0=-8960,2560,chunk do
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
  completed+=1;terrain:SetAttribute("PaperBuildProgress",completed.."/1840 terrain tiles")
  if completed%8==0 then task.wait() end
 end end
 -- Carve actual open corridors through terrain, including both ends of each mountain.
 for _,tunnel in Landscape.Tunnels do
  for offset=-tunnel.length/2,tunnel.length/2,20 do
   terrain:FillBall(tunnel.center+tunnel.normal*offset,tunnel.radius,Enum.Material.Air)
  end
 end
 terrain:SetAttribute("PaperArchipelagoV4",true)
end
terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(73,143,105))
terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(112,116,125))
terrain:SetMaterialColor(Enum.Material.Sand,Color3.fromRGB(214,197,160))
-- Flat water and smooth grass match the reference's broad, readable surfaces.
pcall(function() terrain.Decoration=false end)
local sea=model("Sea");sea.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
-- Roblox caps individual Part dimensions, so use aligned tiles for the full ocean.
for x=-5000,5000,2000 do for z=-9800,4200,2000 do
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
 -- Keep smaller wildlife and reward approaches clear of randomly placed trees.
 for _,animal in World.Animals do
  if Vector2.new(x-animal.position.X,z-animal.position.Z).Magnitude<95 then return end
 end
 for _,ring in World.Rings do
  local offset=V(x,y,z)-ring.position;local along=offset:Dot(ring.normal)
  local sideways=(offset-ring.normal*along).Magnitude
  if math.abs(along)<100 and sideways<65 then return end
 end
 if y<3 or y>980 or rock or (V(x,0,z)-V(-550,0,580)).Magnitude<200 then return end
 local slope=math.max(math.abs(ground(x+8,z)-ground(x-8,z)),math.abs(ground(x,z+8)-ground(x,z-8)))/16
 if slope>1.1 then return end
 local tree=model("Tree",trees);tree:SetAttribute("Elevation",y);tree.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
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
for i=1,420 do
 treeAt(rng:NextNumber(-4900,4500),rng:NextNumber(-8550,2450),i)
end
-- A few nearby groves keep the introductory valley visually grounded.
for i=1,60 do treeAt(rng:NextNumber(-1250,600),rng:NextNumber(-1750,150),i) end
for _,peak in Landscape.Peaks do
 for i=1,90 do
  local a=rng:NextNumber(0,math.pi*2);local r=rng:NextNumber(0.45,0.98)
  treeAt(peak.x+math.cos(a)*peak.rx*r,peak.z+math.sin(a)*peak.rz*r,i*3)
 end
end
-- Persistent coarse silhouettes make the whole archipelago readable beyond streaming range.
-- Detailed terrain occludes these lower surfaces nearby; the client fades close proxy tiles.
local vista=model("DistantLandscape");vista.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
for x=-5376,4864-256,256 do for z=-8960,2816-256,256 do
 local centerY,_,isMountain=Landscape.height(x+128,z+128)
 if isMountain and centerY>170 then
  local tile=model("VistaTile",vista);tile:SetAttribute("Center",V(x+128,centerY,z+128))
  local function point(px,pz)
   local h=ground(px,pz)
   local low=math.min(h,ground(px+48,pz),ground(px-48,pz),ground(px,pz+48),(ground(px,pz-48)))
   return V(px,math.max(-8,low-28),pz)
  end
  local a,b,c,d=point(x,z),point(x+256,z),point(x+256,z+256),point(x,z+256)
  local _,rock=Landscape.height(x+128,z+128)
  quad(tile,"DistantSurface",a,b,c,d,rock and Color3.fromRGB(105,113,123) or Color3.fromRGB(73,137,101))
  for _,p in tile:GetDescendants() do if p:IsA("BasePart") then decor(p);p.CastShadow=false;p.Transparency=1 end end
 end
end end
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
  local segment=decor(beam(m,"NeonArc",pa,pb,0.28,ring.color));segment.Material=Enum.Material.Neon
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
-- Shared folded construction with distinct silhouettes; open leg spacing is intentional.
local function foldedAnimal(animal)
 local m=model(animal.species..animal.id,animals);m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 m:SetAttribute("Species",animal.species);m:SetAttribute("AnimalId",animal.id)
 local cf=CF(animal.position)*CFrame.Angles(0,animal.heading,0)
 local function p(v) return cf:PointToWorldSpace(v) end
 local colors={Lion=Color3.fromRGB(242,202,78),Elephant=Color3.fromRGB(173,192,208),
  Deer=Color3.fromRGB(202,161,117),Fox=Color3.fromRGB(230,133,71),Giraffe=Color3.fromRGB(233,196,101)}
 local color=colors[animal.species];local light=color:Lerp(Color3.fromRGB(255,246,216),0.3)
 local function shape(name,center,size,col)
  return shell(m,name,cf*CF(center),size,col or color,8,4)
 end
 local bodySize=animal.species=="Elephant" and V(39,32,65) or V(32,25,58)
 shape("FoldedBody",V(0,43,0),bodySize)
 -- Tapered legs touch their actual terrain samples and leave a wide longitudinal corridor.
 for _,x in {-15,15} do for _,z in {-20,20} do
  local foot=p(V(x,0,z));local scaledFoot=animal.position+(foot-animal.position)*animal.scale
  local y=animal.position.Y+(ground(scaledFoot.X,scaledFoot.Z)-animal.position.Y)/animal.scale
  local a=p(V(x,42,z));local b=V(foot.X,y,foot.Z)
  local right=cf.RightVector*3;local back=cf.LookVector*3
  local t={a-right-back,a+right-back,a+right+back,a-right+back}
  local q={b-right*0.7-back,b+right*0.7-back,b+right*0.7+back,b-right*0.7+back}
  for j=1,4 do local k=j%4+1;quad(m,"LegFold",t[j],t[k],q[k],q[j],j%2==0 and color or light) end
 end end
 local head=V(0,55,-36)
 if animal.species=="Giraffe" then
  shape("LongNeck",V(0,78,-24),V(13,70,14),light);head=V(0,113,-35)
  for j=1,6 do
   decor(part(m,"PaperSpot",V(13.2,5,5),cf*CF(0,55+j*8,-25),Color3.fromRGB(158,107,58)))
  end
 end
 shape("FoldedHead",head,animal.species=="Elephant" and V(29,30,28) or V(23,22,27),light)
 for _,side in {-1,1} do
  decor(part(m,"Eye",V(1.1,1.5,0.6),cf*CF(head+V(side*7,2,-12.5)),Color3.fromRGB(42,45,47)))
 end
 if animal.species=="Lion" then
  for i=1,16 do
   local a=i/16*math.pi*2;local b=(i+1)/16*math.pi*2;local mid=(a+b)/2
   local a1=head+V(math.cos(a)*21,math.sin(a)*23,1)
   local b1=head+V(math.cos(b)*21,math.sin(b)*23,1)
   local a2=head+V(math.cos(a)*10,math.sin(a)*11,-9)
   local b2=head+V(math.cos(b)*10,math.sin(b)*11,-9)
   local ridge=head+V(math.cos(mid)*17,math.sin(mid)*18,-13)
   triangle(m,"ManeFold",p(a1),p(b1),p(ridge),color)
   triangle(m,"ManeFold",p(b1),p(b2),p(ridge),light)
   triangle(m,"ManeFold",p(b2),p(a2),p(ridge),color)
   triangle(m,"ManeFold",p(a2),p(a1),p(ridge),light)
  end
 elseif animal.species=="Elephant" then
  for _,side in {-1,1} do
   quad(m,"BroadEar",p(head+V(side*8,10,0)),p(head+V(side*30,8,3)),p(head+V(side*29,-19,1)),p(head+V(side*10,-13,-5)),light)
  end
  -- Trunk curls forward above the fly-through path.
  local points={head+V(0,-3,-13),V(0,34,-54),V(0,29,-66),V(0,39,-72)}
  for i=1,#points-1 do beam(m,"FoldedTrunk",p(points[i]),p(points[i+1]),6-i,color) end
 elseif animal.species=="Deer" then
  for _,side in {-1,1} do
   local root=head+V(side*7,8,1);local tip=root+V(side*10,29,5)
   beam(m,"Antler",p(root),p(tip),1.7,Color3.fromRGB(124,98,72))
   for j=1,3 do
    local at=root:Lerp(tip,j/4)
    beam(m,"AntlerTine",p(at),p(at+V(side*8,9,-3)),1.2,Color3.fromRGB(139,114,82))
   end
  end
 elseif animal.species=="Fox" then
  for _,side in {-1,1} do
   triangle(m,"PointedEar",p(head+V(side*5,5,0)),p(head+V(side*11,29,1)),p(head+V(side*14,3,-6)),color)
  end
  shape("WhiteMuzzle",head+V(0,-6,-12),V(17,10,16),Color3.fromRGB(246,233,207))
  shape("BushyTail",V(7,45,43),V(20,18,39),color)
  shape("TailTip",V(7,46,61),V(14,13,14),Color3.fromRGB(247,237,214))
 else
  for _,side in {-1,1} do
   beam(m,"Ossicone",p(head+V(side*6,8,0)),p(head+V(side*6,20,0)),2,color)
   triangle(m,"Ear",p(head+V(side*8,3,0)),p(head+V(side*23,9,0)),p(head+V(side*12,-3,-2)),light)
  end
 end
 if animal.species~="Fox" then
  beam(m,"Tail",p(V(0,48,27)),p(V(5,34,47)),2,color)
 end
 m.WorldPivot=cf;m:ScaleTo(animal.scale);m:SetAttribute("WildlifeScale",animal.scale)
 if animal.behindPeak then m:SetAttribute("BehindPeak",animal.behindPeak) end
end
for _,animal in World.Animals do foldedAnimal(animal) end
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
return string.format("World: %d small rings, %d wildlife landmarks, varied ridges and a broad launch mesa.",#World.Rings,#World.Animals)
