# Paper Skies

A Roblox paper-plane exploration prototype built with AI assistance for a software engineering portfolio.

## Play

Press **F** to aim, move the mouse to rotate the smooth green aiming arc, then click or press **F** again to throw. The character stays on the plateau while a separate plane flies. Aiming supports every direction; the default throw angles slightly upward to clear the plateau. The preview is a fixed-shape direction guide, with a 0.9-stud core and soft glow; it no longer predicts the equipped plane’s physics. Its curvature remains constant as aim rotates.

- Mouse: aim and steer.
- Hold Space: spend boost stamina (4.5-second capacity).
- Release boost: stamina recovers after a 0.35-second pause, including while climbing or stalled. The starter then refills from empty in five seconds (5.35 seconds total); stronger planes refill faster. The bar turns green while recovering.
- F: aim, throw, or end the run and bank gold.
- Shift or Q: release/recapture the cursor.
- R: end/reset the run.
- Controller: left stick aims, A activates, B resets, R2 boosts.
- Touch: drag to aim and hold boost. Device testing is pending.

The starter launches at 90 SPS and gradually settles toward its approximately 100-SPS natural glide speed. Diving and boost can exceed that speed, up to its 160 SPS cap. Both launch speed and maximum speed increase with aircraft tier; the server enforces the equipped type's cap. Climbing spends speed, prolonged climbing causes a stall and nose drop, and diving rebuilds speed. Fresh throws start with 10% of the extra steep-climb drag and pitch-dependent stall threshold, easing smoothly to normal over 1.2 seconds. Gravity, base stall speed, ordinary drag, altitude pressure, and boost costs remain active throughout; this is a short launch transition, not stall immunity. Extra climb drag is now gentler, and the stall nose target is −32° instead of −52°. After a stall, the controls clear any stale upward aim to a shallow glide so recovery does not immediately trigger another climb/stall cycle. Fresh mouse input can still request a climb. The starter begins spending extra energy beyond a 12-degree climb; stronger types tolerate steeper climbs (up to a 28-degree comfort threshold on Kestrel). Above each type's air ceiling, additional drag and sink gradually make further climbing harder. Range comes from energy, drag, sink, and flying technique; there is no per-type distance cutoff. This is a tuned kinematic glider. Collect optional neon rings and distance gold to buy different plane types through **Planes**. Customize changes paper color; Explore lists regions.

The camera orbits above the plane independently of steep aim and shortens its follow distance when a volume sweep hits scenery. This applies while aiming, during the throw countdown, and in flight. The maximum aim angle remains 48 degrees. A throw briefly widens the camera to about 80 degrees and increases follow distance. It settles back to the normal 70-degree view. Active boost smoothly widens to 77 degrees and moves the camera from 29 to 34.5 studs back (half the previous boost effect); releasing boost returns to normal even while speed remains high.

## Plane progression

| Type | Gold | Launch speed | Top speed | Rising air fades out by |
| --- | ---: | ---: | ---: | ---: |
| Paper Dart | Free | 90 SPS | 160 SPS | 650 studs |
| Lockwing | 180 | 105 SPS | 190 SPS | 950 studs |
| Delta | 550 | 120 SPS | 220 SPS | 1300 studs |
| Sailwing | 1400 | 135 SPS | 250 SPS | 1750 studs |
| Kestrel | 3200 | 150 SPS | 280 SPS | 2250 studs |

The five models have different wing shapes and folds. Higher types reduce drag and sink while improving handling. The hangar has 3D previews, server-validated purchases, permanent ownership within the saved profile, and free switching between owned types. Switching during flight is rejected.

Updraft strength was reduced from a previous mountain-zone maximum of 52 to 18 before aircraft efficiency and radial falloff. The starter receives at most 12.6 studs/second of uplift, tapering to zero by 650 studs. Advanced types can use higher air. This is an air-response limit, not an invisible positional ceiling. Full summit routes still need playtesting.

[Online reference images and plane balance](docs/PLANE_REFERENCES.md) records the web sources and model details. Legacy numerical upgrades are preserved as existing profile bonuses; the current shop sells named aircraft.

