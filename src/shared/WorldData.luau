--!strict
local Landscape=require(script.Parent.Landscape)
local Config=require(script.Parent.Config)
local World={}
World.Regions=require(script.Parent.Regions)
World.Thermals={
 {center=Vector3.new(-550,0,-700),radius=260,height=900,strength=13},
 {center=Vector3.new(600,0,-400),radius=270,height=950,strength=14},
 {center=Vector3.new(900,0,1950),radius=280,height=1100,strength=14},
 {center=Vector3.new(-600,0,2450),radius=300,height=1200,strength=15},
 {center=Vector3.new(-2200,0,1350),radius=280,height=1000,strength=14},
 {center=Vector3.new(-1850,0,-2100),radius=300,height=1200,strength=15},
}
-- Keep the two field encounters and exactly one distinct discovery behind each mountain.
-- Seeded rejection sampling keeps every animal off slopes and makes discovery placement reproducible.
World.Animals={}
local random=Random.new(261004)
-- Assign by mountain, not sampling order, so each destination has a distinct identity.
local mountainSpecies={"Gorilla","Mammoth","Turtle","SilverFox","Raccoon","Bear","CandyCat"}
local animalCount=#Landscape.Peaks+2
local launch=Vector3.new(-550,370,534)
local rearCounts={}
local function hiddenBehind(x,z,y)
 for index,peak in Landscape.Peaks do
  if rearCounts[index] then continue end
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
 if #World.Animals>=animalCount then break end
 local x=random:NextNumber(-5000,4100);local z=random:NextNumber(-4650,5000)
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
  table.insert(World.Animals,{id=#World.Animals+1,species=behind and mountainSpecies[behind] or (#World.Animals==0 and "Bear" or "Turtle"),
   position=Vector3.new(x,y,z),heading=random:NextNumber(-math.pi,math.pi),scale=0.62,behindPeak=behind})
  if behind then rearCounts[behind]=true end
 end
end
assert(#World.Animals==animalCount,"Could not place one wildlife discovery behind every mountain")
for index in Landscape.Peaks do assert(rearCounts[index],"Missing mountain encounter "..index) end
-- Keep the established second field encounter behind launch.
-- Default launch faces -Z; +Z places this turtle in the meadow behind the player.
local rearField=World.Animals[2]
rearField.position=Vector3.new(-550,Landscape.height(-550,1850),1850)
rearField.heading=0
-- Authored body offsets shorten limbs without flattening the head, shell, or torso.
local lowStance={
 Bear={drop=22,ringY=0,passageY=8},
 SilverFox={drop=23,ringY=-1,passageY=8},
 Raccoon={drop=28,ringY=-4,passageY=6.5},
 Turtle={drop=36,ringY=-7,passageY=5.5},
 CandyCat={drop=26,ringY=-1,passageY=8},
}
for _,animal in World.Animals do
 local stance=lowStance[animal.species]
 animal.bodyDrop=stance and stance.drop or 0
 animal.bellyRingY=stance and stance.ringY or 18
 animal.bellyRingRadius=stance and 18 or 12
 animal.passageY=stance and stance.passageY or 18
 animal.forwardMeadow=animal.behindPeak==nil and animal.position.Z<launch.Z
 animal.rearMeadow=animal.behindPeak==nil and animal.position.Z>launch.Z
end
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
 {center=Vector3.new(-1700,230,-1450),radius=270,start=0.2,count=10},
 {center=Vector3.new(400,210,-1650),radius=240,start=-1.3,count=10},
 {center=Vector3.new(-50,190,-2650),radius=300,start=0.6,count=10},
 {center=Vector3.new(2000,210,-500),radius=240,start=2.5,count=10},
 {center=Vector3.new(2200,240,2400),radius=280,start=-0.5,count=10},
 {center=Vector3.new(500,240,2250),radius=310,start=1.1,count=10},
 {center=Vector3.new(-850,210,3600),radius=250,start=0.4,count=10},
 {center=Vector3.new(-2500,200,2300),radius=230,start=1.8,count=10},
 {center=Vector3.new(-3200,230,0),radius=270,start=-1.6,count=10},
 {center=Vector3.new(-2700,210,-1750),radius=220,start=2.1,count=10},
}
-- Additional optional routes bridge the open fields between mountain approaches.
for _,route in {
 {center=Vector3.new(-1100,165,-850),radius=170,start=1.8,count=10},
 {center=Vector3.new(220,145,-1050),radius=160,start=2.8,count=10},
 {center=Vector3.new(-1550,155,-150),radius=170,start=1.2,count=10},
 {center=Vector3.new(800,170,750),radius=170,start=-0.5,count=10},
 {center=Vector3.new(150,145,1800),radius=180,start=2.5,count=10},
 {center=Vector3.new(-1950,165,850),radius=170,start=-0.7,count=10},
 {center=Vector3.new(-1950,145,1850),radius=160,start=0.4,count=10},
 {center=Vector3.new(-650,165,2700),radius=180,start=0.3,count=10},
} do table.insert(routes,route) end
-- Longer chains and six outer routes give more consecutive pickups in every direction.
-- Keep the open launch choice and the existing 24-stud spacing within each curve.
for _,route in {
 {center=Vector3.new(-1350,190,-2150),radius=230,start=0.5,count=10},
 {center=Vector3.new(700,200,-2800),radius=240,start=1.8,count=10},
 {center=Vector3.new(2850,230,-200),radius=260,start=2.2,count=10},
 {center=Vector3.new(3150,220,2400),radius=240,start=-1.6,count=10},
 {center=Vector3.new(-1050,210,4400),radius=250,start=-0.4,count=10},
 {center=Vector3.new(-4250,230,-450),radius=260,start=0.8,count=10},
} do table.insert(routes,route) end
-- High trails sit along the near-side mountain updrafts. Higher peaks offer
-- higher rewards to explore without changing aircraft ceilings or lift strength.
for _,peak in Landscape.Peaks do
 local towardLaunch=Vector3.new(launch.X-peak.x,0,launch.Z-peak.z).Unit
 local width=math.max(peak.rx,peak.rz)
 local center=Vector3.new(peak.x,math.clamp(peak.h*0.72,480,1450),peak.z)+towardLaunch*width*0.55
 table.insert(routes,{center=center,radius=170,start=math.atan2(towardLaunch.Z,towardLaunch.X)-0.6,count=10,highSky=true})
