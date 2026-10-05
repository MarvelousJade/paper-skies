# Geometry audit and model optimization

Measured in Studio on October 5, 2026. These are authored geometry counts, not on-screen counts or measured FPS. Include rear staged models; exclude development backups. The current game uses Roblox terrain, Parts, WedgeParts, and generated solid-model geometry rather than imported tree meshes.

| Category | Models | Before parts | After parts | Before estimated triangles | After estimated triangles |
| --- | ---: | ---: | ---: | ---: | ---: |
| Trees | 846 | 71,477 | 5,424 | 581,900 | 75,090 |
| Small stones | 160 | 6,400 | 160 | 51,200 | 9,600 |
| Combined | 1,006 | 77,877 | 5,584 | 633,100 | 84,690 |

About 92.8% fewer Parts and 86.6% fewer estimated triangles in these categories. WedgePart estimates use eight triangles; block Parts use twelve. UnionOperation counts use Studio's TriangleCount property. These totals do not claim that every authored triangle is rendered in every frame. Device LOD, streaming, culling, and shading affect actual GPU work.

The canonical canopy is now one flat-faceted solid (22 measured triangles in the final template), replacing forty separate wedge Parts. An irregular stone is one 60-triangle solid. A pine tier is one 14-triangle solid. Templates are generated once in Edit, saved in ReplicatedStorage.PaperFlight.SceneryMeshes, and cloned with original dimensions and palette. Published clients do not require EditableMesh permission, dynamic CSG computation, or externally uploaded meshes. Tree heights and branch transforms are checked against the recreated procedural baseline. The solid crowns have convex collision rather than hollow overlapping wedge shells; world flight-clearance tests passed. Palette, species, sites, and faceted silhouettes remain; per-face lighting differs from the old baked wedge tint.

All 160 stone positions were matched against a read-only replay of the source generator before replacements were installed. Full-sized original tree migration copies are session-only, non-archivable backups. Saving/publishing excludes them.

## Mountains and other geometry

Terrain has no single fixed polygon count: Roblox changes its tessellation with distance and device quality. No invented triangle total is assigned to the terrain. The main mountain height field and collision have not been reduced in this pass.

The old startup fallback had 504 wedge Parts but omitted large parts of the mountain footprint and eroded sharp summits. Its replacement serializes 835 complete surface tiles as approximately 167 KB of point and terrain-coverage data, with center samples for narrow peaks. The client builds at most 6,680 visual wedges, in batches prioritizing the initial camera direction. The first batches are parented immediately. These shapes reach the base rather than floating as isolated summit fragments. Terrain-presence checks retain the fallback until nearby detailed terrain is available. This is a bounded temporary visual fallback, not a reduction of terrain tessellation. ReplicatedFirst contains 110 instances after baking, instead of 740.

Rings remain 601 models / 29,289 Parts, predominantly 48 cylinder segments per hoop. Their smooth neon style and pickup geometry are unchanged. The nine animals total 2,205 body Parts (plus mesh/effect objects); the mammoth is largest at 838 Parts. These are the next candidates for shared mesh assets if profiling still shows rendering cost. Cylinder, sphere, and terrain triangles depend on engine tessellation/LOD and are excluded from the simple triangle estimates above.

## Loading and regression checks

Camera-view/frustum streaming remains disabled/default as requested; existing plane replication focus and bounded look-ahead are retained. All nine animal landmarks and their belly rings remain in Workspace as Persistent models, while 286 rear foliage/detail models (1,295 Parts) are still staged until approach.

Passed 85,734 world geometry/layout assertions, 29,360 streaming/detail assertions, and four delayed-replication/stream-in plane-visibility regressions. Fresh Play loaded the optimized solid tree geometry, HUD, and all nine animals without new script errors. Existing local meadow PBR-map warnings remain.

Studio Automatic graphics still culled loaded distant terrain and fallback geometry. A fresh Play check found 6,592 visible fallback Parts present, yet distant mountains were absent until Studio Rendering.QualityLevel was raised to Level21 for inspection. This setting was changed only in Studio; player graphics preferences are not overridden. Model optimization does not guarantee distant drawing at every graphics level. One instrumented local skyline build logged 7.69 seconds while Studio was running; that includes scheduled yields/local work and is not published network join time. Published cold-join timing, low-end FPS, and draw distance must still be checked before claiming the original 20–30-second load is resolved.
