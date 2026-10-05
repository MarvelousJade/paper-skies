-- Decorative, local-only glow. A slow four-second cycle keeps the valley calm.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local glows = {}
local function add(instance)
 if instance:IsA("BasePart") then glows[instance] = instance:GetAttribute("PulsePhase") or 0 end
end
for _,instance in CollectionService:GetTagged("PaperFlightGlow") do add(instance) end
CollectionService:GetInstanceAddedSignal("PaperFlightGlow"):Connect(add)
CollectionService:GetInstanceRemovedSignal("PaperFlightGlow"):Connect(function(instance) glows[instance]=nil end)
local elapsed, frameTime = 0, 0
RunService.Heartbeat:Connect(function(dt)
 elapsed += dt; frameTime += dt
 if frameTime < 1/20 then return end
 frameTime = 0
 for part, phase in glows do
  if part:IsDescendantOf(workspace) then
   part.Transparency = 0.12 + 0.26 * (0.5 + 0.5 * math.sin(elapsed * math.pi / 2 + phase))
  end
 end
end)
