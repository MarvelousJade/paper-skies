-- Original low-poly scenery. Broad colored facets replace individual leaves and petals.
local Scenery={}
local V,CF=Vector3.new,CFrame.new
local function part(parent,name,size,frame,color)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=frame;p.Color=color
 p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanTouch=false
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent
 return p
end
local function triangle(parent,name,a,b,c,color)
 local ab,ac,bc=b-a,c-a,c-b
 if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
 elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 if ac:Cross(ab).Magnitude<0.001 then return end
 local right=ac:Cross(ab).Unit;local back=bc.Unit;local up=back:Cross(right).Unit
 for _,s in {{(a+b)/2,right,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,-back,math.abs(ac:Dot(back))}} do
  if s[4]>0.001 then
   local p=Instance.new("WedgePart");p.Name=name;p.Size=V(0.035,math.abs(ab:Dot(up)),s[4])
   p.CFrame=CFrame.fromMatrix(s[1],s[2],up,s[3]);p.Color=color;p.Material=Enum.Material.SmoothPlastic
   p.Anchored=true;p.CanTouch=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent
  end
 end
end
local function solid(parent,name,kind,frame,scale,color)
 local template=assert(script.Parent.SceneryMeshes:FindFirstChild(kind),"Build scenery mesh templates first")
 local p=template:Clone();p.Name=name
 p.Size=template:GetAttribute("CanonicalSize")*scale
 p.CFrame=frame*CFrame.new(template:GetAttribute("CanonicalCenter")*scale)
 p.Color=color;p.UsePartColor=true;p.Parent=parent
 return p
end
local function facets(parent,name,frame,size,color,irregular)
 return solid(parent,name,irregular and "Stone" or "Canopy",frame,size/100,color)
end
local function beam(parent,name,a,b,width,color)
 return part(parent,name,V(width,width,(b-a).Magnitude+0.25),CFrame.lookAt((a+b)/2,b),color)
end
function Scenery.tree(model,origin,h,kind,heading)
 model:SetAttribute("SceneryKind",kind);model:SetAttribute("BasePosition",origin);model:SetAttribute("ArtStyle","BrightFaceted")
 model:SetAttribute("TreeHeight",h);model:SetAttribute("TreeHeading",heading);model:SetAttribute("MeshOptimized",true)
 local frame=CF(origin)*CFrame.Angles(0,heading,0)
 local function point(x,y,z) return frame:PointToWorldSpace(V(x,y,z)*h) end
 local bark=kind=="CherryBlossom" and Color3.fromRGB(103,65,69) or Color3.fromRGB(110,91,67)
 local function branch(a,b,width) return beam(model,"Branch",point(a.X,a.Y,a.Z),point(b.X,b.Y,b.Z),width*h,bark) end
 local function crown(x,y,z,size,color,turn)
  facets(model,"CanopyFacet",CF(point(x,y,z))*CFrame.Angles(0,heading+(turn or 0),0),size*h,color,false)
 end
 if kind=="Palm" then
  branch(V(0,-0.03,0),V(0.06,0.55,0),0.075);branch(V(0.06,0.55,0),V(0.14,0.97,0.02),0.055)
  local tip=point(0.14,0.97,0.02)
  for i=1,7 do
   local a=i*math.pi*2/7;local radial=V(math.cos(a),0,math.sin(a));local side=V(-radial.Z,0,radial.X)*h*0.09
   local mid=tip+radial*h*0.28+V(0,h*0.06,0);local finish=tip+radial*h*0.58-V(0,h*0.15,0)
   triangle(model,"PalmFrond",tip,mid+side,finish,Color3.fromRGB(128,184,72))
   triangle(model,"PalmFrond",tip,finish,mid-side,Color3.fromRGB(157,202,81))
  end
 elseif kind=="Pine" then
  branch(V(0,-0.03,0),V(0,0.92,0),0.07)
  for layer=0,2 do
   local y=0.29+layer*0.22;local radius=(0.31-layer*0.065)*h
   local center=point(0,y,0);local tip=point(0,y+0.49,0)
   local color=Color3.fromRGB(73+layer*11,145+layer*10,118+layer*5)
   solid(model,"PineCrown","Pine",CF(center)*CFrame.Angles(0,-heading,0),V(radius/50,h*.49/100,radius/50),color)
  end
 elseif kind=="Birch" then
  bark=Color3.fromRGB(224,219,180)
  branch(V(0,-0.03,0),V(0.03,0.95,0),0.055)
  branch(V(0.02,0.43,0),V(-0.2,0.77,0.04),0.035)
  for i=1,4 do part(model,"BarkMark",V(h*0.057,h*0.025,h*0.057),CF(point(0.03*i/4,i*0.13,0)),Color3.fromRGB(88,97,82)) end
  crown(0.04,0.92,0,V(0.53,0.8,0.49),Color3.fromRGB(172,206,74),0.25)
  crown(-0.21,0.78,0.05,V(0.42,0.6,0.42),Color3.fromRGB(195,216,99),0.8)
 else
  local cherry=kind=="CherryBlossom"
  branch(V(0,-0.04,0),V(-0.08,0.32,0),0.13)
  branch(V(-0.08,0.32,0),V(0.06,0.64,0.01),0.095)
  branch(V(-0.06,0.38,0),V(-0.31,0.72,0.04),0.06)
  branch(V(0.01,0.54,0),V(0.33,0.79,-0.04),0.05)
  local main=cherry and Color3.fromRGB(243,136,158) or Color3.fromRGB(144,188,65)
  local side=cherry and Color3.fromRGB(227,111,141) or Color3.fromRGB(116,166,62)
  crown(-0.27,0.81,0.04,V(0.81,0.48,0.72),side,0.3)
  crown(0.28,0.9,-0.02,V(0.87,0.55,0.77),main,1.1)
  if cherry then crown(0.01,1.1,0.03,V(0.7,0.46,0.64),Color3.fromRGB(255,164,175),0.65) end
 end
