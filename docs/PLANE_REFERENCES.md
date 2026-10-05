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

| Plane | Gold | Launch speed | Air ceiling | Visible model features |
| --- | ---: | ---: | ---: | --- |
| Paper Dart | Free | 165 SPS | 650 studs | Narrow pointed wings and central keel |
| Lockwing | 180 | 172 SPS | 950 studs | Broad wings, nose lock and raised tips |
| Delta | 550 | 180 SPS | 1300 studs | Swept triangular wings and folded trailing edges |
| Sailwing | 1400 | 188 SPS | 1750 studs | Broad wings, winglets and a separate tail |
| Kestrel | 3200 | 198 SPS | 2250 studs | Forewing folds, swept main wings and split tail folds |

Each higher type also has less drag, less sink, and more turning authority. Space boost has a 4.5-second stamina capacity and the shared 250 SPS speed cap. Releasing boost starts recovery after 0.85 seconds of steady flight at 5 degrees upward or lower, at least 76 SPS, and outside a stall. Holding empty boost cannot regenerate it.

Air ceiling means the altitude at which environmental lift fades to zero for that aircraft. Above it, extra drag and sink increase across a 220-stud band and continue increasing up to three bands. Momentum can carry a plane beyond its nominal ceiling; flight position is never clamped to it. It is not a hard flight boundary. Lift fades across the last 220 studs, so momentum and pitch still matter. The strongest raw thermal now supplies 18 studs/second before aircraft efficiency and radial falloff, instead of 52. Starter efficiency is 0.7, giving at most 12.6 studs/second of uplift near the ground.

## Stamina and climbing balance

| Plane | Comfortable climb threshold | Boost restored per glide second | Empty-to-full including delay |
| --- | ---: | ---: | ---: |
| Paper Dart | 12 degrees | 0.60 seconds | 8.35 seconds |
| Lockwing | 16 degrees | 0.65 seconds | 7.77 seconds |
| Delta | 20 degrees | 0.70 seconds | 7.28 seconds |
| Sailwing | 24 degrees | 0.78 seconds | 6.62 seconds |
| Kestrel | 28 degrees | 0.85 seconds | 6.14 seconds |

The climb threshold marks the start of an additional quadratic energy cost. Ordinary climbing below that threshold still spends speed through gravity. Pulling upward also raises stall speed. A stall forces the nose down until speed recovers.

Range is an outcome of glide efficiency and energy management. A controlled unobstructed simulation starting at altitude 350, targeting level flight, with no boost or thermals, traveled roughly 7486 horizontal studs for Dart and 12279 for Kestrel before reaching altitude 20 or the 120-second test limit. These are comparison fixtures; real terrain, world bounds, turns, wind zones, and player input change reachable distance.

The throw camera briefly pulls back and widens, then settles. Boost adds a separate smooth pullback and 84-degree FOV; releasing boost restores 70 degrees independently of remaining speed.

## Implementation and verification

The hangar shows live 3D previews. A purchase checks the server-owned price, deducts gold, records ownership, and equips the type. Equipping an owned plane is free. The server rejects changes during an active flight.

The held model, launched server model, local flight visual, and flight attributes use the equipped type. Profile normalization retains valid ownership and defaults an invalid selection to Paper Dart. Legacy numerical upgrades are retained as existing profile bonuses; the current shop sells aircraft types.

Live Studio QA used a temporary 5000-gold starting profile: buying Delta left 4450, selecting Delta again kept that balance, and the held and server-launched models were Delta. A mid-flight change was rejected. Kestrel was purchased after landing. The temporary balance was removed; normal new profiles start at zero.

Current assertions: 82 flight/stamina/camera/economy/profile/model checks plus 2875 world checks. Live keyboard input verified boost consumption, camera throw/boost/release transitions, and subsequent stamina recovery in server telemetry and the HUD. Published persistence, full summit flights, and device performance remain unverified.
