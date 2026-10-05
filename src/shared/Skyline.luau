-- Compact, complete mountain surfaces: serialized points, client-created visual wedges.
local Skyline={Step=128}
local V=Vector3.new
function Skyline.bake(landscape)
 local data={}
 local function point(x,z)
  local h,_,mountain=landscape.height(x,z)
  return {x,mountain and h-10 or -8,z}
 end
 for x=-5632,4608-128,128 do for z=-5376,5632-128,128 do
  local intersects=false
  for _,peak in landscape.Peaks do
   local dx=math.max(0,math.abs(x+64-peak.x)-64)/peak.rx
   local dz=math.max(0,math.abs(z+64-peak.z)-64)/peak.rz
   if dx*dx+dz*dz<1 then intersects=true;break end
  end
  if not intersects then continue end
  local h,rock=landscape.height(x+64,z+64)
  -- The center sample retains narrow summits that a coarse corner-only grid misses.
  local row={point(x,z),point(x+128,z),point(x+128,z+128),point(x,z+128),
   point(x+64,z+64),rock and 1 or 0}
  -- Coverage must use the detailed height field, not the coarse triangle plane.
  -- Coarse faces can bridge a real gully well above its fully loaded terrain.
  local samples={}
  local function sample(px,pz)
   -- X/Z are derived from the tile; centimeter-scale height precision suffices.
   table.insert(samples,math.round(landscape.height(px,pz)*100)/100)
  end
  for i=1,5 do sample(row[i][1],row[i][3]) end
  for i=1,4 do
   local a,b,c=row[5],row[i],row[i%4+1]
   sample((a[1]+b[1]+c[1])/3,(a[3]+b[3]+c[3])/3)
  end
  row[7]=samples;table.insert(data,row)
 end end
 return data
end
function Skyline.build(data,parent,yieldBatch)
 local vista=Instance.new("Model");vista.Name="DistantLandscape";vista.Parent=parent
 local function triangle(tile,a,b,c,color)
  local ab,ac,bc=b-a,c-a,c-b
  if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
  elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
  ab,ac,bc=b-a,c-a,c-b
  if ac:Cross(ab).Magnitude<0.001 then return end
  local right=ac:Cross(ab).Unit;local back=bc.Unit;local up=back:Cross(right).Unit
  for _,s in {{(a+b)/2,right,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,-back,math.abs(ac:Dot(back))}} do
   if s[4]<.001 then continue end
   local p=Instance.new("WedgePart");p.Name="SkylineSurface"
   p.Size=V(.035,math.abs(ab:Dot(up)),s[4]);p.CFrame=CFrame.fromMatrix(s[1],s[2],up,s[3])
   p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true
   p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=tile
  end
 end
 for i,row in data do
  local tile=Instance.new("Model");tile.Name="VistaTile";local points={}
  for j=1,5 do points[j]=V(unpack(row[j])) end
  tile:SetAttribute("Center",points[5])
  for j=1,9 do
   local sample
   if j<=5 then sample=points[j]
   else local k=j-5;sample=(points[5]+points[k]+points[k%4+1])/3 end
   local height=row[7] and row[7][j]
   if height then sample=V(sample.X,height,sample.Z) end
   if height or j<=5 then tile:SetAttribute("Sample"..j,sample) end
  end
  local color=row[6]==1 and Color3.fromRGB(139,141,153) or Color3.fromRGB(135,173,85)
  for j=1,4 do triangle(tile,points[5],points[j],points[j%4+1],color) end
  tile.Parent=vista
  if yieldBatch and i%64==0 then yieldBatch() end
 end
 vista.Parent=parent
 return vista
end
return Skyline
