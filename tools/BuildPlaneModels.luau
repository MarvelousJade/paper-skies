-- Original procedural paper models inspired by online folding references.
-- Fold N Fly Lock-Bottom and AFRL dart / glider / sailplane silhouettes; no imported textures.
local package=game.ReplicatedStorage.PaperFlight
local Config=require(package.Config)
local old=package:FindFirstChild("PlaneModels");if old then old:Destroy() end
local folder=Instance.new("Folder");folder.Name="PlaneModels";folder.Parent=package
local V,CF=Vector3.new,CFrame.new
local rng=Random.new(70421)
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
  if s[4]>0.001 then part(parent,name,V(0.035,h,s[4]),CFrame.fromMatrix(s[1],s[2],up,s[3]),color,nil,"WedgePart") end
 end
end
local function quad(parent,name,a,b,c,d,col)
 triangle(parent,name,a,b,c,col);triangle(parent,name,a,c,d,col)
end
local function beam(parent,name,a,b,width,col)
 return part(parent,name,V(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),col)
end

local paper=Color3.fromRGB(255,249,228)
local definitions={
 Dart={nose=-6,tail=4.5,wing={V(0,0,-6),V(4.4,0.35,4.5),V(0.3,0,3.6)}},
 Lockwing={nose=-4.2,tail=3.5,wing={V(0,0,-4.2),V(4.8,0.2,-1.4),V(4.8,0.25,3.5),V(0.3,0,3.1)}},
 Delta={nose=-6,tail=4.4,wing={V(0,0,-6),V(5.3,0.3,4.4),V(2.8,0.12,2.6),V(0.3,0,4)}},
 Sailwing={nose=-4.8,tail=5.2,wing={V(0,0,-4.8),V(5.25,0.25,-1.5),V(5.25,0.35,1.6),V(0.4,0,2.2)}},
 Kestrel={nose=-5.8,tail=5,wing={V(0,0,-5.8),V(0.8,0,-1.6),V(5.2,0.35,2),V(3.8,0.65,5),V(0.3,0,3.8)}},
}
for _,id in Config.PlaneOrder do
 local def=definitions[id];local m=model(id);m:SetAttribute("PlaneType",id)
 local root=decor(part(m,"Root",V(0.1,0.1,0.1),CF(),paper));root.Transparency=1;m.PrimaryPart=root
 local function face(name,a,b,c,shade)
  local before=#m:GetChildren()
  triangle(m,name,a,b,c,paper:Lerp(Color3.fromRGB(105,128,145),shade))
  local children=m:GetChildren()
  for j=before+1,#children do children[j]:SetAttribute("FoldShade",shade) end
 end
 for _,side in {-1,1} do
  local function p(v) return V(v.X*side,v.Y,v.Z) end
  local wing=def.wing
  for j=2,#wing-1 do face("PaperWing",p(wing[1]),p(wing[j]),p(wing[j+1]),side==1 and 0.03 or 0.1) end
  face("CentralFold",V(0,0,def.nose),p(V(0.8,0.02,def.tail-0.4)),V(0,-0.75,def.tail-0.3),0.22)
  face("FoldLip",V(0,0.02,def.nose+0.5),p(V(0.85,0.07,def.tail-0.6)),p(V(1.25,0.09,def.tail-0.9)),0.13)
  local crease=beam(m,"Crease",V(0,0.045,def.nose+0.25),p(V(0.8,0.07,def.tail-0.4)),0.025,Color3.fromRGB(190,190,175))
  crease:SetAttribute("FoldShade",0.25)
  if id=="Lockwing" then
   quad(m,"RaisedWingtip",p(V(4.8,0.2,-1.4)),p(V(4.8,0.25,3.5)),p(V(4.55,0.9,3.5)),p(V(4.55,0.85,-1.2)),paper)
   face("NoseLock",V(0,0.04,-2.6),p(V(1.3,0.15,-1.2)),V(0,0.22,-0.2),0.18)
  elseif id=="Sailwing" then
   face("Tailplane",p(V(0.25,0,2.4)),p(V(2.3,0.2,4.8)),p(V(0.25,0,5.2)),0.08)
   quad(m,"Winglet",p(V(5.25,0.25,-1.5)),p(V(5.25,0.35,1.6)),p(V(5.05,1.1,1.5)),p(V(5.05,1,-1.1)),paper)
  elseif id=="Kestrel" then
   face("CanardFold",p(V(0.1,0.02,-4.5)),p(V(2.1,0.22,-2.3)),p(V(0.65,0.06,-1.6)),0.1)
   face("SplitTailFold",p(V(2.8,0.4,2.6)),p(V(2.8,1.15,4.6)),p(V(3.8,0.65,5)),0.16)
   face("LeadingFold",p(V(0.85,0.035,-1.5)),p(V(5.15,0.38,2)),p(V(3.25,0.15,1.1)),0.14)
  elseif id=="Delta" then
   face("TrailingFold",p(V(2.8,0.15,2.6)),p(V(5.3,0.33,4.4)),p(V(3.6,0.5,4.3)),0.16)
  end
 end
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then decor(p);p.CastShadow=true end end
 for _,side in {-1,1} do
  local a=Instance.new("Attachment");a.Position=V(side*4.1,0.2,def.tail-0.4);a.Parent=root
  local b=Instance.new("Attachment");b.Position=a.Position+V(0,0.1,0);b.Parent=root
  local trail=Instance.new("Trail");trail.Attachment0=a;trail.Attachment1=b;trail.Lifetime=0.5
  trail.Color=ColorSequence.new(paper);trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.65),NumberSequenceKeypoint.new(1,1)});trail.Parent=root
 end
 m:PivotTo(CF())
end
-- Compatibility with earlier installer stages.
local previous=package:FindFirstChild("Plane");if previous then previous:Destroy() end
local starter=folder.Dart:Clone();starter.Name="Plane";starter.Parent=package
return "Built five distinct folded paper plane models"
