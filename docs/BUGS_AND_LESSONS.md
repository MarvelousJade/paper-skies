# Paper Skies bugs and engineering lessons

This log explains the bugs, design hurdles, and testing problems documented during development of Paper Skies. Each entry records what happened, why, what changed, and what evidence supports the result. It is intended for interview preparation and future debugging.

Initial log prepared on October 4, 2026 for the mountain/discovery checkpoint; later findings are appended below. Baseline: `d3fe27b`. Last committed exploration snapshot: `5fd61e2`. Those changes were later committed as 3cf87cc; the radial-world and hangar follow-up remains uncommitted. Intermediate experiments were not individually committed, so some observations are recorded from the development session rather than recoverable as separate Git revisions.

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

**Fix:** Restrict proxies to mountain areas above elevation 170; reduce tile size from 512 to 256 studs; lower proxy vertices using nearby height samples and a 28-stud offset. The first revision hid them in Edit mode. In Play, fade nearby proxies out between approximately 1,100 and 1,650 studs from the camera. They do not collide with the plane.

**Verification:** Later Edit captures no longer showed the original triangle artifacts. A Play capture showed distant mountain silhouettes from the launch area.

**Limit:** The sampling is an approximation, not a mathematical guarantee that every proxy lies below every point of detailed terrain. No full device or camera sweep has been completed.

**Interview explanation:** “A cheap distant representation improved visibility but introduced its own artifacts. Narrowing it to important landmarks, using smaller tiles, and fading it near the camera improved the result without keeping every tree loaded.”

**Code:** [DistantLandscape builder](../tools/BuildExplorationWorld.luau), [client fade loop](../src/client/FlightClient.client.luau).

**Follow-up:** Profile frame time and memory, inspect transitions from multiple directions, and check lower-memory devices before claiming a performance improvement.

## Design and gameplay hurdles

### D01 Mountains and grass did not match the intended world

**Symptom:** Feedback described rounded or overly smooth mountains, excessive grass detail, and a launch mountain that looked like a ball.

**Reason:** Earlier generic shapes and relief did not distinguish meadow surfaces, dramatic mountain silhouettes, and a playable flat launch area.

**Change:** Separate broad low-frequency meadow relief from ridge, massif, table, spire, and broken mountain profiles. Use gullies and surface variation on the mountains. Create a broad flat launch plateau with angular shoulders. Attempt to disable decorative grass blades while retaining grassy coverage; the failed property write was later found and corrected in B04. Add trees only where elevation, material, and slope allow them.

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

**Evidence:** The mountain checkpoint build completed 1,840 terrain tiles; the radial revision uses 1,720. Expanded coastlines and rear meadows were visually inspected.

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



## October 4 radial world and plane hangar follow up

The mountain/discovery checkpoint was committed as `3cf87cc` at the user's request. The subsequent radial world and five-plane hangar changes remain uncommitted. Current checks passed: 59 flight/economy/profile/model assertions and 444 geometry/layout assertions.

### B04 Grass decoration was still enabled

**Observed:** Dense grass blades remained visible despite the earlier documentation saying they were disabled.

**Cause:** The builder wrapped `terrain.Decoration=false` in a pcall and ignored failure. A direct check failed in this scripting context. Roblox documents Decoration as non-scriptable, so the earlier claim of successful disabling was incorrect.

**Fix:** Generate meadows using LeafyGrass and convert the current authored grass surface to that material. Remove the silent property-write attempt.

