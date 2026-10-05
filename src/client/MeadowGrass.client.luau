-- Show individual grass blades only near the viewer, including low flight and walking.
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local MeadowGrass=require(RS:WaitForChild("PaperFlight"):WaitForChild("MeadowGrass"))
local grass=MeadowGrass.new(workspace)
local elapsed=0
local connection=RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<0.12 then return end
 local camera=workspace.CurrentCamera
 if camera then grass:Update(camera.CFrame.Position,elapsed) end
 elapsed=0
end)
script.Destroying:Connect(function() connection:Disconnect();grass:Destroy() end)
