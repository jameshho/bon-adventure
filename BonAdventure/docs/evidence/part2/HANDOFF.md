# Part 2 completion and Part 3 handoff

October 20, 2026. Targeted world refinements; no building relocation, interior
rewrite, new dependency or new gameplay mechanic.

Current layout note: the [23 October compact redesign](../../guides/ARCHITECTURE_REVIEW_PART1.md#coordinates-roads-and-visual-standards)
supersedes this historical report's building/animal positions. The dated evidence
below remains evidence for the original Part 2 pass, not the new arrangement.

## Completed changes

- **Roads:** hospital, school, airport and police parking approaches use a consistent
  6.8 town-unit asphalt width. Added a direct delivery-pad approach and removed the
  pale supermarket connector occupying that corridor. New junctions terminate in
  the existing loop/access road and parking surfaces; the police approach bends
  into its existing access corridor. Roads retain collision, map and vocabulary
  metadata. The main loop, pedestrian links, building entrances and legitimate
  airport runway endpoints remain in place. Slightly separated taxiway/apron
  elevations remove the visible overlapping-surface stripes.
- **Washington:** retained the landmark position, facing, pedestal, plaque and
  collision ownership. Refined the seated rider's proportions, coat, boots, bent
  limbs, reins, tricorn silhouette, face/hair and horse muzzle, eyes, mane and hooves.
  Bronze and stone materials remain consistent with the stylized town.
- **Snake:** its saved CSG body was missing in the baseline render. A single tapered
  mesh now follows the existing authored curve, with surface color bands instead
  of floating scale disks. Kept the face, forked tongue, wandering and picking area;
  reduced eye prominence and enlarged the displayed model slightly.
- **Animals:** central, species-specific display dimensions cover all 20 ParkZoo
  animals. Tiger height increased from about 0.923 to 1.6 town units; giraffe stays
  3.846, elephant is 2.8 and lion 1.5. Small species remain distinct: mouse 0.22,
  bird 0.28, rabbit 0.5, cat 0.55 and dog 0.8. Turtle/fish use horizontal length
  targets of 0.65/0.5 instead of height. The parent 1.3 scale applies to all of these.
  Habitat X/Z positions are unchanged; ground/perch elevations and wandering origins
  are maintained, with the four meadow pets lowered onto the meadow rather than
  retaining their former raised-lawn offset. The tiger close-up exposed transposed
  cylinder axes in stripes/tail/whiskers/claws; restoring those axes removes spikes.
- **Aesthetics:** coherent asphalt/parking colors, muted lawn materials, cleaner
  statue and animal silhouettes, grounded meadow animals, and cleaner airfield
  surface transitions. Existing vegetation, buildings, lighting and interiors remain.

## Files changed

- `scripts/core/main.gd`: one call after the existing home/garden passes.
- `scripts/world/world_refinements.gd`: new idempotent, focused world pass; reuses
  Main's material cache and the existing landscape ribbon/smoothing helpers.
- `docs/evidence/part2/verify.gd`, `capture.gd`, `validation.txt`, this handoff, and six PNGs:
  `town`, `washington`, `wildlife`, `snake`, `tiger`, `airport`.

Existing scene files, prefab resources, vocabulary data, shaders, project settings
and interiors were not edited. Hash comparison against the Part 1 inventory found
only Main changed among previously existing active files, excluding Finder
`.DS_Store` metadata. The saved snapshots are
preserved; changes are applied when playing the main scene, not by editing those
large scene files or regenerating the world.

## Verification

Godot 4.7.2, headless fixed FPS 60; graphical views use the Compatibility renderer
at 1200×900. Tests use a separate learner-data location. See `validation.txt`.

| Check | Result |
| --- | --- |
| Active scenes/scripts | 305 loaded, zero failures |
| Part 2 regression | 694 checks, zero failures; 279 vehicle-volume road samples; collision surface continuity, scaled-animal physics picking/cards, proportions, habitat preservation and idempotence |
| Interaction | Passed targeting, highlights, cards, signals, doors, dismissal, range |
| BonBon movement | Zero failures |
| Rendering regression | Zero failures; garden batching remains 1,831 meshes in 174 batches |
| Garden walking | Zero failures; 2,004 path samples and bridge crossings in both directions |
| Legacy vehicle suite | 67 checks, 20 failures; failure labels exactly match the Part 1 baseline |
| Visual inspection | Rendered overview, airport, statue, snake, tiger close-up and wildlife proportions inspected; mesh issues found during inspection were corrected and rendered again |

No export package, exhaustive manual drive-through, every-interior playthrough or
new FPS benchmark was performed. Passing the clearance queries does not establish
that the existing vehicle controller has no bugs. The known helicopter rotor-
clearance failure and stale vocabulary metadata from Part 1 remain out of scope;
the rotor-specific suite was not rerun here. Headless runs still emit the host
certificate lookup error.

## Part 3 Handoff

Document `world_refinements.gd` as the final world-content pass before UI creation
and garden batching. Its `world_refinements` metadata guard prevents repeat scaling
or geometry. Do not clear the guard on an already modified live tree to preview a
parameter change: restart the scene. Any bake must serialize the guard and the
created children together; no baker was run in Part 2.

Keep the species dimensions in `ANIMAL_HEIGHTS` / `SMALL_ANIMAL_LENGTHS`, measured
in town-local units, rather than adding per-instance multipliers. Character/mascot
pigs outside ParkZoo are intentionally not rescaled. Retain model-local geometry,
word keys, habitat centers, picking Areas and wandering home positions.

The pass is specific to the current reflected reference town. Drive coordinates
use the baked town's +X-west convention; future changes should continue to use the
existing reference-layout conversions. Road geometry and metadata must agree so
the map, collisions and study interactions remain consistent.

Part 3 should update the main README/current-world editing instructions and index
these checks/views, distinguish runtime refinements from saved snapshot content,
and retain the baseline vehicle/metadata caveats. Do not describe the full test
suite as clean or the saved scene alone as containing the Part 2 changes.

From the project directory:

```sh
godot --headless --path . --fixed-fps 60 --script res://docs/evidence/part2/verify.gd
godot --path . --resolution 1200x900 --script res://docs/evidence/part2/capture.gd
```

Views: [town](town.png), [Washington](washington.png), [snake](snake.png),
[tiger](tiger.png), [wildlife](wildlife.png), [airport](airport.png).


## Town appearance polish — 21 October 2026

The current runtime refinement pass now applies a richer outdoor palette: deeper
roads and greens, warmer pedestrian paving/sand, quieter shoreline stone, and
alternating canopy tones on existing garden trees. Materials are assigned to
specific outdoor meshes; shared prefab materials and global lighting are unchanged.

Six low perennial beds and three accent trees fill open park pockets. Planting uses
the existing landscape oval helper, sphere helper and tree prefab, retaining the
prefab's tree picking Areas. A fixed seed produces repeatable placement. Candidates
stay at least seven town-local units from garden path centerlines and nine from
existing garden tree origins or accepted beds; lagoon, zoo/farm, playground,
monument and gazebo regions are excluded. The beds introduce no solid collision.
They live under `PublicGarden/Town planting`, inside the existing refinement guard
and before runtime batching. No saved world was rebaked.

Current views: [town](town-polish-town.png), [park](town-polish-park.png),
[planting detail](town-polish-planting.png). The older six Part 2 images above retain
their original evidence. New captures also inspected the school/hospital frontage,
home, airport, wildlife and monument; these additional views remain temporary.

The [verification follow-up](../../guides/FINAL_VERIFICATION.md#appearance-follow-up--21-october-2026)
records checks and limits. Editing ownership and restart rules remain in the
[architecture guide](../../guides/ARCHITECTURE_REVIEW_PART1.md#coordinates-roads-and-visual-standards).
