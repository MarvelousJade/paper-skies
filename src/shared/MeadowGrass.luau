-- Client-only close-range grass. A bounded pool follows the camera; no server collision.
local MeadowGrass={}
local V=Vector3.new
local SPACING,RADIUS,FADE_START,MAX_CLUMPS=4.2,160,105,1400
local MID_RADIUS=80
local NEAR_RADIUS=58 -- Interleave a denser inner layer with a sparse longer-range layer.
local function wedge(parent)
 local p=Instance.new("WedgePart");p.Name="GrassBlade"
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Material=Enum.Material.SmoothPlastic;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 p.Transparency=1;p.Parent=parent;return p
end
local function triangle(parts,index,a,b,c,color)
 local ab,ac,bc=b-a,c-a,c-b
 if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
 elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local right=ac:Cross(ab).Unit;local back=bc.Unit;local up=back:Cross(right).Unit
 local height=math.abs(ab:Dot(up))
 local first,second=parts[index],parts[index+1]
 first.Size=V(0.035,height,math.max(0.01,math.abs(ab:Dot(back))))
 second.Size=V(0.035,height,math.max(0.01,math.abs(ac:Dot(back))))
 first.CFrame=CFrame.fromMatrix((a+b)/2,right,up,back)
 second.CFrame=CFrame.fromMatrix((a+c)/2,-right,up,-back)
 first.Color=color;second.Color=color
end
function MeadowGrass.new(parent)
 local folder=Instance.new("Folder");folder.Name="CloseMeadowGrass";folder.Parent=parent
 local active,pool,misses={},{},{}
 local allocated,clock=0,0
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={workspace.Terrain};params.IgnoreWater=false
 local api={Folder=folder}
 local function release(key,clump)
  for _,p in clump.parts do p.Transparency=1 end
  active[key]=nil;table.insert(pool,clump)
 end
 function api:Update(eye,dt)
  clock+=dt
  local count=0
  for key,clump in active do
   local distance=(clump.position-eye).Magnitude
   if distance>clump.radius then release(key,clump)
   else
    count+=1
    local fadeStart=clump.radius==NEAR_RADIUS and 40 or clump.radius==MID_RADIUS and 52 or FADE_START
    local target=math.clamp((distance-fadeStart)/(clump.radius-fadeStart),0,1)
    clump.transparency+=(target-clump.transparency)*(1-math.exp(-12*dt))
    for _,p in clump.parts do p.Transparency=clump.transparency end
   end
  end
  local cx,cz=math.floor(eye.X/SPACING),math.floor(eye.Z/SPACING)
  local candidates={};local cells=math.ceil(RADIUS/SPACING)
  for x=cx-cells,cx+cells do for z=cz-cells,cz+cells do
   local dx,dz=x*SPACING-eye.X,z*SPACING-eye.Z
   local d=dx*dx+dz*dz
   -- Sparse far cells double visibility without quadrupling dense geometry.
   local radius=(x%3==0 and z%3==0) and RADIUS or (x+z)%2==0 and MID_RADIUS or NEAR_RADIUS
   if d<radius*radius then
    local key=x..":"..z
    if not active[key] and (not misses[key] or misses[key]<clock) then
     table.insert(candidates,{x=x,z=z,key=key,distance=d,radius=radius})
    end
   end
  end end
  table.sort(candidates,function(a,b) return a.distance<b.distance end)
  local checked=0
  for _,cell in candidates do
   if checked>=80 or count>=MAX_CLUMPS then break end
   checked+=1
   local rng=Random.new((cell.x*73856093+cell.z*19349663)%2147483647)
   local x,z=cell.x*SPACING+rng:NextNumber(-1.2,1.2),cell.z*SPACING+rng:NextNumber(-1.2,1.2)
   local hit=workspace:Raycast(V(x,eye.Y+35,z),V(0,-225,0),params)
   if not hit or (hit.Material~=Enum.Material.LeafyGrass and hit.Material~=Enum.Material.Grass)
    or hit.Normal.Y<0.72 or (hit.Position-eye).Magnitude>cell.radius then
    misses[cell.key]=clock+1.5;continue
   end
   local clump=table.remove(pool)
   if not clump then
    if allocated>=MAX_CLUMPS then break end
    clump={parts={}};for i=1,6 do clump.parts[i]=wedge(folder) end
    allocated+=1
   end
   clump.position=hit.Position;clump.transparency=1;clump.radius=cell.radius
   local base=hit.Position-V(0,0.12,0)
   local rotation=rng:NextNumber(0,math.pi*2)
   for blade=1,3 do
    local a=rotation+blade*math.pi*2/3
    local along=V(math.cos(a),0,math.sin(a));local side=V(-along.Z,0,along.X)
    local width=rng:NextNumber(0.65,1.05);local height=rng:NextNumber(1.6,3.1)
    local col=Color3.fromRGB(124+blade*9,167+blade*7,68+blade*5)
    triangle(clump.parts,blade*2-1,base-side*width,base+side*width,base+V(0,height,0)+along*rng:NextNumber(0.5,1.2),col)
   end
   active[cell.key]=clump;count+=1
  end
  -- Failed terrain queries retry after streaming, and expire rather than growing forever.
  for key,untilTime in misses do if untilTime<clock-2 then misses[key]=nil end end
  folder:SetAttribute("ActiveClumps",count);folder:SetAttribute("AllocatedClumps",allocated)
 end
 function api:Destroy() folder:Destroy();table.clear(active);table.clear(pool);table.clear(misses) end
 return api
end
return MeadowGrass
