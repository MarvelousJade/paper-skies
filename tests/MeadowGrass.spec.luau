-- Run in Studio Edit, where the authored terrain is fully available.
local MeadowGrass=require(game.ReplicatedStorage.PaperFlight.MeadowGrass)
local grass=MeadowGrass.new(workspace)
local ok,result=xpcall(function()
 local eye=Vector3.new(1674,74,1490)
 for _=1,40 do grass:Update(eye,0.2) end
 local folder=grass.Folder
 local allocated=folder:GetAttribute("AllocatedClumps")
 assert(folder:GetAttribute("ActiveClumps")>250,"Nearby meadow needs broad blade coverage")
 assert(allocated<=1400 and #folder:GetChildren()<=8400,"Grass must obey the per-client pool budget")
 local visible,farVisible=0,0
 for _,p in folder:GetChildren() do
  assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery and not p.CastShadow,"Grass cannot affect flight or cast expensive tiny shadows")
  if p.Transparency<0.5 then visible+=1 end
  if (p.Position-eye).Magnitude>120 and p.Transparency<0.98 then farVisible+=1 end
 end
 assert(visible>1500,"Grass should be denser near the viewer")
 assert(farVisible>100,"The outer grass layer must remain visible past 120 studs after doubling the old 80-stud range")
 grass:Update(eye+Vector3.yAxis*1000,0.2)
 assert(folder:GetAttribute("ActiveClumps")==0,"High flight must release ground grass")
 for _,p in folder:GetChildren() do assert(p.Transparency==1,"Released grass must be invisible") end
 for _=1,40 do grass:Update(eye,0.2) end
 assert(folder:GetAttribute("ActiveClumps")>250,"Grass must return on descent")
 assert(folder:GetAttribute("AllocatedClumps")==allocated,"Returning to the same meadow must reuse the pool")
 grass:Update(Vector3.new(5800,50,5800),0.2)
 assert(folder:GetAttribute("ActiveClumps")==0,"Open sea must not grow grass")
 return string.format("Grass checks passed: %d pooled clumps, %d visible blade parts; altitude, water, reuse, and collision checks passed",allocated,visible)
end,debug.traceback)
grass:Destroy()
assert(not grass.Folder.Parent,"Grass cleanup must remove all detail parts")
assert(ok,result)
return result
