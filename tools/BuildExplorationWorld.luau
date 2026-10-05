-- Exploration-world rebuild. Prior part-based worlds are archived before the swap.
-- Terrain is generated only inside this game's authored archipelago footprint.
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local Lighting=game:GetService("Lighting")
local Config=require(RS.PaperFlight.Config)
local World=require(RS.PaperFlight.WorldData)
local Landscape=require(RS.PaperFlight.Landscape)
local ReferenceAnimals=require(RS.PaperFlight.ReferenceAnimals)
local Scenery=require(RS.PaperFlight.Scenery)
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
if not terrain:GetAttribute("PaperArchipelagoV5") then
 -- Previous V2 terrain is reproducible from commit 5fd61e2; preserve the existing snapshot.
 -- Only clear the authored world bounds, in bounded operations.
 for x=-5632,4864-1,512 do for z=-8960,5632-1,512 do for y=-32,2304-1,512 do
  local size=V(math.min(512,4864-x),math.min(512,2304-y),math.min(512,5632-z))
  terrain:FillBlock(CF(V(x,y,z)+size/2),size,Enum.Material.Air)
 end end;task.wait() end
 local chunk=256;local cells=64;local completed=0
 for x0=-5632,4352,chunk do for z0=-5376,5376,chunk do
  local heights,surfaces={},{};local low,high=math.huge,-math.huge
  for ix=1,cells do
   heights[ix]={};surfaces[ix]={}
   local x=x0+(ix-0.5)*4
   for iz=1,cells do
    local z=z0+(iz-0.5)*4
    local h,rock=Landscape.height(x,z)
    heights[ix][iz]=h;low=math.min(low,h);high=math.max(high,h)
    local patch=math.noise(x/140,z/160)>0.28
    surfaces[ix][iz]=h<17 and Enum.Material.Sand or (rock or patch) and Enum.Material.Rock or Enum.Material.LeafyGrass
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
  completed+=1;terrain:SetAttribute("PaperBuildProgress",completed.."/1720 terrain tiles")
  if completed%8==0 then task.wait() end
 end end
 -- Carve actual open corridors through terrain, including both ends of each mountain.
 for _,tunnel in Landscape.Tunnels do
  for offset=-tunnel.length/2,tunnel.length/2,20 do
   terrain:FillBall(tunnel.center+tunnel.normal*offset,tunnel.radius,Enum.Material.Air)
  end
 end
 terrain:SetAttribute("PaperArchipelagoV5",true)
end
-- Flat-color, matte ground shares the low-poly foliage style; keep terrain collision intact.
local materials=game:GetService("MaterialService")
local meadow=materials:FindFirstChild("PaperMeadow") or Instance.new("MaterialVariant")
meadow.Name="PaperMeadow";meadow.BaseMaterial=Enum.Material.LeafyGrass
meadow.ColorMap="rbxasset://textures/sky/white.png";meadow.NormalMap=""
meadow.MetalnessMap="rbxasset://textures/blackBkg_square.png"
-- Roblox's bundled solid-white texture gives full roughness without another uploaded asset.
meadow.RoughnessMap="rbxasset://textures/sky/white.png";meadow.StudsPerTile=32;meadow.Parent=materials
for _,face in Enum.TerrainFace:GetEnumItems() do
 local name="Matte"..face.Name
 local detail=meadow:FindFirstChild(name) or Instance.new("TerrainDetail")
 detail.Name=name;detail.Face=face;detail.ColorMap=meadow.ColorMap;detail.NormalMap=""
 detail.RoughnessMap=meadow.RoughnessMap;detail.MetalnessMap=meadow.MetalnessMap
 detail.StudsPerTile=32;detail.Parent=meadow
end
materials:SetBaseMaterialOverride(Enum.Material.LeafyGrass,meadow.Name)
terrain:SetMaterialColor(Enum.Material.LeafyGrass,Color3.fromRGB(135,173,85))
terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(139,141,153))
terrain:SetMaterialColor(Enum.Material.Sand,Color3.fromRGB(214,197,160))
-- Flat water and smooth grass match the reference's broad, readable surfaces.
-- LeafyGrass keeps a meadow surface without the animated Grass blades.
-- Decoration is not scriptable; do not hide a failed property write in pcall.
local sea=model("Sea");sea.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
-- Roblox caps individual Part dimensions, so use aligned tiles for the full ocean.
for x=-6000,6000,2000 do for z=-6000,6000,2000 do
 local water=part(sea,"Water",V(2000,12,2000),CF(x,-7,z),Color3.fromRGB(101,151,186),Enum.Material.SmoothPlastic)
 water.Reflectance=0.08
