-- Own flight has one local visual. Reapply hiding after late replication or stream-in.
local Visibility={}
function Visibility.new(folder,name)
 local tracked={};local connections={}
 local function hide(p)
  if p:IsA("BasePart") then p.LocalTransparencyModifier=1
  elseif p:IsA("Trail") or p:IsA("ParticleEmitter") or p:IsA("Beam") then p.Enabled=false end
 end
 local function remove(model)
  local connection=tracked[model];if connection then connection:Disconnect();tracked[model]=nil end
 end
 local function observe(model)
  if model.Name~=name or tracked[model] then return end
  tracked[model]=model.DescendantAdded:Connect(hide)
  for _,p in model:GetDescendants() do hide(p) end
 end
 table.insert(connections,folder.ChildAdded:Connect(observe))
 table.insert(connections,folder.ChildRemoved:Connect(remove))
 for _,model in folder:GetChildren() do observe(model) end
 return {Destroy=function()
  for _,c in connections do c:Disconnect() end
  for model in tracked do remove(model) end
 end}
end
return Visibility
