-- ReplicatedFirst contains only the small skyline, not the full scenery.
local started=os.clock()
local RF=game:GetService("ReplicatedFirst")
local RunService=game:GetService("RunService")
local Visibility=require(RF:WaitForChild("PaperSurfaceVisibility"))
local source=RF:WaitForChild("PaperEarlyWorld")
source.Name="PaperEarlyWorld";source.Parent=workspace
local Skyline=require(RF:WaitForChild("PaperSkyline"))
local payload=source:WaitForChild("SkylineData")
local data=game.HttpService:JSONDecode(payload.Value)
-- Build toward the initial camera first, without waiting for ReplicatedStorage or world scripts.
local camera=workspace.CurrentCamera
if camera then table.sort(data,function(a,b)
 local function score(row)
  local offset=Vector3.new(unpack(row[5]))-camera.CFrame.Position
  return offset.Magnitude-(offset.Magnitude>0 and offset.Unit:Dot(camera.CFrame.LookVector) or 0)*10000
 end
 return score(a)<score(b)
end) end
local vista=Skyline.build(data,source,function() RunService.Heartbeat:Wait() end)
local controller=Visibility.new(vista,workspace.Terrain,workspace)
workspace:SetAttribute("PaperSkylineReadySeconds",os.clock()-started)
local elapsed=0
local connection=RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<0.5 then return end;elapsed=0
 local camera=workspace.CurrentCamera;if not camera then return end
 controller:Update(camera.CFrame.Position)
 local world=workspace:FindFirstChild("PaperFlightWorld")
 local rings=world and world:FindFirstChild("Rings")
 for _,marker in source.SummitMarkers:GetChildren() do
  local actual=rings and rings:FindFirstChild(marker.Name)
  local beacon=marker:FindFirstChild("SummitBeacon")
  local anchor=marker:FindFirstChild("SummitBeaconAnchor")
  -- The normal ring controller owns collection visibility once its model arrives.
  if actual and actual:FindFirstChild("SummitBeacon") then marker:Destroy()
  elseif beacon and anchor then beacon.Enabled=(camera.CFrame.Position-anchor.Position).Magnitude>300 end
 end
end)
script.Destroying:Connect(function() connection:Disconnect();source:Destroy() end)
print(string.format("Early skyline ready in %.3fs",os.clock()-started))
