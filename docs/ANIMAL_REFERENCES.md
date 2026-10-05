# Wildlife references and models

The user supplied six reference screenshots in the older project folder at `C:\Users\A\Documents\ChatGPT\Roblox Paper Plane`. Copies are retained in the active repository:

- [Mammoth side view](../references/PixPin_2026-10-04_22-52-58.png)
- [Mammoth front view](../references/PixPin_2026-10-04_22-53-18.png)
- [Gorilla with mammoth behind it](../references/PixPin_2026-10-04_22-53-48.png)
- [Silver fox, bear, and colorful cat creature](../references/PixPin_2026-10-04_23-03-15.png)
- [Cat creature close-up and raccoon](../references/PixPin_2026-10-04_23-03-26.png)
- [Turtle, bear, and other animals](../references/PixPin_2026-10-04_23-03-35.png)

The screenshots guide style and silhouette. All in-game geometry comes from the original `ReferenceAnimals.luau` module. No models, textures, or meshes were extracted from the reference game. CandyCat is this project's name for an original adaptation of the orange square-headed creature with a cyan body and pink fins.

## Current roster

| Model | Instances | Parts per model | Main visual features |
| --- | ---: | ---: | --- |
| Bear | 2 | 161 | Brown beveled body, block ears, protruding muzzle, broad paws |
| SilverFox | 3 | 416 | Silver body, pointed snout, tall ears, white ruff and raised plume tail |
| Turtle | 2 | 75 | Green limbs and head, stepped brown shell, flippers |
| Raccoon | 3 | 162 | Dark eye mask, compact ears, ringed tail, gray-blue body |
| CandyCat | 3 | 51 | Orange square head, large eyes, whiskers, cyan body and pink fins |
| Gorilla | 2 | 264 | Dark hunched torso, shoulder plates, brow, heavy knuckles and silver saddle |
| Mammoth | 2 | 838 | Layered blue/white coat, segmented trunk, curved cyan tusks and ice crest |

All seventeen old encounter instances have been replaced. The previous shared quadruped builder was removed from the active world builder. Built-in stud surfaces are assigned to suitable broad block faces rather than adding thousands of individual stud Parts.

## Placement and gameplay

Locations and the discovery split remain unchanged: thirteen animals are behind mountains and four occupy introductory fields. The front encounters are a bear, turtle, candy cat, and raccoon. The models use a 0.62 authored scale and retain complete 24-stud belly rings facing sideways.

The body and leg proportions provide clearance for the required full rings. All animals remain static exploration landmarks; animation is not implemented.

## Verification

Close views were inspected for each of the five new types; the gorilla and mammoth had already been inspected from three-quarter and side views. A floating/occluded fox-eye iteration was corrected with a forward face panel. Raccoon ears were shortened to distinguish them from the fox.

All 2875 geometry/layout assertions passed, including visible ring-rim clearance samples, plane-width belly passages, sideways reward crossings, eight launch directions, and a check that every encounter uses the new roster and model builder.

The rebuilt world has 22,152 descendants. Device performance and live keyboard-flown collection beneath the new roster remain unverified. These models are original adaptations of the reference style, not exact replicas.