end end
local terrainParams=RaycastParams.new();terrainParams.FilterType=Enum.RaycastFilterType.Include;terrainParams.FilterDescendantsInstances={terrain}
local function ground(x,z) return Landscape.height(x,z) end
local trees=model("Woodlands")
local function treeAt(x,z,index,extra)
 if extra then
  for _,existing in trees:GetChildren() do
   local base=existing:GetAttribute("BasePosition")
   if Vector2.new(x-base.X,z-base.Z).Magnitude<26 then return end
  end
 end
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
 -- Style selection consumes no randomness, preserving the existing grove locations.
 local blossom=y<400 and (math.noise(x/550,z/550,4)>0.3 or index%17==0)
 local kind=y<22 and "Palm" or blossom and "CherryBlossom" or index%3==0 and "Pine" or index%5==0 and "Birch" or "Broadleaf"
 Scenery.tree(tree,V(x,y,z),h,kind,index*2.4)

end
for i=1,420 do
 treeAt(rng:NextNumber(-5300,4250),rng:NextNumber(-5100,5300),i)
end
-- A few nearby groves keep the introductory valley visually grounded.
for i=1,60 do treeAt(rng:NextNumber(-1250,600),rng:NextNumber(-1750,150),i) end
for _,peak in Landscape.Peaks do
 for i=1,90 do
  local a=rng:NextNumber(0,math.pi*2);local r=rng:NextNumber(0.45,0.98)
  treeAt(peak.x+math.cos(a)*peak.rx*r,peak.z+math.sin(a)*peak.rz*r,i*3)
 end
end
-- Additive pass preserves the original groves and fills more of the wider meadows.
rng=Random.new(90817)
for i=1,360 do treeAt(rng:NextNumber(-5300,4250),rng:NextNumber(-5100,5300),2000+i,true) end
for i=1,160 do treeAt(rng:NextNumber(-1900,1300),rng:NextNumber(-1800,2400),3000+i,true) end
-- Fuller meadow patches share the warm foliage palette while keeping flight lanes open.
local accents=model("MeadowAccents")
local accentRng=Random.new(81312)
-- Voxel terrain renders above the analytical height field; sample its real surface
-- for small flowers/grass rather than burying them inside that interpolation band.
local function surfaceGround(x,z)
 local y=ground(x,z)
 local hit=workspace:Raycast(V(x,y+16,z),V(0,-32,0),terrainParams)
 return hit and hit.Position.Y or y
end
local function accentSite(x,z)
 local y,rock=ground(x,z)
 if y<24 or y>600 or rock then return end
 if Vector2.new(x+550,z-534).Magnitude<220 then return end
 if math.abs(ground(x+7,z)-ground(x-7,z))>5 or math.abs(ground(x,z+7)-ground(x,z-7))>5 then return end
 for _,animal in World.Animals do
  if Vector2.new(x-animal.position.X,z-animal.position.Z).Magnitude<105 then return end
 end
 for _,ring in World.Rings do
  local offset=V(x,y,z)-ring.position;local along=offset:Dot(ring.normal)
  if math.abs(along)<110 and (offset-ring.normal*along).Magnitude<70 then return end
 end
 return V(x,surfaceGround(x,z),z)
end
for i,tree in trees:GetChildren() do
 if i%2~=0 then continue end
 local base=tree:GetAttribute("BasePosition")
 local a=accentRng:NextNumber(0,math.pi*2)
 local spot=accentSite(base.X+math.cos(a)*25,base.Z+math.sin(a)*25)
 if not spot then continue end
 local patch=model("FlowerPatch",accents);patch.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 Scenery.patch(patch,spot,surfaceGround,i*113)
 local rockSpot=accentSite(spot.X+10,spot.Z+8)
 if rockSpot and i%4==0 then
  local stone=model("FacetedStone",accents);stone.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  Scenery.stone(stone,rockSpot,V(accentRng:NextNumber(4,8),accentRng:NextNumber(3,6),accentRng:NextNumber(4,7)),a)
 end
