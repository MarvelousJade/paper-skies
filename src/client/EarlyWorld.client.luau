-- ReplicatedFirst contains only the small skyline, not the full scenery.
local started=os.clock()
local RF=game:GetService("ReplicatedFirst")
local RunService=game:GetService("RunService")
local Visibility=require(RF:WaitForChild("PaperSurfaceVisibility"))
local source=RF:WaitForChild("PaperEarlyWorld")
source.Name="PaperEarlyWorld";source.Parent=workspace
local controller=Visibility.new(source:WaitForChild("DistantLandscape"),workspace.Terrain,workspace)
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
