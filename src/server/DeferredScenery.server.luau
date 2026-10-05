local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Deferred=require(script.Parent:WaitForChild("PaperDeferredScenery"))
local controller=Deferred.new(workspace:WaitForChild("PaperFlightWorld"),game.ServerStorage:WaitForChild("PaperDeferredWorld"))
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<0.1 then return end
 local positions={};local planes=workspace:FindFirstChild("ActivePaperPlanes")
 for _,player in Players:GetPlayers() do
  local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
  if root then table.insert(positions,root.Position) end
  local plane=planes and planes:FindFirstChild("Plane_"..player.UserId)
  if plane and plane.PrimaryPart then table.insert(positions,plane.PrimaryPart.Position) end
 end
 controller:Update(positions,elapsed);elapsed=0
end)
