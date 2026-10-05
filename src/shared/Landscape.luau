--!strict
-- Shape references: NPS Rocky Mountain ridges/cirques and Monument Valley mesa silhouettes.
-- Low-frequency meadow relief remains separate from broken mountain surfaces.
local Landscape={}
Landscape.Islands={
 {x=-350,z=-950,rx=2250,rz=2650},{x=1050,z=-4050,rx=2100,rz=2050},
 {x=-2950,z=-3500,rx=980,rz=1200},{x=3000,z=-1350,rx=950,rz=1350},
 {x=-950,z=-6500,rx=1380,rz=800},
 -- Broad lowland extensions on the far sides of the mountains retain soft coastal edges.
 {x=-2600,z=-1900,rx=1300,rz=1500},{x=2700,z=-2350,rx=1400,rz=1700},
 {x=-700,z=-5300,rx=1500,rz=1500},{x=2700,z=-6300,rx=1450,rz=1750},
 {x=-3900,z=-5000,rx=1100,rz=1400},{x=-1000,z=-7600,rx=1500,rz=1150},
 {x=2250,z=1450,rx=1500,rz=1200},
}
Landscape.Peaks={
 {x=-1710,z=-850,rx=650,rz=950,h=1550,style="ridge",angle=-0.22,seed=11},
 {x=1530,z=-1150,rx=640,rz=1050,h=880,style="massif",angle=0.3,seed=23},
 {x=-650,z=-4050,rx=690,rz=890,h=620,style="table",angle=-0.45,seed=37},
 {x=2200,z=-4820,rx=650,rz=900,h=1900,style="spire",angle=0.2,seed=51},
 {x=-2980,z=-3650,rx=560,rz=650,h=430,style="broken",angle=0.65,seed=67},
 {x=-800,z=-6520,rx=610,rz=520,h=730,style="massif",angle=-0.3,seed=79},
 {x=980,z=780,rx=560,rz=660,h=560,style="broken",angle=-0.6,seed=91},
}
function Landscape.baseHeight(x:number,z:number): number
 local h=-30
 for _,island in Landscape.Islands do
  local d=math.sqrt(((x-island.x)/island.rx)^2+((z-island.z)/island.rz)^2)
  local edge=math.clamp((1-d)/0.23,0,1);local coast=edge*edge*(3-2*edge)
  local rolling=61+math.noise(x/1400,z/1550)*28
  h=math.max(h,-24+coast*(rolling+24))
 end
 local lake=math.sqrt(((x-90)/720)^2+((z+2120)/950)^2)
 if lake<1.18 then
  local t=math.clamp((lake-0.82)/0.36,0,1)
  h=math.min(h,-22+t*t*(3-2*t)*115)
 end
 return h
end
-- Low foothill buttresses have ground-level openings, not bores through the main summits.
Landscape.Spurs={
 {name="Fern Arch",x=-980,z=-1100,rx=145,rz=150,h=105,normal=Vector3.zAxis},
 {name="East Foothill Hollow",x=825,z=-700,rx=145,rz=160,h=130,normal=Vector3.zAxis},
 {name="Western Ledge",x=-1450,z=-3850,rx=155,rz=145,h=95,normal=Vector3.xAxis},
 {name="Highland Root Arch",x=1450,z=-5100,rx=155,rz=145,h=115,normal=Vector3.zAxis},
}
Landscape.Tunnels={}
for _,spur in Landscape.Spurs do
 table.insert(Landscape.Tunnels,{name=spur.name,center=Vector3.new(spur.x,Landscape.baseHeight(spur.x,spur.z)+18,spur.z),
  normal=spur.normal,length=420,radius=28,mouth=65})
end
function Landscape.height(x:number,z:number): (number,boolean,boolean)
 local h=Landscape.baseHeight(x,z);local rocky=false;local mountain=false
 for _,peak in Landscape.Peaks do
  local dx=(x-peak.x)/peak.rx;local dz=(z-peak.z)/peak.rz
  local u=dx*math.cos(peak.angle)-dz*math.sin(peak.angle)
  local v=dx*math.sin(peak.angle)+dz*math.cos(peak.angle)
  local d=math.sqrt(u*u+v*v)
  if d<1 then
   local falloff=math.max(0,1-d)
   local shape
   if peak.style=="ridge" then
    local crest=math.max(0,1-math.abs(u+0.12*math.sin(v*5))*2.5)
    shape=falloff^0.7*(0.4+0.6*crest)*(0.86+0.14*math.cos(v*12))
   elseif peak.style=="massif" then
    local left=math.max(0,1-math.sqrt((u+0.26)^2*1.8+(v-0.1)^2*2))
    local right=math.max(0,1-math.sqrt((u-0.25)^2*2+(v+0.18)^2*1.6))
    shape=math.min(falloff*2.5,math.max(left,right)^0.75)
   elseif peak.style=="table" then
    shape=math.min(1,falloff*2.3)^0.65*(0.93+0.07*math.noise(u*4,v*4))
   elseif peak.style=="spire" then
    local rib=0.83+0.17*math.cos(math.atan2(v,u)*5+d*4)
    shape=falloff^1.08*rib
   else
    shape=falloff^0.78*(0.7+0.3*math.abs(math.sin(u*7+v*4)))
   end
   -- Broad gullies and broken strata change the silhouette; small noise only accents rock.
   local gully=(1-math.abs(math.noise(x/210+peak.seed,z/240)))*0.1
   local detail=math.noise(x/72+peak.seed,z/95)*35+math.noise(x/31,z/43+peak.seed)*11
   local top=48+peak.h*math.max(0,shape-gully*falloff)+detail*falloff
   if top>h then
    h=top;mountain=true
    local shelf=math.noise(x/190+peak.seed,z/230)>-0.08
    rocky=not ((d>0.38 and d<0.97 and h<1050 and shelf) or (peak.style=="table" and d<0.32))
   end
  end
 end
 for _,spur in Landscape.Spurs do
  local d=math.sqrt(((x-spur.x)/spur.rx)^2+((z-spur.z)/spur.rz)^2)
  if d<1 then
   local top=Landscape.baseHeight(spur.x,spur.z)+spur.h*math.max(0,1-d*d)^0.65
   if top>h then h=top;rocky=true;mountain=true end
  end
 end
 -- Broad 520 x 540 summit with angular cliff shoulders. No spherical launch mound.
 local dx=math.abs((x+550)/260);local dz=math.abs((z-805)/270)
 local mesa=math.max(dx,dz)
 if mesa<1.75 then
  local slope=math.clamp((1.75-mesa)/0.75,0,1)
  local top=42+307*slope^0.55
  if mesa>1 then top+=math.noise(x/70,z/85)*13*(1-slope) end
  if top>h then h=top;mountain=true;rocky=mesa>1.01 end
 end
 return h,rocky,mountain
end
return Landscape
