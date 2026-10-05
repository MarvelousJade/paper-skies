# Paper Skies

A Roblox paper-plane exploration prototype built with AI assistance for a software engineering portfolio.

## Play

Press **F** to aim, move the mouse to aim the green trajectory, then click or press **F** again to throw. The visible character stays on the launch deck while a separate plane flies.

- Mouse: steer the camera and plane.
- **Hold Space: boost.** The blue bottom-right bar and seconds label show remaining boost time.
- F: aim, throw, or end the current run and bank its gold.
- Shift or Q: release/recapture the cursor.
- R: end/reset the run.
- Controller: left stick aims, A activates, B resets, R2 boosts.
- Touch: drag to aim and hold the boost button. Actual device testing is pending.

The base plane launches at **165 SPS**, settles toward roughly **150 SPS** in a shallow glide, and can reach **250 SPS** with boost or a dive. Boost provides **4.5 seconds per throw**; releasing Space preserves the remaining time, and holding it after depletion provides no thrust. Space no longer sets the glide angle.

Climbing spends speed. Continuing to pull up eventually causes a stall and automatic nose drop. Lowering the nose rebuilds speed. Spiraling air markers identify thermals that extend flights. This is a tuned kinematic glider, not a full aerodynamic simulation.

Pass through optional neon rings to collect gold. Sky trails contain five or six thin, large rings, with open space between groups. Ring colors vary across cyan, pink, green, violet, amber, and white. Six additional rings mark rock passages. These are reward routes, not an ordered race or required completion objective.

Spend gold through **Planes** on better folds, stronger throws, or faster turning. The wallet also opens upgrades. Customize selects a paper color; Explore lists the six regions.

## Current world and references

The project is `G:\Roblox Projects\Roblox Paper Plane`. Reference screenshots are in `references/`, including the new 20:24–20:26 images.

The expanded archipelago has broad grassy slopes, exposed rock patches, sandy shorelines, a lagoon, outlying islands, angular trees and palms, folded paper animals, and three actual passages carved through rock. The previous overlapping-ball grass terrain has been replaced by a continuous height field.

There are 61 rings, six regions, six thermal zones, and 387 procedural trees in the current deterministic build. Water uses adjacent sections so individual part-size limits cannot truncate the ocean. The world contains around 12,000 descendants; mobile performance and production optimization remain unverified.

## Recreate in Studio

1. Run `python tools/GenerateExplorationInstaller.py`.
2. In Studio **Edit mode**, run `tools/InstallStudio.luau` through the command bar or Studio MCP.
3. Enter Play mode to load fresh modules and test.
4. Save a local place file in Studio to retain the complete scene.

Source files do not automatically sync with Studio. Studio place saving or publishing has not been performed by the assistant.

The installer updates the scripts and exploration world. On a fresh place it first creates the plane template using the earlier art builder. It archives existing scenery under `ServerStorage.PaperFlightBackups`, updates Lighting, hides the Baseplate, and relocates the spawn.

Terrain generation is guarded by `PaperArchipelagoV2`. When replacing the previous terrain revision, the builder preserves a `TerrainBeforeV2` snapshot, clears the old authored footprint in bounded chunks, writes the new height field, then carves the tunnels. Terrain generation can take a few minutes. The active generator uses a fixed seed.

The old `GenerateInstaller.py`, `InstallDreamValley.luau`, and `InstallModels.luau` are earlier iterations. Use **GenerateExplorationInstaller.py + InstallStudio.luau** for the current game.

## Source layout

- `src/shared/Config.luau`: speed, boost budget, bounds, wind sound, upgrades.
- `src/shared/Flight.luau`: gliding, stalls, finite boost, steering, swept ring crossing.
- `src/shared/Landscape.luau`: island height field, peaks, and passage coordinates.
- `src/shared/WorldData.luau`: ring trails, regions, and thermals.
- `src/shared/Economy.luau`: prices, level limits, balance validation.
- `src/server/RaceServer.server.luau`: authoritative flights, collision, rewards, input validation, streaming prefetch, and cleanup. Filename retained from the original prototype.
- `src/server/ProfileStore.luau`: Studio session progress and published-server persistence.
- `src/client/FlightClient.client.luau`: mouse camera, throw pose, trajectory, HUD, upgrades, wind, streaks, boost input/meter.
- `tools/BuildExplorationWorld.luau`: terrain, scenery, rings, and paper wildlife.
- `tests/Flight.spec.luau`: 27 flight, boost, ring, and economy assertions.
- `tests/World.spec.luau`: 76 clearance checks against actual terrain and scenery.

## Engineering decisions

The client sends bounded steering axes and a boost-held boolean at 15 Hz, never claimed positions, speed, remaining fuel, or rewards. The server simulates at 60 Hz, validates input types/ranges, limits requests, and clears stale steering and boost requests after 0.5 seconds.

Boost duration and acceleration are computed inside the same deterministic simulation as flight. Consumption is proportional to simulation time and cannot go below zero. The client renders the server's remaining-time value.

Ring rewards use spatial bins and a swept crossing of the ring plane inside its opening. Touching a rim or merely approaching a ring does not pay. Each ring pays once per run. Clearing the session before banking its reward prevents repeated reset requests from paying twice. Rewards combine ring gold with a small distance bonus; upgrades are checked on the server.

A replication focus follows the plane while the avatar stays behind. Bounded, non-blocking streaming requests preload scenery ahead of kinematic flight. Streaming quality still depends on device memory and network conditions.

The client interpolates a visual plane and hides the replicated copy locally. Wind and side streaks vary with speed. Collected rings remain hidden if they stream back in during that run. Wind asset: 687874741.

Published servers use UpdateAsync with session ownership, a renewable lease, retries, periodic saves, and departure/shutdown saves. Failed profile loads do not create replacement empty profiles. **Studio progress is session-only; published persistence has not been end-to-end tested.**

## Validation

Verified on this revision:

- All 27 flight, boost, ring, and economy assertions passed.
- The base plane reached 250 SPS during live keyboard-controlled boost.
- Holding Space emptied the boost supply; the server stopped boosting and the HUD displayed an empty bar and BOOST EMPTY.
- A live flight passed six rings and banked gold.
- All three rock passages were clear along five parallel paths each, including margins 20 studs from the center.
- All 61 ring centers were clear of terrain and scenery.
- Terrain, water, angular trees, colored rings, and the live boost HUD were visually inspected.

Earlier revision checks also verified correct upgrade deductions, rejection of malformed launch values, reset cleanup, no duplicate reset payouts, wind playback, and the avatar remaining at the deck during flight.

Pending: user approval of handling/art, multiplayer tests, phone/tablet/controller testing, high latency/load profiling, and published streaming/audio/persistence verification. Collision currently sweeps the plane center rather than its full wingspan. Interpolation is implemented; client prediction/reconciliation is not.

## Portfolio and Git

The baseline commit is `d3fe27b`. The user approved a snapshot commit of the exploration revision. Future commits require user approval after playtesting.

Keep readable source, reproducible builders, tests, and real development history. Place files are currently ignored by Git. Describe AI assistance accurately and be prepared to explain flight energy, boost budgeting, server validation, ring crossing, reward banking, streaming, and persistence tradeoffs.
