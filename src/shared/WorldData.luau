--!strict
local Landscape=require(script.Parent.Landscape)
local World={}
World.Regions={
 {name="Coastal Cliffs",center=Vector3.new(-550,0,400),color=Color3.fromRGB(85,153,95)},
 {name="Paperwood Valley",center=Vector3.new(-700,0,-1300),color=Color3.fromRGB(81,150,108)},
 {name="Azure Lagoon",center=Vector3.new(350,0,-2300),color=Color3.fromRGB(96,198,232)},
 {name="Cloudspire Highlands",center=Vector3.new(1300,0,-4400),color=Color3.fromRGB(165,157,231)},
 {name="Western Isles",center=Vector3.new(-2950,0,-3500),color=Color3.fromRGB(228,177,98)},
 {name="Northern Reach",center=Vector3.new(-850,0,-6450),color=Color3.fromRGB(195,223,228)},
}
World.Thermals={
 {center=Vector3.new(-550,0,-600),radius=220,height=750,strength=34},
 {center=Vector3.new(700,0,-1850),radius=250,height=850,strength=38},
 {center=Vector3.new(-1400,0,-2800),radius=260,height=950,strength=40},
 {center=Vector3.new(850,0,-4100),radius=280,height=1150,strength=42},
 {center=Vector3.new(-2200,0,-3700),radius=280,height=1000,strength=42},
 {center=Vector3.new(-750,0,-5850),radius=300,height=1200,strength=44},
}
-- Two visible lowland encounters; the remaining wildlife is hidden behind mountain silhouettes.
-- Seeded rejection sampling keeps every animal off slopes and makes discovery placement reproducible.
World.Animals={}
local random=Random.new(261004)
local species={"Lion","Elephant","Deer","Fox","Giraffe"}
local launch=Vector3.new(-550,370,534)
local rearCounts={}
local function hiddenBehind(x,z,y)
 for index,peak in Landscape.Peaks do
  if (rearCounts[index] or 0)>=3 then continue end
  local toPeak=Vector2.new(peak.x-launch.X,peak.z-launch.Z)
  local toAnimal=Vector2.new(x-launch.X,z-launch.Z)
  local along=toAnimal:Dot(toPeak.Unit)
  local side=math.abs(toAnimal.X*toPeak.Unit.Y-toAnimal.Y*toPeak.Unit.X)
  if along>toPeak.Magnitude+math.min(peak.rx,peak.rz)*0.7
   and side<math.min(peak.rx,peak.rz)*0.85
   and (Vector2.new(x-peak.x,z-peak.z)).Magnitude<2200 then
   local occluded=false
   for step=1,19 do
    local t=step/20
    local sight=launch:Lerp(Vector3.new(x,y+35,z),t)
    if Landscape.height(sight.X,sight.Z)>sight.Y+50 then occluded=true;break end
   end
   if occluded then return index end
  end
 end
 return nil
end
for attempt=1,60000 do
 if #World.Animals>=15 then break end
 local x=random:NextNumber(-4700,4100);local z=random:NextNumber(-8400,2300)
 local y,_,mountain=Landscape.height(x,z)
 if y<25 or y>110 or mountain or (Vector2.new(x+550,z-534)).Magnitude<1050 then continue end
 local behind
 if #World.Animals<2 then
  if x< -700 or x>800 or z< -1300 or z>200 then continue end
 else
  behind=hiddenBehind(x,z,y)
  if not behind then continue end
 end
 local flat=true
 for _,offset in {Vector2.new(35,0),Vector2.new(-35,0),Vector2.new(0,45),Vector2.new(0,-45)} do
  local level,_,onMountain=Landscape.height(x+offset.X,z+offset.Y)
  if onMountain or math.abs(level-y)>2.5 then flat=false;break end
 end
 if not flat then continue end
 for _,other in World.Animals do if (Vector3.new(x,y,z)-other.position).Magnitude<360 then flat=false;break end end
 if flat then
  table.insert(World.Animals,{id=#World.Animals+1,species=species[#World.Animals%#species+1],
   position=Vector3.new(x,y,z),heading=random:NextNumber(-math.pi,math.pi),scale=0.62,behindPeak=behind})
  if behind then rearCounts[behind]=(rearCounts[behind] or 0)+1 end
 end
