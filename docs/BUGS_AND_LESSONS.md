# Paper Skies bugs and engineering lessons

This log explains the bugs, design hurdles, and testing problems documented during development of Paper Skies. Each entry records what happened, why, what changed, and what evidence supports the result. It is intended for interview preparation and future debugging.

Prepared on October 4, 2026 against the current working tree. Baseline: `d3fe27b`. Last committed exploration snapshot: `5fd61e2`. The current mountain and discovery changes are uncommitted. Intermediate experiments were not individually committed, so some observations are recorded from the development session rather than recoverable as separate Git revisions.

The implementation and automated checks were produced with AI assistance. The project owner supplied requirements, visual references, and playtest feedback. The interview examples below describe the project; use first-person claims only for work you personally performed or can reproduce and explain.

## How to read the evidence

- **Confirmed defect:** observed failure or a directly verified mismatch in the code.
- **Design iteration:** working behavior that did not meet the intended experience.
- **Testing hurdle:** a problem with the verification method or development workflow.
- **Preventive safeguard:** protection implemented without evidence that the corresponding exploit or failure actually occurred.
- **Open limitation:** incomplete work or unverified behavior.

The latest recorded verification is **27 flight, pickup, and economy assertions plus 414 world geometry and layout assertions**. These are 441 assertions, not 441 separate end-to-end gameplay tests. This documentation task did not rerun the game.

## Confirmed defects and fixes

### B01 Collected rings used the wrong scene folder

**Symptom:** Collection feedback could run without immediately hiding the visible ring.

**Cause:** The client searched for `PaperFlightWorld.Gold`, while the world builder created `PaperFlightWorld.Rings`. The missing folder was handled with a nil guard, so the hiding branch silently did nothing instead of reporting an error. This mismatch is visible in the diff from `5fd61e2`.

**Fix:** Change the client lookup to `Rings`. Keep ring IDs as the identity used for collection state. An early return also suppresses repeated feedback for an already collected ID; that duplicate guard is a safeguard, not evidence of a previously observed server double payout.

**Verification:** In a temporary Play session, ring 1 was kept loaded and the server sent one pickup event. All **48** visual segments had `LocalTransparencyModifier = 1`; one loaded chime played. Sending the event again left the sound count at one. The session was stopped afterward to remove the test setup.

**Limit:** This was a client presentation integration check. It did not fly a plane through the ring or prove the server awarded gold in that same test. Crossing and economy behavior have separate assertions.

**Interview explanation:** “A scene rename left the client using an old folder name. Because the lookup failed safely, there was no obvious exception. Tracing the event through to the rendered object exposed the mismatch. The fix was small; the useful part was testing the visible result and a duplicate event.”

**Code:** [Client collection handler](../src/client/FlightClient.client.luau), [ring builder](../tools/BuildExplorationWorld.luau).

**Follow-up:** Automate the presentation check and validate required scene folders during startup so a future rename fails visibly.

### B02 Wildlife placement exhausted valid sites

**Symptom:** Requiring the updated world module failed with `Could not place all wildlife on clear lowland sites`.

**Cause:** The new placement rules required most animals to be on flat land behind mountains, hidden from the launch viewpoint, separated from each other, and away from spawn. The old coastline left too little suitable ground in those locations. Random sampling could not satisfy all the conditions. The exact share of failures caused by each rejection rule was not instrumented.

**Fix:** Expand the lowlands behind the mountains, enlarge the candidate sampling area, and retain the terrain and spacing checks. Use a fixed random seed so a failing layout can be reproduced. Keep the assertion that all 15 sites must be placed rather than silently generating fewer animals.

**Verification:** The module loaded with 15 animals: two introductory encounters and 13 behind mountains. Tests confirmed all are off mountain terrain and that the rear animals are occluded by terrain along sampled sight lines from launch. The expanded meadows were visually inspected.

**Limit:** Those sight-line samples verify the intended launch view, not concealment from every possible camera position.

**Interview explanation:** “The generator failed because the available world could not satisfy the new placement constraints. More random attempts would not create land. We changed the terrain and sampling domain, kept the safety constraints, and made the result reproducible.”