## World and discovery

The seven mountains, island lobes, ring trails, and thermals now surround the starting plateau. Tests require at least three mountains on either side of each main axis and no gap greater than 75 degrees between mountain bearings. Outer meadows remain behind the mountains.

The world includes a compact rocky launch mountain with a flat 110 × 120-stud top, varied mountain profiles, a lagoon, coastal water, four low foothill passages, and nine stylized animals across seven species. A bear occupies the forward introductory field and a turtle occupies the field behind launch; one animal sits behind each of the seven mountain silhouettes, with a different species assigned to every mountain. All wildlife uses a 0.62 authored model scale.

There are 601 rewards: 310 rings on thirty-one existing sky routes, 269 mountain-surface trail rings, four foothill rewards, nine belly rewards, and nine summit rewards. The annotated reference routes add 50 rings up the near face of the ridge, 156 on a rising spiral around Cloudspire, and 63 on a closed loop over the outer mountain plateau. These are optional pickups, not ordered checkpoints. Their 24-stud openings face the route tangent, spaced about 26 studs along the path. The spiral and ridge routes climb continuously across gullies. Both double-peaked mountains now have a reward on each tip. No reward is within 1000 horizontal studs of launch. Aircraft ceilings and lift strength are unchanged; full climbing routes still need flight playtesting.

The mountain discoveries use one gorilla, mammoth, turtle, silver fox, raccoon, bear, and candy cat, assigned by mountain identity. The two field encounters add a second bear and turtle; mountain discoveries do not repeat species. The legacy lion/elephant/deer/fox/giraffe builder has been replaced. Layered body silhouettes, stepped shells/ears, coats, and expressive faces follow the supplied screenshots. All nine animals now have cylindrical legs and rounded paws; the gorilla also has rounded arms, joints, hands, and cuffs. Reference filenames and modeling decisions are recorded in [Animal references](docs/ANIMAL_REFERENCES.md).

Bears, foxes, raccoons, turtles, and candy cats now have shorter legs and lowered bodies, retaining their original head and torso proportions. Their sideways belly rewards are 36-stud circles centered at or below ground, exposing a half-circle or smaller upper arc. Fly through the visible opening between the front and rear legs. The two gorilla/mammoth encounters keep their taller stance and complete 24-stud rings. The authored model scale remains 0.62.

The nine summit rewards use warm golden neon cores, a soft outer glow, local light, sparse rim sparkles, and larger distant halos. Rewards stay at 10 gold for regular sky rings, 25 for foothill passages, 35 for animal belly rings, and 60–120 for summit rings (60 below 750 studs, 80 at 750+, 100 at 1100+, 120 at 1600+). All new consecutive route rings remain 10 gold. Summit effects hide locally on collection and return for the next run, including nested effects that arrive after collection. The nine summit models remain replicated at distance; their halos hide near the actual opening.

Meadows use a smooth matte PaperMeadow override on LeafyGrass terrain plus a client-only layer of angular grass blades that becomes visible near the ground. An earlier attempt to set the non-scriptable Decoration property had silently failed; the material change was visually verified to remove the dense blades. The authored scene has 141,533 descendants after the scenery update. Close grass adds at most 8,400 non-colliding blade Parts locally per client, recycled around the camera rather than stored across the whole map. Expanded trails also influence tree placement so flight corridors remain clear. The 870 trees include six loose groves with 20 new trees each, 100-stud planting radii, and at least 30 studs between added trunks and other trees. A warm green meadow palette now matches the foliage, with cooler gray stone colors. Meadow accents add 160 small angular stones and 332 fuller patches of cream/lavender flowers and simple grass, each with nine flowers and nine low-poly tufts. The deterministic scenery pass respects the new ring approaches and existing animal clearances; groves occupy six separated lowland sites. This uses more primitives than the previous simple crowns; target-device performance has not been benchmarked.

