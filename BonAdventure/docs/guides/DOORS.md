# Doors — shared door components

User request, 13 November 2026: make doors a reusable component, update every door to it, and
leave no gap between the frame and the door. The user chose (13 Nov 2026): **mainly one uniform
door** (same design everywhere, colours may differ), three separate reusable components
(**door**, **sliding door**, **double door**), and the scope **walk-through doors plus static
(non-opening) doors**.

**Status: paused part-way (13 Nov 2026).** The three components exist and render correctly on
their own. **First building migrated 18 Nov 2026: the bank** (step `shared_doors` in
`scripts/buildings/bank.gd`, [record](TOWN_DESIGN_BRIEF.md#bank-interior-refresh--18-november-2026)):
office = `sliding_door.tscn`, vault = `door.tscn`, both baked, opened and walked through in
`docs/evidence/bank-refresh-20261118/verify.gd`. This was the first bake that stripped door parts.
Every other door in town is still the old hand-built one.

## Files

| Piece | File | State |
| --- | --- | --- |
| Hinged door (shared builder: frame, leaf, panels, handles, sign, collision, registration) | `scenes/props/door.tscn`, `scripts/world/door.gd` | done |
| Double door (two leaves from the jambs, open together) | `scenes/props/double_door.tscn`, `scripts/world/double_door.gd` | done |
| Sliding door (pocket door, or hung on a wall face with a track) | `scenes/props/sliding_door.tscn`, `scripts/world/sliding_door.gd` | done |
| Double-door leaves open together | `scripts/core/door_animator.gd` `toggle()`: `door_partners` meta | done |
| Bake strips the built parts | `tools/bake_unit.gd` `strip_generated()`, "door parts" | done, not yet exercised by a bake |
| Standalone views | `docs/evidence/doors-20261113/components.gd` → `components.png`, `components-open.png` | done |
| Measurement of the old doors | `docs/evidence/doors-20261113/measure.gd` → `measure.json` (world units) | done |
| Before/after views of every door (56 views, both sides) | `docs/evidence/doors-20261113/capture.gd` + `views.json` → `before.png` (taken), `after.png` (to do) | before done |
| Migration steps | `scripts/buildings/<unit>.gd`, step `shared_doors` | **to do** |

## Using the components

Instance a scene in the wall opening. Origin: the floor at the middle of the opening; the wall
lies in the local XY plane, its thickness along Z; +Z is the front. Sizes are in the parent's units.
Set `width` and `height` to the **clear opening**: the frame lines the opening from outside
(jambs and head overlap the wall, `wall_thickness + 0.03` deep so they never share a face with
it) and the leaf fills the opening exactly. That is how the zero gap is guaranteed.

| Export | Default | Meaning |
| --- | --- | --- |
| `width`, `height`, `wall_thickness` | 0.9, 2.1, 0.2 | clear opening, wall depth |
| `interactive` | true | false = a closed door that never opens (still the word "door", solid) |
| `leaf_name` | "Leaf" | leaf node name (double doors add " left" / " right") |
| `leaf_color`, `leaf_thickness`, `handle_color` | warm white, 0.05, steel | the uniform design: slab, two raised panels per face, lever handles both faces |
| `vision_glass` | false | upper panel becomes the shared window glass (`window.tscn`) |
| `sign` | NONE | WOMEN / MEN restroom figure on both faces (do not combine with `vision_glass`) |
| `hinge`, `swing_to_front`, `open_angle` | LEFT, true, 1.6 | hinged and double doors (double ignores `hinge`) |
| `frame_visible`, `frame_width`, `frame_color` | true, 0.07, warm white | the frame |
| sliding only: `slide`, `slide_distance`, `face_offset` | TO_LEFT, 0 (= width + 0.05), 0 (pocket) | bar pulls instead of levers; `safe_slide` re-opens on the player |

Built at load (like `glass_window.gd`): parts carry the `door_part` meta and are not saved. An
interactive leaf gets a `door_state` meta; Main collects it at load
(`DoorAnimator.restore_editor_door_states`), so it becomes an interactable (E, click, tap) and
render culling leaves it unbatched. One shared unit box mesh and one material per colour.

## Inventory and plan (what is left)

World-unit measurements of each door are in `docs/evidence/doors-20261113/measure.json`. Findings:

| Door(s) | Old build | Gap / issue | Planned component |
| --- | --- | --- | --- |
| Home, 11 (Front, Terrace, Hall, Study, 3 bedrooms, 3 bathrooms, Garage access) | frame mount `<X> door frame` with leaf `<X> door`; mount at scale 1 again since home step `door_heights` (13 Nov 2026; the house raise had scaled it ×1.8 in Y, when these measurements were taken: heights in `measure.json` are now 1.8× too big for the home) | opening 2.236 wide (world), leaf 2.06: about 0.09 each side; 0.03 at the head | `door.tscn`, root keeps the mount name, `leaf_name` = old leaf name (keeps paths); oak `bba381`, frame `f0e7d7`, brass `b79258` |
| Bank Manager office, Vault entrance | flat sliding slab | slabs covered only part of each opening | **done 18 Nov 2026**: office `sliding_door.tscn`, vault `door.tscn` (steel, hinged), new wall pieces close the openings |
| Police Interview room, Holding cell | flat sliding slab | as bank | `sliding_door.tscn` |
| Police Lineup room door | pivot + leaf, built by `police.gd` | 0.02 each side | `door.tscn` |
| Airport restrooms (2) | pivot + leaf + icon, `airport.gd` `_restroom_door` | 0.02 each side | `door.tscn`, `sign` WOMEN/MEN; remove `Restroom door jamb/head` parts (keep the wall lintel if structural) |
| Tower deck door | glass slider on the deck face, `airport.gd` `tower_deck` | — | `sliding_door.tscn`, `vision_glass`, `face_offset`; remove `Deck door head/jamb/track`; keep the tower check passing |
| Hospital Pharmacy door (1.8 wide glass) | stiles + glass | — | `double_door.tscn` with `vision_glass` (proposal) |
| Hospital roof door | slab | — | `door.tscn` |
| Warehouse entrance (glass slider), hall door | `scripts/world/warehouse.gd` `doors()` — **also rebuilt at runtime for the minigame copy** | 0.02 | sliding (glass) and `door.tscn`; change `doors()` itself to instance the components (copy: `interactive = false`, `warehouse_exit` meta on the root); remove `Hall door frame` parts |
| Static: airport Boarding door, Burger back door, Alta Cocina kitchen back door (two faces) | static slabs | — | `door.tscn`, `interactive = false` |
| Static: Chapel doors (two leaves standing open, `chapel.gd`) | open leaves | — | `double_door.tscn`; needs a new `start_open` export (and `DoorAnimator.restore_editor_door_states` honouring it) so they stay open as designed |
| Static: Alta Cocina entrance leaf and arched back door; Pizza y Hamburguesas and Fine Dining facade doors | on map facades / arched openings | need a look in `before.png` first | to decide; arched doors may keep their arch trim above a rectangular leaf |

Out of scope (user choice): vehicle doors, cabinet/locker/hutch doors, the home garage door, the
warehouse roll-up door, the barn doors, and the Mystery House minigame doors (`mystery_door.gd`).

### Steps to finish

1. Review `docs/evidence/doors-20261113/before.png` (row order = `views.json`) to settle the bank/police
   slider openings and the facade and arched static doors.
2. Per unit, a new step `shared_doors` in `scripts/buildings/<unit>.gd` (home, bank, police,
   airport, hospital, warehouse, restaurants, chapel): remove the old leaf/pivot and its frame
   parts, instance the component at the measured opening (convert world → parent-local
   explicitly; Apartment scale 1.3; the home mounts are back at Y scale 1), same name, same swing side and
   angle (`measure.json`: `n` points to the swing side, `pivot_u` < 0 = hinge LEFT).
3. Code that builds or names doors: `warehouse.gd` `doors()` (runtime copy), `warehouse_session.gd`
   exit lookup, and the checks that use old paths: `check_hospital_remodel.gd`,
   `docs/evidence/warehouse-20261105/verify.gd` and captures, `docs/evidence/police-detective-20261106/verify.gd`,
   `docs/evidence/police-interior-20261028/verify.gd`, `docs/evidence/bank-interior-20261028/verify.gd`,
   `docs/evidence/tower-deck-20261112/verify.gd`, `docs/evidence/bath-fixtures-20261108/*`, `docs/evidence/hospital-polish-20261031/verify.gd`,
   `docs/evidence/police-lobby-20261108/capture.gd`, `check_reference_home.gd`. Old leaves were the pivot node;
   the new leaf is `<component>/<leaf_name>`.
4. Bake the units (`tools/bake_unit.gd -- <unit>`); `dev_focus.txt` must read `all` afterwards.
5. Verify once: resource load, `check_building_access.gd`, the checks above, then
   `capture.gd` with `VT_SHEET=after` and compare with `before.png`.
6. Update README task table and `docs/README.md` with a Doors row; record results in
   `FINAL_VERIFICATION.md`. Ask before committing.

Caution: home, restaurants and library scenes and scripts have other uncommitted work in the
working tree (home expansion, furnishing); bake on top of it, do not revert it.
