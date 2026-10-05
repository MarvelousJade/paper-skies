-- Run after rebuilding the world. Check real collision, not just authored coordinates.
local package=game.ReplicatedStorage.PaperFlight
local Landscape=require(package.Landscape)
local World=require(package.WorldData)
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={workspace.Terrain,workspace.PaperFlightWorld}
local passed=0
for _,tunnel in Landscape.Tunnels do
 local frame=CFrame.lookAt(tunnel.center,tunnel.center+tunnel.normal)
 for _,offset in {Vector3.zero,frame.RightVector*20,-frame.RightVector*20,Vector3.yAxis*20,-Vector3.yAxis*20} do
  local hit=workspace:Raycast(tunnel.center-tunnel.normal*tunnel.length/2+offset,tunnel.normal*tunnel.length,params)
  assert(not hit,tunnel.name.." must remain open across its full length")
  passed+=1
 end
end
for _,ring in World.Rings do
 local hit=workspace:Raycast(ring.position-ring.normal*12,ring.normal*24,params)
 assert(not hit,"Ring "..ring.id.." opening is blocked")
 passed+=1
end
return string.format("%d world-clearance checks passed",passed)