end
assert(#World.Animals==15,"Could not place all wildlife on clear lowland sites")
World.Rings={}
local palette={
 Color3.fromRGB(25,206,255),Color3.fromRGB(255,57,187),Color3.fromRGB(65,255,129),
 Color3.fromRGB(152,81,255),Color3.fromRGB(255,195,35),Color3.fromRGB(230,249,255),
}
local function add(position,normal,radius,color,value,group)
 table.insert(World.Rings,{id=#World.Rings+1,position=position,normal=normal.Unit,radius=radius,color=color,value=value,group=group})
end
-- Short optional trails are separated by open space. They reward exploration, not ordered checkpoints.
local routes={
 {center=Vector3.new(-1400,280,-1700),radius=270,start=0.2,count=5},
 {center=Vector3.new(650,240,-1800),radius=240,start=-1.3,count=4},
 {center=Vector3.new(-250,210,-2900),radius=300,start=0.6,count=5},
 {center=Vector3.new(1300,360,-2900),radius=240,start=2.5,count=4},
 {center=Vector3.new(-2750,310,-2850),radius=280,start=-0.5,count=5},
 {center=Vector3.new(1200,400,-4150),radius=310,start=1.1,count=4},
 {center=Vector3.new(-150,360,-5180),radius=250,start=0.4,count=5},
 {center=Vector3.new(-1550,290,-6250),radius=230,start=1.8,count=4},
 {center=Vector3.new(2970,300,-1750),radius=270,start=-1.6,count=5},
 {center=Vector3.new(-2860,230,-4500),radius=220,start=2.1,count=4},
}
for group,route in routes do
 local points={};local raise=0
 for i=1,route.count do
  local a=route.start+(i-1)*0.15
  local p=route.center+Vector3.new(math.cos(a)*route.radius,math.sin(i*0.5)*5,math.sin(a)*route.radius)
  points[i]=p;raise=math.max(raise,Landscape.height(p.X,p.Z)+60-p.Y)
 end
 for i,p in points do
  local a=route.start+(i-1)*0.15
  add(p+Vector3.yAxis*raise,Vector3.new(-math.sin(a),0,math.cos(a)),6,palette[(i+group-2)%#palette+1],10,"Meandering route "..group)
 end
end
for i,tunnel in Landscape.Tunnels do
 add(tunnel.center,tunnel.normal,7,palette[(i-1)%#palette+1],25,tunnel.name)
end
for i,animal in World.Animals do
 local normal=(CFrame.Angles(0,animal.heading,0)).LookVector
 add(animal.position+Vector3.new(0,9,0),normal,6,palette[(i+1)%#palette+1],35,animal.species.." belly")
end
-- One small reward at each summit. It sits just above the tip, with no hole through the mountain.
World.Summits={}
for index,peak in Landscape.Peaks do
 local top=Vector3.new(peak.x,Landscape.height(peak.x,peak.z),peak.z)
 for dx=-peak.rx*0.55,peak.rx*0.55,20 do
  for dz=-peak.rz*0.55,peak.rz*0.55,20 do
   local y=Landscape.height(peak.x+dx,peak.z+dz)
   if y>top.Y then top=Vector3.new(peak.x+dx,y,peak.z+dz) end
  end
 end
 local normal=Vector3.new(math.cos(peak.angle),0,math.sin(peak.angle))
 local center=top+Vector3.yAxis*12
 -- Account for the approach and wingspan as well as the exact summit sample.
 for step=-90,90,6 do
  for side=-4,4,4 do
   local p=top+normal*step+Vector3.new(-normal.Z,0,normal.X)*side
   center=Vector3.new(center.X,math.max(center.Y,Landscape.height(p.X,p.Z)+10),center.Z)
  end
 end
 -- Broad rising air along the near face makes high summit rewards reachable by gliding.
 local towardLaunch=Vector3.new(-550-peak.x,0,534-peak.z).Unit
 local width=math.max(peak.rx,peak.rz)
 table.insert(World.Thermals,{center=Vector3.new(peak.x,0,peak.z)+towardLaunch*width*0.55,
  radius=width*0.85,height=center.Y+180,strength=52})
 table.insert(World.Summits,{position=top,ringPosition=center,peak=index})
 add(center,normal,6,palette[(index+2)%#palette+1],60,"Summit "..index)
end
function World.lift(position:Vector3): number
 local value=0
 for _,zone in World.Thermals do
  local distance=Vector2.new(position.X-zone.center.X,position.Z-zone.center.Z).Magnitude
  if distance<zone.radius and position.Y>20 and position.Y<zone.height then
   value=math.max(value,zone.strength*(1-(distance/zone.radius)^2))
  end
 end
 return value
end
function World.region(position:Vector3): string
 local nearest="Open Water";local distance=math.huge
 for _,region in World.Regions do
  local d=Vector2.new(position.X-region.center.X,position.Z-region.center.Z).Magnitude
  if d<distance then distance=d;nearest=region.name end
 end
 return nearest
end
return World
