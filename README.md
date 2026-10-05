# Paper Skies

A Roblox paper-plane exploration prototype built with AI assistance for a software engineering portfolio.

## Play

Press **F** to aim, move the mouse to aim the continuous green trajectory, then click or press **F** again to throw. The character stays on the launch deck while a separate paper plane flies. Aiming supports all directions.

- Mouse: steer the camera and plane.
- Hold Space: boost. The bottom-right bar displays the remaining 4.5-second supply.
- F: aim, throw, or end the run and bank gold.
- Shift or Q: release/recapture the cursor.
- R: end/reset the run.
- Controller: left stick aims, A activates, B resets, R2 boosts.
- Touch: drag to aim and hold the boost button. Device testing is pending.

The base plane launches at 165 SPS, settles toward roughly 150 SPS in a shallow glide, and can reach 250 SPS with boost or a dive. Climbing spends speed; prolonged climbing causes a stall and nose drop. Diving rebuilds speed, and rising air supports exploration of high mountains. This is a tuned kinematic glider.

Optional rings award gold once per flight. Collection hides the ring locally and plays a short chime; the next flight restores it. Spend gold through **Planes** on better folds, stronger throws, or faster turning. Customize selects a paper color; Explore lists the six regions.

## Current world

Project: `G:\Roblox Projects\Roblox Paper Plane`. User screenshots are in `references/`.

- Seven mountains with distinct ridges, broken slopes, table tops, and a tall spire. The tallest summit is about 1,765 studs high.
- A broad 520 by 540 stud launch plateau, with a flat top at elevation 349.
- Expanded lowlands behind the mountains, with coastal edges, water channels, and a central lagoon.
- Fifteen folded animals across five species: lion, elephant, deer, fox, and giraffe. They use 62% of the previous linear size. Two occupy the introductory valley; thirteen sit on flat ground behind mountain silhouettes.
- Seventy-one rings: 45 on ten short curved sky routes, four at low foothill passages, fifteen beneath animals, and seven just above mountain tips. No ring sits within 1,000 horizontal studs of launch.
- Sky rings are 12 studs across with approximately 33–46 studs between neighbors. Belly and summit rings are also 12 studs across; foothill rings are 14. Rims are thin and use varied neon colors.
- Thirteen thermal zones, including rising air near the mountain faces to support summit exploration.
- Simplified broad grass surfaces with decorative grass blades disabled. This build has 143 trees above elevation 180.
- Coarse persistent mountain silhouettes remain visible beyond detailed terrain streaming range. Nearby proxies fade out; the engine streaming-radius property is unchanged.

The current world contains about 18,700 descendants. Actual mobile performance, multiplayer streaming, and complete summit-route playtests remain pending.

