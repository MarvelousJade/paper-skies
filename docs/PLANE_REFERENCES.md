# Plane references and balance

Five original procedural paper-plane models were built using online folding photographs and diagrams as silhouette references. No reference images were supplied from the project folder, and no external models or image textures were imported.

## Online image references

- [Fold N Fly Basic Dart design](https://www.foldnfly.com/1.html) — narrow pointed nose and long triangular wings.
- [Fold N Fly Lock Bottom photograph](https://www.foldnfly.com/data/29/final.jpg) and [folding page](https://www.foldnfly.com/29.html) — broad wings, a locking nose fold, and raised wingtips.
- [AFRL paper airplane gallery](https://afresearchlab.com/paper-airplanes/) — additional dart, glider, and sailplane design references.
- [AFRL sailplane diagram](https://afresearchlab.com/wp-content/uploads/2020/07/Sailplane-Paper-Airplane_template_sml-791x1024.jpg) — broad wings and a distinct tail.
- [AFRL glider diagram](https://afresearchlab.com/wp-content/uploads/2020/07/Belly-Button-Paper-Airplane_Design-MB-791x1024.jpg) — additional folded glider proportions.

The Delta and Kestrel combine general swept-wing and folded-canard ideas into original game silhouettes. Their names, prices, and performance rankings are game design choices; they do not rank the real reference designs.

## Current aircraft

| Plane | Gold | Launch speed | Top speed | Air ceiling | Visible model features |
| --- | ---: | ---: | ---: | ---: | --- |
| Paper Dart | Free | 90 SPS | 160 SPS | 650 studs | Narrow pointed wings and central keel |
| Lockwing | 180 | 105 SPS | 190 SPS | 950 studs | Broad wings, nose lock and raised tips |
| Delta | 550 | 120 SPS | 220 SPS | 1300 studs | Swept triangular wings and folded trailing edges |
| Sailwing | 1400 | 135 SPS | 250 SPS | 1750 studs | Broad wings, winglets and a separate tail |
| Kestrel | 3200 | 150 SPS | 280 SPS | 2250 studs | Forewing folds, swept main wings and split tail folds |

Each higher type also has less drag, less sink, and more turning authority. Space boost has a 4.5-second stamina capacity. Each type has its own server-enforced speed cap, including during boost and dives. Releasing boost starts recovery after 0.35 seconds, regardless of pitch, speed, or stall state. Holding empty boost cannot regenerate it.

Air ceiling means the altitude at which environmental lift fades to zero for that aircraft. Above it, extra drag and sink increase across a 220-stud band and continue increasing up to three bands. Momentum can carry a plane beyond its nominal ceiling; flight position is never clamped to it. It is not a hard flight boundary. Lift fades across the last 220 studs, so momentum and pitch still matter. The strongest raw thermal now supplies 18 studs/second before aircraft efficiency and radial falloff, instead of 52. Starter efficiency is 0.7, giving at most 12.6 studs/second of uplift near the ground.

## Stamina and climbing balance

| Plane | Comfortable climb threshold | Boost restored per recovery second | Empty-to-full including delay |
| --- | ---: | ---: | ---: |
| Paper Dart | 12 degrees | 0.90 seconds | 5.35 seconds |
| Lockwing | 16 degrees | 0.98 seconds | 4.94 seconds |
| Delta | 20 degrees | 1.05 seconds | 4.64 seconds |
| Sailwing | 24 degrees | 1.12 seconds | 4.37 seconds |
| Kestrel | 28 degrees | 1.20 seconds | 4.10 seconds |

The climb threshold marks the start of an additional quadratic energy cost. Ordinary climbing below that threshold still spends speed through gravity. Pulling upward also raises stall speed. A stall forces the nose down until speed recovers.

Range is an outcome of glide efficiency and energy management. An earlier tuning revision's controlled unobstructed simulation starting at altitude 350, targeting level flight, with no boost or thermals, traveled roughly 7486 horizontal studs for Dart and 12279 for Kestrel before reaching altitude 20 or the 120-second test limit. Those historical figures are not measurements of the current tuning; real terrain, world bounds, turns, wind zones, and player input change reachable distance.

The throw camera briefly pulls back and widens, then settles. Boost adds a separate smooth pullback and 77-degree FOV; releasing boost restores 70 degrees independently of remaining speed.

## Implementation and verification

The hangar shows live 3D previews. A purchase checks the server-owned price, deducts gold, records ownership, and equips the type. Equipping an owned plane is free. The server rejects changes during an active flight.

The held model, launched server model, local flight visual, and flight attributes use the equipped type. Profile normalization retains valid ownership and defaults an invalid selection to Paper Dart. Legacy numerical upgrades are retained as existing profile bonuses; the current shop sells aircraft types.

Live Studio QA used a temporary 5000-gold starting profile: buying Delta left 4450, selecting Delta again kept that balance, and the held and server-launched models were Delta. A mid-flight change was rejected. Kestrel was purchased after landing. The temporary balance was removed; normal new profiles start at zero.

Current checks: 1779 flight/stamina/camera/economy/profile/model assertions and 6476 launch/camera assertions. The unchanged scenery previously passed 148611 layout assertions. Live keyboard input verified boost consumption, camera throw/boost/release transitions, and subsequent stamina recovery in server telemetry and the HUD. Published persistence, full summit flights, and device performance remain unverified.