end
for group,route in routes do
 local points={};local raise=0
 for i=1,route.count do
  local a=route.start+(i-1)*24/route.radius
  local p=route.center+Vector3.new(math.cos(a)*route.radius,math.sin(i*0.5)*5,math.sin(a)*route.radius)
  points[i]=p;raise=math.max(raise,Landscape.height(p.X,p.Z)+60-p.Y)
 end
 for i,p in points do
  local a=route.start+(i-1)*24/route.radius
  add(p+Vector3.yAxis*raise,Vector3.new(-math.sin(a),0,math.cos(a)),12,palette[(i+group-2)%#palette+1],10,"Meandering route "..group)
  World.Rings[#World.Rings].highSky=route.highSky==true
 end
end
for i,tunnel in Landscape.Tunnels do
 add(tunnel.center,tunnel.normal,14,palette[(i-1)%#palette+1],25,tunnel.name)
end
for i,animal in World.Animals do
 -- A complete hoop faces the animal's side, between its front and rear legs.
 local normal=(CFrame.Angles(0,animal.heading,0)).RightVector
 -- A broad circle can sit partly below ground; the visible cap is the flight gate.
 add(animal.position+Vector3.new(0,animal.bellyRingY,0),normal,animal.bellyRingRadius,palette[(i+1)%#palette+1],35,animal.species.." belly")
 World.Rings[#World.Rings].groundArc=animal.bodyDrop>0
 World.Rings[#World.Rings].passagePosition=animal.position+Vector3.yAxis*animal.passageY
 World.Rings[#World.Rings].animalId=animal.id
end
-- One reward at each summit. It sits just above the tip, with no hole through the mountain.
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
 local center=top+Vector3.yAxis*19
 -- Account for the approach and wingspan as well as the exact summit sample.
 for step=-90,90,6 do
  for side=-4,4,4 do
   local p=top+normal*step+Vector3.new(-normal.Z,0,normal.X)*side
   center=Vector3.new(center.X,math.max(center.Y,Landscape.height(p.X,p.Z)+17),center.Z)
  end
 end
 -- Broad rising air along the near face makes high summit rewards reachable by gliding.
 local towardLaunch=Vector3.new(-550-peak.x,0,534-peak.z).Unit
 local width=math.max(peak.rx,peak.rz)
 table.insert(World.Thermals,{center=Vector3.new(peak.x,0,peak.z)+towardLaunch*width*0.55,
  radius=width*0.85,height=center.Y+260,strength=18})
 table.insert(World.Summits,{position=top,ringPosition=center,peak=index})
 -- Higher discoveries pay more, while low summits keep the existing 60 gold.
 local value=top.Y>=1600 and 120 or top.Y>=1100 and 100 or top.Y>=750 and 80 or 60
 add(center,normal,12,Color3.fromRGB(255,214,105),value,"Summit "..index)
 World.Summits[#World.Summits].ringId=#World.Rings
end
-- Both lobes of each double summit deserve a discovery. Search the opposite
-- local lobe instead of guessing its height or placing a reward inside the rock.
for index,peak in Landscape.Peaks do
 if peak.style~="massif" then continue end
 local primary=World.Summits[index].position
 local function localU(p)
  return (p.X-peak.x)/peak.rx*math.cos(peak.angle)-(p.Z-peak.z)/peak.rz*math.sin(peak.angle)
 end
 local sign=localU(primary)>0 and -1 or 1
 local top=Vector3.new(peak.x,-math.huge,peak.z)
 for dx=-peak.rx*0.6,peak.rx*0.6,8 do for dz=-peak.rz*0.6,peak.rz*0.6,8 do
  local p=Vector3.new(peak.x+dx,Landscape.height(peak.x+dx,peak.z+dz),peak.z+dz)
  if localU(p)*sign>0.1 and p.Y>top.Y then top=p end
 end end
 local normal=Vector3.new(math.cos(peak.angle),0,math.sin(peak.angle))
 local center=top+Vector3.yAxis*19
 for step=-90,90,6 do for side=-4,4,4 do
  local p=top+normal*step+Vector3.new(-normal.Z,0,normal.X)*side
  center=Vector3.new(center.X,math.max(center.Y,Landscape.height(p.X,p.Z)+17),center.Z)
 end end
 local value=top.Y>=750 and 80 or 60
 add(center,normal,12,Color3.fromRGB(255,214,105),value,"Summit "..index.." second tip")
 table.insert(World.Summits,{position=top,ringPosition=center,peak=index,ringId=#World.Rings,secondary=true})
end
-- Follow the mountain surface, then resample by distance so climbs keep evenly
-- spaced pickups. A footprint envelope leaves room for the entire tilted hoop.
World.MountainRoutes={}
local function mountainRoute(name,peakIndex,path,closed)
 local dense={};local cumulative={0};local total=0
 for i=0,800 do
  local p=path(i/800);local y=Landscape.height(p.X,p.Z)
  for dx=-20,20,10 do for dz=-20,20,10 do
   local height=Landscape.height(p.X+dx,p.Z+dz);y=math.max(y,height)
  end end
  dense[i+1]=Vector3.new(p.X,y+28,p.Z)
 end
 -- A climbing route must not dive into each gully and immediately turn uphill.
 if not closed then
  for i=2,#dense do
   dense[i]=Vector3.new(dense[i].X,math.max(dense[i].Y,dense[i-1].Y),dense[i].Z)
  end
 end
 -- Smooth terrain ripples without dipping below the clearance envelope.
 for pass=1,3 do
  local smooth=table.clone(dense)
  for i=2,#dense-1 do
   local y=(dense[i-1].Y+dense[i].Y*2+dense[i+1].Y)/4
   smooth[i]=Vector3.new(dense[i].X,math.max(dense[i].Y,y),dense[i].Z)
  end
  dense=smooth
 end
 for i=2,#dense do total+=(dense[i]-dense[i-1]).Magnitude;cumulative[i]=total end
 local count=math.max(2,math.floor(total/26));local spacing=total/count
 local points={};local segment=2
 for i=0,(closed and count-1 or count) do
  local target=i*spacing
  while segment<#dense and cumulative[segment]<target do segment+=1 end
  local span=cumulative[segment]-cumulative[segment-1]
  points[#points+1]=dense[segment-1]:Lerp(dense[segment],math.clamp((target-cumulative[segment-1])/span,0,1))
 end
 local ids={}
 for i,p in points do
  local before=points[i-1] or (closed and points[#points] or p)
  local after=points[i+1] or (closed and points[1] or p)
  add(p,after-before,12,palette[(i-1)%#palette+1],10,name)
  local ring=World.Rings[#World.Rings];ring.mountainRoute=true;ring.peak=peakIndex
  ids[i]=ring.id
 end
 table.insert(World.MountainRoutes,{name=name,peak=peakIndex,closed=closed==true,ids=ids})
end
local ridge=Landscape.Peaks[1]
local near=math.atan2(launch.Z-ridge.z,launch.X-ridge.x)
mountainRoute("Ridge face ascent",1,function(t)
 local a=near+0.1*math.sin(t*math.pi);local r=0.82-0.72*t
 return Vector3.new(ridge.x+math.cos(a)*ridge.rx*r,0,ridge.z+math.sin(a)*ridge.rz*r)
end,false)
local spire=Landscape.Peaks[4]
local start=math.atan2(launch.Z-spire.z,launch.X-spire.x)
mountainRoute("Cloudspire spiral",4,function(t)
 local a=start+t*math.pi*3;local r=0.8-0.71*t
 return Vector3.new(spire.x+math.cos(a)*spire.rx*r,0,spire.z+math.sin(a)*spire.rz*r)
end,false)
local mesa=Landscape.Peaks[3]
mountainRoute("Plateau crown loop",3,function(t)
 local a=t*math.pi*2
 return Vector3.new(mesa.x+math.cos(a)*mesa.rx*0.32,0,mesa.z+math.sin(a)*mesa.rz*0.32)
end,true)
function World.lift(position:Vector3,planeId:string?): number
 -- Aircraft attributes change usable rising air; there is no hard positional ceiling.
 local plane=Config.Planes[planeId or "Dart"] or Config.Planes.Dart
 local altitudeFade=math.clamp((plane.airCeiling-position.Y)/Config.ThermalFadeHeight,0,1)
 local efficiency=plane.thermalEfficiency
 local value=0
 for _,zone in World.Thermals do
  local distance=Vector2.new(position.X-zone.center.X,position.Z-zone.center.Z).Magnitude
  if distance<zone.radius and position.Y>20 and position.Y<zone.height then
   value=math.max(value,zone.strength*(1-(distance/zone.radius)^2)*altitudeFade*efficiency)
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
