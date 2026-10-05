--!strict
local Config=require(script.Parent.Config)
local Economy={}
export type Profile={gold:number,levels:{[string]:number},color:number,bestDistance:number,planeId:string,ownedPlanes:{[string]:boolean}}
function Economy.new(): Profile
 return {gold=0,levels={Glide=0,Launch=0,Handling=0},color=1,bestDistance=0,planeId="Dart",ownedPlanes={Dart=true}}
end
-- Both live telemetry and banking use this rule so displayed and awarded gold agree.
-- Inputs are accumulated by the authoritative flight server, never supplied by clients.
function Economy.flightReward(ringGold:number,distance:number):number
 return ringGold+math.floor(distance/Config.DistanceGoldStuds)
end
function Economy.cost(key:string,level:number):number
 return math.floor(Config.Upgrades[key].baseCost*1.65^level)
end
function Economy.buy(profile:Profile,key:string):(boolean,string)
 local upgrade=Config.Upgrades[key]
 if not upgrade then return false,"Unknown upgrade" end
 local level=profile.levels[key]
 if level>=upgrade.maxLevel then return false,"Already fully upgraded" end
 local price=Economy.cost(key,level)
 if profile.gold<price then return false,"Collect more gold first" end
 profile.gold-=price;profile.levels[key]+=1
 return true,upgrade.title.." upgraded!"
end
-- One transaction buys and equips; choosing an owned model never charges twice.
function Economy.selectPlane(profile:Profile,id:string):(boolean,string)
 local plane=Config.Planes[id]
 if not plane then return false,"Unknown plane" end
 if profile.ownedPlanes[id] then profile.planeId=id;return true,plane.name.." equipped!" end
 if profile.gold<plane.price then return false,"Collect more gold for "..plane.name end
 profile.gold-=plane.price;profile.ownedPlanes[id]=true;profile.planeId=id
 return true,plane.name.." unlocked!"
end
return Economy
