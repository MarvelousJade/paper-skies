--!strict
local Config=require(script.Parent.Config)
local Economy={}
export type Profile={gold:number,levels:{[string]:number},color:number,bestDistance:number}
function Economy.new(): Profile
 return {gold=0,levels={Glide=0,Launch=0,Handling=0},color=1,bestDistance=0}
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
return Economy