**Evidence:** The later Play screenshot showed the broad meadow surface without the tall blades. See [Roblox terrain documentation](https://create.roblox.com/docs/reference/engine/classes/Terrain).

**Lesson:** A protected call prevents a crash; its success result still needs checking before claiming the action worked.

### B05 A rear throw hit the instruction board

**Observed:** The eight-direction launch check failed at yaw 180 degrees. A diagnostic raycast identified `LaunchCliff.Instructions` at approximately (-548.6, 379.0, 637.5), on simulation tick 41.

**Cause:** The old deck layout assumed forward launches. Opening all directions exposed an obstacle behind the player.

**Fix:** Lower the instruction board from center height 374 to 363, below the tested rear trajectory. Use a slightly upward default launch pitch to clear the centered plateau.

**Evidence:** All eight default throw paths passed after the change. This tests the sampled center path, not every possible pitch or full-wing collision.

**Lesson:** Expanding a control range creates new geometry and UX test cases.

### B06 A material conversion failed before reporting progress

**Observed:** An asynchronous meadow conversion remained at its initial progress label.

**Cause identified in the script:** `Landscape.height` returns height plus two booleans. Passing it as the final argument in `math.max(high, Landscape.height(...))` expands all return values, introducing booleans into a numeric operation.

**Fix:** Parenthesize the function call to keep only its first result: `math.max(high, (Landscape.height(...)))`. Run the conversion with an awaited result.

**Evidence:** The corrected conversion completed 440 bounded horizontal regions and reported Complete. The exact first asynchronous exception was not preserved across the subsequent Play transition.

**Lesson:** Lua multiple-return behavior matters at argument boundaries; background work also needs explicit completion and error reporting.

### B07 Collected summit halos needed their own cleanup

**Observed:** The first summit feedback check found the halo still enabled after an injected collection event.

**Cause and scope:** The original event handler hid BaseParts but did not explicitly disable BillboardGui descendants. A periodic updater was expected to handle the halo; why that first observation still saw it enabled was not isolated.

**Fix:** Disable BillboardGui descendants synchronously in the collection handler and handle returning billboard instances in the streaming callback. Keep the periodic distance/collection visibility update.

**Evidence:** A fresh session received one summit event, hid 49 parts including the anchor, and reported the halo disabled. This is a presentation check; it does not prove physical flight collection in the same scenario.

### B08 Far rear mountains are missing in the Play preview

**Status: Open.**

**Observed:** Summit halos were visible against the sky while the associated rear terrain and coarse proxy scenery were absent in repeated Play screenshots. Edit screenshots from the same area show the mountains correctly.

**Evidence:** Server terrain raycasts find the rear spire. A temporary extra replication focus made the same terrain queryable on the client, but did not resolve its appearance in the captured view. Proxy parts were present with zero effective transparency in inspections.

**Attempts:** Tested opaque proxy surfaces with local fading, thicker proxy faces, additional streaming requests/foci, reduced atmospheric density, and a temporary scaled backdrop. These did not establish a reliable rendering fix. A temporary distant red diagnostic part also failed to appear in the captured view. All temporary diagnostics and foci were discarded on leaving Play.

**Uncertainty:** The checks have not isolated whether the cause is render distance/quality, preview behavior, or another client rendering issue. Do not call this a confirmed Roblox engine defect.

**Tool limitation:** Changing SavedQualityLevel through the scripting tool lacked the required RobloxScript capability; sending Escape through virtual input was rejected as a CoreGUI action. No graphics-preference change was confirmed.

**Next work:** Compare a normal interactive Studio session and a controlled published client across graphics levels, inspect actual camera/render behavior, and only then choose a rendering or world-distance adjustment. The feature's distant halos work, but complete distant-terrain visibility remains unverified.

### D08 Plane progression changed from numerical upgrades to aircraft types

The user clarified that better performance should come from buying visibly different paper planes. The hangar now provides Paper Dart, Lockwing, Delta, Sailwing, and Kestrel, using online reference images recorded in [Plane references](PLANE_REFERENCES.md).

Purchases, ownership, equipment, flight attributes, and models are driven by the same aircraft ID. The server rejects changes during flight. Profile normalization preserves valid owned types, rejects unknown IDs, and retains legacy gold and numerical bonuses.

Live QA used a temporary 5000-gold starting profile. Buying Delta left 4450; selecting it again did not charge; held and launched models matched. A mid-flight change was rejected, and Kestrel was purchased after landing. The temporary starting balance was removed and normal starter gold was verified as zero.

### D09 Updraft strength and exploration layout were retuned together

The previous 52-stud/second mountain updraft was too strong in user feedback. Raw mountain lift is now 18; the starter's efficiency limits it to 12.6 before radial/altitude falloff. Air response comes from the equipped aircraft, with ceilings from 650 to 2250 and a 220-stud fade band.

Seven mountains and surrounding land lobes now occupy bearings around the start. Tests require mountains on all sides and no gap above 75 degrees. More advanced aircraft improve access to high air without imposing an invisible flight ceiling. Full summit-route reachability remains a playtest task.

### T05 A runtime price patch was not a reliable test fixture

A tool-side mutation of the required configuration table did not cause the running server to sell Delta at the temporary price. The purchase assertion failed, and the following model assertion therefore still observed the starter. The experiment did not establish that the production purchase handler was broken.

The successful replacement fixture changed the starting balance in the temporary Studio test source before entering a fresh Play session. This exercised the actual server purchase path at the real price. Normal source was restored afterward. Treat tool execution context and module state as part of the test environment.

### T06 Authoring tool errors did not mutate the project

A JavaScript orchestration attempt used an unavailable `structuredClone` helper and was corrected to a JSON round trip for serializable source strings. A malformed quoted tool call also failed before execution and was corrected. These were authoring errors, not gameplay bugs. They are recorded for completeness; the gameplay and integration cases are stronger interview examples.


## October 4 stamina, flight envelope, and camera follow up

The preceding radial-world and hangar build was committed first as `b4a7299`, as requested. The changes below remain uncommitted for user playtesting. Automated validation passed 82 flight/economy/camera assertions and 444 world assertions, including all eight launch directions.

### D10 Boost now recovers as stamina

**Requirement:** Make boost recoverable while retaining meaningful plane progression.

**Implementation:** The server owns a 4.5-second capacity. Release boost and fly at 5 degrees upward or lower, at least 76 SPS, without a stall. After 0.85 seconds in that state, recharge begins at the equipped plane's rate. Dart refills from empty in 8.35 seconds including the delay; Kestrel takes about 6.14. Climbing, stalling, or holding boost resets the delay. Holding an empty bar cannot create repeated tiny boosts.

**Engineering detail:** Recharge integrates only the part of a simulation step beyond the delay boundary. This prevents a whole extra frame of recharge at lower update rates. Fuel is clamped to capacity and carried only in the server flight state; the client receives presentation telemetry.

**Evidence:** Tests cover delay, refill rate, capacity, a second boost after recovery, empty held input, climbing/stall exclusion, and 30/120 Hz agreement. Live telemetry showed recovery from 3.17 to 3.43 seconds during a suitable glide, with the HUD reporting RECHARGING; later telemetry reached full capacity.

**Interview point:** Explain why the client sends intent rather than its stamina balance, and how a delay boundary can introduce frame-rate dependence.

### D11 Aircraft have soft climb, altitude, and range differences

**Requirement:** Weak paper planes should shed speed quickly on upward turns and drop their noses sooner. Better models should travel and climb farther.

**Implementation:** Each type has a climb comfort angle and a quadratic additional drag cost above it. Pulling upward raises the speed required to avoid a stall. Beyond the aircraft's nominal air ceiling, added drag and sink increase progressively. Range emerges from the existing type-specific drag/sink and energy management; there is no per-type travel-distance kill switch. Global world bounds and run duration remain.

**Evidence:** From altitude 350 with a 10-degree initial pitch and a sustained 24-degree target, Dart first stalled at 3.18 seconds and had dropped its nose during the four-second test. Kestrel had not stalled at four seconds and retained about 131 SPS. The starter ended at about 78 SPS after its partial recovery. A separate test verifies momentum can still carry a plane above its nominal ceiling. Comparative unobstructed glides verify Kestrel travels over 20% farther than Dart.

**Test design:** Ordinary glide fixtures now start at altitude 400, inside the starter envelope, instead of 800. A separate fixture explicitly tests the new above-ceiling penalties. This keeps ordinary glide behavior and altitude penalties independently testable.

**Limit:** These are tuned game mechanics, not a full aerodynamic solver. Full summit-route reachability, player feel, and economy progression still need playtesting.

### D12 Camera zoom now follows throw and boost events

**Previous behavior:** FOV was assigned directly from speed every frame. Since speed stays high after boost release, that approach could not satisfy the requested return to normal framing.

**Change:** A small shared camera module produces a 1.4-second throw pulse plus an independent boost target, with exponential easing. Normal flight is 70-degree FOV at 29 studs; boost targets 84 degrees at 40 studs. The throw pulse adds up to 10 degrees and nine studs. Releasing local boost immediately targets normal framing, while smoothing avoids a snap. Every throw resets the pulse.

**Evidence:** Seven deterministic camera assertions cover throw pullback, return, active boost, eased release, eventual normal framing, 30/120 Hz agreement, and reset. Live keyboard-driven samples peaked at 79.45 degrees for throw and 83.99 for boost, then returned to 70 after release. The Studio console showed only normal startup messages during that check.

**Interview point:** Physical speed and perceived speed are separate concerns. Keeping camera state separate makes the effect testable without altering authoritative flight.

### T07 An oversized source read was truncated

A batched JSON read exceeded the command output limit, so parsing encountered the tool's truncation warning. No source write occurred. Reading individual files with bounded output and storing their content before generating edits resolved the authoring problem.

### T08 Live test setup must check the current flight mode

The first keyboard sequence assumed the player was Ready, but recorded telemetry showed an existing flight. F ended that run, and the second F entered aiming; no throw event was recorded. Inspecting the HUD state established that the player was aiming. A subsequent single throw produced the intended camera/boost measurements. This was a test setup error, not evidence that throwing failed.

One immediate post-Stop diagnostic also reported an invalid require argument. A follow-up inspection confirmed the modules existed; explicitly resolving the Flight ModuleScript in a subsequent call succeeded. The exact reason for that transient tool execution failure was not isolated.

All temporary telemetry recorders were discarded by stopping Play. The scene is left in Edit with the new production scripts installed. The separate distant-terrain rendering issue B08 remains open.


## October 4 larger rings and meadow encounters follow up

The stamina/flight/camera build was committed first as `644c261`, as requested. This world-layout revision remains uncommitted for playtesting.

### D13 Larger rewards and closer curved routes

The user requested rings about twice their previous size, more connected clusters, and more encounters before the mountains. Sky and summit ring diameter is now 24 studs (previously 12); foothill rings are 28 (previously 14). Sky routes increased from ten to eighteen, with seven or eight rings each. Center spacing is 23.98–24.12 studs instead of roughly 33–46. New route centers occupy intervening fields around the launch area while retaining the clear 1000-stud launch buffer and free choice of throwing direction.

There are now 164 rewards: 136 sky rings, four foothill rings, seventeen animal arches, and seven summit rings. A fox at approximately (-1200, 47.5, -450) and a deer at (-300, 50.7, -550) bring forward lowland wildlife to four. The original thirteen hidden encounters retain their positions. Flat-site and separation checks prevent placing the new animals on mountains or on top of existing encounters.

### D14 Animal rewards became sideways half-ring arches

The first draft raised torsos and widened legs to fit a complete doubled ring. The user clarified that only half the ring should appear beneath the animal, with the opening facing sideways. The final builder restores original animal anatomy and the 0.62 scale. It renders 24 arc segments across the upper half of a 24-stud circle, centered one stud above the animal's ground position. The crossing normal uses the animal's right vector so the path goes between its front and rear legs.

The collection plane and visible arch share the same center, normal, and radius. A representative crossing six studs above the ring center passes the existing server collection aperture with its 3.6-stud margin. The semicircle has no collision geometry in its opening.

**Clearance consideration:** Doubling rings affects more than appearance. Summit centers were raised seven studs to keep the larger lower rim above the rock. New tests sample visible ring rims as well as the flight centerline. Animal tests check side orientation, 24-segment semicircle construction, an actual-scene passage with plane offsets, and the swept collection predicate.

**Evidence:** 2773 geometry/layout assertions and all 82 flight/economy/camera assertions passed in Studio Edit. Close screenshots verified the sideways arch beneath the fox and the denser curved sky route. Geometry checks cover all seventeen animals and the default throws in eight directions. Full keyboard-flown collection of this new layout was not tested during this revision.

The rebuilt scene contains 23,570 descendants, including 109 trees above elevation 180. Increased route density adds renderable parts; device profiling remains pending. The separate distant-terrain Play rendering issue B08 remains open. No new confirmed gameplay defect was encountered during this layout revision.


### D15 Full sideways belly rings restored

The user replaced the half-ring requirement with a complete circle. All seventeen animal rewards now render all 48 segments at radius 12, preserving their sideways orientation. Centers are 18 studs above the sampled ground. Torso/head geometry is lifted 24 unscaled studs and front/rear feet are spaced farther apart; model scale remains 0.62. Collection centers and visible hoops use the same data.

**Visual issue found during revision:** With the first full-ring center at ground +14, the fox screenshot still hid part of the bottom rim even though raycast clearance checks passed. The exact render-surface discrepancy was not isolated. Raising centers another four studs, with corresponding torso clearance, produced a visibly complete circle in the repeated close-up. This shows why collision checks need a visual check too.

**Verification:** Updated full-circle rim, sideways passage, and reward-crossing checks passed: 2858 geometry/layout assertions. The close screenshot shows the entire fox ring. The rebuilt scene contains 23,978 descendants. Source and installer were updated; this follow-up remains uncommitted. This revision does not include a new live flown-collection test.


## October 4 reference-inspired gorilla and mammoth follow up

### D16 Distinct reference models replaced two duplicate encounters

The new screenshots were located in the old Documents project folder rather than the active G: repository. After inspecting all three, the icy animal was identified as the mammoth reference. Copies are retained under `references/`; see [Animal references](ANIMAL_REFERENCES.md).

The existing shared quadruped builder could not produce a recognizable gorilla or the mammoth's layered coat. A separate `ReferenceAnimals` module now generates broad beveled bodies, heavy limbs, original face details, and model-specific features. The world builder calls it for Gorilla and Mammoth, and the installer includes the module so the scene remains reproducible.

Slots 6 and 7 reuse validated hidden lowland positions. The final roster is seventeen animals across seven species, with the same thirteen-hidden/four-visible split. Full sideways rings remain aligned with the collection data.

### B09 Gorilla arm plates appeared detached

**Observed:** The first side-view screenshot showed three decorative plate rows floating in front of the upper arms.

**Cause:** The plates used a fixed front offset and row heights without following the bent forearm's position.

**Fix:** Position each plate along the elbow-to-wrist segment and rotate it to match the forearm slope. The corrected side screenshot shows the plates attached to the forearms.

**Verification:** Geometry/layout checks passed again after the correction (2858 assertions). Front/three-quarter and side screenshots verified both model silhouettes and visible full belly rings. Gorilla uses 264 anchored parts; Mammoth uses 838. Total world descendants: 24,419. Device performance and live flown collection for these models are pending.

**Interview lesson:** A model can pass collision tests and still have detached visual details. Side views reveal attachment problems that a front view can conceal.

A diagnostic was initially sent to the Edit datamodel while Studio was in Play; the tool rejected it without changing the scene. Work continued in Edit after stopping Play. The scene is left in Edit with the final models installed. This revision remains uncommitted.


## October 4 complete wildlife roster replacement

### D17 All old animal instances now use the supplied reference style

Three additional screenshots showed a bear, silver fox, turtle, raccoon, and a colorful square-headed cat-like creature. These supplied the shape and color references for five new builders, alongside the gorilla and mammoth already added. The project calls its original cat adaptation CandyCat.

The final roster has seventeen encounters: two bears, three silver foxes, two turtles, three raccoons, three candy cats, two gorillas, and two mammoths. The legacy generic quadruped builder was removed. A deterministic roster replaces model types after the existing location sampling, retaining the same positions and thirteen-hidden/four-visible split.

The complete sideways rings remain at the same positions. Existing tests verify their openings and approaches. Seventeen additional assertions ensure every encounter belongs to the new roster and actually has a reference-style model, preventing a missing or legacy model from silently passing empty-space collision checks.

**Evidence:** 2875 geometry/layout assertions passed. Close screenshots inspected the new bear, turtle, silver fox, raccoon, and candy cat. The current world contains 22,152 descendants, down from 24,419 before the full replacement. Built-in stud surfaces avoid separate geometry for every small stud. Full device profiling and live flown collection remain pending.

### B10 Silver fox eyes floated, then became hidden during refinement

**Observed:** The first close view showed the fox's eyes offset from its tapering head. An initial adjustment moved them into the head and they disappeared in the next view.

**Cause:** A fixed front-facing eye plane did not follow the fox head's changing cross-section.

**Fix:** Add a forward face panel that intersects the head and place the eyes directly on its outer surface. The final close screenshot shows both eyes attached and visible.

**Lesson:** Geometry edits should be checked from the intended viewing angles. Moving a detail closer without checking the surface can exchange a floating-detail bug for an occlusion bug.

The raccoon's initially tall stepped ears were also shortened as an art refinement, to distinguish its silhouette from the fox. This was a design adjustment rather than a collision defect. All changes remain uncommitted for user review.


## October 4 pickup audio and original background loop

### B11 Rapid pickups produced a warbling multi-chime sound

**Observed:** The user described ring pickup feedback as “blblbl” and requested a simple coin click.

**Cause:** The source asset itself was a multi-chime sound. Four pooled Sound instances allowed adjacent rings to overlap, and the ring ID changed PlaybackSpeed, introducing several simultaneous pitches. The original mute toggle also prevented only new chimes; an already playing tail could continue.

**Fix:** Replace the source with UI Tick (OrcaCreations, asset 99102731755541), use one fixed-pitch Sound, and fade/stop its tail after 140 ms. Rapid pickups restart that voice. Preserve the duplicate-ID guard. Sound OFF stops active click feedback immediately and mutes wind and configured music.

**Verification:** In a fresh Studio Play session, the source loaded (0.340 seconds), one ring voice existed at pitch 1, duplicate feedback produced one start, a rapid pair produced two starts without extra voices, and the tail stopped. Clicking the actual Sound button suppressed the next pickup, muted wind, and restored playback when toggled ON. Tests injected synthetic feedback without changing the server wallet. Subjective listening approval and published asset permissions remain pending.

**Interview lesson:** A valid reward event can still have poor feedback. Consider sample length, voice overlap, and pitch variation together, and verify mute behavior for sounds already playing.

### D18 Original chill electronic music with an explicit upload boundary

`tools/GenerateChillMusic.py` composes and synthesizes a sample-free 100 BPM, 76.8-second loop, exported to `assets/audio/PaperSkies.wav`. Numerical checks found no clipping and no PCM discontinuity at the loop boundary. The client supports quiet looped music and the existing Sound toggle, while an empty music ID safely disables the track until upload.

Roblox requires an uploaded audio asset and appropriate experience permissions. The connected tools cannot upload audio; the WAV and integration are ready, but original music is not yet playing inside Roblox. See [audio setup and verification](AUDIO.md). Listening review and a full loop of the Roblox-encoded asset remain pending. This change is uncommitted.


### D19 Uploaded PaperSkies track enabled and checked in Studio

The user uploaded PaperSkies as asset `126932983544303`. Inventory lookup found the matching title under the user account, and preloading returned Success with duration 76.8 seconds, matching the local export. The repository Config and Studio Config now use that ID; the generated installer was refreshed.

A fresh Play session started the track automatically at volume 0.16 with looping enabled. Seeking to half a second before the end triggered one DidLoop event and continued playback from the beginning. Clicking Sound OFF muted music while time continued advancing, and Sound ON restored the volume without restarting the song. This supersedes D18's upload blocker. A full listening pass and published-client permission check are still pending. The track is left playing in Studio; changes remain uncommitted.


### D20 Longer connected ring trails and a quieter introductory field

After checkpoint `04acf33`, the user clarified that music should begin on entering the game and that “rain” meant the existing collectible rings. Entry music was already implemented and remains unchanged; it is not gated by the green Launch button.

The sky layout now has twenty-four curved trails of ten rings each (240 sky rings, up from 136). Eighteen existing trails were lengthened and six outer routes added. Rings retain a 24-stud diameter, approximately 24-stud spacing, mixed neon colors, and optional collection in either direction. The minimum 1000-stud launch exclusion remains intact.

The two additional meadow encounters were removed, leaving a bear and turtle in the introductory field and thirteen animals at their existing hidden locations. All seven species remain represented. Complete sideways belly rings are retained for the fifteen animals. Total rewards: 266.

The scenery rebuild reused existing terrain and regenerated trees against the new ring corridors. All 4481 geometry/layout assertions passed, including opening/rim clearance, plane-width belly approaches, ten-ring minimum trail length, and exactly two visible field encounters. Close screenshots show the longer curved chain and the open-field bear/turtle placement. The scene contains 26,936 descendants. This is a design iteration, not a newly discovered defect; device performance and full keyboard-flown collection of every route remain unverified. Changes remain uncommitted.


## October 5 distance-gold balance

### D21 Passive flight income made progression too generous

**Observed:** The user reported that flying around earned too much gold and requested a checkpoint before changing it. The current layout was committed as `a0285a5` first.

**Cause:** Passive income awarded one gold per 40 studs, so ordinary 150–165 SPS gliding generated roughly 225–248 gold per minute without collecting rings. The same hardcoded formula appeared separately in telemetry and final banking, increasing the chance that a future balance edit could change only one path.

**Change:** Set `Config.DistanceGoldStuds` to 200, reducing distance-income rate by 80%. At 1000 studs, passive earnings fall from 25 to 5 gold. `Economy.flightReward` now supplies both live telemetry and final payout. Ring values, aircraft prices, and existing saved balances are unchanged; deliberate exploration stays rewarding.

**Verification:** All 87 flight/economy/camera assertions passed, including zero distance, the 200-stud boundary, integer rounding, and preservation of collected ring gold. A fresh Studio run traveled 495.84 studs without rings: the HUD displayed 2 gold, Ended awarded 2, and the wallet increased by 2. Another reset did not pay again. The old formula would have awarded 12 for that distance. The live check used normal launch/reset requests and Studio-only progress; no persistent balances were edited. `git diff --check` passed.

**Interview lesson:** Balance passive income against traversal speed and upgrade prices. Keep display and settlement on one server-owned reward rule, and verify both the visible reward and actual wallet change. This is a tuning correction; long-session progression still needs player feedback. The balance adjustment remains uncommitted for testing.


## October 5 consistent aim arc and thicker neon rings

### D22 Keep aiming curvature stable while improving visual weight

**Request:** Commit first, make the aiming line consistently curved, rounder and thicker, and make sky rings look more like neon tubing. The distance-gold change was committed as `a414140` before this work.

**Cause of the old changing curve:** The preview ran the flight simulation for 144 steps at 30 Hz. Its sampled path responded to aircraft stats, aim pitch, and rising air. Twenty-four narrow one-segment Beams connected those samples. That behavior made sense as a prediction, but conflicted with the requested stable visual guide.

**Change:** Use one fixed cubic curve with 64 rendered segments, a 0.9-stud core (previously 0.3), a soft outer glow, and rounded endpoints. Two attachments and two beams replace the sampled chain. Only the curve’s rigid frame follows the held plane and aim; its control points never change with aircraft stats or thermals. This is deliberately a direction guide rather than an exact prediction. Flight physics itself is unchanged. Handle orientation follows the [Roblox Beam API](https://create.roblox.com/docs/reference/engine/classes/Beam).

Rings retain their locations, colors, 48 segments, and collection radii. The visual segments are now overlapping round cylinders with 0.65-stud diameter instead of 0.28-stud square bars. They remain non-colliding and non-queryable. Studio geometry was updated in place to avoid another terrain/scenery backup; the world builder and generated installer reproduce the same tubing.

**Verification:** All 4481 world geometry/layout checks passed after expanding the rim-clearance sample to account for the wider tubing. Screenshots checked a ten-ring chain and the aiming preview in Play. The live preview contains six descendants, has the expected endpoint and tangents, and uses the configured width. A temporary clone retained identical local control points across twelve pitch/yaw orientations and was then destroyed. Launching removed the curve and held-plane preview correctly. Automated mouse movement did not produce a locked-cursor delta during the tooling check, so hands-on mouse feel remains for user review; the unchanged input path still supplies the aim frame.

**Interview lesson:** Decide whether a visual is a physical prediction or an aiming cue, then keep its behavior consistent with that purpose. Share ring dimensions between rendering and clearance checks when thickening geometry. The new visual changes remain uncommitted.


## October 5 arcade pickup chime and high-sky routes

### D23 Bright ring feedback and elevated exploration trails

The user requested pickup feedback closer to the Sonic ring sound and connected rings higher in the sky. The selected free Creator Store asset is SONIC RING SFX by PastaReaperYT (`111940732857414`), successfully loaded in Studio at 0.952 seconds. The single-voice player now allows 450 ms with a 60 ms fade, at volume 0.35 and fixed pitch. This replaces the earlier UI Tick; duplicate suppression and immediate mute remain in place.

Seven additional ten-ring curves follow the near-side updraft regions of the seven mountains. Their measured elevations range from 475.11 to 1372.99 studs. The existing twenty-four trails remain, for 310 sky rings and 336 total rewards. The high trails are intended to give stronger planes more exploration choices; aircraft ceilings, lift strength, reward values, and the reduced distance-income rate are unchanged.

Only ring models were rebuilt in Studio, using the ring section of the saved world builder. Terrain, trees, animals, and the thick round tubing remain intact. All 5766 geometry/layout assertions passed, including terrain/opening/rim clearance, exactly ten pickups per trail, seven elevated trails, and the existing wildlife placement rules. An elevated camera view checked the mountain-side ring chain. Flying every high trail end to end and subjective sound review remain pending.

### B12 Trail-count regression check lagged behind the authored layout

While updating the high-sky tests, inspection found that an older assertion still accepted eighteen trails even though the preceding map already contained twenty-four. An earlier text replacement had not matched that specific assertion. The layout itself had the correct count, but the check could miss a later regression. The test now requires thirty-one trails, checks ten rings in each, and separately verifies seventy high rings across seven groups. Lesson: inspect edited assertions rather than assuming a text replacement succeeded. All current assertions pass. This task remains uncommitted.


Current chime Play check: asset loaded at 0.952 seconds; one pickup plus its duplicate and two rapid unique pickups produced exactly three sound starts. The tail stopped, Sound OFF suppressed the next pickup, and the toggle was restored to ON. These synthetic feedback IDs did not award server gold. The fresh client also loaded all seventy high-sky rings and 336 total rewards. Subjective listening approval and published audio permissions remain pending.


## October 5 softer pickups and rounded animal limbs

### D24 Reduce harsh pickup feedback and round the legs

The pickup keeps the selected ring sample and its 450 ms envelope, but volume drops from 0.35 to 0.20. A local EqualizerSoundEffect on RingPickupChime attenuates highs by 8 dB and mids by 2 dB. Only pickup feedback is filtered; the wind and background music retain their own mix. This is subjective sound tuning and remains open to listening feedback.

The shared four-leg builder now uses smooth vertical cylinders and rounded paws for bear, silver fox, raccoon, turtle, and candy cat. Mammoth legs/cuffs and gorilla thighs/shins use the same cylinder approach. Gorilla arms, shoulder/elbow joints, hands, and forearm cuffs were also rounded. The original model scale, positions, colors, layered bodies, and complete belly rings are retained. Only animals were rebuilt in Studio.

### B13 Flattened Ball parts made paws and hands look undersized

**Observed:** The first rounded-leg screenshots showed the bear's feet nearly hidden by its legs and the gorilla's hands as small balls disconnected from the intended forearm silhouette.

**Cause:** A simple Ball Part did not visually fill the intended flattened three-axis paw/hand dimensions, even though the reported Size retained them. Checking Size alone did not catch the visual mismatch.

**Fix:** Use a built-in sphere SpecialMesh on a Part with the authored size for paws, hands, toes, and joints. This preserves the flattened ellipsoid proportions and original collision bounds. Keep cylinders for the long leg/arm sections. Curved arm cuffs replace the old flat plates so their edges do not float away from the rounded forearm.

**Evidence:** Corrected bear and gorilla screenshots show attached rounded feet/hands. All 5766 geometry/layout checks passed after the fix, including every belly corridor. A separate model audit found exactly sixty cylindrical leg sections across fifteen animals and no legacy BlockLeg or SteppedFoot parts. Each gorilla adds two elbow parts (266 parts total); the complete scene has 30,494 descendants, including the small built-in sphere meshes. Full device profiling and hands-on flight through every encounter remain pending.

**Interview lesson:** Reported geometry dimensions and visible shape can differ. Review the rendered silhouette as well as collision clearance, especially when changing primitive types. These changes remain uncommitted.

The final Play audio check verified volume 0.20 and enabled EQ (-8 dB high / -2 dB mid). Three unique synthetic pickup notifications produced three starts, a duplicate was suppressed, and the tail stopped. Wind/music were not filtered; music continued playing. The test listener was removed and no server gold was awarded.


## October 5 rear-field turtle placement

### D25 Split the introductory animals around the starting point

The softer sound and rounded limbs were committed first as `ba1ca74`, as requested. The bear stays in front of launch. Turtle2 moved from approximately (-471.8, 50.8, -1055.7) to (-550, 56.5, 1850), around 1316 horizontal studs behind the starting point in the +Z direction. Its heading is zero so it faces the starting area, and belly ring 316 moved and rotated with it.

The relocation happens after seeded placement so it does not alter the random sequence or move any other animal. A direct before/after comparison verified that the other fourteen animals retained both position and heading. The rear site is flat, off the mountains, and about 186 studs from the nearest existing tree. The animal was rebuilt to resample foot heights; the existing ring model was moved to match the new authoritative collection data.

All 5770 geometry/layout assertions passed, including exactly one forward and one rear field encounter, the turtle's footprint, complete belly-ring opening, and sideways flight clearance. The moved ring's rendered center agrees with the collection position within 0.001 stud. A side screenshot confirms the visible complete ring beneath the turtle. This is a layout refinement; no new defect was encountered. The move remains uncommitted for user testing.

## October 5 calm exploration pickup

### D26 Replace the arcade sample rather than only turning it down

The user found the Sonic-style sound unsuitable for the relaxed scenery and music even after attenuation. Replace it with free Creator Store coin_pickup_1 by thienbao2109 (4612374807). Set maximum volume to 0.14, fixed playback speed to 0.92, high EQ to -12 dB, and mid EQ to -2 dB. A 25 ms attack softens the initial transient, and a 180 ms release avoids an abrupt cutoff within the 500 ms playback window. Keep one voice, duplicate suppression, and the shared Sound toggle. Paper Skies retains its existing mix.

Fresh Studio Play verification: the replacement source loaded at 0.702 seconds with playback speed 0.92 and pickup-only EQ at -12 dB high / -2 dB mid. Three unique synthetic pickup notifications plus a duplicate produced exactly three starts on one Sound instance; peak volume was 0.14 and playback stopped after the envelope. Sound OFF suppressed the next pickup and muted music; Sound ON restored the continuing music. Temporary listeners were disconnected. Synthetic IDs awarded no server gold. Subjective listening approval, actual flown collection, and published audio permissions remain manual checks.

**Interview lesson:** Technical playback correctness does not establish a suitable sound style. Treat listening feedback as an art-direction iteration, select a different source when attenuation alone is insufficient, and preserve duplicate and mute behavior while tuning. This is a design refinement, not a newly discovered software defect. The coin replacement and rear-field turtle move remain uncommitted for user testing.

## October 5 boost-camera comfort tuning

### D27 Halve the Space boost camera motion

Committed the rear-field turtle and calm pickup as `5363eca` before this change. The user found the boost camera movement excessive. Halved its extra FOV from 14 to 7 degrees and extra follow distance from 11 to 5.5 studs. Normal flight remains 70 degrees / 29 studs, and the original throw pulse and easing rate are retained. Coin volume increases slightly from 0.14 to 0.18 with the same source, EQ, and envelope.

Validation: all 87 flight, pickup, upgrade, and camera assertions passed. The fresh client module settled at 77 degrees / 34.5 studs during a simulated two-second boost and returned to 70 degrees / 29 studs on release. This checks the live-loaded module, not a full keyboard-flown camera recording. A cosmetic pickup reached volume 0.18, then stopped; music continued and no server gold was awarded. Listening and hands-on camera comfort remain for user testing. Changes remain uncommitted.

Tooling hurdle: Edit execution was rejected when Studio had returned to Play after a stop request. Checking the actual mode and stopping again allowed installation. During the next startup, the client bridge was temporarily unreachable, so a dependent smoke read had no listener state. After startup completed, the listener was installed and the check repeated with a new synthetic ID, then disconnected. No game-code fix was needed; wait for the target datamodel to be ready and establish test setup successfully before relying on it.

## October 5 lower wildlife and slower exploration

### D28 Fit ground arches to natural animal proportions

Committed the camera/audio checkpoint first as `dd549a9`. Lowered bears, foxes, raccoons, turtles, and candy cats: eleven animals across five species. Authored vertical offsets are respectively 22, 23, 28, 36, and 26 units before the existing 0.62 scale. Moving the torso/face geometry intact preserves their shapes; compensating the sampled foot heights keeps paws planted while shortening the rounded legs. Gorillas and mammoths retain their larger stance.

The eleven lowered encounters use 36-stud circular rings centered 0 to 7 studs below the sampled ground. Only half or less of the circle is exposed. Their sideways collection planes and reward values stay intact; explicit above-ground passage points guide clearance and crossing checks. The logical circle still crosses terrain below ground intentionally. No terrain was removed to create these arches.

Validation: 5847 geometry/layout assertions passed, including all animal flight passages, exposed rim clearance, no rim/animal collisions, shorter limb dimensions, reward crossing through exposed arcs, and all eight default launch directions. Bear and turtle side screenshots were inspected. Rebuilt only the eleven changed animals and rings; the rest of the scene remains in place. Full flown collection and device performance remain manual checks.

### D29 Trial a 100 SPS starter

The user chose 100 after considering 50–80. Starter launch speed drops from 165 to 100. Drag is also retuned so a hands-off trim glide stays near 100 instead of accelerating back toward the old cruising speed. Other tier launches are 107, 115, 123, and 133, preserving the existing speed increments and advantages in drag, sink, handling, and climb comfort. Dives and boost can still reach higher speeds; the cap remains 250. HUD defaults now use the shared starter configuration rather than a hardcoded 165.

The slower starting energy caused two older climb-test assumptions to fail: the starter had already stalled by the two-second final sample, and the advanced plane could also stall within a four-second steep climb. Tests now check peak initial altitude, compare first-stall timing, and require greater climb height for the advanced plane, rather than assuming neither has entered recovery at an arbitrary endpoint. The boost-cap check allows the full fuel window from the lower initial speed. All 87 flight, pickup, upgrade, and camera assertions pass. These changes are tuning iterations, not hidden physics fixes; sustained climb intentionally spends energy. User assessment of pace and lower flight gates remains pending. This revision remains uncommitted.

## October 5 special summit rewards

### D30 Make mountain-tip discoveries visually distinct

Committed the slower flight and lower wildlife first as `d875275`. The seven summit rings now use pale gold cores, a wider translucent gold glow, a warm local PointLight, eight sparse rim emitters per ring, and a 38-pixel three-layer distant halo. These are non-colliding effects; the opening, location, and pickup radius stay intact. The user settled on the existing 60-gold reward after reviewing the tier ordering: ordinary sky 10, foothill 25, belly 35, summit 60.

Adding lights and particles required extending collection cleanup. Hiding a Part alone does not disable its light or emitter. The client tracks effect-enabled states, clears existing particles on collection, and restores effects when the run resets. Newly streamed nested effects find their owning ring through ancestors so they cannot reappear after that ring was collected. This prevents a foreseeable leftover-glow defect rather than documenting a defect observed by the user.

Verification: 6204 geometry/layout assertions passed for the special effects, and a close summit screenshot was inspected. A fresh Play synthetic summit notification plus duplicate hid 97 parts and disabled ten effects, with one pickup sound. A late-added nested light was also suppressed. Reset restored the nine light/emitter effects and visible parts; music continued. No server gold was awarded by these cosmetic notifications. The server collection code uses the shared ring value and its once-per-run guard. Full flown summit collection, visual preference, and device performance remain manual checks. This revision remains uncommitted.

## October 5 coordinated low-poly scenery

### D31 Bright trees, blossom groves, and sparse meadow accents

Committed the summit glow first as `b927ae3`. The three supplied images guide shape and color rather than exact asset replication; retained copies are references/Scenery_BrightTrees.png, Scenery_BlossomShape.png, and Scenery_StonesAndMeadow.png. All new geometry is procedural and original in Scenery.luau: faceted green broadleaf crowns, pale birches, layered teal pines, pink/coral blossom canopies, brighter palms, irregular cool-gray stones, simple cream/lavender flowers, and small grass tufts. No individual leaf meshes or dense grass carpet were added.

The original tree placement sampler and random height consumption are preserved. Final roster: 452 trees (120 broadleaf, 30 birch, 211 pine, 78 blossom, 13 palms). Forty-two selected grove sites receive a small non-colliding flower/grass patch and nearby stone. Accent sites reject water, steep or rocky ground, launch space, animal approaches, and ring flight corridors. Only Woodlands and MeadowAccents were rebuilt; terrain and gameplay landmarks remain in place.

Geometry/layout validation passed 8707 assertions, covering existing ring and animal approaches, eight launch directions, sparse accent counts, primitive budgets, non-colliding small plants, and actual flower grounding. Close screenshots checked green crowns, blossom silhouettes, stones, flowers, and grass. Current world descendants: 64,216; maximum tree primitives: 124. The richer crowns increase instance count from the preceding 30,970-descendant world. Atomic tree/patch models keep streaming units bounded, but device performance has not been benchmarked; this count is not proof of a frame-rate target. The revision remains uncommitted for user review.

### B14 Small flowers were buried beneath voxel terrain

**Observed:** The first close meadow screenshot showed the rock, but most flowers and grass were missing. Raycasts showed flower centers around 1.55 studs below the actual terrain surface.

**Cause:** Placement used Landscape.height, the analytical field that authored the terrain. Roblox's voxel surface interpolation rendered approximately two studs above that field at the sampled site. This offset was tolerable for large tree trunks but swallowed small ground details.

**Fix:** Use terrain-only downward raycasts around the analytical height to get the visible surface for each small plant. Apply the same surface placement to stone bases. Retain the analytical fallback when no terrain hit exists. Do not raise every object by an arbitrary global offset.

**Verification:** The revised close screenshot shows cream/lavender flowers and short grass beside the faceted stone. Every flower center is checked to be 0.2–0.8 studs above the terrain ray hit; all checks pass. The small plants are non-colliding and non-queryable so decoration cannot block flight.

**Interview lesson:** Procedural source data and rendered collision surfaces can differ. Validate placement against the actual surface at the scale of the asset, and use close visual review to catch problems that broad route checks miss.

### D32 Match the meadow to the brighter scenery

The user found the first ground-cover pass too sparse and wanted the meadow color to fit the trees and stones. Shifted LeafyGrass from blue-green (73,143,105) to warm green (135,173,85), coordinated terrain rock to (139,141,153), and matched the distant terrain proxies to the new palette. Terrain geometry and tree placements stay intact. Ground cover now occupies 95 patches instead of 42, with nine flowers and nine simple tufts in each broader patch. Stone placement remains limited to 46 accents.

The revised close valley screenshot shows the warmer green base continuous across the ground and slopes, with visible flower/grass clusters. All 15661 geometry/layout assertions passed, including plant grounding, non-collision, ring corridors, and launch clearance. Current world descendants: 70,742. These are counts and geometric checks, not a device-performance benchmark. This is an art-direction refinement; no new defect was encountered. The scenery changes remain uncommitted.

### D33 Ground-level grass needs continuous local coverage

The user still found bare ground when approaching ordinary meadow areas. The earlier 95 decorative patches only covered selected grove sites; increasing those patches and changing terrain color did not provide the expected close-up detail across the landscape.

Added a separate client-only grass layer that follows the camera during walking and low flight. MeadowGrass samples the actual terrain surface, accepting only Grass/LeafyGrass and gentle slopes. Deterministically jittered clumps contain three angular blades in the meadow palette. Their 55-stud neighborhood fades from 36 studs outward, with smooth introduction and a hard cap of 420 pooled clumps / 2,520 non-colliding, non-queryable, shadowless blade Parts per client. Updates occur at approximately 0.12-second intervals with at most 64 new terrain samples per update. Missed terrain samples retry to handle streaming. Returning to old ground reuses hidden parts; grass is not replicated from the server.

An Edit preview showed blades distributed across the close meadow rather than one decorative patch. A dedicated terrain-backed check passed with 403 clumps and 1,650 visible blade parts, verified disappearance in high flight and open water, reappearance on descent without extra allocation, collision/query/shadow flags, and full destruction of temporary test objects. The existing authored world is unchanged. Device frame-rate and long-session playtests remain pending; the pool cap is a resource bound, not a performance benchmark.

**Interview lesson:** Distinguish decorative placements from continuous proximity detail. The user's complaint described missing coverage, not another palette adjustment. Match the implementation to where players expect to see the detail, and bound local rendering work rather than adding millions of permanent objects. This revision remains uncommitted.

Fresh Play check: the automatic controller populated 406 local clumps, and the gameplay screenshot showed close grass around the launch plateau. The server had no CloseMeadowGrass folder, confirming client-only creation. A separate forced high-camera check was inconclusive because the camera returned to Custom and the launch position during the check; its assertion failed, and the temporary camera state was explicitly restored. High-altitude release was verified by the deterministic module check above, not by that interrupted camera test. This did not reveal a grass lifecycle defect.

### D34 Extend grass visibility and match the ground's surface style

The user identified both short grass visibility and a mismatch between noisy terrain texture and flat faceted foliage. Grass spacing changes from 4.8 to 4.2 studs. Alternating grid cells form a dense inner layer reaching 58 studs and a sparse outer layer reaching 80 (previously all stopped at 55), with fade starts at 40/52. The pool is bounded at 950 clumps / 5700 Parts, with 80 new raycasts at most per update. This raises the detail budget; target-device performance still needs measurement.

PaperMeadow is a MaterialVariant override for LeafyGrass, preserving the terrain's material identity, shape, and collision. Its neutral color map removes the default noisy surface pattern. Explicit white roughness and black metalness maps, applied to all three terrain faces, produce the matte ground shown in the close screenshot. The maps use bundled Roblox white/black resources that loaded successfully; no uploaded texture is required. API references: [material overrides](https://create.roblox.com/docs/parts/materials) and [terrain face details](https://create.roblox.com/docs/reference/engine/classes/TerrainDetail).

Material preview hurdle: the initial untextured variant produced a glossy surface. Setting a roughness map alone did not visually settle the result; explicit neutral maps and per-face overrides produced the intended matte appearance. The initial material change also temporarily invalidated visible terrain rendering; later screenshots after the renderer updated showed the terrain intact. No terrain voxel edits were made.

Validation: the grass lifecycle check passed with 858 clumps / 3570 visible blade parts, including visible coverage beyond the old range, pool bounds, altitude/water exclusion, reuse, and cleanup. A close composite screenshot checked the smoother ground against the denser grass. Appearance is still subject to user review. This revision remains uncommitted.

### D35 Double grass range and fill out the scenery

At the user's request, the outer grass layer now reaches 160 studs instead of 80, fading from 105 studs. A sparse one-in-nine grid extends beyond the existing 58/80-stud layers, keeping near density while avoiding four times the dense geometry. The local pool cap rises to 1400 clumps / 8400 blade Parts. Terrain ray depth also increases so sloped ground remains eligible across the longer visibility range.

An additive deterministic tree pass keeps the original grove locations, rejects close overlaps for new trees, and increases the total from 452 to 743. Final roster: 245 broadleaf, 70 birch, 293 pine, 112 blossom, 23 palms. Ground accents increase from 46 to 128 stones and 95 to 261 flower patches. Stones now use smaller authored dimensions (4–8 wide, 3–6 tall, 4–7 deep). Existing slope, animal, ring, and launch exclusion rules apply to the additions.

Validation: 31184 geometry/layout assertions passed, including ring and animal passage clearance, launch directions, grounding, and bounded scenery counts. Grass checks passed with 1252 pooled clumps / 5256 visible blade parts, verified visible coverage beyond 120 studs, altitude/water exclusion, reuse, and cleanup. The close meadow preview was inspected. The authored world has 112,449 descendants before client grass; performance on target devices remains unmeasured. No new defect was encountered. These changes remain uncommitted.

### D36 Mountain routes, summit progression, and compact forests

Created checkpoint `37818bf` before these changes. The user's four annotated screenshots are retained under `references/Mountain_*.png`. Ridge face ascent adds 50 pickups, Cloudspire spiral 156, and the outer plateau crown loop 63. Terrain envelope sampling leaves clearance for tilted rims; arc-length resampling keeps approximately 26-stud spacing. Every trail pickup retains the normal 10-gold reward. Both massif mountains get a second tip reward, found by scanning the opposite local lobe. Summit rewards scale with actual top height: 60 below 750, 80 at 750+, 100 at 1100+, and 120 at 1600+. The server already reads each ring's authored value and deduplicates collection per flight. Existing IDs 1–336 are preserved.

Six separated lowland forests each add 20 closely spaced trees. Their 48-stud planting radii allow overlapping crowns while the 12-stud trunk exclusion and all animal/ring/launch exclusions remain active. Final scenery: 858 trees, 158 stones, 328 meadow patches; 607 total rings; 143,008 authored descendants before client grass. The installer reproduces the edited source. Performance on target devices remains unmeasured.

The first spiral followed every terrain dip. Geometry checks caught two severe tangent reversals (one dot product was negative), creating a route that doubled back vertically around gullies. Applying a non-decreasing height envelope to ascent paths, then smoothing above that envelope, reduced the spiral from 249 to 156 evenly spaced rings and removed the reversals. A first 64-stud forest radius left four trees with nearest neighbors 35–39 studs away; tightening the footprint to 48 studs passed the close-neighbor check. These were caught before the final scene was handed off.

The first WorldData load also failed because Landscape.height returns a number plus two booleans. Passing that call as math.max's final argument forwarded all three values. Assigning its height to a local number before calling math.max fixed the error. Interview lesson: Lua's multiple-return expansion depends on expression position; use an explicit local when calling variadic functions.

Validation: actual terrain/world raycasts check openings, rim samples, summit approaches, flight segments, launch clearance, and animal passages. Route checks cover spacing, tangent alignment, continuous ascent, and closed-loop seam; collection checks exercise the existing swept crossing function for tilted rings. Dense forest, spiral flying-view, and plateau-loop screenshots were reviewed. Full manual flights, progression balance, multiplayer, and device profiling remain pending. These changes are uncommitted for user testing.

### B15 Local material textures work in Edit but are rejected in Play — open

Fresh Play logs after the scenery checkpoint report that local asset maps such as `rbxasset://textures/sky/white.png` are not supported for MaterialVariant/TerrainDetail in the client, followed by invalid TexturePack source warnings. This supersedes D34's claim that preloading those bundled files established working game materials. Preload success and an Edit screenshot did not test the material texture pipeline in a running client.

The correct production fix is to use uploaded, permitted neutral color/roughness/metalness textures and validate the material in Play and a published client. That asset replacement has not been performed in this mountain-layout revision. The geometry and grass layer do not depend on those maps. Interview lesson: verify an asset in its actual rendering subsystem and target execution mode, not just through a generic preload API. The previously recorded distant-terrain streaming/rendering issue also remains open; this revision does not claim to solve it.

D36 final validation: 44,101 geometry/layout assertions passed. Fresh Play loaded 607 ring definitions on both server and client, with 607 server ring models, nine summit rewards, three mountain routes, and six 20-tree forest clusters. The HUD loaded; the client grass controller populated 1159 clumps and no grass folder existed on the server. These startup checks do not substitute for complete manual route flights.

### D37 One distinct wildlife discovery behind each mountain

Committed the preceding mountain routes and forest work as `f5fa574` before changing wildlife. The old sampler allowed up to three animals behind a mountain and selected species by insertion order, producing repeated discoveries. The new requirement is one animal per mountain, with a different species at every mountain.

The sampler now stops after nine encounters: the existing forward bear and rear-field turtle, plus exactly seven mountain animals. A per-mountain occupied flag prevents duplicates, and a roster keyed by peak identity assigns ridge/gorilla, eastern massif/mammoth, table mountain/turtle, Cloudspire/silver fox, southwest broken mountain/raccoon, western massif/bear, and northern broken mountain/candy cat. Flat lowland, distance, and line-of-sight rejection checks still keep animals behind their assigned mountains and off the slopes. Setup asserts every mountain has an encounter. The existing two field positions remain intact. Their duplicate bear/turtle species are intentional field encounters, not repeated mountain discoveries.

Rebuilt wildlife models, rings, and dependent scenery together so removed animals leave no orphan reward and new animals retain clear belly passages. Total animals fall from fifteen to nine and ring rewards from 607 to 601; belly reward values remain 35 gold. Final scene: 858 trees, six dense forests, 158 stones, 329 meadow patches, and 140,593 authored descendants. Prior scene folders are retained in ServerStorage backups.

Validation: 44,037 geometry/layout assertions passed, including exactly one encounter per mountain, unique mountain species, actual model count, far-side placement, hidden-from-launch sightlines, ground/rim clearance, sideways belly collection, and the previous mountain-route/forest checks. Inspected the northern cat encounter in Edit. No new runtime defect was encountered. This is a layout refinement; full manual flights and the previously logged material/streaming limitations remain pending. The new wildlife changes are uncommitted for user testing.

### D38 Let the initial throw settle before full climb penalties

The user reported the climbing slowdown/nose drop felt too strong at the instant of throwing. A controlled starter throw at the maximum 48-degree aim stalled after 0.133 seconds and gained only 11.3 studs before descending; a 40-degree throw stalled at 0.217 seconds. The full quadratic excess-climb drag and pitch-raised stall threshold were active from the first simulation tick, so throw momentum disappeared almost immediately at steep angles.

Flight.new now initializes a simulation age. During the first 1.2 seconds, a smoothstep blend increases the extra climb drag and pitch-dependent portion of the stall threshold from 10% to 100%. Gravity, normal drag, base stall speed, altitude pressure, boost consumption, and recovery remain active. The transition uses simulation time and midpoint sampling, not wall-clock time; only a new server-created flight resets it. Missing age defaults to established flight, and activating boost cannot restart assistance. No launch-speed increase or permanent aircraft stat change was introduced.

Measured starter results without boost/updraft: 48-degree throw stalls at 0.55 seconds and gains 34.7 studs; 40-degree throw stalls at 0.65 seconds and gains 35.1 studs; 24-degree throw stalls at 1.233 seconds versus 0.967 before. The ordinary 10-degree launch result is unchanged. A player still needs to lower the nose into a glide. This intentionally softens the throw rather than granting invulnerability or enough height to bypass plane upgrades.

The previous 87 flight/economy/camera assertions passed before adding focused launch regression checks. New coverage checks delayed steep-throw stall, gravity remaining active, bounded height gain, eventual nose drop, 30/120 Hz consistency, normal behavior after the transition, missing-age handling, boost not resetting age, and low-energy stalls during launch. This is a feel/balance adjustment; user playtesting is still needed. No commit was requested for this revision.

D38 final validation: all 97 flight/pickup/economy/camera assertions and all 44,037 world geometry/layout assertions passed with the new launch transition installed in Studio. The latter includes eight launch directions clearing the starting plateau.

### B16 Steep throw drove the camera underground and landed back on the launch plateau

**Symptoms:** Even after softening initial climb penalties, maximum-angle throws put the camera underground and quickly ended on the starting ground. Reproduction at 48 degrees collided with terrain after 1.767 seconds facing forward/sideways and with the rear deck after 1.667 seconds. Earlier world regression coverage only launched at the default 10 degrees; the isolated flight test checked stall timing and height, not collision with the actual starting terrain. That coverage gap missed the problem.

**Causes:** The camera used `position - aimDirection * followDistance + (0,5,0)`. Increasing aim pitch therefore lowered the camera, reaching below the deck during countdown and early flight. Separately, a 520 × 540-stud flat summit extended beneath the entire short ballistic arc. The plane stalled normally but fell onto that broad surface before reaching open air.

**Fix:** FlightCamera.frame now constructs its trailing offset from horizontal aim, with an independent positive height, and looks a short distance ahead so the plane remains in frame. A two-stud camera sphere sweep shortens the offset at obstacles; the filtered query includes authored world collision and terrain, excluding the character and flight visuals. The same resolver handles aiming, countdown, and flight. API reference: [WorldRoot Spherecast](https://create.roblox.com/docs/reference/engine/classes/WorldRoot#Spherecast). This leaves the existing FOV/boost easing intact.

At the user's request, the launch top is now approximately 110 × 120 studs and the deck 60 × 65, at the original height. Rounded angular contours, uneven ridges, and a wider tapered foot make it read as a small mountain. The initial narrow mesa preview looked like a tower; the revised rocky slopes address that art feedback. The maximum throw angle remains 48 degrees, as the user explicitly requested after considering an angle limit. Normal stall behavior remains active.

**Terrain migration:** Changing Landscape.height alone cannot remove cached terrain. PaperLaunchMesaV3 snapshots the original local voxel region in ServerStorage, then rewrites a bounded 1024 × 1024 footprint through Y −32–416, including air above the new surface to remove the old plateau. Trees, accents, distant silhouettes, and launch props were rebuilt from the final shape. The outer mountain terrain is unchanged. Final authored scene has 141,716 descendants, 870 trees, 161 small stones, and 333 meadow patches.

**Verification:** The new Launch.spec checks actual-scene plane sweeps at 10°, 30°, and 48° in eight directions for three seconds, aiming camera pitch limits, camera view obstruction, a synthetic wall, and removal of high old-terrain voxels. All 6,444 launch/camera checks passed, with minimum sampled camera clearance 2.89 studs. The existing 97 flight/economy/camera checks and 44,421 world geometry/layout checks passed. The revised small mountain was visually inspected in Edit. Sustained maximum-angle input can still eventually stall and land; the fix gives a clear departure rather than unlimited climb. These changes are uncommitted for user testing.

**Interview lesson:** A physics-unit test can pass while the complete player action fails. Test the actual launch at input limits against authored terrain and include the camera's swept volume, rather than treating the camera as an unconstrained point.

### D39 Looser forest groups and immediate stamina recovery

Created the requested checkpoint `974d8b5` before this revision. The user found the 12-stud forest trunk spacing too crowded and boost regeneration too slow/conditional. Expanded each grove's planting radius from 48 to 100 studs and raised the minimum new-trunk distance from all other trees to 30 studs. All six groups still contain 20 added trees, with wildlife and ring exclusions preserved. The wider distribution is visibly more open in the reviewed grove screenshot. Final world: 870 trees, 160 stones, 332 meadow patches, 141,533 descendants.

Boost recovery now behaves as stamina: it begins on the first released simulation tick at a steady rate, regardless of pitch, speed, or stall. Removed the 0.85-second delay, level/downward-glide condition, speed threshold, and unused rest timer. Updated HUD text so it no longer instructs the player to glide to recharge. Recovery rates are 0.9, 0.98, 1.05, 1.12, and 1.2 charge-seconds per second across the five aircraft. The starter refills a fully empty 4.5-second bar in five seconds, compared with 8.35 seconds under uninterrupted qualifying glide previously. Kestrel refills in 3.75 seconds. Capacity, boost acceleration, and aircraft climb/altitude limits are unchanged.

Held boost still prevents regeneration when empty, so it cannot pulse automatically. Re-pressing boost immediately spends recovered charge. Recovery remains server-authoritative, scales with simulation dt, and clamps to capacity. The new rate changes the boost duty cycle; longer route balance and user feel still need playtesting.

Validation: all 101 flight/pickup/economy/camera assertions passed, including first-tick recovery, climbing/stalled recovery, no regeneration while held, five-second starter refill, overflow prevention, zero-time behavior, and 30/120 Hz consistency. All 148,611 geometry/layout assertions passed, including the new all-tree spacing checks around each grove plus existing wildlife and ring clearances. These counts are repeated geometric assertions, not independent play sessions. No new runtime defect was encountered; this is a requested layout and stamina-design refinement. The installer was regenerated and the new changes remain uncommitted for user testing.

### B17 Repeated up-and-down motion from retained upward aim; D40 momentum and recharge tuning

The user reported boost apparently making the plane climb automatically, followed by a sharp nose drop and loss of momentum. Boost itself adds forward speed without changing pitch. The actual feedback issue was that the client retained the upward aim through a stall: after the forced nose drop recovered enough speed, the same old target immediately pulled the plane upward again. A 12-second starter simulation at a retained 24-degree target reproduced four stalls without boost and three after an initial boost burst.

**Reproduction:** Use the starter plane with an upward aim around 24 degrees and leave that aim unchanged. In the controlled fixture, start at Y=350 outside thermals, simulate for 12 seconds at 60 Hz, and feed the retained aim back through Flight.aimInput. Repeat with boost held for the first three seconds and then released. On the old behavior, the plane climbs, loses speed, drops its nose, recovers, and climbs again without a fresh upward mouse input. The fixture reproduced four stalls without boost and three with the initial boost burst; these are simulation results, not counts from a recorded manual play session.

**Why the earlier approach was insufficient:** Increasing launch speed or softening the initial climb penalty gives the plane more energy but leaves the old upward target active. Once recovery finishes, the same feedback loop repeats. The tuning changes improve feel; clearing stale aim fixes the repeated control request. The maximum launch angle was retained at the user's request.

**Fix and expected behavior:** The client now applies Flight.settleAim to server stall telemetry, clearing only upward aim to the normal shallow glide target. An intentional dive target is preserved, and fresh steering remains available. A regression exercising the same 10 Hz telemetry feedback verifies one stall followed by a stable moving glide for both ordinary flight and a three-second boost burst. This is a control-loop fix, not a claim that boost applied vertical thrust.

The starter launch speed increases from 100 to 120 SPS; upgraded launch speeds are 128/136/144/154, preserving tier progression. Ordinary drag and the 250-SPS boost cap remain unchanged. Excess-climb loss coefficients fall to 70/60/50/40/30 across tiers. The base stall threshold is 50, pitch-dependent rise 24, and recovery threshold 68. A stall now eases toward −32° at response rate 1.8 with a lower sink multiplier of 4, replacing the earlier −52°/2.8/8 response. Steep climbs still spend energy and stall; maximum aim remains 48° and altitude limits are unchanged. A maximum-angle starter throw stalls at approximately 0.85 seconds and peaks around 63 studs above release in the deterministic no-boost/no-updraft fixture. A 24-degree throw first stalls at 2.35 seconds versus 1.23 under the preceding tuning.

At the user's request, stamina recovery now waits 0.35 seconds after release before refilling. Its faster recovery rates remain unchanged, and climbing/stalling does not block recovery. Holding boost resets the rest timer; a tick crossing the delay boundary only credits its eligible fraction. The HUD displays RECOVERING SOON during the pause and RECHARGING when charge is actually increasing. Starter empty-to-full time is 5.35 seconds including the pause.

Validation: all 113 flight/pickup/economy/camera assertions passed, including the full stale-aim feedback regression, boost not pitching the plane upward, preserved momentum on release, deliberate steering after recovery, held-empty behavior, partial-delay ticks, 30/120 Hz recharge consistency, and eventual stalls. All 6,337 launch/camera assertions passed at the new speeds; minimum sampled camera clearance was 10 studs. The world scenery was unchanged in this revision, so the previously passed 148,611 layout assertions were not repeated. The installer is regenerated; user feel and long-route progression balance still need playtesting. This fix, momentum tuning, stamina pause, and the preceding grove-spacing changes are included in the requested commit.

Interview lesson: distinguish an acceleration bug from a target-control bug. Isolated force equations did not explain the repeated oscillation; reproducing the loop from retained input through physics and recovery exposed it. Update expectations for deliberately changed tuning while retaining tests for safety bounds and the reported behavior.

**Interview explanation:** “The plane kept an upward steering target after stalling. Its automatic nose drop restored speed, but the controller then pulled it back toward that old target, causing another stall. I reproduced the complete feedback loop, reset stale upward aim from the server's stall state, and verified that the plane recovered into a glide. I also tested that boost only adds speed, releasing boost preserves momentum, and deliberate new steering still works.”
