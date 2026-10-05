-- Rebuild at authored encounter transforms; staged positions and actual geometry must agree.
local package=game.ReplicatedStorage.PaperFlight
local World=require(package.WorldData);local Landscape=require(package.Landscape)
local Wildlife=require(package.ReferenceAnimals)
local folder=workspace.PaperFlightWorld.PaperAnimals
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={workspace.Terrain};params.IgnoreWater=true
local function ground(x,z)
 local y=Landscape.height(x,z)
 local hit=workspace:Raycast(Vector3.new(x,y+40,z),Vector3.new(0,-80,0),params)
 assert(hit,"Animal feet must stand on loaded terrain")
 return hit.Position.Y
end
local fresh={}
for _,animal in World.Animals do
 local model=assert(Wildlife.build(animal,nil,ground))
 model:SetAttribute("AuthoredPosition",animal.position)
 model:SetAttribute("AuthoredHeading",animal.heading)
 -- Only nine landmarks: make discovery silhouettes reliable at a distance.
 model.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
 table.insert(fresh,model)
end
for _,parent in {folder,game.ServerStorage:FindFirstChild("PaperDeferredWorld")} do
 if parent then for _,object in parent:GetChildren() do
  if object:GetAttribute("Species") and object:GetAttribute("AnimalId") then object:Destroy() end
 end end
end
for _,model in fresh do model.Parent=folder end
return "Nine wildlife landmarks restored to authored positions with terrain-grounded feet"
