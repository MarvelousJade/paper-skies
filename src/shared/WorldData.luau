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
World.Rings={}
local palette={
 Color3.fromRGB(25,206,255),Color3.fromRGB(255,57,187),Color3.fromRGB(65,255,129),
 Color3.fromRGB(152,81,255),Color3.fromRGB(255,195,35),Color3.fromRGB(230,249,255),
}
local function add(position,normal,radius,color,value,group)
 table.insert(World.Rings,{id=#World.Rings+1,position=position,normal=normal.Unit,radius=radius,color=color,value=value,group=group})
end
-- Short optional trails are separated by open space. They reward exploration, not ordered checkpoints.
local groups={
 {start=Vector3.new(-548.6,342,345),step=Vector3.new(0,-11,-94),count=6},
 {start=Vector3.new(-1070,315,-1000),step=Vector3.new(-76,-5,-68),count=5},
 {start=Vector3.new(0,370,-1400),step=Vector3.new(92,5,-58),count=6},
 {start=Vector3.new(380,270,-2460),step=Vector3.new(-90,-2,-75),count=5},
 {start=Vector3.new(1450,425,-2750),step=Vector3.new(-45,9,-108),count=6},
 {start=Vector3.new(-2700,405,-3000),step=Vector3.new(-58,4,-95),count=5},
 {start=Vector3.new(900,440,-3900),step=Vector3.new(95,11,-70),count=6},
 {start=Vector3.new(-100,490,-5050),step=Vector3.new(-100,0,-95),count=5},
 {start=Vector3.new(-1480,355,-6140),step=Vector3.new(103,4,-60),count=6},
 {start=Vector3.new(2990,325,-1320),step=Vector3.new(10,-3,-110),count=5},
}
for group,route in groups do
 for i=1,route.count do
  local p=route.start+route.step*(i-1)
  -- Keep complete trails clear of slopes and peaks.
  local ground=Landscape.height(p.X,p.Z)
  p=Vector3.new(p.X,math.max(p.Y,ground+100),p.Z)
  add(p,route.step,32,palette[(i+group-2)%#palette+1],10,"Sky trail "..group)
 end
end
for i,tunnel in Landscape.Tunnels do
 for _,side in {-1,1} do
  add(tunnel.center+tunnel.normal*tunnel.mouth*side,tunnel.normal,tunnel.radius-7,palette[(i-1)*2+1],25,tunnel.name)
 end
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