**Code:** [Placement and hiddenBehind](../src/shared/WorldData.luau), [island extensions](../src/shared/Landscape.luau), [world assertions](../tests/World.spec.luau).

**Follow-up:** Count rejection reasons and report the number of accepted sites when generation fails.

### B03 Distant terrain proxies appeared as large floating triangles

**Symptom:** An intermediate visibility experiment showed conspicuous colored triangles above or across the scenery.

**Cause:** Coarse, full-map proxy tiles bridged terrain height changes. A large planar approximation could sit above detailed terrain between its samples, especially around valleys and coastlines.

**Fix:** Restrict proxies to mountain areas above elevation 170; reduce tile size from 512 to 256 studs; lower proxy vertices using nearby height samples and a 28-stud offset. Hide them in Edit mode. In Play, fade nearby proxies out between approximately 1,100 and 1,650 studs from the camera. They do not collide with the plane.

**Verification:** Later Edit captures no longer showed the original triangle artifacts. A Play capture showed distant mountain silhouettes from the launch area.

**Limit:** The sampling is an approximation, not a mathematical guarantee that every proxy lies below every point of detailed terrain. No full device or camera sweep has been completed.

**Interview explanation:** “A cheap distant representation improved visibility but introduced its own artifacts. Narrowing it to important landmarks, using smaller tiles, and fading it near the camera improved the result without keeping every tree loaded.”

**Code:** [DistantLandscape builder](../tools/BuildExplorationWorld.luau), [client fade loop](../src/client/FlightClient.client.luau).

**Follow-up:** Profile frame time and memory, inspect transitions from multiple directions, and check lower-memory devices before claiming a performance improvement.

## Design and gameplay hurdles

### D01 Mountains and grass did not match the intended world

**Symptom:** Feedback described rounded or overly smooth mountains, excessive grass detail, and a launch mountain that looked like a ball.

**Reason:** Earlier generic shapes and relief did not distinguish meadow surfaces, dramatic mountain silhouettes, and a playable flat launch area.

**Change:** Separate broad low-frequency meadow relief from ridge, massif, table, spire, and broken mountain profiles. Use gullies and surface variation on the mountains. Create a broad flat launch plateau with angular shoulders. Disable decorative grass blades while retaining grassy coverage. Add trees only where elevation, material, and slope allow them.

**Evidence:** Screenshots were reviewed; plateau sample assertions pass. The current scene contains 143 trees above elevation 180.

**Lesson:** Turn visual feedback into separate measurable requirements: silhouette, surface detail, vegetation density, and usable flat space. Fewer details are a design choice here; measured FPS gains have not been established.

**Code:** [Landscape](../src/shared/Landscape.luau), [terrain and trees](../tools/BuildExplorationWorld.luau).

### D02 Reward routes guided players too directly from spawn

**Symptom:** Rings formed an obvious forward route, reducing the sense that players could choose where to explore.

**Reason:** The arrangement still reflected the project's earlier time-trial structure, while the objective had changed to exploration and gold collection.

**Change:** Replace the introductory rail with optional curved clusters farther away. Add rewards at animal bellies, foothills, and mountain tips. Set the launch yaw limit to `math.pi` instead of 80 degrees so the control limits support aiming around the full circle.

**Evidence:** Tests check that all ring centers are more than 1,000 horizontal studs from spawn, and that neighboring sky-route rings are 25–48 studs apart. The actual configured curves produce roughly 33–46 stud spacing.

**Lesson:** Updating the map alone is insufficient if control limits still assume the old route.

**Code:** [WorldData](../src/shared/WorldData.luau), [MaxAimYaw](../src/shared/Config.luau), [world assertions](../tests/World.spec.luau).

### D03 Mountain rewards needed readable and clear approaches

**Symptom:** The user reported rings in mountain bodies and requested rewards near tips, sides, and low openings instead of large holes through the middle.

**Reason:** Reward placement and mountain shapes needed to be designed together. A ring's center coordinate alone says little about the space required to approach and leave it.