end
-- Persistent coarse silhouettes make the whole archipelago readable beyond streaming range.
-- Detailed terrain occludes these lower surfaces nearby; the client fades close proxy tiles.
local vista=model("DistantLandscape");vista.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
for x=-5632,4608-256,256 do for z=-5376,5632-256,256 do
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
  quad(tile,"DistantSurface",a,b,c,d,rock and Color3.fromRGB(130,134,145) or Color3.fromRGB(125,162,79))
  for _,p in tile:GetDescendants() do if p:IsA("BasePart") then decor(p);p.CastShadow=false;p.Transparency=0 end end
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
local sign=part(deck,"Instructions",V(35,12,1),CF(-550,363,638),Color3.fromRGB(42,54,61),Enum.Material.Wood)
local surface=Instance.new("SurfaceGui");surface.Face=Enum.NormalId.Front;surface.PixelsPerStud=35;surface.Parent=sign
local text=Instance.new("TextLabel");text.BackgroundTransparency=1;text.Size=UDim2.fromScale(1,1);text.Font=Enum.Font.GothamBold;text.TextSize=55
text.Text="PAPER SKIES\nCollect gold. Catch rising air.\nF TO LAUNCH";text.TextColor3=Color3.fromRGB(239,238,219);text.Parent=surface
local rings=Instance.new("Folder");rings.Name="Rings";rings.Parent=folder
for _,ring in World.Rings do
 local m=model("Ring"..ring.id,rings);m:SetAttribute("RingId",ring.id);m:SetAttribute("Trail",ring.group)
 m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local cf=CFrame.lookAt(ring.position,ring.position+ring.normal)
 local summit=ring.group:find("^Summit ")~=nil
 if summit then
  -- Only seven summit rewards stay loaded; the halo reveals their small openings at a distance.
  m.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
  local anchor=decor(part(m,"SummitBeaconAnchor",V(0.1,0.1,0.1),CF(ring.position),ring.color))
  anchor.Transparency=1
  local light=Instance.new("PointLight");light.Name="SummitLight"
  light.Color=ring.color;light.Brightness=2;light.Range=48;light.Shadows=false;light.Parent=anchor
  -- Sparse rim sparkles frame the opening without filling the flight path.
  for i=0,7 do
   local a=i*math.pi/4
   local attachment=Instance.new("Attachment");attachment.Name="SummitMotes"
   attachment.Position=cf:VectorToWorldSpace(V(math.cos(a)*ring.radius,math.sin(a)*ring.radius,0));attachment.Parent=anchor
   local motes=Instance.new("ParticleEmitter");motes.Name="SummitSparkles"
   motes.Texture="rbxasset://textures/particles/sparkles_main.dds"
   motes.Color=ColorSequence.new(ring.color,Color3.fromRGB(255,247,210))
   motes.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.25,0.7),NumberSequenceKeypoint.new(1,0)})
   motes.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.2,0.15),NumberSequenceKeypoint.new(1,1)})
   motes.Lifetime=NumberRange.new(1,1.8);motes.Rate=0.8;motes.Speed=NumberRange.new(0.4,1.2)
   motes.SpreadAngle=Vector2.new(40,40);motes.Acceleration=V(0,0.8,0)
   motes.LightEmission=1;motes.LightInfluence=0;motes.Parent=attachment
  end
  local beacon=Instance.new("BillboardGui");beacon.Name="SummitBeacon";beacon.Adornee=anchor
  beacon.Size=UDim2.fromOffset(38,38);beacon.AlwaysOnTop=false;beacon.LightInfluence=0
  beacon.MaxDistance=12000;beacon.Enabled=false;beacon.Parent=m
  for _,layer in {{1,0.8,9},{0.85,0.5,5},{0.72,0,2.5}} do
   local circle=Instance.new("Frame");circle.AnchorPoint=Vector2.new(0.5,0.5)
   circle.Position=UDim2.fromScale(0.5,0.5);circle.Size=UDim2.fromScale(layer[1],layer[1])
   circle.BackgroundTransparency=1;circle.Parent=beacon
   local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(1,0);corner.Parent=circle
   local stroke=Instance.new("UIStroke");stroke.Color=ring.color;stroke.Thickness=layer[3]
   stroke.Transparency=layer[2];stroke.Parent=circle
  end
 end
 -- Round neon tubing, with overlapping ends so the thicker hoop stays continuous.
 for j=1,48 do
  local a=(j-1)/48*math.pi*2;local b=j/48*math.pi*2
  local pa=cf:PointToWorldSpace(V(math.cos(a)*ring.radius,math.sin(a)*ring.radius,0))
  local pb=cf:PointToWorldSpace(V(math.cos(b)*ring.radius,math.sin(b)*ring.radius,0))
  local tubeFrame=CFrame.lookAt((pa+pb)/2,pb)*CFrame.Angles(0,math.pi/2,0)
  local segment=decor(part(m,"NeonArc",V((pb-pa).Magnitude+0.06,Config.RingTubeThickness,Config.RingTubeThickness),tubeFrame,ring.color,Enum.Material.Neon))
  segment.Shape=Enum.PartType.Cylinder;segment.CastShadow=false
  if summit then
   segment.Color=Color3.fromRGB(255,242,193)
   local glow=segment:Clone();glow.Name="SummitGlow";glow.Color=ring.color
   glow.Size=V(segment.Size.X,2.1,2.1);glow.Transparency=0.82;glow.Parent=m
  end
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
-- Every encounter now uses the reference-inspired roster; no legacy quadruped fallback.
for _,animal in World.Animals do
 assert(ReferenceAnimals.build(animal,animals,ground),"Missing wildlife builder: "..animal.species)
end
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
return string.format("World: %d exploration rings, %d wildlife landmarks, varied ridges and a broad launch mesa.",#World.Rings,#World.Animals)
