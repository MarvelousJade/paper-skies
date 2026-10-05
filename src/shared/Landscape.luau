--!strict
-- Broad low-frequency slopes keep grassy ground smooth. Mountain detail is confined to rock.
local Landscape={}
Landscape.Islands={
 {x=-350,z=-950,rx=2250,rz=2650},
 {x=1050,z=-4050,rx=2100,rz=2050},
 {x=-2950,z=-3500,rx=980,rz=1200},
 {x=3000,z=-1350,rx=950,rz=1350},
 {x=-950,z=-6500,rx=1380,rz=800},
}
Landscape.Peaks={
 {x=-1710,z=-850,rx=650,rz=950,h=650},
 {x=1530,z=-1150,rx=640,rz=1050,h=720},
 {x=-650,z=-4050,rx=690,rz=890,h=610},
 {x=2200,z=-4820,rx=650,rz=900,h=780},
 {x=-2980,z=-3650,rx=560,rz=650,h=430},
 {x=-800,z=-6520,rx=610,rz=520,h=480},
 {x=-650,z=-1500,rx=300,rz=330,h=220},
 {x=880,z=-3350,rx=360,rz=360,h=290},
}
Landscape.Tunnels={
 {name="Meadow Arch",center=Vector3.new(-650,158,-1500),normal=Vector3.new(0,0,-1),length=720,radius=49,mouth=70},
 {name="Azure Mountain Pass",center=Vector3.new(1530,335,-1150),normal=Vector3.new(1,0,0),length=1600,radius=70,mouth=220},
 {name="Lake Stone Gate",center=Vector3.new(880,187,-3350),normal=Vector3.new(0,0,-1),length=820,radius=57,mouth=90},
}
function Landscape.height(x:number,z:number): (number,boolean)
 local h=-30
 for _,island in Landscape.Islands do
  local d=math.sqrt(((x-island.x)/island.rx)^2+((z-island.z)/island.rz)^2)
  local edge=math.clamp((1-d)/0.23,0,1)
  local coast=edge*edge*(3-2*edge)
  local rolling=61+math.noise(x/950,z/1050)*46+math.noise(x/470,z/510)*10
  h=math.max(h,-24+coast*(rolling+24))
 end
 -- A broad lagoon connects to the open sea, instead of isolated puddles.
 local lake=math.sqrt(((x-90)/720)^2+((z+2120)/950)^2)
 if lake<1.18 then
  local t=math.clamp((lake-0.82)/0.36,0,1)
  h=math.min(h,-22+t*t*(3-2*t)*115)
 end
 local rocky=false
 for _,peak in Landscape.Peaks do
  local dx=(x-peak.x)/peak.rx;local dz=(z-peak.z)/peak.rz
  local d=math.sqrt(dx*dx+dz*dz)
  if d<1 then
   local ridge=math.max(0,1-d)^1.4
   local detail=math.noise(x/145,z/170)*38*ridge
   local top=48+peak.h*ridge+detail
   if top>h then h=top;rocky=ridge>0.085 end
  end
 end
 -- Retain the established launch position and support the stone deck.
 local cliff=(x+550)^2+(z-653)^2
 if cliff<188^2 then
  local top=169+math.sqrt(188^2-cliff)
  if top>h then h=top;rocky=true end
 end
 return h,rocky
end
return Landscape
