# Paper / Flight — Coastal Run

A Roblox flight time-trial prototype built with AI assistance for an engineering portfolio.

## Play

Press Play in the open Paper Plane Studio project.
Space launches; A/D steer; W/S climb or dive; R resets.
Pass all six rings in order. Gold marks the next ring. Missing a ring ends the attempt.
The timer begins after a two-second countdown. Personal bests last only for the current server session.
Gamepad: left stick steers/climbs, A launches, B resets.
Touch: launch/reset buttons and four directional buttons are implemented; actual device testing is pending.

## Source layout

- src/shared/Config.luau: course positions and tunable flight parameters.
- src/shared/Flight.luau: deterministic kinematic flight and swept checkpoint intersection.
- src/server/RaceServer.server.luau: sessions, fixed-step simulation, collision, checkpoint validation, timing, and cleanup.
- src/client/FlightClient.client.luau: controls, interpolated local visual, camera, and HUD.
- tools/BuildWorld.luau: deterministic scenery and plane-template builder.
- tools/InstallStudio.luau: self-contained installer generated from these sources.
- tests/Flight.spec.luau: seven assertions for flight and swept checkpoint math.

## Recreate in Studio

Paste tools/InstallStudio.luau into Studio's command bar in Edit mode.
The installer updates PaperFlight scripts and recreates PaperFlightWorld and the plane template.
It also changes Lighting, hides the default Baseplate, and relocates the default SpawnLocation.
Save the place in Studio after installation. Source files in this folder do not automatically sync with Studio.
After editing source files, update the corresponding Studio script and regenerate the installer before sharing a release.
Studio place saving/publishing has not been performed by the assistant.

## Architecture and tradeoffs

The client sends bounded steering axes at 15 Hz, never a claimed position, checkpoint, or finish time.
The server simulates each flight at a fixed 60 Hz and checks collisions along the movement segment.
Ordered checkpoint crossings are measured against the ring plane and aperture, catching crossings between updates.
Malformed inputs are rejected; incoming input is limited to 30 Hz per player; stale input clears after 0.5 seconds.
The server owns the anchored plane and hidden character position. Clients smooth the owner's visual and camera.
Launch/reset, character removal, and player departure clean up active sessions.
Other players can fly concurrently, but competitive lobbies and synchronized starts are not implemented.

This is arcade kinematics, rather than aerodynamic rigid-body simulation.
Server authority simplifies validation, at the cost of input latency. There is no client prediction/reconciliation.
Simulation catch-up is capped at 0.25 seconds per Heartbeat. Under sustained server overload, displayed race time
measures simulated time rather than exact wall time; this needs revisiting before competitive release.
Bests are session-only. There are no rewards, purchases, persistent saving, analytics, or backend services.
World-only raycasts prevent hidden player avatars from obstructing other pilots.
The landscape uses primitive Parts; the ocean is a visual Part rather than swimming terrain water.

## Validation performed in Studio

- Seven math assertions passed: swept crossing, radius rejection, backward/stationary rejection,
  consistency across timestep sizes, pitch clamp, and forward movement.
- An automated pilot completed all six rings through the live RemoteEvent/server loop: 15.18 seconds.
- A straight flight cleared ring one and correctly failed at ring two.
- NaN, infinity, wrong-type steering, and a forged Finished action did not terminate or complete the flight.
- Reset removed the active plane, restored the character, and unanchored its root.
- A temporary runtime obstacle triggered collision failure and plane cleanup.
- A full flight after interpolation changes cleaned up both replicated and local plane models.
- Final gameplay run had no script errors in Studio Output.
- HUD and course visually inspected through Studio screenshots.

Pending: two-client playtest, real mobile/controller testing, high-latency testing, load/performance profiling,
character death during flight, and streaming behavior on a published server. No production-readiness claim.

## Engineering discussion

Be prepared to explain why the server owns movement and race progress, how swept crossing works,
how fixed timesteps affect consistency, and the latency/scale tradeoff of server-authoritative flight.
Review the source yourself, experiment with Config, and describe AI assistance accurately in an application.

## Version control

The workspace already contains a Git repository. Keep the readable source, builder, tests, and documentation in Git.
Save a local .rbxl separately as a playable snapshot. GitHub is optional for local history and useful for sharing.
Do not commit credentials or manufacture a history of development. Record actual changes and decisions.

