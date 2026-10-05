# Paper Skies

A Roblox paper-plane exploration prototype built with AI assistance for a software engineering portfolio.

## Play

Press **F** to aim, move the mouse to aim the continuous green trajectory, then click or press **F** again to throw. The character stays on the plateau while a separate plane flies. Aiming supports every direction; the default throw angles slightly upward to clear the plateau.

- Mouse: aim and steer.
- Hold Space: spend boost stamina (4.5-second capacity).
- Release boost and glide level/downward: recharge after 0.85 seconds. The bar turns green while recovering.
- F: aim, throw, or end the run and bank gold.
- Shift or Q: release/recapture the cursor.
- R: end/reset the run.
- Controller: left stick aims, A activates, B resets, R2 boosts.
- Touch: drag to aim and hold boost. Device testing is pending.

Climbing spends speed, prolonged climbing causes a stall and nose drop, and diving rebuilds speed. The starter loses energy sharply beyond a 12-degree climb; stronger types tolerate steeper climbs (up to a 28-degree comfort threshold on Kestrel). Above each type's air ceiling, additional drag and sink gradually make further climbing harder. Range comes from energy, drag, sink, and flying technique; there is no per-type distance cutoff. This is a tuned kinematic glider. Collect optional neon rings and distance gold to buy different plane types through **Planes**. Customize changes paper color; Explore lists regions.

A throw briefly widens the camera to about 80 degrees and increases follow distance. It settles back to the normal 70-degree view. Active boost smoothly widens to 84 degrees; releasing boost returns to normal even while speed remains high.

## Plane progression

| Type | Gold | Launch speed | Rising air fades out by |
| --- | ---: | ---: | ---: |
| Paper Dart | Free | 165 SPS | 650 studs |
| Lockwing | 180 | 172 SPS | 950 studs |
| Delta | 550 | 180 SPS | 1300 studs |
| Sailwing | 1400 | 188 SPS | 1750 studs |
| Kestrel | 3200 | 198 SPS | 2250 studs |

The five models have different wing shapes and folds. Higher types reduce drag and sink while improving handling. The hangar has 3D previews, server-validated purchases, permanent ownership within the saved profile, and free switching between owned types. Switching during flight is rejected.

Updraft strength was reduced from a previous mountain-zone maximum of 52 to 18 before aircraft efficiency and radial falloff. The starter receives at most 12.6 studs/second of uplift, tapering to zero by 650 studs. Advanced types can use higher air. This is an air-response limit, not an invisible positional ceiling. Full summit routes still need playtesting.

[Online reference images and plane balance](docs/PLANE_REFERENCES.md) records the web sources and model details. Legacy numerical upgrades are preserved as existing profile bonuses; the current shop sells named aircraft.

## World and discovery

The seven mountains, island lobes, ring trails, and thermals now surround the starting plateau. Tests require at least three mountains on either side of each main axis and no gap greater than 75 degrees between mountain bearings. Outer meadows remain behind the mountains.

The world includes a broad flat launch plateau, varied mountain profiles, a lagoon, coastal water, four low foothill passages, and fifteen paper animals across five species. Two animals occupy introductory lowlands; thirteen sit behind mountain silhouettes. Animals remain at 62% of the previous linear size.

There are 71 rings: 45 on ten short curved sky routes, four at foothill passages, fifteen beneath animals, and seven at mountain summits. No ring is within 1000 horizontal studs of launch. Sky rings are 12 studs across and roughly 33–46 studs apart within a cluster. Belly and summit rings are also 12 studs across; foothill rings are 14.

The seven summit rewards remain replicated and have small screen-sized halos for visibility at distance. Halos hide near the physical ring and on collection. Both visual segments and the halo are hidden in the collection event handler.

Meadows now use LeafyGrass terrain material. An earlier attempt to set the non-scriptable Decoration property had silently failed; the material change was visually verified to remove the dense blades. The current scene has about 18,600 descendants and 109 trees above elevation 180.

**Open visual issue:** Far mountain terrain and its coarse proxies were absent in the Studio Play rear-view check, although the summit halos remained visible. The same rear mountains render correctly in Edit mode, and server terrain raycasts find them. Extra streaming focus made the rear terrain queryable on the client without resolving that screenshot. The exact rendering cause remains unconfirmed. This issue is tracked in the bug log; full distant-scene visibility is not claimed as verified.