**Change:** Put four passages through low foothill spurs. Find each mountain's highest sampled point and place a small ring just above it. Check surrounding terrain along the approach before setting its height. Exclude trees from reward approaches.

**Evidence:** Actual-scene raycasts pass for ring openings, foothill approaches, and summit approaches, including lateral and vertical offsets. The highest summit ring was visually inspected.

**Limit:** These sampled paths do not prove every possible maneuver is safe or that a complete flight can reach each reward.

**Lesson:** Validate the surrounding playable volume, not just the decorative object.

**Code:** [Summit placement](../src/shared/WorldData.luau), [passages](../src/shared/Landscape.luau), [clearance checks](../tests/World.spec.luau).

### D04 Smaller animals still needed a flyable belly route

**Symptom:** Animals dominated the scene; the user requested smaller animals and more hidden discoveries.

**Reason:** Uniformly shrinking scenery also shrinks its usable gaps. A plane that fits below a large model may not fit below its smaller version.

**Change:** Scale animals to 0.62 of their previous linear size. Lower belly-ring centers from 14 to 9 studs above the site and reduce their radius from 7 to 6. Compute foot contact using the final scaled horizontal positions. Keep trees away from animal sites.

**Evidence:** Tests check scale, placement, and 140-stud belly corridors with offsets representing the plane's width and height. A follow-up geometry inspection found leg extents near site elevations; the smaller wildlife was visually inspected.

**Limit:** A screenshot made a distant animal appear to float. The follow-up inspection did not establish a floating-model defect, so it should not be presented as a confirmed bug that was fixed.

**Lesson:** Art-scale changes affect collision clearance and ground contact.

**Code:** [foldedAnimal and scaledFoot](../tools/BuildExplorationWorld.luau), [animal and ring data](../src/shared/WorldData.luau).

### D05 The aiming preview was dotted and visually detached

**Symptom:** The user wanted one continuous curved line. The old preview used individual visible spheres.

**Reason:** The preview rendered isolated simulated positions. It also advanced the simulation before displaying its first point, leaving the path disconnected from the held plane.

**Change:** Use 25 invisible anchors joined by 24 beam segments. Anchor the first point to the held plane and use sampled flight positions for subsequent points.

**Evidence:** A live aiming screenshot confirmed a continuous line.

**Limit:** The preview uses the shared basic flight simulation; it is not a collision-aware guarantee of the full future route, especially when environmental lift changes.

**Lesson:** Reusing simulation logic improves consistency, while visual attachment still requires separate presentation work.

**Code:** [preview and aiming render update](../src/client/FlightClient.client.luau).

### D06 Higher landmarks needed a way to reach them

**Symptom:** Raising mountains and placing summit rewards introduced a new traversal requirement.

**Reason:** A paper glider loses speed while climbing. A high visual destination does not automatically become reachable with the existing launch energy.

**Change:** Add broad rising-air zones along mountain faces, extending above the summit rewards. The world now has 13 thermal zones.

**Evidence:** Thermal calculations have assertions, and summit approaches are geometrically clear.

**Status:** Full flights to every new summit remain unverified. Do not describe all summit routes as proven reachable.

**Lesson:** World art, flight mechanics, and reward placement must be tested together.

**Code:** [summit thermals and lift](../src/shared/WorldData.luau), [flight simulation](../src/shared/Flight.luau).

### D07 Large world rendering required bounds and detail coordination

**Problem:** Expanding land changes more than island shapes: terrain generation, ocean coverage, placement sampling, and permitted flight bounds must agree.

**Change:** Expand the authored terrain footprint, extend ocean tiles, update flight bounds, and sample the new lowlands. Generate terrain in bounded chunks; write changing surface bands rather than allocating one giant voxel volume. Use a version guard to avoid rebuilding unchanged terrain.

**Historical implementation notes:** The builder already tiled water into 2,000-stud sections to accommodate part-size limits and removed competing atmosphere effects that could obscure the view. These explanations are recorded in the earlier builder. This log does not have a preserved before/after runtime measurement for either issue.

