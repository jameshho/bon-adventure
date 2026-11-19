# Reference floor-plan home

Design source: [original user-supplied interior reference](design-references/home-interior-reference.png).
Use this image for future interior changes, especially the living-room arrangement.
The [current rendered preview](../evidence/town-checks/home-living-space.png) shows the implementation and
is separate from the original design reference.

The home is rebuilt by `scripts/world/reference_home.gd`, called after the existing town layout is loaded. It replaces the old home geometry and furnishings while retaining the home site node and updating its minimap reference. The existing town snapshot remains the base scene; the redesign appears when running the game.

Layout: three west bedrooms, a northwest guest bathroom, west family bathroom, broad central lounge, northeast dining area, east kitchen, front family lounge, southeast double garage, and rear pool terrace. The former extra east bedroom and ensuite have been opened into the shared interior. Finishes include oak flooring/cabinetry, ivory walls, blue/teal upholstery, pale stone counters, full-height pool-facing glazing, bed linens, lamps, patio chairs, and pool loungers.

Eight hinged doors use the existing interaction system, with collision attached to each moving leaf. The two former suite doors were removed with those partitions; all other doorway positions are retained. Storage is static. The pool is a sunken, walkable basin (28 October 2026): 0.95 deep at the east steps, sloping to 1.75 at the west ladder, with translucent water; swimming mechanics are not implemented, and the player walks the floor and climbs out by the steps. See the [design brief](TOWN_DESIGN_BRIEF.md#home-pool-depth-and-raised-sidewalks--28-october-2026). Since the 28 October word clean-up the kitchen teaches oven, faucet, frying pan, cup, salt, pepper, oil, tea and juice (cabinet handles belong to the cabinetry), each bathroom teaches towel, toothbrush, toilet paper, shampoo and perfume (since 8 Nov 2026 each bathroom also has a working toilet and a brass faucet on a vessel basin, and the kitchen faucet works: E; [record](TOWN_DESIGN_BRIEF.md#bathroom-fixtures--8-november-2026)), and room plaques name the bedrooms, bathrooms, living room, kitchen and garage, with post signs for the yard and garden. The garage vehicle entrance was an open bay until 29 October 2026; it now has a sectional overhead door (see [below](#ceiling-roof-seating-and-garage-doors--29-october-2026-user-request)).

Validation: `docs/evidence/town-checks/check_reference_home.gd` loads the actual main scene, checks 13 positions across each door's swing against physics bodies, and verifies all eight doors animate fully open and closed. It also samples player-width routes through the shared interior and checks the revised room labels. Run with `--capture` using graphical Godot to regenerate `docs/evidence/town-checks/reference-home.png`.

## Interior reference update — 21 October 2026

Historical first attempt, superseded by the living-space correction below after
user feedback that it did not follow the supplied image closely enough.

The new supplied image is adapted to the existing footprint and room connections:
warm oak floors, near-white walls and linen sofas, blue accent cushions and stools,
yellow/blue/teal bed covers, a rectangular six-seat dining table, indoor planting,
and a second L-shaped sitting area near the front entrance. The original primary
suite, bathrooms, ten door positions, pool terrace and two-car garage are retained;
this is an interior adaptation, not an exact reconstruction of the image's shell.

The kitchen island is 1.4 × 4.2 home-local units, with a 1.65 × 4.4 stone top and
three stools. The dining top is 2.2 × 2.9. Apartment's existing 1.3 scale still
applies. `linen_sofa()` instances the existing sofa prefab and overrides only its
local materials, preserving its study targets and collision. No shared prefab,
word key, room classification, save setting or world snapshot was edited.

Restart Main to rebuild the guarded home. Current validation evidence is recorded
in [Final verification](FINAL_VERIFICATION.md#home-interior-follow-up--21-october-2026).

## Living-space correction — 21 October 2026

The reference's open shared room now drives the interior layout. Removing the old
east suite partitions expands the shared space across x=-5..16, z=-3..14 in
home-local coordinates. The main conversation area uses a 7.2 × 8.2 neutral rug,
a 5.32-unit cream sofa with blue cushions, two facing blue armchairs, an oval oak
coffee table and a slim console behind the sofa. The rectangular dining group
moves alongside it, centered at (11, 1.5). Full-height framed glass faces the pool,
with the existing terrace door retained.

The kitchen is on the east perimeter, with a straight counter run, oven, fridge,
sink island and four blue stools. Its island is 1.4 × 4.8, topped by a 1.65 × 5
stone slab, centered at (11.6, 7.2). The front L-shaped family lounge remains
connected to the main living area. Table plants are now scaled as small accents.
Main's room labels follow this layout; the extra wardrobe moves into the yellow
bedroom. The three-bedroom wing, two remaining bathrooms, garage, vehicle placement,
site footprint, vocabulary keys, and save identity are preserved.

The existing sofa prefab is reused with instance-only materials and length scale;
new armchairs group their geometry under their selectable chair root. All dimensions
above are before Apartment's 1.3 scale. Restart Main to see the changes.

## Roof and driver placement — 21 October 2026

At the user's request, `reference_home.gd::roof()` adds a terracotta hip roof,
ivory fascia, raised tile courses and ridge caps. Main eaves span x=-11.6..16.6,
z=-3.6..17.6 at y=3.45, with ridge y=6.6. Lower garage and bathroom wings leave
the pool terrace open. This decorative roof has no landing collision. Main's
quarter-second update hides it while the player is within the home/garage bounds
below the ridge and restores it outside. This supersedes earlier open-top guidance.

`world_refinements.gd::taxi_driver()` moves one existing garage driver beside the
taxi, 3.2 town units along +X, and removes the garage duplicate. It leaves other
driver instances outside the garage alone. Both garage cars remain in place.
`check_reference_home.gd` additionally checks roof visibility inside/outside,
zero garage drivers and exactly one driver near the taxi.

Garage car swap (29 October 2026): the west garage car (home-local x=8.5, instanced by `reference_home.gd`) is now `scenes/props/vehicles/subaru_outback.tscn`, a dark-blue Subaru Outback-style wagon (black cladding/arches/rails, silver skid plate and 10-spoke alloys, generic hex grille and badge). It reuses `driveable_vehicle.gd`, `word_key="car"`, the `Tire*` "wheel" words and `StudyArea` box shapes of `car.tscn`, front along -X, ~4.0 long. The east car, the world `Vehicles/Car`, is unchanged. Verified by standalone and in-game renders and a driveable-contract load; parked in the garage a driven step barely moves (as the old car), so open-road driving was not exercised.

**28 October 2026:** at the user's request the curved walk that ran from the road past
the garage, through the backyard to the south pier ("Home town walk" and "South beach
access" in `world_refinements.gd::compact_town`) was removed; the lawn shows through.
The house's straight entry path to the sidewalk is unchanged.

## Living room and seating — 29 October 2026

The entry L-group (two sofas, family TV, side tables, plants) was removed. The home now has
**one sofa and one TV**: the main group (west-wall TV, long sofa, two blue armchairs
angled to the TV, oval coffee table). Terrace topiary planters moved against the glazing
(model z -3.75) so the two patio armchairs (x ±1.55 about the round table) are clear.

Nine NPCs (`data/house_characters.json`; `facing` may now be `[x, z]` for an angled
seat): Leo and Bruno on the sofa and Miso on an armchair face the TV; BonBon, Sunny and
Awoo sit at the dining table; Poppy and Twinkle sit on the patio armchairs angled to the
table and pool; Cocodrilo stays in the pool. Rendered views checked, no floating or clipping seen.

**Renamed 9 Nov 2026 (user):** the dining-table samoyed (id `awoo`) is now called **Sam**. The
name Awoo went to the samoyed at the mahjong table ([MAHJONG.md](MAHJONG.md)). Only `name` changed,
so saves and outfit choices keyed by the id are unaffected. Older notes in this guide still say
Awoo.

## Ceiling, roof, entrance door and Subi — 29 October 2026 (user request)

- Walls, window lintels, terrace glazing, door-head fillers and ceiling lights were raised by `LIFT = .8` in `reference_home.gd` (ceiling 3.2 to 4.0); the hip roof sits 0.8 higher (ridge 7.4). A wall filler now closes the space above every interior door.
- The roof used to vanish for anyone inside a loose box that included the pool terrace and lawn. `Main._process` now hides it only while the player is within the three roof rectangles (main hall, garage wing, west wing) and below y 7.6. *Updated:* since 7 Nov the limit is home-local y 3.9 (the roof is solid), and since 10 Nov 2026 the rectangles are the wall lines, not the roof outline: the 0.6 m eaves made the roof vanish for anyone standing outside beside a wall (front door, pool glazing, garage door). Code: `vehicle_controls.gd::update_home()`.
- The **Front door** now swings inward (angle +PI/2 like the bathroom doors).
- The garage wagon carries `character_name` "Subi" (species "Subaru Outback") on its root, so clicking the body shows the name card instead of the "car" word; wheels still teach "wheel". *Correction 29 Oct:* E did not drive it, because Main only registered `Vehicles/` children. It is now registered through the `driveable_vehicles` group, and E plays the driver-door boarding sequence. Open the garage door to drive out ([road vehicle guide](ZOO_VEHICLE_IMPLEMENTATION.md)).

## Ceiling, roof, seating and garage doors — 29 October 2026 (user request)

- **Ceiling.** `reference_home.gd::ceiling()` adds a "Home ceiling" node (outside "Home roof", so it stays when the roof hides) of flat, down-facing panels at `WALL_TOP` (4.0) over the three `ROOF_WINGS` rectangles. They double as the eave soffits seen from outside. They cast no shadows, so sun patches still fall on the floor through the glazing.
- **Roof gap.** `roof()` builds every wing from `ROOF_WINGS` with its eave at `WALL_TOP`; the main eave used to float 0.25 above the walls and the wings sat 0.05 above them.
- **Sofa.** `linen_sofa(...,PI/2,...)`: cushions face the west-wall TV, backrest toward the sofa console.
- **Seated pose.** `house_characters.gd` gives every `"pose": "sit"` plush one shared pose: paws swung forward with soles out, slight recline, seated 0.07 into the cushion. An optional `"back": [x, z]` (Apartment-local point on the backrest face) slides the sitter until its back touches the backrest, and hides the tail. Placement uses mesh vertices, not bounding boxes.
- **Dining chairs.** Side chairs moved out to ±1.85 (backs ±2.16) and the south end chair to −2.6, so seated plushes clear the tabletop. The north end chair stays at +1.95 to keep the dining–kitchen walkway (route z 4.25). Awoo now sits on the south end chair facing north.
- **Garage access door.** Hinged at z 16.78 beside the front wall and opens into the living room (angle PI/2−.08, so the lever clears the wall).
- **Garage door.** `scripts/world/garage_door.gd` ("Garage door" under the home) is a five-section door on side tracks with a bend of radius 0.4 and an opener rail. Piers and a header narrow the bay to an 8-unit opening. The door starts closed. E (or a click / tap) toggles it when the player aims at it, or stands within 0.6 of its sides and 2.4 of its plane, outside or inside with no car nearby (since 12 Nov 2026 an [interactable](ARCHITECTURE_REVIEW_PART1.md#interaction-system) with the "E" badge; the one-time "press E" prompt and hover hint were removed). An opening/closing toast stays. A press mid-travel reverses the motion smoothly. A closing door that meets a character or rigid body reopens and shows "doorway occupied". When open, every section lies horizontally under the ceiling (lowest centre 3.35) and the doorway is clear. It is independent of the hinge-door registry, so the access door is unaffected. Its sections are solid, so a closed door also stops cars; driving out through the open door was not tested.


## Plush costume fit analysis — 31 October 2026 (planning only, nothing built)

**Status:** measurements and planning from the morning of 31 October. The approach was then approved and built: see [Plush outfits](#plush-outfits--31-october-2026-user-request) below, which supersedes the "proposed approach" paragraph. The measurement table remains current.

**Space.** Plush model space: origin on the floor under the body centre, +Y up, face toward −Z, +X is the character's right. House plushes are unscaled children of Main, so 1 model unit = 1 world unit. Only their *positions* go through `apartment.to_global` (Apartment scale 1.3). House BonBon is `pig_plush.tscn` (`pig_art_variants.gd`, `plush = true`, profile depth ×1.28), not the player model.

**Sources.** *Code*: constants in each `*_sculpt.gd` (body_top, eye/cheek/muzzle centres, arm height/size, tail control points, fur amplitudes). *Computed*: the sculpt's own `_section(y)` and `_mitten_tip()`. *Measured*: vertex extents of each built scene, read by a throwaway headless script that did not load Main or touch saves. *Estimated*: the collar height (chin line = cheek bottom; Cocodrilo's chin groove; Leo's mane bottom). All values are standing, before the seated pose.

| Plush | body_top (code) / overall top (measured) | Head half-width × half-depth at eye line (eye y, code) | Ears or crown parts (measured, right side) | Collar y (est.) and body half-width there | Widest belly y: half-width × half-depth | Shoulder → hand tip, right (computed) | Tail root (code) | Coat over the profile (measured) | StudyShape top |
|---|---|---|---|---|---|---|---|---|---|
| BonBon (pig) | 2.203 / 2.240 | 0.663 × 0.563 (1.710) | Flop-out pads x 0.42–0.86, y 1.88–2.24 | 1.36 (no waist): 0.690 | 0.85: 0.759 × 0.614 | (0.70, 0.92) → (0.935, 0.854) | (0.10, 0.62, back) | none | 2.41 |
| Leo (lion) | 2.06 / 2.351 (mane) | 0.680 × 0.510 (1.60) | Round, x 0.275–0.605, y 1.81–2.14, in front of the mane | Waist 1.14 (0.578) is hidden; the mane front reaches y 0.754, z −0.69 | 0.68: 0.714 × 0.643 | (0.55, 1.04) → (0.78, 0.81) | (−0.30, 0.42, 0.50) | Separate mane, half-width 0.886 | 2.40 |
| Bruno (bear) | 2.18 / 2.240 | 0.646 × 0.545 (1.667) | Round, x 0.325–0.745, y 1.82–2.24 | 1.37 (no waist): 0.674 | 0.81: 0.735 × 0.630 | (0.633, 1.18) → (0.889, 0.924) | none | none | 2.30 |
| Miso (cat) | 2.14 / 2.243 | 0.704 × 0.573 (1.656) | Pointed, x 0.342–0.621, y 1.94–2.24; whiskers to x 0.927, y 1.49–1.60 | Waist 1.16: 0.582 | 0.71: 0.687 × 0.587 | (0.538, 1.08) → (0.768, 0.85) | (0, 0.40, 0.42) | none | 2.35 |
| Awoo (samoyed) | 2.065 / 2.276 | 0.766 × 0.653 (1.71); profile 0.703 | Pointed, x 0.288–0.568, y 1.95–2.28 | Waist ≈1.33: profile 0.710, fur 0.790; the ruff edge hangs to 1.04–1.14 | 0.82: 0.810 × 0.711 | (0.656, 1.22) → (0.913, 0.964) | (0, 0.62, 0.70) | Fur 0.08 code; +0.06 to +0.17 measured above y ≈ 1.1 | 2.325 |
| Poppy (sheep) | 2.18 / 2.340 (wool cap) | 0.726 × 0.658 (1.56); profile 0.633 | Floppy, sideways, x 0.588–0.972, y 1.63–1.89 | 1.31 (no waist): wool 0.736 | 0.82: wool 0.754 × 0.718 (profile 0.680) | (0.606, 1.04) → (0.801, 0.846) | none | Wool 0.11 code (×1.5 crown); +0.07 to +0.21 measured | 2.35 |
| Sunny (golden) | 2.22 / 2.220 | 0.603 × 0.533 (1.80) | Floppy, feathered, x 0.34–0.923, y **1.313**–2.138 | Waist 1.40 (0.610) is inside the ear span; must drop to ≈1.25 | 0.75: 0.731 × 0.620 | (0.56, 1.20) → (0.803, 0.957) | Fan from (0, 0.42, 0.40) | Bib/flanks 0.05 code; +0.03 measured | 2.35 |
| Twinkle (beagle) | 2.23 / 2.230 | 0.539 × 0.472 (1.78) | Long, floppy, x 0.352–0.867, y **1.293**–2.131 | Waist 1.26: 0.520 (ear bottoms at 1.293) | 0.70: 0.635 × 0.564 | (0.486, 1.16) → (0.715, 0.93) | (0, 0.45, 0.46) | none | 2.35 |
| Cocodrilo (croc) | 2.12 / 2.212 (spikes) | 0.607 × 0.507 (1.80) | No ears. Crown spikes x ±0.344, y 1.99–2.21. Snout pad x ±0.37, y 1.52–1.77, front z −0.662; teeth to y 1.46 | Chin groove ≈1.25 (code); waist 1.19: 0.635 | 0.77: 0.660 × 0.560 | (0.575, 1.16) → (0.832, 0.904) | (0, 0.42, 0.34), radius 0.27, to z 1.33 | Back ridge plates to z 0.584 | 2.30 |

**Findings.**
- Spread: body_top 2.06–2.23; belly half-width 0.635–0.810 (×1.28); head half-width at the eyes 0.539–0.766 (×1.42); shoulders 0.92–1.22; inner ear gap at the crown 0.275–0.588.
- **Resizing is not recommended.** One parametric fit absorbs these differences. Rescaling would undo the tuned dining-table clearances and sofa spacing, and the "sized beside BonBon" comparison.
- **Poses.** `house_characters.gd` turns the root (`Basis.looking_at(facing)`, plus a 0.12 rad recline when seated). `_sit()` moves only the `Foot`/`Foot_2` transforms. Arms, head parts and the root scale stay unchanged, and tails are hidden on all eight seated plushes, since each has `back`. So pieces under the root follow every pose; footwear must go under the `Foot` nodes.
- **Placement reads meshes.** `_sit()` reads `Torso` meshes. `_extent()` reads every visible non-`Tail` mesh to set seat sink and backrest contact. Costume meshes must not go under `Torso` and must be excluded from `_extent()`; otherwise a back piece would push a sitter forward.
- **Picking and rendering.** Picking reaches the root's `character_name` through `StudyArea` and the ancestor walk, and hover highlighting recurses into all child meshes. Hats above the StudyShape top are not clickable unless they get their own Area3D. `render_culling.gd` only trims under `apartment`, so it does not touch HouseCharacters.
- **Cocodrilo (inferred).** Standing at Apartment-local y −0.96 with the water line at y −0.1, the lower ≈0.9 of his body is probably under translucent water.

**Proposed approach (unapproved).** Pieces are built from the plush helpers, fitted to each character's measured Torso band radii (which already include fur and wool), with a small per-species data entry for semantic anchors and keep-outs: crown, eye line, collar y, chest, hand, tail root, ear mode and parts to hide. Pieces live under a `Costume` node and are applied after placement. Authored defaults would sit in `house_characters.json`; player choices in a separate `user://` file, never in the progress or quest saves. Prototype on Twinkle and Awoo (the narrowest and widest), then Leo and Cocodrilo. Seated views are not produced by `docs/evidence/town-checks/capture_character.gd`, which renders a fresh standing instance beside BonBon. Any capture must run from an isolated project copy ([Verification](../../README.md#verification)), because loading Main can rewrite the progress file when it normalizes keys.

## Plush outfits — 31 October 2026 (user request)

Ten outfits that any of the nine plushes can wear, with no plush resized or re-sculpted. The driver, teacher, gardener, pilot and businessman were added the same day from the user's reference sheet, simplified to the plush style; the chef was added after them:

| Outfit | Pieces |
|---|---|
| `shopkeeper` | White short-sleeve shirt with collar under a wide green bib apron (straps, waist ties, front pocket with a pen); name tag on the bib. For any store, as shopkeeper or cashier. |
| `police` | Navy short-sleeve uniform shirt (collar, silver buttons, flapped chest pockets); gold star badge; black belt with buckle; peaked cap with a gold cap badge. |
| `doctor` | Long white coat (V neck, placket, buttons, hip pockets and a large chest pocket with a blue and a red pen) over light-blue scrubs; thick stethoscope draped round the neck, with a large round chest piece on the character's right and the steel ear tubes on the left; name tag. |
| `waiter` | Black long-sleeve shirt (collar, buttons, chest pocket) with a notepad and pencil in the pocket. Works for fast food and table service. |
| `driver` | Light-blue short-sleeve shirt with collar; navy tie; navy sleeveless V-neck vest with silver buttons and hip pockets; name tag; navy peaked cap with a gold cord and a small white bus emblem. |
| `teacher` | White shirt with collar; red tie; tan sweater vest; open brown blazer with lapels, long sleeves, one button and hip pockets. No glasses (user decision). |
| `gardener` | Farmer, gardener or zookeeper: white short-sleeve shirt with collar; green overalls (trousers all round, bib with pocket, straps, two yellow buttons); woven straw hat (crown, wide drooping brim, darker straw rings, brown band). The ears poke up through the brim (user decision). |
| `pilot` | White shirt with collar; navy tie; navy double-breasted jacket with lapels, two rows of gold buttons and two gold cuff stripes; gold wings on the chest; navy peaked cap with a gold cord and gold wings. |
| `businessman` | White shirt with collar; blue tie; charcoal suit jacket with lapels, two buttons and flapped hip pockets; white pocket square. |
| `chef` | Black double-breasted chef coat with a rolled stand collar, long sleeves and two rows of light grey buttons; tall black pleated toque with a puffy top that narrows to the room the ears leave. |

- **Wearing one.** Add `"costume": "<outfit>"` to a character in `data/house_characters.json`. `house_characters.gd` dresses it after placement, so seating, the backrest slide and the seat sink are unchanged; `_extent()` also skips `Costume`. **No Home plush wears an outfit yet**: the user has not chosen who wears what.
- **Ownership.** `scripts/characters/plush_costume.gd` (extends `plush_sculpt.gd` for its shapes and plush shading) builds a `Costume` node under the plush root. `data/plush_costumes.json` holds the per-species anchors (`collar_y`, `shoulder`, `hand`, optional `hide`, `tuck`, `press` and `hat_sink`) and the outfits as ordered piece lists with colors. Add a piece type by adding a `_<piece>()` function. Costumes (and sculpts) are cached between launches by `scripts/characters/sculpt_cache.gd`; a costume reading anything besides its wearer, its data and its own variables must not be cached (see that file). Pieces: `shirt` (also vests, jackets and coats through `layer`, `v`/`dip`, `sleeve`, `lapels`, `buttons` with `button_columns`/`button_count`, sized `pockets`, `cuff_stripes`), `apron`, `overalls`, `tie`, `belt`, `badge`, `wings`, `name_tag`, `pen`, `notepad`, `pocket_square`, `stethoscope`, `cap` (`cord`, `emblem` oval/bus/wings), `straw_hat` and `chef_hat`. `shirt` also takes `stand_collar`.
- **Fit.** Garments follow each plush's own measured `Torso` mesh in 0.01 height bands and 48 directions, with the farthest reach smoothed, so fur, wool, the croc's ridge and the golden's bib stay inside. Sleeves are fitted to each arm mesh between the `shoulder` and `hand` anchors. The cap sits on the measured crown and narrows to the room the ears leave. On Leo and Poppy it sinks into the hair (`hat_sink`), and `_press()` flattens that wearer's mane or wool copy so nothing rises past the band's lower edge under the cap and the hair slopes gently down beside it (user request: hair was showing between the band and crown). Under the straw hat the hair follows the brim's underside instead, and the ears poke up through the brim; only the crown must clear them.
- **Hidden and tucked parts.** With the cap on, Cocodrilo's crown spikes are hidden (approved). With a shirt on, Leo's mane is tucked into the collar (`tuck`, user request): `_tuck()` pulls that wearer's own mane mesh copy inside the body below `collar_y` and eases back to full size just above, so the mane frames the face and the badge, pockets and stethoscope show. Seated plushes already hide their tails. Standing plushes keep their tails, which pass through the clothing like a tail hole.
- **Interaction.** Pieces have no collision. A click still resolves to the plush root and shows the name card, never counting as study. Hover highlighting covers the pieces. Worn pieces do not teach words (user decision).
- **Character ids.** Every entry in `house_characters.json` has a permanent `id` (lowercase, unique). It is the node name under `HouseCharacters` and the `character_id` metadata; `name` is only display text. So several characters may share a scene, species or even a name, and a future save of outfit choices or quest state should key on `id`. Never change or reuse an id once a save refers to it. A missing, invalid or duplicate id is reported with `push_error` and that entry is skipped.
- **Not built (user decision):** player-chosen costumes, saving them, and any UI.
- **Known limitations, accepted for now:**
  - Cocodrilo's lower body is under the pool water, so most of a garment there is underwater (confirmed in-game).
  - White coats on the white Awoo and Poppy have low contrast.
- **Checks:**
  - `docs/evidence/town-checks/check_plush_costumes.gd` loads Main, so run it in an isolated copy. It covers garments outside the raw body for every outfit and species, caps and toques clearing the ears (against the hat's width at each height), Leo's mane tucked under the shirt, Leo's and Poppy's hair pressed under the hats, unique character ids as node names, no collision, unchanged placement and extents, name-card picking, no study counted, and highlighting.
  - `docs/evidence/town-checks/capture_costumes.gd -- [outfit ...] [stand] <dir>` renders 3 × 3 contact sheets (front, three-quarter, back) of all nine on its own stage, without loading Main or touching saves.
  - Results are in the [verification record](FINAL_VERIFICATION.md#plush-outfits--31-october-2026).

## Mahjong table — 9 November 2026 (user request)

The front yard has a mahjong table with four chairs (home step `mahjong_table`, `MAHJONG_*`
constants in `scripts/buildings/home.gd`), west of the entry path. Four plush players sit there
at runtime and Mei offers a game of Hong Kong mahjong: [Mahjong guide](MAHJONG.md).

## Family bathroom re-laid — 13 November 2026

User report after playing the welcome tutorial: the bathroom toilet should face naturally (back
to a wall, front to the room or doorway, clear of the door swing) and the toilet room should
look right; curtains should face the doorway. The family bathroom (inside x -10.91..-5.09,
z 3.09..10.91; door on the east wall at z 8.64..10.36, swinging into the room) is the tutorial's
bathroom. Its tub lay along the north wall, so from the doorway its shower curtain (drawn for
the tutorial's hiding friend) was seen edge-on, and the toilet stood in the south-west corner
beside the vanity (z 3.9).

Home step `family_bath_layout` (`home_furnishing.gd` `relay_family_bath()`):

| Item | Now |
| --- | --- |
| Bathtub `Family bathtub` (same model, colours and curtain) | West wall, z 8.31..10.91 under the north window (sill 1.73); taps and shower set on the north wall; the curtain hangs at x -9.49 facing the door |
| Toilet `Family bathroom toilet` | Cistern on the west wall, facing east into the room; (-10.90, z 6.9) after this step, (-10.90, z 5.6) since `family_bath_window` below |
| Roll holder | West wall beside the toilet, 0.85 north of it, height 0.95 |
| Bath mat | In front of the tub, (-8.9, z 9.6), long side along the tub |
| Vanity, walk-in shower, towel rail, plant, tiles | Unchanged (the plant by the door was removed on 14 Nov 2026, [below](#fewer-plushes-and-clear-walkways--14-november-2026)) |

All of it is clear of the door's swing (x -6.72..-5, z 8.64..10.36). The suite bathroom's tub
already faces its door; the east-wing bathroom keeps its tub on the south wall (its east wall
has a window where a tub's rail would end), so its curtain is still seen at an angle from that
door. The bedroom and study window curtains were checked and face the rooms. The bright slivers
on the bathroom floors are sunlight through the window glass (which casts no shadow since
13 Nov 2026), cut by the mullions and the deep sill; not geometry.

Evidence: `docs/evidence/home-tutorial-20261113/capture.gd` (graphics, `VT_FOCUS=home,supermarket`):
`before-*.png` and `after-*.png` of the family bathroom (`family-door`, `family-toilet`,
`family-room`, `family-plan`; after: `family-curtain-drawn`); the unchanged suite and east
bathrooms (`before-*-plan.png`) and window curtains (`before-curtain-1/6.png`) are kept from the
before run only (the script renders all of them).

**Window beside the toilet removed (same day).** At z 6.9 the toilet's cistern touched the
mullion of the south-west window (z 4.4..6.6). The user asked to fix it by removing that window.
Home step `family_bath_window` (`home_furnishing.gd` `remove_family_bath_window()`) frees the
window's seven parts in the opening (glazing — the `window` word object —, three mullions, deep
sill, the wall below and the lintel above), stretches copies of the full-height wall piece and
skirting south of it across z 4.4..6.6, and moves the toilet to the middle of the now solid
wall (z 5.6), roll holder at z 6.45. The north window over the tub stays, so the room keeps
daylight; the outside west façade loses one window. Evidence: `nowin-family-toilet.png`,
`nowin-family-plan.png` (same script, prefix `nowin-`, `VT_FOCUS=home`).

## Fewer plushes and clear walkways — 14 November 2026

User: "other than the ones needed for the tutorial, remove all the NPC in the house" and "remove
all the plants that are blocking the walkway or the entrance of the door".

**Plushes.** Only the welcome tutorial's cast sits in the house: BonBon (guide), Sunny and Leo
(friends). Bruno, Miso, Awoo (Sam), Poppy, Twinkle and Cocodrilo keep their entries in
`data/house_characters.json` with `"in_house": false` (default true), which
`house_characters.gd` `build()` skips. The entries stay because every id is a profile avatar
(`ProfileManager`, `app_screens.gd`, `plush_portraits.gd`), the restaurant draws customers from
the list, and the tutorial's stand-in for a friend who is the player's avatar is the next id in
data order (Bruno first); that stand-in now has no seated house twin to hide (`_hide_twin()`
already skips a missing node). Their seat positions are kept in case one moves back.
`Bedtime` only manages the three placed sitters. (`tools/capture_app_art.gd` no longer aims
at house plushes: its loading shots were retaken as town views on 16 Nov 2026.)

**Plants.** Home step `clear_walkway_plants` (`home.gd`, `WALKWAY_PLANTS`) removes six
houseplants (ivory pot and three foliage spheres each, no collision), at site [x, z]:

| Spot | Where |
| --- | --- |
| (-3.9, -1.8) | Living room, in front of the guest suite door (the tutorial's first doorway) |
| (5.0, 13.0) | Middle of the living room floor, between the front door and the kitchen/east wing |
| (16.4, 9.0) | East hall, in the walking line to the master bedroom door |
| (19.0, 6.9) | Just inside the master bedroom door |
| (-6.3, -2.4) | Just inside the suite bathroom door |
| (-5.6, 7.6) | Just inside the family bathroom door (it opens inward since 13 Nov) |

Kept, off the walking lines: pots in room corners (suite by the dresser, yellow bedroom, master,
study ×2, east bathroom, dining corner), the dining table and living-room side-table plants, the
two terrace topiaries against the glazing (3 m and 4.9 m from the terrace door) and the porch
topiaries (beside the front door, off the entry path). The base world has no greenery at the
home. Evidence: `docs/evidence/home-plants-20261114/` (`capture.gd`, `before-*.png`, `after-*.png`);
[verification](FINAL_VERIFICATION.md#home-plushes-and-walkway-plants--14-november-2026).