Mountain shapes were informed by [NPS geology photographs](https://www.nps.gov/romo/learn/nature/geologicactivity.htm) and a [Monument Valley photograph](https://upload.wikimedia.org/wikipedia/commons/9/9b/Over_Monument_Valley%2C_Navajo_Nation.jpg).

## Recreate in Studio

Project: `G:\Roblox Projects\Roblox Paper Plane`.

1. Run `python tools/GenerateExplorationInstaller.py`.
2. Run `tools/InstallStudio.luau` in Studio Edit mode.
3. Enter Play to load fresh modules.
4. Save a local place file to retain the scene.

Source files do not automatically sync with Studio. The assistant installed the revision in the active scene; saving a place file and publishing were not performed.

The installer builds the five aircraft and world from source. Terrain uses the `PaperArchipelagoV5` guard and 1720 height-field tiles. The clear operation covers the union of old and new authored bounds so moving the islands does not leave old land behind. Prior scenery is archived under ServerStorage; the earlier terrain snapshot is retained. Re-running the same terrain revision rebuilds scenery while skipping terrain.

## Source layout

- `src/shared/Config.luau`: aircraft catalog, prices, flight bounds, audio, tuning.
- `src/shared/Flight.luau`: gliding, aircraft climb/altitude response, server-owned boost stamina, steering, swept ring crossing.
- `src/shared/FlightCamera.luau`: deterministic throw and boost camera easing.
- `src/shared/Landscape.luau`: islands, mountains, plateau, foothill passages.
- `src/shared/WorldData.luau`: wildlife placement, reward routes, summit data, aircraft-specific thermals.
- `src/shared/Economy.luau`: ownership, purchases, selection, legacy upgrade helpers.
- `src/server/RaceServer.server.luau`: authoritative simulation, rewards, purchases, streaming, cleanup.
- `src/server/ProfileStore.luau`: normalization, Studio session profiles, published save logic.
- `src/client/FlightClient.client.luau`: camera, hangar, model selection, HUD, wind, streaks, pickup feedback, summit halos.
- `tools/BuildPlaneModels.luau`: five reproducible folded-paper models.
- `tools/BuildExplorationWorld.luau`: terrain, scenery, rings, wildlife.
- `tests/Flight.spec.luau`: 82 assertions.
- `tests/World.spec.luau`: 444 assertions.

## Engineering decisions

The client sends steering and boost requests at 15 Hz. The server simulates at 60 Hz, validates types and ranges, rate-limits requests, and clears stale input after 0.5 seconds. Plane attributes and purchases are resolved from the server catalog.

Ring rewards use spatial bins and swept plane crossing through an opening with a 3.6-stud margin. Each ring pays once per run. Removing the session before banking prevents repeated reset payouts. Client collection IDs keep returning streamed ring parts hidden.

A replication focus follows the plane while the avatar stays behind. Flight rendering interpolates the server state. Prediction/reconciliation is not implemented.

Published profile writes use UpdateAsync with ownership leases, retries, periodic saves, and departure/shutdown saves. Normalization retains valid plane ownership and selection; old profiles keep gold and existing bonuses. **Studio progress is session-only; published persistence has not been verified end to end.**

Wind asset: 687874741. Pickup audio: [ding-ding stronger by The_Sink](https://create.roblox.com/store/asset/2415965014).

## Validation

- 82 flight, stamina, camera, pickup, economy, profile-normalization, and model assertions passed.
- A controlled 24-degree climb stalled the starter at 3.18 seconds; Kestrel remained unstalled at four seconds.
- Live camera samples reached 79.45 degrees on throw and 83.99 on boost, then returned to 70 on release. Server telemetry and the HUD both showed stamina recovery during a suitable glide.
- 444 actual-scene geometry/layout assertions passed, including eight default throw directions.
- Live purchase deducted Delta's real 550-gold price; repeat selection was free.
- Held and server-launched models matched Delta; changing type during flight was rejected; Kestrel could be purchased after landing.
- A fresh summit pickup presentation check received one event, hid 49 parts including the invisible anchor, and disabled the halo.
- Hangar previews, distinct aircraft silhouettes, visible distant halos, and the flat meadow material were visually inspected.
- Temporary test balances, rendering diagnostics, and Play-session changes were removed. Normal starter gold is zero.

Earlier revision tests covered 250 SPS boost, fuel exhaustion, live reward banking, malformed inputs, duplicate resets, and audio. Current automated totals are assertions, not hundreds of independent full-game playtests.

Pending: the distant-terrain Play rendering issue, full flights to new summits, multiplayer, mobile/controller, latency/load profiling, and published persistence/audio/streaming. Terrain collision still sweeps the plane center rather than its full wingspan.

## Bugs and interview preparation

[Bugs and engineering lessons](docs/BUGS_AND_LESSONS.md) records symptoms, causes, fixes, failed test attempts, evidence, open limitations, and interview examples.

## Git and portfolio

The latest requested checkpoint is **`b4a7299` — Add aircraft hangar and surround launch with exploration landmarks**. Earlier snapshots include `3cf87cc`, `5fd61e2`, and `d3fe27b`. Rechargeable stamina, aircraft flight limits, and throw/boost camera changes remain uncommitted for user testing.

Describe AI assistance accurately. Be prepared to explain aircraft stats, flight energy, boost budgeting, input validation, server-owned purchases, swept collection, profile normalization, and the limits of the current validation.