Mountain silhouettes were informed by [NPS mountain geology photographs](https://www.nps.gov/romo/learn/nature/geologicactivity.htm) and this [Monument Valley photograph](https://upload.wikimedia.org/wikipedia/commons/9/9b/Over_Monument_Valley%2C_Navajo_Nation.jpg). These informed general shapes; no photographic textures were imported.

## Recreate in Studio

1. Run `python tools/GenerateExplorationInstaller.py`.
2. In Studio Edit mode, run `tools/InstallStudio.luau` through the command bar or Studio MCP.
3. Enter Play mode to load fresh modules.
4. Save a local place file in Studio to retain the complete scene.

Source files do not automatically sync with Studio. The assistant installed this revision in the active Studio scene; saving a place file and publishing were not performed.

The installer updates scripts and scenery. On a fresh place it creates the plane template with the earlier art builder. Previous scenery is archived under `ServerStorage.PaperFlightBackups`.

Terrain generation is guarded by `PaperArchipelagoV4`. It clears only the authored footprint in bounded chunks, writes 1,840 height-field tiles, then carves four low foothill passages. The earlier terrain snapshot is retained; the V2 build is reproducible from commit `5fd61e2`. Generation can take several minutes. Re-running the same revision skips terrain regeneration and rebuilds scenery deterministically.

Earlier installers are retained for history. Use **GenerateExplorationInstaller.py + InstallStudio.luau** for the current game.

## Source layout

- `src/shared/Config.luau`: speed, boost, world bounds, audio, upgrades.
- `src/shared/Flight.luau`: gliding, stalls, finite boost, steering, swept ring crossing.
- `src/shared/Landscape.luau`: island extensions, mountain surfaces, launch plateau, foothill passages.
- `src/shared/WorldData.luau`: reproducible wildlife placement, curved routes, summit rewards, thermals.
- `src/shared/Economy.luau`: prices, level limits, balance validation.
- `src/server/RaceServer.server.luau`: authoritative simulation, collision, rewards, input validation, streaming prefetch, cleanup.
- `src/server/ProfileStore.luau`: Studio session progress and published-server persistence.
- `src/client/FlightClient.client.luau`: camera, trajectory, HUD, wind, streaks, boost, collection feedback, distant silhouettes.
- `tools/BuildExplorationWorld.luau`: terrain, scenery, rings, folded wildlife.
- `tests/Flight.spec.luau`: 27 flight, pickup, and economy assertions.
- `tests/World.spec.luau`: 414 geometry and discovery-layout assertions against actual scenery.

## Engineering decisions

The client sends bounded steering axes and a boost-held boolean at 15 Hz. The server simulates at 60 Hz, validates inputs, rate-limits requests, and clears stale steering and boost requests after 0.5 seconds. Positions, fuel, and rewards are computed on the server.

Ring collection uses spatial bins and swept crossing through the ring opening, reserving a 3.6-stud margin for the plane. Each ring pays once per run. Clearing the session before banking prevents repeated resets from paying twice. Distance also awards a small amount of gold.

A replication focus follows the plane while the avatar stays behind. Bounded streaming requests preload scenery ahead of flight. The client interpolates a local visual plane. Wind and side streaks vary with speed. Collected rings remain hidden if they stream back during the same run.

Wind asset: 687874741. Collection sound: [ding-ding stronger by The_Sink, asset 2415965014](https://create.roblox.com/store/asset/2415965014).

Published servers use UpdateAsync, session ownership, renewable leases, retries, periodic saves, and departure/shutdown saves. Failed loads do not create empty replacement profiles. **Studio progress is session-only; published persistence is not end-to-end verified.**

## Validation

Current revision:

- All 27 flight, pickup, and economy assertions passed.
- All 414 geometry/layout assertions passed: ring openings, foothill passages, belly flight envelopes, summit approaches, wildlife concealment, plateau flatness, and sky-route spacing.
- Runtime presentation check: sending one server pickup event hid all 48 ring segments and played one loaded chime. Repeating the event did not replay it. This checks client feedback separately from physical flight collection.
- Visually inspected expanded rear meadows, smaller wildlife, the highest summit ring, and the continuous aiming line.
- Latest Play session started without console errors.
- Generated installer and source whitespace checks passed.

Earlier revision checks verified 250 SPS boost, fuel exhaustion, live collection and banking, upgrade deductions, malformed launch rejection, reset cleanup, duplicate-payout prevention, wind playback, and the avatar remaining on the deck.

Pending: user approval of art/handling, complete flights to the new summit rewards, multiplayer, phone/tablet/controller, high-latency/load profiling, and published streaming/audio/persistence verification. Terrain collision sweeps the plane center rather than its full wingspan. Client prediction/reconciliation is not implemented.

## Bugs and interview preparation

See [Bugs and engineering lessons](docs/BUGS_AND_LESSONS.md) for observed failures, root causes, fixes, verification evidence, open limitations, and three interview stories. Confirmed bugs are distinguished from design iterations and preventive safeguards.

## Portfolio and Git

Baseline: `d3fe27b`. Last user-approved snapshot: `5fd61e2` (exploration, finite boost, neon trails). The current mountain/discovery revision remains uncommitted for playtesting.

Keep readable source, reproducible builders, tests, and real development history. Place files are ignored by Git. Describe AI assistance accurately and be prepared to explain flight energy, boost budgeting, server validation, collection, reward banking, streaming, and persistence tradeoffs.