**Open visual issue:** Far mountain terrain and its coarse proxies were absent in the Studio Play rear-view check, although the summit halos remained visible. The same rear mountains render correctly in Edit mode, and server terrain raycasts find them. Extra streaming focus made the rear terrain queryable on the client without resolving that screenshot. The exact rendering cause remains unconfirmed. This issue is tracked in the bug log; full distant-scene visibility is not claimed as verified.

Mountain shapes were informed by [NPS geology photographs](https://www.nps.gov/romo/learn/nature/geologicactivity.htm) and a [Monument Valley photograph](https://upload.wikimedia.org/wikipedia/commons/9/9b/Over_Monument_Valley%2C_Navajo_Nation.jpg).

## Recreate in Studio

Project: `G:\Roblox Projects\Roblox Paper Plane`.

1. Run `python tools/GenerateExplorationInstaller.py`.
2. Run `tools/InstallStudio.luau` in Studio Edit mode.
3. Enter Play to load fresh modules.
4. Save a local place file to retain the scene.

Source files do not automatically sync with Studio. The assistant installed the revision in the active scene; saving a place file and publishing were not performed.

The installer builds the five aircraft and world from source. Terrain uses the `PaperArchipelagoV5` guard and 1720 height-field tiles. The clear operation covers the union of old and new authored bounds so moving the islands does not leave old land behind. Prior scenery and terrain snapshots remain in ServerStorage for the current editing session. Release preparation marks PaperFlightBackups non-archivable: these development copies are omitted from saves, Play clones, and publishes. Previous published place versions and Git preserve earlier revisions; export any session snapshot separately before closing Studio if it is needed. Re-running the same terrain revision rebuilds scenery while skipping terrain. The compact starting mountain has its own PaperLaunchMesaV3 migration: it snapshots and rewrites only the old launch footprint (X −1024–0, Z 0–1024, Y −32–416), removing the old wide plateau voxels. The outer exploration mountains remain intact.

## Source layout

- `src/shared/Config.luau`: aircraft catalog, prices, flight bounds, audio, tuning.
- `src/shared/Flight.luau`: gliding, aircraft climb/altitude response, server-owned boost stamina, steering, swept ring crossing.
- `src/shared/FlightCamera.luau`: deterministic throw and boost camera easing.
- `src/shared/Scenery.luau`: original faceted trees, blossom crowns, stones, flowers, and sparse grass.
- `src/shared/MeadowGrass.luau` and `src/client/MeadowGrass.client.luau`: pooled close-range grass, following the viewer over meadow terrain.
- `src/shared/Landscape.luau`: islands, mountains, plateau, foothill passages.
- `src/shared/WorldData.luau`: wildlife placement, reward routes, summit data, aircraft-specific thermals.
- `src/shared/Economy.luau`: ownership, purchases, selection, legacy upgrade helpers.
- `src/server/RaceServer.server.luau`: authoritative simulation, rewards, purchases, streaming, cleanup.
- `src/server/ProfileStore.luau`: normalization, Studio session profiles, published save logic.
- `src/client/FlightClient.client.luau`: camera, hangar, model selection, HUD, wind, streaks, pickup feedback, summit halos.
- `tools/BuildPlaneModels.luau`: five reproducible folded-paper models.
- `tools/BuildExplorationWorld.luau`: terrain, scenery, rings, wildlife.
- `src/shared/ReferenceAnimals.luau`: all seven procedural wildlife models.
- `tests/Flight.spec.luau`: 1779 assertions.
- `tests/World.spec.luau`: terrain-backed geometry and discovery-layout assertions.

## Engineering decisions

The client sends steering and boost requests at 15 Hz. The server simulates at 60 Hz, validates types and ranges, rate-limits requests, and clears stale input after 0.5 seconds. Plane attributes and purchases are resolved from the server catalog.

Ring rewards use spatial bins and swept plane crossing through an opening with a 3.6-stud margin. Each ring pays once per run. Distance income is 1 gold per 200 studs (previously 40); a 1000-stud flight earns 5 distance gold instead of 25. Plane prices are unchanged; higher summit rewards now scale by altitude. Live HUD totals and final banked rewards share `Economy.flightReward`. Removing the session before banking prevents repeated reset payouts. Client collection IDs keep returning streamed ring parts hidden.

A replication focus follows the plane while the avatar stays behind. Flight rendering interpolates the server state. Prediction/reconciliation is not implemented.

Published profile writes use UpdateAsync with ownership leases, retries, periodic saves, and departure/shutdown saves. Normalization retains valid plane ownership and selection; old profiles keep gold and existing bonuses. **Studio progress is session-only; published persistence has not been verified end to end.**

Wind asset: 687874741. Pickup audio: [coin_pickup_1 by thienbao2109](https://create.roblox.com/store/asset/4612374807), one quiet voice at volume 0.18 and fixed playback speed 0.92. A 25 ms attack, 180 ms release, and reduced high frequencies soften its 500 ms playback window. Original chill EDM loop: `assets/audio/PaperSkies.wav`; regeneration and Roblox setup are documented in `docs/AUDIO.md`. Background music uses the uploaded PaperSkies asset `126932983544303` at volume 0.16, with looping and the shared Sound toggle.

## Validation

- 1779 flight, stamina, camera, pickup, economy, profile-normalization, and model assertions passed.
- All five types reached their configured top speed during a 4.5-second boost fixture; dives and legacy upgrade bonuses stayed within each type's cap.
- Earlier camera samples reached 79.45 degrees on throw and 83.99 on boost, then returned to 70 on release; boost now targets 77 degrees. Server telemetry and the HUD both showed stamina recovery during a suitable glide.
- 2875 actual-scene geometry/layout assertions passed, including eight default throw directions, ring-rim clearance samples, and sideways animal-ring crossings. These are repeated geometric samples, not 2875 distinct play sessions.
- Live purchase deducted Delta's real 550-gold price; repeat selection was free.
- Held and server-launched models matched Delta; changing type during flight was rejected; Kestrel could be purchased after landing.
- A fresh summit pickup presentation check received one event, hid 49 parts including the invisible anchor, and disabled the halo.
- Hangar previews, distinct aircraft silhouettes, visible distant halos, and the flat meadow material were visually inspected.
- Temporary test balances, rendering diagnostics, and Play-session changes were removed. Normal starter gold is zero.

Earlier revision tests covered 250 SPS boost, fuel exhaustion, live reward banking, malformed inputs, duplicate resets, and audio. Current automated totals are assertions, not hundreds of independent full-game playtests.

Pending: published cold-join timings and low-device rendering coverage, full flights to new summits, multiplayer, mobile/controller, latency/load profiling, and published persistence/audio/streaming. Terrain collision still sweeps the plane center rather than its full wingspan.

## Bugs and interview preparation

[Bugs and engineering lessons](docs/BUGS_AND_LESSONS.md) records symptoms, causes, fixes, failed test attempts, evidence, open limitations, and interview examples.

## Git and portfolio

The latest checkpoint is **`cf89033` — Tune launch and top speeds for each plane tier**. Launch/top speed progression is 90/160, 105/190, 120/220, 135/250, and 150/280 SPS. The current uncommitted revision improves startup content and defers rear scenery. The root cause, reproduction, and interview explanation are recorded in bug B17.

Describe AI assistance accurately. Be prepared to explain aircraft stats, flight energy, boost budgeting, input validation, server-owned purchases, swept collection, profile normalization, and the limits of the current validation.

Scenery verification: 119,063 geometry/layout assertions passed with staged content temporarily restored, including mountain route spacing, continuous ascent, tilted collection planes, forest neighbors, and terrain clearance. Green/blossom trees and grounded meadow details were visually inspected. Tree models are limited to 130 primitives (current maximum 124); flower/grass accents do not collide with planes.

Close grass: three triangular blades per clump, 4.2-stud spacing with jitter, 1.6–3.1 studs tall. Interleaved detail layers reach 58, 80, and 160 studs, fading from 40, 52, and 105 studs respectively. The sparse outer layer doubles the prior range while retaining dense near coverage. Water, rock, steep surfaces, and high flight are excluded. Checks verified 1252 pooled clumps and 5256 visible blade parts in the test meadow, visible grass beyond 120 studs, release at altitude/water, reuse on return, and cleanup. The per-client cap is 1400 clumps / 8400 blade Parts. Device frame-rate testing remains pending.

Material limitation found in fresh Play: Roblox rejects the bundled local PNGs used by PaperMeadow's PBR maps, even though those files can preload and the Edit preview renders. The custom material is not verified in a published client. Replace these maps with uploaded texture assets before claiming the matte override is production ready; see the bug log.

Launch regression: 6,476 checks passed for 10°, 30°, and maximum 48° throws in eight directions over three seconds, camera clearance while aiming/counting down/flying, removal of old plateau terrain, and camera shortening in front of a wall. Minimum sampled camera clearance with the current flight tuning was 10.00 studs. These deterministic checks supplement user flight testing; they do not guarantee unlimited survival when continuously pulling upward.

Boost stamina: releasing boost recovers 0.9/0.98/1.05/1.12/1.2 seconds of charge per second for Dart/Lockwing/Delta/Sailwing/Kestrel. The 4.5-second bar takes 5.0/4.59/4.29/4.02/3.75 seconds of active recovery respectively, plus the 0.35-second release pause. A 0.35-second released-input delay precedes recovery; there is no flight-attitude requirement. Held boost consumes charge and blocks recharge even when empty; the bar cannot exceed capacity.


## Startup and exploration loading

Mountains and summit goals take priority. ReplicatedFirst contains 126 coarse mountain tiles (504 parts) and nine temporary summit beacons, about 740 instances in total. The regular summit rings remain Persistent. A fallback tile is hidden near the camera only when terrain raycasts confirm its replacement exists. Early beacons hand visibility to the normal ring controller as each real summit model arrives.

Three hundred and eight models behind the lower sides of mountains (19,721 parts, including seven wildlife encounters and their belly rings) begin in ServerStorage.PaperDeferredWorld. The server reveals nearby models within 1400 studs of any player or active plane, in batches of roughly 900 instances per 0.1-second update. All current individual models fit that budget. Models return to storage only after all observers stay farther than 1800 studs for ten seconds. The complete original geometry retains server collision when active; this is proximity staging, not camera-based occlusion. Upper slopes and summit routes are not staged.

All 332 flower patches now replicate a seed, 18 baked surface heights, and one invisible anchor instead of 81 decorative parts each. A client reconstructs at most two patches per update within 220 studs, keeps at most 24 patches, and releases them beyond 250 studs. The existing close-grass pool is unchanged. Original patch placement was retained and all 26,892 reconstructed part positions were checked against the prior scene.

Measured Studio startup scene: 94,253 world instances / 92,321 parts, compared with 141,533 / 139,106 before preparation (about one-third fewer initial world parts). The 796,305-instance backup folder is omitted from Play/publish serialization; fresh Play confirmed it was absent. This reduces cold-server contents, not client download traffic from ServerStorage. The flight menu uses a small Regions module rather than rerunning WorldData generation (the latter measured 0.337 seconds in one Edit fixture).

Validation: 28,400 streaming/detail assertions, 119,063 layout assertions, 1,779 flight assertions, and 6,476 launch/camera checks passed. Fresh Play ran the new scripts without new script errors, created all 504 skyline parts, kept all 308 rear models staged at spawn, and loaded the HUD. The early script logged 0.009 seconds for local setup; that is not a network join-time measurement. Existing invalid local PBR texture warnings remain.

Studio's missing distant objects were separately traced to Automatic rendering quality: colored probes at 200/600/1400/2500 studs existed in view, but only the nearest rendered. Setting Studio Rendering.QualityLevel to Level21 made all probes and the mountain terrain visible immediately. Probes were removed; Studio was left at Level21 for visual testing. This is a local Studio preference, not a game script forcing player graphics settings. Distant visibility still depends on device graphics quality. Re-publish privately and measure a fresh Roblox-app join before reporting an improvement over the user's original 20–30-second load.
