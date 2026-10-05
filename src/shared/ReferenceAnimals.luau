-- Original procedural wildlife inspired by the user's block-built animal screenshots.
-- Layered paper bodies with rounded limbs and a clear sideways flight passage.
local Wildlife={}
local V,CF=Vector3.new,CFrame.new
function Wildlife.build(animal,parent,ground)
 local model=Instance.new("Model")
 model.Name=animal.species..animal.id;model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 model:SetAttribute("Species",animal.species);model:SetAttribute("AnimalId",animal.id)
 model:SetAttribute("ReferenceStyle","LayeredBlock")
 local frame=CF(animal.position)*CFrame.Angles(0,animal.heading,0)
 local function block(name,size,localFrame,color,material)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=frame*localFrame
  p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.Anchored=true;p.CanTouch=false
  p.TopSurface=(not material and size.X>=7 and size.Z>=7) and Enum.SurfaceType.Studs or Enum.SurfaceType.Smooth
  p.FrontSurface=(not material and size.X>=10 and size.Y>=10 and size.Z>3) and Enum.SurfaceType.Studs or Enum.SurfaceType.Smooth
  p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=model
  return p
 end
 local function triangle(name,a,b,c,color)
  local ab,ac,bc=b-a,c-a,c-b
  if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
  elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
  ab,ac,bc=b-a,c-a,c-b
  if bc.Magnitude<0.001 or ac:Cross(ab).Magnitude<0.001 then return end
  local right=ac:Cross(ab).Unit;local back=bc.Unit;local up=back:Cross(right).Unit
  local h=math.abs(ab:Dot(up))
  for _,s in {{(a+b)/2,right,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,-back,math.abs(ac:Dot(back))}} do
   if s[4]>0.001 then
    local p=Instance.new("WedgePart");p.Name=name;p.Size=V(0.08,h,s[4])
    p.CFrame=frame*CFrame.fromMatrix(s[1],s[2],up,s[3]);p.Color=color
    p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanTouch=false
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=model
   end
  end
 end
 local function quad(name,a,b,c,d,color)
  triangle(name,a,b,c,color);triangle(name,a,c,d,color)
 end
 -- Octagonal sections along the animal's length form broad chamfers instead of round shells.
 local outline={{-0.7,-1},{0.7,-1},{1,-0.65},{1,0.65},{0.7,1},{-0.7,1},{-1,0.65},{-1,-0.65}}
 local function hull(name,sections,color)
  local previous
  for index,s in sections do
   local ring={}
   for i,v in outline do ring[i]=V(v[1]*s.w,s.y+v[2]*s.h,s.z) end
   if previous then
    for i=1,8 do local j=i%8+1
     local shade=color:Lerp(Color3.new(0,0,0),({0.12,0.08,0,0.025,0,0.04,0.075,0.11})[i])
     quad(name,previous[i],previous[j],ring[j],ring[i],shade)
    end
   end
   if index==1 or index==#sections then
    for i=1,8 do triangle(name,V(0,s.y,s.z),ring[i],ring[i%8+1],color) end
   end
   previous=ring
  end
 end
 local function beam(name,a,b,width,color)
  return block(name,V(width,width,(b-a).Magnitude+0.15),CFrame.lookAt((a+b)/2,b),color)
 end
 local function tube(name,points,widths,color)
  local previous
  for i,center in points do
   local tangent=i==#points and center-points[i-1] or points[i+1]-center
   local orient=CFrame.lookAt(center,center+tangent)
   local ring={}
   for j=1,6 do
    local a=(j-1)*math.pi/3
    ring[j]=orient:PointToWorldSpace(V(math.cos(a)*widths[i],math.sin(a)*widths[i],0))
   end
   if previous then
    for j=1,6 do quad(name,previous[j],previous[j%6+1],ring[j%6+1],ring[j],color:Lerp(Color3.new(1,1,1),j%2*0.12)) end
   end
   previous=ring
  end
 end
 local function footY(x,z)
  local point=frame:PointToWorldSpace(V(x*animal.scale,0,z*animal.scale))
  return (ground(point.X,point.Z)-animal.position.Y)/animal.scale
 end
 local function eye(x,y,z,color)
  local p=block("EyeGlow",V(2.5,3,0.7),CF(x,y,z),color,Enum.Material.Neon)
  p.CanCollide=false;p.CanQuery=false
 end

 -- Roblox cylinders run along local X; rotate them onto a leg's vertical axis.
 -- Smooth ellipsoid paws keep the existing footprint and sampled ground height.
 local function roundPart(name,size,localFrame,color)
  local p=block(name,size,localFrame,color,Enum.Material.SmoothPlastic)
  -- A sphere mesh follows all three dimensions; a Ball Part renders too small
  -- for flattened paws. Keep the original part bounds for reliable collision.
  local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
  return p
 end
 local function roundLeg(name,size,localFrame,color)
  local p=block(name,V(size.Y,size.X,size.Z),localFrame*CFrame.Angles(0,0,math.pi/2),color,Enum.Material.SmoothPlastic)
  p.Shape=Enum.PartType.Cylinder
  return p
 end
 local function roundBeam(name,a,b,width,color)
  local p=block(name,V((b-a).Magnitude+0.15,width,width),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),color,Enum.Material.SmoothPlastic)
  p.Shape=Enum.PartType.Cylinder
  return p
 end
 local function fourLegs(x,z,top,width,color,feetColor)
  for _,side in {-1,1} do for _,endSign in {-1,1} do
   local px,pz=side*x,endSign*z;local floor=footY(px,pz)
   roundLeg("RoundLeg",V(width,top-floor,width+3),CF(px,(top+floor)/2,pz),color)
   roundPart("RoundedPaw",V(width+5,9,width+12),CF(px,floor+4.5,pz-3),feetColor or color)
  end end
 end
 local function faceEye(x,y,z,size)
  local white=Color3.fromRGB(239,246,250);local dark=Color3.fromRGB(15,22,37)
  local rim=block("EyeWhite",V(size,size*1.1,1.3),CF(x,y,z),white)
  local pupil=block("EyePupil",V(size*0.64,size*0.83,1),CF(x,y-0.3,z-0.8),dark)
  local shine=block("EyeShine",V(size*0.24,size*0.25,0.5),CF(x-size*0.13,y+size*0.19,z-1.4),white)
  for _,p in {rim,pupil,shine} do p.CanCollide=false;p.CanQuery=false end
 end
 local function steppedEar(x,y,z,color,inner)
  for row=0,3 do
   local width=19-row*4
   block("EarStep",V(width,8,11),CF(x,y+row*7,z),color)
   block("EarInner",V(math.max(2,width-6),6,1),CF(x,y+row*7,z-6),inner)
  end
 end
 if animal.species=="Bear" then
  local brown=Color3.fromRGB(103,73,50);local warm=Color3.fromRGB(128,92,60)
  local muzzle=Color3.fromRGB(166,119,87)
  hull("BearTorso",{{z=44,y=79,w=24,h=23},{z=23,y=88,w=30,h=33},
   {z=-28,y=91,w=31,h=32},{z=-43,y=85,w=24,h=24}},brown)
  fourLegs(22,36,66,20,brown,Color3.fromRGB(75,53,40))
  block("ChestBib",V(43,27,6),CF(0,78,-47),warm)
  block("BearHead",V(53,44,43),CF(0,111,-43),warm)
  block("ForeheadStep",V(43,9,35),CF(0,136,-43),brown)
  for _,side in {-1,1} do
   block("RoundEarBase",V(18,14,12),CF(side*24,137,-39),brown)
   block("RoundEarTop",V(12,7,10),CF(side*24,147,-39),brown)
   block("EarInset",V(10,10,2),CF(side*24,139,-46),muzzle)
   faceEye(side*14,119,-65,7)
   for j=1,3 do roundPart("PawClaw",V(3,3,4),CF(side*22+(j-2)*5,footY(side*22,-36)+5,-52),muzzle) end
  end
  block("BearMuzzle",V(30,19,16),CF(0,104,-69),muzzle)
  block("BearNose",V(17,8,5),CF(0,110,-79),Color3.fromRGB(39,30,29))
  block("Mouth",V(13,2,1),CF(0,100,-77.5),Color3.fromRGB(54,34,30))
  block("StubTail",V(16,17,16),CF(0,85,49),brown)
 elseif animal.species=="SilverFox" then
  local silver=Color3.fromRGB(163,180,209);local shadow=Color3.fromRGB(111,130,165)
  local white=Color3.fromRGB(227,235,248)
  hull("FoxTorso",{{z=39,y=76,w=15,h=19},{z=20,y=80,w=21,h=24},
   {z=-28,y=79,w=21,h=24},{z=-41,y=77,w=16,h=21}},silver)
  fourLegs(15,32,62,12,shadow,silver)
  hull("PointedFoxHead",{{z=-35,y=95,w=16,h=19},{z=-56,y=92,w=20,h=21},
   {z=-75,y=82,w=10,h=10},{z=-87,y=80,w=3,h=4}},silver)
  block("FoxFacePanel",V(29,15,12),CF(0,98,-69),silver)
  for _,side in {-1,1} do
   steppedEar(side*14,116,-47,shadow,white)
   block("CheekRuff",V(10,18,15),CF(side*19,84,-53)*CFrame.Angles(0,0,side*0.25),white)
   faceEye(side*8,98,-75.8,5)
   for row=0,2 do
    block("ShoulderFold",V(5,17,15),CF(side*(21-row),82+row*6,-17+row*9)*CFrame.Angles(0,0,-side*0.2),white)
   end
  end
  block("FoxNose",V(8,6,5),CF(0,81,-89),Color3.fromRGB(44,58,82))
  tube("PlumeTail",{V(0,81,37),V(5,93,58),V(4,112,73),V(0,124,84)},{9,16,12,5},shadow)
  tube("WhiteTailTip",{V(4,112,73),V(0,124,84),V(-4,132,96)},{12,7,0.1},white)
 elseif animal.species=="Raccoon" then
  local navy=Color3.fromRGB(35,49,76);local gray=Color3.fromRGB(113,139,178)
  local pale=Color3.fromRGB(188,206,230)
  hull("RaccoonTorso",{{z=38,y=76,w=18,h=20},{z=17,y=79,w=25,h=26},
   {z=-25,y=78,w=25,h=24},{z=-38,y=77,w=18,h=20}},gray)
  fourLegs(17,31,60,14,navy,navy)
  for i=0,3 do block("BackStripe",V(40,4,8),CF(0,105-i%2,-19+i*16),navy) end
  block("RaccoonHead",V(44,35,31),CF(0,92,-47),gray)
  for _,side in {-1,1} do
   block("RaccoonEar",V(15,13,10),CF(side*16,115,-44),navy)
   block("RaccoonEarTop",V(9,5,8),CF(side*16,123,-44),navy)
   block("RaccoonEarInset",V(8,8,1),CF(side*16,116,-49.5),pale)
   block("EyeMask",V(18,15,3),CF(side*11,96,-64),navy)
   faceEye(side*11,97,-66,6)
  end
  block("PaleMuzzle",V(25,14,11),CF(0,84,-65),pale)
  block("RaccoonNose",V(10,6,4),CF(0,88,-72),navy)
  local tail={V(0,77,36),V(0,79,49),V(2,85,62),V(4,96,74),V(5,109,82),V(3,117,86)}
  for i=1,#tail-1 do beam("RingedTail",tail[i],tail[i+1],16-i,i%2==0 and pale or navy) end
 elseif animal.species=="Turtle" then
  local green=Color3.fromRGB(105,157,92);local dark=Color3.fromRGB(72,115,70)
  local brown=Color3.fromRGB(151,108,62);local edge=Color3.fromRGB(191,148,91)
  fourLegs(41,49,61,24,green,dark)
  block("ShellRim",V(116,12,132),CF(0,64,0),edge)
  -- Successively smaller courses form the stepped domed shell seen in the reference.
  for layer=0,5 do
   local width=110-layer*15;local length=126-layer*16
   block("ShellCourse",V(width,8,length),CF(0,74+layer*8,0),layer%2==0 and brown or edge)
  end
  block("TurtleNeck",V(27,22,23),CF(0,62,-73),dark)
  block("TurtleHead",V(38,29,34),CF(0,66,-93),green)
  block("HeadTop",V(31,5,29),CF(0,83,-93),green)
  for _,side in {-1,1} do
   faceEye(side*12,72,-111,8)
   roundPart("FlipperEdge",V(13,8,38),CF(side*52,footY(side*41,-49)+5,-52)*CFrame.Angles(0,side*0.2,0),green)
  end
  block("TurtleSmile",V(19,2,1),CF(0,59,-110.5),dark)
  tube("TurtleTail",{V(0,62,61),V(0,49,79),V(0,43,92)},{8,5,0.1},green)
 elseif animal.species=="CandyCat" then
  local orange=Color3.fromRGB(235,147,48);local cream=Color3.fromRGB(243,222,171)
  local cyan=Color3.fromRGB(104,219,230);local pink=Color3.fromRGB(233,146,207)
  fourLegs(20,34,60,17,cream,cream)
  block("CandyBody",V(46,34,78),CF(0,75,6),cyan)
  for i=0,4 do block("BackFin",V(6,15+i%2*5,11),CF(0,98+i%2*2,-17+i*14),pink) end
  for _,side in {-1,1} do
   block("SideFin",V(12,7,40),CF(side*28,78,8)*CFrame.Angles(0,0,side*0.2),pink)
  end
  block("SquareCatHead",V(65,62,45),CF(0,88,-62),orange)
  block("CreamChin",V(54,13,4),CF(0,62,-86),cream)
  for _,side in {-1,1} do
   steppedEar(side*23,125,-65,orange,cream)
   faceEye(side*16,96,-85.5,24)
   for row=0,2 do
    beam("Whisker",V(side*23,67+row*6,-88),V(side*43,64+row*9,-89),1.7,Color3.fromRGB(31,35,42))
   end
  end
  block("PinkNose",V(9,7,3),CF(0,76,-89),pink)
  beam("CatMouth",V(-9,67,-89),V(0,63,-89),2,Color3.fromRGB(39,33,35))
  beam("CatMouth",V(0,63,-89),V(9,67,-89),2,Color3.fromRGB(39,33,35))
  beam("TailStem",V(0,78,41),V(0,91,66),9,cyan)
  block("PinkTailFin",V(36,7,15),CF(0,95,72)*CFrame.Angles(-0.35,0,0),pink)
 elseif animal.species=="Gorilla" then
  local dark=Color3.fromRGB(27,34,47);local edge=Color3.fromRGB(44,53,68)
  local face=Color3.fromRGB(69,79,93)
  hull("SilverbackTorso",{
   {z=39,y=81,w=22,h=24},{z=20,y=91,w=31,h=33},
   {z=-17,y=95,w=40,h=37},{z=-35,y=92,w=33,h=30}},dark)
  -- Broad chest plates and high shoulder pads give a recognizable hunched gorilla silhouette.
  for _,side in {-1,1} do
   block("ChestPlate",V(30,27,7),CF(side*16,91,-38)*CFrame.Angles(0,0,side*0.07),edge)
   roundPart("ShoulderPad",V(31,31,32),CF(side*41,91,-24)*CFrame.Angles(0,0,-side*0.13),edge)
   local armTop=V(side*44,88,-28);local elbow=V(side*49,48,-39);local wrist=V(side*45,14,-51)
   roundBeam("UpperArm",armTop,elbow,25,dark);roundBeam("Forearm",elbow,wrist,26,edge)
   roundPart("ElbowJoint",V(26,26,26),CF(elbow),edge)
   local floor=footY(side*45,-53)
   roundPart("KnuckleHand",V(28,14,25),CF(side*45,floor+7,-53),dark)
   for j=1,4 do roundPart("FingerFold",V(5,9,8),CF(side*45+(j-2.5)*5.5,floor+5,-66),edge) end
   local heelFloor=footY(side*23,39)
   roundBeam("RearThigh",V(side*22,70,32),V(side*24,32,43),22,dark)
   roundLeg("RearShin",V(19,30-heelFloor,20),CF(side*24,(30+heelFloor)/2,42),edge)
   roundPart("RearFoot",V(21,9,29),CF(side*24,heelFloor+4.5,37),dark)
   -- Rounded cuffs follow the forearm so the old flat plates cannot float off its sides.
   for row=1,3 do
    local t=(3+row*8)/34;local center=wrist:Lerp(elbow,t)
    local axis=(elbow-wrist).Unit
    roundBeam("ArmCuff",center-axis*3,center+axis*3,27,dark)
   end
  end
  hull("CrestedHead",{{z=-20,y=119,w=16,h=20},{z=-42,y=119,w=20,h=20},{z=-52,y=115,w=15,h=15}},dark)
  block("FaceMask",V(28,23,6),CF(0,114,-54),face)
  block("Brow",V(31,7,9),CF(0,123,-58),edge)
  block("Muzzle",V(23,12,11),CF(0,108,-59),edge)
  block("Nose",V(12,5,4),CF(0,113,-66),dark)
  for _,side in {-1,1} do eye(side*9,118,-58,Color3.fromRGB(206,218,227)) end
  -- Silver saddle uses large overlapping slabs following the curved back.
  for row=0,3 do
   block("SilverbackPlate",V(41-row*3,3,15),CF(0,125-row*4,2+row*11)*CFrame.Angles(-0.26,0,0),face)
  end
 elseif animal.species=="Mammoth" then
  local blue=Color3.fromRGB(50,116,189);local navy=Color3.fromRGB(31,66,126)
  local ice=Color3.fromRGB(147,230,247);local white=Color3.fromRGB(228,239,248)
  hull("MammothBody",{{z=53,y=84,w=28,h=28},{z=30,y=96,w=38,h=37},
   {z=-25,y=101,w=40,h=40},{z=-48,y=94,w=30,h=32}},navy)
  for _,side in {-1,1} do
   for _,z in {-40,39} do
    local floor=footY(side*26,z)
    roundLeg("MammothLeg",V(22,64-floor,25),CF(side*26,(64+floor)/2,z),blue)
    roundPart("MammothFoot",V(27,13,30),CF(side*26,floor+6.5,z-2),navy)
    roundLeg("AnkleCuff",V(23,13,26),CF(side*26,floor+18,z),white)
    for toe=1,3 do
     roundPart("IvoryToe",V(5,6,4),CF(side*26+(toe-2)*7,floor+4,z-18),white)
    end
   end
   -- Offset rows of white/blue paper armor reproduce the reference's layered coat.
   for row=0,2 do for column=0,5 do
    local z=-38+column*16+(row%2)*4
    local x=side*(34+row*1.5)
    local y=118-row*18-((column==0 or column==5) and 6 or 0)
    local col=(row+column)%3==0 and blue or white
    block("CoatPlate",V(5,25,18),CF(x,y,z)*CFrame.Angles(0,side*0.08,-side*0.18),col)
   end end
   block("EarFold",V(10,45,27),CF(side*30,103,-49)*CFrame.Angles(0,side*0.24,side*0.15),blue)
   block("EarIcePlate",V(5,33,22),CF(side*36,107,-51)*CFrame.Angles(0,side*0.24,side*0.15),ice)
   tube("CurvedIceTusk",{V(side*20,88,-59),V(side*31,62,-74),V(side*44,54,-91),
    V(side*51,69,-106),V(side*49,95,-110),V(side*39,115,-104)},{7,7,6,4.5,2.5,0.1},ice)
  end
  hull("MammothHead",{{z=-42,y=113,w=24,h=27},{z=-62,y=110,w=26,h=26},{z=-69,y=102,w=19,h=20}},blue)
  block("CrownPlate",V(37,8,24),CF(0,137,-52)*CFrame.Angles(-0.18,0,0),white)
  for _,side in {-1,1} do
   block("CheekPlate",V(12,23,6),CF(side*20,108,-71)*CFrame.Angles(0,0,-side*0.24),white)
   block("EyeSocket",V(10,10,4),CF(side*15,119,-73),navy)
   eye(side*15,120,-75.5,Color3.fromRGB(120,255,255))
   block("BrowPlate",V(18,6,7),CF(side*15,129,-69)*CFrame.Angles(0,0,side*0.23),white)
  end
  local trunk={V(0,109,-71),V(0,94,-76),V(0,78,-80),V(0,61,-83),V(0,44,-85),V(0,30,-88),V(0,26,-100)}
  for i=1,#trunk-1 do beam("TrunkSegment",trunk[i],trunk[i+1],17-i*1.3,i%2==0 and blue or Color3.fromRGB(85,156,215)) end
  -- Angular ice spikes stand above the coat, never inside the flight opening.
  for i=0,5 do
   local z=-25+i*14;local y=138-math.abs(i-2)*3
   tube("IceCrest",{V(0,y,z),V(2,y+16,z-3),V(1,y+27,z-5)},{7,4,0.1},ice)
   block("BackPlate",V(43,5,15),CF(0,y-2,z)*CFrame.Angles(0.08,0,0),i%2==0 and white or blue)
  end
  beam("MammothTail",V(0,83,52),V(0,50,70),5,navy)
 else
  model:Destroy();return nil
 end
 model.WorldPivot=frame;model:ScaleTo(animal.scale)
 model:SetAttribute("WildlifeScale",animal.scale)
 if animal.behindPeak then model:SetAttribute("BehindPeak",animal.behindPeak) end
 model.Parent=parent
 return model
end
return Wildlife
