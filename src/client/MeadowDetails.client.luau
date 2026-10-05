local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Details=require(RS:WaitForChild("PaperFlight"):WaitForChild("MeadowDetails"))
local details=Details.new(workspace,workspace:WaitForChild("PaperFlightWorld"))
local elapsed=0
local connection=RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<0.15 then return end;elapsed=0
 local camera=workspace.CurrentCamera;if camera then details:Update(camera.CFrame.Position) end
end)
script.Destroying:Connect(function() connection:Disconnect();details:Destroy() end)