**Evidence:** The latest build completed 1,840 terrain tiles. Expanded coastlines and rear meadows were visually inspected.

**Lesson:** Keep procedural generation reproducible, bounded, and observable. A completed build is not a mobile performance benchmark.

**Code:** [terrain guard, water, and lighting](../tools/BuildExplorationWorld.luau), [world bounds](../src/shared/Config.luau).

## Testing and development hurdles

### T01 A temporary autopilot did not prove physical collection

**Observed:** A QA attempt replaced a required flight module function with temporary steering logic and launched toward a ring. The flight did not hit the target; the counters reported zero ring events and zero chime plays.

**Cause:** Not established. The injected function may not have been the one used by the running client script, or live steering may have overridden the intended behavior. Neither hypothesis was proven.

**Response:** Stop relying on that attempt. Verify geometry and crossing logic separately, then inject a server pickup event to test visual hiding and sound. Stop Play to remove temporary state.

**Lesson:** A failed test setup does not identify the product's root cause. Report the uncertainty and narrow the experiment.

**Follow-up:** Build a dedicated reproducible flight scenario before claiming a complete automated collection playtest.

### T02 A ring disappeared from the test client between checks

**Observed:** After requesting streaming around ring 1, a later test attempted to call `GetDescendants` on a nil ring reference.

**Likely cause:** The remote ring had streamed out again. It was far from the player's normal focus; a request to load an area did not make the test fixture persist indefinitely. The missing instance was observed; the exact unload event was not instrumented.

**Response:** Temporarily set that ring model to Persistent on the test server, wait for the client model, and rerun the presentation check. Stop Play afterward. Production rings retain their normal Atomic configuration.

**Result:** The controlled check verified 48 hidden segments, one sound, and duplicate suppression.

**Lesson:** Integration tests need explicit readiness and stable fixtures. Avoid changing production streaming policy just to make a test pass.

### T03 Source files and Studio are separate copies

**Problem:** Editing repository files does not automatically update scripts in this Studio setup. Already-required modules can also retain state within a running session.

**Workflow:** Generate the installer from source, replace module instances during installation, install in Edit mode, and enter a fresh Play session. The installer uses collision-safe Luau long-string delimiters when embedding source.

**Evidence:** The generator implements module replacement; the README records the manual sync workflow. This is a workflow safeguard, not a claim that every earlier unexpected result was caused by module caching.

**Lesson:** Establish which source version the game is actually running before diagnosing behavior.

**Code:** [installer generator](../tools/GenerateExplorationInstaller.py).

### T04 Moving the repository left the old workspace path behind

**Observed:** The project and Git history moved to `G:\Roblox Projects\Roblox Paper Plane`, while the tool workspace still pointed to the old C drive folder. The user reported that Windows kept the empty old folder locked.

**Response:** Use the G drive path explicitly for repository operations. Save authorized changes there through the available filesystem approval mechanism. Do not treat the empty old directory as the current project or force-delete the locked folder.

**Evidence:** Git status and log were read from G; generated files and documentation were written there.

**Lesson:** Verify the repository root when tools, editors, and filesystem locations disagree.

## Safeguards that are not historical bug claims

| Risk | Current protection | Evidence and boundary |
| --- | --- | --- |
| Missing a ring at high speed | Swept segment crossing through the ring plane | Tests cover crossing, outside-opening, approaching, and stationary cases. No claim of a previously reproduced tunneling incident. |
| Paying twice for one ring | Server collection set keyed by ring ID | The current collection branch checks the set before awarding. Client sound deduplication is a separate concern. |
| Banking a run twice | Remove the session before banking its gold | Earlier session checks rejected repeated-reset payouts; no production exploitation is claimed. |
| Unlimited boost or stale thrust | Server-owned fuel budget and stale-input timeout | Assertions cover depletion, maximum speed, release, and timestep comparisons; earlier live checks exercised fuel exhaustion. |
| Client-forged state or purchases | Validate inputs and calculate simulation, prices, and rewards on the server | Invalid upgrade and balance cases are tested. This is not a security audit or proof of complete exploit resistance. |
| Collected rings becoming visible after streaming | Keep collected IDs separately from instances and hide returning parts | The client contains the handler. A full unload/reload regression for the final revision remains to be run. |
| Rebuilding expensive terrain unnecessarily | Revision attribute guard and deterministic source generation | The latest build completed; repeat builds skip terrain for the same revision. Geometry changes require a new revision or deliberate invalidation. |

