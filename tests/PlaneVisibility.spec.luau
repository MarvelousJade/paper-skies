local Visibility=require(game.ReplicatedStorage.PaperFlight.OwnPlaneVisibility)
local folder=Instance.new("Folder");folder.Name="PlaneVisibilityFixture";folder.Parent=workspace
local manager=Visibility.new(folder,"Plane_123")
local passed=0
local function check(v,message) assert(v,message);passed+=1 end
local ok,err=xpcall(function()
 local mine=Instance.new("Model");mine.Name="Plane_123";mine.Parent=folder
 local first=Instance.new("Part");first.Parent=mine;task.wait()
 check(first.LocalTransparencyModifier==1,"Hide initially replicated own plane")
 local late=Instance.new("Part");late.Parent=mine
 local trail=Instance.new("Trail");trail.Enabled=true;trail.Parent=late;task.wait()
 check(late.LocalTransparencyModifier==1 and not trail.Enabled,"Hide late-arriving own geometry and effects")
 mine.Parent=nil;task.wait()
 local replacement=Instance.new("Model");replacement.Name=mine.Name
 local part=Instance.new("Part");part.Parent=replacement;replacement.Parent=folder;task.wait()
 check(part.LocalTransparencyModifier==1,"Stream-in replacement cannot create a second visible plane")
 local other=Instance.new("Model");other.Name="Plane_456"
 local otherPart=Instance.new("Part");otherPart.Parent=other;other.Parent=folder;task.wait()
 check(otherPart.LocalTransparencyModifier==0,"Other players remain visible")
 mine:Destroy()
end,debug.traceback)
manager:Destroy();folder:Destroy();assert(ok,err)
return passed.." delayed-replication and stream-in plane visibility checks passed"
