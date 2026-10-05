# Paper Skies

A Roblox paper-plane exploration game: glide through mountain valleys, collect gold, and unlock aircraft with better speed, boost, and handling.

**[Roblox experience](https://www.roblox.com/games/90521540129558)** · **Luau / Roblox Studio / Git**

## Engineering highlights

- **Flight and progression:** momentum-based gliding, climb penalties, stall recovery, rechargeable boost, and five aircraft tiers.
- **Server authority:** validated steering and purchases, server-owned flight and rewards, and swept ring-crossing detection.
- **Scenery optimization:** reduced tree and stone Parts from **77,877 to 5,584 (~93%)**, using reusable faceted solids. This measures instance reduction, not FPS improvement. [Geometry audit](docs/GEOMETRY_AUDIT.md)
- **Replication reliability:** handles late-arriving plane parts and streamed replacements; terrain coverage checks prevent mountain placeholders from covering loaded slopes.

## QA and iteration

Hands-on PC playtesting drove fixes for underground cameras, repeated climb/stall cycles, duplicate planes, and misplaced wildlife. The [bug journal](docs/BUGS_AND_LESSONS.md) records symptoms, investigation, causes, fixes, and verification.

[Automated checks](tests) cover flight, economy, camera clearance, world layout, streaming, and plane visibility. Published-client performance, persistence, multiplayer, and mobile/controller coverage remain pending.

## Development approach

Built with AI assistance for implementation, procedural assets, and tests. My focus was gameplay direction, hands-on playtesting, visual feedback, and iterative refinement.

## Documentation

- [Project guide: gameplay, setup, architecture, and development checkpoints](docs/PROJECT_GUIDE.md)
- [Bugs, fixes, and engineering lessons](docs/BUGS_AND_LESSONS.md)
- [Geometry measurements and optimization limits](docs/GEOMETRY_AUDIT.md)
- [Plane references](docs/PLANE_REFERENCES.md) · [Animal references](docs/ANIMAL_REFERENCES.md) · [Audio](docs/AUDIO.md)