## Open limitations and proposed next steps

These are interview discussion points, not completed fixes.

| Limitation | Why it matters | Proposed work and validation |
| --- | --- | --- |
| Terrain collision sweeps only the plane center | A wing may clip scenery even if the center path is clear | Evaluate a swept volume or multiple offset sweeps; test narrow passages, grazing contact, and high-speed motion. The ring margin alone does not solve terrain collision. |
| No client prediction and reconciliation | Server updates plus interpolation may feel delayed on high latency | Measure latency first; prototype local prediction with reconciliation and test packet delay/loss. |
| Device performance is unmeasured | About 18,700 world descendants can affect memory and rendering | Profile on target phones and desktop, record frame time and memory, then optimize measured bottlenecks. |
| Summit reachability is not fully playtested | Clear geometry does not prove flight energy and thermals make a route practical | Fly from spawn to each summit using the base plane and record fuel, altitude, duration, and failures. |
| Published persistence is unverified end to end | Studio progress is session-only | Test save/rejoin, ownership conflicts, failures, and shutdown behavior in a controlled published environment. |
| Multiplayer and device input coverage is incomplete | Single-client desktop checks miss concurrency and input differences | Test simultaneous players, independent ring visibility, touch, controller, and disconnections. |
| Presentation tests are manual | Folder renames could break feedback again | Automate scene-contract checks and pickup/sound/reset/streaming tests in a controlled Studio harness. |
| Procedural terrain is a height field | It cannot represent arbitrary overhangs directly | Keep carved passages separate; evaluate meshes for art that needs overhangs. |
| Hidden animal rules sample one launch viewpoint | Visibility can differ elsewhere on the plateau | Inspect a grid of launch camera positions and adjust the intended concealment rules. |

## Three interview stories to rehearse

### Debugging a silent integration failure

“A pickup reached the client, but a scene lookup still used the old folder name. A nil guard prevented a crash and also hid the failure. Following the event into the scene graph identified the stale name. A controlled runtime check then verified that all 48 ring pieces disappeared and only one chime played, including when the event was repeated.”

Be ready to answer: Why can defensive nil checks hide a broken contract? Why test reward authority and client presentation separately? How would you automate this regression?

### Making procedural placement satisfy gameplay constraints

“Moving wildlife behind mountains exposed a generator failure: the available coastline did not provide enough valid flat ground. The generator rejected candidates for good reasons. The solution expanded the lowlands and sampling domain while preserving clearance and spacing rules. A fixed seed made the layout reproducible, and assertions checked the final count and placement.”

Be ready to answer: What is rejection sampling? Why cap attempts? How would rejection counters help? What happens if generation cannot satisfy the constraints?

### Balancing distant visibility and visual quality

“The distant mountains needed to remain visible to invite exploration. An early coarse representation produced floating triangles. Restricting it to mountain silhouettes, reducing tile size, lowering its surfaces, and fading it near the camera improved the visual result. Device profiling is still needed before claiming a performance win.”

Be ready to answer: What tradeoff does a simpler distant representation make? Why should it not collide? How would you measure memory and frame-time impact?

## Updating this log

For the next issue, record:

- **ID and status**
- **Expected and actual behavior**
- **Reproduction steps and environment**
- **Observed evidence**
- **Confirmed cause or explicitly labeled hypothesis**
- **Fix and affected source**
- **Verification performed and result**
- **Remaining limitation and regression follow-up**

Preserve failed experiments when they explain the investigation. Record measurements only when they were actually captured. Distinguish a user-requested design change from a defect, and a proposed fix from an implemented one.