end
function Scenery.stone(model,origin,size,heading)
 model:SetAttribute("SceneryKind","Stone");model:SetAttribute("BasePosition",origin);model:SetAttribute("MeshOptimized",true)
 facets(model,"StoneFacet",CF(origin+V(0,size.Y*0.25,0))*CFrame.Angles(0,heading,0.08),size,Color3.fromRGB(149,150,163),true)
end
function Scenery.patch(model,origin,ground,seed)
 local rng=Random.new(seed);model:SetAttribute("SceneryKind","MeadowPatch")
 model:SetAttribute("PatchSeed",seed)
 local heights={};local sampleGround=ground
 ground=function(x,z) local y=sampleGround(x,z);table.insert(heights,y);return y end
 model:SetAttribute("BasePosition",origin)
 for i=1,9 do
  local x,z=origin.X+rng:NextNumber(-9,9),origin.Z+rng:NextNumber(-9,9)
  local y=ground(x,z)+0.45;local frame=CF(x,y,z)*CFrame.Angles(0,i*1.3,0)
  local col=i%3==0 and Color3.fromRGB(199,162,232) or Color3.fromRGB(255,246,219)
  part(model,"Petal",V(1.5,0.13,0.48),frame,col)
  part(model,"Petal",V(0.48,0.14,1.5),frame,col)
  part(model,"FlowerCenter",V(0.37,0.19,0.37),frame,Color3.fromRGB(246,207,79))
 end
 for i=1,9 do
  local x,z=origin.X+rng:NextNumber(-10,10),origin.Z+rng:NextNumber(-10,10)
  local base=V(x,ground(x,z)-0.1,z)
  for j=1,3 do
   local a=j*math.pi*2/3+i;local d=V(math.cos(a),0,math.sin(a));local across=V(-d.Z,0,d.X)*0.45
   triangle(model,"GrassBlade",base-across,base+across,base+d*1.2+V(0,1.7+j*0.3,0),Color3.fromRGB(125+j*7,165+j*6,72+j*3))
  end
 end
 model:SetAttribute("PatchHeights",game:GetService("HttpService"):JSONEncode(heights))
 for _,p in model:GetChildren() do if p:IsA("BasePart") then p.CanCollide=false;p.CanQuery=false;p.CastShadow=false end end
end
return Scenery
