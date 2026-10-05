-- Edit-time solid geometry; saved in the place, no runtime editable-mesh permissions.
local package=game.ReplicatedStorage.PaperFlight
local folder=package:FindFirstChild("SceneryMeshes") or Instance.new("Folder")
folder.Name="SceneryMeshes";folder.Parent=package
local V=Vector3.new
local phi=(1+math.sqrt(5))/2
local vertices={V(-1,phi,0),V(1,phi,0),V(-1,-phi,0),V(1,-phi,0),V(0,-1,phi),V(0,1,phi),V(0,-1,-phi),V(0,1,-phi),V(phi,0,-1),V(phi,0,1),V(-phi,0,-1),V(-phi,0,1)}
local faces={{1,12,6},{1,6,2},{1,2,8},{1,8,11},{1,11,12},{2,6,10},{6,12,5},{12,11,3},{11,8,7},{8,2,9},{4,10,5},{4,5,3},{4,3,7},{4,7,9},{4,9,10},{5,10,6},{3,5,12},{7,3,11},{9,7,8},{10,9,2}}
local function build(name,points,triangles,inside)
 if folder:FindFirstChild(name) then return end
 local cube=Instance.new("Part");cube.Size=V(400,400,400);cube.CFrame=CFrame.new();cube.Anchored=true
 local cutters={}
 for _,face in triangles do
  local a,b,c=points[face[1]],points[face[2]],points[face[3]]
  local n=(b-a):Cross(c-a).Unit;if n:Dot(a-inside)<0 then n=-n end
  local p=Instance.new("Part");p.Size=V(800,800,800)
  local position=inside+n*(n:Dot(a-inside)+400)
  p.CFrame=CFrame.lookAt(position,position+n);table.insert(cutters,p)
 end
 local ok,result=pcall(function() return game:GetService("GeometryService"):SubtractAsync(cube,cutters,{SplitApart=false,CollisionFidelity=Enum.CollisionFidelity.Hull}) end)
 cube:Destroy();for _,p in cutters do p:Destroy() end
 assert(ok,result);assert(#result==1,"Convex template should produce one solid")
 local solid=result[1];solid.Name=name;solid.Anchored=true;solid.UsePartColor=true
 solid.CanTouch=false;solid.Material=Enum.Material.SmoothPlastic
 solid:SetAttribute("CanonicalSize",solid.Size);solid:SetAttribute("CanonicalCenter",solid.Position)
 solid:SetAttribute("TriangleCount",solid.TriangleCount);solid.Parent=folder
end
for _,kind in {"Canopy","Stone"} do
 local points={}
 for i,v in vertices do points[i]=v.Unit*50*(kind=="Stone" and (0.88+(i*7%9)*.025) or 1) end
 build(kind,points,faces,V(0,0,0))
end
local cone={V(0,100,0),V(0,0,0)};local triangles={}
for i=0,5 do table.insert(cone,V(math.cos(i*math.pi/3)*50,0,math.sin(i*math.pi/3)*50)) end
for i=0,5 do table.insert(triangles,{1,3+i,3+(i+1)%6});table.insert(triangles,{2,3+(i+1)%6,3+i}) end
build("Pine",cone,triangles,V(0,25,0))
local prototype=folder:FindFirstChild("CanopyPrototype");if prototype then prototype:Destroy() end
return "Three reusable solid templates: canopy, irregular stone, and six-sided pine tier"
