# Final verification — 20 October 2026

## Current state — 18 November 2026

Read this first; everything below is a dated log, and each entry describes only its own run.

- **Last full suite:** 16 Nov 2026, `run_checks.py full`, `dev_focus.txt` = `all`: PASS 47,
  NEW 6, TIMEOUT 3 ([record](#docs-reorganised-into-game--guides--evidence--archive--16-november-2026)).
  All 9 were traced to game changes and their checks fixed; the 9 re-run once: **PASS 7, KNOWN 2,
  NEW 0** ([triage](#triage-of-the-16-november-full-run-failures--16-november-2026)).
- **Since then:** only targeted checks per change (each entry lists them and what was not run).
  No full suite has been run on the 17–18 Nov changes.
- **Known failures:** [`data/expected_check_failures.json`](../../data/expected_check_failures.json)
  is the list (each with a date, reason and priority): `map_facades` (a street ray hits the
  hospital's glass front before its facade, P3) and `rooftops` (the barn's gambrel roof is
  steeper than walkable, by design). Open low-priority noise: `day_night` logs engine errors from
  `verify.gd:90` (P4).
- **How to run:** [README Verification](../../README.md#verification).
- **Order:** entries from 14–16 Nov are at the top (newest first); entries from 12–18 Nov were
  also appended at the end, from [Library books 50 % larger](#library-books-50--larger--12-november-2026)
  onwards. Add new entries at the end; the newest are the last ones.

## Introduction — 20 October 2026

Current vehicle status is in the [road rewrite](#road-vehicle-physics-rewrite--22-october-2026)
and [helicopter rewrite](#helicopter-physics-rewrite--22-october-2026)
below. Earlier sections retain their dated baselines; their
vehicle failure counts do not describe the replacement controller/current tests.

Part 3 changes documentation only. The existing folder structure is retained.
Start at the [README](../../README.md); editing contracts are in the
[architecture guide](ARCHITECTURE_REVIEW_PART1.md), and implementation details and
six rendered views are in the [Part 2 handoff](../evidence/part2/HANDOFF.md).

## Civic fixes: garage, school, police lockers, warehouse cabinet, zoo gate — 23 November 2026

[What was built](TOWN_DESIGN_BRIEF.md#civic-fixes-garage-school-police-lockers-warehouse-cabinet-zoo-gate--23-november-2026).
`tools/bake_unit.gd -- base home school police warehouse` (school re-baked alone from its committed
scene while the step was finished); `tools/compare_scenes.gd` against the committed scenes: only
the intended nodes differ (base: the welcome board, its label and two posts). Isolated `HOME`,
`dev_focus.txt` = `all`. `python3 tools/run_checks.py --only` with the finished scenes:
runtime_resources PASS, interaction PASS, vocabulary_categories PASS, part2 1349 checks 0 failures,
police_interior 202/0, police_detective 130/0, police_officer 15/0, warehouse 105/0,
warehouse_game 108/0, grammar_class 111/0, building_access 486/0, signs 620/0, world_signs 443/0,
vocabulary_report 5416/0 (it rewrote `docs/game/words.md` and the vocabulary report: date and
place counts; *bicycle* now only in the sports store). Every Godot check above printed its summary
and then aborted at exit (`recursive_mutex lock failed`, signal 6), so the runner listed them as
CRASH: compare labels, not the status. Also failing, not from this change: `language` (zh
characters without a reading; the same on a clean HEAD) and `compact_layout` 618 checks, 1
failure "rigid move preserves scale …/Turboprop" (vehicles untouched here; the plane was resized
in bb6f26be; not run on HEAD). Renders (windowed, `VT_FOCUS=home,school,police,warehouse`; not the
full town): `docs/evidence/civic-fixes-20261123/capture.gd` before/after, inspected; it opens the
lockers and the cabinet through the door animator (2 + 2 doors) and the zoo gate from both sides
as the player (leaf tip at z 124.2 from outside, 127.8 from inside; the gate line is z 126). Not run:
the full suite, a hands-on play-test, a touch device or the web export.

## Control tower deck floor, hatch, ladder, dots and stair rails — 23 November 2026

[What was built](TOWN_DESIGN_BRIEF.md#control-tower-deck-floor-hatch-and-stair-rails--23-november-2026).
`tools/bake_unit.gd -- airport` (steps `tower_deck_floors`: added north and west;
`tower_hatch_carpet`; `tower_stair_rails`: 164 old parts removed, 105 new), then
`docs/evidence/tower-fixes-20261123/verify.gd`, windowed, isolated `HOME`, `VT_FOCUS=airport`
(not the full town; `dev_focus.txt` stayed `all`): 22 checks, 0 failures, with renders of the deck
from outside, the hatch from above, three stair views and the empty level's guard in that folder.
The check drives the real player with W and S: from the hatch's head W and S both climb down to the
empty level with no bounce (peak 22.00) and stay at the foot while held; W from the foot climbs,
steps off and walks on away from the hatch. Dots: the control-room radar shows from in front of it
and not from the deck or the ground; the radar-room one not from the floors above. Not run: the
full suite, the old `tower-bridge-seats-20261030` and `tower-deck-20261112` checks, the barn and
chapel ladders (their "forward" ladders skip the new top-taking code; the stick push now also
climbs them, unplayed), electrical-box dots in the town, a touch device or the web export.

## Passport, missions, stamp coin and achievement log — 21 November 2026

[What was built](ACHIEVEMENTS.md). Isolated `HOME`, `dev_focus.txt` = `all` (the runs used
`VT_FOCUS` instead: not the full town), each run on the finished code:
`docs/evidence/stamp-coin-20261121/verify.gd` (headless, a stage of its own, no town): 15 checks, 0
failures; `docs/evidence/passport-missions-20261121/verify.gd` (windowed, `VT_FOCUS=library,police,school`):
77 checks, 0 failures, renders of every Passport page and the map stars in that folder. Coin
renders in the real town: `stamp-coin-20261121/town_view.gd` (`VT_FOCUS=library`, run before the
final code; the coin itself has not changed since). Not run: the full suite,
`tools/language_check.gd`, a real phone or the web export; flying the plane or helicopter and the
swing were not played (their hooks were checked by reading only; sitting was checked through
`tick()`). No stamp coin is placed in the town yet (waiting for the user). Later the same day
the coin got the user's pig face (vtracer trace, `assets/stamps/`): the stamp check again 15 checks,
0 failures (headless), and new town renders `town-coin-close.png`, `town-coin-angle.png`,
`town-outside-door.png`, `town-outside-far.png` (`VT_FOCUS=library`).

## Warehouse shelf and placing — 21 November 2026

[What changed](WAREHOUSE.md#shelf-and-placing-21-nov-2026): plain box removed, two-level shelf
(warehouse unit rebaked, step `two_level_shelf`), tap-a-level placing. Isolated `HOME`,
`dev_focus.txt` = `all`, each run once: `python3 tools/run_checks.py --only warehouse,warehouse_game`:
both PASS (105 and 108 checks, 0 failures; the game check gained the aim checks). Vocabulary
report `--write`: 5368 checks, 0 failures. Renders in `docs/evidence/warehouse-shelf-20261121/`
(windowed, `VT_FOCUS=warehouse`). Not run: the full suite; no real phone or web export test (the
aim was checked with a camera ray, and in a window with the pointer on the top deck's beam).

## Car path steering and chase camera — 21 November 2026

[Path steering and chase camera](ZOO_VEHICLE_IMPLEMENTATION.md#path-steering-and-chase-camera--21-november-2026).
`dev_focus.txt` read `all`. One `run_checks.py --only` run when the code was complete:

| Check | Result |
| --- | --- |
| runtime_resources, vehicle_arcade (104 checks), zoo_vehicles, vehicle_boarding, vehicle_doors, touch_controls | PASS |
| road_physics (393 checks, with the new steering checks) | PASS |

Views (looked at): `docs/evidence/car-driving-20261121/turn-*.png` (`capture.gd`: the
north-east road-side car, camera starting side-on; it swings behind and the car turns).
Not run: the full suite; no hands-on keyboard/touch play-test.

## Supermarket real windows baked — 18 November 2026

The supermarket's `real_windows` step ([windows guide](WINDOWS.md#real-windows--18-november-2026))
baked after the layout commit: two SHOPFRONT windows, 15 old parts each replaced, front piers cut.
`dev_focus.txt` = `all`, isolated `HOME`, each run once: `runtime_resources`, `building_access`
PASS; `real-windows-20261118/capture.gd` (VT_FOCUS=supermarket, so not the full town): both windows
see-through, outdoors face, meadow frame, word window, nothing across the glass; views
`before-supermarket*.png` / `after-supermarket*.png`. The full suite and a web phone test were not run.

## Grocery checkout and free shopping — 21 November 2026

Pay Up! retired into the Grocery Run checkout; prices, free shopping with a basket, the shop door
([record](TOWN_DESIGN_BRIEF.md#grocery-checkout-and-free-shopping--21-november-2026)). Working tree
with other uncommitted work present (the 21 Nov tutorial review, car driving, outfits). Isolated
`HOME`, each run once unless noted:

| Check | Result |
| --- | --- |
| `grocery_checkout` (new, `grocery-checkout-20261121/verify.gd`) | PASS, 45 checks (run twice: again after free shopping became a quiet board activity) |
| `minigame_progression` | PASS (rewritten from Pay Up! to Grocery Run at the till) |
| `minigame_launcher` | PASS, run twice (updated: the till asks for a basket; orders paid at the till) |
| `shop_basket` | PASS, run twice (updated: paid at the till before handing in) |
| `activity_lifecycle` | PASS |
| `tutorial-review2-20261121/verify.gd` (not in the runner) | PASS, 64 checks: the tutorial's shop still pays at the borrowed till |
| `tutorial` (`tutorial-polish-20261118`) | TIMEOUT, 20 failures from "more to show you" on: stale against the uncommitted 21 Nov tutorial review, which removed `tutorial.more_to_show`, `to_supermarket` and others before this work; not caused by the checkout. **P2:** update or retire this check with that review |
| `vocabulary_report -- --write` | 0 failures; `words.md` and the report refreshed (every priced product now counts as ordered) |
| The commit alone (HEAD plus only these changes, in a temporary worktree) | `grocery_checkout`, `shop_basket`, `minigame_progression`, `activity_lifecycle` PASS; the vocabulary report was written there, so it leaves out the other uncommitted work |

Views (`VT_FOCUS=supermarket`, not the full town): `order-cart.png`, `till-check.png`,
`till-pay.png`, `free-basket.png` in `docs/evidence/grocery-checkout-20261121/`.
`data/town_map.json` and `data/nearby_units.json` lost their `cashier_supermarket` entry by hand
(the same as a re-bake; the map picture was not re-rendered). Not run: the full suite, a web or
phone test, walking into the door barrier by hand (checked through `DoorGuard.blocks()` only).

## Stale checks updated — 18 November 2026

Checks whose expectations predated recent changes, each run once (`dev_focus.txt` = `all`,
isolated `HOME`, working tree with the uncommitted supermarket layout work present):

| Check | Before | Now |
| --- | --- | --- |
| `day_night`, `bath_fixtures` | NEW / TIMEOUT on 13 Nov (lamp and fixture counts) | PASS with no change: already fixed since |
| `rooftops` | KNOWN | KNOWN, only the 2 barn roof labels |
| `electrical_box` | TIMEOUT (minimap Nil, 14 Nov) | PASS, 55 checks, no change: the minimap is already optional in its `verify.gd` |
| `compact_layout` | NEW: 44 vehicles expected | PASS: expects 29, since `tutorial_lot_clear` (`26cf153`) removed the 15 parked motorcycles |
| `check_vehicle_collision.gd` (run alone) | "Vehicle remains selectable" failed for all 39 | 0 failures: since 12 Nov a vehicle is an Interactable, which never opens a word card, so the check now aims at it as a player does and requires its Interactable to be aimed and clickable |
| `food_shopping_vocab` (new in the full suite) | hard-coded 500 words, pre-6 Nov store paths, SCRIPT ERROR and hang | rewritten for the modular town with a watchdog: PASS, 105 checks, all 13 words placed and picked |

Not run: the full suite.

## Minigame progression: levels and stars — 18 November 2026

Shared levels, stars and unlocks (`game_progress.gd`; [progression](MINIGAMES.md#progression)),
wired into Pay Up! and Grocery Run; the other games are designed only. `dev_focus.txt` = `all`,
isolated `HOME` (`tools/run_checks.py`), each run once: `minigame_progression` (new, 41 checks)
PASS; `runtime_resources`, `profiles`, `shop_basket`, `minigame_launcher`, `tutorial`, `app_flow`
PASS; `activity_lifecycle` PASS after updating its summary comparison for the three new keys
(`misses`, `needed`, `custom`). Not from this change, recorded as found: `language` NEW
(`zh` readings missing for 便 逛, already in `data/phrases.json` at b4af467), `compact_layout` NEW
(the known vehicle count, "all forty-four road/air vehicles registered"), `practice_log` NEW
("shop bubble: … translated": the check presses `toggle_translation()`, which no longer records a
translation since the EN button took that over, `shop_order_panel.gd` `_on_peek()`). One windowed
run at 1280 × 720 rendered [picker, greeting badge and star card](../evidence/minigame-progression-20261118/).
After merging `main` (e23ecff, wayfinding: the picker's Go there button) `minigame_progression`,
`minigame_launcher`, `activity_lifecycle`, `runtime_resources` PASS, and the picker re-rendered
(Rounds, Level, Go there and Play fit at 1280 × 720).
The full suite, a web export and a phone were not run. `tools/build_cjk_font.py --check` could not
run (no fontTools); the new Chinese text uses only characters already in the data at b4af467.

## All clay zoo animals walk — 16 November 2026

Walking rigs for the other 16 clay zoo animals (four parallel sessions, merged; base step
`clay_animals_walk`; record and limits in
[ANIMAL_SYSTEM.md](ANIMAL_SYSTEM.md#all-clay-zoo-animals-walk-16-nov-2026)). `dev_focus.txt` =
`all`, isolated `HOME`, run once: `runtime_resources`, `compact_layout`, `interaction` PASS; the
pig's bone poses unchanged by the merged animator; all 17 animals rendered walking in the full
town; frame time over the zoo 10.64 ms (animators running) against 8.57 ms (paused) on an M5.
The full suite, a web export and a phone were not run.

## Zoo pig walks — 16 November 2026

The rigged clay pig replaces the zoo pig's static model (base step `pig_clay_walks`; record and
limits in [ANIMAL_SYSTEM.md](ANIMAL_SYSTEM.md#zoo-pig-in-the-town-16-nov-2026)). `dev_focus.txt`
= `all`, isolated `HOME`, run once: `runtime_resources`, `compact_layout`, `interaction` PASS;
rendered walk frames in the full town. The full suite and a web export were not run.

## Lighter clay animal files — 16 November 2026

Clay meshes saved as separate compressed files with compressed vertex attributes
(`tools/clay_save.gd`, base step `clay_meshes_external`); details and the size/load table in
[ANIMAL_SYSTEM.md](ANIMAL_SYSTEM.md#clay-file-sizes-16-nov-2026). `dev_focus.txt` = `all`,
isolated `HOME`, each run once: resource loading (`docs/evidence/clay-sizes-20261116/measure.gd`),
base bake + `compare_scenes.gd` (only `applied_steps` differs), web export (`index.pck` 55.0 →
46.7 MB), pixel diffs of all 17 prefabs (≤ 0.016% of pixels) and seven zoo views (≤ 0.026%).
No test suite was run.

## Seven-part improvement batch, merged — 14 November 2026

User request (movement, shop, warehouse, vehicles, elevator, save/respawn, classroom), built in
six parallel workstreams; each has its own dated entry below. After merging, `dev_focus.txt` =
`all`, one full run (`python3 tools/run_checks.py full`, 1621 s):

| Result | Checks |
| --- | --- |
| PASS (46) | everything else, including player_place, vehicle_arcade, warehouse, warehouse_game, grammar_class, elevator_call_button, shop_basket, tutorial, road_physics, aircraft, helicopter, zoo_vehicles |
| NEW, caused by the merge, fixed | `touch_controls` (3): the east delivery lot's new parked car stood 2 m from the default start, so the check's E boarded it — moved one bay south by base step `spawn_clear_car` (door 5.6 m away, past `BOARD_DISTANCE` 5.2); the locks list now includes `elevator_floor_picker` (intended). Re-run with vehicle_arcade, zoo_vehicles, part2, runtime_resources: all PASS |
| NEW, not from this batch | `language` (2: `restaurant.miss_also` placeholders, zh readings), `compact_layout` (6: ParkZoo animal scale), `building_lookup` (minimap found; minimap hidden), `building_access` (54 market dictionary cards), `rooftops` (jump counter; infinite jump off), `day_night` (3: 47 glowing lamps = chapel chandelier bulbs and zoo lamps besides the 27 street lamps) |
| TIMEOUT, not from this batch | `map_facades` (known label), `bath_fixtures` ("Guest bathroom faucet" not found in the home), `electrical_box` (the hidden minimap is Nil at verify.gd:113) |

These "not from this batch" results also appeared in workstream runs that lacked the changes
of the others; no baseline run of the old commit was made. Motorcycle detail (`Detail`,
`Mechanics`) hides beyond 120 m again (`motorcycle.tscn`, `tools/merge_motorcycle.gd`): overview
+345 draw calls with the 31 parked vehicles (was +405 after the merge, +264 before it). Views
re-rendered in `docs/evidence/parked-vehicles-20261114/` (warehouse lot now shows the new building). Not
tried: a touch device, the Web export, a real quit-and-reopen with a profile.

## Elevator floor picker — 14 November 2026

[Hospital guide, Floor picker](HOSPITAL_THREE_FLOORS.md#floor-picker--14-november-2026)
(`scripts/ui/elevator_floor_picker.gd`, `hospital_elevator.gd`, `elevator_call_button.gd`, a
`PANELS` entry in `minigame_wiring.gd` and a `main.gd` field). E at a cabin panel opens a camera
close-up of the real 3D panel; a tap on a floor button calls the car and closes it; outside tap,
✕ and Esc close it; direct clicks on cabin buttons still press them; cabin pick boxes 1.5× wider
(height clipped to the pitch) and `Area3D`. Runtime only: no unit rebaked. Isolated `HOME`.

- **Checks, once each** (`run_checks.py --only`, full town, `VT_FOCUS=all`):
  `elevator_call_button` PASS (199 checks, 0 failures; extended for the picker in both
  elevators), `hospital_remodel` PASS (872 checks), `hospital_departments` PASS (24 words),
  `runtime_resources` PASS (531). An earlier `elevator_call_button` run of the new section failed
  11 labels before a fix (the panel's reach was measured to its badge 1.3 m up, out of range)
  and the test position; the fixed run above is the result.
- **Rendered** (window 1400×900, `VT_FOCUS="hospital, airport"`):
  `docs/evidence/elevator-floor-picker-20261114/hospital-picker.png` (four buttons, floor 3 lit) and
  `tower-picker.png` (three buttons); title bar and ✕ at the bottom, rings round the buttons.
- **Not verified:** a real touch device or the web build; the other full-suite checks were not
  run.

## Grammar Classroom: 5 questions, one review per miss, bigger board — 14 November 2026

User request: Lana's class is 5 questions (`grammar_lana` progress 5); every missed or
unanswered question comes back once at the end, a review missed again does not (so at most 10);
a bigger, clearer whiteboard with text half as large again; the months poster moves off the
rear wall. Guide: [GRAMMAR_CLASS.md](GRAMMAR_CLASS.md); layout:
[design brief](TOWN_DESIGN_BRIEF.md#grammar-classroom-remodel--6-november-2026).

- `scripts/learning/grammar_session.gd`: `REVIEW_MIN_QUESTIONS` removed; each class works on its
  own copies of the picked questions and marks misses (`missed`); board text 144 / 96 px, ink
  `0f1e3a`, `_fit_board()` wraps and shrinks (to 72 px at least) so sentence + pinyin stay within
  86 % of the board.
- `scripts/buildings/school.gd` new step `bigger_board`, baked with `tools/bake_unit.gd -- school`
  (`BAKE UNIT: school: bigger_board`, `COPLANAR GAPS school pass 3: 0 faces moved`, saved OK,
  2853 nodes; two new shared materials in `materials/palette/`): board 6.0 × 2.6 at (−6.5, 2.1)
  (same node `Whiteboard`, metas kept, `grammar_board` = new size), darker frame; months poster
  to the left side wall's front end (−11.68, 2.6, −9.6) facing +x, its 12 month word objects
  unchanged; "General classroom" sign up to y 3.98.

| Check (isolated `HOME`, `VT_FOCUS=all`, full town, run once) | Result |
| --- | --- |
| `grammar_class` (updated: 5 questions, class of 6 after the first miss, reviews ≤ 5 and = misses, class ≤ 10, board size, board text fits, months poster place and 12 words) | **PASS**, 111 checks, 0 failures |
| `runtime_resources`, `vocabulary_categories`, `vocabulary_translations`, `vocabulary_report` | **PASS** (the report's regenerated files were not kept: their changes come from other work) |
| `building_lookup` | NEW 1: `minimap found` (the minimap is a hidden feature since 14 Nov, `features.gd`; not this change) |
| `building_access` | NEW 54, all `market dictionary card <word>` (supermarket word cards); every school word is pickable (36 school words). Not this change; not compared with HEAD (**P2**, to investigate with the 14 Nov word-card / hidden-features work) |

Renders (windowed, `VT_FOCUS=school`, `capture.gd -- board`), in `docs/evidence/grammar-class-20261114/`:
`board-es-from-start.png` (two-line Spanish sentence, readable from the start),
`board-zh-from-start.png` (Chinese with pinyin), `months-side-wall.png`, `room-top.png`,
`room-from-entrance.png`. Not checked: a phone-size window; Lana is absent from the two
free-camera room shots taken after the class ended (present in the class shots; probably the
14 Nov indoor visibility culling around the hidden player, not investigated).

## Save and respawn — 14 November 2026

[Saved place](ARCHITECTURE_REVIEW_PART1.md#saved-place-and-respawn) (`scripts/core/player_place.gd`,
`player_place_keeper.gd`, `Main._restore_place()`, `Main.ENTRANCES` = the former `DEV_SPAWNS`
plus `tower`, `save_store.gd` `PROFILE_FILES`, `web_resume.gd`). Full town (`dev_focus.txt` =
`all`), isolated `HOME`, headless, run once each.

- **`player_place` (new, full suite): PASS**, 0 failures. Place file round trip (broken file,
  other version, `read_only`); every unit has an entrance; for all 24 `ENTRANCES` a point 3 m
  inside the door is recognised as that unit and respawns at the standing point facing the door
  with the capsule clear, walkable ground below and open sky (the playground, open air, counts
  as outdoors); hospital floors 2 and 3 and the control tower; the warehouse minigame copy saves
  the real warehouse; outdoors: an open spot is kept, a point inside a test wall and inside a
  parked road vehicle move to a clear spot nearby, a flying vehicle 40 m up lands the player on
  the ground below, the supermarket roof puts the player on the ground beside it (about 13 m
  away), a point at sea gives the usual spawn; an unloaded unit and an unknown entrance give the
  usual spawn; with a test profile Main restores outside the bank and the keeper saves the
  library. Without a profile nothing is saved and the player starts at the supermarket.
- **Same run:** `runtime_resources`, `part2`, `public_garden`, `profiles`, `activity_lifecycle`
  PASS; `language` NEW 2 and `compact_layout` NEW 6, the same labels as in the
  [WebGL entry](#webgl-context-loss-reduce--recover--14-november-2026) below;
  `building_access` NEW 54 (all "market dictionary card …": a click on a market word showed no
  card) and `building_lookup` NEW 1 ("minimap found": the minimap has been switched off since
  14 Nov 2026, `Features.MINIMAP`). Without a profile this change only renames the entrance
  table, so these are not from it; no baseline run was made. **Open (medium):** look at the
  market card clicks; update `check_building_lookup.gd` for the hidden minimap.
- **Not tried:** a windowed or web run with a real profile (quit, reopen, tab hidden); rendered
  views of the respawn spots (headless only); a vehicle parked inside a building other than the
  home garage.

## Warehouse redesign — 14 November 2026

User-approved redesign ([blueprint](TOWN_DESIGN_BRIEF.md#warehouse-redesign--14-november-2026),
[guide](WAREHOUSE.md#redesign-14-nov-2026)), uncommitted: the 30 × 14.5 warehouse with the
reception at the east end, two loading bays, the divider and one shelf / table / cabinet
(`half_depth_redesign` step, `tools/bake_unit.gd -- warehouse`), and the five-task minigame
(`warehouse_ramon` progress 5; [minigame](WAREHOUSE.md#minigame-14-nov-2026)). New checks
`docs/evidence/warehouse-20261114/verify.gd` and `verify_game.gd` replace the 5 Nov ones in
`tools/run_checks.py` (`warehouse`, `warehouse_game`).

Full town (`dev_focus.txt` = `all`), isolated `HOME`, `tools/run_checks.py --only
runtime_resources,warehouse,warehouse_game,vocabulary_report,vocabulary_translations,vocabulary_categories,building_access,building_lookup,map_facades --jobs 2`, run once:
- PASS: `runtime_resources` (530 checked), `vocabulary_report` (5434 checks; it rewrote
  `docs/guides/vocabulary-report/`), `vocabulary_translations`, `vocabulary_categories`.
- `warehouse` NEW (4) and `warehouse_game` NEW (7): real bugs, fixed, then these two re-run once:
  a task-writer bug (the shelf capacity read through the planner, so no top-shelf task: only 4 of
  5 tasks planned), parts sharing a name (counted wrong), the truck 1.5 from the wall (moved 1.1
  closer; re-baked), two walk points on the divider ends. **Re-run: `warehouse` PASS (105 checks,
  0 failures), `warehouse_game` PASS (104 checks, 0 failures).**
- `building_access` NEW: 54 `market dictionary card …` labels (supermarket dictionary cards; not
  the warehouse; not traced here).
- `building_lookup` NEW: `minimap found` (the minimap is a hidden feature since 14 Nov 2026).
- `map_facades` TIMEOUT at 300 s with its 1 known label (`street ray picks new facade HOSPITAL`);
  it ran beside another check (`--jobs 2`); not re-run.

Rendered once (VT_FOCUS=warehouse, so other buildings absent; then the two minigame views again
after the fixes, with the town views) in `docs/evidence/warehouse-20261114/`: front with both bays (truck
at bay A, bay B empty), front wide, reception desk, counter (ruler; the scale shows in the
partition view), reception partition (posters, hall door), hall right (empty, both roll-up doors
from inside), hall left (divider, table, shelf, cabinet), shelf with boxes on both levels, and
the minigame mid-task with the task card (*Pon la caja amarilla a la derecha de la caja verde*,
the box carried, the green box in its bay). Ramón is hidden behind the truck in the front view.

Not done / open (priorities in [the guide](WAREHOUSE.md#open-items)):
- P1: the parked car and motorcycle in the warehouse lot (`base.scn`, not this unit).
- P2: the map's `Warehouse entrance connection` still ends at the old entrance (base).
- P2: *brown* and *medium* (added 8 Nov 2026 for the old game) are now placed nowhere and used by
  no game (vocabulary report); remove them or give them a use. *Crocodile* also appears in that
  list (not the warehouse).
- Walking is checked with the player's capsule and teleports, not real movement; no
  hands-on play-test; the full suite was not run.

## Vehicles: parked cars, arcade collisions, exit while moving, resets — 14 November 2026

[Arcade collisions, exit while moving and resets](ZOO_VEHICLE_IMPLEMENTATION.md#arcade-collisions-exit-while-moving-and-resets--14-november-2026),
[more parked vehicles](ZOO_VEHICLE_IMPLEMENTATION.md#more-parked-vehicles--14-november-2026),
[aircraft: exit in flight, resets and the map edge](aircraft.md#exit-in-flight-resets-and-the-map-edge).
Full town (`dev_focus.txt` = `all`), isolated `HOME`, `base.scn` rebaked with the
`parked_vehicles` step. One `run_checks.py` run when the code was complete:

| Check | Result |
| --- | --- |
| runtime_resources, part2, road_physics, vehicle_doors, vehicle_boarding, aircraft, easy_flying, helicopter, interaction | PASS |
| vehicle_arcade (new: `docs/evidence/town-checks/check_vehicle_arcade.gd`) | PASS, 136 checks, 0 failures |
| zoo_vehicles | NEW: its count of 12 road vehicles was out of date (now 41); count updated, re-run once: PASS |
| language | NEW: two zh characters in the new exit lines (fixed, re-run once) plus the pre-existing `restaurant.miss_also` and zh readings 備 質 素 暢 揭 喬 臥 桌, not from this work |
| rooftops | NEW: jump counter 2–6 / successive jump height (`Features.INFINITE_JUMP_AT_START` is false; not vehicles); chapel spire reported FIXED as before |

Existing checks that expected E to be refused while moving or airborne now expect an exit
beside the vehicle without the door sequence (`check_road_physics.gd`, `check_aircraft.gd`,
`check_helicopter_physics.gd`, `check_zoo_vehicles.gd`).

Measured in `vehicle_arcade`: car glancing at 20°, 15 m/s keeps 0.78 of its speed, motorcycle
0.89, car at 60° and 20 m/s 0.24; no tunnelling through a 5 cm wall at 27 m/s; a car left at
14 m/s coasts 118 m and parks after 17.4 s; BonBon leaving a hovering helicopter lands in 1.6 s,
the helicopter comes down, crashes and is back on its pad; the plane turned back from up to
301 m past the map edge (five `vehicle.map_edge` flashes) without crashing.

Render cost of the 29 parked vehicles (`docs/evidence/parked-vehicles-20261114/capture.gd`,
1400×900, default Low graphics, same views hidden → shown): restaurant lot 687 → 981 draw
calls, bakery and electronics 414 → 1002, hospital and school 2027 → 2594 (9.5 → 12.5 ms),
road-side 654 → 1319, overview 4566 → 4830 (14.15 → 15.91 ms); other views at the vsync cap.
Views (looked at): `docs/evidence/parked-vehicles-20261114/restaurant-lot.png`,
`bakery-electronics-lots.png`, `hospital-school-lots.png`, `roadside-car.png`, `overview.png`.

Open items:
- ~~P2: parked motorcycles cost 217 meshes each~~ (done below: merged to 7 meshes).
- P3: the plane can go about 300 m past the soft map edge before it is turned back (it is
  reset 400 m past); the helicopter has no map edge (only the 300 m unoccupied reset).
- P3: road-side cars stand in the edge of the lane (4 town units off the centre line).
- The school bus (in `school.scn`) was not touched. (*Stale:* the warehouse lot now has a car
  and a motorcycle, below.)
- Not checked on a touch device or in the Web export.

**Follow-up, same day: lighter motorcycle, warehouse lot and walk.** `motorcycle.tscn` merged by
`tools/merge_motorcycle.gd` from 217 meshes to 7 (37 surfaces; same 30,264 vertices and bounds;
close-ups from three angles compared by eye with the original: same);
a car and a motorcycle in the warehouse lot's west bays; the entrance walk moved to the new glass
entrance (warehouse-local x −12.2). `base.scn` rebaked from its committed version (steps
`parked_vehicles`, `warehouse_entrance_walk`), no stale instance overrides. One run:

| Check | Result |
| --- | --- |
| runtime_resources, road_physics, vehicle_boarding, vehicle_doors, interaction | PASS |
| zoo_vehicles (count now 43) | PASS, 323 checks |
| vehicle_arcade (now also the warehouse lot, numerically against the 14 Nov warehouse geometry, and the walk) | PASS, 149 checks, 0 failures |
| compact_layout (vehicle count 13 → 44 updated) | NEW: 6 × "rigid move preserves scale" for ParkZoo Tiger, Monkey, Snake, Horse, Hen, Sheep; not vehicles; the vehicle count passes |
| `check_vehicle_collision.gd` (not in run_checks; run alone for the motorcycle) | the 8 prefabs, the motorcycle among them, block from four sides and can be walked around; "Vehicle remains selectable" fails for all 39 town vehicles, old ones included (Car, Bus, Taxi...), so it is the check's aim test, not this change |

Render cost after (added vehicles hidden → shown, draw calls): restaurant 687 → 801, bakery and
electronics 414 → 642, hospital and school 2027 → 2234 (10.3 → 10.6 ms), road-side 654 → 959,
overview 4566 → 4971 (15.4 → 16.2 ms), warehouse lot 888 → 1002; 1,513 mesh instances added
(was 4,358). Lot-view primitive counts equal the earlier run. Overview draws more than before
(merged parts keep the bike's 300 m range; the old small parts hid at 120 m). A first render with
one merged body mesh (32k triangles) lost the body of distant motorcycles on Low
(`render_culling.gd` HEAVY_TRIANGLES); the body is now two meshes under 30k. The warehouse view
shows the old building in this worktree; positions were checked numerically.

## WebGL context loss: reduce + recover — 14 November 2026

[README, Web app](../../README.md#web-app-pwa) and the
[performance guide](performance/README.md#gpu-memory-on-the-web--14-november-2026)
(`render_culling.gd` `share_label_sizes()`, `scripts/core/web_resume.gd`, `app.gd`, the second
script in the Web preset's `html/head_include`, `perf_readout.gd`, three `app.*` phrases).
Full town (`dev_focus.txt` = `all`), isolated `HOME`.

- **Measured** natively (M5, compatibility renderer, 1280×800, Low) with a scratch probe:
  video memory 392 MB (textures 102, buffers 290; meshes 224 of which plush characters 116,
  zoo animals 50); forcing the web-only label step: 87 → 34 font size pairs, glyph atlases
  65 → 43 MB, **textures 102 → 84 MB, video memory 392 → 373 MB**. In the web build (app's
  Chromium, 800×600, Low, 3D ×0.40) the readout showed 395–449 MB after the change; no web
  "before" was taken. Not measured on a phone.
- **Recovery tried** in a web export (`deploy_web.py --out`, not published) served on
  `localhost` in the app's Chromium browser, with a test profile of that origin (no learner
  saves): the note was written every 5 s; after turning the camera,
  `WEBGL_lose_context.loseContext()` gave no alert (`alert` counted 0 times), the page reloaded
  by itself, skipped the title and profile screens and loaded the town with the player at the
  same spot and heading; a second forced loss did the same and "All set! You're right where you
  left off." showed in the HUD message line (small, top right, 4 s). A third loss within two
  minutes showed "Reloading the graphics…" with "Tap to reload", and the tap resumed the same
  way. An ordinary reload started at the title. Labels in the rendered town looked unchanged.
  **Not tried:** a real phone, a loss while the page is hidden, the `visibilitychange` /
  `pagehide` notes (same callback as the loss), resuming a profile in the tutorial.
- **Checks, once:** `run_checks.py` quick: `runtime_resources`, `part2`, `public_garden`,
  `profiles`, `activity_lifecycle` PASS; `language` NEW 2 (`restaurant.miss_also` placeholders;
  readings missing for 備 質 素 暢 揭 喬 臥 桌) and `compact_layout` NEW 6 (rigid move scale of six
  zoo animals): none of these labels touch this change (the new phrases use none of those
  characters; the label step runs only on the web), not compared against a baseline run.

## Mobile playability, combined run — 14 November 2026

Everything of the mobile-playability work together in one tree (uncommitted unless noted):
- graphics tiers (below);
- indoor visibility (commit `3a70d8a` + its uncommitted whole-object fix);
- touch stick (commit `5af91c2` + its uncommitted Roblox-style follow-up);
- home cleanup;
- the top session's own changes:
  - **shorter warm-up** (`app.gd` `_warm_up()`: six headings, one frame each, then 8 steady frames; was a 1.6 s turn + 20 frames; native with shaders cached 1.65 s → 0.25 s, three alternating A/B runs each);
  - **[hidden features](../../README.md#hidden-features)** (`scripts/core/features.gd`: minimap, full map, hyper speed off; infinite jump off at start; the minimap alone measured 8.4 → 64 ms per frame while turning);
  - **the tutorial opening** on BonBon's close-up (`open_on`, `npc_presence.gd` `is_zoomed()`);
  - **a solid tutorial cast** (`HouseCharacters.fit_blocker()`).

Full town, isolated `HOME`, `tools/run_checks.py --only runtime_resources,app_flow,touch_controls,tutorial,interaction,profiles,compact_layout`, run once:
- PASS: `runtime_resources`, `app_flow`, `touch_controls`, `tutorial`, `interaction`, `profiles`.
- `compact_layout` NEW: the same 6 zoo "rigid move preserves scale" labels recorded twice below (not this change).

Rendered once (scratch, not kept): the first 3 s after loading and the zoom back after Next.
- They show the opening close-up on BonBon with her first line, then the player in bed again.
- No minimap; the place line sits in its corner.
- The loading screen's fade-out still shows the warm-up's street view for a moment before the tutorial's fade (known; warming up in the bedroom measured slower, see the shared notes).

Not done: web export, iPhone, the full suite, checks that use the hidden map (listed in the README).

## Graphics tiers: Low default, High kept — 14 November 2026

[Graphics tiers](performance/README.md#graphics-tiers-low-default-high-kept--14-november-2026)
(`render_culling.gd` `apply_graphics()`, `game_settings.gd` `graphics`, `day_night.gd`
`set_graphics()`, Settings "Graphics quality" and "Show FPS", `scripts/ui/perf_readout.gd`).
Full town (`dev_focus.txt` = `all`), isolated `HOME`. Other mobile sessions' uncommitted edits
(`app.gd`, `main.gd` + `indoor_visibility.gd`, touch controls, home) were in the tree.

- **Measured** with a scratch probe (main.tscn, noon, 40 warm-up + 90 frames per view,
  `Performance` monitors), 1280×800 on an M5: street at spawn High 1,392 → Low **585** draws
  (1.81 → 0.71 M triangles), looking back over the zoo 5,841 → 1,209, guest suite facing the
  house 5,169 → 1,947, supermarket 889 → 570. Full table in the performance guide. Not measured
  on an iPhone.
- **Rendered views inspected** (High and Low; street, looking back, guest suite both ways,
  supermarket, park overview, Settings with the readout): Low keeps the day light and colours,
  the far town fades into the sky-coloured fog, no shadows. Found and fixed: shortening every range
  made the church tower body vanish under its spire, so Low now shortens only ranges up to 80 m.
  The park overview (a free camera while the player stands in the supermarket) shows bare tree
  trunks on **both** tiers: indoor hiding hides the batched canopies but not the trunks
  (session B's `indoor_visibility.gd`; reported to it).
- **Checks, once each:** `runtime_resources` **PASS**; `app_flow` 23 checks, 0 failures, then
  Godot's exit abort (`recursive_mutex lock failed`, CRASH): render_culling had left a lambda
  connected to the static `GameSettings` singleton; replaced by a method, re-run once: **PASS**.
  `day_night` (4 new checks: Low is the default, no sun shadows at noon, depth fog opaque at the
  130 m far plane, High restored at runtime) all pass; **3 known failures** remain (47 lamp heads,
  expected 27; see the 13 November entry below), first run also with the exit abort, re-run: NEW
  only for those 3 labels. The 13 November `tutorial` exit abort recorded below was probably the
  same lambda.
- **Not done:** an iPhone measurement (`?perf=1`), the web export, the full suite.

## Indoor visibility: hide far, keep near — 14 November 2026

[Indoor visibility](performance/README.md#indoor-visibility-hide-far-keep-near--14-november-2026)
(new `scripts/world/indoor_visibility.gd`, four lines in `main.gd`). Full town
(`dev_focus.txt` = `all`), isolated `HOME`, native 1280×800 on an M5. Other mobile sessions'
uncommitted edits (graphics tiers, touch controls, app, home) were in the tree.

- **Measured** with a scratch probe (component off, then on, at the same spot; 45 warm-up +
  60 frames): home bedroom Low 2,045 → 1,389 draws (1.00 → 0.30 M triangles), High 7,956 →
  3,696 (4.19 → 1.39 M); supermarket and library unchanged within 5–72 draws (already below the
  street's 585 on Low). Table in the performance guide. The bedroom stays above the street
  figure: the rest is the home's own unbatched furniture and door frames (follow-up).
- **Rendered views** (one batch, Low): supermarket door from outside (all drawn); inside looking
  out of the front (far town hidden, the street in front real); doorway 3 m inside (all drawn
  again: the entrance has no door, found by the box-exit ray); the street after stepping out (all
  drawn); the guest-suite bedroom facing both windows (the home's own wing and the sea, nothing
  missing); the library looking out of its door (near street real). No wall of the current
  building was missing in any view. Teleporting between views gave 0.2–1.3 s first frames
  (loading); the slowest single chunk toggle was 0.6 ms.
- **Fixed during the pass:** a flat forecourt part was taken as the supermarket "building"
  (now the box must rise 2 m above the player), and shower curtains (doors of type "curtain")
  counted as exits.
- **Checks:** `run_checks.py --only tutorial,app_flow`: tutorial PASS, app_flow PASS.
- **Whole-object fix, same day (uncommitted at the user's request; not in 3a70d8a).** The
  graphics-tiers session saw bare trunks and missing bridge towers from a free camera over the
  park while the player was in the supermarket. Batches are now linked to the objects whose
  pieces they hold and hidden together with them (guide). One rendered batch (Low): free camera
  over the park with the player in the supermarket and again in the school (trees and bridges
  gone whole, ground, paths and pond kept; faint flower-bed edging stays, never hidden as its
  batches hold unowned pieces), the park side of the school (street and buses real, nothing half
  drawn), the guest-suite window, the supermarket inside looking out and the doorway (all drawn
  again). Bedroom Low 2,047 → 1,465 draws (0.43 M triangles; 1,389 before the fix, the price of
  keeping objects whole), supermarket 521 → 504, library 392 → 390. Measuring takes about 2.6 s
  of frames after loading. Tutorial check: PASS. app_flow: left to the top session's combined
  run. Done with the minimap and full map switched off (`main.minimaps` empty); the component
  never reads them.
- **Not verified:** an iPhone; walking through a doorway in real time (views were placed, not
  walked); buildings with doorless openings that are not on the box edge (e.g. the home's pool
  terrace) reveal only once the player is outdoors.

## PWA branch merged; home door heights — 13 November 2026

Merge of `claude/pwa-restructure-aa7be2` (profiles, input actions, startup flow, touch controls,
web app export, welcome tutorial) into `main`, and the user's request the same day to fix the
home's door sizes before the bake. Full town (`dev_focus.txt` = `all`), isolated `HOME`.

- **Conflicts.** `main.gd` (the branch's action-based keys, with main's "not during a minigame"
  guards for help, map and journal), `player_controller.gd` (the hand socket is created once and
  moved to the new arm when a profile's avatar replaces the model: `hand_hold.gd` `rebind()`),
  `base.gd` / `home.gd` step lists, `pinyin_zh.json`, `MINIGAMES.md`, this file. The two baked
  scenes were taken from main and re-baked: `base` gained `statue_word`, `home` gained
  `door_heights`.
- **Tutorial in the bigger home.** The branch's house act was placed in the old layout (its
  bedroom is now the guest suite's bathroom, its office the family bathroom). Re-placed in
  `data/tutorial.json`: wake in the yellow bedroom, friend 1 in the family bathtub, friend 2 in
  the guest suite (the old "office" role; the study is across the house). The branch's own curtain
  (`shower_curtain.gd`, step `shower_curtain`) duplicated the one main's furnishing put on the
  same tub and was dropped; the tutorial uses the home's `door_animator.gd` curtain.
- **Curtain badge.** A curtain's middle was 2.8 m above the floor, over the 2.6 m reach of E, so
  it could only be clicked: its badge now sits 0.9 lower (`door_animator.gd`).
- **Door heights (user: "back to original height").** Home step `door_heights`: the 11 door
  mounts return to scale 1 (6.45 → 3.58 world units tall, 2.06 wide as before; the player is
  about 2.3) and the 11 wall headers above them reach down to the old head line. Rooms, windows
  and ceilings keep the raised height. Room signs above the doors stay at their raised height.
- **Full suite, run once (`run_checks.py full --jobs 3`): 45 PASS, 2 KNOWN, 4 NEW, 1 TIMEOUT.**
  - `tutorial` NEW (the curtain was not the focused interactable): fixed by the badge change,
    re-run once alone: PASS, 38 checks.
  - `day_night` NEW (47 lamp heads, expected 27) and `bath_fixtures` TIMEOUT (home fixture
    counts, then a null node at `verify.gd:164`): both checks count the home's lamps and
    fixtures as they were before the home expansion and furnishing (`179a4e5`). Not caused by
    the merge; **not fixed** (priority: medium, update the two checks).
  - `compact_layout` NEW: the same 6 zoo "rigid move preserves scale" failures the branch
    recorded on 12 Nov. `language` NEW: only the known `restaurant.miss_also`. Neither is in
    `data/expected_check_failures.json`.
  - `rooftops` KNOWN, with one expected failure no longer failing (the chapel roof cap); the
    expected-failures file was not changed.
- Views rendered once with graphics, home only (`docs/evidence/home-doors-20261113/capture.gd`):
  bedroom door, front door, drawn bathtub curtain, wake-up spot, guest suite door and friend
  spot; inspected.
- Not tested: a play-through by hand, the web build after the merge, a real phone, the avatar
  swap while holding an item.

## Library book-sorting game — 13 November 2026

Rosa's game and the return cart ([design](TOWN_DESIGN_BRIEF.md#library-return-cart-and-book-sorting-game--13-november-2026)):
steps `return_cart`, `cart_frame`, `cart_spot` baked into `library.scn`; `library_session.gd`
rewritten. Godot 4.7.2, isolated `HOME`, each run once unless noted:

| Result | Checks |
| --- | --- |
| PASS | `docs/evidence/library-sorting-20261113/verify.gd` (new, runner `library_sorting`), graphics, `VT_FOCUS=library`: **30 checks, 0 failures**; headless in the runner (`VT_FOCUS=all`): PASS |
| PASS | runner (`VT_FOCUS=all`): `library_shelves` (its last check now expects the game's first line instead of the old congratulations), `signs`, `minigame_launcher` |
| NEW, not this work (1) | `language`: `restaurant.miss_also` placeholders (recorded above). The first run also flagged 7 Chinese characters without pinyin in the new lines (慢 剩 史 烹 飪 故 事); added to `pinyin_zh.json`, gone on the re-run |
| Fixed during the work | First renders: the cart's solid ends hid its books (now open frames, `cart_frame`); the NEW BOOKS header was saved as RETURNS because the bake restores a translated sign from its `sign_source` meta (`cart_frame` sets it). `library_shelves` then found the cart in the walk to the west computer desk (`cart_spot` moves it 1.05 forward). The sorting check's flourish test waited frames, which pass instantly headless; it now waits 0.8 s |

Renders (`docs/evidence/library-sorting-20261113/`): `new-books` (LIBROS NUEVOS header), `cart-idle`,
`cart-filled` (four books, Rosa behind), `gap-focus` (BonBon holding a book, "E" at a gap, Rosa's
cart_left line), `right-shelf` (sparks around a correctly shelved book), `shelved`.

Limits: the full suite was not run. Placing and checking were driven through the Interactables
and choices in code, not by walking and pressing keys in a played session; touch was not tried
on a device. Top-shelf gaps (about 2.7 m) were not judged for reach or visibility. `dev_focus.txt`
stayed `all`.

## Reusable components audit: plush eyes, blinking and gestures — 13 November 2026

Audit and consolidation of interaction and character behaviour ([guide](COMPONENTS.md)).
`plush_life.gd` is now the one owner of plush eyes, the sleep hold, the breathing swell and the
gestures (the player's lying pose, the napping house characters, the police lineup and the
mahjong players call it); Main's `plush_life` blinks every plush in group `figures` each 6-14 s;
gestures move the whole figure instead of the `Head` node; `hand_hold.gd toggle()` is the shared
take / put-back used by the book. Godot 4.7.2, isolated `HOME`, each run once:

| Result | Checks |
| --- | --- |
| PASS | `docs/evidence/plush-rig-20261113/verify.gd` (new, `plush_life` in the full suite; headless, `--fixed-fps 60`, `VT_FOCUS=home`): **22 checks, 0 failures** |
| PASS | `docs/evidence/hand-hold-20261113/verify.gd` (headless, `VT_FOCUS=library`): 19 checks, 0 failures |
| PASS | `tools/run_checks.py --only` (`VT_FOCUS=all`): runtime_resources, interaction, police_detective |
| NEW, fixed (1) | mahjong_table: "the scoreboard fits on screen" failed because a headless run has a 64 × 64 screen (score card at y 93.6 under a 92-high status card). A check fault, not a game fault, and not from this work: `play.gd` now sets a 1280 × 800 screen when headless and prints the measured rectangles. Re-run once (`VT_FOCUS=home`): **107 checks, 0 failures** (9 more than before: checks that only run at a usable screen size) |

Rendered views (`docs/evidence/plush-rig-20261113/`): `gestures.png` (standalone: rest, the old `Head`
shake / nod / tilt with the face sunk into the body and the ears detached, then the whole-body
shake / bow / lean); from the town with `VT_FOCUS=home`, posed at the peak of each move:
`npc-open.png`, `npc-blink.png` (Leo), `gesture-rest/shake/nod/tilt.png` (Bao at the mahjong
table), `player-lying.png` (eyes shut to slits, tail tucked).

Limits: the full suite was not run. The town views are posed stills, not the moving game: a
graphical run in a background window advanced timers too slowly for timed captures, so motion
and timing rest on the headless check. The lineup was not rendered (its blink and moves are the
same calls; `police_detective` passed). Blinking was not viewed on costumed or scene-saved
plushes (hospital doctors, shop staff) one by one. Nothing was baked; `dev_focus.txt` is `all`.

## Welcome tutorial controls — 16 November 2026

BonBon teaches turning the view and walking right after the player stands up
([guide](ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial), `wait` `view` / `move`,
`scripts/ui/tutorial_cue.gd`, `touch_controls.gd` `highlight_stick()`). Worktree session, full town
(`dev_focus.txt` = `all`), isolated `HOME`, `tools/run_checks.py --only
runtime_resources,language,touch_controls,tutorial`, run once:

- PASS: `runtime_resources`, `touch_controls`.
- `tutorial`: **113 checks, 1 failure**, "the cue goes after the view step": the new check's own
  expectation was wrong (the move step's cue starts in the same frame); the check now expects the
  move cue there. Not re-run.
- `language`: NEW, 2 labels: `restaurant.miss_also` (known since b3b6d10) and zh characters
  without a reading; five of those were this change's (周 螢 拇 搖 桿, added to
  `data/pinyin_zh.json`, not re-run); 備 版 質 素 暢 揭 喬 臥 桌 come from other work.
- Views (graphics, `docs/evidence/tutorial-controls-20261116/capture.gd`), inspected: `view-*` and
  `move-*`, keyboard and touch wording, 1280 × 800 and 844 × 390. The first batch's view cue had
  faint arrows on the bright wall; it got a dark pill and was rendered once more.
- Not tested: a real phone, the web build, a real finger drag or stick (the check calls
  `look_by()` and moves the player).

## Welcome tutorial — 12 November 2026

PWA restructure phase 6 ([guide](ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial)). Full town
(`dev_focus.txt` = `all`), isolated `HOME`.

- `tutorial` (new, full suite): 37 checks, 0 failures — a play-through of all three acts with
  simulated events, checkpoints, the board hold (no "!"), hidden house twins, studied words
  (shower curtain, apple, banana, statue), empty practice log, the avatar stand-in (Sunny →
  Bruno), Replay and Skip. Views rendered once with graphics: `docs/evidence/tutorial-20261112/`
  (wake, bathroom, friend, cutscene, shop, statue, journal), inspected.
- Bakes: `base` (only `WashingtonStatue` gained `word_key`) and `home` (only the 20 curtain
  nodes), both reviewed with `compare_scenes.gd`.
- Runner `--only runtime_resources,app_flow,profiles,tutorial,interaction,vocabulary_categories,
  vocabulary_translations,vocabulary_report,bath_fixtures,compact_layout`: 9 PASS; `compact_layout`
  NEW with the same 6 zoo "rigid move preserves scale" failures seen in phase 5 (not this change).
  `language`: only the known `restaurant.miss_also`.
- Found and fixed on the way: static render batching froze the curtain's cloth (meta
  `keep_own_draw`), and a face close-up started while another eased back returned to the wrong
  camera.
- Not tested: a real phone or touch screen, the web build of this phase, a full play by hand.

## Interaction system — 12 November 2026

One interaction path ([guide](ARCHITECTURE_REVIEW_PART1.md#interaction-system)): Interactable
components, one focus pass, the "E" badge, input claims; the old metas (`click_use`,
`click_play`, `click_hint`, `action_hint`, `label_phrase`), hover glow/label and per-system E
handlers are gone; home, airport and mystery re-baked (step `interaction_metas`). Godot 4.7.2,
isolated `HOME`, `VT_FOCUS=all`, `tools/run_checks.py --only` (21 checks), run once:

| Result | Checks |
| --- | --- |
| PASS (17) | runtime_resources, aircraft, zoo_vehicles, elevator_call_button, seats_swan_boats, vehicle_boarding, vehicle_doors, warehouse, warehouse_game, grammar_class, mystery_house, fitting_room, minigame_launcher, building_access, bath_fixtures, electrical_box, library_shelves |
| NEW, fixed (3) | interaction (fixture: the click now ray-casts at once, so it waits two physics frames after turning the physics-interpolated camera); practice_log (sits through the chair's interactable as it did through `try_sit()`: the check's panels lock controls, which E respects); hospital_remodel (landing call button reach 3.2 m, from the doorway; cabin buttons need aim and reach 4.2 m across the big cabin; the check's stand-in camera is given to the interaction controller). Re-run after the fix: PASS. After the two focus fixes below, interaction, minigame_launcher, mystery_house, library_shelves, warehouse_game (389 s, slower than its first 87 s), grammar_class and practice_log were re-run once: all PASS |
| NEW, not this work (1) | language: `restaurant.miss_also` zh has `{name}` that es/en lack (from b3b6d10) |

Rendered views (`docs/evidence/interaction-system-20261112/capture.gd`, graphics, `VT_FOCUS=home`, avatar
hidden): `npc-bang.png` (Mei's "!" from 8 m), `npc-e.png` (the "E" over her in range),
`faucet.png` (badge on the lever), `car-door.png` (Subi's driver door), `station-dot.png` (the
electrical box's dot). The first render found two focus bugs, fixed before the final images: an
NPC's range was measured to its head badge (above the 2.6 m rise limit when seated), and nearer
chairs outranked a calling NPC (now `CALL_BONUS`).

Limits: the full suite was not run; touch taps were checked through `badge_hit_area()` in
`check_interaction.gd`, not on a device. Baked `seated_hint` metas remain unused in the base,
playground and clothing units (harmless; removed at their next bake).

## One Mexican translation per word — 28 October 2026

`data/words.json` Spanish values only: 83 multi-option entries reduced to one and
14 single entries corrected to Mexican usage (decisions and flagged items in the
[word audit](../archive/WORD_AUDIT.md#one-mexican-translation-per-word--28-october-2026)).
Keys, aliases, categories and prefab sizes unchanged. Godot 4.7.2 headless with
`HOME` pointed at a scratch folder so learner saves were not touched.

| Check | Result |
| --- | --- |
| `tools/word_data.py` | 464 words, 12 aliases, 18 categories; valid |
| `check_vocabulary_translations.py` (now also rejects extra alternatives and shared translations) | PASS |
| `check_vocabulary_categories.py` | 90870 checks, 0 failures |
| `check_project.py` | `town_reference.tscn` parent errors, output identical with the old and new `words.json` (existing) |
| `check_runtime_resources.gd` | 326 resources, 0 failures |
| `check_vocabulary_aliases.gd` | PASS |
| `check_word_cleanup.gd` | 0 failures |
| `check_food_shopping_vocab.gd` | 6 failures: stale `== 500` word-count assertions (file has 464) and 4 "Clickable ray target" picks (credit card, meat, money, price). Popup translation checks passed. Not rerun against the old file, but none depends on the Spanish text |

Not done: no visual play-through; the on-screen text is the unchanged string from
`words.json`, so only the data and popup checks were run. World signs
(`sign_translations.json`) were not changed.

## Documentation changes

- `README.md`: current startup/world ownership, controls, data/save behavior,
  task navigation and safe verification instructions.
- Workspace `AGENTS.md`: concise instructions for targeted inspection, reuse,
  preservation, validation and ongoing documentation maintenance.
- `ARCHITECTURE_REVIEW_PART1.md`: retained assessment; added current coordinate,
  road, asset, interaction and vocabulary editing procedures.
- `LEARNING_UPDATE.md`, `MIGRATION.md`, `QA_REPORT.md`: marked older snapshots
  explicitly; preserved historical evidence.
- `docs/guides/public-garden/README.md`: linked current runtime refinements and verification.
- This record is the only new project documentation file; no new hierarchy.

## Checks performed

Godot **4.7.2**, macOS, GL Compatibility; headless physics checks used fixed 60 FPS
where appropriate. A temporary project configuration isolated learner data.
Python checks used Python 3. The following are actual Part 3 reruns:

| Check under `docs/` | Result |
| --- | --- |
| `check_runtime_resources.gd` | 305 resources; 0 failures |
| `docs/evidence/part2/verify.gd` | 694 assertions; 0 failures; 279 road samples |
| `check_interaction.gd` | Targeting, highlights, cards, signals, doors, dismissal and range passed |
| `check_bonbon.gd` | 0 failures |
| `docs/guides/performance/check_rendering.gd` | 0 failures |
| `check_public_garden.gd` | 2,004 path samples; 0 failures; bridge crossed both ways |
| `check_reference_home.gd` | Ten doors open/close with attached collision; no assertion errors |
| `check_food_shopping_vocab.py` | 345 checks; 0 failures |
| `check_transport_navigation_time.py` | 505 checks; 0 failures |
| `check_vocabulary_aliases.gd` | Fails its stale count assertion (469 words / 13 aliases); actual counts are 502 / 15. Other assertions reported no failures |
| `check_zoo_vehicles.gd` | 67 checks; same 20 failure labels as Parts 1–2 |
| `docs/guides/helicopter_inertia/verify.gd` | 15 checks; same 1 rotor-envelope failure as Part 1 |
| `check_vocabulary_categories.py` | Same 8 stale scene category tags |
| `check_vocabulary_translations.py` | Same 40 stale scene translation tags |
| `docs/evidence/part2/capture.gd` | Graphical startup succeeded; six fresh 1200×900 views rendered and inspected |

Road checks cover the five refined connections, surface/collision coverage and
lane-side samples; they do not simulate every possible vehicle route. Animal
checks cover all 20 ParkZoo picking Areas/cards, target dimensions, grounded
placement, retained transforms and repeat-pass guards. The current dictionary
remains 502 canonical entries with matching category mappings.

Rendered town/airport views show connected access roads. Washington retains the
pedestal and mounted silhouette; the snake's continuous body is visible; wildlife
has differentiated species sizes. Tiger primitives no longer have the prior large
spikes, though its stripe patches remain visibly angular. Fine shadow/paving
artifacts around the statue remain a possible future visual cleanup. These six
views are targeted evidence, not an exhaustive visual sweep of every interior.

## Limits and next priorities

1. **Movement reliability:** investigate the existing helicopter rotor-envelope
   failure and reproduce the vehicle suite failures interactively. Failures cover
   helicopter ascent/travel, exit/hyper restoration and driving/right steering
   for eight vehicles. Do not assume all are either gameplay bugs or test bugs
   without reproduction. They predate the refinements.
2. **Data/check consistency:** reconcile the 8 category and 40 translation caches
   in the reference/public-garden snapshots without rebaking unrelated content;
   runtime cards use authoritative dictionaries. Review the alias test's outdated
   count assertion. Older Python vehicle/general project checks have known stale
   assumptions/false positives (see the Part 1 assessment); they were not rerun
   here and are not evidence of a clean suite.
3. **Broader coverage:** run a manual drive/fly/exit and save/reload playthrough,
   then an export and measured performance test before release. Neither an export,
   FPS benchmark nor a complete manual playthrough was performed in this phase.
   Headless runs reported sandbox denial creating their isolated user-data folder
   and a host certificate lookup error; save persistence was therefore not
   validated. Graphical capture completed without those reported errors.

No gameplay scripts, scenes, assets, data, shaders, tools or project settings were
changed during Part 3 (verified by hashes). Documentation links were checked.
The capture check refreshed the six existing Part 2 PNGs; the inertia test writes
its existing result file. Temporary detailed logs were retained in
`/tmp/spanish-part3/` for this session, but are not durable project documentation.


## Appearance follow-up — 21 October 2026

This later change edits only `scripts/world/world_refinements.gd` for outdoor
materials and garden planting, plus the existing guides and three new rendered
images. The preceding 20 October record is historical and has not been rewritten.
Details and images are in the [handoff addition](../evidence/part2/HANDOFF.md#town-appearance-polish--21-october-2026).

Godot 4.7.2, macOS, Compatibility renderer. A temporary project configuration used
`VocabularyTownChecks/aesthetic-review` as its isolated custom user directory.
Resource loading (305 resources, zero failures) and the Part 2 checks (694
assertions, zero failures, 279 road samples) passed before the edits. Initial test
setup lacked the global class cache; copying the current class cache resolved those
setup parse errors before recording that baseline.

Actual checks after the edits:

| Check | Result |
| --- | --- |
| `check_runtime_resources.gd` | 305 resources; 0 failures |
| `docs/evidence/part2/verify.gd`, fixed 60 FPS | 694 assertions; 0 failures; 279 road samples |
| `docs/guides/performance/check_rendering.gd`, fixed 60 FPS | 0 failures; batching idempotent, map rebuilding and door animation checks passed |
| `check_public_garden.gd`, fixed 60 FPS | 0 failures; 2,004 path samples; bridge crossed both ways |
| Graphical capture, 1200×900 | Town, park, new planting close-up, monument, wildlife, snake, tiger, school/hospital frontage, home and airport rendered; town/park/planting/monument/frontage/home inspected |

Garden batching increased from 1,831 meshes / 174 spatial batches to 1,939 meshes /
191 batches. This verifies batching, not an FPS improvement; no performance
benchmark, export, full manual playthrough or save/reload validation was run in this
follow-up. Global lighting, building/interior transforms, doors, vehicle code,
vocabulary data and save formats were not changed. Existing vehicle and metadata
failures listed above remain unresolved and were not rerun for this visual pass.

## Home interior follow-up — 21 October 2026

The [home guide](REFERENCE_HOME.md#interior-reference-update--21-october-2026)
describes the supplied-image adaptation. Changes are confined to the runtime home
builder and its documentation; the saved world and shared sofa prefab are intact.

Godot 4.7.2 / Compatibility, temporary project at `/tmp/spanish-home-design`,
isolated custom user directory `VocabularyTownChecks/home-design`:

- Before editing: 305 runtime resources loaded with zero failures; all ten home
  doors passed sweep and animation checks.
- After editing: 305 runtime resources loaded with zero failures; all ten doors
  passed 13-position sweep checks and open/close animation with attached collision.
- `check_interaction.gd`: targeting, highlights, cards, signals, doors, dismissal
  and range passed.
- Rendered Main in graphical Godot; inspected an overhead view and the final
  [angled interior view](../evidence/town-checks/home-interior-design.png). The final angled capture also
  reran the ten-door check. Seating, dining furniture and the island are visible
  within the existing interior.

Headless runs reported isolated user-directory/log creation denial and host
certificate errors. The initial sandboxed graphical launch failed; the authorized
graphical retry completed. Save persistence, full manual walking coverage, exports,
performance and the full regression suite were not tested. Previously documented
vehicle and metadata failures remain unresolved and were not rerun here.

## Living-space correction — 21 October 2026

The user rejected the first furnishing-only adaptation. The subsequent
[layout correction](REFERENCE_HOME.md#living-space-correction--21-october-2026)
opens the former east suite into living/dining/kitchen space, retaining three
bedrooms, two bathrooms and the other eight doorways. The preceding ten-door
record and image describe the earlier layout and remain historical evidence.

Godot 4.7.2 / Compatibility, same isolated temporary test configuration:

- Baseline before this correction: all ten previous doors passed sweep/animation.
- Final resource loading: 305 resources, zero failures.
- Final home check: eight remaining doors pass all 13 swing poses and open/close
  animation; 191 player-width clearance samples pass along selected connected
  routes; four room-label assertions pass for living, dining, kitchen and entry.
- Interaction fixture: targeting, highlights, cards, signals, doors, dismissal
  and range pass.
- The actual runtime interior was rendered and inspected at close range. The
  [living-space preview](../evidence/town-checks/home-living-space.png) shows the enlarged seating group,
  connected dining/kitchen layout and pool-facing glazing.

The test routes deliberately go around furniture and the garage enclosure; they
are sampled clearances, not an exhaustive manual navigation playthrough. Headless
log-directory and host certificate warnings persist. No save/reload test, export,
performance benchmark or full suite rerun was performed. Existing vehicle and
metadata failures remain outside this interior correction.

## Town blueprint pass — 21 October 2026

Saved the original [user map](design-references/town-map-blueprint.png) without modification (source
and saved SHA-256 match). README and the building design blueprint now direct
future work to it. Runtime changes are in `world_refinements.gd`; the saved world,
building/interior transforms, vehicles and vocabulary data are not rebaked.
See the architecture guide for road dimensions and ownership.

The road loop is regularized, eight new front lots supplement five existing pads,
parking bays and crosswalks are marked, approach drives connect to the loop, and
basic building roof/corner outlines are added. Detailed facades and the map's full
landscaping are not part of this first pass.

Godot 4.7.2 / Compatibility, isolated temporary configuration:

| Check | Result |
| --- | --- |
| Baseline `docs/evidence/part2/verify.gd` | 694 checks, 0 failures; 279 driveway samples |
| Runtime resource loading | 305 resources, 0 failures |
| Expanded `docs/evidence/part2/verify.gd` | 2,403 checks, 0 failures; 897 driveway samples and 453 loop clearance samples; 13 parking areas |
| `docs/guides/performance/check_rendering.gd` | 0 failures; minimap rebuild, batching and hinge animation pass |
| `check_public_garden.gd` | 0 failures; 2,004 path samples, bridge crossed both ways |
| `check_reference_home.gd` | Eight door sweeps/animations and 191 interior clearance samples pass |
| Graphical views | Town overview, civic parking and bakery exterior rendered and inspected; final crosswalk orientation corrected and rerendered |

Views: [town](../evidence/town-checks/town-blueprint-pass.png), [parking](../evidence/town-checks/town-parking-pass.png),
[basic exterior outline](../evidence/town-checks/building-outline-pass.png). Road queries move registered
vehicles out of the test path; they verify geometry, not driving behavior. No
manual driving sweep, export, FPS benchmark or save/reload test was performed.
Headless isolated-log access and certificate warnings persist. The known vehicle
and cached vocabulary metadata failures above remain unresolved and were not rerun.

## Map-inspired exteriors — 21 October 2026

`building_exteriors.gd::decorate()` now runs after the blueprint outline pass.
The [building guide](BUILDING_DESIGN_BLUEPRINT.md#town-map-blueprint) lists the
per-building features. Existing footprints, physical roof surfaces, doors, interiors,
hospital helipad and parked vehicles are retained. The original map and prior
basic-outline screenshots remain separate historical artifacts.

Godot 4.7.2 / Compatibility, isolated temporary project configuration:

- Baseline and final resource loading: 305 resources, zero failures.
- `check_map_facades.gd`: zero failures; 20 facade groups present, 12 canonical
  vocabulary facade rays pass, no new static collision bodies, decoration
  idempotent, minimap rebuild passes.
- `docs/evidence/part2/verify.gd`: 2,403 checks, zero failures; 897 driveway samples and 453
  loop clearance samples, 13 parking areas.
- `check_reference_home.gd`: eight door sweep/animation checks and 191 shared-space
  clearance samples pass.
- Seven actual runtime views rendered and inspected: [town](../evidence/town-checks/map-facades-town.png),
  [civic buildings](../evidence/town-checks/map-facades-civic.png), [west shops](../evidence/town-checks/map-facades-west.png),
  [bakery](../evidence/town-checks/map-facades-bakery.png), [east shops](../evidence/town-checks/map-facades-east.png),
  [south/park buildings](../evidence/town-checks/map-facades-south.png), [airport](../evidence/town-checks/map-facades-airport.png).

This is a stylized facade adaptation within existing storey heights and usable
roofs, not an exact reconstruction of the illustration. Some distant roof/trim
edges retain aliasing from the existing renderer. Airport close-up crops part of
the control-tower cap; the overview shows the cap. No export, FPS benchmark, full
manual interior/roof traversal, vehicle-suite rerun or save-persistence test was
performed. Existing vehicle/metadata failures remain unresolved; headless isolated
log-directory access and host certificate warnings persist.

## Park trails, swan boats, home roof and taxi driver — 21 October 2026

Tested in the isolated `/tmp/spanish-home-design` project with its custom
`VocabularyTownChecks/home-design` user directory. Learner saves were not used.
The initial park baseline passed 2,004 samples and bridge/dock traversal.

- `check_runtime_resources.gd`: 305 resources checked, zero failures.
- `check_public_garden.gd`: zero failures, 2,004 path-clearance samples;
  bridge crossed in both directions, shoreline junctions and dock entry passed.
- `check_reference_home.gd`: eight doors with collision sweep/animation checks,
  191 interior-clearance samples, roof hidden inside/restored outside, zero
  garage drivers and one driver beside the taxi all passed.
- `docs/evidence/part2/verify.gd`: 2,403 checks, zero failures; 897 road samples, 453 loop
  clearance samples and 13 parking areas.
- Actual Compatibility-renderer views inspected and saved:
  [park trails](public-garden/park-trails.png),
  [swan boat](public-garden/swan-boat.png),
  [home roof](public-garden/home-roof.png),
  [taxi driver](public-garden/taxi-driver.png).

Trail centerlines are retained; this pass refines their widths, surfaces and
edges. Roof is decorative, with no landing collision. Boat remains a vocabulary
prop, not a rideable vehicle. No export, FPS benchmark, full manual gameplay or
save-persistence test was performed. Existing vehicle/metadata issues listed
above remain unresolved; this is not a full-suite clean result. Headless log
directory and host certificate warnings persist.

## Flyable turboprop — 21 October 2026

Added a single-engine aircraft at the existing runway, extending the shared
vehicle/boarding contract. Controls, physics limits, code provenance and retained
MIT license are in the [aircraft guide](aircraft.md). New canonical vocabulary:
`airplane / el avión`, Transportation; dictionary/category/catalog agree.

All engine checks used `/tmp/spanish-home-design` with its isolated user directory.
Before changing gameplay, `check_zoo_vehicles.gd` reproduced the known baseline:
67 checks, 20 failures. After implementation it again reports 67 checks and the
same 20 failure labels (compared with `diff`). Its legacy count/filter now excludes
fixed-wing vehicles, which have a separate flight test; existing assertions remain.

- `check_runtime_resources.gd`: 307 resources, zero failures.
- `check_aircraft.gd`: **30 checks, zero failures**. Actual Main instance and
  existing runway: registration, vocabulary physics targeting, clear parked
  envelope, E boarding, visible animated pilot seat placement, flap cycling,
  takeoff, airborne exit denial, correct bank/turn direction, 30 seconds assisted
  flight, 20 seconds powerless glide, speed-squared lift and post-stall loss,
  runway landing/braking, safe exit/collision restoration, engine shutdown,
  wingtip sweep, actual high-speed wing impact, recovery and unoccupied pause.
- Takeoff reached 4.04 world metres above departure after about 96.2 horizontal
  metres at 27.36 m/s. This fits the existing runway's remaining length from the
  spawn point. It is one deterministic test configuration, not all possible loads.
- Power-off glide from 25 m/s: speed 22.54 m/s and height 173.51 → 138.91 m after
  20 simulated seconds; specific mechanical energy decreased 2014.65 → 1616.82.
  A powered climb can initially keep climbing after idle by trading airspeed for
  height; the dedicated glide check starts at a suitable approach speed.
- `check_interaction.gd`: targeting, highlights, cards, signals, doors, dismissal
  and range passed.
- `check_reference_home.gd`: eight door checks, 191 clearance samples, roof
  visibility and taxi driver placement passed.
- Graphical Compatibility-renderer views inspected: [parked](../evidence/town-checks/aircraft-parked.png),
  [boarding step](../evidence/town-checks/aircraft-boarding.png), [visible pilot](../evidence/town-checks/aircraft-cockpit.png),
  [banked-flight appearance](../evidence/town-checks/aircraft-flight.png). The latter is a staged pose;
  real takeoff/flight/landing evidence comes from the separate simulation check.

Limitations: semi-realistic effective-wing forces with damped attitude controls,
not a full aerodynamic simulator; simplified ground support, no fuel/damage save,
no engine audio or cockpit camera. No export, performance benchmark, full manual
keyboard flight circuit or save-persistence test. Existing vehicle and cached
metadata issues remain unresolved. Host certificate/user-log-directory warnings
persist in headless isolated runs. This is not a full-suite clean claim.

## Helicopter physics rewrite — 22 October 2026

Replaced the helicopter's target-velocity/forced-attitude flight routine with
rotor blade forces, tail-rotor torque, gravity, air drag and body angular inertia.
The [current rotor guide](helicopter_inertia/README.md) documents control assistance,
dimensions, upstream source pin, retained MIT license and model limitations.
The existing helicopter instance/model, dictionary, world placement and player
boarding/camera systems remain in use. Main additionally displays rotor/collective
status through the existing flight HUD.

Baseline reproduced before implementation, using the isolated
`/tmp/spanish-home-design` project: inertia 15 checks/1 rotor-clearance failure;
motion 21 checks/zero failures; legacy zoo/vehicle suite 67 checks/20 failures.
Old inertia/motion suites describe the superseded flight model and are retained
as historical evidence, with current acceptance commands linked from their guides.
No historical result/capture files were overwritten in the project.

Current checks, Godot 4.7.2:

| Check | Result |
| --- | --- |
| `check_runtime_resources.gd` | 308 resources, zero failures |
| `check_helicopter_physics.gd` | 34 checks, zero failures |
| `check_zoo_vehicles.gd` | 69 checks, zero failures |
| `check_aircraft.gd` | 30 checks, zero failures |
| `check_interaction.gd` | Targeting, highlights, cards, signals, doors, dismissal and range passed |
| `check_vehicle_collision.gd` | Zero failures; eight road types block the player, allow walking around and remain selectable in the active town |

The 34 helicopter assertions cover actual hospital support/takeoff, physical spool
and rotor animation, gravity at low RPM, RPM-squared lift, collective authority,
cyclic pitch/roll moments, tail side-force/yaw, hover/drift braking, forward flight,
coasting, left/right turns, 30/60/120 Hz consistency, elapsed-time handling, full
rotor wall sweeps, 1,500 tiny drift steps at a wall, overhead/rotation clearance,
independent tail disk, tilted approach/three-wheel landing, safe exit, parked
stability, rotor shutdown, repeat takeoff and overlay pause.

The tiny-drift fixture stopped the root at x=501.0345 against a wall centered at
x=506.5, keeping the entire 5.265 m main rotor outside. After hover settling,
four-second vertical drift was -0.047 m and final horizontal speed about 0.087 m/s.
The default wind and anti-torque model can require a small hover bank.

The previous 20 legacy failure labels were partly a test sequence problem: one
0.2 s call was treated as a flight despite the old 0.05 s cap, and the test attempted
E exit without landing/stopping. A rejected exit left the helicopter occupied,
invalidating later road-vehicle tests. The current suite simulates normal physics
steps, performs a real landing on a fixture, checks actual active-vehicle ownership,
and brakes each road vehicle before exiting. It disconnects learning callbacks to
avoid writing study progress. No assertion was removed to obtain a pass; airborne
exit-denial and grounded-before-exit assertions were added. Road driving behavior
was not replaced as part of this helicopter change.

Actual graphical trajectory inspected with the Compatibility renderer:
[parked](helicopter_inertia/rotor-parked.png),
[hospital takeoff](helicopter_inertia/rotor-takeoff.png),
[banked flight](helicopter_inertia/rotor-banked.png),
[hospital landing](helicopter_inertia/rotor-landing.png).
The capture script confirms grounded=true, speed=0 and successful E exit at the
hospital after the flight; these are simulated flight states, not staged poses.

Limits: an assisted game rotor model and swept-contact resolver, not the full
upstream VehicleBody3D addon or a certified helicopter simulator. No full manual
keyboard flight circuit, export, performance benchmark or save-persistence run.
Previously documented cached category/translation and alias-check issues remain
outside this change; no full-suite clean claim. Isolated headless runs still print
host certificate and user-log-directory warnings.

Current ownership and references: [park guide](public-garden/README.md) and
[home guide](REFERENCE_HOME.md#roof-and-driver-placement--21-october-2026).

## Road vehicle physics rewrite — 22 October 2026

Replaced target-speed road motion and bumper rays with tire/engine/braking forces,
spring/damper wheel loads, yaw inertia, drag, gravity and full-body swept collision.
The [current road guide](ZOO_VEHICLE_IMPLEMENTATION.md) owns profiles, units, controls,
source pin and retained MIT license. Existing cars/taxi/police car/truck/bus/
ambulance/fire truck/motorcycle models and metadata are reused. Their existing
wheel roots animate together with their vocabulary targets. World scenes and
parked transforms were not rebaked or relocated by this change.

Baseline in the isolated `/tmp/spanish-home-design` project reproduced 69 passing
zoo/vehicle checks and zero road collision/picking failures before the rewrite.
Learner save identity and format are unchanged; tests use the isolated user path.

| Current check | Result |
| --- | --- |
| `check_road_physics.gd` | 125 checks, zero failures across all eight road types |
| `check_zoo_vehicles.gd` | 69 checks, zero failures |
| `check_helicopter_physics.gd` | 34 checks, zero failures |
| `check_aircraft.gd` | 30 checks, zero failures |
| `check_vehicle_collision.gd` | Zero failures; eight types remain solid/selectable and allow walking around |
| `check_runtime_resources.gd` | 309 resources, zero failures |
| `check_interaction.gd` | Targeting, highlights, cards, signals, doors, dismissal and range passed |

The 125 driving checks cover reused wheel/body/vocabulary roots, support, engine
acceleration, configured speed range, moving/stopped exit rules, coasting, service
brakes, automatic reverse, reverse steering, right turns, steering response,
overlay pause, differentiated vehicle profiles, braking before reverse, friction
limits, reduced-grip force response, 30/60/120 Hz agreement, elapsed-time handling,
front/rear offset-post collisions, collision-free stopped poses, turning body
swing, gravity after leaving a platform, airborne exit denial and R recovery.
The offset-post fixture stopped the car root at x=996.138 before a post at x=994,
with the full front corner outside; the old three center/bumper rays could miss
this offset. Acceleration after three seconds was 9.39 m/s for the car versus
4.61 for the bus and 5.42 for the truck, using their different engine/mass profiles.

The shared vehicle test now explicitly uses Space/service brakes before E exit,
matching the new coasting behavior; its exit assertion was retained. Shared sweep
helpers gained optional support-slab exclusions for road queries; default aircraft
queries are unchanged and both aircraft regression suites pass.

Actual graphical garage boarding, 8.95 m driveway exit, tire steering, turn,
service braking and successful on-foot exit were rendered and inspected:
[garage](../evidence/town-checks/road-garage.png), [driveway](../evidence/town-checks/road-driveway.png), [turn](../evidence/town-checks/road-turn.png),
[parked](../evidence/town-checks/road-parked.png). These are actual simulated states, not staged poses.

Limits: an assisted upright-body solver, with balanced motorcycle; no rollover,
full suspension attitude, independent driven-wheel slip/burnouts, gearbox/clutch,
engine audio, damage or dynamic collision impulse exchange. Steep-ramp handling,
full manual keyboard drive-through, export, performance and save-persistence runs
were not performed. Previously documented cached metadata/alias-check issues
remain outside scope; this is not a full-suite clean claim. Isolated headless runs
still emit the existing host certificate and user-log-directory warnings.


## Central trail blueprint follow-up — 22 October 2026

Godot 4.7.2, isolated `/tmp/spanish-trails-review` copy with custom relative user
folder `VocabularyTownChecks/trails-review`; personal learner saves were not used.
Initial tests before importing the temporary project failed to resolve global
script classes; after editor import, the baseline loaded 309 resources with zero
failures and passed the existing 2,004 park-clearance samples.

The runtime trail list now follows the map's statue/lagoon loops and connecting
walks within the main road. Ownership and exact scope are in the
[garden guide](public-garden/README.md#central-trails-matched-to-blueprint--22-october-2026).

| Executed check | Result |
| --- | --- |
| `check_runtime_resources.gd` after changes | 309 resources; 0 failures |
| `check_public_garden.gd`, fixed 60 FPS | 0 failures; 1,785 path samples; bridge both ways, shoreline junctions and dock entry pass |
| Added park assertions | Exactly two closed trail loops, named curve metadata, containment inside the road, eight connected junctions and repeat-refresh guard pass |
| `docs/evidence/part2/verify.gd`, fixed 60 FPS | 2,403 checks; 0 failures; 897 road samples, 453 loop-clearance samples, 13 parking areas |
| Compatibility renderer, 1400×1100 | Actual north-up district and bridge views inspected; flower-bed alignment corrected after initial visual review |

Saved evidence: [central trail layout](public-garden/blueprint-trails.png),
[bridge and shoreline connections](public-garden/blueprint-trails-bridge.png).
No full manual gameplay, full-suite rerun or performance benchmark was performed.
The map is adapted to the preserved building, habitat and lagoon positions;
it is not a pixel-for-pixel reconstruction of the illustration. Previous metadata
issues remain outside this task; see dated vehicle rewrite sections for current
vehicle status. Host certificate warnings remain in headless logs.


## Helicopter descent binding — 22 October 2026

Changed helicopter descent from physical Ctrl to physical Shift. Updated boarding,
vehicle HUD, exit guidance, help and current control documentation. Shift no longer
toggles walking sprint while occupying the helicopter; Space still climbs.
In the isolated `/tmp/spanish-trails-review` project, helicopter physics passed
34 checks both before and after the binding change; final resource loading passed
309 resources with zero failures. Inspected the physical-key input and sprint
routing; no manual keyboard flight test was performed. Physics checks inject flight
commands directly and do not establish hardware-key behavior. No full-suite claim.

## Word card movement dismissal — 23 October 2026

The interaction controller now closes the selected word card on the first physics
frame where the player's world position changes, independently of the 30 Hz hover
check and look-away grace period. This covers walking, jumping, noclip and vehicle
travel. Mouse movement alone retains the existing look-away behavior. The card hint
and README controls describe movement dismissal.

Godot 4.7.2, isolated `/tmp/spanish-popup-check` configuration: baseline and final
resource loading passed (309 resources, zero failures); baseline and extended
`check_interaction.gd` passed. New checks cover standing still, a 0.01-unit step
inside interaction range, vertical movement, immediate dismissal with a 1/120 s
update, and no automatic reopen or extra study notification. Graphical Compatibility
fixture captures were rendered and inspected with the real HUD: card visible before
movement and absent afterward. Evidence is in `/tmp/spanish-popup-check/popup-open.png`
and `/tmp/spanish-popup-check/popup-after-movement.png` (temporary files).

Headless runs emitted isolated user-directory/log access and host certificate
warnings. Graphical verification required running outside the sandbox after the
sandboxed launch exited 134. No full-town keyboard playthrough, save-persistence
check or full-suite rerun was performed; existing metadata issues remain outside
this change, and current vehicle results remain in the dated rewrite sections.

## Word card while moving — 23 November 2026

User: tapping the tiger while jumping did nothing. The 23 October movement dismissal (above)
closed the card on the first moving frame, so a card opened mid-jump or mid-walk vanished at
once. Now `interaction_controller.gd` notes whether the player was moving at the click
(`velocity` above `MOVING_SPEED`); such a card follows the player instead of closing, and once
they stand still for a frame the old rule applies again. Interactables were not affected.

`python3 tools/run_checks.py --only interaction`: **PASS** (0 failures). New checks: a click
while jumping opens the card, it stays open in the air and after landing, and the first step
after standing still closes it. The check's right-button events had left the pointer at (0, 0),
so the existing "Vertical movement dismisses card immediately" check passed without opening a
card; it now re-aims at the fixture and checks the card opened first. Not run: the full suite,
a rendered or on-device playthrough (behaviour-only change).

## Compact town redesign — 23 October 2026

Implemented the user's annotated compact-town request in the active runtime map,
using rigid site/habitat relocations after the existing refinements. The road loop
is now 215 × 135 town units (previously 215 × 195), a 31% reduction in its bounding
area. The approximate inner park is 199 × 119. Building sizes, the lagoon outline,
bridge and statue frame remain unchanged. The zoo is southeast, barn/farm southwest,
playground northwest and chapel northeast; southern library/restaurants/police and
inward-facing side shops concentrate activity around the park. Coastal margins,
parking, entrance connections, walking branches, map/mission bindings, wandering
origins and aircraft recovery position follow the new arrangement.

Source ownership, coordinate conventions and restart requirements are documented
in the [architecture guide](ARCHITECTURE_REVIEW_PART1.md#coordinates-roads-and-visual-standards).
No saved world was rebaked, and the shipped application/save identity is unchanged.

Validation used Godot 4.7.2, Compatibility renderer, and a temporary project copy
with `VocabularyTownChecks/compact` as its custom user directory. Before gameplay
edits, resource loading passed 309 resources; the existing Part 2 suite passed
2,403 assertions (897 driveway / 453 loop samples); garden walking passed 1,785
samples plus bridge crossings. The initial unimported test copy needed Godot's
editor import before class-name resolution worked.

| Final check | Actual result |
| --- | --- |
| `check_runtime_resources.gd` | 309 resources, 0 failures |
| `check_compact_layout.gd` | 706 checks, 0 failures; [compact validation](../evidence/part2/compact-validation.txt) |
| `docs/evidence/part2/verify.gd` | 1,572 checks, 0 failures; 534 driveway and 348 loop-lane samples; 13 parking areas |
| `check_public_garden.gd` | 0 failures; 1,638 walking samples; bridge crossed in both directions |
| `check_interaction.gd` | Targeting, highlights, cards, signals, doors, dismissal and range passed |
| `check_reference_home.gd` | 8 doors and attached collisions; 191 shared-space samples; roof visibility, taxi driver and room assertions passed |
| `check_aircraft.gd` | 30 checks, 0 failures; boarding, takeoff, flight, landing and recovery |
| `check_road_physics.gd` | 125 checks, 0 failures, all eight road vehicle types |
| `capture_compact_layout.gd` | Four fresh 1400 × 1100 graphical views; overview, park, shop fronts and southern frontage inspected |

Views: [overview](../evidence/part2/compact-overview.png), [park](../evidence/part2/compact-park.png),
[inward-facing shops](../evidence/part2/compact-shops.png), [southern frontage](../evidence/part2/compact-south.png).
To reproduce, run `godot --path . --resolution 1400x1100 --script res://docs/evidence/town-checks/capture_compact_layout.gd`
using the README's isolated configuration. This updates only the four compact views.

The Part 2 test now accounts for authorized rigid relocations rather than asserting
unchanged world positions. It retains species-size, picking, lane clearance and
physical-support checks; new parking collisions close an exposed police-pad gap.
The garage driveway correctly terminates on the home's garage floor. The compact
check verifies landmark geometry, scale, building separation, facing, live map
entries, mission locations, gate operation and pass idempotence.

Limits: no exhaustive manual visit to every interior, full vehicle-route drive-through,
export, save-persistence test or FPS benchmark. Road-physics tests include synthetic
fixtures and do not establish every town driving route. Known legacy vehicle and
cached category/translation issues remain recorded above; those legacy suites were
not rerun and this is not a claim that the full suite is clean. Headless runs still
reported sandbox log-directory and host-certificate errors; graphical runs completed
with access to the isolated test directory. Personal learner saves were not used.

## Documentation cleanup — 25 October 2026

`docs/README.md` now indexes current guides, historical implementation records,
verification tools and evidence, including the purpose of each. The project README
and workspace instructions point to it. Nineteen retained implementation records
now carry an explicit historical notice; their original results remain unchanged.

Removed nine superseded vocabulary reports (A1/A2, B1, science, deduplication,
category/translation audits, food/shopping and transportation expansion), seven
unused JSON removal/audit/validation artifacts, and the obsolete `QA_REPORT.md`.
Translation conventions were preserved in the architecture guide's vocabulary
procedure. The two additions manifests consumed by static checks remain in place.
The older QA filename and removed paths in dated records/manifests describe history,
not required current files.

Validation for this documentation-only change:

- 242 local Markdown links and heading anchors checked; zero missing targets.
- No executable GDScript/Python references to the 17 deleted files found under
  `scripts/`, `tools/` or `docs/`.
- `check_food_shopping_vocab.py`: 345 checks, zero failures.
- `check_transport_navigation_time.py`: 505 checks, zero failures.
- SHA-256 inventory comparison confirms project changes are limited to Markdown
  documentation and the seven deleted documentation JSON artifacts. Gameplay,
  scenes, data, assets, checks, tools and project settings are unchanged. Workspace
  `AGENTS.md` has only the documentation-map navigation update.

No Godot runtime, rendering, full-suite or save-persistence checks were run for this
cleanup. Earlier runtime results and known issues above retain their original scope.
This workspace has no Git repository; scope was checked against a before-edit file
hash inventory rather than a Git diff.

## Exterior audit — 25 October 2026

Documentation and inspection only: [town design brief, per-building audit and plan](TOWN_DESIGN_BRIEF.md).
Latest user decisions replace older school/hospital/supermarket design targets and
approve the future restaurant mapping. Existing aircraft and northwest playground
are retained. Conflicting active blueprint guidance was replaced; historical civic,
hospital and grocery records now explicitly identify their superseded design status.
No game scenes, interiors, vocabulary, settings or gameplay scripts were changed.

Executed with Godot 4.7.2, macOS Apple M5, Compatibility renderer, in
`/tmp/spanish-town-exterior-audit`, a temporary copy with custom user directory
`VocabularyTownChecks/exterior-audit-20261025`. The shipped application identity
and personal learner saves were not used. `docs/evidence/town-checks/check_runtime_resources.gd`,
`check_compact_layout.gd`, `docs/evidence/part2/verify.gd`, `check_public_garden.gd`,
`check_interaction.gd` and `check_map_facades.gd` were inspected for side effects.
Original resource/route/interaction tests do not write result artifacts; Main-based
checks load the isolated state. Existing capture scripts overwrite their output
images, so they ran only in the copy. Evidence was copied into
[exterior-audit-20261025](../evidence/exterior-audit-20261025/inventory.json).

| Executed check | Actual outcome |
| --- | --- |
| `check_runtime_resources.gd` | 309 resources, 0 failures |
| `check_compact_layout.gd`, fixed 60 FPS | 706 checks, 0 failures |
| `docs/evidence/part2/verify.gd`, fixed 60 FPS | 1,572 checks, 0 failures; 534 road samples, 348 loop-clearance samples, 13 parking areas |
| `check_public_garden.gd`, fixed 60 FPS | 0 failures; 1,638 path samples, bridge crossed both directions |
| `check_interaction.gd` | Targeting, highlights, cards, signals, doors, dismissal and range passed in its fixture |
| **Unmodified `check_map_facades.gd`** | **12 failures**, all `street ray picks new facade`: HOSPITAL, SCHOOL, SPORTS, FURNITURE, BAKERY _ CAFE, ELECTRONICS, CLOTHING, BANK, LIBRARY, POLICE STATION, SUPERMARKET, CHAPEL. Other assertions emitted no failures; 20 facade groups, 12 vocabulary rays. |
| Temporary transformed-ray diagnostic | Replacing only the two ray endpoint conversions from `town.to_global` to `front.to_global` yielded **0 failures**, 20 groups, 12 rays. Confirms the original check's pre-compact-coordinate assumption. The shipped test remains unchanged and still fails; this diagnostic is not a claim that it passed. |
| `capture_compact_layout.gd` | Four fresh 1400×1100 renders inspected: overview, park, shops, south |
| Temporary `capture_exterior_audit.gd` | 19 fresh 1200×900 context/front views and 19 entrance views; all contact sheets inspected. Tower appears in airport context. A scoped subtree metadata inventory was exported without scene saves. |

Exact logs and the two temporary diagnostic/capture sources are retained beside
images. To reproduce the additional capture **in an isolated project copy**, run:

```sh
godot --path . --resolution 1200x900 --script res://docs/evidence/exterior-audit-20261025/capture_exterior_audit.gd
```

That retained script writes `res://docs/audit-views/`; it does not overwrite the
archived dated evidence. It freezes game/player/interaction processing and adds
inspection cameras to the temporary runtime tree. No materials, roofs, interiors
or scene resources are changed by capture. The transformed-ray diagnostic is
`docs/evidence/exterior-audit-20261025/check_map_facades_transformed_probe.gd` and should also
run only with isolated data. It is a diagnosis, not the maintained regression test.

Limitations: entrance screenshots are not exhaustive interior walk-throughs; the
home shot is outside its door, and some civic/shop views are partially occluded.
No full manual door/vehicle traversal, all-side exterior coverage, FPS/draw-call
benchmark, export or save/reload check. Runtime batching reported 1,986 meshes in
196 spatial batches, not a performance acceptance budget. No claim of complete
vocabulary inventory or learnability coverage. Existing cached category/translation
and legacy vehicle failure records remain; those suites were not rerun. The full
suite is **not** clean. Initial headless execution could not create the isolated
user directory; the graphical authorized run created it. Headless runs also printed
the host-certificate lookup error; reported test outcomes above completed normally.

Priorities: P0 update the maintained facade test for final transforms in a separate
scoped task; P0 resolve school/supermarket dimensions before facade investment;
P1 approve the bakery/library exterior pilot. See the brief for the complete plan.

Documentation validation: 181 local file-link targets in changed/new Markdown checked,
zero missing files. A before/after SHA-256 inventory found changes only in the
project README and `docs/` (guides, dated images/inventory/logs and diagnostic
sources); no gameplay, scene, data, asset or project-setting changes.

### Building-position clarification — 25 October 2026

The user confirmed current building positions are good and building-size changes
are a later problem. The town brief and blueprint now preserve those approved
positions and defer sizing; school/supermarket size studies no longer block current
exterior planning. This supersedes the sizing priority in the audit above.
Documentation only; no game changes or runtime checks for this clarification.

## Building capacity review — 25 October 2026

Latest user instruction supersedes the earlier sizing deferral: evaluate and obtain
approval of dimensions before exterior work, while preserving approved positions.
[Measured review](BUILDING_DIMENSION_REVIEW.md) records all 18 building footprints,
heights, inner-face/floor-plate estimates, room programs, player-scale assumptions
and nearby parking/building constraints. Recommendations are not implemented.

Godot 4.7.2 headless measurement used the existing isolated audit project. SHA-256
comparison of 424 gameplay source/scene/data/asset/shader files found no differences
between that copy and the current project. Player global scale is 1, collision
radius .76 and height 2.2 world; Apartment remains 1.3. Captured architectural
mesh bounds in each facade's orientation, complete hospital-bed root bounds, and
16 downward site-support samples. These sparse samples do not certify the whole
terrain, setbacks or turning space.

Reruns: resource loading 309 resources, 0 failures; compact layout 706 checks,
0 failures. Headless host-certificate error remained. Logs, measurement script/JSON
and a visually inspected schematic budget diagram are in `docs/evidence/dimension-audit-20261025/`.
The diagram represents proposed allocations, not a Godot render or constructed
interior. Current rendered evidence is the unchanged prior exterior audit.

No gameplay/resource edits, resize, relocation, vocabulary or save changes. No
new furnished block-out, proposed-layout collision/camera test, performance run,
export, or full-suite pass. The older public-interior route test uses outdated
coordinates and a smaller capsule than today's player; do not use it to certify
new interior fit. Previously documented facade/metadata/legacy-vehicle issues
remain. Dimensional approval is followed by exact furniture and player-clearance
validation before shell construction.

### Dimensional approval — 25 October 2026

The user approved only the school 24 × 18 single-story and supermarket 26 × 26
dimensional targets from the capacity review. Other proposed changes, including
furniture shortening, airport height reduction and hospital-wing removal, remain
unapproved. Approval was recorded in the review, town brief and blueprint.
Documentation only; no resizing, relocation, interior or vocabulary edits, and
no runtime checks were needed for this approval record.

## Approved building resize — 25 October 2026

The user's subsequent implementation request authorized **only school and
supermarket resizing**. Current geometry and preservation details are in the
[dimension review](BUILDING_DIMENSION_REVIEW.md#implemented-resize--25-october-2026),
with current decision status in the [master blueprint](TOWN_DESIGN_BRIEF.md).
School is 24 × 18, single story, 4.6 clear height; market is 26 × 26 with 5.71
clear above its finished floor. Sites/front axes remain fixed. Runtime refinements
apply before outlines/facades/compact transforms; saved world/prefab inputs remain.

School retains all 47 original school-area canonical keys (including separately
baked fixtures and outdoor objects), and 38 indoor keys were ray-selected through
the real interaction controller from capsule-tested routes. Existing art/music/
geography content is provisionally retained within the two surviving classrooms;
this is not completion of the agreed future fit-out. Eight original desk sets
remain; redundant extra-floor furniture/structure was retired. An existing pencil
prefab repairs the previously absent target required by School Day. Quest IDs,
ordering, word requirements, radii and save format are unchanged; only school
marker positions/destination labels and the floor-location label adapt to the
new shell. The retained mascot now stands beside the front approach, clear of
supplies and the entrance. Nearby school NPCs/flower bed clear the new walls.

Pre-edit baseline: resources **309 / 0 failures**, compact layout **706 / 0**.
An additional pre-resize runtime inventory used the backed-up original three
world scripts and unchanged Main in the isolated copy; its fingerprints/keys are
saved in `docs/resize-20261025/baseline.json` (deleted 7 Nov 2026 with the retired October snapshot checks; in the old-history bundle). It is not regenerated from
the new implementation. The dimension check compares other buildings, site
frames, park/landmarks/vehicles and **301 unchanged supermarket components**
against that evidence. All **12 registered doors** remain. Geometry fingerprints
cover transforms, mesh bounds and collision bounds; they do not certify every
shader/material or dynamic behavior.

Godot **4.7.2**, isolated temporary project, separate custom learner directory:

| Check | Result |
| --- | --- |
| `docs/check_building_dimensions.gd` | **2,042 checks, 0 failures**: exact shell/floor/height measurements, protected geometry/content, current player capsule (radius .76, height 2.2 world), supported entry/hall/classroom/retail routes, 121 underlying-ground samples excluding the new market floor, selection within school mission radii, and resize idempotence. |
| `docs/evidence/town-checks/check_runtime_resources.gd` | **309 resources, 0 failures**. |
| `docs/evidence/town-checks/check_compact_layout.gd` | **690 checks, 0 failures**. Count decreased because obsolete school roof/trim nodes were removed; no assertions removed. |
| `docs/evidence/town-checks/check_map_facades.gd` | **0 failures**, 20 fronts, 12 vocabulary facade rays. Corrected its pre-compact bounds → final facade transform mismatch; the original 12-failure audit evidence remains historical. |
| `docs/evidence/town-checks/check_interaction.gd` | Passed targeting, highlights, cards, signals, doors, dismissal and range. |
| `docs/evidence/part2/verify.gd` | **1,572 checks, 0 failures**; 534 road samples, 348 loop samples, 13 parking areas. |
| `docs/evidence/town-checks/check_public_garden.gd` | **0 failures**, 1,638 path samples; bridge traversal both directions. |
| `docs/evidence/town-checks/capture_building_dimensions.gd` | Graphical Compatibility renderer, Apple M5: nine final views captured. Fronts, entrances, site context, player-scale interiors and explicitly roof-hidden diagnostic cutaways inspected. |

Logs and final PNGs are in [resize-20261025](../evidence/resize-20261025/). The final dimension
and graphical checks include the last display-orientation and mascot-clearance
corrections. Other regression checks preceded those local school-prop adjustments.
Initial headless runs printed isolated-log-directory permission and host-certificate
errors; final headless runs used explicit `/tmp` log paths and retained only the
host-certificate warning. The graphical run completed without script errors.

Limits: route tests sample physics with the actual capsule; they are not a full
manual keyboard/mouse walkthrough or certification of every possible camera orbit.
Player-scale captures use a diagnostic perspective camera. No export, full-session
save/reload, performance benchmark, full nine-department fit-out or full school
equipment program was tested. Batching reports 1,986 meshes / 196 garden batches,
not an FPS acceptance result. Existing cached category/translation and legacy
vehicle issues remain; the full historical suite is **not** claimed clean.

Next: approve a concrete exterior scope and preserve these shell dimensions.
Detailed interior furnishing and permanent vocabulary-primary-location decisions
remain separate stages; all other proposed resizes remain unapproved.

## Supermarket exterior — 25 October 2026

User-authorized scope: **supermarket exterior only**, at its implemented 26 × 26
footprint / 5.71 clear height and existing site/orientation. Result is implemented
for user review; **do not proceed to other buildings until that review**.
Design intent and ownership: [master brief](TOWN_DESIGN_BRIEF.md#supermarket-exterior-review--25-october-2026).

`building_exteriors.gd::finish_market()` replaces the generic small-shop facade
branch for this building. Added broad framed stylized glazing, one blue primary
sign fascia, a clear central canopy/portal, small entrance/cart labels, a light
shelter over the existing carts, neutral wall/plinth skins, panel joints and slate
roof/edge finish. Superseded non-learning ornament meshes are hidden, with their
original collision/picking trees retained. Main's primitive/material helpers and
existing picking preparation are reused; no new textures/shaders/downloaded assets.

Before capture and resource baseline were taken before source edits. The focused
baseline records the already-resized game, separately from the earlier resize
baseline. It was recorded again against the backed-up **original pre-exterior
script** to include parking clearance samples, never against the new facade.
The initially proposed straight parking route hit the parked truck at 16 of 89
samples; the final check verifies the exact existing clear/blocked pattern instead
of asserting that occupied parking is pedestrian-clear. The center pedestrian
approach and entrance are explicitly clear and supported with the actual capsule.

Godot 4.7.2, isolated test project/custom learner directory, explicit `/tmp` engine
log paths. Final production source matches the tested copy. Results:

| Check | Executed result |
| --- | --- |
| Pre-edit `check_runtime_resources.gd` | 309 resources, 0 failures. |
| `check_supermarket_exterior.gd` | **596 checks, 0 failures**. Unchanged site frames and geometry of other buildings/vehicles/landmarks; unchanged appearance of the other 19 facades and the school; all 301 existing market components retain geometry/transforms. Every original market collision path/transform/shape/enabled state, vocabulary-root transform/visibility/key, market-display appearance, mission ID/word list/order and 12-door registry retained. 89 frontage clearance results match baseline; approach and entrance clear/support samples pass; new skin stays in original roof/awning envelope; facade pass remains idempotent. |
| `check_building_dimensions.gd` | **2,042 checks, 0 failures**, including 26 × 26 envelope, 5.71 clear height, entry/aisle routes, protected contents and underlying ground. |
| `check_runtime_resources.gd` | 309 resources, 0 failures. |
| `check_map_facades.gd` | 0 failures; 20 fronts, all 12 vocabulary facade rays pass. |
| `check_compact_layout.gd` | 690 checks, 0 failures. |
| `check_interaction.gd` | Passed targeting, highlights, cards, signals, doors, dismissal and range. |
| `capture_supermarket_exterior.gd` | Six final PNGs: before/after street, wider town context and elevated frontage, using identical camera transforms, projection/FOV/size, resolution and lighting. Actual Compatibility renders visually inspected. Initial sign occlusion/label scale corrected before final captures. |

The focused exterior check and final capture include the final sub-unit roof-edge
adjustment inside the existing envelope; other checks preceded that visual-only
trim adjustment. Evidence, baseline, logs and source/camera hashes are in
[supermarket-exterior-20261025](../evidence/supermarket-exterior-20261025/). The capture script
takes `-- --before` for the before folder; never rerun it on today's source and
overwrite the original before views. The baseline-record flag likewise requires
the actual pre-change source, not a new expected result from the implementation.

Limits: wide glazing is opaque stylized glass over the original physical walls;
it does not create new openings. No interior/display layout, dictionary/category/
translation/save schema, road, parking or other-building source was changed.
No full manual playthrough, export, persistence round trip, night review or FPS
benchmark. Existing metadata/legacy-vehicle issues remain; the full historical
suite is not claimed clean. Headless runs retain the known host-certificate
lookup message; graphical capture completed without script errors.

Future work: user visual review and any requested supermarket refinement. The
nine-department interior and all other building work remain separately scoped.

## School exterior — 25 October 2026

The next explicit user request authorized **school exterior only** after the
supermarket. The result is implemented for review; **stop at the school until
the next user review**. [Design record and matching views](TOWN_DESIGN_BRIEF.md#school-exterior-review--25-october-2026).

`building_exteriors.gd::finish_school()` replaces the generic facade for the
single-story school. Added a warm brick base with restrained coursing, plaster,
framed entry-area windows and three classroom-side window groups per side,
green roof fascia, a small supported canopy, centered SCHOOL sign, compact wall
clock, shallow paved apron and two low decorative planters. The old tall clock
decoration is no longer generated for this shell; its compact replacement stays
below the existing roof. All new geometry is outside the unmodified provisional
interior. Front glazing is opaque stylized glass over the original entry walls;
side frames preserve and organize the existing classroom-side glass bands.

The former market-specific coordinate helper names are now `building_part()` /
`building_lettering()`, reused by the two actual facade users. Their calculations
and supermarket output are unchanged. The picking preparer skips only explicitly
tagged new school paving/planting, which adds no dictionary key or interactive
target. Original picking, controls, door registry and mission state are preserved.

Baseline captured **before edits**, from the already-resized Main scene in the
isolated test project. Original source hash, baseline JSON, logs and six final
images are in [school-exterior-20261025](../evidence/school-exterior-20261025/). Tests used
Godot 4.7.2, isolated learner directory and explicit `/tmp` engine log paths.

| Executed check | Result |
| --- | --- |
| Pre-edit `check_runtime_resources.gd` | 309 resources, 0 failures. |
| `check_school_exterior.gd` | **795 checks, 0 failures**. Exact original school core appearance/geometry, site frame/props, every original collider path/transform/shape/enabled state, people and mascots, school/market keys, mission requirements/order and 12-door registry retained. Other building geometry and appearances, including all other 19 facades and the completed supermarket, match baseline. Exterior has no new StaticBodies; roof width/rear/height envelope retained; new planting has no Areas. Actual player capsule clears supported parking-to-entry/canopy/hall and both classroom openings; facade guard remains idempotent. |
| `check_building_dimensions.gd` | **2,042 checks, 0 failures**. School 24 × 18, one story, 4.6 clear height; all original school-area keys retained; 38 indoor nouns selected through the real controller, including school mission selections inside mission radii. Supermarket approved dimensions/content retained. |
| `check_runtime_resources.gd` | 309 resources, 0 failures. |
| `check_map_facades.gd` | 0 failures; 20 building fronts, all 12 vocabulary facade rays pass. |
| `check_compact_layout.gd` | 690 checks, 0 failures. |
| `check_interaction.gd` | Passed targeting, highlights, cards, signals, doors, dismissal and range. |
| `capture_school_exterior.gd` | Three before/after pairs: street, wider context, and elevated frontage/classroom side, with identical cameras, projection/FOV/size, resolution, lighting and five-frame settle. Actual Main/Compatibility renders visually inspected, not saved-editor screenshots. |

No scene, asset, data, project setting, player/controller or world-refinement
source changed. The sole gameplay source edit is `building_exteriors.gd`.
Tested source matches production; no interior/furniture/learning-object transforms
were changed. Original buses, paths, hedges, flowers and mascot stay in place.
The 3.6-town / 4.68-world entrance and 4.6-town / 5.98-world clear height are
preserved; canopy underside stays above the original 3.5-town entry header.
The actual player capsule is 1.52 wide × 2.2 high world.

Limits: no full manual keyboard/mouse or camera-orbit sweep, night review, export,
save/reload round trip or FPS benchmark. Route/interaction tests and diagnostic
fixed-camera renders are the executed evidence. Existing metadata/legacy-vehicle
issues remain; no clean full historical-suite claim. The older supermarket
appearance baseline deliberately predates this school facade, so its school
appearance assertions are snapshot-specific; this task's baseline verifies the
supermarket itself unchanged. Headless runs retain the known host-certificate
lookup message; graphical capture completed without script errors.

Future work: user review and any requested school refinement. Full classroom
equipment/furnishing and further building exteriors remain separately scoped.


## Café and bank exteriors — 25 October 2026

User explicitly requested café and bank after accepting the school result. Scope
is `Buildings/BakeryCafe` and `RelocatedSites/Bank` exterior only; restaurant Cafe
is unchanged. [Design changes and five matching view pairs](TOWN_DESIGN_BRIEF.md#café-and-bank-exterior-review--25-october-2026).

The sole gameplay source edit is `scripts/world/building_exteriors.gd`. Existing
14 × 22 café / 12 × 15 bank shells, roof geometry, site frames, original collisions,
interior displays, vocabulary, people, missions and doors remain unchanged. Safe
legacy non-learning/non-solid bank ornament is hidden. No new solid body or key.
New glazing is opaque decorative skin over unchanged walls. Bank ATMs remain inside.

Checks used the isolated `/tmp/spanish-town-exterior-audit` project with its custom
learner directory; production save identity/settings were not changed. All 424
script/scene/data/asset/shader files compared byte-identical against that test copy.
Evidence: [dated logs, source hashes, original baseline and PNGs](../evidence/cafe-bank-exteriors-20261025/).

| Check | Result |
| --- | --- |
| `check_cafe_bank_exteriors.gd` | **965 checks, 0 failures**. Pre-change core appearance, content, colliders, other buildings and facades preserved; actual player capsule clears supported café approach/interior spine and bank approach/lobby; facade pass idempotent. |
| `check_building_dimensions.gd` | **2,042 checks, 0 failures**; includes approved school/market dimensions and 38 school noun selections through the controller. |
| `check_runtime_resources.gd` | **309 resources, 0 failures**, both baseline and final. |
| `check_map_facades.gd` | **0 failures**, 20 fronts, 12 vocabulary facade rays. |
| `check_compact_layout.gd` | **690 checks, 0 failures**. |
| `check_interaction.gd` | **PASS** targeting, highlights, cards, signals, doors, dismissal and range. |
| `capture_cafe_bank_exteriors.gd` | Ten 1200 × 900 actual Main/Compatibility PNGs: matched street and elevated frontage for each building plus shared context. Identical cameras/projection, lighting and five-frame settle. All five after views visually inspected against before views. |

An initial diagnostic incorrectly used a slash-containing facade display name;
Godot sanitizes it. The test now selects ownership by `source_building` metadata.
Only the incorrectly included café facade entry was removed from the pre-change
other-building baseline; protected core values were not regenerated from new code.
The corrected focused check passed. This was a diagnostic issue, not a gameplay bug.

Known host-certificate messages remain in headless logs. Historical cached-metadata
and vehicle issues remain unresolved; this is not a clean full-suite claim. Earlier
school/market appearance baselines intentionally predate these authorized facade
changes and were not regenerated. No full manual playthrough, vehicle flight,
save/reload, performance benchmark or export verification in this stage. Future
interior programs, true glazing openings and outdoor bank ATM placement remain
separate work. Stop for user review before another building.

## Supermarket color refinement — 26 October 2026

User scope: a slightly more colorful supermarket exterior. Only material colors
in `building_exteriors.gd::finish_market()` changed. See the
[master design update](TOWN_DESIGN_BRIEF.md#supermarket-color-refinement--26-october-2026).

Verified with Godot 4.7.2 in `/tmp/spanish-market-color-20261026`, using the
isolated custom learner directory `VocabularyTownChecks/market-color-20261026`.
Resource loading passed before and after: **309 resources, 0 failures** each.
The existing supermarket preservation check passed **596 checks, 0 failures**
against a separate baseline recorded before this color edit, including current
school/café/bank appearance, market collision/content, entry route and facade guard.
The historical 25 October baseline was not changed. The reused check/capture scripts
in [evidence](../evidence/supermarket-color-20261026/) only change their baseline/output paths;
run them from that directory in an isolated project for this dated comparison.

Matched before/after Main captures at 1200 × 900 used Compatibility on Apple M5.
After street, elevated front and town-context views were visually inspected:
colored entry reads clearly, signage is legible and restrained accents fit the town.
Tested production-script SHA-256, baseline, logs and six PNGs are retained in evidence.

Headless runs retained the existing host-certificate warning. The initial sandboxed
graphical attempt exited 134; desktop rendering succeeded with elevated execution.
No manual gameplay walkthrough, full suite or performance benchmark was run for
this material-only change. Previously documented vehicle and cached metadata issues
remain unresolved; this does not claim a clean full suite.

## Supermarket interior — 26 October 2026

Scope: authorized nine-department supermarket fit-out, preserving the implemented
shell/exterior and other buildings. [Design and ownership](TOWN_DESIGN_BRIEF.md#supermarket-interior-review--26-october-2026).
Tested in the existing isolated `/tmp/spanish-market-color-20261026` project with
custom learner directory `VocabularyTownChecks/market-color-20261026`; production
application identity and personal saves were not changed.

| Check | Executed result |
| --- | --- |
| Pre-edit resources | The immediately preceding color-pass baseline: 309 resources, 0 failures. |
| `check_market_interior.gd` | **2,449 checks, 0 failures**. Retained learning-root/child-geometry fingerprints, protected other-building/vehicle/facade fingerprints, shell dimensions, door count and mission words. Actual player capsule sampled at .25 spacing through entry, cross aisles, multiple lateral tracks in connecting aisles, dry goods, cold cases, fresh counters and checkout. Floor support, new-fixture bounds, per-key reachable controller rays and dictionary cards, nine departments and repeat guard pass. Grocery apple/milk/bread mission completion tested at new departments. |
| `check_runtime_resources.gd` | **309 resources, 0 failures**. |
| `check_compact_layout.gd` | **690 checks, 0 failures**; site/mission bindings, vehicle registration and compact guards. |
| `check_map_facades.gd` | **0 failures**, 20 fronts and 12 vocabulary facade rays. |
| `check_interaction.gd` | Passed targeting, highlights, cards, signals, doors, dismissal and range. |
| `capture_market_interior.gd` | Actual Main, Compatibility renderer / Apple M5, 1200 × 900. Five matched before/after views: entry, fresh counters, aisles, checkout, roof-hidden diagnostic plan. Additional final player-height view (1.65 town units) inspected. Finished counter guards, stocking, two-sided signs and lighting visually inspected. |

The preservation baseline was first captured before source edits. Its initial
fingerprint included auto-generated node names, which shift when new nodes are
created; the corrected fingerprint uses class/ordered geometry instead. The
baseline was remeasured from restored **pre-interior sources**, not the new fit-out;
the initial baseline is retained as `baseline-v1-generated-names.json`. Individual
small subparts can be occluded by their parent prop; the final interaction contract
is a reachable selectable representative for every retained interior word key,
while all original learning-root/child fingerprints are checked separately.

[Evidence](../evidence/market-interior-20261026/) retains baseline, source hashes, logs and
renders. The final focused check includes the final frozen-stock and counter-guard
additions; compact/map/interaction checks preceded those local visual/stock changes.
Headless runs retain the known host-certificate warning. No manual keyboard/mouse
walkthrough, exhaustive camera-orbit check, export or performance benchmark was
performed. Older pre-interior display-transform assertions are superseded for this
scope, not rerun/rebaselined as passing. Known cached-metadata and legacy vehicle
issues remain unresolved; no full-suite-clean claim is made. User visual review
is the next step; other building interiors remain outside this task.

## School single-divider layout — 26 October 2026

User scope: remove all interior partitions and replace them with one centered wall
from the rear to the depth midpoint, leaving the front half open. Exterior walls,
24 × 18 footprint and 4.6 height remain unchanged. [Current plan and implementation](TOWN_DESIGN_BRIEF.md#school-single-divider-layout--26-october-2026).

`world_refinements.gd::resize_school()` no longer creates the two classroom-front
walls, two hall walls or two classroom doorway headers. It creates one .2 × 4.6 × 9
divider at local (0,2.3,1.3), spanning z=-3.2..5.8. The whiteboard, notice, biology
plaque and mountain artwork are remounted on the existing front exterior wall;
general/science labels move to the rear. Furniture, teaching keys, doors, NPCs,
site transforms, mission definitions and other buildings are preserved.

Godot 4.7.2, isolated `/tmp/spanish-school-wall-20261026` project, custom learner
directory `VocabularyTownChecks/school-wall-20261026`. Production project identity
and saves were not changed. Checks do not write learner progress.

| Check | Executed result |
| --- | --- |
| Before/after `check_runtime_resources.gd` | **309 resources, 0 failures** both runs. |
| `check_school_partition.gd` | **1,075 checks, 0 failures**. Current pre-change baseline preserves other sites/facades/vehicles, school exterior/shell, furnishings and learning-node geometry, mission definitions and door count. Four explicitly remounted props allow position-only changes. Confirms exactly one interior mesh wall, correct midpoint/rear endpoints and dimensions, full-height rear collision, and idempotent guard. Actual player capsule sampled every .2 town units through the front entrance, full front crossing, three center crossings and along both sides of the divider; ground support passes. All four remounted displays remain selectable through the real interaction controller. |
| `check_compact_layout.gd` | **690 checks, 0 failures**. |
| `check_map_facades.gd` | **0 failures**, 20 fronts and 12 vocabulary facade rays. |
| `capture_school_partition.gd` | Four matched before/after Main views at 1200 × 900, Compatibility / Apple M5: open-front interior, lateral crossing, exterior and roof-hidden floor plan. Rendered views inspected. |

[Evidence](../evidence/school-partition-20261026/) contains the new pre-change baseline, logs,
matching PNGs and tested-source hashes. The [current annotated plan](../evidence/school-partition-20261026/floor-plan.png)
is a wall-only schematic, distinct from the furnished runtime cutaway. The baseline
was measured from the original pre-edit script, including after refining the
comparison to exclude all six superseded partition/header roots (some had generated
names). Historical resize/exterior baselines and their reported results were not
rewritten. Their old center-hall/unchanged-interior assertions are superseded for
this task; use the new school check rather than regenerating those baselines.

Limits: no manual keyboard/mouse walkthrough, exhaustive camera-orbit audit,
performance benchmark or full-suite run. Headless runs retain the known macOS
host-certificate warning. Previously documented metadata and legacy vehicle issues
remain unresolved; no full-suite-clean claim. The future detailed school equipment
program remains outside this partition-only change.

## Hospital interior remodel — 26 October 2026

Implemented the user's first-floor quadrant arrangement and approved three-floor
program. Compact 30.26° stairs and an enclosed three-stop elevator share aligned
cores. Existing rear learning wing, bed assets, helipad/helicopter, vocabulary data,
saves and site placement are retained. See [hospital guide](HOSPITAL_THREE_FLOORS.md)
for exact ownership, room mapping, controls, source/license and screenshot method.

Validation used Godot **4.7.2**, GL Compatibility, and an isolated project copy with
`VocabularyTownChecks/hospital-remodel` user data, leaving learner saves separate.

| Check | Result |
| --- | --- |
| Before changes: runtime resources | 309 resources; 0 failures |
| Before changes: historical hospital stairs | Actual player ascended/descended both storeys; 0 failures |
| Updated runtime resources | 310 resources; 0 failures |
| `check_hospital_remodel.gd` | 717 checks; 0 failures: actual player room/stair/gallery/rear routes; all-floor elevator entry/ride/exit; physical button click, number keys and hall E call; obstruction reversal and absent-cabin landing collision; retained word keys |
| `check_hospital_learning.gd` | All 24 retained learning-wing displays: passages, ray targeting and Spanish study cards pass |
| `check_interaction.gd` | Targeting, highlights, cards, signals, doors, dismissal and range pass |
| `check_helicopter_physics.gd` | 34 checks; 0 failures, including hospital support/takeoff |
| Saved-world preservation comparison | Every retained node/resource block byte-identical to pre-remodel snapshot, including wing, helipad and unrelated sites; only obsolete hospital override blocks/editable paths removed |
| Graphical Main inspection | Three annotated floor cutaways and entrance/stair/elevator views rendered and inspected; final graphical route test also passes |

The repeated door-closed assertions during travel contribute to the 717 count;
it is not a count of 717 independent test cases. Floor screenshots hide roofs,
upper storeys and facade for inspection and park the cabin at each depicted floor.
Actual hallway, stairs and elevator perspective views retain normal geometry.

Known limits: no full-project suite, long-session stress, gamepad, navigation-AI,
export-platform or performance certification was performed. Existing unrelated
vehicle/metadata issues recorded earlier are not claimed resolved. The old
`check_hospital_floors.gd` routes are historical and superseded for this layout.
Initial sandboxed headless runs emitted macOS log-directory/certificate warnings;
the isolated elevated final hospital/learning and graphical runs completed cleanly.

## Hospital surface and stair usability repair — 26 October 2026

Supersedes the earlier compact-switchback geometry and its centerline-only usability
evidence. Full Main inspected in graphical Godot 4.7.2, Compatibility, with isolated
learner saves. No world rebake or player-controller changes.

- Hospital route/elevator suite: **717 checks, 0 failures**.
- Normal W/controller stair access: **0 failures**, front/rear approaches on all
  three floors, offset ascent lanes and descent. Graphical default pitch -0.22:
  672 flight samples, spring-arm minimum 2.0703 and median 5.9236 world units
  (requested distance 6.5). A second pitch -0.35 run also passed.
- Learning wing: **24 displays, 0 failures**, passages, picking and cards.
- Runtime resources: **310 checked, 0 failures**.
- Interaction fixture: PASS targeting, highlights, cards, signals, doors, dismissal/range.
- Helicopter physics: **34 checks, 0 failures**.
- Final cutaway capture: 23 setup checks, 0 failures; visually reviewed floors 1–3.
- Reviewed full-geometry front, side, rear, hall, stairs, and normal player views.
  Final annex bands close the exterior seams that exposed rail fragments.

Limits: camera collision still retracts at nearby walls; the stationary upper-landing
view measures 2.0549 vs 1.0824 at the former switchback landing. These are different
landing geometries, not a claim that every possible camera orbit is unobstructed.
One earlier input run lost movement after another Godot window was launched; isolated
graphical reruns passed. Run input tests without a competing focused Godot window.
Sandboxed headless logs contain environment log-directory/certificate warnings.
The broad legacy regex `check_project.py` is **not clean**: 3,013 diagnostics in the
pre-screenshot-copy run, including generated output-path prefixes and legacy saved
scene parent/load-step checks. They are not equivalent to runtime load failures;
this repair does not certify or repair that whole-project checker.

Current dimensions, ownership and test commands: [hospital guide](HOSPITAL_THREE_FLOORS.md).
Visual evidence: [exterior](../evidence/hospital-surface-review/front-left.png),
[normal ascent](../evidence/hospital-surface-review/player-ascent1.png),
[upper landing](../evidence/hospital-surface-review/player-arrival3.png),
and [floor cutaways](../evidence/hospital-remodel/floor1.png).

## Lighting and sky pass — 27 October 2026

Main's environment (`scripts/core/main.gd`, after `world_refinements.gd`) now uses a
procedural gradient sky instead of a flat background color, light depth haze
matched to the sky horizon, a warmer and slightly stronger sun (0.49 → 0.62), and
color grading of brightness 0.83 → 0.90, saturation 0.96 → 1.10 and contrast 1.08.
Ambient fill stays a warm color at 0.50: sky-sourced ambient was tried and washed
out interiors in the Compatibility renderer. Ownership and tuning notes:
[performance guide](performance/README.md#lighting-and-sky).

Godot 4.7.2, macOS, GL Compatibility, Apple M5, in a temporary copy with an
isolated user directory:

| Check under `docs/` | Result |
| --- | --- |
| `check_runtime_resources.gd` | 310 resources; 0 failures |
| `docs/guides/performance/check_rendering.gd` | 0 failures |
| `docs/evidence/part2/verify.gd` | 1,572 checks; 0 failures; 534 road samples |
| `docs/guides/performance/benchmark.gd` (2 runs each) | Median 18.5 → 19.9 ms; p95 18.8 → 20.3 ms; draw calls 8,301 → 8,305 |

The benchmark cost is about 1.4 ms per frame on this machine (roughly 54 → 50 FPS in
the fixed bridge view); a fog-disabled run was too noisy to attribute it to haze or
sky. Six fixed views were inspected before and after with
`docs/evidence/lighting-sky-20261027/capture.gd`: [street](../evidence/lighting-sky-20261027/after/street.png),
[aerial](../evidence/lighting-sky-20261027/after/context.png),
[horizon](../evidence/lighting-sky-20261027/after/horizon.png),
[supermarket](../evidence/lighting-sky-20261027/after/market.png),
[hospital](../evidence/lighting-sky-20261027/after/hospital.png) and
[home](../evidence/lighting-sky-20261027/after/home.png); matching `before/` images sit beside
them. Interiors are only slightly brighter: their flat look comes from uniform
materials, which this pass does not change. Other suites were not rerun.

## Vegetation Phase 0 — 27 October 2026

Audit and proposed implementation only; stop here for user approval. No gameplay,
vegetation, vocabulary, shader or saved-world changes. Full ownership inventory,
baked/live counts, Spanish species names, zone placement and data procedure:
[performance guide](performance/README.md#vegetation-audit-and-proposed-phases--27-october-2026).

Current Main contains **52 trees, 151 outdoor shrub/planter clumps and 14 hedge
sections**, plus five grass/lawn surfaces. The saved snapshot has 48 trees;
runtime planting adds four trees, 35 shrubs and seven beds, while school/café
facades add four shrubs and the rebuilt Home removes one old shrub and lawn.
Six library foliage lobes belong to two indoor plants and are excluded. Prefix-only
counts miss automatically named runtime siblings; loop counts and instantiated
parent contents were also inspected. Garden batching reports **1,986 meshes in
196 spatial batches**. The historical handoff's six beds/three accent trees do not
match this current run.

Checks ran in `/tmp/vocabulary-vegetation-phase0`, copied without `.godot`, with
`config/use_custom_user_dir=true` and relative custom name
`VocabularyTownChecks/vegetation-phase0`. Original project identity and learner
saves were not changed. Initial sandboxed startup could not create the test user
directory; checks were rerun with filesystem access, and those final logs are retained.

| Baseline check | Result |
| --- | --- |
| `check_runtime_resources.gd` | 310 resources; 0 failures |
| `docs/guides/performance/check_rendering.gd` | 0 failures |
| `check_public_garden.gd`, fixed FPS 60 | 0 failures; 1,638 path samples; bridge crossed both directions |
| `docs/evidence/part2/verify.gd`, fixed FPS 60 | 1,572 checks; 0 failures; 534 road samples; 348 loop-clearance samples |

These are targeted passes, not a clean full-suite claim. Known legacy vehicle,
alias-count and cached metadata issues remain outside this audit; vocabulary and
vehicle suites were not rerun because no implementation/data changed.

Graphical `docs/guides/performance/benchmark.gd` was run unchanged with Godot 4.7.2,
Apple M5, GL Compatibility, 1280×720, VSync off, its fixed bridge camera, HUD on,
40 warm-up frames and 120 measured frames:

| Run | Median ms | p95 ms | Draw calls | Primitives |
| --- | ---: | ---: | ---: | ---: |
| 1 | 20.096 | 22.319 | 8,307 | 1,861,031 |
| 2 | 6.936 | 8.039 | 8,167 | 1,826,031 |
| 3 | 20.167 | 21.176 | 8,301 | 1,859,217 |
| 4 | 21.212 | 24.043 | 8,305 | 1,860,601 |

**Recorded baseline summary: 20.132 ms**, the median of the four run medians
(approximately 50 FPS). Keep all four observations: run 2 is a large unexplained
outlier and had fewer rendered primitives; some baseline checks were still running
during that attempt. Run 3 printed its measurements but stalled at the subsequent
screenshot stage before eventually completing; the sequential fourth run and
five-view capture completed afterward. Do not attribute this variability to a
vegetation change. There is no post-change measurement yet.

The requested cumulative budget gives a provisional **22.132 ms** ceiling under
matching conditions. Because this session was variable, use paired unchanged-copy
and changed-copy runs in each implementation phase and report both absolute values
and deltas; resolve anomalous runs before claiming compliance. Benchmark the same
viewport and foreground/window conditions, with no simultaneous test workload.
The 40-frame warm-up and single view also limit generalization across the island.

[Raw benchmark/check logs](../evidence/vegetation-20261027/) are retained with the
[fixed-camera capture script](../evidence/vegetation-20261027/capture.gd). All five 1200×900
before images were opened and inspected:
[overview](../evidence/vegetation-20261027/before/overview.png),
[pond](../evidence/vegetation-20261027/before/pond.png),
[park beds](../evidence/vegetation-20261027/before/park.png),
[road frontage](../evidence/vegetation-20261027/before/frontage.png),
[shore/building edge](../evidence/vegetation-20261027/before/shore.png).
They show flat bright lawn surfaces, repeating rounded tree silhouettes, highly
regular bed borders and sparse foundation/shore planting. The frontage view has a
large foreground trunk; it is useful for tree scale and roadside clearance rather
than a full facade review. These are before evidence only, not visual acceptance
of the proposed work. No commit or rebake was performed.

## Vegetation Phase 1: grass — 27 October 2026

Following user approval, implemented one shared GL Compatibility grass material on
the five active lawn/ground surfaces. `world_refinements.gd::grass_surfaces` assigns
it after compact layout; minimap/atlas retain an explicit green fallback. The
material combines a muted green base with two subtle world-space noise scales.
The first visual draft was too mottled from above; broad modulation was reduced
from 0.16 to 0.08 and fine modulation from 0.045 to 0.025 before final captures and
performance measurement. No blades/clumps, gameplay, vocabulary, geometry,
collision, trees, bushes, lighting or saved-world edits. Implementation/tuning
ownership is in the [performance guide](performance/README.md#shared-grass-material--phase-1-27-october-2026).

Validation used separate `/tmp/vocabulary-grass-baseline` and
`/tmp/vocabulary-grass-changed` project copies with custom relative user directories
`VocabularyTownChecks/grass-baseline` and `VocabularyTownChecks/grass-changed`.
A first sandboxed import could not write editor/test-user settings; subsequent
checks and captures ran with access to the isolated test directory and their logs
contain no errors. Personal learner saves and shipped identity were untouched.

| Check | Result |
| --- | --- |
| `check_runtime_resources.gd` | 310 resources; 0 failures |
| `docs/guides/performance/check_rendering.gd` | 0 failures, including shared grass assignment, post-batch visibility, map color fallback and retained beach material |
| `check_public_garden.gd`, fixed FPS 60 | 0 failures; 1,638 path samples; bridge crossed both directions |
| `docs/evidence/part2/verify.gd`, fixed FPS 60 | 1,572 checks; 0 failures; 534 road samples |
| Final GL Compatibility captures | Five fixed views rendered and visually inspected; no shader errors |
| `git diff --check` | Passed |

The four suites ran on the implementation before the final noise-strength-only
adjustment; final shader compilation/appearance and performance were then checked
graphically. Garden batching remains **1,986 meshes / 196 batches**. Known unrelated
vehicle/metadata/alias-count issues remain outside this work; this is not a full
suite or export certification.

Two sequential paired runs of unchanged `docs/guides/performance/benchmark.gd`, with
1280×720, GL Compatibility, Apple M5, VSync disabled, 40 warm-up/120 measured frames,
HUD enabled and its fixed bridge camera:

| Pair | Unchanged median / p95 | Grass median / p95 | Median delta |
| --- | ---: | ---: | ---: |
| 1 | 19.886 / 20.640 ms | 19.612 / 20.685 ms | −0.274 ms |
| 2 | 19.845 / 20.091 ms | 19.699 / 21.548 ms | −0.146 ms |

Median of run medians: **19.866 → 19.656 ms (−0.210 ms)**. This is no measurable
median regression, not proof of a speedup. Compared with the Phase 0 recorded
20.132 ms summary, Phase 1 is **−0.476 ms**, within the cumulative approximately
+2 ms budget. The second p95 increased by 1.457 ms; retain that variability in
future comparisons. Draw calls: baseline 8,305 / 8,304; grass 8,304 / 8,307.
Primitive counts remain approximately 1.861 million. `--quit-after 240` bounded
each graphical run to avoid the earlier post-measurement capture stall; the
benchmark's warm-up and 120-frame timing code were unchanged. No checks ran
concurrently with these four measurements.

[Phase 1 raw logs and after images](../evidence/vegetation-20261027/phase1/) accompany the
unchanged [fixed cameras](../evidence/vegetation-20261027/capture.gd). Five before/after pairs
were opened and inspected: overview, pond, park, frontage and shore. Grass shows
soft tonal variation without obvious seams/tiling, with clearer distinction from
pale paths; soil beds, beaches and buildings retain their previous materials.
The effect is deliberately restrained at walking height. Examples:
[before park](../evidence/vegetation-20261027/before/park.png) /
[after park](../evidence/vegetation-20261027/phase1/after/park.png),
[before overview](../evidence/vegetation-20261027/before/overview.png) /
[after overview](../evidence/vegetation-20261027/phase1/after/overview.png).

Phase 1 is ready for review. No commit, branch change, push or rebake was performed.
Tree and bush implementation have not started.

## Vegetation Phase 2: tree species — 27 October 2026

Eight species scenes, a runtime zone pass and ten Nature vocabulary words; see the
[tree species guide](performance/README.md#tree-species--phase-2-27-october-2026).
Vocabulary is now 513 canonical words and 179 catalog records (aliases unchanged at
15): oak/el roble, pine/el pino, palm tree/la palmera, birch/el abedul, weeping
willow/el sauce llorón, cherry tree/el cerezo, cypress/el ciprés, maple/el arce,
apple tree/el manzano, orange tree/el naranjo. No quest references changed.

Godot 4.7.2, macOS, GL Compatibility, Apple M5, temporary copy with an isolated
user directory:

| Check | Result |
| --- | --- |
| `docs/evidence/vegetation-20261027/phase2/verify.gd` | 0 failures: 52 trees, all eight species present, no generic garden/willow/old-maple trees left, every species tree teaches its word from at least one crown approach and `tree` from its solid trunk, ten fruit trees retained |
| `check_public_garden.gd` | 0 failures; 1,638 path samples; bridge crossed both ways (same as Phase 1) |
| `check_runtime_resources.gd` | 319 resources; 0 failures |
| `docs/guides/performance/check_rendering.gd` | 0 failures |
| `docs/evidence/part2/verify.gd` | 1,572 checks; 0 failures; 534 road samples |
| `check_interaction.gd` | PASS |
| `check_vocabulary_categories.py` / `check_vocabulary_translations.py` | Same 8 / 40 pre-existing stale-scene-tag failures as the previous commit, compared line by line; counts rose to 513 words / 179 records |
| `check_vocabulary_aliases.gd`, `check_vocabulary_categories.gd` | Still fail their stale hard-coded 469-word counts; the `.gd` category check's allowed list also lacks the existing `Time` and `Directions` labels. Not caused by this change |
| `docs/guides/performance/benchmark.gd`, two paired runs | Median 19.65 / 19.78 → 20.38 / 20.27 ms (about +0.6 ms); draw calls 8,305 → 8,449; garden batches 196 → 245 |

The nearest garden trunk is 3.1 units from a walk centerline; generic garden trees
previously had no solid trunk, and the walking suite passes with the new colliders.
Overlapping grove crowns can make a ray from one side pick the neighbouring tree,
which is why the check accepts any of four approaches. Visual evidence:
[species lineup](../evidence/vegetation-20261027/phase2/lineup.png),
[close-ups](../evidence/vegetation-20261027/phase2/lineup-close.png),
[conifers and palms](../evidence/vegetation-20261027/phase2/lineup-close-right.png), and fixed
views in `docs/evidence/vegetation-20261027/phase2/before/` and `after/` (pond, park, frontage,
overview, shore). Bushes (Phase 3) are not started.

## Vegetation Phase 3: bushes — 27 October 2026

Four bush scenes and a runtime refit/addition pass; see the
[bush guide](performance/README.md#bushes--phase-3-27-october-2026). Vocabulary is
now 515 canonical words and 183 catalog records (aliases unchanged at 15): new
`rose bush`/el rosal and `fern`/el helecho, plus catalog records for the shrub,
hedge, rose bush and fern prefabs. No quest references changed.

Godot 4.7.2, macOS, GL Compatibility, Apple M5, temporary copy with an isolated
user directory:

| Check | Result |
| --- | --- |
| `docs/evidence/vegetation-20261027/phase3/verify.gd` | 0 failures: no old border/bed/hedge clumps left; 174 bushes; every pickable bush teaches its word from at least one of five approaches; no bush has a StaticBody; facade planter shrubs have no study area; hedges keep cached Spanish; 16 additions, all outside the lagoon and at least 3 units from walk centerlines |
| `docs/evidence/vegetation-20261027/phase2/verify.gd` | 0 failures. Trunk picks now try ankle height and 60% of trunk height from four sides, because bushes can stand in front; one trunk (`Garden grove tree17`, a cypress whose short trunk sits in its own foliage beside a planting bed) is fully shielded and is listed, capped at two |
| `check_public_garden.gd` | 0 failures; 1,638 path samples; bridge crossed both ways |
| `check_runtime_resources.gd` | 324 resources; 0 failures |
| `docs/guides/performance/check_rendering.gd` | 0 failures after raising the batch bound to 400 (316 batches); it failed the old bound of 250 |
| `docs/evidence/part2/verify.gd` | 1,572 checks; 0 failures; 534 road samples |
| `check_interaction.gd` | PASS |
| `check_vocabulary_categories.py` / `check_vocabulary_translations.py` | Same 8 / 40 pre-existing error lines as the Phase 2 commit, compared line by line |
| `docs/guides/performance/benchmark.gd`, two paired runs against Phase 2 | Median 20.09 / 19.98 → 20.67 / 20.56 ms (about +0.6 ms); draw calls 8,449 → 8,592; primitives 1.92 M → 2.11 M |

Cumulative vegetation cost is about +0.5 ms median versus the Phase 0 recorded
baseline (20.13 ms), inside the plan's 2 ms budget. Evidence: [bush lineup](../evidence/vegetation-20261027/phase3/lineup.png),
[school entrance before](../evidence/vegetation-20261027/phase3/school-entrance-before.png) /
[after](../evidence/vegetation-20261027/phase3/after/school-entrance.png), and fixed views in
`docs/evidence/vegetation-20261027/phase3/after/`; the matching "before" views are Phase 2's
`phase2/after/` images. Foundation planting at blank facade ends was not added:
facade geometry was not audited for it, so hedges and planters stay at their
existing spots.

### Foundation planting follow-up — 27 October 2026

Six clumps at the blank front-wall ends of the school, hospital and supermarket; see
the [bush guide](performance/README.md#foundation-planting--27-october-2026). This
supersedes "Foundation planting at blank facade ends was not added" above.
`phase3/verify.gd` now also checks that garden plus foundation additions stay
within 24 (16 + 6) and that foundation bushes are at least 2 units from entrance
hedges: 0 failures (180 bushes, 176 pickable). Reruns with 0 failures:
`phase2/verify.gd` (same one shielded trunk), `check_public_garden.gd` (1,638
samples), `check_runtime_resources.gd` (324), `docs/guides/performance/check_rendering.gd`,
`docs/evidence/part2/verify.gd` (1,572), and `check_interaction.gd` PASS. Two paired benchmarks
against the Phase 3 commit: median 20.56 / 20.89 → 20.86 / 20.72 ms (within noise),
draw calls 8,592 → 8,628. Before/after views of the three fronts are in
`docs/evidence/vegetation-20261027/phase3/foundations-before/` and `foundations-after/`.

## Spanish world signs — 27 October 2026

134 world labels now show Spanish from a 98-entry table and switch back with the
HUD's English mode; see the [Spanish signs guide](spanish-signs-20261027/README.md).
52 labels shrink; the smallest are FRUTAS Y VERDURAS (52%, for PRODUCE), VESTÍBULO
PRINCIPAL and TECNOLOGÍA (59%) and RADIOGRAFÍA (63%);
seven fixed views were inspected before and after (`docs/guides/spanish-signs-20261027/before`,
`after`): supermarket front, aisles and entry, school, library, police station and
bank. All inspected signs fit their panels; most small interior labels were not
individually rendered.

Godot 4.7.2, macOS, GL Compatibility, temporary copy with an isolated user directory:

| Check | Result |
| --- | --- |
| `docs/guides/spanish-signs-20261027/verify.gd` | 0 failures: Spanish by default; English → Spanish → Both round trip restores text and font size on all 134. Remaining labels with English-looking words are Spanish, proper names or codes (TAXI, PIZZA, PASTA, WASHINGTON) |
| `check_runtime_resources.gd` | 325 resources; 0 failures |
| `docs/guides/performance/check_rendering.gd`, `docs/evidence/part2/verify.gd` (1,572), `check_bonbon_ui.gd`, `docs/evidence/vegetation-20261027/phase3/verify.gd` | 0 failures |
| `check_interaction.gd` | PASS |
| `check_building_exteriors.gd` | Fails "Front ray: hospital" both before and after this change (pre-existing) |
| `check_market_interior.gd`, `check_supermarket_exterior.gd`, `check_school_partition.gd` | Already failing against their 26 October baselines before this change (16 / 242 / 47); now 44 / 254 / 75 because their fingerprints hash label text, which this change intentionally rewrites (for example POLICE → POLICÍA). Rebaseline only when that area is next intentionally changed |

## Supermarket accents and stock — 27 October 2026

Department accent colours (sign boards, floor inlays, wall bands) and 205 decorative
shelf items in the pantry gondolas and refrigerators; see the
[design brief note](TOWN_DESIGN_BRIEF.md#supermarket-interior-review--26-october-2026)
and [ownership](ARCHITECTURE_REVIEW_PART1.md#supermarket-interior-ownership--26-october-2026).
Six fixed views were inspected before and after with `capture_market_interior.gd`
(copies in `docs/evidence/market-accents-20261027/before` and `after`).

Godot 4.7.2, macOS, GL Compatibility, temporary copy with an isolated user directory:

| Check | Result |
| --- | --- |
| `check_runtime_resources.gd` | 325 resources; 0 failures |
| `docs/guides/performance/check_rendering.gd`, `docs/evidence/part2/verify.gd` (1,572), `docs/guides/spanish-signs-20261027/verify.gd` | 0 failures |
| `check_interaction.gd` | PASS |
| `check_market_interior.gd` | Same 44 failures as the previous commit (stale 26 October baseline, sign text); 2,449 → 2,464 checks, the 15 new ones pass |
| In-store frame time (entry camera, 1280×720, 120 frames, two paired runs) | Median 8.56 / 9.34 → 8.85 / 8.88 ms (within noise); draw calls 1,132 → 1,184; stock 205 items in 24 batches, shadows off |

Not changed: other interiors (hospital, school, home, library, shops). The garden
`docs/guides/performance/benchmark.gd` view is outdoors and does not include the store.

## Hospital colours, floor signs and elevator facing — 27 October 2026

Interior palette (warm walls/floors, a colour per floor and per room), floor signs at
the elevator, stairs and hall, an oak/colour-coded stair finish, and the elevator
rotated to open onto the central hall; layout, stair geometry/collision and the
exterior are unchanged. See the
[hospital guide](HOSPITAL_THREE_FLOORS.md#colours-floor-signs-and-elevator-orientation--27-october-2026).
`tools/build_hospital_remodel.py` regenerated `hospital.tscn` (the unmodified
generator reproduced the committed scene byte for byte first). No saved-world
overrides target the main hospital floors or elevator.

Godot 4.7.2, macOS, GL Compatibility, temporary copy with an isolated user directory:

| Check | Result |
| --- | --- |
| `check_hospital_remodel.gd` | 717 checks; 0 failures: every room, both stair directions, gallery, rides to all three floors, physical button, obstruction reversal, absent-cabin doors, hall call. Elevator walking points now use `lift_point()` (elevator-local) |
| `check_hospital_learning.gd` | 24 displays; 0 failures |
| `check_hospital_stair_access.gd` (graphical, real W input) | Flaky before and after: new version 1 clean run of 4, previous commit 1 clean run of 3; every other run had one "Normal W movement blocked" at varying inner-landing/rear-hall points. The guide already notes that focus can drop injected W input; the deterministic route suite above passes |
| `check_hospital_floors.gd` | Same 14 failures as before (superseded switchback routes) |
| `check_runtime_resources.gd` (325), `docs/guides/performance/check_rendering.gd`, `docs/evidence/part2/verify.gd` (1,572), `docs/guides/spanish-signs-20261027/verify.gd` | 0 failures |
| `check_interaction.gd` | PASS |
| Hospital hall frame time (1280×720, two paired runs) | 11.2 / 11.8 → 13.0 / 7.2 ms (noisy, no clear change); draw calls 6,122 → 6,311 |

Exterior views (front, front-left, rear) were compared before and after: only the
room colours seen through the windows differ. Refreshed guide renders:
`docs/evidence/hospital-remodel/` cutaways, stairs, elevator, entrance and
`docs/evidence/hospital-surface-review/` hall/stair/exterior views; the `player-*` stair-access
captures were not regenerated. New review views are in
`docs/evidence/hospital-colours-20261027/after/`; baseline images of the same areas are in
`before/` (the dedicated capture script hangs on the old scene's third view, so
the baseline comes from the existing inspection captures).

## Hospital rear extension removed — 27 October 2026

The single-storey rear extension (prefab, four room scenes, `check_hospital_learning.gd`)
was deleted, and its saved-world overrides were removed from
`town_public_garden.tscn` (1,568 node blocks and 29 editable paths, deletions only;
the school's extension and every other override are untouched). Its 24 displays
now live in the matching rooms; see the
[hospital guide](HOSPITAL_THREE_FLOORS.md#department-displays-from-the-former-rear-extension--27-october-2026).

Godot 4.7.2, macOS, GL Compatibility, temporary copy with an isolated user directory:

| Check | Result |
| --- | --- |
| `check_hospital_departments.gd` (new) | 0 failures: all 24 words in their rooms with pick shapes, **sheet** on the examination bed, four missions target their rooms and reach their words |
| `check_hospital_remodel.gd` | 717 checks; 0 failures (rear-extension walk replaced by a removal check) |
| `check_runtime_resources.gd` (320), `docs/guides/performance/check_rendering.gd`, `docs/evidence/part2/verify.gd` (1,572), `docs/guides/spanish-signs-20261027/verify.gd` | 0 failures |
| `check_interaction.gd` | PASS |
| `check_vocabulary_categories.py` | Same 8 pre-existing errors |
| `check_vocabulary_translations.py` | 39 pre-existing errors, one fewer: the stale "monitor" tag lived in the removed overrides |

Historical checks that targeted the extension (`check_civic_expansion.gd`,
`capture_civic_expansion.gd`, `check_building_dimensions.gd`) were not updated or
rerun. Room views: `docs/evidence/hospital-wing-removal-20261027/after/` (Urgencias, Exámenes,
Imágenes, Fisioterapia, closed rear exterior).

## Hospital one room deeper with lounges — 27 October 2026

Main block extended to z=19.9 (18 × 32.1), back rooms moved to z=16.05, open lounge
behind the stairs/elevator on every floor; see the
[hospital guide](HOSPITAL_THREE_FLOORS.md#one-room-deeper-with-a-lounge-on-every-floor--27-october-2026).
Regenerated from `tools/build_hospital_remodel.py`; no saved-world changes.

Godot 4.7.2, macOS, GL Compatibility, temporary copy with an isolated user directory:

| Check | Result |
| --- | --- |
| `check_hospital_remodel.gd` | 717 checks; 0 failures. Route now visits front rooms, the moved back rooms and both lounge sides on every floor |
| `check_hospital_departments.gd` | 0 failures; mission targets follow the moved rooms |
| `check_runtime_resources.gd` (320), `docs/guides/performance/check_rendering.gd`, `docs/evidence/part2/verify.gd` (1,572), `docs/guides/spanish-signs-20261027/verify.gd` | 0 failures |
| `check_interaction.gd` | PASS |
| Clearance scan of the new volume plus 1.5 margin | Only the hospital's own roof-derived outline trims (which follow the new roof); no other town object |

The step 1 commit left `check_hospital_remodel.gd`'s `--capture` mode hiding the
removed extension; that is fixed here and the cutaways were re-rendered (camera
re-centred, size 47). The graphical `check_hospital_stair_access.gd` was not rerun;
stairs and elevator geometry are unchanged. Views: `docs/evidence/hospital-deeper-20261027/after/`
(lounges on floors 1–2, hall to the back rooms, a back room, side and rear
exteriors) and refreshed `docs/evidence/hospital-remodel/` and `docs/evidence/hospital-surface-review/` renders.

## Hospital sign clean-up — 27 October 2026

Generator: hanging hall signs, green directory, rear stair sign and stair-top "↓" sign
and arrow removed; matching small stair signs; landing tint moved to an inset above
the slab (fixes the flicker); door plaques for all 12 rooms; wall-coloured inner faces
on the facade header bands. Runtime (`remodel_hospital_displays()`): CLÍNICA plaque,
the stranded imaging plaque and three unbacked annex display labels removed. See the
[hospital guide](HOSPITAL_THREE_FLOORS.md#colours-floor-signs-and-elevator-orientation--27-october-2026).

Godot 4.7.2, macOS, GL Compatibility, temporary copy with an isolated user directory:

| Check | Result |
| --- | --- |
| `check_hospital_departments.gd` | 0 failures; now also checks **imaging** on the Imágenes door plaque |
| `check_hospital_remodel.gd` | 717 checks; 0 failures |
| `check_runtime_resources.gd` (320), `docs/guides/performance/check_rendering.gd`, `docs/evidence/part2/verify.gd` (1,572), `docs/guides/spanish-signs-20261027/verify.gd` | 0 failures |
| `check_interaction.gd` | PASS |

Known consequence: **clinic** (la clínica) no longer has an object in town. The
flicker fix was checked by geometry (inset top at y 0.022, label at 0.045, slab top at
0), not by watching motion. Views: `docs/evidence/hospital-signs-20261027/after/`.

## Hospital reception and final polish — 27 October 2026

Reception redesign, receptionist placement and a floor 3 ceiling panel; see the
[hospital guide](HOSPITAL_THREE_FLOORS.md#reception-and-final-polish--27-october-2026).
Final walkthrough views (each floor's hall, lounges on floors 1 and 3, front exterior)
are in `docs/evidence/hospital-reception-20261027/after/`, with the reception from two angles;
guide cutaways and surface renders were refreshed.

Godot 4.7.2, macOS, GL Compatibility, temporary copy with an isolated user directory:

| Check | Result |
| --- | --- |
| `check_hospital_departments.gd` | 0 failures |
| `check_hospital_remodel.gd` | 717 checks; 0 failures |
| `check_runtime_resources.gd` (320), `docs/guides/performance/check_rendering.gd`, `docs/evidence/part2/verify.gd` (1,572), `docs/guides/spanish-signs-20261027/verify.gd` | 0 failures |
| `check_interaction.gd` | PASS |

Not rerun: the graphical `check_hospital_stair_access.gd` (stair and elevator
geometry unchanged since its last flaky-but-equal comparison). Remaining open item
from step 3: **clinic** has no object in town.

## Walkable park terrain — 27 October 2026

Godot 4.7.2; isolated project copy with custom user directory
`VocabularyTownChecks/park-terrain`. Personal saves and application identity were
not changed. Baseline: 320 runtime resources, zero load failures; public garden
zero failures, 1,638 path samples and both bridge directions passed.

After implementation:

- Runtime resources: 321 checked, zero failures.
- Public garden: zero failures, 1,638 clearance samples, both bridge directions,
  shoreline junctions and landing entry.
- Park terrain: zero failures; 403 elevated collision samples, six traversals using
  the actual player collider/configured snap, protected flat sites, gentle upward
  normals and idempotence. Static terrain has 11,992 triangles.
- Compact layout: 683 checks, zero failures. The old unchanged-bridge-height
  assertion was updated for the authorized 3.0 rise; footprint still checked.
- Compatibility rendered overview, bridge and player-height park views inspected.
  Initial downward terrain normals were corrected; a grove tree intersecting the
  raised bridge was moved clear before final rendering.

No target-laptop FPS benchmark, export, full vehicle suite or exhaustive manual
playthrough was performed. Existing SpatialMaterial remapping warnings remain;
restricted headless runs also logged certificate/user-directory write warnings.
These are not a claim that the full project suite is clean.

## Interactive grass trial — 27 October 2026

Godot 4.7.2 Compatibility, isolated test project and learner directory. Baseline
runtime loading passed (321 resources). After the grass trial: 322 resources,
zero failures. `check_park_grass.gd` passed with 1,698 placements / 25 batches:
terrain grounding, dry placement, path clearance, absence of physics/picking
objects, shared material, shadow setting, bounds, distant culling and toggles.
Public garden passed with 1,638 samples and both bridge directions.

Actual 1280×720 renders were inspected at park and close-up distances. Paired
close-ups show local tip displacement; putting the hidden test player three town
units above the same position restores upright blades. No shader compile errors.

Short local measurements: VSync off, 30 warmup and 90 timed frames per mode/view;
background game activity continues, so results contain scene and timing noise.

| View / mode | Median ms | p95 ms |
| --- | ---: | ---: |
| Close / off | 24.434 | 24.969 |
| Close / static | 24.968 | 26.433 |
| Close / bending | 25.835 | 28.690 |
| Park / off | 28.580 | 32.183 |
| Park / static | 28.711 | 29.344 |
| Park / bending | 28.954 | 31.992 |

These observations do not isolate shader cost or certify low-end laptop
performance. No target-device benchmark, moving-camera percentile benchmark,
whole-town grass deployment, export or full-suite pass is claimed. Existing
material-remapping and restricted headless user-directory warnings remain.

## Lawn texture and park-wide static grass — 27 October 2026

See the [performance guide](performance/README.md#lawn-texture-and-park-wide-static-grass--27-october-2026).
Builds on Codex's terrain and grass trial (committed separately as-is).

Godot 4.7.2, macOS, GL Compatibility, temporary copy with an isolated user directory:

| Check | Result |
| --- | --- |
| `check_park_grass.gd` (updated for park-wide, static grass; clearance sampled on every 20th clump) | 0 failures; 28,480 placements; 254 batches |
| `check_park_terrain.gd`, `check_public_garden.gd` (1,638 samples), `check_runtime_resources.gd` (322), `docs/guides/performance/check_rendering.gd` | 0 failures |
| `check_interaction.gd` | PASS |
| `docs/evidence/part2/verify.gd` | 1 failure, "physics ray picks scaled animal Cat"; identical on the previous commit without these changes (appeared with the terrain/grass trial commit). Fixed in the follow-up below |
| Paired benchmarks | Park walking view +0.6 ms median; town benchmark +0.1 ms; Main load +0.3 s |

### Animals buried by the park slopes — 27 October 2026

The Part 2 cat-pick failure was a real bug: the rolling park terrain raised the
ground under the wandering cat (0.8 units) and rabbit (2.2 units, fully hidden), so
both stood inside the hills and clicks hit the slope. `park_terrain.gd::build()` now
gives every wandering animal whose loop touches raised ground a `ground` callable on
`park_animals.gd`; the animal stands on the slope immediately (home and position)
and follows it as it moves. A scan of park objects found no other buried roots.

| Check | Result |
| --- | --- |
| `docs/evidence/part2/verify.gd` | 1,572 checks; 0 failures (cat pick and wandering origins pass) |
| `check_park_terrain.gd`, `check_park_grass.gd`, `check_public_garden.gd`, `check_runtime_resources.gd` (322), `docs/guides/performance/check_rendering.gd` | 0 failures |
| `check_interaction.gd` | PASS |
| Ad-hoc: 60 steps each for cat and rabbit | Largest gap to the terrain 0.007 (their original resting offset) |

## Zone inspection — 28 October 2026

Stage 1 only; layout approval pending. Isolated Godot 4.7.2 Compatibility copy.
Resource baseline 323/0 failures; final 324/0. `check_zones.gd`: 5,091 checks/0
failures. `check_compact_layout.gd`: 683/0. `check_interaction.gd`: PASS.
Rendered overview, park, restaurant, hospital and player-camera views inspected.
See [detailed scope, evidence and limitations](ARCHITECTURE_REVIEW_PART1.md#zone-boundaries--stage-1-inspection-28-october-2026).
No full-suite or Stage 2 acceptance claim; existing warnings remain.

## Grass clumps removed, sunken pool, raised sidewalks, taquería — 28 October 2026

User requests: keep the lawn texture but remove the standing grass clumps; give the
home pool real depth; give the pedestrian walk height; turn the restaurant-row Cafe
shell into a Mexican restaurant (TAQUERÍA) with new Mexican food words. Details:
[design brief](TOWN_DESIGN_BRIEF.md#mexican-restaurant-taquería--28-october-2026),
[pool and sidewalks](TOWN_DESIGN_BRIEF.md#home-pool-depth-and-raised-sidewalks--28-october-2026),
[grass removal](performance/README.md#grass-clumps-removed--28-october-2026),
[ownership](ARCHITECTURE_REVIEW_PART1.md#taquería-pool-opening-and-sidewalk-ownership--28-october-2026).
Views: `docs/evidence/town-polish-20261028/*.png` (`capture.gd`).

Isolated Godot 4.7.2 Compatibility copies. A 30-script suite ran on both the previous
commit (baseline) and the changed tree; the copy also contained the concurrent,
uncommitted zone work. Labels were compared, not only exit codes.

| Check | Result |
| --- | --- |
| `docs/evidence/town-polish-20261028/verify.gd` (pool floor depths, solid terrace, walk out up the steps; road↔lawn walks over the curb at six spots; 19 new words in dictionaries, 17 placed; facade word) | 0 failures |
| `docs/evidence/part2/verify.gd` | 1,572 checks; 0 failures. Before dropped curbs, 60 "drive collision surface" failures: the raised sidewalk covered each driveway mouth. Fixed by `drop_curbs()` |
| `check_road_physics.gd` (125), `check_vehicle_collision.gd`, `check_zoo_vehicles.gd` (69), `check_compact_layout.gd` (683), `check_runtime_resources.gd` (324) | 0 failures |
| `check_interaction.gd` | PASS |
| `check_park_terrain.gd`, `check_public_garden.gd`, `check_park_bridge.gd`, `check_reference_home.gd`, `docs/guides/performance/check_rendering.gd`, `docs/guides/spanish-signs-20261027/verify.gd` | 0 failures, same as baseline |
| `check_cafe_bank_exteriors.gd` 283 → 287, `check_market_interior.gd` 50 → 54 failures | The extra failures are those scripts' "protected preserved" fingerprints for Home, Restaurants, Restaurants/Cafe and the moved Ambulance/Fire_Truck/Vehicles — intended changes here, not regressions |
| `check_map_facades.gd` | Same 1 failure; 13 vocabulary facade rays (was 12: the taquería teaches *restaurant*) |
| Other existing failures (vocabulary count/alias checks, `world_expansion`, `map_upgrade`, `town_layout`, `transport_navigation_time`, `public_interiors`, `food_shopping_vocab`, `building_exteriors`) | Identical labels to baseline |
| `check_house`, `check_home_refresh`, `check_island`, `check_civic_expansion`, `check_learning_stores` | Time out (300 s) on baseline and changed tree alike; no result |

Rendered and inspected: pool from the terrace and the far edge, the curbed loop road,
the taquería front, dining room and taco bar. Moved vehicles: Bus −3.0 and Ambulance
−2.1 toward the curb, Fire_Truck +0.6 onto the verge. Limitations: no
swimming; entrance walks pass under
the continuous sidewalk rather than having their own dropped curbs.

## Category / area journal — 28 October 2026

After user approval of Stage 1: isolated Godot 4.7.2 Compatibility copy. Category
integrity 94,880 checks/0 failures (baseline had 8 stale cached-category tags).
Area journal 237/0; zone regression 5,091/0; category, alias and interaction checks
PASS; resource loading 325/0. Both journal modes and a real mouse view-switch
captured at 1280×720. All 80 scene edits are category metadata only. See [exact
scope and limitations](ARCHITECTURE_REVIEW_PART1.md#category-and-area-journal--stage-2-28-october-2026).

## One word file, 18 categories, word audit — 28 October 2026

User request after Codex's zone/journal work: make the JSON the only word source,
reduce the categories, merge the word files, audit the words, and stop the
"Fine Dining (Pizza shell)" internal note showing as an area name. Details:
[vocabulary data procedure](ARCHITECTURE_REVIEW_PART1.md#vocabulary-data-procedure),
[word audit](../archive/WORD_AUDIT.md).

- `data/words.json` replaces `vocabulary.json`, `vocabulary_categories.json`,
  `vocabulary_aliases.json` and `learning_catalog.json`. The game reads it through
  `scripts/learning/word_data.gd`; tools and checks use `tools/word_data.py`.
- Cached word metadata was removed from scenes: 11,142 `metadata/english|spanish|category`
  lines in 175 `.tscn` files (no runtime script read them). `bake_editable_town.gd`
  and the prefab generators no longer write them.
- 26 → 18 categories, each with a one-line rule. Keys, Spanish, aliases and saves
  are unchanged.
- The area is now named **Pizzeria**, matching the building's sign (id still
  `fine_dining`). The loop-road curb is now clickable as *curb*.

| Check (isolated copy) | Result |
| --- | --- |
| `check_vocabulary_categories.gd` / `.py`, `check_vocabulary_translations.py`, `check_vocabulary_aliases.gd` | All PASS. On the previous commit both `.py` checks failed: scene-cached Spanish/category copies had drifted out of date. The `.gd` checks failed on stale counts |
| `docs/evidence/part2/verify.gd` | 1,572 checks; 0 failures |
| `check_zones.gd` (5,091), `check_area_journal.gd` (237; its own `journal-20261028` user dir), `docs/evidence/town-polish-20261028/verify.gd`, `check_hospital_departments.gd`, `docs/evidence/vegetation-20261027/phase2/verify.gd`, `check_runtime_resources.gd` (326) | 0 failures |
| `check_interaction.gd` | PASS |
| `check_transport_navigation_time.py` (473), `check_food_shopping_vocab.py` (332) | 0 failures; cached-tag assertions now require that no copy exists |
| `check_food_shopping_vocab.gd`, `check_public_interiors.gd`, `check_transport_navigation_time.gd`, `check_project.py`, `check_zoo_vehicles.py` | Same failure labels as the previous commit (`check_zoo_vehicles.py` has one fewer: its fixed 500-word count) |
| `docs/evidence/vegetation-20261027/phase3/verify.gd` | 2 rose-bush pick failures, identical on the previous commit |
| `docs/word_audit.gd` | 534 words; 451 clickable; 83 unplaced; 0 unknown scene keys; 5 shared Spanish translations; 1 singular/plural pair. Suggestions in the audit await the user's decisions |

Historical tools `docs/migrate_v27_source.py` and `docs/evidence/town_upgrade/verify.gd` still
name the old files and are not expected to run on the current project.


## Word clean-up from the audit — 28 October 2026

User decisions on the [word audit](../archive/WORD_AUDIT.md#decisions-applied-user-28-october-2026):
home kitchen/bathroom items and room signs, 70 words deleted (8 with their objects),
*olive oil* → *oil*, *bank*/*bench* sense labels, *shoe* → *shoes*, body-part words on
the anatomy model only, standable/clickable tree crowns. Result: **464 words, all
clickable; 0 unknown keys, 0 shared translations**.

| Check (isolated copy) | Result |
| --- | --- |
| `check_word_cleanup.gd` (no retired objects, body words only on the anatomy model, 21 home words, handles in cabinetry, landing on every tree species and a cloud; 52 crown platforms) | 0 failures |
| `word_audit.gd` | 464 words; 464 clickable; 0 unplaced, 0 unknown, 0 shared Spanish, 0 singular/plural |
| `check_vocabulary_categories.gd` / `.py`, `check_vocabulary_aliases.gd`, `check_vocabulary_translations.py` | PASS (save-migration fixtures now use *bedside table* → *nightstand*, since *photo* was deleted) |
| `docs/evidence/part2/verify.gd` | 1,572 checks; 0 failures |
| `check_zones.gd` (5,091), `check_compact_layout.gd` (683), `check_road_physics.gd` (125), `check_vehicle_collision.gd`, `docs/evidence/town-polish-20261028/verify.gd`, `check_hospital_departments.gd`, `docs/evidence/vegetation-20261027/phase2/verify.gd`, `check_runtime_resources.gd` (326), `check_reference_home.gd` | 0 failures |
| `check_interaction.gd` | PASS |
| `check_transport_navigation_time.py` (473), `check_food_shopping_vocab.py` (332) | 0 failures |
| `check_market_interior.gd` | 71 failures (54 before): the extra ones are its "protected preserved" fingerprints for the figures whose body tags were removed, Home, the taquería, the moved vehicles, and its mission snapshot (*monitor* → *medical monitor*) — intended changes |
| `check_food_shopping_vocab.gd`, `check_public_interiors.gd`, `check_transport_navigation_time.gd`, `check_project.py`, `check_zoo_vehicles.py`, `docs/evidence/vegetation-20261027/phase3/verify.gd` | Same failure labels as the previous commit |

Rendered and inspected: kitchen (COCINA plaque, pan, shakers, oil, tea, handles), hall
plaques (BAÑO, DORMITORIO, SALA), bathroom items and the yard post sign.

## Streets polish and driving — 28 October 2026

User request with screenshots: roads past their edges, white strips in the road,
inconsistent curbs, floating objects, streetlights, textures and driving. Details:
[design brief](TOWN_DESIGN_BRIEF.md#streets-polish--28-october-2026),
[vehicle guide](ZOO_VEHICLE_IMPLEMENTATION.md#ownership-and-tuning). Views:
`docs/evidence/streets-20261028/*.png` (`capture.gd`).

| Check (isolated copy) | Result |
| --- | --- |
| `docs/evidence/streets-20261028/verify.gd` (drives start ≥4.9 from the centreline, entrance/home/beach walks stay ≥5.6 off it, 17 whole streetlights + traffic light, no loose parts or banners, car crosses the curb at three spots) | 0 failures. On the previous commit the same curb test stopped the car at the road edge at one spot |
| `docs/evidence/part2/verify.gd` | 1,254 checks, 0 failures (375 road samples; fewer than before because drives no longer run to the centreline). Its drive check now expects a road-edge start |
| `check_road_physics.gd` | 125 checks, 0 failures; car 12.5 after 3 s (was 9.4) |
| `check_zoo_vehicles.gd` | 69 checks, 0 failures (helicopter category updated to *Vehicles*) |
| `check_vehicle_collision.gd`, `check_compact_layout.gd` (683), `check_zones.gd` (5,091), `check_park_terrain.gd`, `check_public_garden.gd`, `docs/guides/performance/check_rendering.gd`, `check_runtime_resources.gd` (326), `check_word_cleanup.gd`, `docs/evidence/town-polish-20261028/verify.gd`, `check_vocabulary_categories.gd` | 0 failures / PASS |
| `check_interaction.gd` | PASS |
| `word_audit.gd` | 464 words, all clickable (the floating spare tire was replaced by a tire stack in the home garage) |
| `docs/evidence/world_expansion/verify.gd` | 37 failures (was 38): "existing car drives on expanded road" now passes |
| `check_map_facades.gd`, `check_transport_navigation_time.gd` | Same failure labels as before |

Rendered and inspected: the east street at eye level, a crosswalk ramp, the drives in
front of the sports store from above, the north street and a high overview.

## Lagoon Bridge likeness — 28 October 2026

Bridge rebuilt after the user's Boston Public Garden photos
([details](public-garden/README.md#lagoon-bridge-likeness--28-october-2026); views in
`docs/evidence/bridge-20261028/`).

| Check (isolated copy) | Result |
| --- | --- |
| `check_public_garden.gd` | 0 failures; 1,638 path samples; bridge crossed in both directions (an intermediate smoothstep profile left a lip at each deck end and failed both crossings; fixed with ease-out ramps) |
| `check_park_bridge.gd` | success |
| Ad-hoc: the player (BonBon capsule) walked the full bridge both ways | Crossed; peak height 2.97 |
| `check_park_terrain.gd`, `docs/evidence/part2/verify.gd` (1,254), `check_runtime_resources.gd` (326), `docs/guides/performance/check_rendering.gd` | 0 failures |
| `word_audit.gd` | 464 words, all clickable |

Rendered and compared with the reference photos: side view from the water, the swan
boat landing angle, a close tower view and the deck.

## Word card closes on camera drag — 28 October 2026

User request: the word card should disappear when the view is dragged with the right
mouse button. `interaction_controller.gd::_input()` tracks the right button from its own
events and closes the card once a drag exceeds `ORBIT_DISMISS_PIXELS` (6 px); a click
or tiny jitter keeps it open. `check_interaction.gd` (new cases: jitter keeps the card,
a 12 px right-drag closes it): PASS.

## Restaurants and police relocation — 28 October 2026

Scope: police station moved east of the loop road south of the supermarket; fine dining
and Pizza and Burger built ([record](TOWN_DESIGN_BRIEF.md#restaurants-and-police-relocation--28-october-2026)).
Run headless with `HOME` pointing at a scratch folder (isolated `user://`), Godot 4.7.2;
the baseline was a `git archive HEAD` copy (with the `.godot` cache) of the same commit
`3843ced` in a scratch folder, so nothing in the repository was stashed or reset.

| Check | HEAD baseline | After the change |
| --- | --- | --- |
| `check_runtime_resources.gd` | 326 checked, 0 failures | 327 checked, 0 failures |
| `check_compact_layout.gd` | 683 checks, 0 failures | 691 checks, 0 failures (the "inward entrance Police" expectation was updated from BACK to RIGHT because the door now faces the east road) |
| `check_interaction.gd` | PASS | PASS |
| `docs/evidence/part2/verify.gd` | 1254 checks, 0 failures | 1304 checks, 0 failures |
| `check_zones.gd` | not run on baseline | 5092 checks, 0 failures (samples and envelopes updated for the new zones) |
| `check_map_facades.gd` | 1 failure (HOSPITAL street ray) | same 1 failure; 20 facades |
| `check_public_garden.gd`, `check_road_physics.gd`, `check_hospital_remodel.gd`, `docs/evidence/town-polish-20261028/verify.gd`, `docs/evidence/streets-20261028/verify.gd` | 0 failures | 0 failures |
| `check_zoo_vehicles.gd` | 2 failures (gate translation, gate popup) | same 2 failures |
| `check_cafe_bank_exteriors.gd`, `check_supermarket_exterior.gd` | 297 / 264 failures (stale snapshot comparisons) | identical labels plus one new `sites preserved Police`, the intended move |
| `check_market_interior.gd`, `check_school_partition.gd` | many stale "preserved" failures | same first 25 sorted failure labels (the full lists were not diffed) |
| `check_vocabulary_translations.py`, `check_vocabulary_categories.py`, `tools/word_data.py` | — | PASS (469 words) |
| `docs/evidence/restaurants-20261028/verify.gd` (new) | — | 199 checks, 0 failures |

The new check covers: police position/overlap/pad/car/walk/drive; restaurant footprint
overlaps; word keys placed in each venue and present in the vocabulary; sign translations
and facade lettering; capsule probes along door-to-counter/table routes (with
two negative probes proving the test can fail); clear entrance rays; taquería retained.

Rendered inspection (graphical Godot run, evidence PNGs in `docs/evidence/restaurants-20261028/`):
street views of the row and police lot, fine-dining and kitchen interiors, cut-away top
views. Limits: not driven by a player in a live session; no frame-time measurement; the
`check_zoo_vehicles`, `check_map_facades`, exterior and `*_preserved` failures were
already present and are not claimed fixed; the full suite is **not** clean. Not run:
aircraft, helicopter, hospital departments, public-garden capture. The P&B roof renders
a bright coral-red under the town sun; shell glass is a simple translucent material.


## Chair/bench sitting — 28 October 2026

Isolated Godot 4.7.2 Compatibility copy. `check_sitting.gd`: 211 checks/0 failures,
170 seats. Player movement baseline and final: 0 failures; BonBon UI: 0 failures;
interaction: PASS; resource loading: 328/0. Actual bench/chair sit and stand rendered
and inspected. See [details and limitations](BONBON_VALIDATION.md#sitting-on-chairs-and-benches--28-october-2026).


## Pond basin terrain — 28 October 2026

Broader smooth pond slopes replace the isolated hill-only profile, with fitted
path cross sections and unchanged bridge geometry/placement. Isolated Godot
4.7.2 checks: terrain 0 failures (913 collision samples, six actual-player
traversals, 23,948 ground triangles); garden 0 failures (1,638 path samples,
both bridge directions, shore junctions and dock); resources 328/0. Rendered
views inspected. Existing warnings remain; no full-suite or learner-save claim.
See [pond basin relief](public-garden/README.md#pond-basin-relief--28-october-2026)
for rationale, editing parameters and screenshots.


## Lowered lagoon, bridge clearance and water — 28 October 2026

Lagoon water lowered below a sloped bank and bed (ground layers cut), bridge railing
collision now follows the deck so the spans can be waded under, piers reach the bed,
and the water shader is translucent with glints and ripples. Isolated Godot 4.7.2
checks: garden 0 failures, including a new wade-under-bridge check (fails 4/4 with
the old walls); terrain 0 failures; phase 2 trees 0 failures; resources 328/0.
Rendered bank, under-bridge and island views inspected. Existing warnings remain;
no full-suite or learner-save claim. See
[lowered lagoon](public-garden/README.md#lowered-lagoon-bridge-clearance-and-water--28-october-2026).

## Sports store interior — 28 October 2026

Scope: sports store fitted out from the user's isometric design inside the unchanged
14 × 24 shell ([record](TOWN_DESIGN_BRIEF.md#sports-store-interior--28-october-2026)).
Run headless in an isolated `user://` copy (custom user dir), Godot 4.7.2.

| Check | Result |
| --- | --- |
| `docs/evidence/sports-interior-20261028/verify.gd` (new) | 115 checks, 0 failures: footprint/position unchanged, no overlap with hospital/furniture, all 16 roots kept, inside walls and reachable, centre aisle and door gap clear for the player capsule, side aisles open, shelves/counter/tent solid, every sign translated |
| `check_runtime_resources.gd` | 329 checked, 0 failures |
| `check_zones.gd` | 5092 checks, 0 failures (zone polygon unchanged) |
| `check_interaction.gd` | PASS |
| `check_learning_stores.gd` | Not completed: times out on baseline too (see the earlier record) |

Rendered inspection (graphical run, PNGs in `docs/evidence/sports-interior-20261028/`): plan view
with roof/ceiling hidden, doorway view, view from the rear, cutaway. Limits: not driven by
a live player; compact-layout, part2 and market/school preserved-checks were not re-run;
five props (tennis ball, baseball, glove, bat, barbell) are non-learnable decor because
their words were removed in the word audit; snow/camping items are decor, no new vocabulary.

## Clothing store interior — 28 October 2026

Scope: clothing boutique fitted out from the user's isometric design inside the unchanged
shell ([record](TOWN_DESIGN_BRIEF.md#clothing-store-interior--28-october-2026)). Headless
runs in an isolated `user://` copy, Godot 4.7.2.

| Check | Result |
| --- | --- |
| `docs/evidence/clothing-interior-20261028/verify.gd` (new) | 130 checks, 0 failures: footprint/position/shell/windows preserved, no overlap with bakery/electronics, all 17 learning roots kept on table tops and reachable, door gap, centre lanes and fitting-room approach clear, fixtures solid, old tables/bench removed, every sign translated |
| `check_runtime_resources.gd` | 330 checked, 0 failures |
| `check_zones.gd` | 5092 checks, 0 failures (zone polygon unchanged) |
| `check_interaction.gd` | PASS |

Rendered inspection (graphical run, PNGs in `docs/evidence/clothing-interior-20261028/`): plan view,
doorway, cutaway. In the doorway image the dark slab is the gable roof seen from inside with
the flat roof hidden for the capture. Limits: not driven by a live player; compact-layout and
part2 checks not re-run; the pre-existing "PERCHERO" rack label near the shopkeeper was not
changed; `check_learning_stores.gd` still times out as on the baseline.

## Electronics store interior — 28 October 2026

Scope: electronics showroom fitted out from the user's isometric design inside the unchanged
shell ([record](TOWN_DESIGN_BRIEF.md#electronics-store-interior--28-october-2026)). Headless
runs in an isolated `user://` copy, Godot 4.7.2.

| Check | Result |
| --- | --- |
| `docs/evidence/electronics-interior-20261028/verify.gd` (new) | 120 checks, 0 failures: footprint/position/shell/windows preserved, no overlap with bakery/clothing, all 16 learning roots kept and reachable, door gap, centre aisle and side lanes clear, fixtures solid, old tables removed, every sign translated |
| `check_runtime_resources.gd` | 331 checked, 0 failures |
| `check_zones.gd` | 5092 checks, 0 failures (zone polygon unchanged) |
| `check_interaction.gd` | PASS |

Rendered inspection (graphical run, PNGs in `docs/evidence/electronics-interior-20261028/`): plan view,
doorway, rear view, cutaway (roof hidden for capture, so floors look bright). Limits: not
driven by a live player; compact-layout and part2 checks not re-run; `check_learning_stores.gd`
still times out as on the baseline.

## Electronics store refresh — 1 November 2026

Scope: the electronics interior refitted as a real electronics shop in the unchanged shell
([record](TOWN_DESIGN_BRIEF.md#electronics-store-refresh--1-november-2026)). Runs in an isolated
project copy (`use_custom_user_dir=true` / `custom_user_dir_name="VocabularyTownChecks/isolated"`),
Godot 4.7.2, macOS; each check run once on the finished code.

| Check | Result |
| --- | --- |
| `docs/evidence/electronics-interior-20261101/verify.gd` (new) | 769 checks, 0 failures: shell/door nodes and metadata kept, scale 1.3; all 24 word roots kept with their keys, inside the room, pick area on the model, resting on a surface or mounted on a wall, reachable by BonBon's 0.76 m capsule within 1.3 units, and picked through `vocabulary_target` from a reachable eye ray within `INTERACT_DISTANCE`; 1376 reachable floor cells from the door; door gap and centre aisle clear; routes to all 11 departments; fixtures solid; no look-alike decor or old gondolas; every non-price sign translated; at least 20 price tags |
| `check_runtime_resources.gd` | 363 checked; 0 failures (usual Godot 3 `specular` remap warnings) |

The first `verify.gd` run reported one failure that was a bug in the check (the checkout
counter is picked through its solid word body, not an Area3D); the check was corrected and
run again. A last decor-only fix (game graphics moved in front of the gaming screen surface)
came after the verify run and is shown in the final renders.

Rendered inspection (graphical run, PNGs in `docs/evidence/electronics-interior-20261101/`): before and
after views of the front, entrance, left, right, rear, checkout and two overviews, plus gaming
bay, phones table and appliances close-ups. Not run: `docs/evidence/electronics-interior-20261028/verify.gd`
(superseded; it asserts the removed gondola layout), `check_zones.gd`, `check_interaction.gd`,
`check_learning_stores.gd` (times out on the baseline). Not driven by a live player.

## Sports store winter revision — 28 October 2026

Scope: eight winter words and the sports interior revision ([record](TOWN_DESIGN_BRIEF.md#winter-sports-revision--28-october-2026)).
Headless runs in an isolated `user://` copy, Godot 4.7.2. The copy excluded the bakery café
interior then in progress in the same folder (its unfinished script did not parse).

| Check | Result |
| --- | --- |
| `docs/evidence/sports-interior-20261028/verify.gd` (extended) | 158 checks, 0 failures: earlier checks plus tent, accessory shelves and skier solid; all ten winter words (8 new + helmet, jacket) in words.json, tagged, pickable and inside the walls; every sign translated |
| `tools/word_data.py`, `check_vocabulary_categories.py`, `check_vocabulary_translations.py` | PASS (477 words) |
| `check_vocabulary_categories.gd`, `check_vocabulary_aliases.gd` | PASS |
| `word_audit.gd` | Every category fully placed (477/477) |
| `check_runtime_resources.gd` | 331 checked, 0 failures |
| `check_zones.gd` | 5092 checks, 0 failures |
| `check_interaction.gd` | PASS |

Rendered inspection (graphical run, PNGs in `docs/evidence/sports-interior-20261028/winter/`): plan,
doorway, winter department, from the rear, cutaway (roof hidden for plan/cutaway). Limits: not
driven by a live player; picking of the new props checked by collision presence, not by
clicking; compact-layout and part2 checks not re-run.

## Café and bakery interior — 28 October 2026

Scope: café/bakery fitted out from the user's pink "Cafe & Cakes" design inside the unchanged
14 × 22 shell ([record](TOWN_DESIGN_BRIEF.md#café-and-bakery-interior--28-october-2026)). Headless
runs in an isolated `user://` copy, Godot 4.7.2, with the concurrent sports (winter) and bank
interior work present in the tree.

| Check | Result |
| --- | --- |
| `docs/evidence/bakery-cafe-interior-20261028/verify.gd` (new) | 174 checks, 0 failures: position/footprint/shell preserved, no overlap with electronics/furniture, all 23 learning roots kept, inside and reachable, relocated soup/cupcake/snack on fixtures, cook behind the register, old tables/shelves/labels removed, door gap, centre aisle, staff gap and work area clear, fixtures solid, 24 sittable seats, every sign translated and visible |
| `check_runtime_resources.gd` | 333 checked, 0 failures |
| `check_zones.gd` | 5092 checks, 0 failures (zone polygon unchanged) |
| `check_interaction.gd` | PASS |

Rendered inspection (graphical run, PNGs in `docs/evidence/bakery-cafe-interior-20261028/`): cutaway and plan
(roof hidden for capture, so the floor looks sunlit), doorway, counter, seating, behind the counter.
Limits: not driven by a live player; sitting not exercised in play; compact-layout and part2 checks
not re-run; `check_learning_stores.gd` not re-run (times out on the baseline).

## Bank interior — 28 October 2026

Scope: bank interior from the user's isometric design ([record](TOWN_DESIGN_BRIEF.md#bank-interior--28-october-2026)). Headless runs in an
isolated `user://` copy, Godot 4.7.2, excluding the bakery café interior then in progress in the same folder.

| Check | Result |
| --- | --- |
| `docs/evidence/bank-interior-20261028/verify.gd` (new) | 111 checks, 0 failures: position, shell and footprint kept; 19 preserved roots (ATMs, vault, safes, office doors, desk, computer, cabinet, queue, coffee table, brochure, phone, four chairs, poster) present, inside and reachable; both doors still registered; old counters removed and their words on the new line; quest words present; entry, queue lane, tellers, office and vault doors, ATMs, reception and consultation walkable; counter, desk, sofa, shelf solid; two sofas sittable, teller chairs not; pig behind the desk; signs translated (window numbers are codes) |
| `docs/evidence/sports-interior-20261028/verify.gd` | 158 checks, 0 failures |
| `check_sitting.gd` | 238 checks, 0 failures; 197 seats |
| `check_runtime_resources.gd` | 333 checked, 0 failures |
| `check_zones.gd` | 5092 checks, 0 failures |
| `check_interaction.gd`, `check_vocabulary_categories.gd`, `check_vocabulary_aliases.gd` | PASS |
| `check_cafe_bank_exteriors.gd` (25 Oct snapshot) | Already failing before this change (300 of 965, stale baseline). Now 436: the added bank failures are only the replaced teller fittings and the moved chairs, coffee table, brochure, phone and poster; no new collision or bank-route failure |

Rendered inspection (graphical run, PNGs in `docs/evidence/bank-interior-20261028/`): plan, doorway, tellers, waiting,
consultation, view from the tellers, cutaway (roof and ceiling hidden for plan/cutaway). Limits: not driven by a
live player; compact-layout and part2 checks not re-run.

## Police station interior — 28 October 2026

Scope: police station interior from the user's isometric design ([record](TOWN_DESIGN_BRIEF.md#police-station-interior--28-october-2026)).
Headless runs in an isolated `user://` copy, Godot 4.7.2, excluding the bakery café interior then in progress.

| Check | Result |
| --- | --- |
| `docs/evidence/police-interior-20261028/verify.gd` (new) | 129 checks, 0 failures: position, 144 original children and footprint kept; 30 roots (reception, desks, monitors, radios, chairs, boards, badge, cabinets, locker label, cell bench, first aid, both doors) present, inside and reachable; both doors still registered; cabinets in the equipment alcove; pig behind the desk; entry, alcove, both room doors, waiting, reception, coffee counter and both rooms walkable; desk, wall fillers, shelving, lockers and coffee cabinet solid; new words tagged; signs readable |
| `docs/evidence/restaurants-20261028/verify.gd` | 199 checks, 0 failures (child count now ignores the added `Interior` node) |
| `docs/evidence/bank-interior-20261028/verify.gd`, `docs/evidence/sports-interior-20261028/verify.gd` | 111 / 158 checks, 0 failures |
| `check_sitting.gd` | 214 checks, 0 failures; 173 seats, the same with the police interior removed (the bank run counted 197; the drop is not from this change and was not traced) |
| `check_runtime_resources.gd`, `check_zones.gd` | 333 / 5092 checks, 0 failures |
| `check_interaction.gd`, `check_vocabulary_categories.gd` | PASS |
| `docs/evidence/town_upgrade/verify.gd` | Not usable: it reads a removed backup file and hangs (stopped after 42 minutes) |

Rendered inspection (graphical run, PNGs in `docs/evidence/police-interior-20261028/`): plan, doorway, left, right,
rear rooms, from the rear, cutaway. Limits: not driven by a live player; compact-layout and part2 checks not re-run.

## Airport terminal interior — 28 October 2026

Scope: airport terminal interior and the new Travel words ([record](TOWN_DESIGN_BRIEF.md#airport-terminal-interior--28-october-2026)).
Headless runs in an isolated `user://` copy, Godot 4.7.2, excluding the bakery café interior then in progress.

| Check | Result |
| --- | --- |
| `docs/evidence/airport-interior-20261028/verify.gd` (new) | 180 checks, 0 failures: shell, footprint, tower and aircraft kept; 29 words in words.json, tagged, pickable and inside; the seven new words in Travel; door, aisle, every zone, the security lane and detector, the gap, gate, boarding door, claim, restrooms and carts walkable; counters, x-ray, carousel, glass, board, seats and rails solid; gate closed except the gap; 50+ seats sittable; signs translated |
| `police`, `bank`, `sports` interior checks, `docs/evidence/restaurants-20261028/verify.gd` | 129 / 111 / 158 / 199 checks, 0 failures |
| `check_sitting.gd` | 268 checks, 0 failures; 227 seats |
| `check_runtime_resources.gd`, `check_zones.gd` | 334 / 5092 checks, 0 failures |
| `check_interaction.gd`, `check_vocabulary_categories.gd`, `check_vocabulary_aliases.gd` | PASS (486 words, 19 categories) |
| `word_audit.gd` | Every category fully placed, including Travel 7/7 |
| `check_vocabulary_categories.py`, `check_vocabulary_translations.py` | PASS (486 words) |

Rendered inspection (graphical run, PNGs in `docs/evidence/airport-interior-20261028/`): plan, doorway, check-in,
security, gate, baggage claim, shop and café, cutaway. Limits: not driven by a live player; compact-layout and
part2 checks not re-run.

## Airport detector and seats; steerable swan boats — 28 October 2026

User report: BonBon could not pass the airport metal detector or sit on the airport seats,
and the swan boats should be standable, with sittable benches and a steering seat in the swan.

- Detector: the opening was 1.10 town units (1.43 world), narrower than BonBon's
  1.52-wide capsule. The sides now stand on the lane-rail lines: 1.42 (1.85 world).
- Seats: each waiting-seat row shared one blocker, so the seat sight line hit it for
  every seat except the first ("Seat"). Each seat now owns its blocker. Seat choice
  also penalizes seats the player stands behind (between rows the nearer seat faces away).
- Swan boats: `world_refinements.gd::swan_boats()` groups each boat's loose garden parts
  under a `scripts/world/swan_boat.gd` root (outside the garden render batches). Deck,
  benches and swan are solid; the five benches are seats; a red saddle on the swan's back
  steers (W/S pedal, A/D steer, E stand up). Motion is swept against solids and kept
  inside the lagoon polygon. `seating_controller.gd` now keeps seat points node-local
  (seats may move) and reads optional seat metadata, documented in its header.

| Check | Result |
| --- | --- |
| `check_seats_and_swan_boats.gd` (new) | 0 failures: walked through the detector and gap; 54/54 airport seats sat from the front and stood; two boat roots, six seats each, start clear and afloat; stood on the deck; bench sit/stand; saddle chosen from the last bench, steers, turns, carries the pilot, stops at the shore, stands onto the last bench |
| `check_sitting.gd` | 304 checks, 0 failures, 263 seats |
| `docs/evidence/airport-interior-20261028/verify.gd` | 180 checks, 0 failures |
| `docs/evidence/bank-interior-20261028/verify.gd` | 111 checks, 0 failures |
| `check_public_garden.gd` | 0 failures |
| `check_interaction.gd`, `check_runtime_resources.gd` | pass; 336 resources, 0 failures |

Rendered inspection (graphical run, not saved): BonBon inside the wider detector; seated in a
middle-row airport seat; seated on a boat bench; on the swan saddle facing the bow, docked
and while steering. Limitations: driving was exercised by calling `drive()` directly
(headless runs cannot hold keys); the full suite was not rerun.

Follow-up, same day (user report): the second boat's neck stayed behind when the boat
moved. Its mesh was added without a readable name, so it was auto-named
`@MeshInstance3D@…` and missed the "Swan" grouping; `public_garden.gd` now adds it with a
readable name and the check asserts each boat carries its neck. The widened detector's
sides also cut through the bare lane rails: the visible rails now stop at the detector
frame and stand on posts with top and middle bars (collision unchanged). Rechecked:
`check_seats_and_swan_boats.gd`, `docs/evidence/airport-interior-20261028/verify.gd`, `check_sitting.gd`
and `check_public_garden.gd`, 0 failures; lane rendered from the queue and from the lane entry.

## Furniture showroom — 29 October 2026

Furniture store enlarged to 24 × 26 (front wall line unchanged), flat green-trim exterior,
five-department showroom, eight new words (rug, floor lamp, TV stand, side table, ottoman,
office chair, sideboard, monitor); see the [design record](TOWN_DESIGN_BRIEF.md#furniture-showroom--29-october-2026).
Run with an isolated user directory (symlinked copy of the project with the README's
`custom_user_dir_name`), so learner saves were not touched.

| Check | Result |
| --- | --- |
| `docs/evidence/furniture-interior-20261029/verify.gd` (new) | 199 checks, 0 failures: position, shell lines, zone containment, clearance from sports/hospital/electronics/bakery, 16 original roots kept, 8 new words placed with one picking box each, every tagged key is a word, rugs only in the showroom, spine/door-gap/cross aisles walkable, standing spot beside each fixture, signs translated |
| `check_zones.gd` | 5092 checks, 0 failures |
| `check_sitting.gd` | 317 checks, 0 failures, 276 seats (the new dining chairs and armchairs are sittable) |
| `check_interaction.gd`, `check_runtime_resources.gd` | pass; 355 resources, 0 failures |
| `docs/evidence/sports-interior-20261028/verify.gd` | 158 checks, 0 failures (neighbour unaffected) |
| `python3 tools/word_data.py` | valid, 494 words |
| `docs/evidence/town-checks/check_vocabulary_translations.py`, `check_vocabulary_categories.py` | 1 failure each, both the existing uncommitted `crocodile_plush.tscn` / `crocodile` key problem, unrelated to this work |

Rendered inspection (graphical run): exterior from the street, doorway, plan and cutaway,
and living, bedroom, dining, office and lighting views, saved in `docs/evidence/furniture-interior-20261029/`
(`capture.gd` regenerates them). Corrected from renders: the bed's headboard end, the
computer's scale on the desk, rug colours, and two original roots (wardrobe, bookshelf) that
had been left at their old positions.

Limitations and open items: hover/click of the new words was verified by structure (one
layer-2 picking box under a `word_key` root), not by driving the pointer in a live session.
The BEDROOM sign still reads DORMITORIO while the word is *la recámara* (shared existing
sign, priority low). The new displays use the project's flat-colour primitives, so chairs are
the existing blue prefab and bookshelves are plain; the existing Map-facades checks
(`check_map_facades.gd`) were not rerun and already failed on street-ray picks before this
work. The full suite was not rerun.

## Airport control tower — 29 October 2026

Solid tower boxes replaced by a walkable three-level tower (8.4 shaft flaring to an 11.2 glass control room, lift plus stair); see the [design record](TOWN_DESIGN_BRIEF.md#airport-control-tower--29-october-2026). Run with an isolated user directory (symlinked project copy with the README's `custom_user_dir_name`), so learner saves were not touched.

| Check | Result |
| --- | --- |
| `docs/evidence/control-tower-20261029/verify.gd` (new) | 221 checks, 0 failures (after the taller, open-shaft revision) (includes the four new words, two stair roots, shared elevator script, outer landing door + call lamp at all three stops): old boxes and collision gone; footprint inside zone `control_tower`; no overlap with the terminal; every tagged key is an existing word and pickable; ray picking resolves the word roots; glazing on all four sides; free standing spots with the real player capsule (r 0.76, h 2.2 world); **simulated walking** up the stair lobby → radar deck → control room and back down; **simulated lift rides** lobby → control room → radar deck → lobby with the rider carried by the cabin and doors opening. |
| `docs/evidence/airport-interior-20261028/verify.gd` | 180 checks, 0 failures (terminal unaffected) |
| Hospital, before and after the shared-elevator change | `check_hospital_remodel.gd` 717 checks / 0 failures; `check_hospital_departments.gd` 24 words / 0 failures; `check_hospital_stair_access.gd` 0 failures — identical before and after. `check_hospital_floors.gd` **14 failures both before and after, identical ERROR lines** (existing stair-walk problem, not from this work). |
| `python3 tools/word_data.py` | valid; four words added (stairs, elevator, radar, headset) |
| `check_zones.gd` | 5092 checks, 0 failures |
| `check_interaction.gd` | pass |
| `check_runtime_resources.gd` | 360 resources, 0 failures |

Rendered inspection (graphical run): exterior (near, far with terminal, rear), cabin close-up, lobby, stair, lift, radar deck, control-room south/east/north/core/outlook and a top plan, saved in `docs/evidence/control-tower-20261029/` (`capture.gd` regenerates them). Corrections made from renders: stone bands had been solid slabs (now rings), a roof-named fascia triggered tall corner posts from `building_outlines()`, the tower was widened first and then narrowed on the user's request.

Limitations: the lift and stair were verified with a simulated character body in a headless run, not by driving the real player in a live session; pointer picking was verified by physics rays, not live clicks. The extra plan views for the lower floors were dropped because the hide logic was not reliable. The stair flights are 1.4 wide (player diameter 1.17) and the corridor beside the stair opening is about 1.3, so it is snug. The full suite, `check_map_facades.gd` and `check_sitting.gd` were not rerun; the office chairs are the showroom-style item, not sittable. Nothing was committed.

Update (same day): the first version used a separate tower elevator script; it was replaced by the parametrised `hospital_elevator.gd` after the user asked to reuse and improve the hospital elevator. The word-list and README/glossary audits (`docs/word_audit.gd`, `check_vocabulary_*`) were not rerun for the four new words.

Revision (same day, user request: taller, no filled floors, discreet entrance): shaft 22 high with four stair storeys, landing strips only at 5.5/11/16.5, a hidden radar room at the lift stop at 11, one small side door and no lobby, canopy, sign or reception desk. `verify.gd` now walks the stair up all four storeys and back, rides the lift 0 → 22 → 11 → 0, checks the shaft is open between strips (a ray from y 12 falls to the ground floor), the side-door path and standing spots, and four `stairs` roots. Renders were regenerated (exterior, side door, ground, shaft, landing strip, radar room, control room); the hospital checks were not rerun after this revision because it changes only `tower_interior.gd` (the shared elevator script is unchanged since their last run). The CONTROL TOWER sign translation was removed again.

## Coast, deserted island, boulders and crabs — 29 October 2026

East-coast island, rebuilt sand edge and shallows with a new sand shader, 14 beach boulders, 10 crabs
(new word *crab* = el cangrejo, Animals, the only word added); see the
[design record](TOWN_DESIGN_BRIEF.md#coast-deserted-island-boulders-and-crabs--29-october-2026).
Run with an isolated user directory (symlinked copy of the project with the README's
`custom_user_dir_name`), so learner saves were not touched. No clean pre-change baseline run was
possible because other uncommitted work shares the tree; the table is the post-change state.

| Check | Result |
| --- | --- |
| `docs/evidence/coast-20261029/verify.gd` (new) | 3278 checks, 0 failures: crab/rock/palm words and no duplicate Spanish; sand edge turns under 20° per 1.8 m, simple polygons, width 6.6–12.2 m and never narrower than before; piers still touch sand; every beach sample has solid, walkable ground (normal > 0.85, steps < 0.2 m); 14 boulders (8 east), one mesh and one body under each `rock` root, picking resolves to the root, clear of piers, runway, aircraft, walk vertices; 10 crabs (2 island) with one mesh and a picking area, 400 wander steps stay within ±0.7 m and on sand; island 10+ m from the shallows, clear of all buildings, runway, road, plane and piers, palms use the `palm tree` word, top is solid; airport and furniture positions unchanged |
| `check_runtime_resources.gd` | 359 resources, 0 failures |
| `check_compact_layout.gd` | 684 checks, 0 failures |
| `check_park_terrain.gd`, `check_public_garden.gd`, `check_interaction.gd`, `check_vocabulary_aliases.gd` | pass |
| `word_audit.gd` | Animals 21 words, 21 placed (crab included) |
| `python3 tools/word_data.py` | valid |
| `check_seats_and_swan_boats.gd` | **1 failure**: airport seats sat on intended seat 53/54 (54/54 on 28 Oct). Not investigated; the coast pass touches no interior, and another session is editing the airport tower and shared elevator, but it was not isolated |
| `check_vocabulary_categories/translations.py` | 1 failure each, the existing uncommitted `crocodile_plush.tscn` / `crocodile` key problem |
| `check_island.gd` | stale (asserts three school floors, fails before reaching the coast); not a coast check |

Rendered inspection (graphical run, `docs/evidence/coast-20261029/capture.gd` regenerates): overview, island
from the air, water and shore, shoreline, beach sand and close sand, boulders and a crab close-up,
all looked at. Corrections made from renders: sand was washed out and uniformly pale (darkened,
three-tone, higher grain and ripple contrast), boulders rendered near white (darker rock colour,
larger radii), foam and wet-sand bands too heavy (narrowed), crab legs rendered as flat blades
(basis scaling order fixed), island lacked a foam ring.

Limitations and open items: hover and click of crabs and boulders was checked structurally (the
shared `vocabulary_target` resolves each body/area to its root), not by driving the pointer in a live
session. Crab animation is a body bob and a sideways run, not leg or claw motion (single merged mesh).
The island is unreachable on foot (the sea has no floor collision) and lies outside the minimap
bounds, so it is not drawn on the map. The foam and shallow rings are flat vertex-coloured meshes,
not animated water. The sand shader and 10 crabs add roughly 40 draw calls (an estimate from node counts, not a profile); frame time was not
measured. The full suite was not rerun.

## Tower stair walls and ladder, flush lift doors, swivel seats, standable bridge — 30 October 2026

Design record: [TOWN_DESIGN_BRIEF.md](TOWN_DESIGN_BRIEF.md#tower-stair-walls-and-ladder-flush-lift-doors-swivel-seats-standable-bridge--30-october-2026).
Follow-up (same day): stair, landing and opening handrails are now round top/mid rails on posts (`railing()` in `tower_interior.gd`); the ladder has round rails and rungs, wall plates and bent grab handles; the control-room hatch has a yellow floor border, guard rails with kick plates on its two long sides (east side open) and collision guards. Re-verified: tower-bridge-seats 43/0, control-tower 217/0; renders `hatch_from_above.png`, `empty_level_ladder.png`, `stairs_level2.png` re-captured and inspected.

Second follow-up (same day): radar room partition walls and floating ceiling slab removed (world map moved to the south wall); stair treads are now thin slabs (0.08 m, open risers) on steel stringers with the wedge collision unchanged; the upper flight's west handrail was dropped because it doubled the level rail around the floor opening; `SWIVEL_SPEED` 2.2 → 3.0 rad/s. Beach: new invisible "Coastal seabed" body (`build_seabed()` in `coast.gd`) continues the sand edge down ~6° to −1.65 m (waist depth) over ~9 m beyond the shallow edge, then drops steeply to −8 m with no ground beyond, so the player falls and `main.gd`'s y < −15 check returns them to spawn. New `docs/evidence/coast-20261029/verify_wading.gd`: 25 shore points, 53 checks / 0 failures (seabed reaches 6–13.5 m beyond the shallow edge, deepest wade −1.65 m, no step over 1.2 m); `docs/evidence/coast-20261029/verify.gd` 3278/0, tower-bridge-seats 43/0, control-tower 217/0. Renders inspected: empty level, stairs, radar room. Limitations: wading verified by ray probes, not a live walk-in (no swim, no camera dip); the "east side structure" in the brief was not located and nothing was removed for it; the full regression suite was not re-run after this round.

Isolated user directory (symlinked project copy with the README's `custom_user_dir_name`); learner saves not touched.

| Check | Result |
| --- | --- |
| `docs/evidence/tower-bridge-seats-20261030/verify.gd` (new) | 43 checks, 0 failures: three stair roots and no tread above 16.5; east and north stair walls solid; full floor at 16.5 (incl. the north-west corner), hatch open straight down to it, control-room floor solid elsewhere; ladder in group `ladders` (rise 5.5); a real player body **grabs with W, climbs to the control-room floor and ends beside the hatch, and climbs back down with S** (physics, simulated key events); tower and hospital lift trim at most 6.5 cm proud of the shaft face; swivel office chairs (>= 8, all 8+ tower chairs sittable) and 8 swivel bar stools registered as seats, seat heights sane; **A turns the chair and the player with it, D turns back**; 80+ handrail strips, 100+ chain strips and 8 globe pads solid from above; a player dropped on a rail, a chain and a globe rests on it |
| `docs/evidence/control-tower-20261029/verify.gd` | 217 checks, 0 failures **after updating three expectations** (three stair roots, stairs walked 0 → 16.5 only) |
| `check_sitting.gd` | 336 checks, 0 failures, 295 seats |
| `check_public_garden.gd`, `check_park_bridge.gd`, `check_interaction.gd` | pass (bridge crossed and waded under both ways, walk success) |
| `check_runtime_resources.gd`, `check_compact_layout.gd` | 359 resources, 0 failures; 684 checks, 0 failures |
| `docs/evidence/coast-20261029/verify.gd`, `docs/evidence/furniture-interior-20261029/verify.gd` | 3278 and 199 checks, 0 failures (neighbouring work unaffected) |
| `check_seats_and_swan_boats.gd` | **1 failure**: airport seats sat on intended seat 53/54, the same failure seen before these changes; not investigated |

Rendered inspection (graphical run, `capture.gd` regenerates): stairs from the ground floor and the 5.5 landing, the empty level, ladder and hatch from below and above, a climbing player, tower and hospital lift doors, a player seated and swivelled at the south desk, and a player on a handrail, a chain and a lamp globe. Corrected from renders: first swivel and stairs views were inside walls (camera only).

Limitations and open items: swivel is verified with simulated A/D events and a seated pose, not in a live session; the player sits through the chair turn with the existing seated animation. Climbing speed, grab zone and the hop-off are first values, not tuned by play. Standing on the suspension chains where they are steep (near the towers) will slide; the stone tower tops and the cables' outer hangers are still not standable. The ladder, stair walls and empty level have no vocabulary words (no *ladder* word was added). The empty 16.5 level has only a ceiling light and the hatch ladder; nothing is furnished. The full suite was not rerun.

## 2026-10-29 performance assessment (measurement only, no game code changed)

Godot 4.7.2, GL Compatibility, 1280x720, macOS, vsync off, player teleported to 14 spots, median of 100 frames. GPU time is not reported by the Compatibility renderer, so CPU render submission (`rcpu`) is the usable split. Scripts and raw output live in the side-session notes folder (`perf/`), not the repository.

| Fact | Measured |
| --- | --- |
| Build time / nodes / MeshInstance3D | about 18 s / 49,248 / 23,455 (3,571 hidden), 304 MultiMeshInstance3D |
| Triangles if everything drew | 5.7 M; 7,910 unique meshes, 2,650 materials, 6 custom shaders |
| Collision | 3,618 Area3D (2,315 monitoring), 5,896 CollisionShape3D, about 14,000 collision pairs at every spot; physics step 0.4 to 0.9 ms |
| Lights | 124 OmniLight3D (none shadowed), one shadowed sun (max distance 100); removing the omnis changes nothing measurable |
| Median frame ms (draws) | street 16.5 (9.7k), north road 33 to 39 (13 to 20k), park 19 to 22 (7 to 9k), zoo 17, farm 13, beach 15, sea view 4 (227), airport 24 (9 to 11k), tower 30 (15 to 17k), hospital 31 (17k), supermarket 13 to 15, furniture 24, school 27, home 11 |
| Render scale 0.75, MSAA 4x | no change, so the game is CPU draw-submission bound, not fill-rate bound |
| Sun shadow off | street 16.7 to 8.4 ms (draws 9.7k to 2.7k); park -6 ms; airport -6.5; supermarket -5.5; beach -5 |
| Sun shadow max distance 40 / 80 / 150 | street 12.7 / 15.3 / 17.2; north road 32.9 / 37.1 / 45.9; other spots within 2 ms |
| Small props (<1 m) not casting shadows | street 16.8 to 12.1; tower -2.3; furniture -1.9; others about -1 |
| Camera far 150 / 80 | park 22.6 to 12.4 / 7.4; airport 25.5 to 16.5 / 9.1; street and supermarket barely change |

Limits: the 600-frame teleport run (58 to 76 ms median) moves the player 0.4 to 0.9 m per frame and is not representative of walking; screenshots of the interior spots were not all checked, so some spots may see through walls to other buildings. No real driving trace was recorded.

### 2026-10-29 render trim (implemented: `scripts/world/render_culling.gd`)

Applied once at the end of `Main._ready` (after garden batching): sun shadow max distance 100 to 50; meshes under 1 m stop casting sun shadows and hide beyond 60 m; meshes 1 to 3 m under Buildings, RelocatedSites, Restaurants and Airport hide beyond 70 m. 12,198 meshes affected. Nodes, collision, word areas, door metadata and interior roots are unchanged; animals, characters, vehicles and the player are skipped. Same bench as above, median ms (draw calls), before then after:

| Spot | Before | After |
| --- | --- | --- |
| Street | 16.5 (9.7k) | 10.6 to 12.1 (3.3k) |
| North road | 33 to 39 (13 to 20k) | 19 to 20 (7.3k) |
| Park | 19 to 22 (7 to 9k) | 12 (3.3k) |
| Zoo / farm | 17 / 13 | 8.7 / 8.7 |
| Beach west | 15 (5.8k) | 9 (2.2k) |
| Airport | 24 (9 to 11k) | 16.5 (4.6k) |
| Tower | 30 (15 to 17k) | 18 (7.3k) |
| Hospital | 31 (17k) | 17 to 23 (7.8k) |
| Supermarket / furniture / school | 13 to 15 / 24 / 27 | 11.6 / 14.5 / 17 |
| Home | 11 | 9 |

Run-to-run spread is about 1.5 ms, with one 23 ms outlier at the beach that did not repeat. Checks: `check_runtime_resources` 360 resources, 0 failures; `check_compact_layout` 684 checks, 0 failures; `check_interaction` pass. Street, park and hospital views were inspected in rendered captures with no visible change except lost small-prop shadows. Not done: hiding whole interior or exterior roots by player position, and the north road, hospital and school still run above 16.7 ms. Not tested: a live driving or walking session, and running the full suite.

### 2026-10-29 render trim, phase 2 (segments, ranges, static batching)

The rules are in [performance/README.md](performance/README.md#town-wide-render-trim--29-october-2026). Changed: `render_culling.gd`, plus one tag line each in
`garden_rendering.gd` and `interaction_controller.gd::highlight_object`. On a normal
start: 18,765 meshes get ranges, 1,438 round meshes are simplified, and 10,258 meshes
are merged into 2,524 batches. Startup was 11.3 s before and 11.6 s after (one run
each).

Bench: an isolated project copy, Godot 4.7.2 GL Compatibility, Apple M5, 1280x720,
vsync off, a fixed camera, 30 warm-up frames, median and p95 of 90 frames, with the
player's physics paused. "Before" includes the phase-1 trim above. "Kitchen" is the
camera at local (10, 1.7, 30), which is inside the home kitchen. Draw calls are in
parentheses.

| View | Before ms | After ms |
| --- | --- | --- |
| Bridge (`benchmark.gd` camera) | 17.6 (4.9k) | 12.9 (3.1k) |
| Player eye | 9.8 (3.5k) | 8.1 (2.1k) |
| Aerial, 120 m up | 27.5 (8.2k) | 15.5 (3.8k) |
| Low flight | 28.7 (8.8k) | 16.5 (4.0k) |
| Kitchen | 24.7 (8.0k) | 18.1 (5.0k) |
| Supermarket / school interior, draw calls only | 8.4k / 2.5k | 5.3k / 1.8k |

The after-runs were repeated twice and agreed within 0.7 ms. The sphere and cylinder
triangle total dropped from about 2.0 M to 0.1 M; the plush characters (about 0.6 M
triangles) now hide past 45 m.

Checks, headless at 60 fixed fps, isolated user directory. Every result matches the
baseline run before the change:

| Check | Result |
| --- | --- |
| `check_runtime_resources` | 362 resources, 0 failures |
| `check_interaction` | pass |
| `check_compact_layout` | 684 checks, 0 failures |
| `check_public_garden` | 0 failures, 1,638 path samples |
| `check_road_physics` / `check_vehicle_boarding` | 153 / 73 checks, 0 failures |
| `check_hospital_departments` | 0 failures |
| `docs/guides/performance/check_rendering` | **1 failure**, `beach retains its own material` (also on baseline) |
| `docs/evidence/part2/verify.gd` | 1,304 checks, **3 failures**, Home garage-door drive clearance (also on baseline, from the uncommitted garage-door work) |
| `check_seats_and_swan_boats` | **1 failure**, airport seats 53/54 (also on baseline) |
| `check_zoo_vehicles` | 99 checks, **2 failures**, `gate translation` / `gate vocabulary popup` (also on baseline) |
| Scratch highlight probe | 200 merged word meshes become visible with an overlay while highlighted and hide afterwards; no door or Home-roof mesh merged |

Rendered and compared with the before captures: bridge, player eye, aerial, low flight,
kitchen, supermarket and school interiors. Exteriors match. Zoo animals, parked cars,
swan boats and the hospital helicopter disappeared in the first attempt (ranges were
set per part) and were restored by sizing whole objects. A kitchen dish was visibly
faceted at 12 segments, so the minimum is now 16. Interiors differ in lighting only,
because of the per-frame light cap (see the performance guide); with the cap raised,
before and after are identical.

Not done: a live walking, driving or flying session (pop-in was judged from stills
only), an export build, other hardware, and the remaining suite.

#### 2026-10-31 light cap raised to 256

`project.godot` sets `rendering/limits/opengl/max_renderable_lights=256` (default
32). Two Godot processes left by other sessions (a hung `check_compact_layout`, about
two cores for over a day, and a stale `_tmp_sports_only.gd`) were stopped first. They
were also running during the 29 October bench above, so its absolute times are
inflated, probably on both sides. Bench (1280×720, isolated copy, median ms of two
alternating runs; draw calls unchanged between caps):

| View | Cap 32 | Cap 256 |
| --- | --- | --- |
| Bridge | 11.9 / 11.7 | 11.5 / 11.7 |
| Player eye | 7.1 / 7.4 | 7.4 / 7.2 |
| Aerial | 12.6 / 13.8 | 12.0 / 12.2 |
| Low flight | 15.1 / 14.4 | 13.1 / 13.2 |
| Kitchen | 15.4 / 15.4 | 15.1 / 15.7 |
| Supermarket interior | 15.4 / 15.3 | 15.3 / 15.4 |
| School interior | 7.7 / 7.6 | 8.4 / 7.8 |

Pixel comparison (share of pixels changed by more than 6%): the merged town at cap 32
and cap 256 is identical in all seven views (aerial 0.16%). The merged town matches
the unmerged town at 256 (school 0.14%, supermarket 0.18%). The unmerged town at 32,
re-rendered today, differs from both (school 7.2%, supermarket 20.3%). So the
interior shift recorded above restores dropped lights; merging did not lose any. Checks
with the new setting: `check_runtime_resources` 362, 0 failures; `check_interaction`
pass; `check_public_garden` 0 failures. Other checks were not rerun, since headless
runs do not exercise the renderer limit.

## 2026-10-29 home living room, seating and NPC placement

Changes: entry L-group couches and family TV removed (one sofa, one TV remain); patio topiary moved to the glazing so it clears the armchairs; patio chairs respaced; Miso on a blue armchair, Leo and Bruno on the sofa, BonBon/Sunny/Awoo at the dining table, Poppy and Twinkle on the patio armchairs, Cocodrilo unmoved in the pool (`data/house_characters.json`, `facing` accepts `[x, z]`). Also in the tree, from a separate session: the Subaru Outback-style west garage car (see `REFERENCE_HOME.md`).

Isolated user directory (symlinked project copy, README `custom_user_dir_name`), headless unless noted: `check_runtime_resources` 361 resources, 0 failures; `check_compact_layout` 684 checks, 0 failures; `check_reference_home` doors, 191 clearance samples, roof/taxi all passed; `python3 tools/word_data.py` ran. A probe confirmed one home sofa and one TV. Graphical captures (living room, top view, patio, dining) inspected: animals seated on seats, no visible floating or clipping, plants clear of chairs.

Not run or not conclusive: `check_home_refresh` and `check_house` time out on baseline and changed trees alike (see above); `docs/evidence/part2/verify.gd` and the vehicle-physics checks were not rerun; the old `check_home_refresh` Sofa assertion targets the editor snapshot, not this runtime layout. Armchair angles and the Samoyed on a dining end chair were judged from stills only.

### 2026-10-29 ceiling, roof, door, Subi

Isolated project, headless: `check_reference_home` (8 doors, 191 clearance samples, roof and taxi) passed; `check_compact_layout` 684 checks, 0 failures. A probe confirmed the car root carries `character_name` "Subi" and that body colliders resolve to it. Rendered: interior walls at the new height, front door open into the hall (leaf inside), exterior with the roof seated on the walls. Not checked: the roof toggle while walking (derived from the rectangles, not a live session), a click on the car in a live session, `docs/evidence/part2/verify.gd`, `check_home_refresh` (known time-out).

### 2026-10-29 ceiling, roof gap, seating and garage doors

Changes are listed in [REFERENCE_HOME.md](REFERENCE_HOME.md#ceiling-roof-seating-and-garage-doors--29-october-2026-user-request). All runs used the isolated user directory.

- `check_reference_home` (headless): 8 doors open and close, including the reversed access door; 191 clearance samples; roof visibility and taxi driver all passed. One intermediate layout, with the north end chair pulled out, failed the z 4.25 walkway route and was reverted.
- Scratch garage script (graphical): 14 checks, 0 failures:
  - starts closed and blocks the opening;
  - a second press mid-travel reverses (step 0.026);
  - rapid presses stay in range;
  - opens fully, the doorway is clear, and sections sit above the opening;
  - reopens with the player under it;
  - closes fully;
  - E outside opens it, E 7 units away does not, and the access door is unaffected;
  - the access door leaf ends at x 4.5, on the living-room side;
  - the sofa front points at the TV.
- Vertex probe of the seated plushes against solid colliders: the only contacts are the intended 0.07 cushion sink, plus a 1 mm backrest touch for Sunny. BonBon, Sunny and Awoo had clipped the dining table before the chairs moved.
- Rendered and inspected: living room toward the TV, the sofa seen from the TV, the armchair cat, dining from two sides, the patio, the ceiling, the front wall by the PATIO sign, the west and garage-wing eaves, an aerial corner, the pool-side soffit, the garage door closed, opening, open (from outside and inside) and closing, and the access door open.

Not done: a live keyboard session, so E was exercised by calling Main's handler, not a key event. Driving a car out through the opened door was not tested. `check_runtime_resources`, `check_compact_layout`, `docs/evidence/part2/verify.gd` and `check_home_refresh` (known time-out) were not rerun.


## 2026-10-29 Subi driving, shared road handling and car boarding animation

Changes are described in [ZOO_VEHICLE_IMPLEMENTATION.md](ZOO_VEHICLE_IMPLEMENTATION.md) ("Shared controller and handling").
Root cause: Main registered only `Vehicles/` children (plus the helicopter), so Subi (`RelocatedSites/Home/SubaruOutback`) and the school bus were never offered to E. Twelve vehicles are now registered through the `driveable_vehicles` group.

These checks used an isolated project copy with its own user directory, headless at 60 fixed fps:

| Check | Result |
| --- | --- |
| `check_vehicle_boarding.gd` (new) | 73 checks, 0 failures. Subi is registered, keeps its name card, and is picked at its driver door. E boards; the door opens more than .9 rad; BonBon reaches the seat, then hides. W does nothing during boarding. With the garage door open, Subi drives out, brakes, exits via the door sequence, and collision returns. Fast-road pad for all 10 road vehicles: top speed is 1.5–2× the former 14 m/s, with a full-lock slip of .06 or less and yaw of .35 rad/s or less, and each brakes to a stop. |
| `check_road_physics.gd` | 153 checks, 0 failures. Speeds after 3 s: Car 16.4 (was 12.5), Bus 8.5, Police 18.5 |
| `check_compact_layout.gd` | 684 checks, 0 failures. The count is updated to 12 vehicles. |
| `check_zoo_vehicles.gd` | 99 checks, 2 failures: `gate translation` and `gate vocabulary popup`, the same labels as the baseline. The test now waits for the boarding and exit sequences. |
| `check_vehicle_collision.gd` | 0 failures |
| `check_helicopter_physics.gd` | 34 checks, 0 failures |
| `check_aircraft.gd` | 30 checks, **1 failure**: `airplane vocabulary` expects the category "Transportation", but the committed `words.json` says "Vehicles". The test label is stale. This change does not touch it, and it is not fixed. |
| `check_seats_and_swan_boats.gd` | **1 failure**: airport seats 53/54, already known (see above) |

Handling on the fast pad (top / 0–14 m/s / braking from top): Car and Subi 25 m/s, 2.6 s, 35 m. Police 27, 2.2 s, 41 m. Motorcycle 27, 2.1 s. Bus and school bus 21, 5.2 s, 24 m. Fire truck 21, 4.5 s.

Rendered with `render_vehicle_boarding.gd` and inspected, in `docs/evidence/vehicle-boarding-20261029/`: approaching Subi, the door open, BonBon climbing in, seated with the door closed, driven out, getting out with the door open, on foot at the door, and the police-car door. The police door is dark like its body.

Not done:
- A live keyboard session. E was exercised through Main's handler, not real key events, and the camera ease was judged from code and stills, not from motion.
- `check_aircraft` boarding was checked headless only; the plane's renders were not redone.
- `check_road_physics` render, `docs/evidence/part2/verify.gd` and `check_home_refresh` (known time-out) were not rerun.
- The garage door (from another session) must be opened manually before Subi can leave.


## Animal wandering and measured minimum scale — 31 October 2026

Authoritative guide: [Animal system](ANIMAL_SYSTEM.md). Shared 20-animal wandering
now selects random destinations, pauses/rests, uses species speeds, stays in inset
habitats and avoids solids/nearby peers. Runtime visible BonBon height 2.239191 and
pre-change snake height 1.014 world units establish the fixed minimum; all 21
species / 30 animal instances satisfy it, including 10 coastal crabs. Uniform
scales and fitted instance-owned picking shapes preserve designs and interaction.

Validation used isolated copied projects and `VocabularyTownChecks/animals` saves:

| Check | Result |
| --- | --- |
| Runtime resources, before / after | 362 checked, 0 failures in both |
| `check_animals.gd` | 30 measured instances, 20 walkers, 0 failures; two simulated minutes at 60 Hz; heights, fitted boxes, picking rays, walk/pause, containment and explicit solid obstacle |
| Movement distance | Every walker moved; smallest maximum excursion 0.756 town units |
| Controller + check cost | 0.0896 ms/frame across all 20 walkers |
| Rendered zoo/farm | Inspected `docs/evidence/animals-review/zoo.png` and `farm.png`, BonBon included for scale |
| Rendered farm, disabled/enabled movement | Medians disabled 7.022/7.322 ms; enabled 6.332/9.213 ms; p95 disabled 9.174/9.364, enabled 9.590/9.930 ms. Short samples vary; no consistent large regression, not a universal performance guarantee. |
| Part 2 baseline / after | 1304 checks, identical 3 garage-drive failures at sample 21 and offsets -1.4/0/+1.4; all animal assertions pass |
| Older zoo test | 20-animal portion completes; later historical remodeled-building `InteriorDetails` assertion fails at line 46. Not a clean whole-test pass. |

The new dedicated test is the animal verification entry point. Existing animal
expectations in Part 2 now account for the minimum overriding small-species height
and aquatic length targets. No unrelated garage/building changes were made. Tests
cover current authored habitats, not arbitrary future obstacle mazes. Original/final
measurement JSON and images live in `docs/evidence/animals-review/`. No commits were made.

## Plush outfits — 31 October 2026

Guide: [Plush outfits](REFERENCE_HOME.md#plush-outfits--31-october-2026-user-request). New: `scripts/characters/plush_costume.gd`, `data/plush_costumes.json`, `docs/evidence/town-checks/check_plush_costumes.gd`, `docs/evidence/town-checks/capture_costumes.gd`. Changed: `house_characters.gd` (an optional `costume` key, dressed after placement; `_extent()` skips `Costume`). No plush scene, sculpt, position or save format changed, and no Home plush is dressed by default.

Validation used an isolated copied project (`VocabularyTownChecks/isolated`):

| Check | Result |
| --- | --- |
| Runtime resources | 363 checked, 0 failures |
| `check_plush_costumes.gd` | 164 checks, 0 failures: 4 outfits × 9 plushes seated, plus the Main integration on the 9 placed Home plushes |
| Mutation test | Re-introducing the angle-lookup bug found during development (`posmod` on a float) produced 36 failures ("Garments outside the body"), so the fit check is not vacuous |
| Rendered: `capture_costumes.gd` | Front, three-quarter and back sheets inspected for all 4 outfits seated, plus doctor and police standing. No wool, fur, ridge or ears poke through. |
| Rendered in game | In the isolated copy only, all nine Home plushes were dressed in `house_characters.json` and photographed where they sit. Outfits follow the seated recline on the sofa, armchairs and dining chairs. Cocodrilo's crown spikes hide under the cap, and his uniform is mostly underwater. |

Not run: `docs/evidence/part2/verify.gd` and the other integration suites (no shared code changed beyond `house_characters.gd`'s optional key), and a live mouse click in a played session (resolved through `vocabulary_target`/`show_word` instead). Known limit: white coats have low contrast on Awoo and Poppy.

**Revision, same day (user request).** Shopkeeper: white shirt with short sleeves under a wider bib (0.3) that tapers over a longer waist, so the shirt no longer reads as a top layer over the apron. Leo: mane tucked into the collar under any shirt (`tuck` in `plush_costumes.json`, `_tuck()` in `plush_costume.gd`). Characters: permanent unique `id` per entry in `house_characters.json`, used as node name and `character_id` metadata; names are display only.

| Check | Result |
| --- | --- |
| Runtime resources | 363 checked, 0 failures |
| `check_plush_costumes.gd` | 190 checks, 0 failures (adds mane-tuck and id checks) |
| Mutation test | Disabling `_tuck()` produced 8 failures ("Tucked under the shirt", Leo × 4 outfits × front and back mane) |
| Rendered: `capture_costumes.gd` | All 4 outfits seated, front, three-quarter and back: shopkeeper apron over a white shirt, Leo's mane framing the face with chest details visible |
| Rendered in game | Isolated copy with five plushes dressed: Leo (police) on the sofa and BonBon (shopkeeper) at the dining table; nodes are named by id |

**Revision 2, same day (user request).** Leo's mane and Poppy's wool showed between the police cap's band and crown. The cap now sinks into the hair (`hat_sink` 0.08 / 0.10), and `_press()` flattens the hair copy below the band's lower edge under the cap, sloping down beside it (`press` in `plush_costumes.json`).

| Check | Result |
| --- | --- |
| Runtime resources | 363 checked, 0 failures |
| `check_plush_costumes.gd` | 193 checks, 0 failures (adds "Hair stays under the cap" for Leo and Poppy) |
| Mutation test | Disabling `_press()` produced 3 failures (Leo front and back mane, Poppy wool) |
| Rendered: `capture_costumes.gd` | Police sheets at front, three-quarter and back: band fully visible on Leo and Poppy, no hair through it; other plushes unchanged |
| Rendered in game | Isolated copy: Leo (police) on the sofa and Poppy (police) on the patio armchair |

**Revision 3, same day (user request).** Five new outfits from the user's reference sheet: `driver`, `teacher` (no glasses, user decision), `gardener` (farmer/gardener/zookeeper, straw hat with the ears through the brim, user decision), `pilot`, `businessman`. New pieces: `tie`, `overalls`, `pocket_square`, `wings`, `straw_hat`; `shirt` gained lapels, button columns/counts, sized pockets and cuff stripes; `cap` gained a cord and bus/wings emblems. Doctor: thicker stethoscope draped round the neck with a large round chest piece, and a larger chest pocket with two pens.

| Check | Result |
| --- | --- |
| Runtime resources | 363 checked, 0 failures |
| `check_plush_costumes.gd` | 374 checks, 0 failures: 9 outfits × 9 plushes, plus overalls and ties in the outside-the-body check, straw-hat crowns clearing the ears and hair staying under the brim |
| Mutation test | Skipping the hair press under the straw hat produced 3 failures (Leo's front and back mane, Poppy's wool). Run before the final change that rests the hair on the brim's underside; the check's limit was tightened to that same underside. |
| Rendered: `capture_costumes.gd` | Front, three-quarter and back sheets inspected for all five new outfits and the doctor. Fixed during review: straw-hat brim too small, teacher's vest hem showing through the blazer, stethoscope reading as a bar across the shoulders. |
| Rendered in game | Isolated copy with eight plushes dressed (BonBon and Poppy gardener, Leo pilot, Bruno doctor, Sunny businessman, Miso and Awoo teacher, Twinkle driver); Bruno, Leo and Poppy inspected where they sit |

Windowed renders sometimes stalled with no output while another Godot process was running; a retry completed. Not run: `docs/evidence/part2/verify.gd`, a live mouse click. Known limit: a wide flat brim leaves a visible gap over dome-shaped heads (Poppy), as a real hat would.

**Revision 4, same day (user request).** New `chef` outfit: black double-breasted coat (`stand_collar`, two button columns) and a black toque (`chef_hat`, built as CapBand/CapCrown so the cap checks cover it). The ear check now compares ears with the hat crown's own width per 0.02 height band, not its bounding box, because the toque's puffy top is wider than its body.

| Check | Result |
| --- | --- |
| Runtime resources | 363 checked, 0 failures |
| `check_plush_costumes.gd` | 415 checks, 0 failures (10 outfits × 9 plushes) |
| Mutation tests | A toque as wide as 2 × its radius from the base produced 3 failures (bear, cat, samoyed ears). An unlimited puff or flare alone produced none: the ear tips sit below the toque's top. |
| Rendered: `capture_costumes.gd` | Chef front, three-quarter and back on all nine. Fixed during review: the first toque read as a top hat (puffy top enlarged), and the pocket pen was lost against black (removed). |
| Rendered in game | Isolated copy: Sunny as the chef at the dining table |

Windowed renders stalled twice more with no output and completed on retry.


## Hospital pharmacy, side-tower elevator and roof access — 31 October 2026

Guide: [hospital guide](HOSPITAL_THREE_FLOORS.md#pharmacy-side-tower-elevator-and-roof-access--31-october-2026). These checks ran in an isolated copied project (`VocabularyTownChecks/isolated`). The HEAD baseline came from a second copy.

| Check | Result |
| --- | --- |
| `check_hospital_remodel.gd` (headless) | Before: 720 checks, 0 failures (adds fridge ray checks: frame resolves to refrigerator, interior does not). After: **1087 checks, 0 failures**. The new checks cover the pharmacy door, shopfront and counter, the open lounges, the roof stairs and door, the parapet, both ramps, and the four-stop elevator with the AZOTEA stop. |
| `check_hospital_departments.gd` | 24 room words, 0 failures |
| Regenerating `hospital.tscn` before any edits | Byte-identical to the committed file |
| Load warnings | The four stale helipad parapet overrides in `town_public_garden.tscn` were removed, along with their 8 unused sub-resources. Only the old 15 `specular` material-remap warnings remain. |
| `check_hospital_stair_access.gd` (graphical, real W input) | 2 of 4 runs clean; minimum camera clearance 1.95 (baseline 2.07). Failures stop at random points on open floor. The HEAD baseline also failed once under the same conditions, because the user's own Godot window was open. |
| Rendered views (Main, isolated copy) | Front, front-left, front-right, aerial, rear, the floor-1 hall and pharmacy (3 views), lounges on floors 2–3, the lift lobby, the roof landing, the roof door, inside the stair house, the floor-3 flight and the roof ramp. All were inspected; the colour bars are gone, and there was no clipping. |

Removed: `docs/check_hospital_floors.gd`. It tested the superseded switchback routes and the pre-resize school stairs, and failed at HEAD (16 failures) as well as after this change (14 failures).

Not run:
- `docs/evidence/part2/verify.gd` and the full suite, so the suite is not claimed to be clean.
- The `docs/evidence/hospital-remodel/` cutaway re-capture; those images still show the 27 October layout.

Known issues:
- `check_rooftops.gd` was already broken before this work: it references the missing `HouseStructure/HomeRoof`. Only its hospital sample path was updated.
- This change took far longer than its size warranted, because of repeated full-town graphical runs. A verification budget is now recorded in the hospital guide.

## Hospital polish — 31 October 2026

Isolated copy (`custom_user_dir_name="VocabularyTownChecks/isolated"`), Godot 4.7.2.
Details: [hospital guide](HOSPITAL_THREE_FLOORS.md#polish-floors-reception-waiting-room-anatomy-model--31-october-2026).

| Check | Result |
| --- | --- |
| `python3 tools/word_data.py` | 511 words, 13 aliases, no problems |
| `check_runtime_resources.gd` | 361 checked, 0 failures |
| `docs/evidence/hospital-polish-20261031/verify.gd` run 1 | 1 failure, a test artifact (face pick aimed at the nose); renders showed the sheep missing (left behind by `compact_town()`) and an interior eave/post |
| `docs/evidence/hospital-polish-20261031/verify.gd` run 2, after fixes | 99 PASS, 0 failures; 8 views in `docs/evidence/hospital-polish-20261031/after/` |

Not re-run: the sheep doctor's height was raised from 2.0 to 2.7 town units after run 2
(its face only peeked over the counter); that last view is not re-rendered. The hospital
exterior-word glow case wasn't exercised: no `exterior_word` node was found under the
hospital, so only the road and a small object were checked. `check_hospital_remodel.gd`,
`check_hospital_departments.gd`, `check_interaction.gd` and the other suites were not run.

## People, vehicles, posters and pizza entrance — 31 October 2026

Isolated `HOME`, Godot 4.7.2, windowed 1200×900. Design record:
[town brief](TOWN_DESIGN_BRIEF.md#people-vehicles-classroom-posters-and-pizza-entrance--31-october-2026).

| Check | Result |
| --- | --- |
| `python3 tools/word_data.py` | 507 words, no problems |
| `docs/evidence/town-checks/check_vocabulary_translations.py` | 2 pre-existing issues only (`hair` has two translations; `crocodile_plush.tscn` has no `crocodile` word); `pilot` added to its multi-option list |
| `docs/evidence/town-checks/check_vocabulary_categories.py` | 1 pre-existing failure (same crocodile key) |
| `docs/evidence/people-vehicles-posters-20261031/verify.gd`, first runs | did not compile (two GDScript type-inference errors in new code) and then 7 failures from duplicate node names; fixed |
| `docs/evidence/people-vehicles-posters-20261031/verify.gd`, last run | 70 PASS, 0 failures; 13 views in `docs/evidence/people-vehicles-posters-20261031/after/` (poster symbols "1 km"/"D+1" were shrunk after a first render showed them overlapping the Spanish word) |

The earlier `docs/evidence/hospital-polish-20261031/verify.gd` check "people keep their torsos" reads `People/Teacher`, which no
longer exists; that one check is stale, not a regression. Removed word keys in a learner's save are dropped on load by
`VocabularyProgress.normalize_studied_words`. The scene files `scenes/characters/{firefighter,teacher,student,driver}.tscn` are kept because the saved `town_public_garden.tscn` and the older snapshots still reference them; the live game frees those people at startup.
Not run: `check_interaction.gd`, the vehicle/metadata suites and the other full checks.

## Alta Cocina Italian remodel and plush staff — 1 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#alta-cocina-italian-remodel-and-plush-staff--1-november-2026).
Godot 4.7.2 with `HOME` pointed at a scratch folder (isolated `user://`); each check was
run once on the finished change, in a separate working copy. No HEAD baseline was run.

| Check | Result |
| --- | --- |
| `tools/word_data.py` | 519 words, 13 aliases, 19 categories; valid |
| `check_vocabulary_translations.py` | 2 issues, both unrelated and present in HEAD's data: `hair` has two options; `crocodile_plush.tscn` uses unknown key `crocodile` |
| `check_vocabulary_categories.py` | 91589 checks, 1 failure (the same `crocodile_plush.tscn` / `crocodile` label) |
| `check_runtime_resources.gd` | 360 checked, 0 failures (`cook.tscn` deleted; nothing references it) |
| `check_zones.gd` | 5092 checks, 0 failures |
| `check_compact_layout.gd` | 669 checks, 0 failures |
| `docs/evidence/restaurants-20261028/verify.gd` | 230 checks, 0 failures |
| `docs/evidence/bakery-cafe-interior-20261028/verify.gd` | 174 checks, 0 failures (cook check now reads `People/SamoyedCook`) |
| `docs/evidence/town-polish-20261028/verify.gd` | 1 failure: "terrain opening is a second surface; minimap outline untouched" (home pool terrain mesh, not touched by this work; not compared with HEAD, cause unknown — **P2** to investigate) |
| `docs/evidence/alta-cocina-20261101/verify.gd` (new) | 199 checks, 0 failures |

The new check covers: `cook.tscn` absent with no instances; eight plush staff (species,
word, outfit, world scale 1, click resolving through `vocabulary_target` to the word);
the bakery cook's site tag; the host waiter facing the door; 36 words placed in Alta
Cocina and present in the vocabulary, coffee on the terrace; kitchen corners inside the
zone; building width 30.6; a capsule route door → kitchen → chef, with two negative probes.

Rendered inspection (graphical run, PNGs in `docs/evidence/alta-cocina-20261101/`): front,
terrace, rear, dining, entrance, table, booth, bar, pass, kitchen, taquería,
Pizza and Burger, bakery. Limits: not played live (terrace seats, clicking staff and the
journal's By Area listing were not exercised by hand); no frame-time measurement after
adding several hundred small meshes; the bakery's existing BOTANAS label hangs in front
of the cook from the customer side; plushes are shorter than the bar, so the beagle
bartender shows head and shoulders.

## Alta Cocina revision — 1 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#alta-cocina-revision-entrance-booths-floor-ceiling-roof--1-november-2026).
Godot 4.7.2, `HOME` pointed at a scratch folder (isolated `user://`); each check run once on
the finished change. No HEAD baseline was run.

| Check | Result |
| --- | --- |
| `docs/evidence/alta-cocina-revision-20261101/verify.gd` (new) | 21 checks, 0 failures |
| `docs/evidence/alta-cocina-20261101/verify.gd` | 199 checks, 0 failures |
| `docs/evidence/restaurants-20261028/verify.gd` | 230 checks, 0 failures |
| `check_zones.gd` | 5092 checks, 0 failures |
| `check_compact_layout.gd` | 669 checks, 0 failures |
| `check_runtime_resources.gd` | 360 checked, 0 failures |

The new check covers: no named mesh in the doorway (render-batch meshes are skipped, since
batching merges props into one large box); slat dividers gone; six booth shells and backs;
no square-table cloths, round cloth kept; *tablecloth, table, bench, chair, ceiling* still
taught; each booth's open end reachable; quatrefoil floor present; ceiling at 6.47; width
30.6; both hip roofs built; motorcycle on the lot, between stall stripes, > 5 from the door,
upright.

Rendered inspection (graphical run, PNGs in `docs/evidence/alta-cocina-revision-20261101/`): front,
aerial, rear, doorway, motorcycle, entrance, dining, booths, booth-close, booth-seated, tables, bar, floor.
Limits: not played live (riding the motorcycle out of the stall and sitting in the booths
were not exercised; booth seats are not sittable, as before); no frame-time measurement;
the bottle wall still draws bottles across the arched back door's upper part (as before);
the other vehicle, interaction and metadata suites were not run.

**Booth enlargement and seats (same day, later):** re-ran once after the change:
`docs/evidence/alta-cocina-revision-20261101/verify.gd` 28 checks, 0 failures (now also: enlarged shell
sizes; six booth seats registered by the seating controller, each at its bench's aisle end
and facing its table; aisle probes at the new booth positions); `docs/evidence/alta-cocina-20261101/verify.gd`
199/0; `docs/evidence/restaurants-20261028/verify.gd` 230/0. Renders `booths.png`, `booth-close.png` and the
new `booth-seated.png` (eye at the outer seat) re-captured. Not played live: sitting down and
standing up by hand were not exercised.

## Storefront exterior redesign — 1 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#storefront-exterior-redesign--1-november-2026).
Godot 4.7.2, macOS, GL Compatibility, temporary copy with an isolated user directory
(`VocabularyTownChecks/isolated`); each check run once on the finished change.

| Check | Result |
| --- | --- |
| `docs/evidence/exterior-redesign-20261101/verify.gd` (new) | 63 checks, **1 failure** |
| `check_runtime_resources.gd` | 360 checked, 0 failures |

The new check covers, for each of the eight fronts: no solid facade parts; flower boxes
present (supermarket exempt) and not pickable; wall lamps present; door approach, threshold
and first inside step clear for a player capsule; a street ray at a side window still names
the building; exactly one visible Spanish name sign.

The one failure is **existing**, not from this change: the clothing approach probe 1.6 units
outside the door hits `RelocatedSites/Clothing/Shoes2/Footprint`, a shoe word prop standing on
the entrance path (visible as the pink pair in both renders). Priority: low; move it aside in a
clothing task if the user wants a clear approach.

Rendered inspection (graphical run, 1200 × 800, PNGs in `docs/evidence/exterior-redesign-20261101/`
`before/` and `after/`): one oblique street view per building. Found and fixed during review:
the furniture green frame was not recoloured (reparented parts lose readable names; now matched
by exterior tag and colour, plus the shell's `Lintel_15`); the police shell's cream sign panel
covered the new sign; supermarket and school icons were on the viewer's right.

Not run: the older `check_school_exterior.gd`, `check_supermarket_exterior.gd` and
`check_cafe_bank_exteriors.gd` compare against their 25 October visuals and colours, which this
approved restyle changes on purpose; `check_building_exteriors.gd` (uses `town_complete.tscn`,
not this pass); zone, compact-layout, vehicle and interaction suites. Not played live; no
frame-time measurement (about 220 small flower and leaf spheres were added).


## Playground rebuild and rideable swings — 1 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#playground-rebuild-and-rideable-swings--1-november-2026).
Godot 4.7.2, macOS, GL Compatibility, `HOME` pointed at a scratch folder (isolated `user://`).

| Check | Result |
| --- | --- |
| `docs/evidence/playground-20261101/verify.gd` (new) | 51 checks, 0 failures |
| `check_runtime_resources.gd` | 362 checked, 0 failures |
| `check_seats_and_swan_boats.gd` | 0 failures (re-run after fixing a `get_meta(key, null)` error log it exposed) |
| `check_interaction.gd`, `check_vocabulary_aliases.gd` | pass |
| `check_compact_layout.gd` | 669 checks, 0 failures |
| `word_audit.gd` | completes; Sports & Play 24 words, 24 placed |
| `check_vocabulary_categories.py` / `check_vocabulary_translations.py` | 1 / 2 failures, all **existing** (`crocodile_plush.tscn` uses unknown key `crocodile`; `hair` has two options) |

The new check drives Main with real key events. Structure: old equipment removed, sandbox /
tent / ball kept, nine words taught, pad inside the zone and larger than the old oval, floor
rays land on the bridge (1.90), deck (2.20), stairs ramp, slide and merry-go-round. Swing:
two seats registered and unbatched; E sits; holding W gives one kick (0.25 rad); timed W/S
presses build the arc from 0.14 to 0.58 rad in 4 s and 0.87 rad in 14 s, never past
1.2 rad; mistimed presses slow it (0.64 → 0.40); with no input it slows (0.84 → 0.36 in
~12 s); BonBon stays locked to the seat (0.0000 m / 0.0000 tilt drift), angular speed changes at
most 0.052 rad/s per frame, and no BonBon mesh touches the frame, the other swing or the
ground over a full swing; E while swinging brakes and stands in 2.2 s, level, on clear ground;
E at rest stands at once; walking resumes.

Rendered inspection (1200 × 800, `docs/evidence/playground-20261101/before/` and `after/`): aerial,
front, towers, stairs, slide, merry-go-round, seesaw/monkey bars, and BonBon on a swing at rest,
forward and back. Fixed after review: orange mulch toned to brown, slide legs fitted under
the bed, crawl arch moved off the base face (z-fighting), seesaw lowered so its low end rests.

Limits: not played live with a keyboard (the headless check sends the same key events);
seesaw and merry-go-round are static props; the curb is decorative (no collision); no
frame-time measurement (about 400 small parts, most of them batched).

**Follow-up, 1 November 2026: wider bridge, faster swing.** `verify.gd` now 54 checks,
0 failures (run once). New: a capsule 25 cm wider than BonBon on each side fits at seven spots
from deck to deck (0 blocked); BonBon walks across with W (west deck → x −5.95 on the east
deck, lowest 1.90 on the sag, 0.00 drift); one full free swing takes 2.65 s. Updated
expectations: peak windows 2.7 s (one swing); per-frame angular-speed limit 0.15 (the
restoring acceleration scales with `PACE`), measured 0.104. Arc 0.11 → 0.69 rad after 4 s of
timed presses, 0.96 rad after 14 s; mistimed 0.69 → 0.28; no input 0.37 → 0.14; braking
stands in 1.8 s; clearance, seat lock and exit checks unchanged and passing. Renders
re-captured in `after/`, adding `bridge-bonbon.png` and `bridge-along.png` (BonBon mid-bridge,
clear of both rope sides). Other suites not re-run (only playground files changed).

## Shop staff: bank, sports store, furniture showroom — 1 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#shop-staff-bank-sports-store-furniture-showroom--1-november-2026).
Godot 4.7.2, macOS, GL Compatibility, `HOME` pointed at a scratch folder (isolated `user://`).
Another session's unfinished, untracked `scripts/world/barn_interior.gd` was present in the
checkout and fails to parse; its errors appear in every Main load below. They are not part
of this change.

| Check | Result |
| --- | --- |
| `docs/evidence/shop-staff-20261101/verify.gd` (new) | 26 checks, 0 failures (re-run once after moving the banker clear of the reception monitor) |
| `check_plush_costumes.gd` | 473 checks, 0 failures (covers the two new apron outfits) |
| `check_runtime_resources.gd` | 363 checked, 1 failure: the other session's `barn_interior.gd` parse errors |
| `word_audit.gd` | completes; People 12 words, 10 placed (*banker*, *salesperson* placed; *nurse*, *teacher* still unplaced) |
| `check_vocabulary_aliases.gd` | pass |
| `check_vocabulary_categories.py` | 91589 checks, 1 failure: existing `crocodile_plush.tscn` key `crocodile` |
| `check_vocabulary_translations.py` | 2 existing issues (`hair` two forms, `crocodile` plush key); the new gender pairs pass |

Renders (`docs/evidence/shop-staff-20261101/capture.gd`): [bank lobby](../evidence/shop-staff-20261101/bank-lobby.png),
[banker](../evidence/shop-staff-20261101/bank-banker.png), [sports floor](../evidence/shop-staff-20261101/sports-floor.png),
[sports salesperson](../evidence/shop-staff-20261101/sports-salesperson.png),
[furniture entrance](../evidence/shop-staff-20261101/furniture-entrance.png),
[furniture salesperson](../evidence/shop-staff-20261101/furniture-salesperson.png). The reception desk
(1.0 high) hides most of the banker's suit; the lapels show at the collar. The golden stands
half behind the checkout counter's rear end. Not performed: walking/clicking the staff in a
live session.

## Library refresh — 1 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#library-refresh-reference-table-dictionary-and-atlas--1-november-2026).
Godot 4.7.2, macOS, run in an isolated project copy with
`custom_user_dir_name="VocabularyTownChecks/library-20261101"`. The copy was taken before
other sessions' playground/shop-staff/barn edits, so those were not part of these runs.

| Check | Result |
| --- | --- |
| `docs/evidence/library-refresh-20261101/verify.gd` (new) | 21 checks, 0 failures: word keys, both books resting inside the table footprint and picked by a ray from the aisle, map on the wall without its stand, bin on the floor, five translated signs, six capsule routes (entrance spine, door → table, along the table, rear cross aisle, returns bin, story ledge) |
| `check_runtime_resources.gd` | 362 checked, 0 failures |
| Rendered views | `docs/evidence/library-refresh-20261101/capture.gd`, 8 views before and after; inspected |

Not run: the full suite. `docs/evidence/town-checks/check_public_interiors.gd` still tests the library at its
pre-relocation apartment coordinates, so it no longer covers the relocated library (stale,
low priority); the new verify replaces it for this room. No play-through with the player
walking up and pressing E on the books.

## Farm barn rebuild — 1 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#farm-barn-gambrel-roof-hayloft-and-supplies-interior--1-november-2026).
Godot 4.7.2, macOS, GL Compatibility, `HOME` pointed at a scratch folder (isolated `user://`).
The working tree also held other sessions' uncommitted work (library refresh, shop staff),
so the suite results below include it.

| Check | Result |
| --- | --- |
| `docs/evidence/barn-20261101/verify.gd` (new) | 45 checks, 0 failures (the first run had 2 failures in the check itself: a roof ray on the exact ridge seam, and a drop test that walked BonBon out of the door; fixed and run once more) |
| `check_runtime_resources.gd` | 363 checked, 0 failures |
| `check_compact_layout.gd` | 661 checks, 0 failures |
| `check_interaction.gd`, `check_vocabulary_aliases.gd` | pass |
| `word_audit.gd` | completes; 530 words; 1 **existing** failure (`crocodile_plush.tscn` / `crocodile`) |
| `check_vocabulary_categories.py` / `check_vocabulary_translations.py` | 1 / 2 failures, all **existing** (`crocodile`; `hair` has two options) |
| `check_map_facades.gd` | 4 failures, none from the barn: the **existing** HOSPITAL street ray; 19 fronts (CONTROL TOWER absent); StaticBodies under `FINE DINING` (terrace furniture); two FURNITURE street rays (`furniture_interior.gd` was being edited by another session). `FARM BARN` is present with no bodies |

The new check: old shell and gable slabs removed, 12 × 9 foundation kept, MainRoof ridge
10.68 (top of slate), facade entry and sign present, all twelve barn words placed and
resolving (wheelbarrow study card), four lamp lights; floor rays at 0.16 (floor, doorway,
notch) and 3.0 (loft, three spots); roof hit at four x positions; the player capsule clears
29 points from outside the door to the ladder. Real key events: holding W from the doorway
walks in, grabs the ladder, climbs and steps off onto the loft (ends y 3.00, z 3.79);
holding S walks back into the notch and drops to the floor inside the barn. Second build
adds nothing.

Rendered inspection (1200 × 800, `docs/evidence/barn-20261101/after/`): front, aerial, rear, interior
from the door, both interior sides, ladder, loft, view from the loft, tool rack. Fixed after
review: the farm lawn slab (top 0.12) showed through the first plank floor (top 0.11), so the
floor was raised to 0.16; slate showed between the wall tops and the roof lining and at the
knees, so the lining now starts at the wall top and timber purlins / a ridge beam were added.

Limits: not played live with a keyboard (the check sends the same key events); windows are
painted panels, not openings; door leaves are fixed open; `check_building_dimensions.gd`
(its protected `Barn` fingerprint now changes by design), the part 2 suite and
baseline comparisons were not run; no frame-time measurement (about 600 small parts, four
lights).

### Barn ladder turned, paddock shelter rebuilt — 1 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#farm-barn-gambrel-roof-hayloft-and-supplies-interior--1-november-2026)
(Ladder row and paddock paragraph). Changed: `barn_interior.gd` (notch z 0.6…2.1, ladder
turned to face the door, new `yard()`), `player_controller.gd` (opt-in `ladder_exit`
"forward"; ladders without the meta, i.e. the tower ladder, step off as before),
`docs/evidence/barn-20261101/verify.gd` and `capture.gd`. Run in an isolated copy of the project
(`use_custom_user_dir`, `VocabularyTownChecks/isolated`), Godot 4.7.2, macOS.

| Check | Result |
| --- | --- |
| `docs/evidence/barn-20261101/verify.gd` | 56 checks, 0 failures on the third run. Runs 1 and 2: 2 failures (plank wall and skid counts), caused by `block()` reparenting same-named parts into ParkZoo, which renamed them to `@Node3D@…`; the yard parts now get numbered names. The ladder, floor and climb checks passed on every run |
| `check_runtime_resources.gd` | 363 checked, 0 failures |

New checks: ladder contract (group, height 2.84), ladder +Z points to the barn's −Z from
z 1.85 inside the notch, `ladder_exit` forward; floor rays at the notch's back (0.16) and
just past it (3.0); capsule route clear from outside the door to the ladder foot. Real key
events: holding W from the doorway grabs the ladder, climbs **facing north into the loft**,
and steps off forward onto the loft (ends y 3.00, z 3.79); S walks back into the notch and
drops to the floor. Paddock: the roof keeps *shelter*; all four post heads sit at the roof
underside within its corners; four back planks; trough bottom 0.31 above the ground ray on
two skids, water surface on top.

Rendered inspection (1200 × 800, `docs/evidence/barn-20261101/turned/`): ladder from the door, BonBon
on the ladder, ladder head from the loft, paddock shelter from the trough side and from the
side, plus the earlier barn views. The ladder faces the door and the rails rise through the
notch; the shelter reads as a field shelter with a trough in front.

Limits: not played live with a keyboard; the tower ladder and `check_compact_layout.gd`,
`check_zoo_vehicles.gd` and the rest of the suite were not re-run; animals can still wander
through the shelter posts (they do not collide with props).

## Hospital ward doctors — 1 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#hospital-ward-doctors--1-november-2026).
Godot 4.7.2, macOS, GL Compatibility, run in a scratch copy of the project with the README's
custom user dir (`VocabularyTownChecks/isolated`). Other sessions' uncommitted barn,
player-controller and exterior edits were in the copy; every check ran once.

| Check | Result |
| --- | --- |
| `docs/evidence/hospital-doctors-20261101/verify.gd` (new) | 37 checks, 0 failures: reception sheep unchanged; three doctors exist with unique names, species pig/cat/beagle, word *doctor*, `doctor` outfit, world scale 1, click resolves; lowest point on the floor (0.000), inside the room, doorway lane clear, no furniture bounds overlap |
| `check_plush_costumes.gd` | 473 checks, 0 failures |
| `check_runtime_resources.gd` | 363 checked, 0 failures |

Measured room-local body bounds (x, z): BonBonDoctor 1.32..2.48, −1.75..−0.25 (the exam
counter starts at z −1.75, so the gap there is only millimetres); CatDoctor −2.75..−1.44,
0.95..2.36; BeagleDoctor 1.34..2.59, 0.32..1.68.

Renders (`docs/evidence/hospital-doctors-20261101/capture.gd`): [exam room](../evidence/hospital-doctors-20261101/exam-room.png),
[BonBon doctor](../evidence/hospital-doctors-20261101/exam-bonbon.png), [ICU](../evidence/hospital-doctors-20261101/icu-room.png),
[cat doctor](../evidence/hospital-doctors-20261101/icu-cat.png), [imaging](../evidence/hospital-doctors-20261101/imaging-room.png),
[beagle doctor](../evidence/hospital-doctors-20261101/imaging-beagle.png), [reception](../evidence/hospital-doctors-20261101/reception.png)
(sheep unchanged). In the ICU views the bed rail and exam counter sit in the foreground.
Not performed: the hospital route/department suites (no geometry changed), walking or clicking
the doctors in a live session.

## Police officer: crocodile plush at the station entrance — 1 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#police-officer-crocodile-plush-at-the-station-entrance--1-november-2026).
Godot 4.7, macOS, GL Compatibility, run in a temporary project copy with
`use_custom_user_dir=true` / `custom_user_dir_name="VocabularyTownChecks/isolated"`. The copy
included other sessions' uncommitted barn, hospital-doctor and storefront work.

| Check | Result |
| --- | --- |
| `docs/evidence/police-officer-20261101/verify.gd` (new) | 16 checks, 0 failures: old officer gone everywhere, one *police officer* root (the crocodile), `police` outfit with cap and badge, world scale 1, click resolves, spot follows the moved site, in front of the facade and > 3 units off the door axis, faces the street, body volume and door approach lane free of solids, police car > 5 units away. (First run passed with a per-node retirement check; tidied to one check and run once more.) |
| `check_plush_costumes.gd` | 473 checks, 0 failures (already covers the `police` outfit on the crocodile; no outfit changed) |
| `check_runtime_resources.gd` | 362 checked; 0 failures |

Renders (`docs/evidence/police-officer-20261101/capture.gd`): [entrance](../evidence/police-officer-20261101/entrance.png),
[officer](../evidence/police-officer-20261101/officer.png), [officer side](../evidence/police-officer-20261101/officer-side.png),
[aerial](../evidence/police-officer-20261101/aerial.png), [car and officer](../evidence/police-officer-20261101/car-and-officer.png).
The crocodile stands on the lawn by the left planter (viewed from the street), off the entrance
walk; door, walk, parking bays and police car are unobstructed. Not performed: walking or
clicking the officer in a live session; word audit and vocabulary suites (no key changed).

## Police-side floating beams removed — 1 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#police-side-floating-beams-removed--1-november-2026).
Godot 4.7, macOS, GL Compatibility, run in a temporary project copy with
`use_custom_user_dir=true` / `custom_user_dir_name="VocabularyTownChecks/isolated"`. The copy
included other sessions' uncommitted barn, electronics, hospital-doctor and police-officer work.

| Check | Result |
| --- | --- |
| `check_runtime_resources.gd` | 363 checked; 0 failures |
| Outline probe (scratch script, not kept): every visible "Building outline" piece tested for a roof/eave mesh within 1 unit | before: 17 pieces without a roof (burger set beside the police station, `corner18`, set 41–44); after: 8 (only set 41–44, recorded as unresolved in the design record) |

Renders (`docs/evidence/police-beams-20261101/capture.gd -- before|after`, the before/ set with the old
nearest-site matching): [ground before](../evidence/police-beams-20261101/before/ground.png) /
[after](../evidence/police-beams-20261101/after/ground.png), [aerial before](../evidence/police-beams-20261101/before/aerial.png) /
[after](../evidence/police-beams-20261101/after/aerial.png), [south](../evidence/police-beams-20261101/after/ground-south.png),
[burger restaurant](../evidence/police-beams-20261101/after/burger.png). The frame is gone; the station,
its parking and police car, the beach rocks and the tree are unchanged. Not performed: a live
walk-through; vocabulary suites (no key changed).

## Clothing store clerk and refresh — 1 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#clothing-store-clerk-and-refresh--1-november-2026).
Godot 4.7.2, macOS, `HOME` pointed at a scratch folder (isolated `user://`). Other
sessions' uncommitted barn, hospital, electronics and player edits were in the checkout
during these runs.

| Check | Result |
| --- | --- |
| `docs/evidence/clothing-clerk-20261101/verify.gd` (new) | 99 checks, 0 failures (third run: the first two failed only "orphan rack captions removed" until the captions were keyed on the retired-word list) |
| `docs/evidence/clothing-interior-20261028/verify.gd` | 130 checks, 1 failure before its probe was updated: "checkout counter is solid" tested the old counter spot (4.55, 6.2); the probe now points at the moved counter (3.4, 5.25). Not re-run after that edit |
| `check_plush_costumes.gd` | 502 checks, 0 failures (covers `clothing_shopkeeper`) |
| `check_runtime_resources.gd` | 362 checked, 0 failures |

Renders (`docs/evidence/clothing-clerk-20261101/capture.gd`): before and after [entrance](../evidence/clothing-clerk-20261101/entrance.png),
[checkout](../evidence/clothing-clerk-20261101/checkout.png), [left](../evidence/clothing-clerk-20261101/left.png),
[right](../evidence/clothing-clerk-20261101/right.png), [rear](../evidence/clothing-clerk-20261101/rear.png),
[cutaway](../evidence/clothing-clerk-20261101/aerial.png) (`before-*.png` alongside). The counter
hides most of the clerk's apron from the shop floor. The fitting-room plaque reads small
on the left wall. Not performed: vocabulary suites (no word key added or removed), a
live walk-through or clicking the plushes in play.

## Lot entrance strips removed — 2 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#lot-entrance-strips-removed--2-november-2026).
Godot 4.7.2, macOS, `HOME` pointed at a scratch folder (isolated `user://`). Other sessions'
uncommitted edits (police interior, vehicles, playground, HUD) were in the checkout.

| Check | Result |
| --- | --- |
| `check_compact_layout.gd` | 668 checks, 0 failures |
| `docs/evidence/streets-20261028/verify.gd` (walk-off-road probe now covers only the entrance connections) | 0 failures |
| `docs/evidence/restaurants-20261028/verify.gd` | 233 checks, **1 failure**: "police interior/exterior children preserved (144)". It counts the children of `RelocatedSites/Police`, which this change does not touch; the police interior was changed by the 1 Nov crocodile-officer work and uncommitted edits. Not compared against a baseline. The police entrance walk and parking drive checks pass |
| `docs/evidence/coast-20261029/verify.gd` (its "beach access walk found" probe was dropped) | 3308 checks, 0 failures; run once, before the `lot_stub` world-space fix, which changes only stub geometry |

The first `lot_stub` draft compared world-space lot bounds with town-local door positions
(the town root is scaled 1.3), so every lot fell back to the old full walk and the police
stub ran diagonally. Fixed and the three headless checks above rerun; the first and last
renders differ only for that reason. Renders: before and after
[restaurants](../evidence/lot-strips-20261102/after-restaurants.png), [police and supermarket](../evidence/lot-strips-20261102/after-west_upper.png),
[hospital and school](../evidence/lot-strips-20261102/after-hospital_school.png), [furniture and sports](../evidence/lot-strips-20261102/after-furniture_sports.png),
[east beach](../evidence/lot-strips-20261102/after-east_lower.png) (`before-*.png` alongside), all
top-down; airport, library and east-upper views were inspected but not saved. Not performed:
a live walk to every door, vehicles driven through the lots, or the full suite.

## Supermarket refit — 2 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#supermarket-refit-fruit-checkout-by-the-door-and-clerks--2-november-2026).
Godot 4.7.2, macOS, `HOME` pointed at a scratch folder (isolated `user://`). Other sessions'
uncommitted edits (figure blockers in `house_characters.gd`, player, seating, HUD, police,
playground, restaurants) were in the checkout during these runs.

| Check | Result |
| --- | --- |
| `docs/evidence/supermarket-20261102/verify.gd` (new) | 540 checks, 0 failures (third run). First run: 5 failures. The open fridge and the cooler had no front collider at body height; the clerks overlapped their own `FigureBlocker` (probe now excludes it); and duplicate-named fittings were reported as unworded. Second run: 0 of 536. Third run: added the *leaf* / *flowerpot* plant and its two expectations |
| `word_audit.gd` | Completes. Run before the plant was added: *leaf* was unplaced (only the retired stray market leaf taught it), so the plant was added and the verify check now asserts *leaf*. Still unplaced: *base*, *nurse*, *teacher*, not touched by this change. Not rerun after the plant |
| `python3 tools/word_data.py` | Valid; 550 words |
| `check_vocabulary_categories.py` | 1 failure: `crocodile_plush.tscn` word *crocodile* missing. Not touched by this change |
| `check_vocabulary_translations.py` | 2 issues: *hair* has two translations, and the same *crocodile* scene key. Not touched by this change |

Renders (`docs/evidence/supermarket-20261102/capture.gd`), before and after:
[entrance](../evidence/supermarket-20261102/entrance.png), [checkout](../evidence/supermarket-20261102/checkout.png),
[fruit](../evidence/supermarket-20261102/fruit.png), [vegetables](../evidence/supermarket-20261102/vegetables.png),
[pantry](../evidence/supermarket-20261102/pantry.png), [dairy](../evidence/supermarket-20261102/dairy.png),
[rear counters](../evidence/supermarket-20261102/rear.png), [drinks and home](../evidence/supermarket-20261102/drinks.png),
[cut-away plan](../evidence/supermarket-20261102/cutaway.png) (`before-*.png` alongside). The after renders
predate the entrance plant. Pantry goods read small against their shelves, and the rear wall
bands show as plain colour blocks above the cases.

Known out-of-date checks: `check_market_interior.gd`, `check_learning_stores.gd`
(expects 26 MarketDisplays roots) and `check_food_shopping_vocab.gd` assert the previous
layout and would now fail; not run. Not performed: frame-rate measurement (the store now
holds a few thousand small product meshes, merged by the render trim), a live walk-through
or clicking items in play, `check_plush_costumes.gd` for the new outfit, and the full suite.


## Airfield roads and school-street vehicles — 2 November 2026

Scope: [design record](TOWN_DESIGN_BRIEF.md#airfield-roads-and-school-street-vehicles--2-november-2026).
Godot 4.7.2, macOS, isolated `HOME`; other sessions' uncommitted edits were in the checkout.

| Check | Result |
| --- | --- |
| `check_compact_layout.gd` | 665 checks, 0 failures (668 before: the count follows the road/entrance nodes, one of which is retired) |
| `docs/evidence/coast-20261029/verify.gd` | 3328 checks, 0 failures; run after the airfield change, before `park_on_road()`, which moves only three vehicles |

Renders (top-down and oblique, graphics run): the apron, taxiway and runway read as one surface,
the taxiway meets the runway square and the apron reaches the terminal front and the car park; the
bus, school bus and fire truck sit in the lane beside the school. The streets and restaurants
suites and the vocabulary suites were not re-run. Not performed: driving the taxi or fire truck
from the new positions, or taking off and taxiing the turboprop on the new taxiway (its
collision follows the same trimesh as before, but this is untested). The apron-to-lot
overlap and the straight taxiway are judged from renders only.

## Customer order minigame — 3 November 2026

Run once each, headless, isolated `HOME`:
- `docs/evidence/customer-order-20261103/verify.gd` (order rules, dialogue, panel, stubbed session): 85 checks, 0 failures (second batch: return-to-clerk flow, cart after dialogue).
- `docs/evidence/customer-order-20261103/verify_town.gd` (real town: clerk tagged, in front of the wall, in zone, beside the door, on the ground, clickable; "!" and hop follow need/order; all 80 pool words have a shelf object; quests gone): 17 checks, 0 failures.
- `docs/evidence/supermarket-20261102/verify.gd`: 538 checks, 0 failures after marking `Pick blocker` bodies as `market_fitting` (the first run after the item scaling/blockers change failed only "no unworded product roots") and after updating the clerk spot to (-37.6, 31.0), dropping the in-store `salesperson` expectation and skipping the `NeedsHelpMarker` label in the sign check.
- Graphical `docs/evidence/customer-order-20261103/capture.gd` at 1280 × 800: views reviewed incl. face close-up (distance 3.4 / FOV 55 after two too-tight attempts), 80%-wide dialogue, big centre-right cart, return-to-clerk, bigger fruit/vegetables/pantry/fridge/cooler. Long retry text overlaps the clerk's chin; accepted.
- `docs/evidence/town-checks/check_project.py` and `docs/evidence/town-checks/check_vocabulary_categories.py` no longer read `learning_quests.gd` (edited and syntax-checked, **not run**).

Third batch (spawn outside the supermarket, text scaled to the window, `dev_focus.txt` fast boot): `docs/evidence/supermarket-20261102/verify.gd` 538 / 0, `docs/evidence/customer-order-20261103/verify.gd` 85 / 0 and `verify_town.gd` 20 / 0, all run once **with the focus switch on**; `capture.gd` re-rendered once at 1920 × 1200 (spawn view, dialogue, cart, retry offer reviewed; the first cart render had the card stretched past the screen and a map overlay, fixed by `_fit_cards()` and rendered again). The focus switch skips interiors; it was later generalised to a building list in the tracked `dev_focus.txt` (default `all`). Headless boots with `VT_FOCUS="bank, restaurants"` (7 s) and with the default `all` (15 s, full town) printed no errors; the verify/capture runs above used `supermarket` focus. `airport_aircraft()` must stay (compact_town needs the turboprop). Boot time headless: about 15 s full, 6 s focused.

Not run: the full suite, `check_vocabulary_translations.py`, and no live play-through with real mouse clicks. Historical checks that still call `game.quests` / `relocate_quests` (`check_area_journal.gd`, `docs/evidence/world_expansion/verify.gd`, `check_town_layout.gd`, `check_sitting.gd`, `check_school_*`, `check_supermarket_exterior.gd`, `check_market_interior.gd`, `check_food_shopping_vocab.gd`, `check_hospital_departments.gd`, `check_compact_layout.gd`, `check_cafe_bank_exteriors.gd`, `check_building_dimensions.gd`, `check_school_partition.gd`) are **stale**: expect mission-related failures; the rest of each is unverified since this change. Not verified: the "!" and hop in motion (stills only) and a first real mouse click on the clerk.

## Cashier money minigame — 4 November 2026

All run once, headless, isolated `HOME`. The two town runs used `dev_focus` **supermarket** (VT_FOCUS), so they are **not** full-town results; `dev_focus.txt` itself still reads `all`.
- `docs/evidence/cashier-money-20261104/verify.gd` (no town): 44 checks, 0 failures: 10 denominations (no $500), 33 known Spanish phrases (un / veintiún / ciento un / cien / mil, zero cents, one cent), structural rules on **every** amount from 25 to 30,000 cents, `usd()` format, totals and "any exact combination", bucket probabilities, and 200,000 seeded draws (cumulative 10 / 40 / 70 / 90% within 1%, both ends reachable).
- `docs/evidence/cashier-money-20261104/verify_town.gd` (supermarket focus): 45 checks, 0 failures: session and tagging, request dialogue with Spanish and dollar lines, panel opens and locks the player and interaction, keys swallowed, add / remove / clear / total, wrong answer keeps the tray, "what went wrong", close → "¿Seguro?" (no / ✕ stay, yes ends), exact amount built from $1 bills accepted, new round clears the tray, the clerk's session unaffected.
- `docs/evidence/customer-order-20261103/verify.gd`: 112 checks, 0 failures (the new `cashier_*` / `money_*` phrases are checked for both languages); `verify_town.gd` (supermarket focus): 20 checks, 0 failures, so the clerk minigame is unchanged.
- Graphical `docs/evidence/cashier-money-20261104/capture.gd` at 1920 × 1200 (desktop) and 800 × 1400 (narrow, touch-shaped): request, translation, empty / selected / crowded money screen, wrong answer, explanation, "are you sure" reviewed. Two layout fixes came from the renders (first pieces too large and overflowing, then an over-tall empty tray in the narrow window, now capped by `TALL_LIMIT`).

**Not verified:** a real mouse click or E on the cashier through the pick ray (tests emit `clerk_activated`), the full town with all interiors, the Python check scripts, a real touch device. Known limits: no face zoom for the cashier; the narrow window still leaves a tall empty tray.


## Language framework, Stage 1 — 4 November 2026

Single source for words and phrases, per-language rules modules, `tools/language_check.gd`
([procedure](ARCHITECTURE_REVIEW_PART1.md#vocabulary-data-procedure)). No visible change
intended. All run once, headless, isolated `HOME`. The two town runs used `VT_FOCUS=supermarket`,
so they are **not** full-town results; `dev_focus.txt` reads `all`.
- **Identical text:** a scratch script dumped every shop/cashier text with the old code before
  the change and through the new code after it: 550 word display texts and categories, all
  phrases in both languages, speaker and "return to" lines for all 12 People words, 160 order
  lines, the full reveal list, all 30,001 money amounts 0–$300.00 and 1,004 number samples.
  31,778 compared lines, 0 differences.
- `tools/language_check.gd`: 283 checks, 0 failures. Also run once against planted mistakes
  (wrong Spanish forms, missing forms, missing English text, placeholder mismatch between
  languages, a wrong sample, a probe script with `"the " +` and "¡Hola!"): every one reported,
  files restored afterwards.
- `python3 tools/word_data.py`: clean (550 words, 13 aliases, 19 categories).
- `docs/evidence/customer-order-20261103/verify.gd`: 114 checks, 0 failures (two more phrases than before:
  `shop.item_count`, `shop.word_pair`); `verify_town.gd` (supermarket focus): 20 / 0.
- `docs/evidence/cashier-money-20261104/verify.gd`: 44 / 0 (now calls `rules_es.gd::money_words`);
  `verify_town.gd` (supermarket focus): 45 / 0.
- `docs/evidence/town-checks/check_runtime_resources.gd`: 373 checked, 0 failures. `check_vocabulary_categories.gd`
  and `check_vocabulary_aliases.gd`: PASS.
- `docs/evidence/town-checks/check_vocabulary_categories.py`: 1 failure; `check_vocabulary_translations.py`: 2 issues.
  All are the known `crocodile_plush.tscn` / `crocodile` key and `hair` two-option exception.

Not run: graphical captures (no layout or appearance change), the full suite, the full town,
`docs/word_audit.gd`, `docs/evidence/coast-20261029/verify.gd` (its `words.json` read was updated to
`text.es`, not run). Open items are listed under "Not yet covered" in the procedure.

## Hospital family game, Stage 2 (words, posters, Dr. Li) — 4 November 2026

[Design record](TOWN_DESIGN_BRIEF.md#hospital-family-game--4-november-2026). Each check
was run once on the finished change unless noted. The two town runs below used
`VT_FOCUS="school, hospital"` and are **not** full-town results; `dev_focus.txt` reads `all`.
- `tools/language_check.gd`: 307 checks, 0 failures (585 words, 63 phrases, names for both
  languages and genders). `python3 tools/word_data.py`: clean (585 words, 20 categories).
- `docs/evidence/family-posters-20261104/verify_town.gd` (school + hospital focus): 176 checks,
  0 failures. Covers: posters inside the shell on the right walls, rear posters not
  overlapping, every poster word pickable through its own area and in the school zone,
  all 35 new words placed (cousin twice), Lexicon labels, a plain "yo" card, the 31 Oct
  posters kept, and Dr. Li's scene, outfit, name, id, scale, position, facing, feet on the
  ground and click target. It ran twice. The first run was before the final label-size
  and height fix; the second, on the final layout, gave the same 176 / 0. A third
  focused run only listed warnings: the expected missing supermarket clerk and cashier,
  since that interior is skipped.
- Graphical `docs/evidence/family-posters-20261104/capture.gd` at 1600 × 1000 (same focus), rendered
  three times:
  1. Rear-wall titles overflowed into each other, and the AULA GENERAL label touched the
     poster tops.
  2. Fixed (titles shrink to fit; posters lowered 0.09), but the narrow posters' cards
     overlapped their header strip.
  3. Fixed (smaller cards). Final views reviewed: tree, tree detail, rear wall, months,
     Dr. Li, Dr. Li close-up.

  Accepted: the spouses' ring is partly hidden behind their cards.
- `docs/word_audit.gd` (full town): Family 21 / 21 and Time & Directions 27 / 27 placed.
  People 10 / 12 and Building Parts 23 / 24 are unplaced counts in words this work did not
  touch (not compared with an earlier run).
- `docs/evidence/hospital-doctors-20261101/verify.gd` (full town): 37 checks, 0 failures.
- `docs/evidence/town-checks/check_vocabulary_categories.gd`: PASS (585 words, 20 categories).
  `check_vocabulary_categories.py`: 1 failure. `check_vocabulary_translations.py`: 2 issues,
  after its article and masculine/feminine lists gained the months, before/after,
  older/younger and cousin. All three are the known `crocodile` key and `hair` exception.

Not run: the full suite, the shop/cashier town checks (their code is unchanged), a real
mouse click on a poster or on Dr. Li (tests call the pick resolver), the HUD language
toggle on the posters (poster text follows `languages.json` at build time; the toggle is
UI-stage work). *Superseded the same day by the entry below.*

## Poster text follows the L language toggle — 4 November 2026

Poster labels are bound to Lexicon text references (`scripts/language/live_labels.gd`;
[guide](ARCHITECTURE_REVIEW_PART1.md#vocabulary-data-procedure)); new `label` form in every
rules module. Each check ran once on the finished change; the town runs used
`VT_FOCUS="school, hospital"` and are **not** full-town results; `dev_focus.txt` reads `all`.
- `tools/language_check.gd`: 446 checks, 0 failures (64 phrases; `label` samples for both
  languages, `posters.person` sample "el tío" / "uncle").
- `docs/evidence/family-posters-20261104/verify_town.gd` (school + hospital focus): 186 checks,
  0 failures. New: labels are bound; after `language_changed(0)` (English mode) the uncle,
  cousin, May, older, after and "me" cards and the family title and COUPLES read English;
  every bound label fits its width; `language_changed(2)` (Both) restores "el tío".
- Graphical `capture.gd` (same focus, 1600 × 1000), rendered once: all eight views, with
  two new English-mode views (family tree, rear wall) reviewed. The Spanish views are
  unchanged. Minor: in English, "40 years old" sits close above "older" on the age poster.

Not run: a real key press of L (the test emits the HUD signal Main listens to), the full
suite, the full town.

## Hospital family game, Stage 3 (Dr. Li's game) — 4 November 2026

[Design record](TOWN_DESIGN_BRIEF.md#hospital-family-game--4-november-2026),
[ownership](ARCHITECTURE_REVIEW_PART1.md#hospital-family-game-ownership--4-november-2026).
Final run of each check, once, on the finished change. Town runs used `VT_FOCUS` and are
**not** full-town results; `dev_focus.txt` reads `all`.
- `tools/language_check.gd`: 629 checks, 0 failures (24 new `family.*` phrases; the
  `{relation:label}` slot renders for every Family word in both genders; new samples
  "¿Quién es la prima de Ana?" / "Who is Ana's cousin?"). `python3 tools/word_data.py`: clean.
- `docs/evidence/family-game-20261104/verify.gd` (logic, no town): 67 checks, 0 failures. 400 random
  families per template (ages match birth dates and the reference date, all different and at
  least 6, foreign names unique, every relation consistent both ways and matching gender);
  kinship spot checks (an uncle by marriage, a nephew by marriage, no word for a
  father-in-law); 4,000 questions, each with exactly one answer that `answers()` recomputes,
  rendered in both languages; all 8 kinds, all 19 relationship words and all 12 months asked;
  no kind repeated twice in a row; yes/no 496 of 1,000 "yes". An earlier run of this script
  failed (some families had no birth month only one person shared), so birth months were made
  all different before the final run.
- `docs/evidence/family-game-20261104/verify_town.gd` (`VT_FOCUS=hospital`): 37 checks, 0 failures:
  Dr. Li tagged, her "!" only when the player is near and nothing is open, greeting from "Dra.
  Li", the panel opens and locks the player, one card per person with name, gender icon, age
  and MM/DD/YYYY, legend and "Hoy: 11/04/2026", translation toggle, wrong answer ✗ with retry,
  right answer ✓ and Otra pregunta, a new family from another template, Esc closes with a
  goodbye and unlocks the player, "Ahora no", walking away closes the greeting.
- `docs/evidence/customer-order-20261103/verify.gd`: 149 checks, 0 failures; `verify_town.gd`
  (`VT_FOCUS=supermarket`): 20 checks, 0 failures, after the clerk's "!" and face camera moved
  to `npc_presence.gd`.
- Graphical `docs/evidence/family-game-20261104/capture.gd` (`VT_FOCUS=hospital`, 1600 × 1000, plus one
  view at 1280 × 800), rendered three times. The first render showed the date legend wrapping
  one letter per line and squeezing the tree away (legend wrapping turned off). The second
  showed the greeting without "Ver traducción" in a hospital-only run (the session now sets
  that text itself). Final views reviewed: Dr. Li calling, greeting, question, wrong, right
  with translation, yes/no, yes/no at 1280 × 800.

Seen, not changed: the shared dialogue box renders much taller than its 27 % share in these
scripted captures; the 3 Nov customer-order captures show the same, so it is not new
(priority low, check in a real play session). "¡Correcto! / Correct!" wraps onto two lines
with the translation on. Not run: a real E key press or mouse click on Dr. Li or a card
(tests emit the same signals), the full suite, the full town, the school posters' town check
(Dr. Li's node and position did not change; her talk tag is checked above).

**Same day, after the user's play test.** Bug: with the translation on, a yes/no question's
bottom bar (legend, "Hoy / Today", feedback and four two-language buttons) left the feedback
no width, so it wrapped one letter per line and pushed the tree off the screen. Fix: the
feedback has its own full-width row, and buttons and the date line put the translation on a
second line. Also by user decision every tree template now has **7 people** (was 9), and
in-laws sit on the outside of their couple so the line to the children never crosses them.
Checks after the change, each once: `verify.gd` 73 checks, 0 failures (a 7-people check
per template; new kinship spot checks for the cousins tree; all 19 words and 12 months
still asked; yes/no 534 of 1,035 "yes"). That run was before the layout columns moved,
which the logic does not read. `verify_town.gd` (`VT_FOCUS=hospital`) 38 checks, 0 failures
(new: with the translation on in a 1600 × 1000 window the feedback row stays under 15 % and
the tree over 40 % of the height). A first run of the new check failed only because the
headless window is 64 px tall; the check now sets the window size. `capture.gd` rendered
twice: the first showed the boyfriend sitting under the children's line, so the in-laws
moved outside; final views reviewed, including the new `yes-no-translation.png`.

## Shared UI, Stage 1 (dialogue box, Esc, Settings) — 4 November 2026

[Decisions and ownership](ARCHITECTURE_REVIEW_PART1.md#shared-dialogue-popups-and-settings--4-november-2026).
Final run of each check, once, on the finished change. Town runs used `VT_FOCUS` and are
**not** full-town results; `dev_focus.txt` reads `all`. Isolated HOME throughout (the new
check deletes its `user://settings.json`).
- `tools/language_check.gd`: 651 checks, 0 failures (new `settings.*` and `language.*`
  phrases; `money.tray_empty` removed with the hint text).
- `docs/evidence/ui-settings-20261104/verify_town.gd` (`VT_FOCUS=supermarket,hospital`, new): 54 checks,
  0 failures. Defaults Foreign only / en / es; the gear left of the book; Esc with nothing open
  opens Settings, in Settings closes it and returns the controls; help + map close in order
  without opening Settings; the cashier's box is the top popup, its bubble reads EN, sits in
  the top row and reveals the native line; two centred choices with icons; the box stays at
  the bottom; money panel: hand icon in the empty tray, icons on Clear / Hand over / Close,
  both disabled at first, Hand over widest, Clear and Close the same size; Esc on the money
  panel asks to quit, Esc on that question returns to the panel; L cycles Both → Native only
  → Foreign only with the right lines, buttons and world signs, and saves; the Settings
  buttons set the mode; native and foreign may both be English; a Spanish native relabels
  Settings, the HUD button and the bubble (ES).
- `docs/evidence/customer-order-20261103/verify.gd`: 160 checks, 0 failures; `verify_town.gd`
  (`VT_FOCUS=supermarket`): 20, 0.
- `docs/evidence/cashier-money-20261104/verify.gd`: 44, 0; `verify_town.gd` (`VT_FOCUS=supermarket`): 45, 0.
- `docs/evidence/family-game-20261104/verify.gd`: 73, 0; `verify_town.gd` (`VT_FOCUS=hospital`): 38, 0.
  Two of its checks were updated for the new rules: Esc now goes through
  `Main._unhandled_input`, and a hidden translation line is empty until revealed.
- Earlier runs during the work: the new check first failed 5 of 54 (the Settings card measured
  its wrapped labels at zero width and grew 2,972 px tall, so its titles no longer wrap; a
  wrong expectation for "Total", which is the same word in both languages; a test dialogue no
  session owned). The family town check failed once on the empty hidden line (check updated).
- Graphical `docs/evidence/ui-settings-20261104/capture.gd` (1600 × 1000, same focus): dialogue in
  Foreign only, translated, Both and Native only; money panel empty, translated and its quit
  question; Settings; the family panel; help. Reviewed. One render stalled after loading with
  no error (window likely in the background) and was stopped; the next render completed. The
  first renders showed the speaker still in Spanish in Native only (the speaker is now a
  two-language line) and "English (English)" in the dropdown (now one name when they match).

Seen, not changed: the dialogue box (10–90 % of the width) covers the bottom-left Display Mode
button and the words-found label while it is open, as before this change (priority low).
Text built before a language change (a family tree in progress, NPC names, world signs, which
only exist as English → Spanish) keeps its old language until rebuilt: Stage 3. Not run: the
full suite or full town; `docs/guides/spanish-signs-20261027/verify.gd` (its cycle order was updated
for the new L order), `docs/evidence/town-checks/check_interaction.gd` and `docs/evidence/town-checks/check_bonbon_ui.gd`, which press L
or Esc; a real key press in a window (the checks call Main's input handler directly).

## Shared UI, Stage 2 (activity board, progress bar) — 4 November 2026

[Decisions and ownership](ARCHITECTURE_REVIEW_PART1.md#shared-dialogue-popups-and-settings--4-november-2026).
Final run of each check, once, on the finished change (exit codes recorded). Town runs used
`VT_FOCUS` and are **not** full-town results; `dev_focus.txt` reads `all`. Isolated HOME.
- `tools/language_check.gd`: 661 checks, 0 failures (new `common.finish_first`,
  `cashier.no_request`, `cashier.complete`, `family.not_now`, `family.complete`).
- `docs/evidence/activities-20261104/verify_town.gd` (`VT_FOCUS=supermarket,hospital`, new): 30 checks,
  0 failures. Data (every chance 1.0; targets 5 / 20 / 0); chance 0 never offers and 0.5
  offers 420–580 times in 1,000; cashier: 0/5 bar left of the bubble, an exact first payment
  counts, right after a miss does not, 5/5 thanks and ends the session, then "nothing to pay"
  until the next visit; a running grocery order makes the cashier ask to finish first,
  quitting it frees him; a cashier round hides the clerk's "!" and makes him refuse, the "!"
  returns after; family: 0/20, a right first tap counts, right after a miss does not, 20/20
  thanks and closes the panel, Dr. Li is "busy" until the player comes back; no bar in the
  grocery cart.
- Unchanged checks: customer-order `verify.gd` 165, 0 (its check count varies with the
  random orders) and `verify_town.gd` (`supermarket`) 20, 0; cashier `verify.gd` 44, 0 and
  `verify_town.gd` (`supermarket`) 45, 0; family `verify.gd` 73, 0 and `verify_town.gd`
  (`hospital`) 38, 0; `docs/evidence/ui-settings-20261104/verify_town.gd` 54, 0.
- Earlier runs during the work: the new check passed 30 of 30 but Godot then aborted on quit
  (exit 134, a mutex error), because the static board held lambdas bound to the sessions; it
  now holds weak references and exits 0. The first renders showed the grocery cart covering
  the cashier's refusal (the dialogue box is now drawn above the cart).
- Graphical `docs/evidence/activities-20261104/capture.gd` (1600 × 1000, same focus): money panel at
  2/5, the cashier's thanks, the refusal over the open cart, the family panel at 7/20.
  Reviewed.

Not run: the full suite or full town; the older checks that press L or Esc (see Stage 1).
A real walk into the store or up to Dr. Li (the checks call the sessions' per-frame update
with set positions).

## Shared UI, Stage 3 (interface text in data, live re-rendering, progress per language) — 4 November 2026

[Decisions and ownership](ARCHITECTURE_REVIEW_PART1.md#shared-dialogue-popups-and-settings--4-november-2026).
Final run of each check, once, on the finished change (exit codes recorded). Town runs used
`VT_FOCUS` and are **not** full-town results; `dev_focus.txt` reads `all`. Isolated HOME.
- `tools/language_check.gd`: 1,249 checks, 0 failures (about 300 new phrases in 16 groups;
  the word-card code exception is gone).
- `docs/evidence/language-ui-20261104/verify_town.gd` (`VT_FOCUS=supermarket,hospital`, new): 51
  checks, 0 failures:
  - Progress: an older single-array save loads as the Spanish progress, with aliases
    canonical. The old file is never written again. English as the foreign language has its
    own progress, and switching back restores the Spanish one.
  - Word card in Foreign only, Both and Native only, with the bubble revealing the
    words.json word. The NPC talk hint follows the world language.
  - With native Spanish: the controls summary, the place line ("Hospital · Planta 2 · …"),
    pointer hints, the mode button, card titles, the F1 guide, the journal (both views),
    saved words, the movement label and the vehicle status are all in Spanish.
  - Every name `Main.current_room()` returns on a grid over the town and four floor
    heights, plus every zone, area, category, species, seat, map label and outfit, has a
    phrase.
  - A language change ends the family game (Dr. Li is renamed), the cashier round and a
    grocery order. A Display Mode change alone ends nothing.
- Unchanged checks, all exit 0:
  - customer-order `verify.gd`: 459 checks, 0 failures (its count varies with the random
    orders). Its clerk-hint check now expects the phrase reference.
  - customer-order `verify_town.gd` (`supermarket`): 20 checks, 0 failures.
  - cashier `verify.gd`: 44, 0. Cashier `verify_town.gd` (`supermarket`): 45, 0.
  - family `verify.gd`: 73, 0. Family `verify_town.gd` (`hospital`): 38, 0.
  - `docs/evidence/ui-settings-20261104/verify_town.gd`: 54, 0.
  - `docs/evidence/activities-20261104/verify_town.gd`: 30, 0.
  - The three town checks' "E: Hablar" checks now resolve the hint as the hover does.
- Earlier run during the work: the new check failed once, because the family car's name card
  ("Subaru Outback" as its species) had no phrase. `species.subaru_outback` was added.
- Graphical `docs/evidence/language-ui-20261104/capture.gd` (1600 × 1000, same focus). Reviewed:
  - the card in Foreign only, revealed
  - the F1 guide, journal by area and town map with native Spanish (with native Spanish
    and foreign English, world signs show English, as designed)

Not run:
- the full suite or the full town
- `docs/check_building_exteriors.gd`: its hover expectation was updated to the Display
  Mode, "el banco", but the check was not run
- `docs/evidence/town-checks/check_interaction.gd`, `check_bonbon_ui.gd` and the older checks that press L or Esc
- `docs/evidence/town-checks/check_area_journal.gd`, which still drives the missions removed on 3 Nov
- in-game seat, ladder and garage hints near the objects: their phrases are covered by
  the name check, not by walking up to them

## Traditional Chinese, Stage 4a (kin details, mother's-side tree) — 4 November 2026

[Decisions](TOWN_DESIGN_BRIEF.md#hospital-family-game--4-november-2026). Each check run once
on the finished change. Isolated HOME; `dev_focus.txt` reads `all`.
- `docs/evidence/chinese-kinship-20261104/verify.gd` (new, logic only): 84 checks, 0 failures. Over
  five seeds of each template it checks the side, elder, link and by-marriage details for:
  - grandparents and grandchildren
  - siblings
  - aunts and uncles, by blood and by marriage
  - cousins
  - nieces and nephews, including through a spouse
  
  It also checks:
  - `mothers_side` exists, and `relation()` still returns the word key
  - English and Spanish labels ignore the details
  - with a labeler that tells sides and ages apart, 80 relation questions are unique by
    label, and both sides come up
- `docs/evidence/family-game-20261104/verify.gd`: 74 checks, 0 failures (73 before: one more
  template in its per-template loop).
- `tools/language_check.gd`: 1,249 checks, 0 failures.
- `docs/evidence/family-game-20261104/verify_town.gd` (`VT_FOCUS=hospital`, focused): 38 checks,
  0 failures.
- Graphical `docs/evidence/chinese-kinship-20261104/capture.gd`: the `mothers_side` tree in the
  panel. Reviewed: lines and placement are correct, with the same empty column as
  `big_family`.

Not run: the full suite or full town; there is no Chinese text yet (4b).

## Traditional Chinese, Stage 4b (draft language, family game in Chinese) — 4 November 2026

[Decisions](TOWN_DESIGN_BRIEF.md#hospital-family-game--4-november-2026). Each check run once
on the finished change. Isolated HOME; `dev_focus.txt` reads `all`. Chinese is a **draft**:
35 of 585 words and 45 of 399 phrases. The Chinese is Claude's draft and awaits the user's
review.
- `tools/language_check.gd`: 1,480 checks, 0 failures. It validates the Chinese text that
  exists (placeholders, the kinship terms, samples for numbers, money, forms and grammar
  phrases) and reports what is missing. It also checks that the defaults are not drafts.
- `python3 tools/word_data.py`: valid, with drafts allowed to lack words.
- `docs/evidence/chinese-family-20261104/verify.gd` (new, logic only): 139 checks, 0 failures.
  - `zh` is listed but not playable, and a saved `zh` choice falls back to the defaults.
  - Over six seeds, 23 expected terms come out right, among them 爺爺/公公, 嫲嫲/婆婆,
    姐姐/妹妹, 哥哥/弟弟, 姑媽/姑姐, 姨媽/阿姨, 舅父, 舅母, 表哥/表弟, 外孫女, 外甥 and 內姪.
  - Across 40 rounds of every template, every pair of relatives gets one specific term.
  - 400 Chinese questions each have one answer and render; relationship questions use 20
    or more different terms.
  - Numbers and money render in Chinese.
- `docs/evidence/family-game-20261104/verify.gd`: 86 checks, 0 failures (74 before: its
  every-language loops now include `zh`).
- `docs/evidence/chinese-kinship-20261104/verify.gd`: 84 checks, 0 failures.
- `docs/evidence/ui-settings-20261104/verify_town.gd` (`VT_FOCUS=supermarket,hospital`, focused): 54
  checks, 0 failures. Settings now lists only complete languages.
- `docs/evidence/family-game-20261104/verify_town.gd` (`VT_FOCUS=hospital`, focused): 38 checks,
  0 failures.
- Graphical `docs/evidence/chinese-family-20261104/capture.gd`: the family panel with Chinese as the
  foreign language and English as the native one, with the Lexicon set directly because a
  draft can't be chosen in Settings. The capture shows a relationship question with its
  translation revealed, then the same view in Both. Reviewed:
  - the characters render through system font fallback
  - the question asks for 綺雯's 外甥女, and the girl is her husband's sister's daughter,
    which is correct

Not run: the full suite or full town. Not done yet:
- the in-town posters and every other screen in Chinese (4d)
- pinyin (4c; built below)
- a check by a Chinese speaker

## Traditional Chinese, Stage 4c (pinyin) — 4 November 2026

[Decisions](TOWN_DESIGN_BRIEF.md#hospital-family-game--4-november-2026). Each check run once
on the finished change. Isolated HOME; `dev_focus.txt` reads `all`. Pinyin comes from
`data/pinyin_zh.json` (207 characters, 99 words; Claude's draft for review) through
`rules_zh.gd` `reading()`.
- `tools/language_check.gd`: 1,496 checks, 0 failures (1,480 before). New checks:
  - every character of the Chinese words, terms, phrases and names has a reading
  - every listed reading is spelled with pinyin letters
  - 13 `readings` samples match, for example 嘉欣的公公是誰？ → "Jiāxīn de gōnggong shì
    shéi?", and money → "yībǎi sìshíqī měiyuán sānshíbā měixiān"
- `docs/evidence/chinese-pinyin-20261104/verify.gd` (new, logic only): 9 checks, 0 failures.
  - only Chinese has a reading line
  - the line shows in Foreign only and Both but not in Native only, and never with Spanish
    as the foreign language
  - every Chinese word, 400 generated questions and their names read completely
- `docs/evidence/chinese-family-20261104/verify.gd`: 139 checks, 0 failures.
- `docs/evidence/ui-settings-20261104/verify_town.gd` (`VT_FOCUS=supermarket,hospital`, focused): 54
  checks, 0 failures.
- `docs/evidence/family-game-20261104/verify_town.gd` (`VT_FOCUS=hospital`, focused): 38 checks,
  0 failures.
- Graphical `docs/evidence/chinese-pinyin-20261104/capture.gd` (`VT_FOCUS=hospital`, Lexicon set
  directly). Reviewed:
  - [greeting](../evidence/chinese-pinyin-20261104/greeting.png): the pinyin line sits under Dr. Li's
    Chinese line
  - [question-revealed](../evidence/chinese-pinyin-20261104/question-revealed.png): the pinyin sits
    between the question and the English
  - [word-card](../evidence/chinese-pinyin-20261104/word-card.png): 爺爺 / 公公 with "yéye / gōnggong"
  - The bottom-left mode button still reads "Spanish only" because the capture sets the
    Lexicon directly; Settings is not used for a draft language. This is a capture artefact.

Not run: the full suite or full town; the money request with Chinese, because the cashier
has no Chinese phrases until 4d. Known limits:
- pinyin is the Mandarin reading, while Hong Kong readers usually read Cantonese (open
  decision)
- tones are citation tones (一 and 不 changes are not written)
- buttons, titles, posters and world signs show no pinyin

## Traditional Chinese, Stage 4d batch 1 (supermarket and cashier) — 4 November 2026

[Decisions](TOWN_DESIGN_BRIEF.md#hospital-family-game--4-november-2026). Each check run once
on the finished change. Isolated HOME; `dev_focus.txt` reads `all`. Claude's draft for review,
in Hong Kong written usage (牛油果, 西蘭花, 芝士, 薯仔, 士多啤梨, 收銀員, 美仙):
- the 80 supermarket items and the 12 People words
- the 50 shop, cashier and money sentences
- pinyin for 198 more characters and 122 more words

Chinese now covers 127 of 585 words and 95 of 399 phrases.
- `tools/language_check.gd`: 1,586 checks, 0 failures. Two Chinese samples for
  `shop.return_to_clerk` were added.
- `docs/evidence/chinese-shop-20261104/verify.gd` (new, logic only): 4 checks, 0 failures.
  - every supermarket item and People word has Chinese, and the speaker cards read 售貨員
    and 收銀員
  - 200 random orders and amounts render every shop and cashier line in Chinese with full
    pinyin, for example 一共一百四十七美元三十八美仙，謝謝。 → "Yīgòng yībǎi sìshíqī měiyuán
    sānshíbā měixiān, xièxie."
- `docs/evidence/chinese-pinyin-20261104/verify.gd`: 9 checks, 0 failures. `docs/evidence/chinese-family-20261104/verify.gd`:
  139 checks, 0 failures.
- Graphical `docs/evidence/chinese-shop-20261104/capture.gd` (`VT_FOCUS=supermarket`, Lexicon set
  directly). Reviewed:
  - [money](../evidence/chinese-shop-20261104/money.png): the request in Chinese numerals with pinyin and
    the English amount, and the Chinese / English buttons
  - [order](../evidence/chinese-shop-20261104/order.png): the clerk 售貨員 asks for help; the cart list
    opens after this line and was not captured

Not run: the town checks. This batch changes only Chinese data, and they run in Spanish.
Known issues:
- **Font (medium; fixed 4 Nov 2026, see "Pinyin font" below):** Godot's built-in font has
  no ǐ, so it falls back to a system font, and the caron on ǒ and ǎ draws rounded, like a
  breve. A bundled font with full pinyin coverage would fix it, but that changes every
  screen: the user decides.
- **Spacing (low):** the cashier's "what went wrong" answer joins its two sentences with a
  space (`cashier_session.gd` `_join`), which Chinese does not use.

## Traditional Chinese, Stage 4d batch 2 (interface text) — 4 November 2026

[Decisions](TOWN_DESIGN_BRIEF.md#hospital-family-game--4-november-2026). Each check run once
on the finished change. Isolated HOME; `dev_focus.txt` reads `all`. Claude's draft for review:
the 304 remaining interface phrases, in Hong Kong written usage (車房, 升降機, 天台, 梳化,
傢俬, 試身室, 課室, 警署, 急症室). Key names (WASD, Shift, Esc, F1) and the car model
"Subaru Outback" stay as printed. Pinyin was added for 329 more characters and 290 more
words. Chinese now covers 127 of 585 words and **399 of 399 phrases**.
- `python3 tools/word_data.py`: valid.
- `tools/language_check.gd`: 1,890 checks, 0 failures. Every phrase line checks its
  placeholders, and every character has a reading.
- `docs/evidence/chinese-pinyin-20261104/verify.gd`: 9 checks, 0 failures.
  `docs/evidence/chinese-shop-20261104/verify.gd`: 4 checks, 0 failures.
  `docs/evidence/chinese-family-20261104/verify.gd`: 139 checks, 0 failures.
- Graphical `docs/evidence/chinese-ui-20261104/capture.gd` (`VT_FOCUS=supermarket,hospital`). The
  native language is set to Chinese in code, as a Chinese speaker learning English. Reviewed:
  - [settings](../evidence/chinese-ui-20261104/settings.png): the Settings window in Chinese; the "我的語言"
    dropdown is empty because Settings lists only playable languages and Chinese is a draft
    (expected until 4d ends)
  - [help](../evidence/chinese-ui-20261104/help.png): the F1 guide in Chinese; the Esc row wraps onto a
    second line
  - [journal](../evidence/chinese-ui-20261104/journal.png): the journal by area
  - [map](../evidence/chinese-ui-20261104/map.png): the town map with Chinese place names

Not run: the town checks. This batch changes only Chinese data, and they run in Spanish.
Native-language Chinese text has no pinyin; pinyin is only for the language being learned.

## Traditional Chinese, Stage 4d batch 3 (remaining words) — 4 November 2026

[Decisions](TOWN_DESIGN_BRIEF.md#hospital-family-game--4-november-2026). Each check run once
on the finished change. Isolated HOME; `dev_focus.txt` reads `all`. Claude's draft for review:
the 458 remaining words across 18 categories, in Hong Kong written usage (雪櫃, 焗爐, 的士,
巴士, 單車, 電單車, 波鞋, 恤衫, 背囊, 結他, 擦膠, 間尺, 探熱針, 櫃員機, 街市). No two words
share a Chinese text. Pinyin was added for 283 more characters and 340 more words. Words
of up to three characters are composed from their characters' readings; neutral tones,
other readings and longer words are written by hand. Chinese now covers **585 of 585 words
and 399 of 399 phrases**, and is still marked `draft`.
- `python3 tools/word_data.py`: valid.
- `tools/language_check.gd`: 1,890 checks, 0 failures. It reports `zh` DRAFT at 585/585
  words and 399/399 phrases.
- `docs/evidence/chinese-pinyin-20261104/verify.gd`: the first run had 1 failure out of 9. Its test
  character for "no reading" (龍) now has a reading, because 龍門 (goal) uses it. The test
  now uses 鑰, which is not in the data. Re-run: 9 checks, 0 failures; every Chinese word
  reads completely.
- `docs/evidence/chinese-shop-20261104/verify.gd`: 4 checks, 0 failures.
  `docs/evidence/chinese-family-20261104/verify.gd`: 139 checks, 0 failures.
- Graphical `docs/evidence/chinese-words-20261104/capture.gd` (`VT_FOCUS=supermarket`, Lexicon set
  directly). Reviewed:
  - [refrigerator](../evidence/chinese-words-20261104/card-refrigerator.png): 雪櫃 / xuěguì
  - [stethoscope](../evidence/chinese-words-20261104/card-stethoscope.png): 聽診器 / tīngzhěnqì
  - [sneakers](../evidence/chinese-words-20261104/card-sneakers.png): 波鞋 / bōxié, with the English
    revealed

Not run: the town checks. This batch changes only Chinese data, and they run in Spanish.
Still open:
- a check by a Chinese speaker
- the user's decision to take `zh` out of draft
- the pinyin font issue (batch 1; fixed below)
- the Mandarin or Cantonese reading question (Stage 4)

## Pinyin font (Noto Sans SemiBold for the pinyin line) — 4 November 2026

User decision: a bundled font for the pinyin line only, through one shared helper, tested
on all four tones including ǖ ǘ ǚ ǜ. Each check run once on the finished change. Isolated
HOME; `dev_focus.txt` reads `all`.
- **Cause:** Godot's built-in Open Sans SemiBold has no ǎ ǐ ǒ ǔ ǖ ǘ ǚ ǜ Ǎ Ǒ (checked with
  `Font.has_char`).
- **Font:** `fonts/NotoSans-SemiBold.ttf`, downloaded with the user's approval from
  github.com/notofonts/notofonts.github.io (625,052 bytes, SIL Open Font License), with its
  `.import` file.
- **Helper:** `scripts/ui/pinyin_text.gd` (`style()`, `show()`) now draws all four pinyin
  lines (dialogue box, family question, money request, word card), which used to set their
  text and visibility themselves.
- `docs/evidence/chinese-pinyin-20261104/verify.gd`: 12 checks, 0 failures (9 before). New checks:
  - the pinyin font has every tone letter and every letter the readings use
  - the built-in font still lacks the caron letters
  - `PinyinText.style` gives a label the font and hides it
- `tools/language_check.gd`: 1,890 checks, 0 failures. The helper keeps tone letters out
  of game code: the test lists them.
- `docs/evidence/ui-settings-20261104/verify_town.gd` (`VT_FOCUS=supermarket,hospital`, focused): 54
  checks, 0 failures. `docs/evidence/family-game-20261104/verify_town.gd` (`VT_FOCUS=hospital`,
  focused): 38 checks, 0 failures.
- Graphical:
  - New `docs/evidence/chinese-pinyin-20261104/capture_tones.gd`
    ([tones](../evidence/chinese-pinyin-20261104/tones.png)): every tone letter, ǖ ǘ ǚ ǜ and the
    capitals in a `PinyinText` label, above the built-in font. Zoomed, the carons on ǎ ǒ ǔ
    ǚ are pointed and the ü tones stack above the dots. In this bare test the built-in font
    shaped them acceptably too.
  - Re-rendered `docs/evidence/chinese-pinyin-20261104/capture.gd` (greeting, question-revealed,
    word-card, `VT_FOCUS=hospital`). In the game, before the fix, "hǎo", "Wǒ" and "xiǎng"
    had rounded carons and ǐ came from another font; after, the carons are pointed and the
    weight is even. The layout is unchanged.

Still open: the font's license text (OFL.txt) should go into `fonts/` with the font when the
game is distributed; it needs a separate download approval.


## Chinese playable (offered in Settings) — 4 November 2026

User decision: add Chinese to Settings; Mandarin pinyin is fine for now. Each check run
once on the finished change. Isolated HOME; `dev_focus.txt` reads `all`.
- `data/languages.json`: `zh` no longer has `"status": "draft"`, so `Lexicon.playable_codes()`
  is `en, es, zh` and Settings offers "Chinese (中文（香港）)". The draft mechanism stays for
  later languages.
- `scripts/learning/family_session.gd` `end_activity()`: returns when Dr. Li's node is
  missing. Choosing a language with the hospital not built (`VT_FOCUS` without `hospital`)
  logged "Cannot call method 'set_meta' on a null value"; setup already skipped the missing
  node. Found by the capture below; the guard was added after the town checks, which build
  the hospital and so never reached it.
- `python3 tools/word_data.py`: ok. `tools/language_check.gd`: 1,890 checks, 0 failures; `zh`
  is reported as playable with 585/585 words and 399/399 phrases.
- `docs/evidence/chinese-family-20261104/verify.gd`: 139 checks, 0 failures. Its draft checks now
  require `zh` to be playable and a saved choice of Chinese to be kept.
  `docs/evidence/chinese-pinyin-20261104/verify.gd`: 12 checks, 0 failures.
- Focused town checks (`VT_FOCUS=supermarket,hospital`): `docs/evidence/ui-settings-20261104/verify_town.gd`
  54 checks, 0 failures; `docs/evidence/language-ui-20261104/verify_town.gd` 51 checks, 0 failures.
- Graphical, new `docs/evidence/chinese-playable-20261104/capture.gd` (`VT_FOCUS=supermarket`, focused):
  [Settings](../evidence/chinese-playable-20261104/settings-chinese.png) with Chinese chosen and the
  "Chinese only / Both / English only" toggle;
  [word card](../evidence/chinese-playable-20261104/card-apple.png) 蘋果 with pinyin píngguǒ.

Still open: review of the Chinese text by a Chinese speaker; Jyutping, if the user later
wants Cantonese readings; the font's OFL.txt (see the pinyin font entry).

## Family game: highlight the people the question names — 4 November 2026

User request: highlight the people a question names, so the learner can attend to the
language. Each check run once on the finished change. Isolated HOME; `dev_focus.txt` reads
`all`.
- `scripts/learning/family_questions.gd` `named()`: the relation question's subject, or
  both people of the three pair kinds; nobody for age, month, year and oldest/youngest
  (highlighting there would point at the answer). `family_session.gd` passes it as
  `ui.named`; `family_panel.gd` gives those cards a pale gold fill, a 4 px gold border and a soft glow
  (6 px, 30% opacity; the first version's 6 px border and 12 px, 75% glow was too strong for
  the user). A right/wrong mark replaces the border colour.
- `docs/evidence/family-game-20261104/verify.gd`: 86 checks, 0 failures. Over 4,000 questions,
  `named()` is exactly the subject or the pair, every id is a family member, and a relation
  question never highlights its answer.
- `docs/evidence/family-game-20261104/verify_town.gd` (`VT_FOCUS=hospital`, focused): 39 checks,
  0 failures. New check: the cards with the gold border and glow are exactly `named()`.
- Graphical, new `docs/evidence/family-highlight-20261104/capture.gd` (`VT_FOCUS=hospital`, focused,
  Spanish), re-rendered once with the softer glow (the town checks above ran before it; only
  the colours and sizes changed): [relation](../evidence/family-highlight-20261104/relation.png)
  ("¿Quién es la madre de Roberto?", Roberto lit), [yes/no pair](../evidence/family-highlight-20261104/pair.png)
  (José and Fernanda), [who is older](../evidence/family-highlight-20261104/pair-who.png),
  [month, nobody lit](../evidence/family-highlight-20261104/none.png) and
  [wrong tap](../evidence/family-highlight-20261104/pair-wrong.png) (red border and ✗ on the lit card).
  Assessed: the gold border picks the people out across the tree; the glow stays close to
  the card.

Not built: a photo next to each name in the question (undecided; see the design record).

## Test sweep: mission code removed from stale checks — 4 November 2026

The mission system was removed on 3 Nov, so the checks that called `game.quests`,
`relocate_quests` or `learning_quests.gd` were edited to drop those lines (the other
assertions are unchanged): `check_sitting`, `check_compact_layout`, `check_town_layout`,
`check_cafe_bank_exteriors`, `check_school_partition`, `check_market_interior`,
`check_building_dimensions`, `check_hospital_departments`, `check_school_exterior`,
`check_supermarket_exterior`, `check_area_journal` and `docs/evidence/world_expansion/verify.gd`.
This supersedes the "stale" lists above for the missions only.

Each run once, headless, from a scratch copy of the project (not the shipped one),
`dev_focus` `all`. The copy's isolated-save setting was written under the wrong key, so the
runs used the normal user folder; no save file there changed (only logs), but treat the
setup as not isolated. They no longer fail on missions, but results are **mixed**:

| Check | Result |
|---|---|
| `check_compact_layout` | 646 checks, 0 failures |
| `check_town_layout` | 0 failures |
| `check_hospital_departments` | 24 room words placed, 0 failures |
| `check_sitting` | 384 checks, 10 failures, all E-key sit/stand transitions (last recorded: 0 failures) |
| `check_cafe_bank_exteriors` | 964 checks, 466 failures (walk-path samples at the café) |
| `check_school_partition` | 1074 checks, 271 failures (exterior and door registry comparisons) |
| `check_market_interior` | 8256 checks, 429 failures (e.g. fixtures outside the shell) |
| `check_building_dimensions` | 2008 checks, 482 failures (market north expansion samples) |
| `check_school_exterior` | 794 checks, 330 failures (parking, canopy, entrance samples) |
| `check_supermarket_exterior` | 595 checks, 303 failures (approach and entry samples) |
| `docs/evidence/world_expansion/verify.gd` | 1000 checks, 23 failures (snapshot site locations, vocabulary associations) |
| `check_area_journal` | **not run**: refused to start (its isolated user-dir check did not match) |

Unresolved (priority order): (1) the six building-exterior/interior checks above fail on
hundreds of walk-path and baseline comparisons; the town has changed since their baselines
were recorded, so they need re-baselining or retiring after review, not blind fixing;
(2) `check_sitting` E-key failures; (3) `check_area_journal` unverified. The failures were
not compared with a pre-edit run, so which are older than this edit is unknown.

### Follow-up: sitting check fixed, six building checks re-baselined — 4 November 2026

Runs below used a scratch copy with `config/use_custom_user_dir` set correctly
(`VocabularyTownChecks/perf`), so they were isolated; `dev_focus` `all`. Each run once.

- `check_sitting`: **385 checks, 0 failures.** The 10 E-key failures were the check's,
  not the game's: Poppy rests on `RelocatedSites/Home/Lounge chair`, and the game rightly
  refuses a taken seat. The check now uses a free home chair (the lounge chair when free).
- Six building checks re-baselined at the user's request: `--record-baseline` from the
  current game, then a normal run. The new `baseline.json` files replace the October ones
  (old ones in git history). `check_building_dimensions` now records from the current
  `main.gd`; its old `docs/resize_baseline_sources/main.gd` no longer exists.
  All snapshot ("preserved/unchanged") comparisons now pass. Remaining failures are
  fixed-coordinate walk-path samples and one bounds test written for the October layouts:

| Check | Before | After re-baseline | Remaining failures |
|---|---|---|---|
| `check_school_partition` | 271 | **0** / 1074 | none |
| `check_cafe_bank_exteriors` | 466 | 9 / 642 | café approach and interior spine |
| `check_supermarket_exterior` | 303 | 13 / 365 | market pedestrian approach and entry |
| `check_school_exterior` | 330 | 31 / 564 | school parking, canopy, entrance and hall |
| `check_market_interior` | 429 | 133 / 8679 | aisle clearances (dry goods, connecting, frozen, checkout); "fixture within shell Costume" |
| `check_building_dimensions` | 482 | 207 / 1887 | market rear aisle, south/north expansion, school entry and hall, market entrance |

Unresolved (priority order): (1) decide per walk-path sample whether a route is really
blocked in game (play-test) or the sample coordinates are outdated after the supermarket
and school redesigns; then move the samples or fix the geometry; (2) the "Costume" fixture
outside the market shell; (3) `check_area_journal` still not run.

### Project rename and save migration — 4 November 2026

`config/name` is now "Vocabulary Town" (was "Vocabulary Town v0.21 - Discovery Missions").
`scripts/core/save_migration.gd` (first call in `Main._ready()`) copies the four save files
from the old `user://` folder when the new one has none; details in the README.
Checked once, headless, with fake saves in an isolated `VocabularyTownChecks` folder: first
run copied 3 files (the obsolete quests file was skipped), a second run copied nothing and did
not overwrite a changed `settings.json`, the old folder stayed intact; test folders removed.
**Not checked:** a full game boot under the new name, so the learner's real saves have not
been migrated yet; they will be copied on the first launch.

### Save migration confirmed; market bounds test skips plush staff — 4 November 2026

- **Save migration, real launch** (one headless boot of the shipped project): printed
  "Save migration: copied 4 save files"; all four files in `app_userdata/Vocabulary Town`
  are byte-identical to the old folder, which is unchanged.
- **"Costume" outside the market shell** was Twinkle the beagle clerk, who stands outside
  the door by design (3 Nov). `check_market_interior` now skips plush characters in the
  fixture-bounds test. Run once, isolated: **8615 checks, 102 failures** (was 133); the
  Costume failures are gone and nothing new failed. Remaining: aisle walk-path samples
  (connecting 33, dry goods 33, frozen approach 13 — the frozen section was removed in the
  2 Nov refit, checkout 12), `dictionary card cashier` (2) and the `tea` pick (1).


### Boston-inspired central garden — 4 November 2026

Implemented the user's approved garden refinement with the explicit correction
that lawns retain subtle, realistic variation. The monument garden and avenue
have quieter grades, the high basin shoulder and five mounds are removed, six
formal beds have fuller seasonal planting, and trees/accents frame the open lawn.
Existing path centerlines are retained and refitted to the new terrain. See
[ownership and tuning](public-garden/README.md#boston-inspired-garden--4-november-2026).

Godot 4.7.2, isolated project at `/tmp/vt-garden-20261104`, custom user directory
`VocabularyTownChecks/garden-20261104`; `dev_focus.txt=all`, no focus override.
The first baseline launch was invalid because the temporary copy lacked `fonts/`
and the sandbox denied its test-data directory; stopped it, completed the copy,
and ran the valid baseline with test-directory access. No gameplay changes had
been copied into that baseline. Learner saves were not used.

| Check | Result |
| --- | --- |
| Baseline `check_park_terrain.gd` | 0 failures; 913 elevated collision samples, six actual-player traversals, 23,948 triangles |
| Final `check_runtime_resources.gd` | 389 resources, 0 failures |
| Final `check_park_terrain.gd` | 0 failures; 452 elevated collision samples, six actual-player traversals, 22,542 triangles; sampled peak 0.832 town units, monument oval peak 0.255; grade bounds, adjacent slopes, level protected pads, nonzero relief, shoreline and idempotence passed |
| Final `check_public_garden.gd` | 0 failures; 1,638 path-clearance samples; bridge crossings, shore junctions, wading under bridge and dock entry passed |
| `docs/guides/public-garden/capture_pond.gd` | One graphical batch, five 1200 × 800 views rendered and inspected |
| `git diff --check` | Passed |

Rendered evidence: [overview](public-garden/pond-boston-20261104-overview.png),
[monument](public-garden/pond-boston-20261104-monument.png),
[low lawn view](public-garden/pond-boston-20261104-lawns.png),
[bridge approach](public-garden/pond-boston-20261104-approach.png),
[bank](public-garden/pond-boston-20261104-bank.png).
The lawn/monument/overview views show the subdued terrain, clear approach and
filled beds; paving follows the ground without visible breaks. The bank camera
is partly obscured by a tree, so it is limited shoreline evidence; no repeat
capture was run. Legacy material warnings remain. No full-suite, FPS benchmark,
boat-steering regression or interactive manual-play claim; previously documented
vehicle/metadata and market failures are outside this verification scope.


### Boston garden photographic layout revision — 4 November 2026

Supersedes the first garden pass above. The user requested stronger northeast and
northwest statue lawns, two fountains and clipped bushes, then supplied a clearer
aerial specifying the bed/path arrangement. Implemented a grass statue island,
ring walk, straight cross-paths, narrow lawn-edge/crescent borders, two tapered
entrance beds, twelve clipped shrubs and two entrance-side stone fountains. Trees
are relocated clear of fountain basins without deleting their learning roots.
Existing lagoon, bridge, building sites and destination connections remain.
[Current ownership, geometry and references](public-garden/README.md#boston-inspired-garden--4-november-2026).

Verification used Godot 4.7.2, the same isolated project at
`/tmp/vt-garden-20261104` and `VocabularyTownChecks/garden-20261104` user directory.
`dev_focus.txt=all`; no focus override. The previous valid 0-failure terrain run
(452 samples/six traversals) was reused as baseline after confirming the terrain,
garden, refinement and terrain-check source files matched that tested copy.

| Check | Final result |
| --- | --- |
| `check_runtime_resources.gd` | 389 resources, 0 failures |
| `check_park_terrain.gd` | 0 failures; 476 elevated collision samples, six actual-player traversals; 22,372 triangles; sampled park peak 1.375 town units, monument oval peak 1.110; bounded gradients, nonzero northern relief, level fountain aprons, shoreline and guard checks pass |
| `check_public_garden.gd` | 0 failures; 1,929 path-clearance samples; three connected loops, two fountains, twelve shrub StudyAreas, trees clear of fountain sites, bridge crossings, shore junctions, under-bridge wading and dock access pass |
| `capture_pond.gd` | Final seven-view 1200 × 800 graphical batch rendered and inspected |
| `git diff --check` | Passed |

A lightweight height-function probe (no town construction) measured NE relief at
(29,155) as 1.067 and NW at (65,155) as .605 town units, with maximum adjacent
one-unit height change .192; these are design samples, not surveyed Boston grades.

Corrections during verification: fixed one GDScript type-inference error before
valid gameplay checks. The first stronger terrain trial had 30 grade/height
assertion failures; reducing amplitudes left two fountain-transition violations,
and widening that blend left one old NW sampling-point assertion. The subsequent
user-supplied aerial moved the fountains and NW shoulder; the actual intended NW
lawn now has the measured .605 relief above and passes. The first aerial path run
found two capsule offsets touching fountain rims at the ends of diagonal walks;
radial final approach segments fixed both. Rendered tree/basin overlap was fixed
by relocating tree roots. Checks/renders were repeated only after those concrete
fixes or the user's new layout instruction, not to obtain a flaky pass.

Final evidence: [north-up plan](public-garden/pond-aerial-20261104-plan.png),
[monument](public-garden/pond-aerial-20261104-monument.png),
[northern lawns](public-garden/pond-aerial-20261104-lawns.png),
[entrance beds](public-garden/pond-aerial-20261104-fountains.png),
[overview](public-garden/pond-aerial-20261104-overview.png),
[bridge approach](public-garden/pond-aerial-20261104-approach.png),
[bank](public-garden/pond-aerial-20261104-bank.png).
The bank view remains partly obscured by foliage; plan/monument/approach views
provide the useful layout evidence. No full-suite, performance benchmark,
boat-steering or manual-play claim. Legacy material warnings remain; previously
documented vehicle, metadata and market failures are outside this focused scope.
No learner saves were used. The user approved committing this revision on 4 November 2026.

### Washington monument refinement — 5 November 2026

User request: review and redesign the statue, bushes, flower beds and two
fountains to resemble the Boston Public Garden photographs, keeping the game's
style and leaving surroundings unchanged. Implemented a paved forecourt enclosing
the lens beds, 28 sheared yews (new shrub profile 3), chain fences and promenade
lamps, layered tropical lens beds, recoloured borders, low granite-sett fountains,
pedestal moldings and a raised foreleg
([record](public-garden/README.md#washington-monument-refinement--5-november-2026)).

Godot 4.7.2, `dev_focus.txt=all`. The checks ran in the shipped project, not an
isolated copy; none of them study words (progress is written only by
`save_studied_words`). Before/after views were rendered with the new
`docs/guides/public-garden/capture_monument.gd`; no baseline check run was made.

| Check | Result |
| --- | --- |
| `check_public_garden.gd` | 0 failures; 1,947 path-clearance samples; 28 yew StudyAreas with the `shrub` key (count check updated from 12 to `YEW_SPOTS`), two fountains, trees clear of fountains, three loops, junctions, bridge, wading and dock pass |
| `check_park_terrain.gd` | 0 failures; 470 elevated collision samples, six player traversals, 22,232 triangles; peak 1.375, monument peak 1.110; level fountain aprons pass |
| `check_runtime_resources.gd` | 389 resources, 0 failures |
| `capture_monument.gd` | Six 1200 × 800 views rendered and inspected (plan, forecourt, fountain, lens bed, avenue, statue) |

During design, renders found stacked-lobe yews reading as tiers, oversized bed
plants and spiky curb joints; these were fixed (single egg lobe plus base, smaller
plants, joints removed) before the checks above. Not run: `docs/evidence/part2/verify.gd`
(pedestal transform unchanged), `check_interaction.gd`, the full suite and any
performance measurement; the extra ~450 bed meshes and 28 yews are batched by
`garden_rendering.gd` but frame time was not measured. Legacy `specular` material
warnings remain. Earlier documented vehicle, metadata and market failures are
outside this scope.

### Monument trail cleanup — 5 November 2026

User request: edit the trails to follow their red/yellow markup of an in-game view
against the Boston aerial, with no overlapping trail clusters
([record](public-garden/README.md#monument-trail-cleanup--5-november-2026)).
Godot 4.7.2, `dev_focus.txt=all`, shipped project (no study actions).

| Check | Result |
| --- | --- |
| `check_public_garden.gd` | 0 failures; 1,815 path-clearance samples; four closed loops, the x=−91 entrance fork and other junctions, the new monument overlap check (no pair within 2.4 units for over 7.5 units at canonical x < −2), 28 yews, fountains, bridge, wading and dock pass |
| `check_park_terrain.gd` | 0 failures; 470 elevated samples, six player traversals, 22,232 triangles, peak 1.375 / monument 1.110 (grading unchanged) |
| `check_runtime_resources.gd` | 389 resources, 0 failures |
| `capture_monument.gd` | Seven views rendered; plan, the user's angle, forecourt and fountain inspected and kept |

Found and fixed during this work (each check was rerun only after a concrete fix):
the first garden run had two paths blocked by saved benches and a relocated grove
tree on the bridge's east end (both bridge walks failed). The first terrain run had
a grove tree on the NE slope traversal, standing in the lawn freed by the removed
x≈−18 bend. The second garden run found the northern connection crossing the
rabbit's wander circle. Fixes rerouted the two lagoon links and changed the tree
relocation rules; no check thresholds or traversal routes were changed. A
temporary overlap scan also lists east-bank overlaps (Charles walk/lagoon walk 27
units, east entrance/gazebo link 21) outside this area; these are unchanged and
not covered by the new check.

## Warehouse Phase 1: building and school move — 5 November 2026

User request: a warehouse between the airport and the school, the school moved toward the
hospital, a furnished reception and an empty hall ([record](TOWN_DESIGN_BRIEF.md#warehouse-and-warehouse-worker-minigame--5-november-2026),
[guide](WAREHOUSE.md)). Godot 4.7.2, `dev_focus.txt=all`, isolated HOME, no study actions.

| Check | Result |
| --- | --- |
| `check_compact_layout.gd` (baseline before edits) | 646 checks, 0 failures |
| `check_compact_layout.gd` (after) | 647 checks, 0 failures (separate footprints, location bindings and rigid moves hold with the school at x 10) |
| `check_zones.gd` | First run 1 failure: "25 named zones" (the new `warehouse` zone makes 26, intended). Count updated to 26 and samples added for the warehouse and the moved school; rerun 5,094 checks, 0 failures |
| `tools/language_check.gd` | 1,893 checks, 0 failed (new `places.warehouse` in three languages) |
| `check_runtime_resources.gd` | 390 resources, 0 failures |
| `docs/evidence/warehouse-20261105/verify.gd` (new) | 17 checks, 0 failures: footprint, school at x 10, gaps (hospital/school, school/warehouse over 15, warehouse/tower over 10), room name, zones, lot, drive, map entry, both doors registered and blocking when closed, receptionist, player-sized capsule clear from the lot through both open doors and across the hall |
| `docs/evidence/warehouse-20261105/capture.gd` | 11 views rendered and inspected. The first batch showed the monitor screen facing the visitor, the cladding reading white in sun, clerestory frames reading as stripes, the school crossing left at x 0 and the moved street tree on the sidewalk; all fixed and the batch re-rendered |

Not run: `docs/evidence/part2/verify.gd`, `check_interaction.gd`, vehicle and garden checks and the full
suite; no frame-time measurement for the six new omni lights. Door movement was checked
with a capsule, not by driving the player. Known vehicle, metadata and market failures
recorded earlier are outside this scope.

## Warehouse Phase 2: vocabulary — 5 November 2026

User approval: "Approve, start Phase 2" (the shortened A1–A2 list). 50 words, posters,
Ramón and word metadata ([guide](WAREHOUSE.md#vocabulary-built-phase-2)). Godot 4.7.2,
`dev_focus.txt=all`, isolated HOME, no study actions.

| Check | Result |
| --- | --- |
| `tools/language_check.gd` | First run 1 failure: 12 new Chinese characters had no pinyin (裹 闆 裡 去 舉 量 撿 稱 綠 重 輕 述); readings added; rerun 1,929 checks, 0 failed |
| `python3 tools/word_data.py` | 634 words; Actions 22, Colors & Descriptions 8, Time & Directions 41 |
| `docs/evidence/town-checks/check_vocabulary_translations.py` | First run: 44 "missing article" errors for the verbs, adjectives and position phrases (article-free by design; the checker now exempts those categories and phrases), boss/employee m/f forms (added to the allowed list), and two real clashes: *la caja* (box vs checkout counter) and *el carrito* (cart vs trolley). Fixed in the data: the box is *la caja de cartón*, the cart reuses `trolley`. Rerun: only the 2 known issues (`hair` two options; `crocodile_plush.tscn` key) |
| `docs/evidence/town-checks/check_vocabulary_categories.py` | 91,370 checks, 1 failure (the known crocodile key) |
| `check_runtime_resources.gd` | 390 resources, 0 failures |
| `docs/word_audit.gd` | 634 words in 22 categories, 631 with a clickable object; every new word is placed; the 3 unplaced (base, nurse, teacher) predate this work; no duplicate translations |
| `docs/evidence/warehouse-20261105/verify.gd` (extended) | 30 checks, 0 failures (run twice: before and after the box/trolley key change). New: walls and reception front wall pick as *warehouse*, door, cardboard box, trolley, Ramón = boss, Paty = employee (no name card), package; posters hold 22 / 14 / 8 cards all known to the Lexicon; walk in front of the entrance clear beside Ramón |
| `docs/evidence/warehouse-20261105/capture_words.gd` (new) | 7 views (3 posters, Ramón, trolley, pallet boxes, desk package with Paty), three batches. Batch 1: long position phrases shrank to unreadable size, the trolley's edge strip covered its deck, up/down arrow heads read as diamonds, "1 kg" overlapped its box. Batch 2: labels wrap, deck fixed; the chevrons pointed the wrong way. Batch 3 after the sign fix: see the guide's renders |

Not run: `docs/evidence/part2/verify.gd`, `check_interaction.gd`, the vehicle and garden checks and the
full suite. Chinese texts are drafts (no native check). The posters show the L-toggle
language only in Spanish here; English/Chinese rendering was not captured.

## Warehouse Phase 3: hall equipment — 5 November 2026

User approval: the equipment list plus *el contenedor*, light stock. Godot 4.7.2,
`dev_focus.txt=all`, isolated HOME, no study actions.

| Check | Result |
| --- | --- |
| `tools/language_check.gd` | 1,935 checks, 0 failed (new word `container`, phrases `posters.zone_in/out`, pinyin 納) |
| `docs/evidence/town-checks/check_vocabulary_translations.py` | only the 2 known issues (`hair`; crocodile key) |
| `docs/evidence/warehouse-20261105/verify.gd` (extended) | 44 checks, 0 failures. New: racks' shelves, both tables, ruler, scale, cabinet, conveyor, container, crate, truck and the moved trolley pick as their words; rack letters A–C; IN / OUT labels; scale readout; a player-sized capsule fits in front of each rack, the cabinet, the scale, both tables and inside both floor areas, besides the Phase 1 aisles |
| `docs/evidence/warehouse-20261105/capture_hall.gd` (new) | 8 views, two batches. Batch 1: the floor areas showed the raw phrase id (`warehouse.zone_in`; the phrases live in `posters`) and read upside down for a player facing them, and rack letter plates covered the top-shelf boxes. Fixed (`posters.zone_in/out`, flat labels face south, taller uprights with a top beam carrying the letters); batch 2 inspected and correct. `verify.gd` ran before these visual fixes (they change no picked word or walking space) |

Not run: word audit, `check_vocabulary_categories.py`, runtime resources, `docs/evidence/part2/verify.gd`,
`check_interaction.gd`, the vehicle and garden checks and the full suite; no frame-time
measurement.

## Warehouse Phase 4: game frame — 5 November 2026

User approval: "go ahead". Godot 4.7.2, `dev_focus.txt=all`, isolated HOME, no study actions.

| Check | Result |
| --- | --- |
| `tools/language_check.gd` | 1,983 checks, 0 failed (17 `warehouse.*` phrases; pinyin 係 存 第 蒙, 沒關係, 拉蒙) |
| `docs/evidence/warehouse-20261105/verify_game.gd` (new) | First run 28 checks, 0 failures, but the log held repeated "Invalid type in function 'highlight_object' … previously freed" script errors: the interaction controller passed the freed copy object under the cursor to a typed function. Fixed in `interaction_controller.gd`; rerun 28 / 0 with no script errors. Covers: talk target and activity data, greeting choices, copy built at the lift with no doors registered, Ramón hidden, player at the station, task card title, task and 0/5 bar, intro line, map stand-in and room name "Warehouse", other activities blocked, twin picks as *boss*, fall recovery, Esc → leave question, No keeps playing, twin repeats the task, Leave → Yes frees the copy and returns the player, card hidden, stand-in cleared, board free; a second game ended by a language change also frees the copy |
| `docs/evidence/warehouse-20261105/verify.gd` | 44 checks, 0 failures (the copy flag leaves the town doors registered) |
| `check_runtime_resources.gd` | 392 resources, 0 failures |
| `docs/evidence/warehouse-20261105/capture_game.gd` (new) | 7 views, two batches. Batch 1: the task card stretched to the bottom of the window (wrapped labels measured before their width settled) and drew over the dialogue box and the leave question. Fixed (refit after a frame; the card sits under the dialogue panel) and Ramón's twin moved 0.8 m further from the station; batch 2 inspected and correct. `verify_game.gd` ran before these layout fixes |

Not run: word audit, vocabulary category check, `docs/evidence/part2/verify.gd`, `check_interaction.gd`
(the controller changed by one guard), the vehicle and garden checks and the full suite.
The game was driven by calling the session's signals, not by keyboard and mouse input.

## Warehouse Phase 5: goods and tasks — 5 November 2026

User approval: "yes go ahead". Godot 4.7.2, `dev_focus.txt=all`, isolated HOME, no study actions.

| Check | Result |
| --- | --- |
| `tools/language_check.gd` | 2,214 checks, 0 failed (76 new `warehouse.*` phrases replacing `example_task`; `polish()` contractions pinned by three es samples and one en/zh sample each; one zh reading sample; pinyin 寫 度 從 抓 斤 某 案 準 留 答 置 訴 and words 告訴 答案 位置 對準 寫着 量度 某個 拿出來 包裹). First run failed one reading sample (包裹 read as two words); fixed by the `words` entry |
| `docs/evidence/warehouse-20261105/verify_game.gd` (extended) | Development runs: 100 checks / 3 failures (the scale summed two items, so the weight question was asked with a wrong screen; only one cabinet door got a hinge because duplicate part names are renamed by Godot), then 100 / 1 (hinge). Fixed (weigh / measure only with the device free and the item alone on it; doors named `west` / `east`); final run **100 checks, 0 failures, no script errors**. New coverage: 7 upright rigid goods, containers, trolleys, hinges; all 38 entries written, rendered in es/en/zh without placeholders or *de el / a el*, and solved by scripted moves (place goals, holding, handing over, trolleys, cabinet, going to a rack) or answered (weigh / measure readouts and choices, where choices); W pushes a held trolley, the player stays behind the handle with walking off, E lets go; E on the cabinet; carrying floats the box and puts it down; out-of-reach items are not picked up; session flows: wrong place → *Dime qué salió mal* → hint and marker → right place counted; weight asked on the scale, wrong answer → screen hint → right answer; *Dame* by talking while carrying; *¿Dónde está?* answered |
| `docs/evidence/warehouse-20261105/verify.gd` | 44 checks, 0 failures |
| `check_runtime_resources.gd` | 394 resources, 0 failures |
| `docs/evidence/warehouse-20261105/capture_tasks.gd` (new) | 8 views, two batches. Batch 1: the carried box hid behind the player, the weight choices could read "1 kilos", Ramón's face zoom covered the scale screen during the weight question, and a long box hid the measuring screen. Fixed (carry height 1.75, weights from 2 and choices above 1, no face zoom for number questions, the measuring screen on a post); batch 2 inspected and correct. `verify_game.gd` ran before these four fixes |

Not run: word audit, vocabulary category check, `docs/evidence/part2/verify.gd`, `check_interaction.gd`,
the vehicle and garden checks and the full suite. The game was driven by calling the
session, goods and signals (and one parsed W key event), not by playing with keyboard and
mouse; nudging by walking, aiming a put-down with the mouse and frame time were not measured.

## Warehouse play-test refinements — 5 November 2026

User request: reference boxes next to a wall for directional tasks, bigger boxes, play-test
and improve interior and question types. Godot 4.7.2, `dev_focus.txt=all`, isolated HOME.

| Check | Result |
| --- | --- |
| `tools/language_check.gd` | **2,289 checks, 0 failed** (25 new `warehouse.*` phrases; pinyin 甚 麼 and words 甚麼 東西 顏色) |
| `docs/evidence/warehouse-20261105/verify_game.gd` (extended: bays, wall frame, variants) | First run 142 checks / 5 failures + a script error: tasks moved the bay boxes away so *left / right* became unwritable, a *behind* put-down landed on the reference (sizes ignored a box turned by pushing), `take_out` drawn after the bottle had left, and the check assumed `make("weigh")` is never empty. Fixed in the game (tasks never use things standing in a bay; `half()` follows the turn) and in the check. Second run 124 / 3 (the check assumed `make("inside")` is a place task; it can be a *what* question). **Final run 127 checks, 0 failures**: all 38 entries written and solved or answered; colour, what and both comparison variants written, rendered without placeholders and answered |
| `docs/evidence/warehouse-20261105/verify.gd` | First run 1 failure (expected three rack letters; the floor letters make six); check updated; **44 checks, 0 failures** |
| `check_runtime_resources.gd` | 394 resources, 0 failures |
| `docs/evidence/warehouse-20261105/playtest.gd` (new, real key events and pointer) | Three runs while fixing. Run 1: walking into a box moved it 0.00 m, a 2 s trolley push ended 0.36 m short of its area. Fixed (`_nudge()` sets a walking speed; trolley 2.6 m/s). Run 3: pick-up, aimed put-down right of a bay box, nudge 1.03 m, trolley 5.07 m into the area, cabinet, colour and comparison questions all as intended; views inspected |
| `docs/evidence/warehouse-20261105/capture_tasks.gd` | 8 views re-rendered (made robust to the new task kinds), inspected |

Not run: word audit, vocabulary category check, `docs/evidence/part2/verify.gd`, `check_interaction.gd`,
vehicle and garden checks, the full suite. No human hands-on play; frame time not measured.


## Airport flight game — 5 November 2026

User request: an airport minigame for time, date and country words (Capitán Bruno, departure
board, schedule booklet) and one shared random "today" for it and the family game. Godot
4.7.2, `dev_focus.txt=all`; the graphical capture ran with `VT_FOCUS=airport` (airport
interior only, **not the full town**) and an isolated HOME.

| Check | Result |
| --- | --- |
| `tools/language_check.gd` | First run failed: 20 Chinese characters had no pinyin; added. **2,526 checks, 0 failed** (66 new words, `flight.*` phrases) |
| `docs/evidence/flight-game-20261105/verify.gd` (new, logic only) | 600 random todays × 12 questions: schedules valid (16–20 flights, unique codes, times and month/days, sections hold every flight, board range), every question has **exactly one** matching flight in the right tense, every kind appears, every question and wrong-flight explanation renders in every language. **619 checks, 0 failed** |
| `docs/evidence/family-game-20261104/verify.gd` (now rolls the shared today each round) | **86 checks, 0 failures** |
| `check_runtime_resources.gd` | 402 resources, 0 failures (old SpatialMaterial `specular` warnings only) |
| `docs/evidence/flight-game-20261105/capture.gd` (new) | 16 views. First renders showed: the front-wall *¿Cuándo?* poster's title and first row missing (`building_exteriors.gd` `hide_front_labels()` hid labels near the front facade above 3 m; poster labels now carry `interior_label`), poster words breaking mid-word (smaller text), board rows under the feedback lines and the booklet footer pushed off the page (rows fit the space; the booklet page now scrolls). The final run stalled (Godot idle, frames not drawn, likely a throttled window) after `game-chinese`; it was stopped, not re-run, so `browse-past.png` is from the run before the scroll change. Views inspected |

Not run: word audit, vocabulary category check, `docs/evidence/part2/verify.gd`, `check_interaction.gd`,
vehicle and garden checks, the full suite. No real-input play-test of walking to Bruno or
pressing E on the board; no human hands-on play; frame time not measured. Chinese rows with
translation shown are small, their two lines sit slightly out of step across columns, and a busy week scrolls (priority: low).

## Integrated vehicle doors — 5 November 2026

Scope: [vehicle guide](ZOO_VEHICLE_IMPLEMENTATION.md#integrated-vehicle-doors-and-warehouse-box-truck--5-november-2026).
Godot 4.7.2 Compatibility; full `dev_focus.txt = all`, temporary project
`/tmp/vt-vehicle-checks`, isolated relative user folder
`VocabularyTownChecks/vehicle-doors`. Personal learner saves were not used.

| Check | Result |
| --- | --- |
| Pre-change `docs/evidence/town-checks/check_vehicle_boarding.gd`, fixed 60 FPS | 73 checks, 0 failures |
| Updated `docs/evidence/town-checks/check_vehicle_boarding.gd`, fixed 60 FPS | 73 checks, 0 failures: Subi E entry/exit, garage drive-out, collision restoration, all road-vehicle acceleration/braking/steering checks; permanent closed doors are now visible |
| `docs/evidence/town-checks/check_runtime_resources.gd` | 402 resources, 0 failures; resource pass preceded the last CSG winding correction, which was subsequently compiled/executed by the final graphical integration run |
| New `docs/evidence/town-checks/check_vehicle_doors.gd`, final graphical run, fixed 60 FPS | **138 checks, 0 failures**, no script/runtime errors in final log: all 12 registered vehicles, permanent closed geometry, E boarding, hinged opening/closure, safe actual-door exits, reverse animation, return to walking/collision, unchanged node counts through interaction; warehouse prefab and separate cab/cargo nodes |
| Visual inspection | Closed/open model views reviewed for car, taxi, police car, pickup, ambulance, fire truck, bus, school bus, Subi, helicopter and turboprop; motorcycle remains doorless. Warehouse truck reviewed at its preserved loading-bay position. |
| `git diff --check` | Passed |

Reviewed contact sheets (closed left, open right):
[car/taxi/police/pickup](../evidence/vehicle-doors-20261105/contact-0.jpg),
[ambulance/fire truck/bus/school bus](../evidence/vehicle-doors-20261105/contact-1.jpg),
[Subi/helicopter/turboprop](../evidence/vehicle-doors-20261105/contact-2.jpg),
and [warehouse truck](../evidence/vehicle-doors-20261105/warehouse-truck.png).
BonBon is hidden only during model-inspection snapshots; the integration check runs
her actual boarding/exit animation and verifies walking visibility restoration.

Development findings, retained for accuracy: initial fixture did not settle unoccupied
vehicles and stepped the aircraft through the road API; corrected both. Initial
school-bus word alias selected the car profile; added its bus mapping. The first
render fixture was beyond the aircraft's 2,500-unit boundary; moved it to (900,900).
CSG polygon outlines can have either winding: visual review caught missing Subaru
hood/windscreen surfaces, now corrected by orientation-aware side triangulation.
The aircraft's existing door swung inward; it now opens outward, and its fixed lower
sill no longer overlaps the leaf. The final run above follows these corrections;
these were deterministic implementation/fixture defects, not repeated flaky passes.

Earlier isolated runs logged sandbox user-log access warnings, legacy material
`specular` warnings, and a missing imported map texture in the temporary copy. The
map import was restored from the source cache before the final graphical run; its
log has no errors. These did not involve personal saves or changed game assets.

Limits: scripted E-handler cycles on a clear pad plus Subi's garage sequence, not
an exhaustive manual drive/flight circuit at every parking position. No full suite,
performance benchmark or save-persistence test was run. Existing unrelated vehicle,
metadata and broader suite issues elsewhere in this record are not declared fixed.
Door leaves retain the existing whole-vehicle collision envelope; they do not add
physical swinging-door collision/sweep avoidance against adjacent scenery. The
warehouse box truck remains decorative; rear loading interactions and collision
changes for cargo access remain future work (P2). Legacy textured/skinned model
partitioning is unsupported; use authored hinges for such future vehicles.

## Warehouse Phase 6: full suite — 5 November 2026

User: "you have 10%, try breaking it into smaller steps … airport is done". Tree at
`ef87fc9` (warehouse refinements and the airport flight game committed), Godot 4.7.2,
`dev_focus.txt=all`, isolated HOME, `--fixed-fps 60`, each check run once (a first batch
did not start: macOS has no `timeout`, exit 127). The full suite is **not clean**.

| Check | Result | Compared with the last record |
| --- | --- | --- |
| `docs/evidence/warehouse-20261105/verify.gd` | 44 checks, 0 failures | same |
| `docs/evidence/warehouse-20261105/verify_game.gd` | 151 checks, 0 failures | same (count varies with the random variants) |
| `tools/language_check.gd` | 2,526 checks, 0 failed | — |
| `check_runtime_resources.gd` | 402 resources, 0 failures | — |
| `check_compact_layout.gd` | 647 checks, 0 failures | — |
| `check_public_garden.gd` | 0 failures, 1,815 path samples, bridge both ways | — |
| `check_helicopter_physics.gd` | 34 checks, 0 failures | — |
| `check_road_physics.gd` | 153 checks, 0 failures | — |
| `check_hospital_departments.gd` | 24 room words, 0 failures | — |
| `docs/evidence/part2/verify.gd` | 1,330 checks, **4 failures**: `thirteen marked front parking areas` (14 now: the warehouse added its front lot in Phase 1, a stale count) and `drive clearance Home garage drive 21` at −1.4 / 0 / 1.4 (hits the Home garage door section) | parking: caused by the warehouse; garage: new, not investigated (the garage door was last changed by `f103d0a`, vehicle door animations) |
| `check_interaction.gd` | **2 failures**: `Hover label identifies target`, `Card translation and category` | new (last recorded pass); not investigated |
| `check_aircraft.gd` | 30 checks, **4 failures**: `airplane vocabulary` (known stale category), `E disembarks after landing`, `high-speed wing impact stops aircraft and offers recovery`, `walking collision and visible pig restored` | 3 new; not investigated |
| `check_zoo_vehicles.gd` | 31 checks, **5 failures**: `gate translation`, `gate vocabulary popup` (known), `E boards Car`, `player is on foot again`, `hyper effects resume after exiting` | 3 new; not investigated |
| `check_hospital_remodel.gd` | 1,087 checks, **1 failure**: `Hospital retains word floor` | new; not investigated |
| `check_seats_and_swan_boats.gd` | **1 failure**: airport seats sat on intended seat 51/54 | known label (53/54 before); the airport interior changed in `ef87fc9` |
| `check_vocabulary_categories.py` | 91,560 checks, 1 failure (known crocodile key) | same |
| `check_vocabulary_translations.py` | **51 issues** (50 printed): known `hair`, and 49 *missing definite article* on the airport game's new time, weekday and country words (`ef87fc9`) | 49 new, from the airport words (the 51st issue is counted but not printed); the checker's article rule does not fit adverbs, times and country names |

Not run: word audit, `check_interaction`-style graphical captures, baseline comparisons at an
earlier commit (not requested). The new vehicle, interaction, aircraft and hospital failures
were not traced to a commit; the warehouse code does not touch vehicles, cards or the
hospital, but this was not proven.


### Tracing the new failures (5 Nov 2026, user: "work on the untraced failures first")

| Failure | Cause | Action / result |
| --- | --- | --- |
| `check_interaction.gd`: hover label, card translation | **Stale test.** Since UI Stage 3 (`60abf20`, 4 Nov) the hover label and card show the lexicon's text (*la puerta*, lowercase *door*), not the fixture's `puerta` / `Door` | Test updated (accepts the article and either language); rerun **passes** |
| `check_zoo_vehicles.gd`: `E boards Car`, `player is on foot again`, `hyper effects resume after exiting`; `check_aircraft.gd`: `E disembarks after landing`, wing impact recovery, walking collision restored | **Very likely stale tests** after the vehicle-door commit `f103d0a` (5 Nov): boarding and exits are now door-checked animated sequences with permanent closed door geometry; these older tests place the player inside the car and expect E to seat or unseat at once. That commit verified only `check_vehicle_boarding.gd` and `check_vehicle_doors.gd` | Both rerun on the current tree: **73 checks, 0 failures** and **138 checks, 0 failures** (all 12 vehicles board and exit through their doors). The zoo and aircraft tests were not updated (P2) |
| `docs/evidence/part2/verify.gd`: `thirteen marked front parking areas` | Warehouse lot (Phase 1) makes 14 | Not changed yet (P2: expect 14) |
| `docs/evidence/part2/verify.gd`: `drive clearance Home garage drive 21` (×3) | Hits `Home/Garage door/Section 1`; likely the garage door work in `8b09c2a` / `f103d0a` | Not traced further (P2) |
| `check_hospital_remodel.gd`: `Hospital retains word floor` | No hospital node carries `word_key` *floor* any more; not traced to a commit | Open (P2) |
| `check_seats_and_swan_boats.gd`: airport seats 51/54 | Airport interior changed in `ef87fc9` | Open (P3) |

None of these trace to the warehouse game code.

## Airport flight game: layout, flags and bilingual rows — 6 November 2026

User request: information desk right of the door, the poster wall moved to the empty front
wall left of the door (both posters, plus a new countries poster), right-hand waiting rows
removed, country flags, readable Chinese rows. Godot 4.7.2, `dev_focus.txt=all`; the capture
ran with `VT_FOCUS=airport` (airport interior only, **not the full town**), isolated HOME.

| Check | Result |
| --- | --- |
| `tools/language_check.gd` | **2,529 checks, 0 failed** (`posters.countries_title`) |
| `docs/evidence/flight-game-20261105/verify.gd` | **619 checks, 0 failed** |
| `docs/evidence/airport-interior-20261028/verify.gd` (updated: seats ≥ 35 after the three removed rows, the seat-row solid moved to the kept rows, the desk added as a solid) | First run: every flight-game poster label failed "sign translated" (the check, last run 28 Oct, expected fixed English sign text; poster cards are live Lexicon labels since 5 Nov). Check now skips `interior_label` poster labels. **184 checks, 0 failures**: walkways (door, entry, aisle) clear, gate partition intact |
| `docs/evidence/flight-game-20261105/capture.gd` (views updated: `entrance`, `poster-countries`, `game-chinese-board`; `concourse` dropped) | 18 views, run completed; inspected: desk and Bruno right of the door facing the aisle, the left rows and pilot Awoo kept, four posters with flags, flags in board and booklet rows, Chinese rows with English under each cell, aligned |

Not run: `check_runtime_resources.gd`, `docs/evidence/people-vehicles-posters-20261031/verify.gd` (pilot Awoo's
seat is unchanged), the full suite; no real-input play-test. With Chinese and translations
shown the booklet page shows about three flights at a time and scrolls (the question, pinyin,
translation and two-line "today" take the top of the panel; priority: low).
Follow-up the same day (user request): the "today" line now stays one line in the foreign
language, its translation on hover. `capture.gd` re-run once (completed): `game-chinese`
shows about 3½ flights in the booklet, `game-chinese-board` 5 on the board (4½ before); the
rest scroll.

## Alta Cocina restaurant game — 6 November 2026

User request: a restaurant ordering game in Alta Cocina (Twinkle, one seated customer,
icon-only dish inspection). Godot 4.7.2. `dev_focus.txt` was set to `police` by a concurrent
session at the time; the town run overrode it with `VT_FOCUS=all` (**full town**) and used an
isolated HOME.

| Check | Result |
| --- | --- |
| `tools/language_check.gd` | First run failed: 26 Chinese characters had no pinyin; added. **2,979 checks, 0 failed** (46 new words, `restaurant.*` phrases; the count includes a concurrent session's new words) |
| `docs/evidence/restaurant-20261106/verify.gd` (new, logic only) | Catalog valid; 3,000 random menus × 4 courses × 3 settings (shipped; intensity and negation forced; negation with 3 requirements): every order exists, **exactly one** dish of its course matches, every other dish misses a requirement, every order and missed-requirement line renders in es/en/zh, Spanish adjectives after *algo* are masculine. **522,827 checks, 0 failed** |
| `docs/evidence/restaurant-20261106/capture.gd` (new; town checks + 16 views) | **32 checks, 0 failed**: seat marker, Twinkle's meta, a seated non-staff customer on the booth, four posters with icon sheets; one meal through the session (a wrong dish then the right one for each course, the missed property, progress 1–4, summary, Finish, a different customer); the activity board blocks another game during the meal and frees it after; leaving early. First renders showed each dish row's price wrapped one character per line, pushing picture and name off the row (price no longer wraps; rows grow for two-line names and the translation). Re-run once after the fix; views inspected |

Not run: word audit, vocabulary category check, `check_runtime_resources.gd`,
`check_interaction.gd`, `docs/evidence/part2/verify.gd`, the full suite. No real-input play-test (walking
to Twinkle, pressing E, clicking dishes); no human hands-on play. `game-offer.png` shows the
street (the capture disables the camera follow). Open items (priority: low): the *blando*
(soft) icon is faint on the page; the ingredients poster's fish card shows the existing word's
full text "el pez (animal) / el pescado (comida)" and its text overlaps the picture slightly.

## Police station enlargement and detective games — 6 November 2026

User request: two detective minigames in an enlarged police station
([record](TOWN_DESIGN_BRIEF.md#police-station-enlargement-and-detective-games--6-november-2026)).
Godot 4.7.2. Development used `dev_focus.txt` = `police`; **every result below is from
`all` (full town)**, run once each, with a temporary `override.cfg` pointing `user://` at
`VocabularyTownChecks/isolated` (removed afterwards).

| Check | Result |
| --- | --- |
| `docs/evidence/police-detective-20261106/verify.gd` (new) | **113 checks, 0 failures**: 20 × 22 shell with the front, position, door lane and car unchanged; both room doors registered with their new origins; anchors, two posters, ten shelf exhibits; walkable lobby, lineup and counter spots; evidence room on the left and lineup room on the right seen from the door; both officers on their spots, inside, uniformed, clear of solids; both sessions found their officer. Lineup: 4 rounds, each valid, every suspect built as its data says, a wrong guess, accusing nobody, the right guess, Next and the end. Evidence: 4 rounds, touch, listen (the inset shows the sound), look (close-up), choose, the tool-instruction reminder, drops on wet objects, the end; leaving early asks first and clears the table. The activity board blocks the other police game while one runs |
| `docs/evidence/police-detective-20261106/verify_clues.gd` (new) | 8,000 generated rounds: **77,124 checks, 0 failures** (exactly one answer, distractors overlap the clues, no repeated pair, no impossible looks, answer positions spread, every clue used) |
| `docs/evidence/police-interior-20261028/verify.gd` (updated for the new plan) | **192 checks, 0 failures**. Its first run here failed 1: "root kept: Locker label". That label has hung on its locker door since the 3 Nov 2026 commit, so the check (not rerun since 28 Oct) now finds it there |
| `docs/evidence/police-officer-20261101/verify.gd` (updated: officer inside, two "police officer" roots) | **15 checks, 0 failures** |
| `tools/language_check.gd` | **2,979 checks, 0 failed** (26 Chinese readings added for the new words) |
| `check_runtime_resources.gd` | 413 resources, 0 failures (Godot 3 material remap warnings, as before) |
| `check_compact_layout.gd` | 648 checks, 0 failures |
| `check_interaction.gd` | PASS |
| `check_vocabulary_categories.py` | 91,560 checks, **1 failure: missing interactive word crocodile** (existing) |
| `check_vocabulary_translations.py` | 50 errors, the same list as HEAD's data (missing articles on time words). New *suspect* (*el sospechoso / la sospechosa*) added to the gendered-people allowance like *teacher* |
| `docs/evidence/police-detective-20261106/capture.gd` (new) | Views inspected: exterior, rear, lobby, lineup room, evidence room, plan, posters, both games (wrong and right answers, touch, listen, look). The views found the first build mirrored against the approved plan (fixed: `police_interior.gd` mirrors about the door axis), the evidence camera overridden by the lineup camera's return (fixed), the inset covering the table and the card covering tall suspects' heads (both fixed) |

Not run: `docs/evidence/part2/verify.gd`, the vehicle checks, the full suite, the older restaurant and
police-officer captures (their PNGs show the officer outside and are historical). No
real-input play-test (walking in, clicking with the mouse); picks were exercised through the
session API, and mouse ray picking was not driven by synthetic clicks. Open items (priority:
low): a *dark* paper or fabric on the navy table mat is hard to see; no audio for Escuchar
(by decision).

## Police detective games: real-input fix — 6 November 2026

User report: both police games did not work. Reproduced with a new real-input check,
`docs/evidence/police-detective-20261106/play_input.gd` (graphics; walks up to each officer, aims with the
mouse, presses E, clicks Play, a suspect or Elegir and an object, "¡Es este!", Next, then Esc).
The earlier checks called the session directly and missed all three causes:

1. **Game camera taken back (both games).** Closing the greeting started the officer's
   face-camera zoom-out, whose end made the player's camera current again over the game
   camera; clicks then picked nothing. Fixed in `npc_presence.gd` (the zoom-out only returns
   the view while the face camera still shows) and `police_detective_session.gd` (returns to
   the player's own camera, never the face camera).
2. **Shared dialogue box taken over (second game).** Rocco's goodbye was still "his" when
   Mimi's greeting replaced it; Rocco's session, more than 8 m away, closed the box. Fixed:
   a session acts on the box only while it shows its own line (`shop_order_panel.gd`
   `current_line()`); a stale talk is forgotten, so neither officer gets stuck.
3. **Mimi hard to reach.** The evidence counter top was 1.39 m, hiding the cat below her
   head; clicks on her body hit the counter. Lowered to about 1.04 m (0.8 station units).

Results, `dev_focus.txt` = `all`, isolated user directory: `play_input.gd` **both games pass
through real input** (talk, play, game camera current, pick, right answer, round 2, leave
question; the evidence round's tool instruction reminder shown as designed);
`docs/evidence/police-detective-20261106/verify.gd` **109 checks, 0 failures** (count varies with which
rounds carry a tool instruction); views re-rendered and inspected (lobby: the cat now stands
visible above the counter). Not re-run: the other checks listed above (no change to their
subjects). Other games use the same dialogue pattern, but their NPCs stand far apart;
no change made there (priority: low).

## Police suspect game improvements — 6 November 2026

User request: improve the suspect lineup (subtle heights, polar-bear cream colours, cuter hair,
beard, moustache, nose and shirt, idle life, hover highlight, untested face variety, end word
summary); every suggestion except a ✗ mark after a wrong guess. Design record:
[TOWN_DESIGN_BRIEF](TOWN_DESIGN_BRIEF.md#police-station-enlargement-and-detective-games--6-november-2026)
("Suspect game improvements").

Runs used the environment overrides `VT_FOCUS=all VT_SPAWN=none` (full town, normal spawn)
because `dev_focus.txt` held other in-progress work (`restaurants, police`, `spawn=police`);
isolated user directory through a temporary `override.cfg` (removed afterwards).

| Check | Result |
| --- | --- |
| `docs/evidence/police-detective-20261106/verify_clues.gd` (medium height / nose added; no clue names them) | **77,115 checks, 0 failures** |
| `docs/evidence/police-detective-20261106/verify.gd` (suspects checked by height ÷ width ratio and nose scale; new word-summary checks for both games) | **116 checks, 0 failures**. An earlier run with the dev spawn active failed only "door approach lane is clear": the spawned player and the outside officer stood in the lane |
| `docs/evidence/police-detective-20261106/play_input.gd` (real input) | **Both games pass**: talk, Play, game camera, click a suspect / object, right suspect solved, round 2, leave question; the evidence round began with a tool instruction, so its "¡Es este!" showed the reminder as designed. An earlier run in the same session drew no frames (four identical screenshots) and missed the evidence click; it is not counted |
| `tools/language_check.gd` (three new `police.summary*` phrases) | **PASS, 2,988 checks** |
| Views | `capture.gd` ran once fully (new `lineup-suspects.png`, `lineup-summary.png`); after it the fringe was raised, the nose base enlarged and the hover light made double-sided. A second capture stalled after `exterior.png` (window not drawing) and was not retried, so `lineup-*.png` and `after-lineup.png` show the art before those three fixes; `input-lineup-*.png` from `play_input.gd` show the final art (inspected: fringe above the eyes, readable nose sizes, lit spot under the hovered suspect) |

Not re-run: police-interior, police-officer, runtime resources, compact layout, interaction,
categories, translations (their subjects are unchanged apart from the height-chart numbers,
which the police-interior check does not count). Priority low: re-render the lineup views
with `capture.gd` when the window draws reliably.

### Police games: one click to answer — 8 November 2026

User request: no second click on the card after clicking a suspect. Clicking a suspect (or
keys 1-5), or an object with Elegir, now accuses at once (`police_detective_session.gd`
`choose()`); the "¡Es este!" button is hidden; Enter only moves on after a solved round.
`verify.gd` now answers by choosing; `play_input.gd` no longer clicks "¡Es este!" and reads the
host's `_near` / `line_id` (it still read `_near` from the session after the shared-host move
and failed with a script error before talking). `dev_focus.txt` = `all`, isolated `HOME`:

| Check | Result |
| --- | --- |
| `docs/evidence/police-detective-20261106/verify.gd` | **111 checks, 0 failures** (fewer than before: the separate "choose selects" check went) |
| Then: play again (user request) | After Finish the officer's "well done" line asks "¿Quieres resolver otro caso?" with Yes (`police.play`, starts a new game) / No. `verify.gd` **116 checks, 0 failures** (new: each game ends by asking). Yes → new game not exercised by a check; real input not re-run |
| Then: softer suspect palette (user request) | Hair, facial hair and shirt hex values in `detective_game.json` and `FACIAL_DEFAULT`; the two round hints no longer mention "¡Es este!". Views: three lineup rounds rendered close (`VT_FOCUS=police`, not the full town; scratch script, no project PNGs overwritten), inspected: every colour distinct, red vs pink vs orange and blond vs yellow shirt readable, blond visible on the fur. `verify.gd` not re-run after the colour change (data values only; it checks shapes, not colours) |
| `docs/evidence/police-detective-20261106/play_input.gd` (real input) | Lineup: one click on the right suspect solved the round, button hidden, round 2, leave question. Evidence: the round asked for a tool first, so the click showed the reminder as designed (no solve exercised through real input). `input-lineup-answer.png` inspected. The log also shows a parse error in the uncommitted `warehouse_tasks.gd` (`_gender()`), from separate warehouse work in progress |

### Police evidence game redesign — 8 November 2026

User-approved redesign ([decision](TOWN_DESIGN_BRIEF.md#police-evidence-game-redesign--8-november-2026)):
one property word a round (*duro/blando*, *áspero/liso*, *pesado/ligero*), find and report
rounds, Apretar / Tocar / Levantar examine every object and leave result icons, agreeing answer
lines, tracked practice; poster rebaked (`police.gd` step `evidence_poster_words`,
`tools/bake_unit.gd -- police`, report OK, 1793 nodes). `dev_focus.txt` = `all`, isolated `HOME`:

| Check | Result |
| --- | --- |
| `verify_clues.gd` (no town) | **70,005 checks, 0 failures**: 4,000 evidence rounds (2,000 find / 2,000 report), every clue used 628–683 times, every object kind on tables, find answer positions even; lineup unchanged |
| `run_checks.py` `runtime_resources`, `language`, `vocabulary_report`, `police_interior`, `practice_log` | **PASS** (the report check rewrote `docs/guides/vocabulary-report/` files: evidence property words now "tested") |
| `police_detective` (`verify.gd`) | First run: the updated check had a type error (did not load). Second: **125 checks, 0 failures**, then Godot aborted at exit (`recursive_mutex lock failed`, CRASH); cause: the check left a lambda connected to the practice log's static singleton; disconnected. Third: **PASS**. After the summary and report-icon fixes below: **PASS** (once) |
| `play_input.gd` (real input, windowed) | Evidence: clicking Tocar marked the objects, clicking the rough object solved round 1 ("¡Correcto! Mira: la cuerda es áspera."), Next, round 2 report answered with its button ("Mira: la llave es lisa."), leave question. It logged "Lambda capture … was freed" (a delayed tool step after the round changed): fixed with a tool serial; real input **not re-run** after that fix. It printed 3 badges of 4 after 100 unpaced frames (timing of the capture, the later views show 4) |
| Views `docs/evidence/police-evidence-20261108/capture.gd` (windowed) | First run stalled after two shots waiting for a frame (window likely hidden) and was stopped; second run complete. Inspected: poster (three columns), find round with four icons, wrong-object line, report round, touch and lift icons. Found and fixed: the report round's long object reached toward the camera and its icon hid behind the taller card (object now lies across, icon beside it), and the summary gave dictionary forms (*la piedra: duro*; now agreeing, *la cuerda: ligera*). Third run after the fixes: inspected `report-wrong.png`, `summary.png` |

Not done: Chinese and English rendering only through the language check (no zh/en views);
Spanish and Chinese wording not reviewed by speakers; the full suite was not run. The old
6 Nov evidence views (`docs/evidence/police-detective-20261106/evidence-*.png`) show the old game.

### Police evidence game, second pass (objects, badges, button translations) — 8 November 2026

User request ([decision and object audit](TOWN_DESIGN_BRIEF.md#second-pass-objects-result-badges-button-translations-8-nov-2026)):
card buttons translated with the translate bubble; ten new or remodelled objects (stone,
coconut, frying pan, dumbbell, key, pencil, ball, pillow, sponge, towel) in the product art
style; navy pin result badges; shelf exhibits swapped (`police.gd` step `evidence_shelf_objects`,
`tools/bake_unit.gd -- police`: report OK, 1754 nodes, 2 steps). `dev_focus.txt` = `all`,
isolated `HOME`:

| Check | Result |
| --- | --- |
| `verify_clues.gd` (no town) | **70,005 checks, 0 failures**: 4,000 evidence rounds, clue uses 658–674 each, all ten new kinds on tables (850–1,143 times) |
| `run_checks.py` `runtime_resources`, `language`, `vocabulary_report`, `police_detective`, `police_interior`, `practice_log` | **PASS** (police detective 130 checks: new checks that the shelf exhibits are the game's objects and that tool and answer buttons show their translation with the bubble on and one line with it off). The report rewrote `docs/guides/vocabulary-report/` |
| After the pillow / ball reshape and re-bake: `runtime_resources`, `police_detective`, `police_interior` | **PASS** (police detective 130 checks again) |
| Views `docs/evidence/police-evidence-20261108/models.gd` (no town) and `capture.gd` (windowed) | Model sheet `models.png`, `models-close.png`, `badges.png`. First capture inspected: pins over four objects (find), the report card translated (*áspera / rough*, *Apretar / Squeeze*), lift badge, shelves. Found and fixed: the pillow read as a box with feet and the ball as a dome in a white dish (reshaped; the never-committed police scene restored from git and re-baked); the white shelf pillow vanished against the wall (now blue). Second capture complete (13 views) and inspected: `find-tool` (pins over pillow, ball, pencil, towel), `shelf-evidence` (all ten exhibits). Left: the brass key on the upper shelf sits behind its gold label and is hard to see (low; a steel key there would fix it) |

The first data edit of this pass duplicated the lineup block inside `detective_game.json`
(the duplicate key made Godot read the old evidence objects); found on the first model sheet and
repaired before any check. Not done: zh/en views; speaker review of *la toalla es áspera*; the
full suite; real-input run.

Word removal (user decision, same day): *hand bell, fabric, wooden block, rope, paper* deleted
from `words.json` and added to `removed_with_objects`; grammar question zh-003 changed from
一張紙 to 一張地圖 (*map*); pinyin 塊 removed. `run_checks.py` `language`,
`vocabulary_report` (778 words, 10 unplaced and unused, **0 removed words still placed**),
`vocabulary_categories`, `vocabulary_translations`, `grammar_class`, `runtime_resources`:
**PASS**.

Lineup nose fix (user report, same day): a big nose (×1.9) covered the bear's "w" mouth and the
mouth's top poked out below it as dark lumps. `suspect_builder.gd` now moves the mouth down as
the nose grows. Bare-scene render of small / medium / big noses before and after
(`docs/evidence/police-evidence-20261108/nose-before.png`, `nose-after.png`): clean ovals, mouth visible.
`police_detective`: **PASS**. Not rendered in the station or with a moustache.

### Police lobby rearrangement — 8 November 2026

User request ([decisions](TOWN_DESIGN_BRIEF.md#police-lobby-rearrangement--8-november-2026)):
reception against the right wall, chairs by the entrance, second workstation and *AGENTES* sign
removed, word poster on the side wall, lineup room door (hinged, opens inward) and dark window.
`police.gd` step `lobby_layout`, `tools/bake_unit.gd -- police`: report OK, 1756 nodes, 1 step,
19 doors. The first bake hung on a GDScript parse error (an untyped loop variable); the bake tool
does not quit on a script error, so it was stopped and re-run after the fix.
`dev_focus.txt` = `all`, isolated `HOME`:

| Check | Result |
| --- | --- |
| `run_checks.py` `runtime_resources`, `police_interior`, `police_detective` | **PASS**. `police_interior` updated: removed workstation roots dropped from the kept list; new checks that they and the OFFICERS sign are gone, the lineup room door is a registered working door and solid when closed, the window is tagged *window*, the poster is on the side wall; walkable spots moved for the chairs, the reception customers and the poster |
| Views `docs/evidence/police-lobby-20261108/capture.gd` (windowed; 7 views) | Inspected: entrance, reception against the wall, chairs under the front window, poster on the side wall, lineup door closed and open (swings into the room), view from inside the lineup room through the window. Left (low): from the entrance the hanging RECEPCIÓN sign still overlaps the notice board's front edge; two poster cells (`el pelo / el cabello` and the first) have very small text (unchanged by this pass) |

Not done: real-input walk-through (opening the door with E, the lineup game with the door
closed), full suite.

Follow-up, same day (reception moved out, beagle receptionist on a staff platform, modelled
chairs; step `reception_officer_chairs`). The police scene was restored from git and re-baked
with all four uncommitted steps (report OK, 1771 nodes, 4 steps; one palette file written). The
first view showed the officer hidden to the eyes by the 1.94 m counter; a platform (0.34, then
0.5) fixed it. `police_interior` gained checks: officer present (*police officer*), behind the
desk and facing the lobby; every chair's mesh reaches the floor; no "Chair back" boxes left.

| Check | Result |
| --- | --- |
| `run_checks.py` `runtime_resources`, `police_interior`, `police_detective` on the final scene | **PASS** |
| Views (`capture.gd`, now 11 incl. `reception-officer`, `chairs-close`, `office-chair`, `interview-chairs`) | Inspected: officer's face and cap above the counter, sign clear of the notice board, waiting chairs with legs and armrests, swivel chair, interview chairs. One capture run stalled while the checks ran alongside it (window in the background); it was stopped and run alone |

## Modular town, phases 1 and 2 — 6 November 2026

The saved town became a base world plus one scene per building (user decision; guide:
[MODULAR_TOWN](MODULAR_TOWN.md)). Full suite run once on the old pipeline (commit `73fca2b`)
and once on the modular town, `dev_focus.txt=all`, isolated `HOME`; labels compared, not exit
codes. Two new failures (aircraft wingtip sweep, swan boat movement) were fixed and those two
checks rerun once: every check now has the baseline's failure labels or fewer (police detective
4 → 0, random rounds). Node parity and a 19-view render comparison match apart from moving
animals and characters. Focus `restaurants, police`: 2 of 18 units, windowed first frame 7.1 s
(was about 11 s). Full table, timings and limits:
[verification record](MODULAR_TOWN.md#verification-record). Not done: phase 3 cut-over.

### Boot time follow-up — 6 November 2026

Character sculpts and costumes are cached in `user://sculpt_cache/` and share one shader per
code ([details](MODULAR_TOWN.md#boot-time-follow-up--6-november-2026)). Windowed first frame
with a warm cache: `restaurants, police` 7.1 s → 3.9 s, full town 11.5 s → 5.4 s. Cache off vs
warm character dump identical; `check_plush_costumes.gd` 572/0 (stale `Bedtime` count fixed),
police detective 115/0, seats and swan boats the known 1, runtime resources 419/0, clothing
interior 1 failure of 130 that also occurs with the cache off (not traced, low).

### Modular town phase 3 (cut-over) — 6 November 2026

Buildings now change through their unit scene or their own script + `tools/bake_unit.gd`; the
full bake refuses once a unit has own-script steps; the loader owns loaded nodes by the town.
Round trip of all 18 units with no steps: node dump identical apart from the random customer and
crab positions. Step test (temporary police script): applied once, skipped on a second bake,
loads in place, full bake refused. Police detective 114/0, vehicle doors 138/0. Old pass files
frozen, not deleted (about 25 checks call them). [Record](MODULAR_TOWN.md#phase-3--6-november-2026).

### Old pipeline removal — 6 November 2026

User decision: delete the frozen startup passes and rework or retire the checks that used them.
Deleted 33 pass scripts, 7 legacy tools and 5 old saved worlds (about 47 MB); retired 5 checks and
`migrate_v27_source.py`; reworked 18 checks. Each relevant check run once (full town, isolated
`HOME`): runtime resources 384/0, language PASS 2,988, compact layout 642/0, public garden 0,
park terrain 0 (same figures as before), barn 56/0, police 115/0, 216/0, 15/0; `docs/evidence/part2/verify` the
known 3 garage-drive failures; `check_map_facades` the 1 Nov labels; `check_rooftops` still broken
(28 Oct); six snapshot checks fail on fingerprints changed by later approved work (not traced).
One-building bake round trip: node dump identical. Not run: vehicle, aircraft, hospital, seat and
interaction checks, rendered views. [Record, check review and open items](MODULAR_TOWN.md#old-pipeline-removal--6-november-2026).

### Base world bake — 6 November 2026

`tools/bake_unit.gd -- base` bakes `scenes/town/base.scn` from steps in
`scripts/buildings/base.gd`, including layout data (`baked_layout`: sites, roads, map entries);
`tools/compare_scenes.gd` diffs two saved scenes. Bakes now drop nodes scripts build at runtime,
keep each part's saved `unit_index` and save crabs at their home. No-step round trip of base + 18
units: 18 scenes identical, base only crab `display_size` metas (overwritten at load), hospital
only its saved rotor blur (replaced at load); originals kept. Step test: applied once, skipped on
rebake, loads in the game. Full town, each once: runtime resources 385/0, compact layout 642/0,
`docs/evidence/part2/verify` the known 3 garage-drive failures, public garden 0; focus `chapel` loads with only
the designed staff warnings. [Record](MODULAR_TOWN.md#base-world-bake--6-november-2026).

### Building address book and dead-code sweep — 6 November 2026

Runtime code finds buildings with `modular_town.gd::building(town, unit, part, below)` (null when
dev focus leaves the unit out) instead of literal node paths; node paths unchanged. Removed
uncalled code: most of `warehouse.gd` (kept `build_copy()` and what it needs), `school_posters.gd`,
Main's original neighbourhood builders. Each once, isolated `HOME`, full town: 302 scripts load,
runtime resources 384/0, language PASS 2,988, compact layout 642/0, `docs/evidence/part2/verify` the known 3
garage-drive failures, police detective 115/0, warehouse game 129/0, new
`check_building_lookup.gd` 0 failures on the full town and with `VT_FOCUS=chapel` (no script
errors). Not run: rendered views, rest of the suite.
[Record](MODULAR_TOWN.md#building-address-book-and-dead-code-sweep--6-november-2026).


## Check runner — 6 November 2026

`python3 tools/run_checks.py [quick|full]` runs each check as its own process (isolated `HOME`,
`VT_FOCUS=all`, `VT_SPAWN=none`, `VT_SCULPT_CACHE=0`, `--fixed-fps 60` where needed, per-check
timeout), parses failure labels and compares them with `data/expected_check_failures.json`
(seeded from the records above: part 2's three garage-drive samples, aircraft 4, zoo vehicles 5,
hospital remodel 1, airport seats, vocabulary crocodile / `hair` / 49 article labels, map facades'
four 1 Nov labels, the six snapshot checks as counts, `check_rooftops` marked broken). It reports
PASS / KNOWN / NEW / FIXED / CRASH / TIMEOUT and exits 1 only for NEW, CRASH or TIMEOUT
([usage, adding a check, updating expected failures](../../README.md#verification)). From now on,
compare a run with this file, not by hand.

**Full suite, run once** (tree `25014b6` plus another session's uncommitted
`suspect_builder.gd` and `sculpt_cache.gd` edits; Godot 4.7.2 headless, Apple M5, `dev_focus.txt=all`,
one check at a time, 458 s): **18 PASS, 14 KNOWN, 0 NEW, 0 FIXED, 0 crashed or timed out,
1 skipped** (`check_rooftops`). Every check reproduced its last record: runtime resources 384/0,
language PASS 2,988, compact layout 0, `docs/evidence/part2/verify` 1,304 checks / the 3 garage-drive labels,
public garden 0, interaction pass, aircraft the 4 labels, helicopter 0, zoo vehicles the 5 labels,
road physics 0, hospital remodel `Hospital retains word floor`, hospital departments 0, seats
`airport seats sat on intended seat: 37/39`, vocabulary categories the crocodile key, vocabulary
translations 51 issues (50 printed: `hair` + 49 article labels), park terrain 0, barn 0, police
detective 0/113, interior 0, officer 0, map facades the 4 labels, vehicle boarding 0, doors 0,
building lookup 0/68, warehouse 0, warehouse game 0, snapshot checks 265 / 90 / 29 / 28 / 149 / 71.
Trial runs before it (map facades, zoo vehicles, interaction, vocabulary) also matched; a forced
3 s timeout killed the process group and reported TIMEOUT. No file in `docs/` changed.

Limits: label matching only; the snapshot checks' failures are stored as counts, so a changed
label within the count is not noticed. `check_animals.gd` is left out (writes into `docs/`);
known crab `Fitted picking` failures (P3) are not tracked by the runner. Headless only: no rendered views.

## Police lineup suspects art pass — 7 November 2026

User request: the lineup suspects looked terrible ([what was wrong and what changed](TOWN_DESIGN_BRIEF.md#police-station-enlargement-and-detective-games--6-november-2026)).
Changed: `suspect_builder.gd` (hair, beard, moustache, lashes, part transforms, shirt dressed first),
`sculpt_cache.gd` (typed script variables restored; restored costume pieces ownerless),
`data/detective_game.json` (blond `ecc054`); the eye-blink fix in `police_detective_session.gd`
landed earlier inside commit `25014b6`. Rendered after every pass (police focus, 1280 × 800): game
camera, front row, a close-up of each suspect and a three-quarter view, three fixed lineups covering
every hair, colour, facial hair, nose and height value; before/after sheets
`docs/evidence/police-detective-20261106/suspects-before-after.png` and `suspects-close-before-after.png`.

Checks, each once on the finished change unless stated, isolated `HOME`, `VT_FOCUS=all`,
`VT_SPAWN=none`, `dev_focus.txt` = `all`:

| Check | Result |
| --- | --- |
| `docs/evidence/police-detective-20261106/verify_clues.gd` | 8,000 generated rounds, **77,115 checks, 0 failures** (as before) |
| `docs/evidence/police-detective-20261106/verify.gd` | **114 checks, 0 failures** (count varies with tool-instruction rounds). Run twice: the first run (113 / 0) printed 243 costume "owner inconsistent" warnings (83 at unit load as recorded before, 160 from the now-cached suspect shirts); after the owner fix the second run printed none |
| `docs/evidence/police-detective-20261106/play_input.gd` (graphics, real input) | **Both games pass** (talk, Play, game camera, click a suspect, right answer, round 2, leave question; the evidence round's tool reminder as designed). `input-lineup-*.png` show the new suspects in the full town |
| `docs/evidence/police-detective-20261106/capture.gd` (police focus) | Ran once; kept the four views with suspects (`lineup-game`, `-wrong`, `-right`, `-suspects`), the other views put back unchanged |
| Round build time (headless probe, 4 rounds) | About 75–170 ms per round of five once the shirts are cached (first build of a colour about 0.3 s); the old builder took about 0.35 s every round |

Not run: the rest of the suite. `sculpt_cache.gd` also serves every town character: restored
meshes are unchanged; only the restored variables' types and the pieces' owners differ (both now
as a fresh build), and the full town loaded in `verify.gd` and `play_input.gd` without errors.

### Material palette — 6–7 November 2026

Identical materials in the 19 town scenes are now saved once, as `materials/palette/<hash>.tres`
(1,916 files), by every bake (`tools/material_palette.gd` in `bake_unit.gd`); runtime code must
`duplicate()` a found material before changing it. Re-baked `base` + 18 units once. Stored
StandardMaterial3D objects 2,957 → 14; scene comparison: identical nodes, transforms, metadata and
material content (plus the two predicted base/hospital normalizations); 5 views before/after
identical apart from the random customer and moving objects. Full suite once: 18 PASS, 9 KNOWN,
5 NEW in the snapshot checks; a label diff against a run on the pre-merge scenes showed only extra
`preserved` fingerprints (render culling now merges and hides ~200 more meshes), no walk, pick,
collision or door labels; recorded in `data/expected_check_failures.json`.
[Record](MODULAR_TOWN.md#material-palette-bake--6-november-2026).

## Grammar Classroom — 7 November 2026

Built from the user's brief ([guide](GRAMMAR_CLASS.md), [room record](TOWN_DESIGN_BRIEF.md#grammar-classroom-remodel--6-november-2026)).
Remodel committed first (`9118c00`); renders `docs/evidence/grammar-class-20261106/room-*.png` and `seat-A…D.png`
(seated players face the board; the first bake had the chairs facing the front wall and the
board over two posters, both fixed before that commit). Game renders, one batch per language
(school focus, 1280 × 800, the countdown frozen while rendering): `class-es|zh|en-question`,
`-board`, `-feedback` and `class-en-feedback-top.png` (the green right desk and the filled board).

Checks with isolated `HOME`, `VT_FOCUS=all`, `VT_SPAWN=none`, `dev_focus.txt` = `all`:

| Check | Result |
| --- | --- |
| `docs/evidence/grammar-class-20261106/verify.gd` (runner id `grammar_class`, full suite) | **75 checks, 0 failures** on the final code. Earlier runs found and fixed: the check approached chairs from behind (the seating controller then picks the chair facing the player, as designed; it now steps in from the aisle side); the final score box closed when the player sat more than 9 units from Lana (now only leaving the school closes it during a class) |
| `tools/language_check.gd` (`language`) | PASS, including the new bank rules; the first full run found five characters without pinyin (娜 參 才 秒 滿), added |
| `python3 tools/run_checks.py full`, once, before the last two session fixes (label shadows, green plate) | 18 PASS, 10 KNOWN, 5 NEW, 1 SKIPPED (rooftops). NEW: `language` (fixed above); `building_dimensions` +14 `school noun ray reachable`, `school_exterior` +6 `general classroom opening`, `school_partition` +19 `preserved` (the remodel moved and removed the furniture these October snapshots fingerprint; recorded in `data/expected_check_failures.json`); `cafe_bank_exteriors` +1 `cafe approach and interior spine (144.0, 0.1, 166.0)`, far from the school and not explained by this change, **left as NEW** (P3: look at it on the next full run) |

Found in the renders and fixed: answer-desk tops turned grey because the session cleared the
tops' `material_override` (their wood colour); the green is now a separate runtime plate, so the
top is never touched. Not verified: a real play-through with the mouse and keyboard (the check
drives the session and the seating controller directly); `check_school_partition.gd` now picks
the rear-wall board from the room side.

**Compact dialogue box in class (7 Nov 2026, user request).** The shared dialogue box gets a
compact mode (`shop_order_panel.gd` `set_compact()`, 50 % × ≥ 15 % of the window at the bottom,
text 72 %, buttons unchanged) that `grammar_session.gd` turns on in `start_class()` and off in
`end_class()`. Renders, school focus via `VT_FOCUS=school` (the file stayed `all`), 1280 × 800,
`capture.gd -- dialogue before|after`: `dialogue-keep-going-*` and
`dialogue-final-*` (`before` = the old 80 % × 27 % box over the front desks; `after` = the compact
box, front desks and board visible, Replay / Finish buttons the same size). `grammar_class`:
**77 checks, 0 failures** (two new: compact in class, normal after). Its first run with a
geometry assertion failed because the headless window is not the real size; the geometry
assertion was replaced by the mode check, the renders cover the geometry. Not verified: other
window sizes than 1280 × 800.

**The NEW `cafe_bank_exteriors` label, traced (7 Nov 2026).** Not flaky and not a cafe change:
the failure labels of four full runs (6 Nov check-runner run 28; palette pre-merge 28; palette
post-merge 44 = 28 + 16 `preserved`; after `3d70cea` 45) differ only by
`FAIL: school_words unchanged` in the last run. This snapshot also compares the school's word
set, and the classroom remodel (`9118c00`) added Lana with the word `teacher` (absent from the
October baseline). The runner showed a spine sample as the NEW label because the count-only
`any` entry absorbs the first 28 labels whatever they are. Approved change: recorded in
`data/expected_check_failures.json` as the exact label (no run needed; confirmed by the final
full run below).

## `main.gd` split — 7 November 2026

Last item of the modular-town restructure. `scripts/core/main.gd` 819 → 508 lines; Main stays the
entry point and keeps every public method and field (checks call `game.toggle_vehicle()`,
`game.shop_panel`, ...). Bodies moved, unchanged, into static helpers that take Main:
`scripts/core/minigame_wiring.gd` (shop, cashier and minigame sessions and panels; their Esc
entries, Settings refresh and control lock), `scripts/core/vehicle_controls.gd` (boarding/exits,
zoo and farm gates, Home garage door and roof), `scripts/core/door_animator.gd` (door states and
animation) and `scripts/world/room_names.gd` (`current_room()`; the `language_check.gd` exception
for "Bakery & Café" moved with it). Ownership: [architecture](ARCHITECTURE_REVIEW_PART1.md#architecture-and-ownership).

**Full suite, once** (`run_checks.py full`, `dev_focus.txt=all`, 526 s): 20 PASS, 13 KNOWN,
0 NEW, 0 crashed, 1 skipped (rooftops): every known label as before the split. Caveat: piece-3
check edits of the next section were being written during this run, so `vocabulary_categories`
and `map_facades` already reported FIXED labels; that does not touch the split.

## Leftover Godot files — 7 November 2026

Policy (Claude's recommendation, accepted by the user): the 61 untracked `.uid` files, all of
tracked scripts and resources (checked one by one; 4 are the new `main.gd` helpers), are
committed; `.import` files of documentation images (`BonAdventure/docs/**/*.png.import`,
`*.jpg.import`, 144 untracked) are ignored by the root `.gitignore`. No scene or script loads an
image from `docs/` (searched `res://docs/…png|jpg` in `.gd`, `.tscn`, `.tres`, `.json`; capture
scripts only write PNGs). `.gdignore` was not used: most docs image folders also hold check
scripts Godot must see. Nothing was deleted. Open: 909 older doc-image `.import` files are
still tracked (ignoring does not untrack them); untracking them (`git rm --cached`, files stay
on disk) is a separate decision.

## Known check failures resolved — 7 November 2026

Each entry of `data/expected_check_failures.json` was traced (one targeted run where needed) and
then fixed, refreshed or kept with a traced reason. **Final full suite, once**
(`run_checks.py full`, `dev_focus.txt=all`, after all edits below): **25 PASS, 9 KNOWN, 0 NEW,
0 crashed or timed out, 0 skipped**. Per-check times in that run are not meaningful (21,850 s in
total; the machine slept). Not verified: rendered views (all changes are to checks or data).

| Check | Old label(s) | Decision and reason |
| --- | --- | --- |
| `part2` | `drive clearance Home garage drive 21` ×3 | **Check refreshed.** The Home drive ends at the overhead garage door (`f103d0a`), closed until E opens it; the clearance sweep now excludes the door's bodies. PASS |
| `aircraft` | `airplane vocabulary` | **Check refreshed:** the category is `Vehicles` (was `Transportation`). PASS |
| `aircraft` | `E disembarks after landing`, `walking collision and visible pig restored`, `high-speed wing impact …` | **Check fixed:** E now starts the door / climb-out sequence (`f103d0a`); the check steps it to the end before asserting. The later two followed from the first. PASS (30 checks) |
| `zoo_vehicles` | `gate translation`, `gate vocabulary popup` | **Check refreshed:** the gate word is `el portón` in `words.json`. PASS |
| `zoo_vehicles` | `player is on foot again`, `hyper effects resume after exiting`, `E boards Car` | **Check fixed:** the helicopter exit sequence is stepped to the end; the road-vehicle loop then starts from foot. PASS |
| `hospital_remodel` | `Hospital retains word floor` | **Check refreshed:** the only hospital `floor` word was the rear extension floor (`git show 55f9b83`), removed by the approved three-floor remodel; nothing in `scenes/town/hospital.scn` carries it, home and school still teach it. ~~**Open (P3, user decision):** give the hospital a clickable floor again?~~ **Decided NO (user, 7 Nov 2026):** the hospital gets no floor word back; the home and school teach *floor*. PASS |
| `vocabulary_categories` | `Missing interactive word: crocodile_plush.tscn / crocodile` | **Game fixed (data):** `words.json` gains `crocodile` (el cocodrilo, 鱷魚, Animals). The plush scene already carried the key and every other plush species has its word; Officer Rocco was not a valid word. PASS |
| `vocabulary_translations` | `hair` two options | **Check refreshed:** `el pelo / el cabello` is the user's approved synonym pair (31 Oct 2026, noted in `words.json`); added to the allowed list. PASS |
| `vocabulary_translations` | 49 `missing definite article` | **Check refreshed:** countries, flight statuses and time expressions of the airport game (`ef87fc9`; weekdays as on the departure board) take no article; listed explicitly. PASS |
| `police_detective` | `accusing nobody asks to choose first` ×4 (flaky) | **Entry retired:** 0 failures in six isolated-`HOME` runs since 6 Nov; the 4 came from the old non-isolated baseline. PASS |
| `map_facades` | `seventeen building fronts plus home, gazebo and control tower` | **Check refreshed:** 19 fronts since the control tower revision (user, 29 Oct 2026: discreet entrance, no sign). |
| `map_facades` | `facade additions leave … clearances unchanged` | **Check refreshed:** only the approved Alta Cocina terrace bistro tables under `FINE DINING` may be solid (4 bodies). |
| `map_facades` | `street ray picks new facade FURNITURE` | **Check fixed:** the ray hits `FurnitureStore/FrontRight_13/ExteriorPick`, which shows the same exterior word; the check now accepts what `aimed_object()` would show. |
| `map_facades` | `street ray picks new facade HOSPITAL` | **Kept (traced, game, P3):** the ray hits `Hospital/Floor1/FacadeGlass3/Body` (no exterior word) before the facade. KNOWN 1 |
| `seats_swan_boats` | `airport seats sat on intended seat: 37/39` | **Kept (traced, game, P3):** Pilot Awoo's `FigureBlocker` stands at the front approach of row seats (2.2 / 2.8, −4.38) and pushes the player away, also when stepping in at 0.8 / 0.6 m (tried, reverted). Fix: move Awoo or the seats (airport bake). KNOWN 1. **Fixed later the same day:** [Awoo moved](#pilot-awoo-moved-off-the-waiting-seats--7-november-2026) |
| `cafe_bank_exteriors` | `school_words unchanged` (7 Nov) | **Refreshed** earlier today: Lana's `teacher` word (section above). |
| six snapshot checks | counts 279 / 101 / 30 / 45 / 157 / 111 | **Retired later the same day (user decision), see [below](#snapshot-checks-retired--7-november-2026).** Was: **kept, decision pending (user):** October fingerprint and walk-line snapshots that every approved change invalidates. Recommendation: retire them or re-record their baselines (`--record-baseline` rewrites `baseline.json`). KNOWN |
| `rooftops` | broken (hung on `HouseStructure/HomeRoof`) | **Check reworked:** the deleted Home roof slopes and samples removed, missing nodes fail instead of stopping the script, helicopter parts renamed (`PilotWindowLeft`, `MainWheelLeft/Right`); back in the full suite. 262 checks, 18 failures, KNOWN: 16 `Solid surface above` (decorative roofs and canopies without collision: new Home roof, eaves, hospital and terminal canopies, Alta Cocina hip roofs, chapel / gazebo caps, play tower roofs, police roof; the October record already had 17 roof failures) and 2 `Walkable normal above` (the steeper barn gambrel the user approved). **Open (P3, design):** which roofs should be walkable (settled the same day: all solid, [record](#decorative-roofs-made-solid--7-november-2026)). Jump progression and helipad landing pass |

## Display modes: Both removed, Native mode checkbox — 7 November 2026

Stage 0 of the vocabulary tracking work (user decisions, 7 Nov 2026; [guide](ARCHITECTURE_REVIEW_PART1.md#shared-dialogue-popups-and-settings--4-november-2026)).
Both, the L key and the HUD mode button are gone; Native mode is the Settings checkbox
"Show everything in my language" (off by default); a saved `display` 2 loads as Foreign.

| Check | Result |
| --- | --- |
| `docs/evidence/display-mode-20261107/capture.gd` (graphics, `VT_FOCUS=hospital`, isolated `HOME`, 1600 × 1000) | **8 checks, 0 failures** (saved Both loads as Foreign, Foreign by default, no HUD button or cycle, L does nothing, checkbox off by default, turns Native on and is saved, `set_native(false)`). Renders inspected: `settings-off.png`, `settings-on.png`, `family-native.png`, `family-foreign.png` (bubble only in Foreign), `help.png` (no L row; the family farewell box overlaps it, a capture artefact) |
| `python3 tools/run_checks.py full`, once, `dev_focus.txt` = `all` | **25 PASS, 9 KNOWN, 0 NEW** (same labels as `847b383`); `interaction` now switches the card through `GameSettings.set_native` |

Not verified: clicking the checkbox with a real mouse (the capture emits `toggled`).
`docs/evidence/ui-settings-20261104/verify_town.gd` and `capture.gd` use the removed mode and no longer compile (historical).

## Vocabulary usage report — 7 November 2026

Stage A of the vocabulary tracking work ([guide](ARCHITECTURE_REVIEW_PART1.md#vocabulary-usage-report),
[result](vocabulary-report/summary.md)). Developer tool only, no game change; replaces `docs/word_audit.gd`.

| Check | Result |
| --- | --- |
| `tools/vocabulary_report.gd -- --write` (headless, isolated `HOME`, `VT_FOCUS=all`), final code | **5016 checks, 0 failures**: no unknown key in game data, scenes, labels, aliases, phrase slots or the clickable index. 781 words; 777 placed in saved scenes, 2 only at runtime (`tree`, `crocodile`), 778 clickable; **2 placed nowhere and used by no game: `base` (Building Parts), `nurse` (People)**; `crocodile` placed but not clickable; 0 duplicate groups; 0 `removed_with_objects` words still placed. 158 words tested: shop 80, restaurant 38, family 19, grammar (zh) 16, flight 12, warehouse 3 |
| `python3 tools/run_checks.py full`, once, `dev_focus.txt` = `all` | **26 PASS, 9 KNOWN, 0 NEW** (the 25 + 9 labels of `ded0a83` plus `vocabulary_report` PASS). That run used the report before the clickable column and singular/plural groups were added; the final code's check result is the row above |

Not verified: the FAIL path with a deliberately unknown key (no data was broken to test it).
Dialogue words written as plain text are not reported (by design).

## Practice tracker — 7 November 2026

Stage B of the vocabulary tracking work ([guide](ARCHITECTURE_REVIEW_PART1.md#practice-tracker)).
Commits: `f96eb11` tracker + shop + family, `9d07acd` restaurant, `6345a1f` warehouse,
`0241a4f` flight countries, `f889cbb` grammar Chinese nouns. Police games deliberately untracked.

| Check | Result |
| --- | --- |
| `docs/evidence/practice-log-20261107/verify.gd` (runner id `practice_log`; isolated `HOME`, whole town) | **80 checks, 0 failures** in the full run (the count varies with how many untracked family / flight / warehouse questions come up first). Every grocery row (first try right, wrong then right, translate then right, wrong then translate, many toggles, translate after completion, abandoned), Native mode at the start and mid-question, a language change, several words, the saved file; then each game in the town with a wrong-first row, a bubble row and leaving |
| Targeted runs per commit | quick suite + `interaction` PASS (tracker commit); `warehouse`, `warehouse_game` PASS; `grammar_class` PASS; `vocabulary_report` regenerated (5016 checks, 0 failures; game id `grammar_lana`) |
| `python3 tools/run_checks.py full`, once, `dev_focus.txt` = `all` | **27 PASS, 9 KNOWN, 0 NEW** (the Stage A labels plus `practice_log` PASS) |

Not verified: real mouse play-throughs (the check calls the sessions' handlers and the
panels' `toggle_translation()`); the word card path is exercised only through the tracker's
signal, not by clicking an object during a question.

## Snapshot checks retired — 7 November 2026

User decision (7 Nov 2026): the six October snapshot checks (`check_building_dimensions`,
`check_school_exterior`, `check_supermarket_exterior`, `check_cafe_bank_exteriors`,
`check_market_interior`, `check_school_partition`) and their `baseline.json` files are deleted;
their dated folders (renders, logs) stay. Each one compared stored fingerprints of every site,
facade, collision shape and word root, so every approved change since (restaurants, police,
school move, Grammar Classroom, palette) failed them (KNOWN 279 / 101 / 30 / 45 / 157 / 111).

What they guarded and where it is checked now:

| Guarded | Now |
| --- | --- |
| Other buildings' and sites' appearance and collision unchanged (fingerprints) | Not checked by a frozen snapshot any more (by design): changes go through unit bakes and renders |
| Facades add no solid obstacles, stay in their envelope | `map_facades` (solid bodies under facades; fronts and street picks) |
| Classroom layout, chairs, board | `grammar_class` |
| Door registry (count) | **`building_access`**: every saved `door_state` of the loaded town is registered, none freed (18 / 18) |
| Approved school 24 × 18 single story 4.6 m, supermarket 26 × 26 envelope and clear height | **`building_access`** (school front/axis updated for the approved 5 Nov 10-unit move: floor corner (−2, −0.2, 221)) |
| Real-capsule walk lines | **`building_access`**: school parking → entrance → open front half, front crossing, both rear side accesses (axis x = 10); supermarket approach, entrance spine, both cross aisles, both connecting aisles, fresh counters; café approach and interior to the front counter; bank approach and lobby. Old lines that now end in approved fittings were shortened (school rear divider at z 230, café front counter at x 142); the old checkout line runs into `Checkout counter2` and was dropped |
| School and supermarket words pickable with the real controller; market dictionary cards | **`building_access`**: 37 school words, 110 market words inside the shell, each picked from some clear spot within 3.5 m; card opens for every non-character market word (characters open their dialogue). Front windows, sign and mat sit under the `SUPERMARKET` map facade, which shows the exterior word (`map_facades`) |
| Market foundation on the ground, divider endpoints, fixtures inside the shell | Not kept (static geometry, unchanged since the bakes; renders) |

| Check | Result |
| --- | --- |
| `run_checks.py --only building_access` (`dev_focus.txt` = `all`, isolated `HOME`) | **PASS: 622 checks, 0 failures** (10 s) |

## Decorative roofs made solid — 7 November 2026

User decision (7 Nov 2026): the 16 roofs and canopies that `check_rooftops` reported as
`Solid surface above` get collision only. Steps `solid_roofs` in the own scripts of home,
playground, police, airport, hospital, restaurants, chapel and base (new: `home.gd`,
`playground.gd`, `airport.gd`, `hospital.gd`, `restaurants.gd`, `chapel.gd`), all calling
`scripts/buildings/roof_solids.gd`: a `StaticBody3D` "RoofSolid" (layer 1) under each roof mesh,
a box for box meshes, a two-sided trimesh of the surface otherwise (the rule of the deleted
`rooftop_collisions.gd` pass). The control tower's faceted cap is a frustum open at its 0.5 m apex
(the mast passes through) standing on the cabin top slab, so it gets a filled convex shape.
One bake (`bake_unit.gd -- base home playground police airport hospital restaurants chapel`, then
airport alone for the tower cap); a node diff of each saved scene against its copy from before
shows only the 16 `RoofSolid` + `Collision` pairs added and `applied_steps` changed.

Side effect fixed: the Home roof hid itself whenever the learner was inside its footprint below
7.6 m, so it vanished under her once she could stand on it. `vehicle_controls.gd::update_home()`
now hides it only below the roof base (home-local y < 3.9; the walls end at 4.0).

`check_map_facades` now allows `RoofSolid` bodies under the map facades if their lowest point is
at least 2.4 m above the town floor (new label "roof and canopy collision stays above head height").

| Check | Result |
| --- | --- |
| `run_checks.py --only rooftops` | **KNOWN, 342 checks, 3 failures** (was 262 / 18): `Walkable normal above Barn roof lining Barn interior` and `… MainRoof Barn` (approved steep gambrel, kept) and new `Walkable normal above Faceted roof cap CHAPEL`: the solid spire cap is steeper (normal 0.40) than 0.7 by design; the landing and jump checks on it pass. Recorded as known. 50 roof landings and jumps |
| `run_checks.py --only map_facades` | **KNOWN 1** (the traced HOSPITAL street ray, unchanged); the head-height rule passes |
| Renders (graphical, `VT_FOCUS` = home, playground, police, hospital, airport, restaurants, chapel; isolated `HOME`; BonBon dropped onto each roof with the real player physics) | BonBon stands on the Home roof (it stays visible after the fix), a play tower roof, the police roof, the control tower cap, the terminal and hospital canopies, the Alta Cocina dining roof and the gazebo cap; on the chapel she slides off the spire onto the chapel roof. [Home](../evidence/roof-solids-20261107/home.png), [play tower](../evidence/roof-solids-20261107/play-tower.png), [tower cap](../evidence/roof-solids-20261107/tower-cap.png), [hospital canopy](../evidence/roof-solids-20261107/hospital-canopy.png), [gazebo](../evidence/roof-solids-20261107/gazebo.png). Roofs look as before (no mesh changed) |

Not verified by hand: walking about on the roofs in play. The render run printed parse errors
from `flight_schedule.gd`, which another session was editing at the time (not part of this work).

## Pilot Awoo moved off the waiting seats — 7 November 2026

User decision (7 Nov 2026). Pilot Awoo sat across the front of seats 2.2 and 2.8 of the middle
waiting row (terminal-local z −4.38); her `FigureBlocker` pushed the learner away from both.
Airport step `move_pilot_awoo` (`scripts/buildings/airport.gd`, baked; node diff: only her
transform changed) moves her 1.9 units toward the information desk to the open floor at the
row's end (x 0.3, z −3.95), same facing, pose, outfit and word `pilot`, lowered 0.48 so she sits
on the floor instead of the seat edge. The walk from the entrance to Captain Bruno's desk stays open.

| Check | Result |
| --- | --- |
| `run_checks.py --only seats_swan_boats` | **PASS**, `airport seats sat on intended seat: 39/39` (was 37/39; expected-failure entry removed) |
| Renders (graphical, `VT_FOCUS=airport`, isolated `HOME`, terminal ceiling hidden) | [before](../evidence/awoo-seats-20261107/before.png), [after](../evidence/awoo-seats-20261107/after.png), [after, from above](../evidence/awoo-seats-20261107/after-top.png): seated, outfit and cap unchanged, middle row free |

## Doc-image import files untracked — 7 November 2026

User decision: the 908 older `.png.import` / `.jpg.import` files under `docs/` that were still in
git are no longer tracked (`git rm --cached`; the files stay on disk). The ignore rule of
`2ac312b` (`.gitignore`) covers them from now on; nothing in the game loads them.

## Airport flight game: board-only redesign for time expressions — 7 November 2026

User decisions (7 Nov 2026; [design record](TOWN_DESIGN_BRIEF.md#board-only-redesign-time-expressions--7-november-2026)):
the flight game now tests time expressions. Board only (anteayer…pasado mañana, 12 flights,
3 per country with a shared tense), 4 countries (United States, France, Brazil, Mexico) shown
as flag + airport code, no status column, the day column hidden for weekday questions; kinds
day, part, clock, weekday, hours; every question has one matching flight, at least 2 decoys with
its country and tense, and a near miss; wrong picks are explained by the tested expression; the
practice tracker records the time word and the named country. The 5 Nov `verify.gd` and
`capture.gd` of `docs/evidence/flight-game-20261105/` were removed (they tested the booklet); their
PNGs stay as historical evidence (the deletion landed early, by accident, in `3b403ec`). `dev_focus.txt` read `all`.

| Check | Result |
| --- | --- |
| `run_checks.py --only practice_log,flight_logic,vocabulary_report` | **PASS ×3**: practice log 86 checks (flight rows: near miss first → time word negative, country positive; other country and time first → both negative; right first → both positive; bubble → both translated); `flight_logic` (new runner check, `docs/evidence/flight-board-20261107/verify.gd`) 10 checks over 600 random todays and nows: every kind askable in every schedule, every 5-question session found, all questions valid, explanations and text in es/en/zh; vocabulary report 5014 checks |
| `run_checks.py full` (after `f2da0ed`, working tree with this change, once) | **30 PASS, 2 KNOWN, 0 NEW** (554 s): KNOWN `map_facades` 1 (traced HOSPITAL street ray) and `rooftops` 3 (barn gambrel ×2, chapel spire cap), both recorded; `flight_logic` and `practice_log` PASS |
| `tools/vocabulary_report.gd -- --write` | regenerated: `flight_bruno` tests 22 words (4 countries, 5 day words, 4 part-of-day words, 7 weekdays, *hace / dentro de una hora*), shows 0; 168 words tested by a game (was 158) |
| Renders (graphical, `VT_FOCUS=airport`, isolated `HOME`, today Thu 03/12/2026 14:30; `docs/evidence/flight-board-20261107/capture.gd`) | [es question](../evidence/flight-board-20261107/es-question.png), [es wrong + explanation](../evidence/flight-board-20261107/es-wrong.png), [es weekday, no day column](../evidence/flight-board-20261107/es-weekday.png), [es summary](../evidence/flight-board-20261107/es-summary.png), [en question](../evidence/flight-board-20261107/en-question.png), [zh with translation](../evidence/flight-board-20261107/zh-question.png), [browse](../evidence/flight-board-20261107/browse.png). Flags and codes read clearly; with the feedback and explanation lines shown, 11 of 12 rows fit and the board scrolls (as before); Chinese with translation shows about 6 rows and scrolls |

Not changed (and noted for later): the countries poster in the terminal still shows 12 flags and
the 3D booklet prop stays on the desk (E opens the board); both are saved in the airport unit.
Not verified by hand: playing the game with the mouse.

## Grammar Classroom seat choice from behind a chair — 7 November 2026

User request: E pressed from behind an answer chair picked the chair in the row behind (whose open
side faced the player's back). `seating_controller.gd::nearest_seat()` added +3 to every seat whose
back faces the player; it now skips that penalty when the player faces the seat (within about 45°,
facing = `-basis.z`). Facing away keeps the old choice; aimed furniture, `sit_priority`, reach and
sight lines are unchanged.

| Check | Result |
| --- | --- |
| `grammar_class` (new case: 0.7 behind chairs A and C, facing the board, E) | **PASS, 79 checks** (was 75 + 2 new labels and their stand-ups); with the old scoring line the two new labels FAIL (run once to confirm the case) |
| `seats_swan_boats`, `practice_log` | **PASS** (airport 39/39) |
| `docs/evidence/town-checks/check_sitting.gd` (not in the suite; read-only, isolated `HOME`) | **370 checks, 0 failures, 328 seats** |

Not run: `docs/evidence/hospital-walls-seating-20261031/verify.gd` (writes PNGs into `docs/`). Not verified with a
real keyboard in play.

### Full suite after the seven follow-ups — 7 November 2026

`python3 tools/run_checks.py full`, once, `dev_focus.txt` = `all`, after `4f75335`: **30 PASS,
2 KNOWN, 0 NEW, 0 crashed or timed out** (499 s). KNOWN: `map_facades` (the traced HOSPITAL street
ray) and `rooftops` (barn gambrel ×2, chapel spire). Fixed since the 27 PASS / 9 KNOWN record:
`seats_swan_boats`; the six snapshot checks are replaced by `building_access` (PASS). The working
tree also held another session's uncommitted flight-game edits, including its new `flight_logic`
check (PASS), so this run covered them too.

## Vocabulary book (journal table) — 8 November 2026

Stage C of the vocabulary tracking work ([guide](ARCHITECTURE_REVIEW_PART1.md#vocabulary-book)):
the J journal lists every word with ★, studied, right and wrong, filters, Show / Hide scores and a
per-game detail view, read from the practice tracker.

| Check | Result |
| --- | --- |
| `vocabulary_book` (new; seeded es and zh test save in an isolated `HOME`) | **PASS, 76 checks** (with graphics, `VT_FOCUS=home`, 1600 × 1000: 76 / 0 and 8 PNGs in `docs/evidence/vocabulary-book-20261108/`, inspected). 781 words: rebuild 3.5 ms, scroll step 0.3 ms; about 20 row controls |
| `python3 tools/run_checks.py full`, once, `dev_focus.txt` = `all` | **31 PASS, 2 KNOWN, 0 NEW** (503 s). KNOWN as before: `map_facades`, `rooftops` |

Stale, not in the suite: `docs/evidence/town-checks/check_area_journal.gd` and `docs/evidence/language-ui-20261104/verify_town.gd`
read the removed `journal_list` (they were already stale: `game.quests`, `hud.mode_name`). Not
verified: a real mouse and keyboard in play (clicks were emitted as signals), an OptionButton menu
open on screen, windows smaller than 1100 × 800.

## Warehouse goods resize — 8 November 2026

Minigame copy only ([guide](WAREHOUSE.md#goods-resize-8-nov-2026)): three fixed box sizes in six
colours, the trolley-only big box, a suitcase and a barrel instead of the bottle, wide low
containers, bigger tables, scale, racks, trolleys and bays. `dev_focus.txt` = `all`.

| Check | Result |
| --- | --- |
| Baseline before the change: `warehouse_game` | PASS, 132 checks |
| `warehouse_game` (`verify_game.gd`, updated: 10 goods, box mix and fixed lengths, no bottle, big box trolley-only and rides its trolley with a rider, *on top of* the big box, *¿Qué hay encima de …?*) | **PASS, 215 checks** on the final version (the count varies with the random arrangement). Runs during the work failed on the check's own placements and draws, each fixed in the check: a borrowed box taken from its container, a put-down onto an earlier task's leftover, and a comparison drawn every round instead of a plain *measure* (1 run in 6 before the fix; the check now redraws) |
| `warehouse` (`verify.gd`, town building) | PASS, 44 checks |
| `language` (`tools/language_check.gd`) | PASS, 3167 checks, after adding readings for 型 and 搬 |
| Pig size (`docs/evidence/warehouse-20261108/measure_pig.gd`) | 2.23 m tall, 1.42 wide in the world (1.71 × 1.10 hall units) |
| Views (`docs/evidence/warehouse-20261108/capture.gd`, 1400 × 900) | 7 PNGs, inspected |

Not run: the full suite, `tools/vocabulary_report.gd` (it now finds *suitcase* and *barrel* and no
longer *bottle* among the warehouse game's words). Not verified: real keyboard play with the new
sizes (reach to the top shelf, carrying the medium box in view), and the too-heavy toast on screen.


## Talk camera, dialogue look and shared minigame helpers — 8 November 2026

Changes: the talk camera (18° above the face, avoids walls, hides the player in the shot), the
dialogue box, choice buttons and quit card restyled
([record](ARCHITECTURE_REVIEW_PART1.md#shared-dialogue-popups-and-settings--4-november-2026));
the shared NPC host `minigame_host.gd` and in-world zone `minigame_zone.gd`
([guide](MINIGAMES.md#building-a-minigame)), with the family, flight, restaurant, both police and
grammar sessions moved onto them. Shop, cashier and warehouse are unchanged (the warehouse was
being edited by another session at the time).

- `docs/evidence/talk-camera-20261108/capture.gd` (graphics, 1600 × 1000): 16 talk views of the 8 minigame
  NPCs from the front and the side, plus the quit card; `TALK CAMERA: 0 failures` (the player's
  model hidden in all 16 and shown again after). Before/after PNGs in that folder.
- Runner, before the helpers: runtime_resources, grammar_class, warehouse_game, police_detective,
  flight_logic, practice_log — 6 PASS. After the helpers: runtime_resources, interaction,
  grammar_class, police_detective, police_officer, flight_logic, practice_log, vocabulary_book —
  8 PASS; police_detective and grammar_class again after the ✕ fix below — PASS.
- Not in the runner: `docs/evidence/activities-20261104/verify_town.gd` 30 checks, 0 failures;
  `docs/evidence/family-game-20261104/verify_town.gd` 40 checks, 1 failure, **"legend and today"**: the check
  expects the fixed date 11/04/2026, but "today" is random per launch since `game_clock.gd`
  (5 Nov 2026). Stale check, not a game fault (P3: compare with `GameClock.shared().today`).
  Its first run also caught a host bug (✕ on the goodbye did not hide the box), fixed before the
  re-run.

Not run: the full suite. Not verified: real mouse and keyboard play of each game on the
helpers, and a long Chinese line in the smaller dialogue box.

Second round, same day (user: bigger suitcase and barrel, no yellow conveyor parts, wall bays on
the left wall only, better-looking goods): `warehouse_game` **PASS, 220 checks**, with new checks
for the one-sided bays, the conveyor motor colour and the enlarged sizes. Views: `docs/evidence/warehouse-20261108/capture.gd`
first stalled at its first screenshot (Godot idle, the window not drawn); with
`RenderingServer.force_draw()` per view it finished, and the 9 PNGs were inspected (bays on the
left wall, a grey conveyor motor, the new carton, suitcase and barrel details). Two camera spots
were moved after the first pass (the pig stood in a container; the trolley hid the goods row).

Third round, same day (user: a 10-task session; at the end Ramón asks to help again, Yes / No,
instead of only saying goodbye): `data/activities.json` progress 10, `warehouse.intro` says ten
tasks, `warehouse.complete` ends with the question, `end_game()` offers Yes (`warehouse.play`) /
No (`common.reply_no`). `warehouse_game` **PASS, 224 checks, 0 failures** (new: a finished game
asks again; Yes starts a new game from 0; No says goodbye); `language_check` **PASS, 3167**.
Not rendered (dialogue text and choices only); not played by hand.

Fourth round, same day ([task plan](WAREHOUSE.md#task-plan-8-nov-2026): rack C out and the
containers in its place, ten tasks planned and validated before the game with backups, no
mistake for a wrong put-down, settled placement, two-level hints from the card and Ramón, E
on the doors / loading gate asks to leave, task card review, *brown* / *medium* as words).
`dev_focus.txt` = `all`. Checks, each run once on the finished change unless noted:
- `warehouse_game` (`docs/evidence/warehouse-20261105/verify_game.gd`): first run **PASS, 260 checks**;
  after adding the place limit (the first render's plan used one reference three times) a
  second run **PASS, 252 checks, 0 failures** (the count varies with the random variant
  loops). New checks: racks A/B only; containers at the old rack C spot; 10 planned tasks with
  no problems; the plan replays; no thing or place in more than 2 of 10; no thing twice in a
  row; all planned sentences and both hint levels render in es/en/zh without the old opener;
  30 more plans for the same arrangement all valid and 28+ different; a done task is replaced
  by a valid backup (writer and session); practice words (thing, size, colour; colour
  question); *brown* / *medium* in `words.json`; a wrong put-down gives no message and no
  penalty; card ? → level 1, Ramón's *¿Me das una pista?* → level 2 (marker on the thing), then
  the place once carried; a momentary placement and an unsettled one do not count, a settled
  one does; marker and hint level reset; E at the hall door and the loading gate asks, *No*
  keeps progress; carrying, E at the gate puts down without asking.
- town `warehouse` (`docs/evidence/warehouse-20261105/verify.gd`): **PASS, 44 checks** (baked town
  unchanged).
- `language_check`: **PASS, 3245 checks** (after adding pinyin for 者 and 附).
- `vocabulary_report -- --write`: **PASS, 5029 checks**; `report.csv` and `summary.md`
  refreshed: 783 words, `warehouse_ramon` tests 16 words (was 3); *brown* and *medium* are
  flagged `unplaced` (no object in town).
- Renders (`docs/evidence/warehouse-20261108/capture_round3.gd`, 5 PNGs, inspected): task card with ?
  and exit buttons, no duplicate count; containers where rack C was; hint 1 text; hint 2
  green marker; leave question at the loading gate.

Not run: the full suite. Not verified: hands-on play with real mouse and keyboard (aiming E at
a door, the feel of hints), the vocabulary book screen itself (it lists every `words.json`
word), a speaker's check of the new Spanish and Chinese lines.

Fifth round, same day ([boxes only, totes, click](WAREHOUSE.md#boxes-only-tote-containers-and-click-to-use-8-nov-2026)).
`dev_focus.txt` = `all`. Each check run once on the finished change:
- `warehouse_game`: **PASS, 256 checks, 0 failures**. Changed: box mix 1 big / 4 medium /
  3 small in 8 colours, no package. New: a left click (an `InputEventMouseButton` through
  `main.gd`) picks the suitcase up and puts it down where clicked, with no word card.
- `language_check`: **FAIL, 3329 checks, 1 failed**: no reading for 港, from the airport board
  tabs (`tab_departures` / `tab_arrivals`, another session's uncommitted flight work), not from
  this change.
- `vocabulary_report -- --write`: **PASS, 5029 checks**; *package* is no longer tested by
  `warehouse_ramon` (15 words). The refreshed files also reflect the other session's
  uncommitted flight and word changes in the working tree.
- Renders (`docs/evidence/warehouse-20261108/capture_round4.gd`, 5 PNGs, inspected): rims and dark
  insides make both containers read as open bins; eight boxes in distinct colours; arrows on
  the medium boxes' ends. The pig hides part of the close views.

Not run: the town `warehouse` check (the baked town is unchanged), the full suite. Not
verified: hands-on clicking with a real mouse.

Sixth round, same day ([fifth round](WAREHOUSE.md#fifth-round-bigger-goods-two-verb-tasks-pushing-the-upright-ruler-8-nov-2026)).
`dev_focus.txt` = `all`.
- `warehouse_game`: first run **FAIL, 277 checks, 3 failures**: a give-me thing put down on
  top of an earlier one in front of Ramón did not count (fixed: anything standing there
  counts), and the old "talking while carrying hands it over" flow (replaced by the second
  verb; the check now puts it down in front of him). Second run after the fixes **PASS, 276
  checks, 0 failures**. New: weights within their size's range; big box fits the deck,
  medium fits a shelf; two verbs for lift / pick up / look for / find / bring / give in es;
  weight comparison of one size; the upright ruler reads 66 cm for a medium box; no word card
  in the game; Ramón's *¡Bien! Ahora …* on pick-up; walking into a trolley rolls it slowly;
  the goodbye closes after walking 4 m.
- `language_check`: **PASS, 3332 checks**.
- `vocabulary_report -- --write`: **PASS, 4996 checks** (files unchanged by this round).
- Renders (`docs/evidence/warehouse-20261108/capture_round5.gd`, 4 PNGs, inspected): larger goods; the
  ruler with its 66 cm screen (the pig hides the box); the two-verb card; Ramón's next-step line.

Then, for the two shared changes (no word cards in a minigame; the walk-off close of the
shared dialogue box), once each with `python3 tools/run_checks.py --only interaction,part2,
compact_layout,police_detective,grammar_class,flight_logic,practice_log`: **PASS 7 of 7**
(0 failures, 80 s). These do not test the walk-off close in the other games themselves (only
`warehouse_game` does). Not run: the town `warehouse` check, the full suite.

Then the praise moved onto the task card and the *find* tail was dropped: `warehouse_game`
first run **FAIL, 277 checks, 2 failures** (the check put a give-me thing down while the card
still praised, when no task is watched; it now waits for the praise first), second run
**PASS, 277 checks, 0 failures** (new: praised on the card with no box below; the next task
after the praise). `language_check` **PASS, 3332 checks**. Renders (`capture_round6.gd`, 2
PNGs, inspected): green praise line on the card; the next find task without the tail. Not verified by hand: the feel of pushing (physics only checked through the trolley
roll), clicking far put-downs with a real mouse.


## Supermarket product art — 8 November 2026

Change: every grocery product redrawn with the shared model library, plus fridge backs, shelf
price tags and department pictograms ([design record](TOWN_DESIGN_BRIEF.md#supermarket-product-art--8-november-2026)).
Baked with `tools/bake_unit.gd -- supermarket` (steps `product_models`: 195 groups, 1,798 units;
`fixture_finish`: 2 fridge backs, 3 gondolas, 5 pictograms). `dev_focus.txt` = `all` throughout
(renders used `VT_FOCUS=supermarket`).

| Check | Result |
| --- | --- |
| `docs/evidence/supermarket-20261102/verify.gd` (words, picking, colliders, fixtures of the store) | **0 failures, 538 checks** |
| Runner: runtime_resources, language, compact_layout, part2, public_garden, building_access (market word picks), interaction | **7 PASS** |
| `docs/evidence/supermarket-visual-20261108/stats.gd`, before and after | Same 111 words, 280 word roots, 299 pick bodies; meshes 5,795 → about 2,380; static batches 608 → 524 (supermarket focus) |
| `tools/compare_scenes.gd`, two bakes of the final steps | 3,947 vs 3,947 nodes, 0 differences (the bake is deterministic) |
| Renders: `capture.gd` (14 views, before and after) and `models.gd` (5 model sheets) | Inspected. Three rounds of fixes came from them: blue-grey sheen on dark satin frosting (now matte, satin roughness .5), blotchy peaches, odd soap wrapper, small pictograms and a clock-like steak icon (now a drumstick) |

Not run: the full suite, the customer-order and cashier checks (the product word roots and pick
areas they use are unchanged, and `verify.gd` picks every product). Not verified: a web export
(no export exists yet), frame time in play, and the hover highlight on the new meshes in a live
session (the controller overlays any `MeshInstance3D`, as before).

Found on the way (P3, stale guidance, fixed in [MODULAR_TOWN](MODULAR_TOWN.md#material-palette)):
the palette-pruning `grep` recipe cannot see palette paths, because the unit scenes are saved
compressed (`RSCC`); it reported every palette file unused. Use `ResourceLoader.get_dependencies()`.

### Second batch: carts, checkout props, seafood ice, café reuse, cart pictures — 8 November 2026

Change: [design record](TOWN_DESIGN_BRIEF.md#supermarket-product-art--8-november-2026) (second batch).
Supermarket rebaked from the committed scene with all four steps (`product_models` 195 groups /
1,798 units, `fixture_finish`, `checkout_props` 29 roots, `seafood_ice` 2 slabs); bakery baked
with its new own script (`shop_products`: 20 drinks, 3 loaves). The new fittings draw about
22,500 vertices (two carts 2 × 2,826, eight casters 8 × 232, two basket stacks 2 × 2,820, the
rest under 1,200 each) and the ice 17,300, against about 460,000 for the products.
`dev_focus.txt` = `all` throughout (renders used `VT_FOCUS=supermarket` / `bakery`).

| Check | Result |
| --- | --- |
| `docs/evidence/supermarket-20261102/verify.gd` (words, picking, colliders, fixtures) | **0 failures, 538 checks** |
| `docs/evidence/customer-order-20261103/verify_town.gd` (order flow with the changed panel) | **20 checks, 0 failures** |
| Runner: runtime_resources, language, compact_layout, part2, public_garden, interaction, building_access | **7 PASS** |
| Renders: `capture.gd -- props` (lane 1, lane 2, baskets, cash tray, carts, seafood), `bakery_views.gd`, `cart_pictures.gd`, plus a model sheet without the town | Inspected; fixes from them: ice too white (darker tones, finer grid, less jitter), washed-out banknotes, raised basket handles |

Not run: the full suite, the bakery's own checks (the café word roots keep their pick areas; only
meshes changed), a web export, and hovering the new models in a live session. Product pictures
are drawn by a `SubViewport` at runtime: checked in a windowed render only; headless runs skip
them by design. The cart-picture render prints its "CART PICTURES" line after the shot, and that
line did not appear in the log although the picture was written (not investigated, P3).

## Airport flight game: calendar, clock, 12-hour times and play again — 8 November 2026

Change: [design record](TOWN_DESIGN_BRIEF.md#calendar-clock-12-hour-times-and-play-again--8-november-2026).
A Sunday-first calendar and a digital clock replace the today/now line; 12-hour times with
a.m. / p.m.; one day column (weekdays, or month/day dates for weekday questions); 3 countries
from a pool of 8, 4 flights each, no 12 o'clock flights; weekday tracking for day, part and
clock questions about another day; Bruno asks to play again after Finish. Code and data only
(no unit rebaked). `dev_focus.txt` read `all` throughout; the render used `VT_FOCUS=airport`
and an isolated `HOME`.

| Check | Result |
| --- | --- |
| `docs/evidence/flight-board-20261107/verify.gd` (runner `flight_logic`, updated: 4 flights per country, 3 countries from the pool, no 12 o'clock flight, 12-hour and Sunday-column helpers) | **PASS, 15 checks** over 600 random todays and nows; every kind askable in every schedule (600 each). First run failed `hours` on 147 boards (the hours cluster was left out of a quarter of them) and a second run failed boards at 9:00–9:30 (the hours cluster's fourth flight could not fit); both fixed in the schedule, see the [ownership note](ARCHITECTURE_REVIEW_PART1.md#airport-flight-game-ownership--5-november-2026) |
| `tools/language_check.gd` | **PASS, 3275 checks** (846 phrases in es / en / zh) |
| `docs/evidence/flight-board-20261108/capture.gd` (graphical, town with the airport) | **13 PASS, 0 failed**: 3 × 4 flights, no 12 o'clock flight, 12-hour board and clock (*jueves 2:30 p. m.*), Sunday-first calendar with one today, weekday words for day questions, dates under *Fecha* for weekday questions, the target's weekday tracked (and missed on another day), Finish asks to play again, yes restarts at 0/5, the month-end calendar shows April 1–2. Views: [es day](../evidence/flight-board-20261108/es-day.png), [es wrong](../evidence/flight-board-20261108/es-wrong.png), [es weekday](../evidence/flight-board-20261108/es-weekday.png), [es summary](../evidence/flight-board-20261108/es-summary.png), [play again](../evidence/flight-board-20261108/es-again.png), [month end](../evidence/flight-board-20261108/es-month-end.png), [en](../evidence/flight-board-20261108/en-question.png), [zh with translation](../evidence/flight-board-20261108/zh-question.png), [browse](../evidence/flight-board-20261108/browse.png) |

Not run: the full suite and the vocabulary report (`--write`); the report will list the four new
pool countries (Canada, Spain, Germany, Japan) as tested by `flight_bruno` on the next full-suite
run. Not verified by hand: playing the game with the mouse. Known limits (P3): empty space under
the calendar grid; Chinese with translations scrolls the board after about 6 rows (as before).

### Follow-up: arrivals, evening gap, review summary — 8 November 2026

Change: [design record](TOWN_DESIGN_BRIEF.md#calendar-clock-12-hour-times-and-play-again--8-november-2026)
(follow-up table): no flights 7:00–8:59 p.m.; departures and arrivals with take-off / landing
icons and *llegar* questions (country-less only when the verb decides, then tracked); missed
questions first in the summary. Code and data only. `dev_focus.txt` = `all`.

| Check | Result |
| --- | --- |
| `docs/evidence/flight-board-20261107/verify.gd` (runner `flight_logic`, extended: one direction per country, both on every board, phrase direction, verb-decided country-less questions and their explanation, no flight 7–9 p.m.) | **PASS, 15 checks** over 600 boards; every kind askable on every board; questions 3,088 departures / 2,912 arrivals, 527 verb-tracked |
| `tools/language_check.gd` | **PASS, 3341 checks** (868 phrases) |
| `docs/evidence/flight-board-20261108/capture.gd` (graphical, extended) | **18 PASS, 0 failed** (adds: no 7–9 p.m. flight, both directions, an arrival question without a country tracks *to arrive* and a departure at that time misses it, a first-tap miss is kept and listed first in the summary). New view: [es arrival with a wrong departure](../evidence/flight-board-20261108/es-arrival.png); [es summary](../evidence/flight-board-20261108/es-summary.png) now shows *Para repasar*; the other views were re-rendered |

Not run: the full suite and the vocabulary report. Not verified by hand: playing with the mouse.

## Word *bird* removed — 8 November 2026

User request: remove *bird* and everything related to it. Removed: the zoo animal `ParkZoo/Bird`
(base step `remove_bird` in `scripts/buildings/base.gd`, baked with `-- base`), its model
`scenes/animals/bird.tscn` and its instance in the legacy `scenes/world/park_zoo.tscn`, the
`words.json` entry (*el pájaro* / 鳥), its wander profile and display height in `park_animals.gd`,
the unused 鳥 pinyin entry, and the Chinese grammar question zh-009 now asks 一隻鴨 (*duck*) instead.
Old saves are safe: studied-word lists drop unknown keys on load, and the practice log is read by
key. The zoo now has 19 animals (`docs/evidence/town-checks/check_zoo_upgrade.gd` updated; [animal guide](ANIMAL_SYSTEM.md#animal-size-table)).
Godot 4.7.2 headless, `dev_focus.txt` = `all`.

| Check | Result |
| --- | --- |
| `tools/compare_scenes.gd` on `base.scn` before/after the bake | 13 differences: the 12 Bird nodes and `applied_steps` + `remove_bird`; 14471 → 14459 nodes |
| `tools/run_checks.py --only runtime_resources,language,part2,grammar_class,vocabulary_categories,vocabulary_translations` | PASS 5; `language` NEW 1: 港 has no pinyin. It comes from the uncommitted airport board tabs (離港 / 抵港 in `phrases.json`), not this change — **P2**, add 港 to `pinyin_zh.json` with that work |

Not run: the full suite, the vocabulary report (it regenerates on the next full run and still
lists *bird* until then), a rendered view of the zoo.

### Second follow-up: Salidas / Llegadas tabs, time-only clock — 8 November 2026

Change: [design record](TOWN_DESIGN_BRIEF.md#calendar-clock-12-hour-times-and-play-again--8-november-2026)
(second follow-up table). Panel and session only, plus four phrases (`tab_departures`,
`tab_arrivals`, `col_origin`, `col_destination` back to *Destino*) and the reading of 港 in
`data/pinyin_zh.json`. `dev_focus.txt` = `all`.

| Check | Result |
| --- | --- |
| `docs/evidence/flight-board-20261107/verify.gd` (`flight_logic`) | **PASS, 15 checks** (schedule and questions unchanged) |
| `tools/language_check.gd` | First run **FAIL 1**: no reading for 港 (new tab text 離港 / 抵港); added `"港": "gǎng"`; rerun **PASS, 3329 checks** (the lower total than the morning's 3341 comes from other uncommitted work in the tree, not this change) |
| `docs/evidence/flight-board-20261108/capture.gd` (extended) | **21 PASS, 0 failed** (adds: the clock shows the time only, a game starts on Salidas, each tab shows only its flights under *Destino* / *Origen*); all views re-rendered, e.g. [es day](../evidence/flight-board-20261108/es-day.png), [zh with translation](../evidence/flight-board-20261108/zh-question.png) |

Not run: the full suite and the vocabulary report. Not verified by hand: playing with the mouse.

### Third follow-up: no calendar day names, 8 + 8 flights, shorter questions — 8 November 2026

Change: [design record](TOWN_DESIGN_BRIEF.md#calendar-clock-12-hour-times-and-play-again--8-november-2026)
(third follow-up table). Before the fix, 300 boards measured: every clock question named a
country, 16 words on average (up to 20); hours questions with *va a* up to 15.
`dev_focus.txt` = `all`.

| Check | Result |
| --- | --- |
| `docs/evidence/flight-board-20261107/verify.gd` (`flight_logic`, extended: 8 arrivals of 16, long kinds without country or *va a*, every Spanish question at most 12 words, verb tracked only when it decides) | First run **FAIL 1**: still 13–14 words (the *Busca el vuelo que…* form, *Estados Unidos* + *va a*); fixed (long kinds ask *¿Qué vuelo…?*, the game skips questions over `max_words`); rerun **PASS, 15 checks**, every kind on every board; verb tracked in 3,076 of 6,000 questions |
| `tools/language_check.gd` | **PASS, 3332 checks** |
| `docs/evidence/flight-board-20261108/capture.gd` | **22 PASS, 1 FAIL**: "with translations the calendar shows native day names" found 1 of 7 labels, a fault in the check (it searched by node name and Godot renames same-named siblings); the [zh view](../evidence/flight-board-20261108/zh-question.png) shows all seven (Sun…Sat). Check fixed to use a `calendar_head` meta; **not re-run**. New view: [es start](../evidence/flight-board-20261108/es-start.png) |

Not run: the full suite and the vocabulary report. Not verified by hand: playing with the mouse.

### Fourth follow-up: a board built for each question, 6 + 6, no scroll bar — 8 November 2026

Change: [design record](TOWN_DESIGN_BRIEF.md#calendar-clock-12-hour-times-and-play-again--8-november-2026)
(fourth follow-up table). The play-test screenshot showed the board overflowing (8 rows a tab,
two-line rows) with a scroll bar. `dev_focus.txt` = `all`; the capture ran with `VT_FOCUS=airport`
(only the airport building loaded).

| Check | Result |
| --- | --- |
| `docs/evidence/flight-board-20261107/verify.gd` (`flight_logic`, rewritten for `design()`: 300 todays × every kind, 6 + 6 flights, at most 3 of a country a tab, country trap when a country is named, verb trap in the other tab, plus the earlier question checks) | **PASS, 15 checks**; every kind got a board on every today (1,500 of 1,500); verb tracked in 991 |
| `tools/language_check.gd` | **PASS, 3332 checks** |
| `docs/evidence/flight-board-20261108/capture.gd` (6 + 6 boards, new board for each question, rows fit without a scroll bar in es-day and the two-line zh view) | **26 PASS, 0 FAIL** (also the native calendar heads check fixed in the third follow-up). The log starts with a compile error in `scripts/learning/evidence_props.gd` (`pore` type), uncommitted police work outside this change; the airport checks ran. Views: [es day](../evidence/flight-board-20261108/es-day.png), [zh](../evidence/flight-board-20261108/zh-question.png), [wrong verb](../evidence/flight-board-20261108/es-arrival.png) |

Not run: the full suite and the vocabulary report. Not verified by hand: playing with the mouse.


## Monument plaza art — 8 November 2026

User request with an illustrated reference: improve the Washington monument's flower beds,
fountains and statue. Base steps `tulip_beds`, `plaza_fountains`, `bronze_statue`
(`scripts/buildings/monument_plaza.gd`, `scripts/objects/baked_multimesh.gd`,
`shaders/fountain_stream.gdshader`), baked with `-- base`
([record](public-garden/README.md#monument-plaza-art--8-november-2026)). Godot 4.7.2.
`dev_focus.txt` read `restaurants, police, warehouse` (unrelated in-progress work, left as is);
the base world always loads, and the checks below ran with `VT_FOCUS=all` and an isolated `HOME`
except the first render pair, which ran without an isolated `HOME` (capture only, no study).

| Check | Result |
| --- | --- |
| `tools/compare_scenes.gd` on `base.scn` before/after (first bake) | 14459 → 12093 nodes, 2405 differences, `applied_steps` + the three steps; listing truncated to removed flower nodes, so the rest was checked by renders and a node dump |
| Node dump after the first bake | All four tulip MultiMeshes had identity transforms and a zero AABB: the dummy renderer drops instance data. Fixed with `baked_multimesh.gd`; `base.scn` restored from the pre-bake copy and baked again (1,842 lens + 1,392 border tulips, 696 border balls replaced) |
| `check_public_garden.gd` (after the first bake) | 0 failures; 1,815 path samples; two fountains with ≥ 5 bodies, horse faces west, bridge and wading pass. Not re-run after the second bake, which changed only the tulip storage and dropped the fountain spill sheet |
| `check_runtime_resources.gd` (after the second bake) | 409 checked, 0 failures |
| `capture_monument.gd` (after the second bake) | Forecourt, lens bed, fountain and statue views inspected; tulips, curbs, streams, bronze child and horse/rider render as intended |

Not run: `docs/evidence/part2/verify.gd` (its tricorn-brim node is kept, hidden), `check_park_terrain.gd`
(no terrain change), the full suite and any frame-time measurement. The tulips add about
3,200 instances (~110 k triangles) in four MultiMesh draws without shadows, against ~1,160 removed
sphere meshes; frame time was not measured (**P3**). The fountain figure keeps a small bronze
bird as the old figure did; the 8 Nov word removal did not cover decorative sculpture.

## Washington statue blueprint — 8 November 2026

User request with a "Character Blueprint" sheet: make the Washington statue match it. First
pass: base step `statue_blueprint`; the user said it did not look like the blueprint, so a
comparison was made and the bronze re-traced from the blueprint's side view (steps
`statue_traced`, `statue_traced_refit`; `scripts/buildings/monument_plaza.gd`), each baked with
`-- base` ([record](public-garden/README.md#statue-from-the-character-blueprint--8-november-2026-later)).
Godot 4.7.2. `dev_focus.txt` read `restaurants, police, warehouse, school` (unrelated work, left
as is); full-town renders ran with `VT_FOCUS=all` and an isolated `HOME`. Restoring `base.scn`
from the git index before re-tracing was refused by the permission system, so the second pass
is a step that removes the first pass's mesh (the documented "add a step that undoes it").

| Check | Result |
| --- | --- |
| Isolated previews (base scene only, step applied in memory; scratch script) | First pass: two rounds. Second pass: three rounds of blueprint-style front/right/left/back/3/4 views plus face and horse-head close-ups; fixed coat skirts (were blobs), face (jaw read as a moustache), small horse head, haunch lumps, blanket size, bare neck |
| `tools/bake_unit.gd -- base` ×3 (`statue_blueprint`, `statue_traced`, `statue_traced_refit`) | `base.scn` saved OK each time (12,092 → 12,093 nodes; the door count in the report read 19, then 21, from other units' in-progress work) |
| Full-town renders (scratch copy of `capture_monument.gd`'s set-up, 1200 × 800) | First pass: 5 views (first run stalled after two; the remaining three in a second run). Second pass: 5 views, inspected; a pale reflection and dark dot on the chest and over-tall ears led to the refit, then one more batch of the same 5 views |

Not run: `check_public_garden.gd` and `docs/evidence/part2/verify.gd` (they read the old hidden horse and
tricorn nodes, which these steps do not touch), `check_runtime_resources.gd`, the full suite and
frame time. The traced statue is about 5.2 m from hoof to hat (top y ≈ 8.8, was 7.45);
`UpperPlinth`'s mesh is hidden behind a wider `Statue cap`, its 3 × 3 collision unchanged
(**P3**: the cap's outer 0.45 m has no collision; out of reach at 3 m up). From the front walk
the horse's head hides most of the rider's face (**P3**, see the record).

## Alta Cocina dining room refresh — 8 November 2026

Change: [design record](TOWN_DESIGN_BRIEF.md#alta-cocina-dining-room-refresh--8-november-2026)
(step `dining_room_refresh` in `scripts/buildings/restaurants.gd`, baked with
`tools/bake_unit.gd -- restaurants`: "table parts moved 107", scene saved OK).

| Check | Result |
| --- | --- |
| `docs/evidence/alta-cocina-20261108/capture.gd` (new; `VT_FOCUS=restaurants`, isolated HOME, **not the full town**) | 12 checks, 0 failures: window glass in front of the wall, four posters on the rear wall, MENÚ over the kitchen door, Twinkle and the west table moved inward, 4 corner posts, 4 crown mouldings, 6 front/rear wainscot panels, plaster on 11 wall faces |
| Views `window.png`, `entrance-side.png`, `from-door.png`, `rear-wall.png` | Inspected: clean window, readable corners, posters in one row above the pass and kitchen door |

Limits: the run stalled before its summary line and two extra corner views (the off-screen
Godot window stopped drawing); those shots were removed from the script and the run was not
repeated. The flicker fix is shown by geometry (no coplanar faces left) and a still view; a still
cannot prove the absence of flicker in motion. `docs/evidence/restaurant-20261106/capture.gd` (the game
playthrough) was updated for the new poster and Twinkle positions and run once afterwards
(`VT_FOCUS=all`, isolated HOME): **32 checks, 0 failures** (seat and customer, Twinkle's offer,
the four posters with their icons, a full four-course meal with a wrong and a right dish per course,
summary, a new customer, leaving early). It rewrote that folder's 18 view PNGs, which now show
the rear-wall posters; `poster-menu.png` and `game-offer.png` were inspected.

## Bathroom fixtures — 8 November 2026

Working toilets and faucets in both Home bathrooms and the kitchen, and two new airport restrooms
([design record](TOWN_DESIGN_BRIEF.md#bathroom-fixtures--8-november-2026)). Baked:
`bake_unit.gd -- home airport` (steps `bath_fixtures`, `restrooms`); `compare_scenes.gd` against
the pre-bake scenes: home 2380 → 2399 nodes (old toilet parts, basin discs and the two tap pieces
removed; fixtures added), airport 4092 → 4200 nodes, applied steps as expected. A first bake left
the four mesh-less carousel/sign nodes behind (wrong transform in the step); the scenes were
restored from the pre-bake copies, the step fixed and baked again.

| Check (one run, `run_checks.py --only …`, VT_FOCUS=all) | Result |
| --- | --- |
| `runtime_resources` | PASS |
| `bath_fixtures` (new, full suite: words and E hint, picking, flush timing and signals, faucet stays on and clears, doors registered, player fits in walkways, doorways and both rooms, old doors gone, carousel collision moved) | PASS |
| `interaction` | PASS |
| `building_access` | PASS |
| `seats_swan_boats` | **NEW 1:** `airport seats sat on intended seat: 38/39` (39/39 on 7 Nov). The failing seat is (11.6, 0.58, 5.82), the gate's rear row; the log shows the player's nearest seat was another one. The gate nodes within 2.5 of it are identical in the pre- and post-bake scenes and the restroom block is about 5 units away, so the change is not shown to cause it; this check's airport count has varied before (53/54, 51/54, 37/39). Not re-run (verification budget); not added to the expected failures. P3. |

Views: `docs/evidence/bath-fixtures-20261108/capture.gd` (13 PNGs; rendered twice: the first batch showed
the Home lever poking through the raised lid and water too pale, fixed before the second).
Not done: the full suite; hand play-testing (E from the player's real aim, camera inside the small
restrooms); the family-bathroom walk-in.

## Sitting on toilets, flush control, first sounds — 9 November 2026

E near a toilet sits; E or a click on its lever / push plate flushes; the flush and running-water
sounds play from the fixtures ([design record](TOWN_DESIGN_BRIEF.md#bathroom-fixtures--8-november-2026),
*Sound*). Baked: `bake_unit.gd -- home` and `-- airport`, new step `toilet_flush_control` in both
(applied steps confirmed; the first bake stopped after one toilet on a freed-node error in
`rebuild_toilets`; the scenes were restored from pre-bake copies, the helper fixed, baked again).

| Check (`run_checks.py --only …`, VT_FOCUS=all) | Result |
| --- | --- |
| `runtime_resources` | PASS (before and after the bake) |
| `interaction` | PASS (before the bake) |
| `seats_swan_boats` | **NEW 1:** airport seats 40/41 (before the bake; toilets were rebuilt at load, same parts). The two airport toilets are now seats and both were sat on and stood up from; the one failure is the same gate seat (11.6, 0.58, 5.82) as on 8 Nov (P3). |
| `bath_fixtures` (77 checks: also toilets are seats; bowl vs lever / push plate picking by the real camera ray; E on the lever flushes; a click on the push plate and, seated, on the lever flushes; E at the bowl sits without flushing; seated over the bowl; E stands up clear; flush sound plays at the toilet, 2.8 s, SFX bus, freed when done; running water loops at the faucet and stops when it is turned off; SFX bus exists) | PASS on the third run. Run 1 timed out (the baked toilets lacked the new parts: the bake step was then added); run 2 failed 3 picking checks because physics interpolation eased the check's probe camera (the check now turns it off for the probe). Both were defects, not flaky retries. |

Views: `capture.gd` batch rendered once after the bake (14 PNGs, new `home-toilet-seated.png`);
the models look as before. Not verified: anything audible (Claude cannot hear: players were
checked as created, playing, looping, on the SFX bus and at the fixture; the user listens in
game); hand play-testing of E / click from the real player camera; the full suite.

## Grammar Classroom walk-back and countdown — 8 November 2026

User request ([guide](GRAMMAR_CLASS.md#how-it-plays)): after every answer the game stands the
player up and walks them back to the start (−6, −2) before the next question; the seconds left
are a large number at the top centre with a hint below ("Hurry! Pick a desk!" / "Press Confirm
or wait"), red and pulsing in the last 3 s. The walk uses a new `auto_walk` list on
`player_controller.gd` (normal physics, collisions and walk animation). `grammar.time_left` /
`time_left_sit` were replaced by `grammar.hurry` / `grammar.seated`.
`docs/evidence/grammar-class-20261106/verify.gd` was updated: its old "stays seated across questions"
case now checks the walk back, plus new cases for the countdown and the leave question during
the walk.

| Check (one run each, `run_checks.py --only …`, VT_FOCUS=all) | Result |
| --- | --- |
| `runtime_resources` | PASS |
| `language` | First run NEW 1: the Chinese hint used 等, which has no pinyin entry; the phrase was reworded to 按「確定」，或者稍候. Second run: PASS |
| `grammar_class` | First run NEW 3: the updated Q5 case let the countdown run out while sitting down (a test timing error). After the fix: **PASS** |
| `seats_swan_boats` | NEW 1: `airport seats sat on intended seat: 38/39`, the gate's rear-row seat (11.6, 0.58, 5.82), which also fails in the uncommitted airport work's own record (P3; this change only acts while `auto_walk` has points) |

Views (scratch script, `VT_FOCUS=school`, 1280 × 800, not saved in `docs/`): the countdown first
sat at 40 % of the height and covered the question on the board, so it moved to 14 % (over the
ceiling). Measured walk-backs from desks A–D: 1.3–2.3 s, at most 0.13 m per physics step (walks,
never snaps), ending within 0.15 of the start. Not verified: hand play with a real keyboard,
other window sizes, the full suite. `dev_focus.txt` lists buildings (another session's setting);
the runner used VT_FOCUS=all.

### Follow-up: walk route, closer start, review of missed questions — 8 November 2026

User requests: the walk back first stepped away from the aisle (it always went round behind the
chair, also when BonBon stood up on the aisle side); now it goes straight across to the aisle and
only goes round from the wall side. The start moved from (−6, −2) to (−6, −0.4), between desks C
and D (`School.START`, runtime only). Missed questions come back once at the end
([guide](GRAMMAR_CLASS.md#how-it-plays)); new phrase `grammar.review_later`. `verify.gd` gained
review checks (Q1's miss queued as question 11; no question straight after itself; reviews only
repeat earlier questions once).

| Check (one run each, `run_checks.py --only …`, VT_FOCUS=all) | Result |
| --- | --- |
| `runtime_resources`, `language`, `grammar_class` | **PASS** |

Scratch render (`VT_FOCUS=school`, 1280 × 800): the start view matches the user's reference
(BonBon between desks C and D). Walk-backs from desks A–D: 1.7–2.1 s, at most 0.13 m per physics
step, ending within 0.15 of the start; the largest sideways move away from the aisle line is
0.14 (the turn into the aisle), where the old route stepped about 0.8 toward the wall first. Not
verified: hand play with a real keyboard; the review toast was not rendered.

### Follow-up: Continue after a miss — 9 November 2026

After a wrong or missed answer the explanation stays until Continue (the card's Confirm button,
relabelled, phrase `grammar.continue`) or 10 s; right answers still move on after 2 s. The walk
back still runs meanwhile. `verify.gd`: the 10 s hold and its timeout, the Continue button, and
an `advance()` helper for the remaining questions.

## Washington sculptural reference — 8 November 2026

Base steps `statue_reference` and `statue_reference_finish` refine the horse/rider and
pedestal from the user's subsequent sculptural portrait. See the
[design and limits](public-garden/README.md#sculptural-portrait-refinement--8-november-2026).

- `check_runtime_resources.gd`: baseline, first bake and final correction each loaded
  415 resources, 0 failures. Existing macOS certificate error / legacy `specular`
  remapping warnings appear in these runs; no new GDScript parse failures.
- `tools/bake_unit.gd -- base`: both steps saved successfully, 12,094 nodes.
- `capture_statue_reference.gd`: bronze mesh, corner pilasters, plaque and pedestal
  assertions passed; 18/18 units loaded. Four 1200 × 800 views rendered per batch.
  First batch revealed facial-relief/pilaster placement issues; corrected and the
  final close, front and side views inspected. Final images use tag
  `reference-final-20261108`. Initial sandbox graphical launch aborted before output;
  graphical captures succeeded outside the sandbox (exit 0).
- Isolated HOME used throughout. `dev_focus.txt` temporarily set to `all` for the
  full-town captures/final resource check, then restored byte-for-byte to the original
  `restaurants, police, warehouse, school, airport` setting. Base always loads.

Limits: no full suite, gameplay traversal or performance benchmark. Existing garden
checks target the hidden legacy horse, so were not treated as sculpture validation.
The model remains stylized with visible component joins; the front view still hides
part of the rider behind the horse's head and has a bright chest reflection (P3).
Existing collision was preserved, including the previously recorded cap-edge limit.


### Washington angular head and hair texture — 8 November 2026

User follow-up: head too round; add hair texture. Base step `statue_angular_portrait`
rebuilds the bronze with a planar forehead/cheek/jaw mesh and swept strands,
spiral-ridged wig rolls and a grooved queue. Previous turn's rendered statue and
415-resource result were the baseline; no gameplay behavior changed.

- `tools/bake_unit.gd -- base`: one step applied, 12,094 nodes, saved successfully.
- `check_runtime_resources.gd`: 415 checked, 0 failures. Existing macOS certificate
  message and legacy material warnings remain.
- `capture_statue_reference.gd -- angular-20261108`: 18/18 units loaded; mesh,
  pilaster, plaque and pedestal assertions passed. Three-quarter and side images
  rendered and inspected. Capture stalled before front/close/portrait/hair images;
  bringing Godot forward did not resume it, and the session was stopped. No rerun.
  Dedicated close-up verification is incomplete (P3).
- Isolated HOME used. `dev_focus.txt=all` during verification, then restored to
  `restaurants, police, warehouse, school, airport` byte-for-byte. No full suite or
  additional baseline comparison. No commits.

### Washington temple hair and proportions — 9 November 2026

User follow-up: remove added colour, fill temple hair, slightly widen/shorten the
face. Base steps `statue_temple_hair` and `statue_hair_relief_fit` implement a
uniform bronze face/hair, temple locks and a 1.12 lateral / 0.92 vertical portrait
scale. The second step fits raised strands to the hair surfaces after close-up review.
The previous turn's images/resource result supplied the relevant visual baseline.

- Both `tools/bake_unit.gd -- base` runs saved successfully, 12,094 nodes each.
- `check_runtime_resources.gd` after the first step: 415 checked, 0 failures;
  existing certificate/legacy material warnings remain. Final correction loaded
  successfully in the second bake and graphical run.
- `capture_statue_reference.gd` with `portrait`: two images per run (face/temple and
  rear hair), all inspected; both processes exited 0. Final tag
  `temples-final-20261108` (the work crossed midnight) records fitted relief,
  temple coverage and uniform bronze. All 18 units loaded; statue mesh/plaque/
  pedestal assertions passed. No flaky capture retry or full suite.
- Isolated HOME throughout; `dev_focus.txt=all` during verification, restored
  byte-for-byte to `restaurants, police, warehouse, school, airport` afterwards.
  No commits. Hair remains stylized with visible individual locks and metallic
  highlights; no claim of photorealistic sculpture.

### Entire statue in one bronze finish — 9 November 2026

User repeated “remove the different color.” Step `statue_single_bronze` applies
one material to the entire horse/rider mesh, disables all vertex colour accents,
and softens reflective colour shifts. Geometry and stone are unchanged. Prior
portrait renders served as the visual baseline.

- `tools/bake_unit.gd -- base`: saved successfully, one step, 12,094 nodes.
- `check_runtime_resources.gd`: 415 checked, 0 failures; existing certificate and
  legacy material warnings remain.
- `capture_statue_reference.gd -- single-bronze-20261109 <folder> portrait`:
  uniform albedo / disabled vertex-colour assertions passed, along with the
  mesh/pedestal/plaque assertions. Two close-ups rendered and inspected, exit 0;
  18/18 units loaded. Natural light/shadow still varies across surfaces.
- Isolated HOME; focus `all` during verification, then original
  `restaurants, police, warehouse, school, airport` restored byte-for-byte.
  No full suite, gameplay checks or commit for this material-only change.

## Bench placement audit — 9 November 2026

User request: check every bench for odd positions (in a road, hidden by terrain) and fix them.
A headless scan (scratch script, not kept) listed every node named or keyed `bench`: 36 benches
(7 park benches, the gazebo bench, 6 public-garden benches, the bus stop bench, 10 swan boat
seats, 11 interior benches and booths). For each it cast rays down through the footprint (what
the bench stands on, and any solid above its base) and tested its volume against other solids;
outdoor benches were also tested against road, walk, bed and fence meshes. No bench stands on a
road. Interior benches, booths, swan boat seats and the gazebo bench are fine.

Fixed by the base step `bench_placement` (`scripts/buildings/base.gd`; town coordinates):

| Bench | Problem | Fix |
| --- | --- | --- |
| Park bench5-8 (15, 101) | sunk ~0.3 m into the raised park ground (seat at grass level) | lifted 0.31 |
| Park bench25-28 (30, 99) and Picnic table2 beside it | sunk ~0.45 m | lifted 0.46 |
| Garden bench seat (12, 109) | in the middle of the lagoon walk junction | on the lawn at (7.75, 106.3), facing the lagoon |
| Garden bench seat4 (-55, 120) | straddling the zoo boundary fence | lawn strip outside the fence (-52.8, 120), facing the walk |
| Garden bench seat5 / seat6 (34, 135 / 143) | inside the roped tulip lawns of the monument plaza, out of reach | on the plaza walk edges (34, 137.25 / 140.95), facing each other |
| Bus stop bench (35.8, 189) | a bare seat plank inside a planting bed | moved beside the bus stop sign (37.4, 190), given a back and two legs (children of the word root), facing the road |
| Garden bench seat2 (12, 163) | on a slope, its back legs in the ground | removed (user, 9 Nov 2026) |
| Park bench9-12 (-73, 186) | alone in a lawn facing a building wall | removed (user, 9 Nov 2026) |

| Check | Result |
| --- | --- |
| `bake_unit.gd -- base` + `compare_scenes.gd` | step applied alone (the earlier base steps were already baked), baked again from the pre-bench copy after the removals were added; 70 differences against it: bench / picnic-table transforms, the three new bus bench parts, the 28 removed bench nodes, the root metas and `applied_steps`; the layout's map details drop the removed garden bench parts |
| Bench scan after the first bake | every fixed bench stands on ground, nothing above its base, no overlaps |
| `check_sitting.gd` | 361 checks, 0 failures (319 seats after the removals). The "wall blocks seat approach" test built an axis-aligned wall, which only blocks a bench facing ±Z; the wall now turns to the bench's facing |
| `run_checks.py --only runtime_resources,public_garden,park_terrain` (after the removals) | PASS, PASS, PASS |
| `run_checks.py --only seats_swan_boats` (first bake) | NEW 1: `airport seats sat on intended seat: 38/39`, traced below |
| Rendered views (scratch, 800×500, before/after) | every moved bench checked from two sides: on the grass or walk, upright, reachable |

**Airport seat failure traced (P2, game layout, not fixed; needs a user decision).** The failing
seat is the gate's rear-row chair at terminal-local (11.6, 0.58, 5.82). The rear row (x 9.2-13.4,
facing +z) has the gate desk (`Interior/Gate desk`, collision 2.2 × 1.1 × 0.75 centred at
(12.6, 0.63, 7.2), front face z ≈ 6.83) about 0.7 in front of the seats, but BonBon's capsule radius
is 0.76: there is no room to stand in front of the chairs at x 11.6-13.4. Placed anywhere in the
gap (z 6.2, 6.35, 6.5 and the check's 6.67), the player is pushed out to (10.96, 6.61), the pocket
at the desk's west end, so E sits on the neighbouring chair (11.0) instead. The desk and row are
unchanged from the committed airport (`HEAD` scene compared), so the count's run-to-run swings
(53/54, 51/54, 37/39, 39/39, 38/39) come from the check's depenetration at the desk corner, not
from the restrooms work. Fix options: move the gate desk toward the rear wall or the row forward.

### Statue cast-bronze patina — 9 November 2026

User photograph of the Boston statue: colour and texture "a little off". Base steps
`statue_patina` and `statue_patina_warm` replace the flat `796037` material with one
triplanar patina material ([record](public-garden/README.md)); geometry unchanged.
Godot 4.7.2; isolated `HOME`, `VT_FOCUS=all` for renders; `dev_focus.txt` untouched
(`restaurants, police, warehouse, school, airport`, unrelated work).

- Baseline: full-town render of the flat finish (scratch copy of the capture set-up): reads as
  mustard brass, no surface variation.
- Isolated previews (base scene only, two rounds): first patina too large and teal
  (camouflage look); then finer, greyer and mostly brown.
- `tools/bake_unit.gd -- base` ×2: saved OK, 12,078 nodes each, "materials left unshared": 1
  (the textured bronze).
- `capture_statue_reference.gd -- patina-20261109` ×2 (assertion updated to the patina finish):
  exit 0, "Uniform bronze material (patina finish): passed", statue checks passed. The first
  run showed a near-black statue mirroring the blue sky, which led to `statue_patina_warm`;
  the second run's six views were inspected and kept.

Not run: `check_runtime_resources.gd`, the full suite, frame time (one 512² noise texture pair
generated at load). Remaining: the tricorn brim's underside still picks up some sky blue when
seen from above, and close up the patina reads as blotches rather than fine rain streaks (**P3**).
No commits.

### Statue in the town's style — 9 November 2026

User: the patina finish should "look and feel like the rest of the game". Base step
`statue_town_bronze` (`monument_plaza.gd` `town_statue_bronze()`) replaces the triplanar
patina with one plain dark olive bronze (`#5c5236`, roughness 0.6, not metallic, no vertex
colours), the way Main's `material_for()` paints every other prop. Geometry unchanged.

- Swatches first (runtime material swap, full town, scratch renders): matte `#7d6a4a`,
  `#6e6447`, `#806446` at roughness 0.82 read as beige clay in sunlight; at roughness 0.6,
  `#4e5b45` read as a green toy soldier and `#5f4a32` as chocolate; `#5c5236` kept.
- `tools/bake_unit.gd -- base`: one step; `compare_scenes.gd` against the pre-bake copy: 2
  differences (the bronze's `material_override`, `applied_steps`). The bake also moved the 11
  materials the scene stored itself (the patina pair and the scooter steps' materials) into
  palette files, as every bake does.
- `run_checks.py --only runtime_resources,public_garden`: PASS, PASS.
- Rendered views (scratch, 900×700, six directions around the statue, full town): one even
  colour, no blotches or sky reflections; reins, coat, hat and hair still read in shade.

Not run: the full suite; `capture_statue_reference.gd` (it overwrites the record's PNGs), whose
finish assertion now expects the town bronze. The figure's shape is unchanged (stylized; the horse's head still hides
part of the rider in the head-on view, P3).

## Scooter with a visible rider — 9 November 2026

User request: BonBon stays visible on the motorcycle, seated with paws on the grips and
footrests, with getting-on/off, steering, leaning and acceleration/braking motion; cars must
keep working. BonBon (a round plush with very short limbs) could not reach a motorcycle's pegs or
bars, so the user chose a toy-like scooter built around her. User follow-up the same day: no
shrinking her (make the scooter bigger), she must touch the seat, and her feet must stay joined
to her body. Final design: [vehicle guide](ZOO_VEHICLE_IMPLEMENTATION.md#scooter-and-rider--9-november-2026).
Godot 4.7.2; isolated `HOME`. `dev_focus.txt` untouched (`restaurants, police, warehouse, school,
airport`, other sessions' work); the check ran with `VT_FOCUS=all`, the town views with
`VT_FOCUS=restaurants` (the scooter is in the base world). Results below are for the final
full-size design.

| Check | Result |
| --- | --- |
| `bake_unit.gd -- base` + `compare_scenes.gd` (twice: `toy_scooter`, then `toy_scooter_full_size`) | each bake ran only its own step (the other base steps, including another session's statue steps, were already baked); every difference is under `Vehicles/Motorcycle` plus `applied_steps` (second bake: 11874 nodes before and after, 39 differences) |
| `check_vehicle_boarding.gd` (full town, `--fixed-fps 60`) | 101 checks, 0 failures. Scooter section: prefab with rider mount, word `motorcycle`, E at the mounting step, BonBon visible throughout getting on and off, hop above the seat, seated at the mount at full size (rider scale 1.0), both paws on the grips (< 3 cm) and both feet on the floorboard mat (< 6 cm), left turn leans 0.2–0.42 rad, collision upright, acceleration and braking reach the rocking pose, every tick seated (< 12 cm) with paws on the grips, brakes to a stop, mount-step exit, upright and head straight after, scooter upright, player physics order restored. Subi still hides BonBon in the cabin. Handling: Motorcycle top 27, 0–14 m/s 2.1 s (unchanged), brakes from 25 m/s in 2.87 s / 35.9 m; other vehicles' figures unchanged |
| Preview renders (`docs/evidence/scooter-20261109/preview.gd`, plain floor, 1200×900) | parked, mid-hop, seated side/front/rear, accelerating, left-turn lean, braking. Paw-to-grip 0.000 m in every riding pose; belly-to-cushion −0.004 m seated, −0.005 accelerating, −0.019 turning, −0.006 braking (resting on the cushion, never a gap); seat offset ≤ 0.06 m. Saved as `docs/evidence/scooter-20261109/preview-*.png` |
| Town renders (`docs/evidence/scooter-20261109/capture.gd`, full game loop) | parked in its Alta Cocina lot stall, getting on, seated, riding a left turn (lean 0.41 rad, 33 km/h) and braking on the street at 40 km/h (−6.2 m/s²). Saved as `docs/evidence/scooter-20261109/town-*.png` |

**Handling follow-up (same day).** Lean steering for two-wheelers
([guide](ZOO_VEHICLE_IMPLEMENTATION.md#scooter-and-rider--9-november-2026)).
`handling_probe.gd` (headless, `VT_FOCUS=restaurants`, flat pad + the lot-to-street route):
before, a 6 s left hold on the pad reached 0.38 rad/s in 0.25 s and stayed flat (113°), and in
town the kerb crossing reversed the yaw (+0.97 → −0.68 rad/s with A held) and snapped the lean
0.42 → −0.03 (three lean jumps). After: the pad hold builds 0.14 → 0.75 rad/s over 5.5 s (178°),
a full-throttle right hold 0.07 → 0.47 rad/s; in town no lean jumps on kerbs (the remaining
yaw stops are collisions with raised edges, lean held). `check_vehicle_boarding.gd` (full town):
**101 checks, 0 failures**; every car's handling figures identical; Motorcycle top 27, 0–14 2.1 s,
full-lock slip 0.03, yaw 0.40 rad/s, braking from 20.0 m/s (speed scrubbed in the turn) in 2.25 s
/ 22.1 m. No renders for this change (the poses are unchanged; only how the lean is produced).

**Second handling pass (same day, user: held turns still too wide).** Grip 2.4, cornering drag
6, bars' visible turn capped at 0.06 rad, arm squash limit 0.5. Probe: pad left hold 0.65 rad/s
at 1 s → 1.07 at 2 s → 1.8 cap at 4 s, 428° in 6 s (was 178°); full-throttle right hold 1.0 → 1.28
rad/s (272°, was 110°); town holds 392° / 386°; no lean jumps. First boarding run with grip 2.4 and
drag 8 failed 2 checks (paw 0.086 m off its grip in the tight turn; the car-only yaw limit 1.0
caught the intended 1.02 rad/s): the bar cap, squash limit and drag 6 fixed the first (headless
reach probe: worst 0.006 m before the 0.5 limit), and the check now gives two-wheelers a 1.85 rad/s
limit (their cap is 1.8). Final `check_vehicle_boarding.gd` (`dev_focus` all): **101 checks, 0
failures**; all other vehicles' handling identical to the previous run; Motorcycle top 27, 0–14
2.1 s, slip 0.07, yaw 0.88, braking from 18.1 m/s in 2.0 s / 17.4 m. That run also printed 4
`Node not found: "Model/Flush/Lever"` errors for Home and Airport toilets, not from this change
(another session's work; the scooter files do not touch them). Not played live; no renders.

**Third handling pass (same day: bigger start, more growth, slower coasting).** Lean snaps to
0.35 then builds to 1.0; velocity turns with the nose; cornering drag 2, coasting 0.35 m/s².
`handling_probe.gd` (now also logs a straight coast and a coasting turn): straight coast 16.3 →
15.2 m/s in 1.5 s; left hold at 22 m/s 0.48 rad/s at 0.5 s → 1.18 at 2 s → 1.65 at 3 s → 1.77
at 5.5 s, speed 22.4 → 20.7 (before this pass the same hold bled 22 → 14 m/s); coasting turn
20.4 → 16.2 m/s in 1.5 s (was 12.7 → 5.0); town holds 474° / 361°, no lean jumps.
`check_vehicle_boarding.gd` (`dev_focus` all, yaw limit for two-wheelers now `LEAN_YAW_MAX`+0.05):
**101 checks, 0 failures**; other vehicles identical; Motorcycle top 27, 0–14 2.1 s, slip 0.00,
yaw 1.52, braking from 24.0 m/s in 2.73 s / 32.4 m. The toilet errors did not recur. Not played
live; no renders.

Limits: not played live with the keyboard (the capture steps the scooter's inputs in the game
loop, because `Input.is_physical_key_pressed` ignores injected events). The belly-to-cushion
measure is in the preview only, not in the check. Riding with one of the new fitting-room outfits
on was not tried (the sleeves follow her arm parts). Riding straight out of the stall stops at the
lot edge in front of Alta Cocina (6 m); learners reverse out first, as with the old motorcycle.
No sound (none in the game yet).

## Mahjong table — 9 November 2026

[Guide](MAHJONG.md). Godot 4.7.2; isolated `HOME`. `dev_focus.txt` untouched (it lists other
sessions' buildings).

**First build (same day).** The `run_checks.py` rows `runtime_resources`, `part2`,
`public_garden`, `mahjong_logic`, `mahjong_table`, `building_access` and `language` passed.

Two failures came from other work:
- `compact_layout` "all twelve road/air vehicles registered": there are 13 since the drivable
  warehouse truck (commit 4598be7).
- `seats_swan_boats` airport seats 38/39: the airport unit has other sessions' uncommitted
  changes.

(This section was written then, and replaced here because a concurrent edit had dropped it.)

**Memory (23 Nov 2026).** [Memory](MAHJONG.md#memory): `mahjong_memory` 30 checks, 0 failures
(headless, and again with graphics for its two views); `mahjong_table` 101 checks, 0 failures.
Both ran with `VT_FOCUS=home` (only the home loaded, not the full town) and an isolated `HOME`.
Godot printed the known `recursive_mutex` abort at exit after the summary line.

**Hand hide/show button (24 Nov 2026).** `mahjong_hand_toggle` 9 checks, 0 failures, with graphics
at 1280×800, `VT_FOCUS=home`, isolated `HOME` (one test bug fixed first: it read the panel before
the session redrew it). `mahjong_table` afterwards (headless, same setup): 104 checks, 0 failures.

**Mahjong UI polish (24 Nov 2026).** `VT_FOCUS=home`, isolated `HOME`, not the full town.
`mahjong_ui_polish` (new): 21 checks, 0 failures at 1280×800 with graphics (status card 80 px,
10 % of the height; it was 107 px). At 844×390: 19 checks, 2 failures, "the player may claim a
discard" and "call buttons show". That random game offered the player no Pung/Chow/Kong in 34
turns, so the call buttons were **not checked at phone size**. The layout, nameplate and tray
checks passed there. The first 844×390 run hung on its first screenshot while other sessions'
Godot windows were open; it was stopped and run once more. `mahjong_hand_toggle` (updated for the
centred pull tab and its slide): 9 checks, 0 failures, headless. `mahjong_table` and
`mahjong_memory` were not re-run.
25 Nov 2026: nameplates and the cream counter reverted (user). `mahjong_ui_polish` without their
checks: 10 checks, 0 failures at 1280×800 with graphics; the 1280×800 renders were redone. The
844×390 renders still show the removed nameplates and plaque.

**Follow-up (user requests, same day).** Changes:
- Awoo's chair moved back (home step `mahjong_chair_back`).
- Lin renamed Awoo, and the home's Awoo renamed Sam.
- The preset game in progress (`data/mahjong.json` `preset`).
- Separated tiles with rims, and the 8 bamboo drawn as "W" over "M".
- A fixed hand bar of reused slots (no shift, no rebuild flicker).
- The place / words line hidden during play.

| Check | Result |
| --- | --- |
| `bake_unit.gd -- home` | ran only `mahjong_chair_back`; `home.scn` saved (2497 nodes) |
| `docs/evidence/mahjong-20261109/verify.gd` (adds the preset: no tile more than 4 times, 136 conserved, 79 out of the wall) | **17120 checks, 0 failures** |
| `docs/evidence/mahjong-20261109/play.gd` with graphics, `VT_FOCUS=home`, 1280×800 | **33 checks, 0 failures**: the preset shows all 136 tiles before sitting and again after leaving, and two hands are played in each mode. Renders: `approach.png`, `preset.png`, `game.png`, `result.png` |

Inspected in the renders:
- The walls and hands show as separate tiles.
- Mei's standing hand and chow are visible in the preset.
- The hand bar is left-filled, with the drawn tile apart.
- The 8 bamboo is "W" over "M".

Not checked:
- The flicker fix was not watched live: the panel now reuses its slots, so no node is freed or
  rebuilt between turns.
- No full `run_checks.py` run.
- The place / words line hiding (`_hide_hud`) was added after the play check and is not covered
  by it.

- The home's renamed Sam is not rendered (only her `name` changed).

**Seven Pairs made a limit hand (user, same day).** Changed in `data/mahjong.json`
`limit_hands` and `mahjong_rules.gd` `score()`. `verify.gd`: **17120 checks, 0 failures**; the
seven pairs hand scores the 13-fan limit.

**Table polish (user, same day).**
- Call-button tiles keep a tile's shape.
- The status card shows wind tiles.
- The hand bar is centred and shrinks per exposed set, with the drawn place kept.
- The 8 bamboo is retraced from the user's reference.
- Tile gaps are 30 % smaller.
- Mei gets up and the player sits down in the town before the fade.
- 3D tiles slide between places (discard, then the next draw; the hand closes up).

`play.gd` gained two checks:
- the sit-down happens before the fade;
- slides run in real time.

It also renders `sitting.png` and `slide.png`.

Found while rendering: the preset tiles had been merged into the town's static render batches
(`render_culling.gd` runs after the minigames are set up), so a frozen copy of the preset stayed
drawn under every game. The tiles are now made after that pass, and `play.gd` checks that no
tile is batched.

`play.gd` with graphics (`VT_FOCUS=home`, 1280×800): **36 checks, 0 failures**. Two earlier runs
of this change stopped on my own script errors and were fixed, not retried. Inspected:
- `sitting.png`: Mei standing beside the table, the player seated.
- `game.png`: a real game, distinct from the preset. Wind tiles in the status card, the centred
  hand bar with the drawn place, and the new 8 bamboo.
- `slide.png`: the player's discard on its way to the pile.

Not checked: the call-button tiles (no claim was showing in a render). Slides were watched only in
that render, not played live.

**Camera moved (user, same day).** `CAMERA_AT` (0, 3.8, 1.5), `CAMERA_LOOK` (0, 1.0, 0.15).
`play.gd` with graphics: **36 checks, 0 failures**.
- In `game.png` the player's two exposed sets (white dragon pung, 1-2-3 dots chow) lie above the
  hand bar, and the whole table, walls and every discard pile are in view.
- The edge of the player's own red chair cushion now shows below the hand bar.

**Camera lowered (user: "too high", same day).** `CAMERA_AT` (0, 2.7, 2.0), `CAMERA_LOOK`
(0, 1.1, -0.2), and the player's own concealed tiles stand on the table.
`play.gd` with graphics: **36 checks, 0 failures**.
- `game.png`: Awoo's face is fully visible, and Bao's and Kiko's partly at the edges. The tops
  of the player's standing tiles show just above the hand bar.
- `result.png` also shows the HUD's "Saved words" list open at the right. The check never opens
  it, so it was probably the mouse over the book button while the window ran; not
  investigated.

**Camera moved back (user: "move back slightly so i can see my revealed tiles", same day).**
`CAMERA_AT` (0, 2.7, 2.4), the same look point. `play.gd` with graphics: **36 checks,
0 failures**.
- `game.png`: the player's exposed chow and the 中 pung lie on the table above the hand bar.
  Awoo's face is fully visible, and Bao's and Kiko's partly at the edges.

**Closer camera, sets on the left, call words (user, same day).**
- Camera (0, 2.8, 2.25) looking at (0, 1.08, -0.12), FOV 45.
- Every seat's exposed sets lie on its left; concealed hands keep to the right.
- Each call pops up as a word over the table, and play pauses 1.0 s after it.
- The game hides the HUD day clock: another session's new `day_clock.gd` covered the turn
  message.

`play.gd` with graphics, `VT_FOCUS=home`: **69 checks, 0 failures**. This is the home unit only,
not the full town. New checks: the meld side for every seat with sets, and call-word placement.
The new `call.png` shows the first call.
- The first run, before the fixes, had 49 checks and 0 failures, but its renders showed stale
  call words in the result, an oversized word at the player's seat, and the clock over the
  message.
- In the rerun's `game.png`, three words show at once because the check plays turns without
  real time passing. In play each word fades after 1.6 s; this was not watched in real time.

**Bigger, clearer tiles; discards toward the player (user, same day).**
- Table tiles are 10 % larger, with walls, hands and sets moved out to fit.
- The faces have stronger colour and contrast, and part of each face glows; the backs are
  brighter.
- Discards lie eight to a row in a pinwheel 8 cm closer to the player; tiles beyond three rows
  lie on top of the first rows.

`play.gd` with graphics, `VT_FOCUS=home`: **62 checks, 0 failures**. The count varies with which
seats call in the random hands.
- `game.png` and `result.png` were rendered at dusk under the new day cycle. Faces are readable,
  the player's exposed sets show above the bar, and no pile touches a wall.
- Not seen: the stacked layer of a fourth row, which needs 25 or more discards at one seat.

**Call words reworked; the sun steps (user, same day).**
- Call words are always English, near the caller's edge and centred on the seat. They show for
  0.9 s with a 0.15 s fade: white letters with a pastel outline per call.
- `day_night.gd` turns the sun in 5-game-minute steps (`SUN_STEP_MINUTES`, about 1°) against
  shadow shimmer.

Checks run:
- `play.gd` with graphics, `VT_FOCUS=home`: **46 checks, 0 failures**. `call.png` shows "Pung!"
  at Awoo's edge in pink.
- After that render, the outline colours were deepened a little and the outline widened (34);
  this is not rendered.
- `run_checks.py full --only day_night`: **PASS**.
- The flicker itself was not watched in real time.

**Tiles capped for the midday sun (user, same day).**
- Tile surfaces are drawn at 80 % of their colour.
- The face glow follows the sun (none at noon), and the strokes are darker.

`play.gd` now sets the time to noon and pauses the clock first, so its views show the brightest
light. Graphics, `VT_FOCUS=home`:
- The first run had **70 checks, 3 failures**. All three were the new meld-side check: Kiko
  had four exposed sets, which run past the middle of the row.
- The check now tests that sets start at the far left and lie left of the seat's concealed
  tiles. The rerun had **65 checks, 0 failures**.
- In `game.png` and `result.png` at noon the faces read ivory, with strongly coloured symbols.

**Tiles at 75 %, a 30-minute day, slow sun at the table (user, same day).**
- `TILE_BRIGHTNESS` 0.75 and `cycle_minutes` 30.
- While seated at mahjong the sun steps about every 30 s of real time and slides over 1 s
  (`set_sun_steps`); leaving restores the normal steps.

Checks run:
- `play.gd` with graphics, `VT_FOCUS=home`: **61 checks, 0 failures**, including the new
  slow-sun and restore checks. `game.png` at noon has readable ivory faces.
- `run_checks.py full --only day_night`: **PASS**. Its default-cycle check now expects 30
  minutes.
- The slide was not watched in real time.

**The player's Mahjong! choice, no turn message, code review (user, same day).**
- A winning hand shows a big pulsing golden Mahjong! button with the hand's worth. On a draw,
  Keep playing goes on instead; on a discard, Pass does.
- The "Your turn: click a tile" message is gone.
- Review fixes (MAHJONG.md "Code review"): the kong after Keep playing, the cancelled sitting,
  the `PopWord3D` component, `day_night.daylight()`, and smaller cleanups.

Checks run:
- `play.gd` with graphics, `VT_FOCUS=home`: **65 checks, 0 failures**. Its new win-offer and
  Keep-playing checks did not run, because no player self-draw win came up in the four
  random hands.
- They were covered by a scratch run with a winning hand set up at noon:
  - the offer showed, and Keep playing hid it with the player's turn going on;
  - it saved `docs/evidence/mahjong-20261109/offer.png`;
  - it also logged a pool overflow, because the scratch hand left its tiles in the wall. That
    led to the view guard; a real game cannot reach that state.
- `verify.gd` headless: **17120 checks, 0 failures**.
- The real-time pulse was not watched.

**Shared table helper, HUD group, staged win check (user: "work on the two larger items and any
already identified bugs", same day).**
- New `minigame_table.gd` holds the seated-table choreography.
- `seating_controller.gd` gains `sit_at()`; `vocabulary_hud.gd` gains `GAME_HIDDEN_GROUP` and
  `hide_for_game()`, and Main puts the minimap and day clock in that group.
- The mahjong session uses all three.
- The check's win-offer test no longer depends on luck. It stages a legal deal with the player
  holding a winning draw, then checks:
  - the offer shows, with no turn message;
  - Keep playing hides it and the turn goes on;
  - pressing Mahjong! wins.

Checks run:
- `play.gd` with graphics, `VT_FOCUS=home`: **67 checks, 0 failures**.
  - `sitting.png`: Mei standing, the player seated.
  - `offer.png`: the minimap, clock and place line are hidden by the group.
- Not run: the general sitting check (`docs/evidence/town-checks/check_sitting.gd`). The seating controller only
  gained the new call; its existing paths are unchanged.
- The earlier "Saved words" panel in a render was the journal button's tooltip under the test
  window's mouse; it has not come back and is not a game bug.

**Mahjong lessons (user: "include some images and make it look cute", discarder pays double,
1-fan minimum payout, same day).** Two lessons of three pages, drawn from data
(`data/mahjong.json` `lessons`, `points`; text in `data/phrases.json`) by the new
`scripts/ui/mahjong_lesson_panel.gd`; Mei asks "Do you know how to play?" after Yes, and a book
button opens them during a game ([MAHJONG.md](MAHJONG.md#lessons)).

Checks run:
- `tools/language_check.gd`: **PASS, 3806 checks, 0 failed** (pinyin for every new character).
- `play.gd` with graphics, `VT_FOCUS=home` (home only, not the full town): **85 checks, 0
  failures** on the first run, with the new lesson checks (points table, balances −16 / 0 / +48 /
  −32, 6 and 4 smallest wins, both worked examples scoring 5 fan by `Rules.score`, the book
  button pausing the game).
  - The renders showed the HUD over the card's top, a crowded worked-example legend and
    balances labels, and oversized translated bold text; all were fixed.
  - Two later runs for the fixed renders (84 and 81 checks, 0 failures; counts vary with the
    random hands) were not clean loads: another session's work-in-progress
    `scripts/ui/radar_patrol_panel.gd` failed to parse, so Main's wiring stopped after the
    mahjong panels. The lesson renders from them were inspected.
  - Final run once that panel loaded (user: "Yes, re-render"), `VT_FOCUS=home`: a clean load,
    **72 checks, 0 failures** (the meld-side checks run per exposed set, so the count follows
    the random hands). Every lesson page, the translated, Chinese and in-game views were
    inspected: no overlaps, the worked-example sum sits beside its parts, and no page scrolls.

**Mei's lesson question as yes / no (user, same day).** "Do you know how to play mahjong?" Yes →
the mode question; No → "What would you like to learn?" (The basics / Scoring); after a lesson,
another lesson or Let's play. Reworded `lesson_*` phrases plus `lesson_teach`, `lesson_which`,
`lesson_more`, `lesson_play`.

Checks run:
- `tools/language_check.gd`: **PASS, 3830 checks, 0 failed**.
- `play.gd` with graphics, `VT_FOCUS=home` (home only): **82 checks, 0 failures**, a clean
  load. New views `ask.png` and `ask-which.png` were inspected.

**Playing a tile ahead (user, same day: "when others are playing … click it twice and that tile
would be automatically played when it's my turn").** A double-click on a hand tile during another
player's turn marks it, and it is discarded on the player's next turn unless Mahjong! or Kong
shows ([MAHJONG.md](MAHJONG.md#flow)). `mahjong_panel.gd` `TileButton` counts two presses within
0.45 s (touch too); `mahjong_session.gd` `_queued` / `_auto_tile()`; `pace.auto_discard` 0.5 s.

Checks run:
- `play.gd` with graphics, `VT_FOCUS=home` (home only), new play-ahead checks with real clicks:
  - first run **93 checks, 2 failures**: the test clicked before the panel had drawn the new
    deal (its first redraw is on the next frame), a test timing fault, fixed in the test;
  - second run **87 checks, 0 failures**. Whether the auto-play or the "waits for Mahjong! /
    Kong" branch ran depends on the random hand (the first run reached the auto-play branch).
  - `play-ahead.png`: the marked tile lifted with its pink border and ▶ badge.

**No message line; faster NPC moves (user, same day: "remove this sentence and everything shown
in this box"; "speed that up by 60%").** The panel's message line is gone (no "X's turn…", claim
prompt, "too few fan" note or own-call line; the phrases `thinking`, `claim`, `too_few`,
`call_self_win` were removed). Tile slides and NPC pauses take 1/1.6 of their time:
`SLIDE_SECONDS` 0.175, `CLOSE_UP_DELAY` 0.075, `DRAW_DELAY` 0.22, `pace.npc_turn` 0.56,
`pace.claim_pause` 0.44. Call words and `call_hold` are unchanged.

Checks run:
- `tools/language_check.gd`: **PASS, 3818 checks, 0 failed**.
- `play.gd` with graphics, `VT_FOCUS=home` (home only): **89 checks, 0 failures**. `game.png`
  shows no message line. The faster pace was not watched in real time.

**Livelier mahjong players (user, same day: reuse the suspect ID game's blinking and movement,
"only once in a while").** New reusable `scripts/characters/plush_life.gd` (`PlushLife`): the
lineup's eye-squash blink every 4-10 s per player, and one small hop, head shake, nod or tilt
every 10-20 s across the table; the mahjong session gives it to its four players. The police
detective session keeps its own copy for now (its suspects also breathe and lean toward the
pointer), so it was not touched or re-checked.

Checks run:
- `play.gd` with graphics, `VT_FOCUS=home` (home only): **83 checks, 0 failures**, with the
  new checks (eyes not batched, a forced blink and head tilt that end at rest, the next move at
  most 20 s away). `lively.png` shows Awoo's head tilted. The random timing was not watched
  in real time.

**Awoo's sets behind his wall; centred discard piles (user, same day: "check if the undrawn
tiles in front of the samoyed would prevent me from seeing his revealed tiles … make the discard
piles more left right centered … run the game a few times").**
- A scratch script (scratchpad `awoo_view.gd`, not in the repository) rendered the game camera
  view, `VT_FOCUS=home`: a staged deal with Awoo holding a pung, a chow and a kong behind a full
  wall, then three random hands, a view whenever Awoo exposed a set.
  - **Finding:** none of Awoo's exposed sets show while his wall stands (staged; and 1-3 sets
    at 83-42 tiles left in the random hands). Recorded as P2 in MAHJONG.md; not fixed.
  - The scratch views show several call words at once because the script steps the game
    without real time; in play they fade in 0.9 s.
- Discards: each pile is centred on its seat, six to a row (`DISCARD_ROW` 6, `DISCARD_R`
  0.255, `DISCARD_SHIFT` 0); 18 tiles before stacking instead of 24. Renders before and after:
  the piles are now symmetric about the screen centre.
- `play.gd` with graphics, `VT_FOCUS=home` (home only): **101 checks, 0 failures**; `game.png`
  shows the centred piles.

**Awoo's sets visible (user, same day: "fix the hidden sets of awoo by perhaps moving all the
walls closer to the player").** `mahjong_view.gd`: the far and side walls move 0.13 toward seat
0 (`WALL_TOWARD_PLAYER`; the side walls' near ends then stop 0.008 short of the player's hand,
so no further; the player's own wall cannot move, the hand stands right behind it). Measured
from the camera, flat sets would still show only their far 39 %, so the far seat's sets stand
facing the player, leaning back 25° (`ACROSS_SET_LEAN`).
- Scratch renders (same `awoo_view.gd`): the staged pung, chow and kong stand fully visible above
  Awoo's full wall; in a random hand his two sets show the same way.
- `play.gd` with graphics, `VT_FOCUS=home` (home only): **106 checks, 0 failures**.

**Awoo's sets lie flat (user, same day: "i dont not want awoo's shown tile to be vertical, that
looks unnatural").** `mahjong_view.gd`: the standing sets and `ACROSS_SET_LEAN` are gone; every
seat's sets lie flat. Instead Awoo's wall alone moves in to 0.57 from the centre
(`ACROSS_WALL_R`; was 0.745 − 0.13), its inner face 3 mm clear of his discard pile; the discard
square moves 0.085 toward the player (was 0.08) so that gap exists, and the player's pile still
ends 0.008 inside the player's wall. Computed from the camera, about 83 % of each flat set tile
clears his wall (his sets' nearest edge stays hidden); 100 % would need 0.55, over his pile.
- Scratch renders (same `awoo_view.gd`, `VT_FOCUS=home`): the staged green-dragon kong, chow and
  red-dragon pung lie flat with faces readable above Awoo's full wall (faces toward Awoo, as at
  a real table); in random hands his 1-3 sets show the same way. Not checked: how the nearer
  wall looks once Awoo's discards pass 18 and stack.
- `play.gd` with graphics, `VT_FOCUS=home` (home only): **92 checks, 0 failures** (106 in the
  run above; the reason for the lower count was not looked into). The first run's summary line
  was dropped by my output filter (no FAIL lines), so it ran a second time to read the total.


## Journal redesign: saved words merged, bigger gear and book — 9 November 2026

[Guide](ARCHITECTURE_REVIEW_PART1.md#vocabulary-book). The saved-words panel became the journal's
Saved tab; the book button opens the journal; new header (progress, ✕), styled tabs, one tools
row, framed table; gear and book 60 × scale px (were 46 × 44).

| Check | Result |
| --- | --- |
| `vocabulary_book` with graphics, isolated `HOME`, `VT_FOCUS=home` (only the home unit; not the full town), 1600 × 1000 | First run **83 / 1**: my new "book and gear show" check read the HUD one frame early (it updates in `_process`); the check now waits two frames. Second run, also with the empty Saved footer blanked: **84 checks, 0 failures**. 778 words: rebuild 3.3 ms, scroll step 0.33 ms |
| `tools/language_check.gd` | **PASS, 3566 checks** (943 phrases in en, es, zh) |

Inspected PNGs in `docs/evidence/vocabulary-book-20261108/`: `table-en-es`, `saved-en-es`,
`saved-empty-en-es`, `detail-en-es`, `scores-hidden-zh-es` and `hud-buttons` (gear and book about
75 px at this size). The full suite was not run. Not verified: a real mouse in play (clicks were
emitted as signals), the category / sort menus open on screen, windows smaller than 1100 × 800.
Stale, not in the suite (unchanged): `docs/evidence/language-ui-20261104/verify_town.gd` also calls the
removed `set_bookmarks_open` / `bookmark_title`.

## Day-night cycle and HUD clock — 9 November 2026

[Guide](performance/README.md#day-night-cycle--9-november-2026). A 20-minute day-night cycle
(`scripts/world/day_night.gd`, `data/day_night.json`) replaces Main's fixed sun and sky. The
HUD clock (`scripts/ui/day_clock.gd`) sits top centre. Daylight is slightly softer: sun
0.62 → 0.56, ambient 0.50 → 0.54. Full town (`dev_focus.txt` = `all`), Apple M5, Godot 4.7.2,
isolated `HOME`.

| Check | Result |
| --- | --- |
| `docs/evidence/day-night-20261109/verify.gd` (headless; new `day_night` row in `run_checks.py`, full suite) | First run **44 checks, 0 failures**. After the fixes below (indoor light and walls, sun out of the sky), **45 checks, 0 failures**: one sun and no added lights; starts at the shared "now"; noon at the old direction; keyframes smooth in 5-minute steps; 27 lamp heads glow only at night and keep their material through batching; 23:30 + 1 h = 00:30 (12:30 AM) and back; − / + pause, Resume restarts; panel opens, Esc-able, Close keeps the time; indoor light in the supermarket at midnight, moonlight outside |
| `python3 tools/run_checks.py` (quick) | runtime_resources, language, part2, public_garden **PASS**. compact_layout **NEW: "all twelve road/air vehicles registered"**: the check expects 12 drivable vehicles, and commit 4598be7 (drivable warehouse truck) made 13. Not caused by lighting; the check was not changed |
| `capture.gd` (windowed, 1200 × 900) | First run: the sunset sky had a dark blob (the sun halo takes the dim sun's colour) and the Home was dim orange at night (its lifted roof lets the sun light it by day). Fixed: the sun is no longer drawn in the sky; the indoor blend now covers the light too (noon light with shadows under a roof between walls). Re-captured and inspected: `sheet-outdoor.png` (street, aerial, garden at 06:30, 12:00, 17:45, 18:40, 21:00), `sheet-indoor.png` (supermarket and Home at 12:00 and 21:00 look alike), `hud-night.png` (clock and open panel) |

Frame times (`capture.gd`, VSync off, 120 frames after 40; second run, ms):

| View | Noon, paused (median / p95) | Midnight, paused | Sunset running at 1-minute day |
| --- | --- | --- | --- |
| Garden benchmark camera | 14.85 / 18.45 (3,477 draw calls) | 12.77 / 16.88 (3,291) | 16.12 / 19.17 |
| Street | 5.60 / 10.31 (1,454) | 4.19 / 11.31 (853) | 6.96 / 8.03 |

Night is cheaper than day because the sun has no shadows then. Single-frame maxima (21–65 ms)
were scattered and differed between the two runs, including paused views where the cycle
writes nothing, so they were not attributed to it. Earlier garden figure for comparison:
19.7 ms median on 19 Oct (older town).

Not verified:
- A web export: no export presets or Web export templates are installed.
- Other interiors at night (only the supermarket and the Home were rendered).
- A real mouse on the clock (clicks were emitted as signals).
- A full 20-minute run watched live (the running test used a 1-minute day).
- The full suite was not run.

**Second round, same day (user): area menu, multi-select menus, star-only press, touch sizes.**
`vocabulary_book` with graphics (`VT_FOCUS=home`, 1600 × 1000): first run of this round
**96 checks, 0 failures**. Its Spanish render showed the five-control tools row clipping the menu
labels, so the scores button moved to the tab row as a short toggle; second run **96 / 0**.
New checks: ticking one and two categories and areas, All clearing them, By Area showing only
the ticked areas, a real click (viewport input) on a ★ saving without opening the detail, a click
on the word opening it, rows ≥ 56 px and scroll bar ≥ 24 px × scale. `language_check`: **PASS, 3608**.
Inspected `areas-en-es.png`, `table-es-zh.png`, `scores-hidden-en-es.png`. Still clipped by a
letter: the Spanish "Todas las categorías" label at this size. Not verified: an open
multi-select menu on screen (the popups were driven by signals), a real touch screen.

## Web build of the day-night cycle — 9 November 2026

Follow-up to the [day-night entry](#day-night-cycle-and-hud-clock--9-november-2026), which
listed the web export as not verified. Official Godot 4.7.2 export templates were installed
(user approved the 1.28 GB download; SHA-512 matched the release's `SHA512-SUMS.txt`). A new
`export_presets.cfg` has one **Web** preset:
- single-threaded, so it runs on any static server without cross-origin isolation headers;
- leaves out `docs/`, `tools/` and `screenshots/`, and includes `*.json` and `*.txt`.

The export is a 40 MB `.pck` plus a 40 MB `.wasm`. It was served locally and driven in
headless Chrome 156 (throwaway profile) with `docs/evidence/day-night-20261109/web_measure.py`. The
user's Chrome was not used: the Claude in Chrome extension was not connected, and the
built-in browser pane could not be shown.

| Check | Result |
| --- | --- |
| Load | WebGL 2 through ANGLE Metal on the Apple M5 (not software rendering); all 18 of 18 units load; garden and render batching report the same counts as on desktop (2,405 / 241; 15,091 meshes in 3,474 batches) |
| Clock | Pill shows the time with a sun or moon icon. Clicking opens the panel. − ×7 from 7:37 PM gave 12:37 PM (paused, pause icon, "Time paused"); + ×12 gave 12:37 AM (midnight wrap). Resume ran 12:37 → 12:45 in about 7 s (20-minute day). Esc closed the panel and the time kept running. Inputs were real browser mouse and key events |
| Lighting | Noon and midnight at spawn look as on desktop: [web-noon-panel.png](../evidence/day-night-20261109/web-noon-panel.png), [web-midnight.png](../evidence/day-night-20261109/web-midnight.png) |

Frame rate at spawn, 1280 × 800 CSS window, frame cap off (5 s of animation frames):

| Pixel density (canvas size) | Noon: FPS, median / p95 ms | Midnight: FPS, median / p95 ms |
| --- | --- | --- |
| 2× (2560 × 1426) | 58.1, 16.4 / 32.3 | 71.5, 13.6 / 17.1 |
| 1× (1280 × 713) | 132.3, 7.5 / 8.2 | 152.7, 6.5 / 7.2 |

With the browser's normal 60 FPS cap at 2×, the game held 59.8 FPS.

**Finding (priority: high for weaker computers):** the web build renders at the screen's full
pixel density. At 2× this halves the frame rate on an M5, and weaker laptops would be hit
harder. Rendering the 3D at a lower scale on the web (UI text kept sharp) is the likely
biggest single web speed-up. **Done the same day (user: "Yes, add it"):** see below.

Seen, not caused by this work: at spawn the camera sits right behind BonBon's head, so her ears
fill most of the view (not checked on desktop; not investigated).

Limits:
- One view, one machine, headless Chrome only.
- Not tested in Safari or Firefox, on low-end hardware, or with the real user's Chrome.
- The web save (IndexedDB) and the first-load sculpt cache time were not measured.

**Web 3D scale (same day).** Web builds only: `render_culling.gd` `apply_web_3d_scale()` sets the
viewport's `scaling_3d_scale` to 1 / pixel density, never below 0.5, with bilinear scaling. It
re-runs on resize, since browser zoom or a different screen changes the density. The HUD and
text keep full sharpness. Desktop is untouched. Re-exported and measured the same way, at 2×
density (canvas 2560 × 1426):

| Build | Noon: FPS, median / p95 ms | Midnight: FPS, median / p95 ms |
| --- | --- | --- |
| Before, full density | 58.1, 16.4 / 32.3 | 71.5, 13.6 / 17.1 |
| With the web 3D scale | **125.3**, 7.8 / 9.3 | **147.5**, 6.7 / 7.6 |

[web-scaled-noon.png](../evidence/day-night-20261109/web-scaled-noon.png): the clock panel and HUD text are
sharp; the 3D is slightly softer; shadow edges show stair-steps on the road.
`docs/evidence/day-night-20261109/verify.gd` gained "desktop keeps full 3D resolution": **46 checks,
0 failures**.

## Minigame test launcher and the older games on the shared host — 9 November 2026

What changed ([guide](MINIGAMES.md#minigame-picker)): an F9 / corner-button test launcher (debug
builds) starts any game with a chosen number of rounds and records no practice; the shop,
cashier and warehouse sessions now use `minigame_host.gd` (and the warehouse `minigame_zone.gd`),
which gives the cashier the gold "!" it lacked; grammar and mahjong read their rounds from the
activity board; Esc or ✕ on any game's leave question now means "stay".

Run once each through `tools/run_checks.py` (isolated `HOME`, `VT_FOCUS=all`; `dev_focus.txt` = `all`):

| Check | Result |
| --- | --- |
| `minigame_launcher` (new, `docs/evidence/minigame-launcher-20261109/verify.gd`) | **PASS** after one check fix (the warehouse game moves the player into its copy, so "near Ramón" now also accepts `in_game()`): every game launched with 3 rounds, practice paused and both undone afterwards; cashier and grocery clerk "!"; cashier leave question and Esc = stay; two grocery orders in a row |
| `warehouse_game`, `grammar_class`, `police_detective`, `mahjong_table`, `runtime_resources` | **PASS** |
| `language` | NEW at first (four Chinese characters of the new phrases had no reading: 買 閒 載 錄); **PASS** after adding them to `data/pinyin_zh.json` |
| `practice_log` | NEW at first: the check called the shop's old `_on_quit_answered` (now `_on_leave_answered`); the error left the grocery question open and failed the family and warehouse rows after it. Fixed the call; then two warehouse rows still failed because the uncommitted 8 Nov warehouse change shows the next task only after the card's 1.6 s praise, which the check did not wait for. The check now skips the praise (`_warehouse_done()`): **PASS** |

Rendered at 1280 × 800 (`docs/evidence/minigame-launcher-20261109/capture.gd`, with graphics):
[cashier-calling.png](../evidence/minigame-launcher-20261109/cashier-calling.png) shows the cashier's gold
"!" (and the grocery clerk's) and the play-icon button left of the gear;
[launcher.png](../evidence/minigame-launcher-20261109/launcher.png) the window. The first render ran off the
bottom of the screen; padding was tightened and the name column given a minimum width, and the
re-render fits. That last layout change came after the check runs above (it touches only sizes;
not re-run). The graphical capture stalled at start-up in 3 of 6 runs, with or without the
launcher change, before any frame was drawn (recorded, not investigated).

Not run: the full suite. Not covered: the shop and cashier flows by hand in the running game.

**Indoor light fix (same day, user report).** At night, walking into the hospital lit the street
outside the door like noon under a night sky. The cause: the indoor blend set the town's one
directional light to noon strength, colour and shadows. Now only the ambient fill blends
indoors (in about 1 s) and the moon fades; the sun, shadows and sky keep the time of day.
- `docs/evidence/day-night-20261109/verify.gd`: **49 checks, 0 failures**. New: warm fill indoors at
  night, no moonlight or noon sun indoors at night, the sky stays night, the sun is unchanged
  indoors by day.
- `capture.gd` re-rendered. `sheet-indoor.png` gained a third row, looking out of the
  supermarket door: at 21:00 the street outside is dark under a night sky. The supermarket
  interior is unchanged. The Home at 21:00 is darker and lamp-lit (by day its roof opening
  lets the sun in).
- Frame times (ms, median): garden 16.8 noon / 15.7 midnight; street 7.9 / 7.1.
- Not checked: the hospital itself (the user's report), and the web build after this change.

**Sun disc, moon and cloud tint (same day, user report).** The clouds and the sky's sun disc kept
one colour all day, and the disc sat south-east of town while the noon light comes from the
north-east. Both were fixed unshaded spheres in the baked base world. Now the disc follows the
light (sun by day, sinking below the horizon at dusk; pale moon by night) and takes the `disc`
keyframe colour, and the 32 cloud puffs share one material tinted by the `clouds` value
([guide](performance/README.md#day-night-cycle--9-november-2026)).
- `docs/evidence/day-night-20261109/verify.gd`: **55 checks, 0 failures** (first run was a parse error in
  the new check, fixed). New: the disc left the batched town; one cloud material on 32 puffs; the
  disc in the light's direction at noon and midnight; yellow sun and white clouds at noon; orange
  sun and warm clouds at 18:00; the disc set at 18:45; no disc at 19:00; dimmed clouds at night.
- `capture.gd` re-rendered (1200 × 900). `sheet-outdoor.png` gained a fourth row, looking toward
  the sun/moon at each hour. The first render washed the dawn and dusk discs out to cream, so
  their colours were made more saturated and the sheet re-rendered. Inspected: orange disc
  low in the east at 06:30, yellow at noon, orange setting at 18:40, pale moon and blue-grey clouds at 21:00.
  Frame times (garden, median): noon 16.6 ms, midnight 12.5 ms, running sunset 16.8 ms; same
  draw calls as before (the disc and the clouds each had their own material already).
- Not verified: the web build; sunset clouds up close (no view frames them at 18:40); the full suite.

## Hold L to peek at signs in the native language — 9 November 2026

User decision, 9 Nov 2026 ([guide](ARCHITECTURE_REVIEW_PART1.md#vocabulary-data-procedure)):
holding L, or the native-badge button ("EN") left of the gear, shows world signs and
Lexicon-bound labels in the native language until released. Not saved, not a Display
Mode; dialogue, cards and practice recording are unchanged; the button is hidden in
Native mode. The minigame test launcher button moved one slot left.

| Check | Result |
| --- | --- |
| `docs/evidence/peek-20261109/capture.gd` (graphics, `VT_FOCUS=supermarket`, isolated `HOME`, 1600 × 1000) | **15 checks, 0 failures** (L down/up switches the SUPERMERCADO sign and back, Display Mode unchanged and not saved, button down/up, finger-sized badge button, a missed release ends by itself, no button in Native mode). Renders inspected: `foreign.png` (SUPERMERCADO / ENTRADA / MERCADO), `peek-held.png` (SUPERMARKET / ENTRANCE / MARKET), `help.png` (hold L row fits on one line) |
| `tools/language_check.gd` | **PASS: 3818 checks, 0 failed** (after adding the reading of 招 to `pinyin_zh.json`) |

Not run: the full suite (asked first per the verification budget). Not verified: a real
finger or mouse on the button (the capture emits `button_down` / `button_up`), and the
launcher's new position (debug builds only). Known limitation (P3), fixed the same day
([below](#world-signs-in-every-taught-language--9-november-2026)): `sign_language.gd` signs only knew English and
Spanish, so with a native language other than English they stayed in the foreign language while peeking.

## World signs in every taught language — 9 November 2026

User request, 9 Nov 2026 ([guide](ARCHITECTURE_REVIEW_PART1.md#vocabulary-data-procedure)): with Chinese
as the native language, holding L left building and department names in Spanish, and about 45
signs authored in Spanish (hospital floors and rooms, elevator, zoo, vehicles, travel hub,
bakery, clothing) or English (Burger menu boards) never switched at all.
`data/sign_translations.json` now holds every sign in English, Spanish and Chinese (224
entries plus poster glosses and titles); `sign_language.gd` matches authored text in any
language; the elevator builds its words from the table.

| Check | Result |
| --- | --- |
| `docs/evidence/signs-20261109/verify.gd` (headless, `VT_FOCUS=all`, isolated `HOME`; new, full suite `signs`) | **498 checks, 0 failures**: every entry in every playable language, no visible Label3D left uncovered (286 table signs; the rest Lexicon-bound, elevator, letter-free or `_same`), every native/foreign pair of en/es/zh shows the right text both ways (signs, poster glosses and titles, elevator), and holding L with native Chinese turns RECEPCIÓN into 接待處 and back. First run: 1 failure, a minimum count guessed at 300 (actual 286), corrected |
| `docs/evidence/signs-20261109/capture.gd` (graphics, `VT_FOCUS=hospital, school, supermarket`, native zh, foreign es) | Renders inspected: `supermarket` (超級市場 / 入口 / 市場 while held), `hospital-directory` (1 樓 directory), `school-poster` (Chinese meaning lines; MAÑANA as 明天 and as 早上) |

Not run: the full suite, `docs/evidence/peek-20261109/capture.gd` again. Not verified: Chinese sign
wording by a native speaker (Hong Kong Traditional usage, e.g. 的士, 薄餅, 升降機); the
Burger menu boards now show Spanish by default (they were English for everyone).
Older interior checks that read the table as English → Spanish strings
(`spanish-signs-20261027`, the October interior `verify.gd` scripts) no longer apply.

**Full suite after the hold-L peek and the multilingual signs** (`run_checks.py full`, once,
`dev_focus.txt` = `all`, 722 s, working tree with other sessions' uncommitted work):
**32 PASS, 2 KNOWN, 7 NEW**. `signs` PASS; KNOWN as before: `map_facades` 1, `rooftops` 3.
The NEW rows, none traced to the peek or sign change:

| Check | Label | Reading |
| --- | --- | --- |
| `compact_layout`, `zoo_vehicles` | vehicles registered (12 / 10 expected) | Vehicle count grew (drivable warehouse truck `4598be7`, recorded above; uncommitted scooter work) |
| `seats_swan_boats` | airport seats 40/41 | Same gate seat as 8 and 9 Nov (P3) |
| `police_officer` | two police officer word roots: the crocodile and the cat | `crocodile` became a word (`words.json`, recorded above); the check predates it |
| `warehouse_game` | solved: Find the black suitcase and put it behind the medium yellow box | One random task; not investigated (P3, rerun alone next time) |
| `minigame_launcher` | Play is a large target (×11) and a SCRIPT ERROR (`s.host.npc` is Nil at `verify.gd:167`) | The suite window is 1280 × 720, so the launcher's scale is 0.9 and Play is 56 × 0.9 = 50 px, under the check's 52 px; the only peek edit in `game_launcher.gd` is the corner button's position. Recorded PASS earlier today; the Nil host is unexplained (P2: owner of the launcher work) |
| `vocabulary_book` | clicking the star saves… / clicking the word opens the detail | Real viewport clicks were verified with graphics only (`VT_FOCUS=home`); the suite runs headless. The peek button is hidden while the journal is open (P3: make the check graphics-only or headless-safe) |

`vocabulary_report` rewrote `docs/guides/vocabulary-report/report.csv` and `summary.md` (its documented behaviour).
Traced and corrected in the [follow-up below](#follow-up-the-7-new-failures-traced--9-november-2026).

### Follow-up: the 7 NEW failures traced — 9 November 2026

Branch `claude/check-failures-20261109-c54527` (its own worktree; another session's police,
sports, furniture and restaurant interior work is not in it). `dev_focus.txt` = `all`; Godot
4.7.2; isolated `HOME`. Two readings in the table above were wrong: the police failure is a third
officer, not the crocodile word, and the suite window is not 1280 × 720 — **headless Godot has a
64 × 64 root viewport that cannot be resized** (probed: `root.size = 1280 × 720` has no effect),
so the launcher's scale clamps to 0.5 and the journal's real clicks land outside the viewport.

| Check | Cause | Change |
| --- | --- | --- |
| `compact_layout`, `zoo_vehicles` | Out-of-date count. Probe of `driveable_vehicles` (full town): **13** = helicopter, turboprop (fixed-wing), `Vehicles/` Car, Truck, Bus, Taxi, Police_Car, Ambulance, Fire_Truck, Motorcycle, plus SchoolBus, SubaruOutback (Subi) and `Warehouse/Exterior/Delivery truck`. The scooter is the restyled `Vehicles/Motorcycle`, not an extra vehicle; the warehouse truck (8 Nov) is the only addition | Expect 13 / 12 non-fixed-wing, named in a comment; `compact_layout` prints the paths when the count differs |
| `police_officer` | Out-of-date. Three roots carry *police officer*: the crocodile, the cat and the beagle receptionist `RelocatedSites/Police/ReceptionOfficer` (`police.gd` step `reception_officer_chairs`, 8 Nov). The crocodile still teaches *police officer* | Expects the three by node |
| `vocabulary_book` | Check, headless only: the clicks at (49, 167) and (120, 169) fall outside the 64 × 64 viewport (diagnostic run, `VT_FOCUS=home`: nothing hovered, both clicks dropped). Not the peek button | The three real-click checks run only with graphics (prints a skip line headless); the star toggle via `pressed` and the touch-size row check still run headless |
| `minigame_launcher` (Nil host) | Check: Radar Patrol has no NPC host by design (`radar_patrol_session.gd` `host = null`; the launcher calls its `launch()`), and it has no `end_activity()` | Host-less sessions: only `radar_patrol` may have no host; it ends by closing its screen |
| `minigame_launcher` (Play ×11) | Game, touch rule: the buttons were 56 × scale with no floor (50 px at 1280 × 720, 28 px headless) | **Game fixed:** `game_launcher.gd` `_layout` floors Play, −, + and close at 52 px (like the corner button). The check now reads the minimum sizes for Play, − and +, and with graphics also checks that the window fits the screen |
| `warehouse_game` | Not reproduced. The failing task (round 0, third task) left the suitcase at the check's own "behind" spot x = 14.01 (box at the bay centre 13.0 + 0.46 + 0.40 + 0.15; the wall face is at 14.7, so there is room) but 0.29 above the floor (rotation is locked), i.e. resting on something or still falling. The check's `spot_for` tries one "behind" spot only, so an earlier task's leftover blocks it; a player has room beside it (the area is 1.48 m wide). Read as a random check-side failure, not proven | No fix. The "not solved" line now also prints the item's velocity, `on_floor` and the goods within 1.5 m, for next time |
| `seats_swan_boats` | Not touched (P3, as before) | — |

| Run | Result |
| --- | --- |
| `run_checks.py --only compact_layout,zoo_vehicles,police_officer,vocabulary_book,minigame_launcher,warehouse_game --jobs 2` (headless, once, final code) | **PASS 6**: compact layout 642 checks / 0; zoo and vehicles 106 / 0; police officer 15 / 0; vocabulary book 93 / 0 (real clicks skipped headless); minigame launcher 155 / 0, no SCRIPT ERROR; warehouse game 276 / 0 (random tasks; no "behind" goal failed) |
| Launcher render, graphics, 1280 × 720, full town (scratch script) | Scale 0.9; every Play 112 × 52 (the two three-line police rows 75 tall), − / + / close 52; window 902 × 641 at y 39.5, fits with no scroll bar; inspected, nothing clipped |

Not run: the full suite, the vocabulary book's real clicks with graphics (last verified with
graphics, `VT_FOCUS=home`, 9 Nov), `docs/evidence/minigame-launcher-20261109/capture.gd`. No entries were
added to `data/expected_check_failures.json` (every failure here is fixed or unproven).

## Mystery House and Mystery Doors — 9 November 2026

User request, 9 Nov 2026 ([design](TOWN_DESIGN_BRIEF.md#mystery-house-and-mystery-doors--9-november-2026),
[game](MINIGAMES.md)): a new building, *La Casa de las Estrellas* (unit `mystery`, 24 × 30,
south of the bank), with Madame Luna's Mystery Doors game (colours and shapes, a toad for 2 s
after a wrong door). The door wall follows the user's door reference image.

| Check | Result |
| --- | --- |
| First targeted run (`run_checks.py --only` with the new and touched checks, isolated `HOME`, `dev_focus.txt` = `all`) | `runtime_resources`, `vocabulary_categories`, `vocabulary_translations`, `signs`, `building_lookup`, `vocabulary_report`, `practice_log` PASS; `language` NEW (14 Chinese characters without pinyin, added to `pinyin_zh.json`, then PASS); `mystery_house` CRASH (a parse error in the new `verify.gd`, fixed); `minigame_launcher` NEW ×12: the known 1280 × 720 "Play is a large target" rows (×11 above, one more for the new `mystery_luna` row) and the Nil-host SCRIPT ERROR at its `verify.gd:167`, unchanged |
| `docs/evidence/mystery-house-20261109/verify.gd` (new, full suite `mystery_house`) | Second run: 3 failures from the test itself (it waited for the next round while the fade was still running, when the session correctly ignores doors) and a SCRIPT ERROR that followed from them; waits fixed. **Final run (once): 60 checks, 0 failures**: building (Luna, 3 doors with word `door`, painted leaf and head, 4 symbols, a 3-cornered triangle, roof over the room, map site and entry, zone `mystery_house`, room name), round rules (6 rounds shape → colour → both, 300 random rounds always one answer, clue in es/en/zh), locked doors outside a game, a wrong door (toad 2 s, clue again with highlighted key words, no progress), right doors (open, walk, next round), first-try counting, leave (button No, doorway Yes), the final line and Finish, a language change while a toad |
| `docs/evidence/mystery-house-20261109/capture.gd` (graphics, `--always-on-top`, `VT_FOCUS="mystery, bank, library"`; 15 views in three batches) | Render fixes: the triangle symbol was a diamond (a CylinderMesh keeps ≥ 4 sides; now a prism); the dome's flat base hid the starry interior (opened); lanterns rendered white (warm glow); the card covered the HUD clock (moved down); the hall cameras were blocked by the entrance door (moved). Last batch inspected: `front`, `room-doorwall`, `room-dome`, `game-card`, `game-toad` |

Not run: the full suite. Limitations: no sounds yet (door and toad cues are played only when
they exist); the toad only hops; lanterns are emissive, not lights; the house's south-west rear
corner reaches the beach sand (`site-top`); in the captures the HUD room name reads "Front
yard" because Main's process is off there (the room name is checked in `verify.gd` instead).
`vocabulary_report` rewrote `docs/guides/vocabulary-report/report.csv` and `summary.md`.

**Endless hall and the hopping toad (user change, same day).** The right door now leads on
through a straight hall of identical rooms (built hidden under the house; the player is moved
back one room once the door has shut behind them), the door behind says `mystery.no_way_back`,
and the toad hops about. New bake step `endless_hall` in `mystery.gd`, baked on the committed scene
(3,646 nodes, 3.3 MB; was 1.8 MB). The checks and renders below first ran on a from-scratch bake
that produced the same 3,646 nodes; `mystery_house` ran once more on the step bake: 77 checks,
0 failures.

| Check | Result |
| --- | --- |
| `run_checks.py --only mystery_house,language,runtime_resources` (once, isolated `HOME`, `dev_focus.txt` = `all`) | **3 PASS.** `mystery_house` **77 checks, 0 failures**, now also: the hall hidden with three door walls, a solid floor and ceiling, zone `mystery_house`; the toad can move and hops (fast in the air, still between hops, normal speed after); the right door into the hall (the door used behind, the next round ahead, the mystery room's doors reset); the door behind rattles with `mystery.no_way_back`; the next room pre-dressed; the slam once well into the next room; the step back is exactly one room and the camera keeps its offset; leaving from the hall back to the mystery room; the arch leave question; a two-door game ending back with Luna |
| `capture.gd` (graphics, `--always-on-top`, `VT_FOCUS="mystery, bank, library"`; 20 views, once) | New views inspected: `hall-ahead`, `hall-behind`, `hall-open` (the next room through the door), `hall-toad-hop`, `hall-after-step` |

Not verified: the seamlessness of the step back by eye in motion (the check compares positions
and the camera offset; the stills match), touch movement while a toad (the hop reads the same
movement input as walking). Not run: the full suite.

**Second change (user, same day): start in the hall, one door behind, hinges on the right.**
New bake step `hinges_right`; `endless_hall` (not yet committed) now builds a "Back" trim and a
solid "Back cover" per door; both baked on the committed scene (3,682 nodes). The game starts in
the hall with the mystery room's doors as they were for round 1; those doors get a new look when
the player leaves the house. `run_checks.py --only mystery_house` (isolated `HOME`,
`dev_focus.txt` = `all`): first run **78 checks, 4 failures**, all test timing (the room check
runs on process frames, the test waited physics frames; the toad's speed was first set a frame
late, now set as it appears: a real fix); second run **78 checks, 0 failures**. `capture.gd`
once: `game-card` (the room's doors in the hall), `hall-behind-start` and `hall-behind` (one door
behind), `hall-open` (right-hand hinge, opening away), `game-toad`, `hall-after-step` inspected.

**Third change (user, same day): the treasure ending.** After the last door a treasure chest with
a diamond; opening it (E or a click) plays the shake, the surge with a rainbow ray and the
diamond's disappearance, the chest stays open, one far door opens and leads (a fade) out of the
matching mystery-room door, and Luna thanks the player when spoken to. `endless_hall` (not yet
committed) now also builds `Treasure` and an exit alcove; baked on the committed scene (3,744
nodes). New `scripts/world/treasure_chest.gd`; `interaction_controller.gd` aims at a non-word
`click_use` object and shows its `label_phrase`. `run_checks.py --only mystery_house` (isolated
`HOME`, `dev_focus.txt` = `all`): first run **90 checks, 1 failure** (the test checked the exit
door before it had swung open; now waits), second run **91 checks, 0 failures**, now also: the
treasure shown only in the last room, the chest solid and not a vocabulary word, `use` opens it,
the ray appears and the diamond goes, the exit door opens, the player comes out of the matching
mystery-room door, the room's doors take the exit wall's looks, Luna calls with the "!", the
final line thanks. An earlier `language` run in this work reported NEW: the `zh` pinyin table lacks
修, from another session's electrical-box text (not this work; 鑽 was added for this work).
`capture.gd` once (25 views): `treasure-chest`, `treasure-surge` (rainbow beams behind the rising
diamond), `treasure-open` (empty open chest, exit door open), `room-return` (out of the mystery
room's middle door) inspected. Not verified: the animation's timing by eye in motion. Not run:
the full suite.

**Talk camera on Luna (user, 10 Nov 2026).** The dialogue box covered Luna's face: the talk
camera measures the face from the NPC's top, which her tall wizard hat raises. `npc_presence.gd`
now reads an optional NPC meta `talk_face_drop` (the hat's height, NPC-local); the session sets
0.6 on Luna (`LUNA_HAT_DROP`). Other NPCs are unchanged (no meta). Render at 2000x1200
(scratch script, `VT_FOCUS=mystery`): her face and hat sit above the box. `mystery_house` not
re-run for this.

**Zodiac plaques (user, 10 Nov 2026).** The twelve constellations redrawn from the user's chart
(`ZODIAC` holds the chart's pixel points) with an English nameplate under each; new bake step
`zodiac_signs` replaces the mystery room's plaques (0.8 size, raised so the plates clear the
windows); the hall's four use the same builder. Baked on the committed scene (3,950 nodes).
Scratch render (`VT_FOCUS=mystery`): both room walls and a close-up inspected; the first try
overlapped the window arches, fixed by the size and height. The names stay English after
`SignLanguage.set_language` es and zh (all 20 labels). `run_checks.py --only mystery_house,signs`
(once, isolated `HOME`, `dev_focus.txt` = `all`): **2 PASS** (the names are listed in `_same`).

**Door backs and nameplates (user, 10 Nov 2026, after the combined render review).** The door
back now has plank grooves into the arch head and an arched head rail with an iron band and gold
nails. Found while doing it: `_merged` dropped every non-indexed part (arcs, stars) appended after
an indexed one, so the doors' arch borders and star bosses and the back surround's stone arch had
never rendered; every part is now de-indexed first. The nameplates are larger and bolder. Baked
on the committed scene (4,330 nodes). `capture.gd` three times while fixing (door back, front and
open views, room corner inspected; the last run shows the star bosses, the stone arch round the
back and the iron band); `run_checks.py --only mystery_house,signs` once (isolated `HOME`,
`dev_focus.txt` = `all`): **2 PASS**, mystery_house 117 checks and signs 500 checks, 0 failures.

**Arch closed mid-game (user, 10 Nov 2026).** The player got out mid-game with the quit question
showing: `ask_leave` turned the controls off, but nothing told Main's `sync_player_controls` that
the game was paused, so the next refresh turned them back on. Now an invisible wall fills the arch
during a game (not at the final stage), and a zone on the room side asks the question; leaving the
zone takes it away. `mystery_house` (isolated `HOME`, `dev_focus.txt` = `all`): first run **121
checks, 1 failure** (the new step-back check waited only physics frames; the session checks on
process frames), then **121 checks, 0 failures**. New checks: the arch is closed mid-game
(`test_move`), stepping up asks while the player can still move, stepping back removes the question
and the game goes on, and the arch is open at the final stage. Not tried in the running game by
hand; no render (nothing visible changed).

**Walking out at the final stage (user, 10 Nov 2026).** Reported: after the diamond, walking
out kept the player in the game. Reproduced (scratch test): the arch only reacted in `choose`, so
in `return` the game, its "Go back to Madame Luna" card and Luna's "!" stayed on (other games
blocked) until the player went back to her. Now the arch in `return`/`over` finishes like Finish
(`ask_leave` → self-closing `mystery.finished`, the result line skipped); mid-game it still asks.
New checks: a one-door game walked out through the real doorway (no question, only the goodbye,
card gone, no "!", no blocker, player not put back) and the mid-game arch question with No.
`run_checks.py --only mystery_house` (isolated `HOME`, `dev_focus.txt` = `all`): first run
**98 checks, 4 failures**: 3 toad-timing rows from another session's toad changes then in
progress, and 1 from the new test, which read the goodbye after walking on 3 m (the panel's
walk-off had closed it; now read when the game ends). Second run **107 checks, 0 failures**
(the other session had updated the toad checks meanwhile). Not verified by eye in the game.

**Slower toad change, longer toad (user, 10 Nov 2026).** Each change now takes 0.95 s (was a
0.2 s wait and an instant swap; `PUFF_SECONDS`): the old shape shrinks in the smoke for the first
half, the models swap at the middle, the new one pops up in the second half (`_change_tick`), with
controls locked; the puff lasts 1.2 s. The toad lasts 3 s (`TOAD_SECONDS`, was 2). `verify.gd` now
times each part (change in, toad, change back) and checks the shrinking, the locked controls and
the full-size player afterwards; `capture.gd` adds a `game-toad-change` view (not rendered this
time). `run_checks.py --only mystery_house` (once, isolated `HOME`, `dev_focus.txt` = `all`):
**107 checks, 1 failure**, all toad checks passing; the failure, "only the self-closing goodbye
()", is the new walk-out-at-the-final-stage test that another session was changing at the same time.

**Door pacing, door faces, room lighting (user, 10 Nov 2026;
[design](TOWN_DESIGN_BRIEF.md#mystery-house-and-mystery-doors--9-november-2026)).** Pacing:
`_walk_tick` shows the next clue (or the treasure line) once the player is 0.5 past the wall and
slams when the leaf's swing is clear of them (`_clear_of_leaf`), no longer waiting for the camera.
Door faces: new step `door_faces` (both leaf faces, merged meshes; the hall's back surround).
Lighting: probed `day_night._probe_indoor` on a grid of the room (scratch script, `VT_FOCUS=mystery`):
before, the up-ray hit a roof only under the dome (the deck's upward one-sided trimesh is not hit
from below), so the rest of the room took the outdoor night ambient — the user's two screenshots;
new step `room_ceiling` (a box collider above the ceiling, no mesh or light): after, every grid
spot in the hall and room reads roof + at least 3 walls. Baked from the committed scene with all
uncommitted steps (another session's `room_twin` included; 4,330 nodes).
| Check | Result |
|---|---|
| `run_checks.py --only mystery_house,signs` (once, isolated `HOME`, `dev_focus.txt` = `all`) | `signs` **PASS** (500, 0 failures). `mystery_house` **NEW, 23 failures**: 4 from this change's own expectations (each leaf now has 3 painted meshes, not 2: `verify.gd` updated to 3, not re-run); 19 from "the game starts in the endless hall" on, which match the start-in-place change another session ("Mystery Doors: start in Luna's room, no teleport") was making to `mystery_session.gd` and `verify.gd` during the run, so this change's pacing checks (card praises → next clue at past + 1.0 with the door still open → slam at past + 2.8) did not get a valid run. **Re-run once both changes are in.** |
| `capture.gd` (graphics, `--always-on-top`, `VT_FOCUS="mystery, bank, library"`, once) | Stopped after `treasure-through-door` (no error printed; the game flow it drives was being changed by the same session). Inspected: `room-doorwall` (new fronts: straps, panels, kick plates, star bosses on all three colours), `hall-behind` (a door back in game), `pacing-through` (just through the doorway: the card already shows round 2's clue, door still open), `pacing-slam` (the door swinging shut behind the player). |
| Scratch stills (the stills list now at the end of `capture.gd`, `VT_FOCUS=mystery`, after one fix) | First renders: the back's ledges and braces vanished in the leaf colour; added translucent dark edge lines (`Leaf batten shadows`), re-baked. Inspected: `door-back` (ledged and braced, straps, ring pull, bolt, kick plate, stone arch and pilasters), `door-back-open`, `night-room-corner` (1 a.m., the user's screenshot spot) identical to `day-room-corner` (noon); indoor = 1.0 at every view. |
Not verified: the pacing in the running game by hand; the full `mystery_house` run on the final code.

**Leaving mid-game goes to Luna's table (user, 10 Nov 2026).** "Yes" to the quit question
mid-game (card button, Esc or the arch; from the hall or the room; now also while a toad) fades
the player to `Mystery.GUEST_SPOT`, across the fortune table from Luna and facing her (a toad is
turned back first), and she says the new `mystery.sorry_leave` (es/en/zh; pinyin `得走` děi zǒu
added). "No" and finishing a won game are unchanged. New `verify.gd` rows: leaving from the hall
and as a toad each end across the table, clear of it, facing Luna, with the line said; a toad
can ask to leave. `run_checks.py --only mystery_house,language` (isolated `HOME`,
`dev_focus.txt` = `all`): `language` PASS; `mystery_house` **111 checks, 27 failures**. The new toad
row had not made a real toad, because the game now starts in Luna's room. The row was fixed
(it uses the current round's doors) and the check re-ran `mystery_house` once: **112 checks, 27
failures**. All the new rows pass. The 27 failures come from other sessions' changes that
were in progress at the same time: the game starting in the mystery room (`the game starts in
the endless hall` and the toad, miss and first-try rows that follow from it), the doors'
painted parts (3, was 2) and the final-stage walk-out rows. I did not fix them here. Rendered
once (scratch script, `VT_FOCUS=mystery`): the arrival view shows the player across the crystal
ball from Luna with her goodbye.

**The game starts in place; a seamless swap at the first right door (user, 10 Nov 2026).** Yes
(and Play again) starts round 1 where the player is, with no fade or move. The round uses the
mystery room's own doors. At the right door the player and camera are moved in the same frame
to the same spot before the hall's wall B, whose matching door opens
(`mystery_session.gd` `_ready_hall`, `_swap_into_hall`, `_room_round`). New bake step
`room_twin` (baked on top of the scene: `bake_unit.gd -- mystery`, 1 step, 4,318 nodes)
removes the hall's runner (word `carpet`), plaques, sconces, cornice and skirting, and dresses
each hall room's door end like the mystery room's: the inside windows, a sconce, the room's
constellation plaques, and the zodiac wheel cut at the wall behind. `verify.gd` adds these rows:
the start in place, round 1 at the room's doors, the hall ready below, the swap offset exact,
the camera keeping its offset, the room door staying shut, a one-door game swapping, and Play
again in place. `run_checks.py --only mystery_house` (once, isolated `HOME`, `dev_focus.txt` =
`all`): **PASS, 117 checks, 0 failures**. Rendered once with `capture.gd` (`VT_FOCUS="mystery,
bank, library"`): `swap-before` and `swap-after` look the same apart from the door starting to
open, and the toad, step-back and treasure views look right. Not matched: the dome
and Luna's corner behind the player (only seen if the camera looks up or back at that
instant). The hall's room label read "Front yard" in this capture both before and after the
swap; this was not investigated (P3).

## Interiors polish — 9 November 2026

Sports store, Pizza and Burger, furniture store and police station
([record](TOWN_DESIGN_BRIEF.md#interiors-polish--9-november-2026)); branch
`claude/interiors-polish-11e6ea`, commits 390a5e9, 414a101, 0ac53d9, 8f77b96 and the docs commit.
Each building was audited with `docs/evidence/interiors-polish-20261109/audit.gd --rays --loose` after its
bake (`VT_FOCUS` listing the audited units). Final checks were run once at the end, with
`dev_focus.txt` = `all`:

| Check | Result |
| --- | --- |
| `docs/evidence/interiors-polish-20261109/verify.gd` (new) | 8 PASS, 0 FAIL (every word root clickable except the police entrance mat, locker apples and lineup door; all earlier word keys present) |
| `run_checks.py --only runtime_resources, language, interaction, police_interior, police_detective, police_officer, signs, building_access, map_facades, vocabulary_report, hospital_remodel` | 8 PASS, KNOWN 1 (`map_facades`), NEW 2 (below) |
| `police_officer` NEW | "two police officer word roots" — already recorded above (the crocodile became a word); not this work |
| `signs` NEW | "table signs found": 276 labels, under the 280 floor. Caused by the sports refit (the 28 Oct department signs, some double-sided, replaced by seven wall signs; Pizza and Burger gained ORDER HERE and DRINKS). Every sign is in the table; the floor was lowered to 270 (`docs/evidence/signs-20261109/verify.gd`) and the check was not re-run |
| `docs/evidence/shop-staff-20261101/verify.gd` | 3 FAIL: banker, golden and sheep salespeople "stand inside a fixture or wall"; the same three failed before the polish (the banker's building is untouched) — P3 |
| `docs/evidence/furniture-interior-20261029/verify.gd` | no FAIL before a SCRIPT ERROR at its last line (`table["DINING"]=="COMEDOR"`: reads the sign table in its pre-multilingual format, see above); the process hung and was stopped |
| `docs/evidence/restaurants-20261028/verify.gd` | FAIL "police interior/exterior children preserved (144)" and "police clear of the loop sidewalk and supermarket lot" (the 6 Nov police enlargement changed both), then the same sign-table SCRIPT ERROR (line 76); stopped |
| `docs/evidence/sports-interior-20261028/verify.gd` | not run: superseded by the refit (it checks the old fixture layout) |

`vocabulary_report` rewrote `docs/guides/vocabulary-report/report.csv` (more locations for chair, basketball, dumbbell,
french fries and other words now taught by every copy).
Renders: before/after views in `docs/evidence/interiors-polish-20261109/` (captured with graphics,
`VT_FOCUS` limited to the five buildings). Open issues: the October interior checks' sign-table
reads (P3, owner of the sign work); the police entrance mat is unreachable under the threshold (P3).

**Sports second pass (same day, step `second_pass`).** Run once after the bake, `dev_focus.txt` = `all`:
`run_checks.py --only runtime_resources, interaction, signs, building_access, vocabulary_report`: 5 PASS
(`signs`: 290 labels, the hanging signs added 14). `docs/evidence/interiors-polish-20261109/verify.gd`: 8 PASS.
`docs/evidence/shop-staff-20261101/verify.gd`: the same 3 FAIL as before (P3). Renders `pass2-sports-*` inspected.

## Full suite after merging the interiors and check-failure branches — 9 November 2026

Main after `5bedf67` (mystery house snapshot), the
[interiors polish](#interiors-polish--9-november-2026) merge and the
[7-failure follow-up](#follow-up-the-7-new-failures-traced--9-november-2026) merge.
`python3 tools/run_checks.py full`, run once, headless, `dev_focus.txt` = `all`, isolated `HOME`, 757 s:
**PASS 39, KNOWN 2, NEW 1.**

| Check | Result |
| --- | --- |
| `map_facades` | KNOWN (1), as before |
| `rooftops` | KNOWN (3), as before |
| `seats_swan_boats` | NEW: airport seats 40/41, the same gate seat as 8 and 9 Nov (P3, untouched by both branches) |
| Every other check (39) | PASS, including the six checks updated by the follow-up, `signs` (after the sports second pass), `police_officer` (the reworked police station plus the follow-up's three-officer expectation), `mystery_house` and `warehouse_game` |

`vocabulary_report` rewrote `docs/guides/vocabulary-report/report.csv` and `summary.md` (committed with this record).
Not run in this pass: the graphics-only checks (vocabulary book real clicks, launcher capture) and
the October building verifies listed under the interiors polish.

## Coplanar faces across the town — 10 November 2026

Design and fix: [design brief](TOWN_DESIGN_BRIEF.md#coplanar-faces-across-the-town--10-november-2026).
Bakes: every unit with `coplanar_gaps` (1,599 faces moved), every unit again with
`coplanar_gaps_2` (pass 2; see the doubled Mystery House gaps in the brief), then the
supermarket with `coplanar_envelope`. `dev_focus.txt` = `all` throughout, isolated `HOME`.

| Check | Result |
| --- | --- |
| `docs/evidence/coplanar-scan-20261110/scan.gd` before | 2,423 visible pairs, 386 m² |
| `docs/evidence/coplanar-scan-20261110/scan.gd` after | 387 pairs, 14 m² (295 runtime or prefab on both sides, 92 signs and icons sized at load) |
| `run_checks.py --only runtime_resources, language, compact_layout, part2, public_garden, building_access, interaction, map_facades, hospital_remodel, barn, police_interior, warehouse, rooftops` | PASS 10, KNOWN 2 (`map_facades` 1, `rooftops` 3, as before), NEW 1: `building_access` "market exact external wall envelope" (the back wall's top raised 5 mm). Fixed by `coplanar_envelope`; `building_access` re-run alone: PASS |
| Flicker renders (`docs/evidence/coplanar-scan-20261110/flicker.gd`, six camera positions 0.2 mm apart, changed pixels in magenta) | Changed pixels before → after: hospital roof band 28,104 → 462 ([before](../evidence/coplanar-scan-20261110/before-hospital-parapet.png), [after](../evidence/coplanar-scan-20261110/after-hospital-parapet.png)); Mystery House name sign 252,477 → 732 ([before](../evidence/coplanar-scan-20261110/before-mystery-sign.png), [after](../evidence/coplanar-scan-20261110/after-mystery-sign.png)); bakery hutch 433 → 428 and Pizza and Burger wall base 225 → 374 (the views do not frame those faces well; edge aliasing and a different time of day, `*-bakery-hutch.png`, `*-pizza-wall-base.png`); bridge pier 3,852 → 3,910 (camera inside the railing, not evidence; not kept). Electronics theatre (30) and warehouse wall base (492): before only, the after run stalled (off-screen window) and was not repeated |

Remaining pairs after the fix: `docs/evidence/coplanar-scan-20261110/remaining-pairs.tsv` (move_a/move_b ≠ 0
marks pairs a later bake would still move). The render script turns vsync off: a window behind
others drew one view in ten minutes; even so, runs after the first view or two stalled, so views
were taken two per process. The after view of the hospital shows a saw-tooth shadow edge under
the band (shadow-map aliasing, static; not counted as flicker). Before views were drawn from an
APFS clone of the project with the scenes as they were before this work.
**Hospital rebake (same day).** A parallel session had put `scenes/town/hospital.scn` back to git HEAD
before the second bake (the cause of the doubling there). The scene went back to HEAD again and
`bake_unit.gd -- hospital` ran alone: pass 1 moved 190 faces, pass 2 moved 2. Scan after it: 397
pairs, 9.4 m² (no hospital pair left that a bake can move). `run_checks.py --only hospital_remodel,
hospital_departments, elevator_call_button, building_access`: 4 PASS. The hospital render views above
were drawn before this rebake.

Not run: the full suite and the other building verifies; the parallel sessions' checks
(mystery house, elevator call buttons) were not run by this work.

## Minigame names, the player-facing picker and the HUD layout — 10 November 2026

What changed (user decisions this day): short game names in three languages
([names](MINIGAMES.md#minigame-index); Radar Patrol translated too), the ▶ picker made a player
feature with tiles, tabs and a detail bar, games played from it recording practice
([guide](MINIGAMES.md#minigame-picker)), and the HUD layout (bigger minimap that opens the map,
place line under it, controls text hidden, bottom-right cluster;
[layout](ARCHITECTURE_REVIEW_PART1.md)). `dev_focus.txt` = `all`, isolated `HOME`.

| Check | Result |
| --- | --- |
| `run_checks.py --only runtime_resources, language, compact_layout, part2, public_garden, minigame_launcher, vocabulary_book, practice_log, electrical_box, radar_patrol_rules` | 7 PASS, 3 NEW: `language` (12 new characters without pinyin; added), `minigame_launcher` (the check expected only Radar Patrol without an NPC; the electrical box is the second, its check fixed), `vocabulary_book` (book-left-of-gear position check; now checks the cluster slot) |
| Same three after the fixes, plus `runtime_resources` (after the dialogue-box change) | 4 PASS |
| Rendered views (scratch capture: HUD at 1100 × 800 and 1280 × 720, picker in English, Chinese, Spanish and the "Just for fun" tab, full map) | Picker fits and centres at both sizes; first-open sizing, the shade and drawing under the clock fixed after the first capture |

Not run: the full suite, `docs/evidence/ui-settings-20261104/verify_town.gd` and
`docs/evidence/language-ui-20261104/verify_town.gd` (not in the runner; the first had its position check
updated). Not seen rendered: the dialogue box with the cluster (help and ▶ now hide under it,
from its 16–84 % width rule), sprint and hyper lines, a picker game started by tapping Play,
and Radar Patrol's translated title on its arcade screen (system-font fallback for Chinese;
web builds untested).

### Button sizes and closing menus by moving — 10 November 2026 (later)

User: buttons 2.8 × larger, the bottom-right ones one size, the top-right ones smaller; the
picker, F1 help, map, journal and Settings close when the player moves (W, A, S, D, Space).
Built as a 2 × 2 cluster of 168 px buttons at 1100 × 800 (`CLUSTER_SCALE`), top-right 90 px
(`TOP_SCALE` 1.5); any cluster button the NPC dialogue box overlaps hides while it shows.

| Check | Result |
| --- | --- |
| `run_checks.py --only runtime_resources, compact_layout, minigame_launcher, vocabulary_book` (the launcher check now presses W, Space and D on the open menus and compares the slot sizes) | 4 PASS |
| Rendered views (HUD at 1100 × 800 and 1280 × 720, with an NPC dialogue line, picker) | Cluster and top buttons as specified; with the dialogue box all four cluster buttons hide (it overlaps the journal by 8 px at 1100 wide) |

Not checked: a real key press in a window (the check calls `_unhandled_input` directly), and the
journal's search field keeping W/A/S/D while focused.
Then (user, same day, after seeing 168 px): `CLUSTER_SCALE` 2.0, 120 px at 1100 × 800; checked
by one more rendered HUD view only (the checks compare sizes, not the factor).

### Mystery house and warehouse entrances walkable — 10 November 2026 (later)

User: a step at the open doors of the mystery house and the warehouse blocked walking in (the
player had to jump). Found by walking the real player capsule (`move_and_slide`) straight in:
the mystery house's invisible step ramp ended 0.48 high where the plinth (0.6) starts, a 12 cm
lip at local z −15.5; the warehouse reception floor edge stood about 0.19 above the lot at the
entrance (local z 0) with no ramp. Fixed by baked steps: `mystery.gd` `entry_ramp` (the ramp
collider now runs through the step nosings and ends 5 cm onto the plinth; visible steps
unchanged) and `warehouse.gd` `entrance_ramp` (a visible 2.8 m wide concrete ramp, about 10°,
from the lot to the floor).

| Check | Result |
| --- | --- |
| Scratch walk probe (`VT_FOCUS=warehouse,mystery`, isolated HOME; three lanes per door, x 0 and ±1 / ±0.6) | Before: all six lanes stopped at the lip. After: all six walk through the open doors into the hall / reception (lanes off centre graze the open leaves / jambs and slide past) |
| Rendered views (noon: warehouse entrance, mystery steps) | Warehouse ramp shows as a low grey threshold under the door, mostly covered by the path; mystery steps look as before |

Not run: the full suite or the mystery and warehouse verify scripts; the walk was probed with
scripted movement, not keyboard play in a window. The probe was a scratch script and was not
kept.

### Mahjong: no corner buttons at the table, visit scoreboard — 10 November 2026

User: hide the bottom-right buttons during mahjong; keep a score for the visit that resets when the
player leaves ([guide](MAHJONG.md#flow)). `vocabulary_hud.gd` `cluster_off`; the points rule moved
from the lesson panel to `mahjong_rules.gd` (`points_for()`, `balances()`) so the lessons and the
scoreboard share it.

| Check | Result |
| --- | --- |
| `docs/evidence/mahjong-20261109/play.gd` with graphics, `VT_FOCUS=home`, isolated `HOME`, 1280×800 (adds: cluster hidden at the table, visit points zero-sum and on the result card, cleared with the buttons back after leaving) | **102 checks, 0 failures**; 4 hands, 2 won, visit points [0, 0, -12, +12] |
| Renders `game.png`, `result.png` | No cluster at the table; "Tus puntos" on the status card; "Puntos de esta visita" with totals and the hand's change on the result card |

Not run: `verify.gd` (logic), `language` and the full suite. Only the home unit was loaded.
A run of the same check before this one was cut short by an output filter, not by a failure.

## Static lion blueprint display — 10 November 2026

Scope: additive zoo display only; [ownership/design](TOWN_DESIGN_BRIEF.md#static-lion-blueprint-display--10-november-2026).

- Saved-base inspection before editing: existing zoo lion and other animals present; all
  existing base steps applied. No gameplay behavior edited.
- `docs/evidence/town-checks/check_runtime_resources.gd`: **460 resources, 0 failures**. The updated authoring
  script also compiled and generated its asset successfully after the shading refinement.
- `tools/build_lion_blueprint.gd`: **86 static mesh parts**, successful packed-scene save.
- `tools/bake_unit.gd -- base`: **one step**, successful save; no other unit baked.
- `tools/compare_scenes.gd -- /tmp/vt-lion/base-before.scn res://scenes/town/base.scn`:
  **11,874 → 11,961 nodes, 88 differences**: the display root and 86 meshes added, plus
  the root's applied-step record. No existing-node removals or other reported changes.
- `docs/lion-blueprint-20261110/capture.gd`: graphical exit **0**; front, three-quarter,
  side, rear, real-town close-up and entrance overview rendered. Inspected the model and
  clear placement beside the entrance. Full town **19/19 units**, isolated test HOME,
  `VT_FOCUS=all`, `VT_SPAWN=none`. The display has no script; the original lion retains
  `park_animals.gd`. First standalone views exposed hard shading and obscured ears;
  corrected and rendered the final batch. Runtime static batching adds its own helper.
- `dev_focus.txt` temporarily read `all` for final rendering; restored the user's original
  `all` plus `spawn=airport` afterward. No learner saves used. No commit.

Limits: visual resemblance is approximate; full gameplay/vehicle/metadata suites were not
run and their recorded issues remain. Existing legacy material `specular` warnings appeared
on scene load; headless runs also emitted the macOS certificate warning.

## Clay lion display — 10 November 2026

Scope: additive zoo display only; [design](TOWN_DESIGN_BRIEF.md#clay-lion-display-second-build-for-comparison--10-november-2026).

- `tools/build_lion_clay.gd`: **72,864 triangles**, saved `scenes/animals/lion_clay.scn`.
- `tools/bake_unit.gd -- base` (isolated HOME): **one step** `lion_clay_display`, save OK,
  11,967 nodes. Run while another session's chapel bake was still running; that bake writes
  only `chapel.scn`.
- `tools/compare_scenes.gd` before/after base: **11,961 → 11,968 nodes, 8 differences**: the
  display root, its four meshes, footprint body and shape, and the applied-step record.
  The display's two vertex-colour materials are stored in `base.scn` (count 0 → 2).
- `docs/evidence/lion-clay-20261110/capture.gd -- zoo`: graphical exit **0**; turnaround, close-up,
  pair and location views inspected. Full town (`VT_FOCUS=all`, `VT_SPAWN=none`, isolated
  HOME; `dev_focus.txt` not edited).
- `docs/evidence/town-checks/check_runtime_resources.gd`: **461 checked, 1 failure**: `scripts/buildings/chapel.gd`
  parse errors (variable type inference); that file was being edited by a concurrent
  chapel session, not by this work. `lion_clay.gd` loads.

Limits: visual resemblance is approximate; gameplay, vehicle and full suites were not run.
No commit.

**Face rework — 11 November 2026** ([design](TOWN_DESIGN_BRIEF.md#clay-lion-display-second-build-for-comparison--10-november-2026)):
- `tools/build_lion_clay.gd`: **71,072 triangles**, save OK.
- `tools/bake_unit.gd -- base` (isolated HOME): **one step** `lion_clay_face_rework`, done.
  No other base step was pending. `compare_scenes.gd` before/after: **11,968 → 11,968 nodes,
  1 difference** (applied steps; the tool does not compare mesh data). A load probe confirmed
  the saved display's meshes now match the rebuilt scene (face details 4,764 → 6,516 vertices).
- Scratch measurements against the user's blueprint (not in the repository): side-profile front
  edge within ~2 px from y 200 to 280; front cream half-width within ~4 px from y 209 to 284.
  Front and side comparison images saved in `docs/evidence/lion-clay-20261110/`.
- `capture.gd -- zoo` (full town, isolated HOME): first run saved the turnaround, then hung
  after loading the town (stopped after ~10 min, no zoo views); one retry exited **0** and
  saved all views. The zoo close-up and pair show the reworked face. `dev_focus.txt` not edited.
- Not run: resource check, gameplay, vehicle and full suites. No commit.

**Ears fitted — 11 November 2026:**
- `build_lion_clay.gd`: **70,836 triangles** (five meshes, new `Ears`), save OK.
- `bake_unit.gd -- base`: only pending step `lion_clay_ears_fit`, done. `compare_scenes.gd`:
  11,969 → 11,969 nodes, 1 difference (applied steps; the tool does not list the nodes inside
  the instanced display). The load probe shows the saved display has the rebuilt meshes,
  including `Ears` (924 vertices).
- Front and side comparison images were re-saved with the ears. `capture.gd -- zoo` (full town,
  isolated HOME): exit **0**, display has 6 parts. The town came up at night in this run, so
  the zoo views are dusk-lit (the day/night cycle; not changed here); they show the fitted ears
  and the reworked face. Not run: resource check, gameplay, vehicle and full suites. No commit.

**Eyes and mane — 11 November 2026:**
- `build_lion_clay.gd`: **74,576 triangles** (six meshes, new `Eyes`), save OK.
- `bake_unit.gd -- base`: only pending step `lion_clay_eyes_mane`, done. `compare_scenes.gd`:
  11,970 → 11,970 nodes, 2 differences (applied steps; the mane's new matte material). The load
  probe shows the saved display's meshes match the rebuilt scene (eyes 5,136 vertices).
- Scratch silhouette measurements (not in the repository) against the user's front image and
  the blueprint sheet are recorded in the design brief. Comparison images saved in
  `docs/evidence/lion-clay-20261110/`.
- `capture.gd -- zoo` (full town, isolated HOME, daylight this run): exit **0**, display has
  7 parts; the close-up and pair show the new eyes and the caramel matte mane.
  `dev_focus.txt` not edited. Not run: resource check, gameplay, vehicle and full suites.
  No commit.

**Ears and two-layer mane — 11 November 2026:**
- `build_lion_clay.gd`: **66,668 triangles** (fewer: two mane layers instead of three plus the
  rosette), save OK.
- `bake_unit.gd -- base`: only pending step `lion_clay_ears_mane_two_layers`, done (11,969
  nodes reported). `compare_scenes.gd` against a scratch copy of the previous `base.scn`:
  11,970 → 11,970 nodes, 1 difference (applied steps). The load probe shows the saved display's
  meshes match the rebuilt scene (mane 13,144 vertices, ears 684).
- Scratch renders (not in the repository) compared front, side, back and front 3/4 with the
  blueprint sheet, the high-res front view and the user's 3/4 and side renders; silhouette
  numbers are in the design brief, images in `docs/evidence/lion-clay-20261110/`.
- `capture.gd -- zoo` (full town, isolated HOME, `VT_FOCUS=all VT_SPAWN=none`, daylight): exit
  **0**, display has 7 parts; the close-up and pair show the set-back ears and the two-layer
  mane. In strong zoo sunlight the mane reads lighter and more saturated than in the user's
  softly lit references (lighting, not changed). `dev_focus.txt` not edited. Not run: resource
  check, gameplay, vehicle and full suites. No commit.

**Second pass, whole model — 11 November 2026** ([design](TOWN_DESIGN_BRIEF.md#clay-lion-display-second-build-for-comparison--10-november-2026)):
- `build_lion_clay.gd`: **70,428 triangles**, save OK.
- `bake_unit.gd -- base` (isolated HOME): only pending step `lion_clay_second_pass`, done (12,039
  nodes reported). `compare_scenes.gd` against a scratch copy of the previous `base.scn`:
  12,040 → 12,040 nodes, 2 differences (applied steps; the display's footprint box centre).
- Scratch comparison renders (cream stage, sheet crop beside the model at the same scale) for
  front, side, front 3/4, face, face from the side and back, repeated over six tuning rounds;
  the final set is saved as `docs/evidence/lion-clay-20261110/pass2-*-compare.png`.
- `capture.gd -- zoo` (full town, isolated HOME, `VT_FOCUS=all VT_SPAWN=none`): exit **0**,
  display has 7 parts at world (-95.55, 0.156, 157.95); `zoo-close.png` inspected: stands on the
  lawn, facing the gate. `turnaround.png`, `zoo-pair.png`, `zoo-location.png` regenerated.
- Load probe (headless): all nine `*_clay.gd` scripts load (they extend `lion_clay.gd`; a first
  run failed because `_h()` had been removed with the old mane code, so it was put back) and
  `lion_clay.scn` instantiates with 7 children. The other clay animals were not rebuilt.
- `dev_focus.txt` not edited (it read `all` with `spawn=airport` before and after). Not run:
  `run_checks.py`, gameplay, vehicle and full suites. No commit.

## Lion "relax crawl" display — 11 November 2026

Scope: new prefab `scenes/animals/lion_crawl.tscn`, base step `lion_crawl_display`
([design](TOWN_DESIGN_BRIEF.md#lion-relax-crawl-display-third-build--11-november-2026)).

- `tools/build_lion_crawl.gd`: **102,844 triangles**, save OK.
- Pre-bake probe: `base.scn` had 49 of 49 steps applied (nothing pending from other work).
- `tools/bake_unit.gd -- base` (isolated HOME, `VT_FOCUS=all VT_SPAWN=none`): 19 of 19 units
  loaded, **one step** `lion_crawl_display`, save OK (12,050 nodes reported).
  `compare_scenes.gd` against a scratch copy of the previous `base.scn`: 12,040 → 12,051 nodes,
  12 differences (the display's 11 nodes and `applied_steps`).
- `docs/lion-crawl-20261111/capture.gd` stage renders (cream stage, sheet crop beside the model
  at the same scale), repeated over the user's review rounds; final set saved there.
- `capture.gd -- <dir> zoo` (full town, isolated HOME, `VT_FOCUS=all VT_SPAWN=none`): display
  has 9 parts at world (-101.4, 0.156, 154.96); `zoo-close.png`, `zoo-face.png`,
  `zoo-location.png` inspected: stands on the lawn inside the gate, facing it, clear of the
  kangaroo and red panda. `zoo-side.png` written, not inspected.
- Limitations: stage light is not the town's (the Compatibility renderer adds the sun pass in
  display space, so town daylight is much brighter); colours were toned from one partial-town
  preview and wash out in sunlight (see design note). `dev_focus.txt` not edited (it read `all`
  with `spawn=airport` before and after). Not run: `run_checks.py`, resource, gameplay, vehicle
  and full suites. No commit.

**Colours toned for town sunlight — 11 November 2026** (same scope): `build_lion_crawl.gd`
102,844 triangles, save OK; pre-bake probe showed only `lion_crawl_colours` pending;
`bake_unit.gd -- base` (isolated HOME, `VT_FOCUS=all VT_SPAWN=none`): one step, save OK;
`compare_scenes.gd`: 12,051 → 12,051 nodes, 1 difference (`applied_steps`; vertex colours are
not compared). `capture.gd -- <dir> zoo`: `zoo-close.png` regenerated and inspected (mane
deeper orange with visible seams, cream and muzzle no longer white, ear pink visible); the run
was stopped before `zoo-face.png`, `zoo-side.png` and `zoo-location.png` were rewritten, so
those three still show the earlier colours. No suites run. No commit.

## Combined lion display and temporary lion marks — 11 November 2026

Scope: new prefab `scenes/animals/lion_mix.tscn`; base steps `lion_mix_display`,
`lion_temp_marks`, `lion_temp_marks_lower`
([design](TOWN_DESIGN_BRIEF.md#combined-lion-display-and-temporary-lion-marks--11-november-2026)).

- `tools/build_lion_mix.gd`: **93,568 triangles**, save OK.
- Stage renders with the crawl lion's `capture.gd` (`LION_SCENE=res://scenes/animals/lion_mix.tscn`):
  `compare-bodies.png` and `compare-faces.png` inspected; `compare-quarters.png` written, not
  inspected.
- Pre-bake probe: only `lion_mix_display` and `lion_temp_marks` pending. `bake_unit.gd -- base`
  (isolated HOME, `VT_FOCUS=all VT_SPAWN=none`): two steps, save OK (12,063 nodes reported);
  `compare_scenes.gd` against a scratch copy: 12,051 → 12,064 nodes, 14 differences (the 13 new
  nodes and `applied_steps`). Second bake: one step `lion_temp_marks_lower`, save OK (no
  compare run for it).
- `docs/lion-mix-20261111/capture_zoo.gd` (full town, isolated HOME, `VT_FOCUS=all
  VT_SPAWN=none`): display has 7 parts at world (-89.05, 0.156, 159.64), all four marks
  present; `zoo-all-lions.png` (after lowering) and `zoo-close.png` (before lowering)
  inspected: the lion stands on the lawn right of the clay lion, and each number sits over its
  lion. `zoo-face.png` written, not inspected.
- Limitations: a wandering zoo animal (tiger) was beside the new lion in the renders; its
  routes were not checked against the new footprint. `dev_focus.txt` not edited (`all` with
  `spawn=airport`). Not run: `run_checks.py`, the signs check, resource, gameplay, vehicle and
  full suites. No commit.

## Local indoor fill (outside seen through doors keeps the time of day) — 10 November 2026

Scope: `scripts/world/day_night.gd` only ([guide](performance/README.md#day-night-cycle--9-november-2026)).
The user's screenshots showed the street outside the hospital door lit warm and bright at
night from the corridor, but night-blue from the street. Cause: the indoor fill was the
global ambient (night `aebbe0` × 0.46 switched to `fff4e4` × 0.54 indoors), which also lit
everything seen through doors. Now the environment keeps the outdoor ambient, and one
ReflectionProbe (ambient colour only, cull mask 0, no reflection, hidden outdoors) is fitted to
the building around the player by rays.

- Engine test in a scratch project (Godot 4.7.2, GL Compatibility): the probe's ambient applies
  per pixel inside its box, follows a move at once, and matches the environment ambient once
  its colour is converted to linear.
- Fitted boxes (headless debug, not kept): hospital corridor **23.3 × 22.8 × 41.6 m** (three
  floors; the front side stops at the facade header above the door); supermarket
  **33.2 × 7.2 × 33.2 m** (outer walls on all four sides).
- `docs/evidence/indoor-fill-20261110/capture.gd` (new; full town 19/19 units, isolated HOME,
  `VT_FOCUS=all`, `VT_SPAWN=none`): `sheet.png` inspected. Mean colour of the street seen
  through the hospital door at 21:00: old fill emulated **(130, 127, 100)**, player inside
  **(75, 86, 95)**, player outside **(79, 90, 104)**. The corridor, side rooms and supermarket
  stay warm at night (same as noon); the supermarket door shows a night street.
- `run_checks.py --only runtime_resources,day_night,mystery_house`: **day_night PASS**
  (indoor checks rewritten for the probe: box around the player, 0.54 fill inside it, global
  ambient keeps the night colour, the street outside the door is outside the box),
  **mystery_house PASS**, **runtime_resources NEW 2**: parse errors in uncommitted
  `scripts/buildings/chapel.gd` (modified) and `scripts/characters/lion_clay.gd` (untracked),
  not part of this change.
- Not run: full suite, web build frame times. The capture window had to stay on top
  (macOS stops drawing a covered window). No commit.

Limits (priority low): the box is one rectangle, so an L-shaped building's outdoor corner or a
covered porch can share the fill; lower floors seen down a stairwell keep the outdoor ambient;
other buildings' interiors seen from the street are not filled.

#### Later the same day: scoreboard button, table-centre counter

User: a scoreboard to open instead of in-world name plates (a plates version was built and
rendered, then replaced). The status card keeps the mode and your wind; a ★ button showing your
points opens "Points this visit" (wind, name, points per player); the tiles left and the round wind
moved to a console in the middle of the table ([guide](MAHJONG.md#flow)).

| Check | Result |
| --- | --- |
| `docs/evidence/mahjong-20261109/play.gd` with graphics, `VT_FOCUS=home`, isolated `HOME`, 1280×800 (adds: star shows your points, the card opens with every player's points and fits, closes again; the counter shows the tiles left and goes with the preset) | **106 checks, 0 failures** |
| Renders `game.png`, `scoreboard.png` | Counter reads "東 61 fichas"; the scoreboard card opens under the status card |

After that run, two small fixes were made and are not re-rendered: the scoreboard's labels now
scale with the window (they were drawn at the default size), and ★ no longer opens it over the
result card. Not run: `verify.gd`, `language` and the full suite. Esc does not close the scoreboard.

## Clay red panda display — 11 November 2026

[Design record](TOWN_DESIGN_BRIEF.md#clay-red-panda-display--11-november-2026). Run once, with
an isolated `HOME`, `VT_FOCUS=all`, `VT_SPAWN=none` (`dev_focus.txt` itself read `all`,
`spawn=airport`, and was not changed):

- `tools/build_red_panda_clay.gd`: 99,045 triangles, save OK.
- `tools/bake_unit.gd -- base`: OK after one retry. The first try failed to save because
  another session was rewriting `elephant_clay.tscn` at that moment; `base.scn` was untouched
  by the failed try. `compare_scenes.gd` against the copy from just before: only
  `ParkZoo/RedPandaClayDisplay` and its 8 children added, plus the step list.
- `docs/evidence/red-panda-clay-20261111/capture.gd -- zoo`: display found in the loaded town with 7
  parts; turnaround, face and two zoo views inspected (it stands on the lawn, clear of the
  other displays).

Not run: `run_checks.py`, `docs/evidence/part2/verify` and any other suite. Other clay-animal sessions were
changing `base.gd` and `base.scn` during this work, so the base should be re-checked once they
have all finished.

## Clay kangaroo display — 11 November 2026

[Design record](TOWN_DESIGN_BRIEF.md#clay-kangaroo-display--11-november-2026). Run with an
isolated `HOME`, `VT_FOCUS=all`, `VT_SPAWN=none` (`dev_focus.txt` itself read `all`,
`spawn=airport`, and was not changed):

- `tools/build_kangaroo_clay.gd`: 72,320 triangles on the last build before the final colour
  and face edits (that last build's count was not read), save OK.
- `tools/bake_unit.gd -- base`: OK, 1 step applied (`kangaroo_clay_display`), 12,039 nodes. No
  scene comparison against the previous `base.scn` was made.
- `docs/evidence/kangaroo-clay-20261111/capture.gd -- zoo`: display found in the loaded town with 5
  parts; turnaround, face and two zoo views inspected against the sheet (it stands on the
  lawn clear of the other displays). The capture was run five times while the model was
  refined; one run stalled after the first strip and was stopped. The final run's town views
  are at night.

Not run: `run_checks.py`, `docs/evidence/part2/verify` and any other suite. Other clay-animal sessions were
changing `base.gd` and `base.scn` during this work, so the base should be re-checked once they
have all finished.

## Restaurant game: reception, tables and order tablet — 11 November 2026

User request; design record:
[TOWN_DESIGN_BRIEF.md](TOWN_DESIGN_BRIEF.md#restaurant-game-reception-tables-and-order-tablet--11-november-2026).
Textures and extras removed from the game, a menu table with a flip-book menu by the host stand,
the walk-around flow (Twinkle → customer → order tablet → verdict → Twinkle's report), two customers
at two tables, taste levels as icon + pill bars. World change baked with step `dining_game_tables`
(`tools/bake_unit.gd -- restaurants`, 1 step, `restaurants.scn` OK, 8202 nodes).

| Check | Result |
| --- | --- |
| `docs/evidence/restaurant-20261106/verify.gd` (logic: catalog, 36,000 generated orders in three difficulty settings, text in es/en/zh, Spanish *algo* agreement, the new wrong-dish report) | PASS, 497,130 checks. Before the generator change it failed 3 orders in the forced "negation, three requirements" setting (dessert menus with no unique 3-requirement order once textures were gone); the generator now also tries fewer requirements |
| Chinese readings of the `restaurant.*` phrases (scratch script, `Lexicon.reading_gaps`) | 哎, 呀, 絲 were missing; added to `data/pinyin_zh.json`; none missing after |
| `docs/evidence/restaurant-flow-20261111/capture.gd` (graphical, full town, `VT_FOCUS=all`, isolated HOME; not in the runner) | PASS, 72 checks: poster removed and moved, menu book usable, two different non-staff customers seated at both seats, the board blocks other games, one game of 5 visits (1 wrong, 4 right) through every step, summary of 12 words, Finish, new guests, Stop serving, ✕ on the tablet keeps the visit (es and zh) |
| Rendered views | Inspected: room from the entrance, menu table, both customers, rear-wall posters, every flow step, tablet (dish, sent, summary, translated es/zh). The first town render showed the book's bookmark row under the HUD clock and its cover pages overflowing the cover; fixed afterwards and re-rendered **standalone** (`book_render.gd`, no town): `book-cover-standalone.png`, `book-desserts-standalone.png`. The town capture was not re-run after that fix (the hidden "!" while a customer talks, the book layout); its stale book views were deleted |

Not run: the quick/full suites (`tools/run_checks.py`) and `tools/language_check.gd`. The old
captures `docs/evidence/restaurant-20261106/capture.gd` and `docs/evidence/alta-cocina-20261108/capture.gd` are marked
stale (they look for the removed textures poster / old panel API).

### Second request, same day: 2–3 courses per customer, the door question, Twinkle names no one

User request (11 Nov 2026); [design record](TOWN_DESIGN_BRIEF.md#restaurant-game-reception-tables-and-order-tablet--11-november-2026).
Each customer orders 2–3 courses (first "Quisiera pedir una entrada y una bebida.", 2 seconds later the
requests); the tablet has an order slip, "Choose this dish" per course and one Send; Twinkle's report
has one sentence per wrong dish; an invisible wall and the shared quit card at the entrance while a game
runs; Twinkle says "Mira si hay clientes que quieren pedir." with no name. No world change (the door
wall is built at runtime); nothing re-baked.

| Check | Result |
| --- | --- |
| `docs/evidence/restaurant-20261106/verify.gd` (logic; now also the two-miss report and the "Quisiera pedir…" line in es/en/zh) | PASS, 564,054 checks |
| Chinese readings of the `restaurant.*` phrases (scratch script, `Lexicon.reading_gaps`) | none missing |
| `docs/evidence/restaurant-flow-20261111/capture.gd` (graphical, full town, `VT_FOCUS=all VT_SPAWN=none`, isolated HOME), updated for the new flow | First run PASS, 105 checks; the renders showed three layout faults (below). After the fixes for the first two, second run PASS, **106 checks**: 2–3 courses in menu order, the courses line then the requests after `INTRO_SECONDS`, Choose moves to the next course, Send only with every course, all dishes sent, a two-wrong-dish report ("También quería…"), no name in Twinkle's lines, door: no wall without a game, wall and question during one, `test_move` out of the door blocked, stepping back takes the question away, asked again, yes ends the game and opens the door |
| Rendered views | Inspected: intro line, requests, slip, sent (two dishes), wrong report, door question, summary. Faults found: (1) "✓ Platos principales" clipped in its tab, now the chosen courses' tabs turn from a teal to a green frame; (2) with translation on and three courses the order text pushed Send order off the tablet, now the order text shrinks (to 0.6 at most) until the tablet fits; (3) after the second run: the order text shrank further than needed, and the two-language "Choose this dish" squeezed the dish list. Fixed (the fit waits a frame; Choose pinned under the dish page, two lines, clipped; dish rows sized by their text) and checked with the new **standalone** render `tablet_render.gd` (no town; PASS 4: Send inside the tablet, the list keeps 331 px, es and zh): `tablet-three-courses-es.png`, `tablet-three-courses-zh.png`. The town capture was not run again after fix 3; its old `tablet-translated-*.png` were deleted |
| `docs/evidence/practice-log-20261107/verify.gd` | `restaurant_game()` rewritten for the new API (it still called the 6 Nov `_on_serve` / `_next_course`); **not run** |

Not run: the quick/full suites (`tools/run_checks.py`) and `tools/language_check.gd`. `dev_focus.txt`
was not touched by this work (it lists `spawn=airport` from another session; the checks above set
`VT_FOCUS=all`).

## Library category shelves and return shelf — 11 November 2026

User request; [design record](TOWN_DESIGN_BRIEF.md#library-category-shelves-and-return-shelf--11-november-2026).
World change baked with step `category_shelves` (`tools/bake_unit.gd -- library`, `library.scn`
OK, 1985 nodes).

| Check | Result |
| --- | --- |
| `docs/evidence/library-shelves-20261111/verify.gd` (new, full town, `VT_FOCUS=all VT_SPAWN=none`, isolated HOME; runner name `library_shelves`) | PASS, **173 checks, 0 failures**: old fittings removed, eight *bookshelf* cases with translated headers, five clickable rows and gaps each, 24 different picture books on the return shelf with metas, cover titles and a home gap on their own bookcase that fits them, six capsule routes, Rosa's greeting → Yes → congratulations |
| Rendered views | `docs/evidence/library-shelves-20261111/capture.gd`, before and after; inspected: entrance, both walls, rear, back to the door, return shelf, covers, a bookcase, Rosa. Fixed after earlier renders: mid-word title wraps, a sun past its picture, leftover vines over the headers. The `top` view shows the roof (camera fault, not fixed) |

Not run: the quick/full suites (`tools/run_checks.py`) and `tools/language_check.gd`. The 1 Nov
`docs/evidence/library-refresh-20261101/verify.gd` now fails on the removed returns bin (historical, superseded).
`dev_focus.txt` was not touched (it lists `spawn=airport` from another session).

**Second pass, same day (user: thicker, fewer, plainer books in one palette; cuter):** step
`category_shelves` changed before any commit and re-baked from the pre-step scene (`library.scn`
OK, 1947 nodes). `docs/evidence/library-shelves-20261111/verify.gd` again PASS, **173 checks, 0 failures**.
Views re-rendered (`after-*.png`) and inspected: entrance-side walls and a close bookcase. The
darkest navy/green shades read too heavy in the first render and were lightened once.

### Follow-up, same day: shared door guard, order slip, the last tablet checks

User request (11 Nov 2026): make the door question reusable, re-verify, and move the requests onto
the tablet's slip. `minigame_zone.gd` `make_door_guard()` (wall + question zone + its own tick)
now serves the Mystery House arch and the Alta Cocina entrance (the arch keeps its node names and
layer); the tablet's bubble says only the courses and each request is on its slip row; dish rows
grow to their wrapped names.

| Check | Result |
| --- | --- |
| `run_checks.py --only mystery_house,practice_log` (once; runner: isolated HOME, `VT_FOCUS=all`; `dev_focus.txt` still lists `spawn=airport`, which the runner overrides) | **2 PASS.** `mystery_house` 121 checks, 0 failures (the arch question through the shared guard); `practice_log` 83 checks, 0 failures (its restaurant part rewritten for multi-course orders). The practice-log run also logged `lexicon: missing phrase warehouse.thing_suitcase_red` from the warehouse game: not from this work, not investigated |
| `docs/evidence/restaurant-flow-20261111/capture.gd` (once, full town, isolated HOME) | PASS, **111 checks** (adds: the bubble shows the courses, the slip has one row per request); the door checks pass through the shared guard |
| Rendered views (town) | Inspected `tablet-1-dish`, `tablet-2-slip` (three requests, three dishes), `tablet-translated-es`: slip correct; in `tablet-translated-es` long dish names with translation overflowed their list rows (older row-height guess) |
| `tablet_render.gd` (standalone, after the row fix) | PASS 6: Send inside the tablet (order text 0.85 es, 0.70 zh), list 331 px wide, every dish row holds its wrapped name; `tablet-three-courses-es.png`/`-zh.png` inspected. The town capture was not re-run after the row fix |

Not run: the quick/full suites and `tools/language_check.gd`.

## Zoo zones — 12 November 2026

Base step `zoo_zones` ([design record](TOWN_DESIGN_BRIEF.md#zoo-zones--12-november-2026)).
Baked with `tools/bake_unit.gd -- base` (OK, 12116 nodes); a second, final bake was made from
the pre-step `base.scn` after the first renders (bamboo leaf tufts, savanna ferns instead of
grass cylinders, a larger plaza cherry tree). `dev_focus.txt` was not touched (it lists `all`
and `spawn=airport` from another session; the runner and the check override the spawn).

| Check | Result |
| --- | --- |
| `docs/evidence/zoo-zones-20261112/check.gd -- views` (graphics, isolated HOME, `VT_FOCUS=all VT_SPAWN=none`; run once per bake) | **0 failures** both times: scenery present, old board gone, four zone grounds, five translated signs; each of the 16 zone animals configured with its habitat inside its zone; all 28 ParkZoo wanderers stayed contained over two simulated minutes and moved (zone animals 1.46–3.05 units) |
| Rendered views | `overview`, `savanna`, `forest`, `bamboo`, `plains`, `entrance`, `plaza` inspected: animals on their zone grounds at species size, signs read LA SABANA / EL BOSQUE / EL BAMBÚ / LAS LLANURAS / EL ZOOLÓGICO, waterfalls and ponds in place |
| `run_checks.py --only runtime_resources,compact_layout,part2,public_garden,signs,zoo_vehicles,park_terrain,interaction` (once) | **PASS** part2, public_garden, signs, zoo_vehicles (gate opens/closes, gate word), park_terrain, interaction. **NEW** runtime_resources: `chapel.gd` parse errors, already recorded on 11 Nov ([clay zoo](ANIMAL_SYSTEM.md#clay-animals-join-the-zoo-11-nov-2026)). **NEW** compact_layout: "rigid move preserves scale" for Tiger, Monkey, Snake, Horse, Hen and Sheep; horse, hen and sheep were not touched by this step and `zoo_zones` changes no scale, so these come from the uncommitted 11 Nov `animals_bigger` rescale (P2: update the check's recorded scales or its expected failures once that work is committed) |

Not run: the full suite. Performance not measured; the step adds about 1,900 nodes (fences,
bamboo, rocks, colliders), mostly merged into batches by `render_culling.gd` at load.

## Control tower roof and observation deck — 12 November 2026

Step `tower_deck` (`scripts/buildings/airport.gd`), baked into `scenes/town/airport.scn` after
the window-component bake of the same day ([design record](TOWN_DESIGN_BRIEF.md#control-tower-roof-and-observation-deck--12-november-2026)).
All runs used an isolated `HOME`; Godot checks ran with `VT_FOCUS=airport` (not the full town)
except the `run_checks.py` rows (`VT_FOCUS=all`).

| Check | Result |
| --- | --- |
| `docs/evidence/tower-deck-20261112/verify.gd` (new; graphical run for the views, then headless after the pick-area fix) | 17 checks, 0 failures: old slab/fascia/ledge/rail gone; door registered (slide) and picked by pointer; closed door blocks; door slides open 1.5 and shut; real-size capsule walks from the control room out of the door, round all four deck corners at deck level and back in; railing stops it; deck/roof air space holds only the tower. Tower coplanar pairs: 1 (older, inside the shaft) besides the older ear-cup pads |
| `docs/evidence/control-tower-20261029/verify.gd` | 231 checks, 0 failures after two check updates: the zone check measures the tower below the cabin slab (the deck overhangs the zone), and the four-side glazing check accepts shared window components (the south pane became one in the window bake). Before them: height (from the narrowed box, my edit), glazing (window bake) and pointer picking (deck door had no layer-2 area; added, re-baked from the pre-bake scene) |
| `run_checks.py --only runtime_resources,building_access,rooftops,radar_patrol_rules` | PASS, PASS, KNOWN, PASS. `rooftops` reports the CHAPEL spire expectation as FIXED; it comes from the separate chapel rebuild, not this step (P3: update `expected_check_failures.json` with that work) |
| Views ([folder](../evidence/tower-deck-20261112/)) | Below south-west and west, far south, the deck by the west door shut and open, along the north deck, inside towards the open door, roof from above (13:44, as the user's screenshot). Roof edge and railing read cleanly; stills cannot prove the absence of flicker in motion |

Not run: the full suite, web-export frame rate. Unresolved: the 5 cm slit between the cabin
glass/mullion tops and the header (older, all four sides; P3).

## Shared glass windows — 12 November 2026

User request: one reusable window component with shared, semi-transparent blue-gray glass in
13 buildings, performance first. Design, files and the per-window list: [WINDOWS.md](WINDOWS.md).
Bake: `tools/bake_unit.gd -- airport warehouse school sports bakery electronics bank barn library
restaurants police supermarket clothing` (step `glass_windows`), then `-- warehouse restaurants`
(step `glass_windows_2`: 3 auto-named panes the name list missed), then, after the tower deck
work was finished, `-- airport` (`glass_windows_2`: 18 panes: 2 terminal gate panes, the tower's
windows and cabin sides, and the tower deck's cabin and door glass). Result: 84 windows, 38
see-through and 46 opaque on walls. No thin transparent pane of the old look remains in the 13
units except display cases, fridges and coolers, the bank teller glass and the police one-way glass. `tools/compare_scenes.gd` against HEAD (bank, restaurants, supermarket) shows
only the window nodes changed. Node counts are equal or lower (window glass and frame are rebuilt at
load; the bake now strips them, "window parts").

Checks, all with `VT_FOCUS=all` and the isolated HOME of `tools/run_checks.py`:

| Check | Result |
| --- | --- |
| `runtime_resources`, `part2`, `public_garden`, `interaction`, `barn`, `police_interior`, `building_access`, `warehouse` | PASS |
| `map_facades` | KNOWN (1, as recorded) |
| `language` | NEW, unrelated: `restaurant.miss_also` placeholders (phrase data, not touched here) |
| `compact_layout` | NEW, unrelated: "rigid move preserves scale" for six `ParkZoo` animals (zoo work in the base world, not touched here) |
| `warehouse_game` | NEW in the batch run: `put down on the floor` (a box dropped in the hall did not come to rest within 40 frames), then follow-on errors. Re-run once to find the cause: PASS with the reception-window change reverted, and PASS again with it in place, so it is a flaky physics step and not caused by the windows. Priority: low; the step waits a fixed 40 frames |
| After `glass_windows_2`: `warehouse`, `warehouse_game`, `building_access`, `runtime_resources` | PASS |
| After the airport's `glass_windows_2`: `runtime_resources`, `building_access`, `radar_patrol_rules`, `interaction`; `docs/evidence/control-tower-20261029/verify.gd` by hand | PASS; tower check 231 checks, 0 failures |
| `rooftops` | KNOWN (2); reports the CHAPEL spire expectation as FIXED (chapel rebuild, not this work) |

Views (`docs/evidence/windows-20261112/capture.gd`, a window, both sides of every window, noon and 21:00):
the sheets `<unit>.png` in that folder. The see-through panes show the real interiors from the
street (electronics, clothing, Pizza y Hamburguesas, warehouse reception, control tower) and the
street from inside. At night the lit rooms show through. Overlapping panes (Pizza y Hamburguesas
front glass with its door leaves; tower cabin glass) show no sorting seams or flicker. Opaque panes
read as blue-gray glass with a sun highlight. `electronics-opaque-mode.png` shows the
`glass_mode = "opaque"` fallback.

The airport views (`airport.png`, rows 5–22) show the tower's stairs and rooms from outside and the
airfield from inside, and the cabin glass shows the deck and control room in one tint. The
`WINDOWS perf` lines of that last capture run are invalid and not used: all four views reported
the same 2085 calls, so the camera did not reach them. The game was running in the editor at the
same time.

Draw calls, desktop (M5, 1000 × 780, noon, four fixed views; the same working tree with the
13 unit scenes from HEAD vs baked):

| View | Before | After |
| --- | --- | --- |
| Supermarket | 1082 | 1082 |
| Restaurants | 2080 | 2072 |
| Bank | 858 | 858 |
| Airport | 1568 | 1569 |
| Static batches (whole town) | 3721 | 3718 |

The opaque fallback gives the same draw calls; it saves only transparent fill. An earlier
"before" of 1004 calls at the supermarket was taken before a concurrent chapel/base commit
(`e06dbe2`) and is not comparable.

Web build ("Web" preset, release, headless Chrome 156 through `docs/evidence/day-night-20261109/web_measure.py`,
1280 × 800 at 2×, frame cap off; spawn at Pizza y Hamburguesas through a temporary `spawn=burger`,
restored afterwards; camera zoomed out so the 16 m front glass and dining room fill the middle).
FPS, three 5 s runs each, in the order run:

| Run | Build | FPS |
| --- | --- | --- |
| 1 | before | 93, 97, 97 |
| 2 | after | 70, 70, 70 |
| 3 | before | 48, 51, 54 |
| 4 | after | 71, 72, 73 |

The machine's speed drifted strongly during the session (earlier spawn-view runs: before 158, after
116, then after 103, before 94). Alternating builds, the after build was neither consistently
slower nor faster than the before build next to it, so there is no measurable web regression. The
noise is too large to give a precise difference. Not measured: a weaker device, and Firefox/Safari.

## Library books 50 % larger — 12 November 2026

[Design](TOWN_DESIGN_BRIEF.md#library-books-50--larger--12-november-2026). Step `big_books` baked
with `tools/bake_unit.gd -- library` from the committed library scene (1771 nodes; 48 book parts
dropped from the save, rebuilt at load). A first bake the same day (40 % sizes) was discarded
before any commit. `dev_focus.txt` read `all` throughout.

- `docs/evidence/library-shelves-20261111/verify.gd` (isolated HOME, full town): **173 checks, 0
  failures**. The check was updated for the new structure: rows expected = `TIERS.size()` (4), a
  book's thickness from `thickness()`, the cover title found below the book's model. Earlier
  runs this day: 24 "cover title" failures (old title lookup, fixed in the check); then, at 50 %,
  "Kings and Queens has its home gap" failed (three thick home books on one shelf exhausted the
  40 random placements; now 200 tries over a wider range, with an error if one is still missing).
- Renders (`VT_FOCUS=library`, 1280 × 800): `docs/evidence/library-books-20261112/after-*.png`, inspected:
  close-shelf (four rows of larger books with gaps), close-returns (24 translated covers, six a
  tier), rear and east (rack clear of the aisle and Rosa). Cover preview `covers.png` inspected
  (a first preview showed the pictures mirrored; the picture helpers now mirror x).
- 13 Nov 2026, larger cover titles (runtime only, no re-bake): `covers.png` and the library
  renders (`VT_FOCUS=library`) inspected in English and Spanish; every title inside its band.
  Same day, title band in the cover colour: `covers.png` and the close-returns render re-inspected.
  `library_shelves` was not re-run for this change (titles keep their node names).
- Not run: the full suite and other buildings' checks (only the library unit and the bake tool's
  per-book part removal changed).

## Staged loading, home first — 13 November 2026

User choice (option B of the staged-loading investigation): a profile that will play the welcome
tutorial starts with the base world plus `home` and `supermarket`; the other 17 units are added
one at a time during the tutorial ([how](MODULAR_TOWN.md#units-added-while-the-game-runs-home-first--13-november-2026)).

**Measurements (web build, `tools/deploy_web.py`, served locally, headless Chrome on ANGLE/Metal,
Apple Silicon laptop; a phone is likely several times slower).** Timing prints were added to
scratch copies of the project only.

- Before, every unit before play: Play → playable 18.6 s with a warm shader cache (load
  `main.tscn` 0.8 s, first frame 1.3 s, unit files 1.2 s, units entering the tree 7.4 s, Main's
  setup 4.1 s, warm-up 4.7 s). The very first run (cold browser/GPU shader cache) had a 20.7 s
  warm-up, about 37 s in all.
- After: Play → playable **7.3 s** (warm cache). Then one freeze per unit added later (including
  the hookup in `Main.add_unit()`): restaurants 2.2 s, hospital 1.4 s, police 0.9 s, airport and
  warehouse 0.6 s, school 0.6 s, mystery 0.5 s, library 0.45 s, sports 0.4 s, clothing,
  furniture, bank and bakery about 0.3 s, the rest under 0.2 s; 17 units over about 33 s.
  Not measured: the stall when the player first sees a newly added building (shader compile).
- `ResourceLoader.load_threaded_request()` on the single-threaded web build loads inside the
  call (1.3 s for `main.tscn`) and gives no background loading.
- Download (unchanged): `index.pck` 86 MB, which gzip barely shrinks (the scenes are already
  stored compressed; GitHub Pages sends about 80 MB), plus `index.wasm` 10 MB gzipped. In the
  pack: `base.scn` 39.5 MB, the 20 animal scenes about 35 MB, all 19 units about 5 MB.

**Checks.** `app_flow` (isolated `HOME`, `VT_FOCUS=all VT_SPAWN=none`): 23 checks, 0 failures.
Its "loading spans many frames" check now reads "several frames" (2 units load before play) and
new checks cover the first units, every unit arriving during the tutorial, a late unit replacing
its stand-in site, the hospital's minigame being set up when the hospital arrives, and its render
batches. The exit leak warnings and 15 "SpatialMaterial remapped parameter" warnings are the same
as before the change. The full suite was not run.

**Rendered views.** A scratch capture script rendered the supermarket, restaurants, hospital,
police, airport, school and library from the same cameras with the whole town loaded up front and
with home first (after every unit had arrived). The counts match (doors 28, seats 358, translated
signs 344, all 19 units); 17577 meshes merged instead of 17521 (late units get their own
batches). The views match apart from wandering animals, tiny shading differences (light-sharing
groups of late batches) and the home roof, lifted in the staged run because the tutorial had
placed the player inside. Interiors were not compared.

**Shorter late-unit freezes, download and warm-up review (13 November 2026, user "do all of
them").** Same web setup; a scratch copy added every pending unit 0.3 s apart.
- Plush characters are now put back one per frame (`Main.add_unit()`, see
  [MODULAR_TOWN.md](MODULAR_TOWN.md#units-added-while-the-game-runs-home-first--13-november-2026)).
  Longest single frame per unit: restaurants 0.8 s (was 2.2 s), mystery 0.6 s, library 0.5 s,
  school 0.46 s, police 0.44 s (was 0.9 s), warehouse 0.39 s, hospital 0.38 s (was 1.4 s), the
  rest 0.35 s or less. The time in all is about the same, split over more frames. A native check
  showed plush sculpting is 85-90% of a unit's `_ready` (restaurants 1258 ms with no sculpt cache,
  109 ms with one). Shipping a sculpt cache was rejected: about 51-76 MB.
- `app_flow` after the change: 23 checks, 0 failures. No new rendered views (plushes are put back
  in the same parent, order and transform).
- Download, smaller (user "Yes, try it"): `base.scn` already stored every clay zoo animal's
  meshes and materials, so the 17 clay scene files (32.7 MB in the pack) were loaded only to have
  their meshes replaced. New base step `clay_animals_unpacked` saves those 17 nodes as plain
  nodes; the Web preset excludes `scenes/animals/*_clay.*`, and `deploy_web.py` refuses a build
  whose scenes still name one (it finds all 17 in the previous `base.scn`). `index.pck` 86.3 → 53.6
  MB, gzipped 80.7 → 48.4 MB. Checks: `compare_scenes.gd` old vs new base: 12101 nodes each, 4
  differences (the steps list, the root metas, and two tree crowns losing a `root__ref` that did
  not resolve before either: at load both towns give those crowns no `root`); the 17 clay nodes
  keep their mesh counts; zoo renders (zebra, dog, lion, giraffe, elephant, pig, cub, flamingo)
  match apart from the time of day; `app_flow` 23 checks, 0 failures; web run in Chrome: Play →
  playable 7.1 s, every unit added, no missing-file errors. Re-saving `base.scn` with compressed
  mesh attributes would save only 2.5% (not done).
- First-launch warm-up, not changed: the town draws about 36 distinct material shaders (2963
  materials); the cold 20 s is the browser compiling them, each stalling a frame of the camera
  turn. Chrome keeps the compiled programs, so later launches warm up in about 4.7 s. Cutting it
  means merging material variants (visible). P3, not started.

**Known limits.** `TUTORIAL_UNITS` (`app.gd`) must list every building a tutorial step uses.
Players who skip the tutorial early see a short "Getting everything ready" screen while the
remaining units load.

**No loading during the house act; buildings load behind the title cutscene (16 November 2026,
user: "the tutorial is still kinda slow, especially at the start").** The house act had most of
the 17 late-unit freezes (one every 1.5 s while a dialogue line showed, or after 20 s anyway)
while the player was learning to look and walk. Now `app.gd` `_load_rest()` adds none during act
0 and all of them, back to back, while the title cutscene is up; the cutscene shows the progress
bar and stays until they are in (at least 7 s, at most `cutscene_max_seconds` 60 s; what is left
after that loads as before). Checks (isolated `HOME`, `VT_FOCUS=all`): `runtime_resources` PASS,
`tutorial` 113 checks, 0 failures; `app_flow` 24 checks, 0 failures, with the old "every unit is
added during the tutorial" check replaced by "no unit is added during the house act" (4 s) and
"every unit is added behind the title cutscene". Not measured: the cutscene's length on the web
build or a phone (on the 13 Nov laptop timings the freezes add up to about 10 s, so expect a
cutscene of roughly 10–15 s there, longer on a phone), and the shader stall when the player first
walks outside. No rendered views (no visual change besides the bar under the title).

## Welcome tutorial review and loader owner fix — 13 November 2026

User review of the welcome tutorial (9 items; [guide](ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial)):
guest-suite start, inward family bathroom door (home step `family_bath_door_inward`), only the
suite, bathroom and yellow bedroom doors open ("They're not hiding in here!"), a fixed bathtub
close-up camera, a smaller see-through cart (`shop_order_panel.gd` `CART_RECT`, shared by every
shop), the market act kept at the supermarket and its lot, the statue step ("Click on the statue
to reveal it!", only the statue clickable, the player held still, "It's the statue of George
Washington!") and a J on the journal button.

- Found on the way: since a4c5c2c the loader left a placed unit's nodes ownerless
  ([details](MODULAR_TOWN.md#units-added-while-the-game-runs-home-first--13-november-2026)); a home
  bake wrote a 2 KB `home.scn` (restored, not committed). Fixed in `modular_town.gd`; base and home
  re-baked: `compare_scenes.gd` home 3827 vs 3827 nodes, 2 differences (steps list, the bathroom
  door's state); base 12101 vs 12101, 3 differences (root metas, and two tree crowns getting back
  the `root__ref` the 3ce693a bake had dropped). Bake report: 48 runtime-built nodes dropped (was
  2787 with the bug).
- `tutorial` (graphics, isolated HOME, `dev_focus.txt` all): first run 66 checks, 1 failure (the
  no-card click still aimed at the old bedroom's curtain; the check now clicks the suite's bed);
  after that fix and moving the cart below the toast line: 66 checks, 0 failures. Views
  inspected: wake (suite), bath-door (leaf inside the bathroom), friend (straight-on close-up),
  shop (cart card top right), statue (line and card), J on the journal button.
- `app_flow`: 23 checks, 0 failures. Other suites not run.

## Touch joystick strength and a view that stays still — 14 November 2026

User (iPhone, Safari / home-screen app): the stick felt jerky and the view turned by itself while
using it. Changes in `scripts/ui/touch_controls.gd` (rules in its header) and
`scripts/player/player_controller.gd`; no camera auto-follow was added.

- **View turning (cause found by reading Godot 4.7.2's web template, not on a phone):** the web
  build sets `InputEventScreenDrag.relative` per slot of the browser's `changedTouches`, not per
  finger. With two fingers down (the stick and a look finger, or a thumb resting on the screen)
  it is the distance between the fingers, and the view drag used it. Finger movement is now
  measured from positions kept in the script. Also: touch indices are `Touch.identifier` (not 0
  for the first finger on iOS), so the finger owning the emulated mouse is tracked as the first
  one down instead of "index 0"; and the stick's zone grew from the lower left 42 % × 68 % to the
  left 50 % × 78 %, so a thumb pulled along with the stick does not land outside it and drag the
  view. A finger in the zone that lifts without moving now clicks (the larger zone would
  otherwise swallow taps).
- **Jerky stick:** `movement_direction()` normalised the stick, so any push was full speed. It now
  keeps the strength (`limit_length(1.0)`; keys unchanged), the strength curve is linear from the
  dead zone, and the drawn knob sits under the finger with no easing while held (the easing lagged
  at 20-30 frames a second). The controls redraw only when something changes.
- Not changed: acceleration, deceleration and turn smoothing are per physics tick with physics
  interpolation on, so they do not depend on the frame rate. The spring arm still shortens the
  camera against walls indoors (zoom, not a turn).

| Check (once each, `run_checks.py --only`, isolated HOME, `dev_focus.txt` all) | Result |
| --- | --- |
| `touch_controls` (`docs/evidence/touch-controls-20261112/verify.gd`, extended: stick alone and stick + second finger with a wrong `relative` leave the yaw unchanged, iOS-style indices, GUI-taken first finger, stick tap, half push 0.43 × walk speed, full push, two keys full speed) | **PASS**, 0 failures |
| `app_flow` | **PASS**, 0 failures |
| `tutorial` | **66 checks, 1 failure**, then Godot's exit abort (`recursive_mutex lock failed`, reported as CRASH): "the shower curtain is the focused interactable in the bathroom (none)". Not re-run. The check sends no touches and teleports instead of walking; the other mobile sessions' uncommitted edits (`app.gd`, `render_culling.gd`, `game_settings.gd`, `day_night.gd`) were in the tree. Unattributed; **P2: re-run once those land.** |

Rendered once (windowed 1280 × 720, `VT_FOCUS=home`, not the full town): stick at rest, held at
0.57 of the radius (knob under the finger, 3.04 m/s of 6, yaw unchanged) and released (home,
dimmed). One line (`_drawn = []` when the controls show or hide) was added after the checks.
**Not verified on a real iPhone**: the web cause is from the engine's code, and the feel at phone
frame rates was not measured.

### Roblox-style stick — 14 November 2026 (later the same day, uncommitted)

User: still not smooth enough; do it the way Roblox does, and the whole left side may start the
stick. Compared with Roblox's `DynamicThumbstick` (PlayerModule, read from the
Roblox-Client-Tracker mirror): its stick starts at the touch point and never moves, has a 2 point
dead zone and reaches full speed 20 points from the start (40 on big screens); past that only
the direction counts. Ours was pulled along with the finger, moved in from the screen edge, and
needed the full drawn radius (about 50 points on an iPhone) with a 12 % dead zone (about 6
points). `touch_controls.gd` now does it Roblox's way: fixed start point, `DEAD_ZONE` 0.04 and
`FULL_SPEED` 0.45 of the radius, the whole left half as the zone (not the minimap corner), the
knob drawn under the finger also outside the ring.

`touch_controls` once: **35 checks, 0 failures**, but in a tree where two other sessions' files
did not parse at that moment (`render_culling.gd:176`, `indoor_visibility.gd:284`, so `main.gd`
ran partly: `_ready` stopped at line 209). **Re-run when those files load.** No rendered view and
no other check for this change; not tried on a phone.


## Home plushes and walkway plants — 14 November 2026

User: only the tutorial's characters stay in the house, and plants that block a walkway or a
doorway go ([record](REFERENCE_HOME.md#fewer-plushes-and-clear-walkways--14-november-2026)).
Changed: `data/house_characters.json` (`"in_house": false` on Bruno, Miso, Awoo, Poppy, Twinkle,
Cocodrilo; note updated), `house_characters.gd` `build()` (skips them), home step
`clear_walkway_plants` (`home.gd`) and `scenes/town/home.scn`. Uncommitted (user: no commits).

- Bake `home`: step reported "6 plants removed"; `home.scn` OK, 3778 nodes. During the bake
  another session's `render_culling.gd` did not parse, so `main.gd` failed to compile; the
  comparison shows this did not affect the result. `compare_scenes.gd` old vs new: 3827 vs 3779 nodes, 49
  differences = the 48 nodes of the six plants (pot + three foliage spheres, each with its mesh)
  and the new `applied_steps` entry; 1,407,947 → 1,401,112 bytes; no materials stored in the scene.
- Rendered views (`docs/evidence/home-plants-20261114/capture.gd`, graphics, isolated HOME,
  `VT_FOCUS=home`): `before-*`/`after-*` of the suite door, suite bathroom (both sides), east hall,
  master and study doors, family bathroom and yellow bedroom doors, living room/entry, front
  path and terrace. The six pots are gone; the corner pots and topiaries are unchanged. BonBon, Sunny
  and Leo are in place; the other six plushes no longer appear. The before views used the old JSON (swapped in for that
  run only). The first after-run stalled after one shot (window not drawing); the other views
  came from a second run. `render_culling.gd` also failed to parse during the before runs, so render
  culling was off in those images.
- `tutorial` (graphics, isolated HOME, `VT_FOCUS=all`, `dev_focus.txt` all): **66 checks,
  0 failures**, no script errors (includes the hidden-twin and avatar stand-in checks; the
  stand-in Bruno now has no house twin).
- Not run: other suites. `tools/capture_app_art.gd` shot 4 still targets
  `HouseCharacters/cocodrilo`, which is no longer placed (Low; re-aim before re-rendering app art).
  *(Resolved 16 Nov 2026: the shots were re-aimed at town views, see
  [loading shots retaken](#loading-and-title-cutscene-shots-retaken--16-november-2026).)*

## New-profile language picker in English — 14 November 2026

User: every player reads English, so the language page of a new character is in English with
English preselected, and is easier to use ([README](../../README.md#web-app-pwa)). Changed:
`app_screens.gd` (screens before the town in `Lexicon.default_native`; new profile starts with
`languages.json`'s pair; "I speak" / "I want to learn" rows of badge + name + own-name tiles,
picked = green, gold border, check; green Start; a page that does not fit is rebuilt smaller),
`lexicon.gd` (`default_native`, `default_foreign`), `data/phrases.json` (`app.languages` text,
`app.languages_hint`, `app.i_speak_hint`, `app.i_learn_hint`), `capture.gd`. `dev_focus.txt`: all.

- Rendered views (`docs/evidence/app-flow-20261112/capture.gd`, graphics, isolated HOME, 1280 × 720):
  `languages` (new profile: printed `en -> es`), `languages_picked` (Chinese to learn) and
  `languages_phone` (844 × 390); all fit with finger-sized tiles. The other app pages were
  re-rendered too (`names.png` is the page removed on 13 Nov; left in place).
- `app_flow` (`docs/evidence/app-flow-20261112/verify.gd`, headless, isolated HOME, `VT_FOCUS=all`):
  **23 checks, 0 failures**.
- `tools/language_check.gd`: 4286 checks, 2 failed, both outside this change:
  `restaurant.miss_also` placeholders (recorded above) and zh readings missing for
  備 質 素 暢 揭 喬 臥 桌 (Medium; not in the new phrases). The new phrases add no Chinese
  character, so the CJK font subset is unchanged.
- Not run: the quick/full suites; a real phone browser (the phone view is a desktop window of
  phone size; Godot's web canvas may report device pixels, which only makes the page larger).

## Easy flying for the plane and the helicopter — 14 November 2026

User: "add a easy control for the plane and the helicopter" ([easy flying](aircraft.md#easy-flying)).
Changed: `driveable_vehicle.gd` (`easy_flying`, C toggle, helicopter hover on a centred stick,
`descend` lowers it, easy status), `turboprop.gd` (`easy_step()`, `easy_inputs()`,
`easy_height()`, auto-recovery; F flaps only in expert mode), `touch_controls.gd` (▼ button
while flying), `vehicle_controls.gd` (easy boarding toasts), `vocabulary_hud.gd` (F1 rows),
`data/phrases.json`, `check_aircraft.gd` (runs in expert mode), new `check_easy_flying.gd`,
`run_checks.py`. `dev_focus.txt`: all.

- `check_easy_flying` (headless, isolated HOME, `VT_FOCUS=all`): **11 checks, 0 failures**.
  Take-off to 60 m in 17 s; level hold drifted 6 m in 15 s; 176° turn in 20 s losing 4 m;
  touchdown at 24 m/s, stopped 134 m past the parked spot (on the grass past the runway).
- `check_aircraft` (expert mode): **31 checks, 0 failures** (run before the easy-mode tuning,
  which touches only the easy path).
- Rendered views (`docs/evidence/easy-flying-20261114/capture.gd`, graphics, 1560 × 720): helicopter
  hovering with the touch ▼ button, turboprop easy status, F1 guide. The process exits 137
  (the hard exit) after saving.
- `tools/language_check.gd`: 4337 checks, 2 failed before the fix: the known
  `restaurant.miss_also` placeholders and zh readings; added readings for 簡 易 專 退 to
  `data/pinyin_zh.json` (備 質 素 暢 占 卜 揭 喬 臥 桌 are other work's and still lack them; not
  re-run). `tools/build_cjk_font.py` rebuilt the subset (1351 characters, 427 KB); its `--check`
  now reports 0 missing, which also covers 卜 占 喬 揭 暢 臥 質 from other uncommitted work.
- Not run: `check_helicopter_physics` (calls `drive_step()` directly, unaffected) and the
  quick/full suites. Not tried by hand on a phone; the tuning is from the headless flights only.

## Run button, plane Reset and quicker supermarket orders — 14 November 2026

User requests (movement + HUD buttons; shopping). Changed: `player_controller.gd` (walk 7.2,
run 12; hyper unchanged), `touch_controls.gd` (Run and Reset Buttons in the HUD, touch and
mouse; touch buttons under the shop cart hide instead of lifting off screen),
`vocabulary_hud.gd` (`game_buttons_hidden()`), `shop_session.gd` (cart + basket at once with
the clerk's line), `shop_order.gd` (`build_pool()` allow-list), `data/shops.json`
(`order_words`, 2 items, 1–2 each, cart max 3), `shop_order_panel.gd` (no ScrollContainer, card
fits content, cart ✕ ~1.7 ×), `hand_hold.gd` (basket inspect tilt 80°, fill 1.0),
`shopping_basket.gd` (`give()` passes kind "basket"; the given basket had been using the default
hand profile), docs (README controls, TOWN_DESIGN_BRIEF "Quicker orders", HAND_HOLD).
Guides: [README controls](../../README.md#controls-and-learning),
[quicker orders](TOWN_DESIGN_BRIEF.md#quicker-orders--14-november-2026).

- New `docs/evidence/run-button-shop-20261114/verify.gd` (graphics 1200 × 800 and 844 × 390, isolated
  HOME, `VT_FOCUS=supermarket`, so **not the full town**): **36 checks, 0 failures** (second run;
  the first found the basket using the default hand profile, 2 failures, fixed). Renders in that
  folder: `run_laptop_off.png`, `run_laptop_on.png`, `run_touch_on.png`, `plane_reset.png`,
  `order_start.png`, `order_phone.png`, `basket_inspect.png` (looked at). Exits 137 (hard exit).
- `tools/run_checks.py --only runtime_resources,language,compact_layout,part2,public_garden,profiles,activity_lifecycle,touch_controls,tutorial,shop_basket,minigame_launcher,grammar_class`
  (`VT_FOCUS=all`): PASS 10; NEW 2, both outside this work: `language` (the
  `restaurant.miss_also` placeholders and zh readings 備 質 素 暢 揭 喬 臥 桌, as in the easy
  flying entry above) and `compact_layout` (6 × "rigid move preserves scale" for ParkZoo
  animals; not traced, no zoo code was touched).
- Limitations: `plane_reset.png` shows the button only; `reset_to_start()` belongs to another
  workstream and is called only when present (absent in this tree). The carried basket's new
  hanging pose was not rendered close up. Historical `docs/evidence/customer-order-20261103/verify.gd`
  (not in run_checks) still expects the old rules (80-word pool, cart max 10) and will fail.
- Unresolved (P3): on a 844 × 390 phone the Inspect button (`hold_inspect_ui.gd`) overlaps the
  cart's Done button (it hides only under the dialogue box), and the top-right peek badge and
  gear overlap each other (seen in `order_phone.png`, `run_touch_on.png`; not changed here).

## Loading and title cutscene shots retaken — 16 November 2026

User: retake the pictures of the welcome tutorial's "Welcome to Bon Adventure!" cutscene so they show
the current town; the slideshow itself (`loading_screen.gd`, also the app's loading screen) is
unchanged. `tools/capture_app_art.gd` now aims its four shots at the town (all at 11:30, High
graphics so the sun casts shadows and there is no short-view fog): `shot_1` the front-yard
mahjong table and street (same view as 13 Nov), `shot_2` the EL ZOOLÓGICO gate with the animals,
`shot_3` the Washington statue garden with the farm barn, `shot_4` the SUPERMERCADO front. The old
shots 2–4 showed house plushes indoors and in the pool (Cocodrilo, no longer placed). New in the
tool: `VT_ART=shots` skips the avatar portraits, frames are taken with `force_draw()` and vsync
off (an occluded window stalled the first attempt; `--always-on-top` in the command line), shot
quality `SHOT_QUALITY` 0.5. Sizes (1280×720 WebP): 71.6 / 31.4 / 57.1 / 25.5 KB → 47.6 / 62.6 /
70.0 / 29.3 KB (186 → 209 KB). The kept files are the tool's 0.8-quality render re-encoded at 0.5
(the tool now saves at 0.5 directly). `backdrop.webp` was left as it was (shot 1's view is
unchanged). Checked by looking at all four images; the cutscene was not played in the game, and
no check suite was run (art only). `dev_focus.txt` = `all`.

## Docs reorganised into game / guides / evidence / archive — 16 November 2026

User request: make the docs easier to navigate. The game guide (`docs/game/`) was added, then
every other entry at the top of `docs/` moved with `git mv` into `guides/` (current
references and their folders, plus `design-references/`), `evidence/` (179 dated folders, and
`town-checks/` for the 220 loose October check, capture, screenshot and fixture files) or
`archive/` (11 superseded reports); see the [layout](../README.md#folder-layout). A script
rewrote 5,364 references in 2,389 files (markdown links recomputed from each file's new place;
`res://docs/…`, `docs/…` and `BonAdventure/docs/…` paths; docs-relative paths in backticks;
the ignored `.import` sidecars; the memory notes). By hand: the six Python checks in
`evidence/town-checks/` and `evidence/editor_import/verify.py` find the project folder three
levels up (`parents[3]`), and four old capture scripts (`render_aircraft.gd`,
`render_road_physics.gd`, `measure_buildings.gd`, `capture_exterior_audit.gd`) now write into
their own evidence folders instead of the top of `docs/`. The vocabulary report also writes
`docs/game/words.md` (per-game word lists) and counts only the supermarket's 16 `order_words`
as Grocery Run's tested words (186 → 130 tested words in the summary).

Checks:
- Link and path scan of every tracked markdown file and every `res://docs/` path: before the
  move 23 broken links (deleted lion folders, old hospital audit images, two stale anchors) and
  28 missing `res://` paths (output files never generated, prefixes); after the move the same
  23 and 28. All 56 scripts the runner lists exist at their new paths.
- Full suite once (`python3 tools/run_checks.py full`, `dev_focus.txt` = `all`, 2,178 s):
  **PASS 47, NEW 6, TIMEOUT 3**. No log shows a missing file, a load error or an old `docs/`
  path; every check ran from `res://docs/evidence/…` or `res://docs/guides/…`. The failures
  are not from the move. They match game changes since the last recorded full run (none was
  recorded after 9 Nov 2026), and no baseline run was made before the move to confirm it:
  - `building_lookup` ("minimap found"), `map_facades` (TIMEOUT: `TownMinimap` not found),
    `electrical_box` (TIMEOUT: a null HUD part at `verify.gd:113`): the minimap and full map
    are hidden since 14 Nov 2026 (README "Hidden features" names these checks).
  - `rooftops` (jump counters): infinite jump is off at start since 14 Nov 2026; its two
    expected entries no longer fail (runner: update `data/expected_check_failures.json`).
  - `bath_fixtures` (TIMEOUT: home toilet/faucet counts, "Guest bathroom faucet" not found):
    the family bathroom was re-laid on 13 Nov 2026.
  - `day_night` (47 lamp heads, expected 27): lamps added with the parked vehicles and lots,
    14 Nov 2026 (not confirmed).
  - `compact_layout` (zoo animals' scale under rigid moves): the clay animals of 11–12 Nov 2026
    (not confirmed).
  - `building_access` (54 market word-card labels) and `language` (`restaurant.miss_also`
    placeholders in Chinese, missing pinyin readings): data and word-card behaviour, not
    investigated.
  None of these was fixed or added to `data/expected_check_failures.json`; they need their
  own follow-up.

## Triage of the 16 November full-run failures — 16 November 2026

Follow-up to the entry above (9 checks NEW or TIMEOUT). Each cause was confirmed by reading the
check and the change it points to (`building_access` also with a one-off diagnostic run of the
market click); none needed a game behaviour change.

| Check | Cause (confirmed) | Change |
|---|---|---|
| `language` | `restaurant.miss_also` zh named `{name}`, es/en do not; 9 characters without pinyin (備 版 質 素 暢 揭 喬 臥 桌, from newer phrases and signs) | Data fixed: zh line now "還想要{want}，但你上了{dish}。"; the 9 readings and the word 喬治 Qiáozhì added to `data/pinyin_zh.json` |
| `compact_layout` | Base step `animals_bigger` (user, 11 Nov 2026) scaled every ParkZoo animal; 6 still carry the old compact-move transform | ParkZoo animals: scale must stay uniform (proportions), not equal |
| `building_lookup`, `map_facades`, `electrical_box` | Minimap and full map hidden since 14 Nov 2026 (`Features.MINIMAP` / `FULL_MAP`); `map_facades` and `electrical_box` hit a null and hung until the timeout | Map and minimap parts run only while the switch is on; `building_lookup` checks no map exists while both are off; `electrical_box` expects the map button and minimap to follow the switches |
| `building_access` | Any click closes an open word card (user, 14 Nov 2026), so every other market click only closed the previous card | The check closes the card before each click |
| `rooftops` | Infinite jump off at the start since 14 Nov 2026; the chapel "Faceted roof cap" no longer exists (chapel rebuilt 12 Nov 2026) | New checks: off at the start, no second jump in the air, lands; then turned on (as the I key) for the successive jumps. Chapel entry removed from `data/expected_check_failures.json` |
| `day_night` | 47 lamp heads, 4 glow materials: 27 street and bridge lamps + 6 zoo-zone lamps (12 Nov) + 14 chapel lanterns and chandelier bulbs (11–12 Nov) | Expectations 47 and ≤ 4; lamp-batch lookup skips ShaderMaterial overrides |
| `bath_fixtures` | Bigger home (13 Nov 2026): three bathrooms; `Guest bathroom faucet` gone; vanity basins nested in each vanity | 3 toilets + 7 faucets (words 5 toilet, 9 faucet); 3 vanity basins keep `sink`; the faucet test uses `Family vanity faucet` |

Runner: a `SCRIPT ERROR` raised in the check's own script (or another script under `docs/`)
ends its coroutine and Godot then idles until the timeout. `tools/run_checks.py` now kills such
a run once its log has been quiet for 30 s (`STALL_SECONDS`) and reports CRASH with a "stalled"
note (README Verification). Tested offline on the 16 Nov logs: only `map_facades`,
`bath_fixtures` and `electrical_box` match; not yet seen on a live stall.

Run once: `python3 tools/run_checks.py --only language,compact_layout,building_lookup,building_access,rooftops,day_night,map_facades,bath_fixtures,electrical_box`
(`dev_focus.txt` = `all`, 117 s): **PASS 7, KNOWN 2, NEW 0**. KNOWN: `rooftops` the two barn roof
normals; `map_facades` "street ray picks new facade HOSPITAL" (P3, since 28 Oct 2026). Infinite
jump rises 1.64 → 4.27 m over six jumps. Not run: the rest of the full suite. Remaining noise,
not a label: `day_night` still logs 168 engine errors from the typed `cloud_materials.has()` at
`verify.gd:90` (same ShaderMaterial cause as the lamp lookup, P4). Headless checks only; no views
rendered (no visual change).

## World signs: readable supermarket signs — 16 November 2026

User: signs were hard to read. Rendered before/after views at 1280×720 and as the web LOW tier
on a landscape phone (844×390, MSAA off, 3D at 0.8), with an inventory of every supermarket
label: [evidence](../evidence/world-signs-20261116/) (`capture.gd`, `before-*` / `after-*`).
Cause confirmed: letter size against reading distance (capitals under about 6 px blur), plus
translations shrinking signs (BAKERY, PRODUCE to half size) and no outline on low-contrast
boards. Rule recorded in the blueprint's
[sign readability](BUILDING_DESIGN_BLUEPRINT.md#sign-readability); component
`scripts/world/world_sign.gd` ([World signs](COMPONENTS.md#world-signs)), hooked into
`sign_language.gd` (shrinks a world sign only to its board, never below its minimum) and
`tools/bake_unit.gd` (`keep_signs` keeps the base pixel size).

Supermarket step `world_signs` (baked once, from the committed scene): 35 labels. Department
bands 0.52 → 0.60 m letters (read 18 m), outlined where the board lacks 4.5 contrast; OPEN tags
0.10 → 0.17 m, the two tags grown to fit ABIERTO / OPEN / 营业中; PRODUCE 0.15 → 0.20 m on two
lines; MARKET 0.19 → 0.27 m; lane numbers, price, facades already met the rule (kept). A first
bake also widened the lane number cubes (the back-side OPEN label found the cube as its board);
fixed by choosing the board by colour, the committed scene restored and baked again.

Run once (`dev_focus.txt` = `all`): `python3 tools/run_checks.py --only world_signs,signs`:
**PASS 2**. `world_signs` (new, full suite): 35 world signs, 249 checks in en/es/zh, 0 failures;
`signs`: 574 checks, 0 failures. Renders: one batch with `VT_FOCUS=supermarket` (supermarket
only, not the full town). Not run: the rest of the full suite.

Limits: from the entrance the back-wall bands (SEAFOOD, MEAT, BAKERY, 33 m) are still about
3.5 px capitals on a phone; the rule targets 18 m and the boards cannot take larger letters.
Other buildings are not migrated: the check reports labels under 0.15 m in Airport (74),
RelocatedSites (68), Buildings (53), Restaurants (41), Warehouse (16) and Vehicles (12)
(follow-up in [COMPONENTS open items](COMPONENTS.md#open-items), P2).

## Bon Adventure logo, display title and app icon — 16 November 2026

User: put the new logo on the first page, try VTracer on it, show the game as "Bon Adventure:
Little Town of Words" and make the icons from the logo. `config/name` is unchanged (a separate
rename owns it with the save move). Details, comparison and screenshots:
[evidence](../evidence/bon-adventure-logo-20261116/README.md).

- Run once: `python3 tools/run_checks.py --only language,app_flow` (`dev_focus.txt` = `all`,
  37 s): **PASS 2**. Full suite not run: only the title page, `app.title`, the icons and the
  deploy step changed.
- Title page rendered at 1280 × 720, 1440 × 900, 1100 × 620, 844 × 390, 667 × 375 and
  2532 × 1170 (`capture.gd` there) and inspected: logo centred above Play, nothing clipped.
- **Not tried:** a web export or deploy (the page title and manifest rewrite was only tried on
  the published files), installing on a phone, the new icon on a real home screen.

## Library game review — 17 November 2026

Rosa's book-sorting game after the user's review
([design](TOWN_DESIGN_BRIEF.md#library-return-cart-and-book-sorting-game--13-november-2026)):
Rosa's check removed, a wrong shelf wobbles the book back into the hand, new mid-game, start and
win dialogue (`library_session.gd`, `data/phrases.json` group `library`). Godot 4.7.2, isolated
`HOME`, each run once:

| Result | Checks |
| --- | --- |
| PASS | `docs/evidence/library-dialogue-20261117/verify.gd` (new; runner `library_sorting` now points here instead of the 13 Nov check), graphics, `VT_FOCUS=library VT_SPAWN=none`: **37 checks, 0 failures**. Renders in the same folder: `talk-left`, `wrong-wobble`, `wrong-back-in-hand`, `right-shelf`, `win-recap` (Spanish) |
| PASS | runner (`VT_FOCUS=all`): `runtime_resources`, `language` |
| CRASH, not this work | `library_shelves`: a SCRIPT ERROR at its line 50. Its sign table and counts still describe the 8 categories and 24 books from before 16 Nov 2026 (no TRAVEL / NATURE, expects 24 books); stale since the six-categories change. Its Rosa part (greeting → Yes → `library.start`) is covered by the new check. Priority: medium (fix the fixture) |

Not run: the full suite and the runner's headless `library_sorting` (the same script ran once
with graphics above). The `win-recap` render's camera sits behind the cart, but the dialogue box
text is readable.

## Library new titles, tracking and cosy room — 17 November 2026

Second library round the same day
([design](TOWN_DESIGN_BRIEF.md#library-return-cart-and-book-sorting-game--13-november-2026)):
steps `new_titles`, `rear_display`, `cosy_room` baked into `library.scn` (`bake_unit.gd -- library`:
3 steps, no errors; the scene grew from 818 KB to 1,016 KB); new covers, words, sign
translations, practice tracking and replenishing. Godot 4.7.2, isolated `HOME`, each run once:

| Result | Checks |
| --- | --- |
| PASS | `docs/evidence/library-refresh-20261117/verify.gd` (new; runner `library_sorting` now points here), graphics, `VT_FOCUS=library VT_SPAWN=none`: **109 checks, 0 failures** (categories, titles and words, header words, free gaps for every book, desks gone, display/Rosa/cart spots, cart filled at load, practice: wrong first try negative, right positive, retry not recorded, resting with no "!" and `all_back`, replenish borrows the books and fills a new cart). Renders: `cart-new-titles`, `headers`, `talk-left`, `wrong-wobble`, `wrong-back-in-hand`, `right-shelf`, `win-recap` |
| PASS | runner (`VT_FOCUS=all`): `runtime_resources`, `language`, `signs` |
| PASS | `tools/vocabulary_report.gd -- --write` (`VT_FOCUS=all`): 5530 checks, 0 failures; `library_rosa` tests 24 words; files updated (`docs/game/words.md`, report). Report-only notes: *soccer* and *tennis* show as "placed but not clickable" (their only objects are the picture books, whose pick areas are built at load); new "same text" group: zh 足球 for *soccer* and *soccer ball* |
| Views | `capture.gd -- before` / `-- after` in the same folder: top, entrance, rear |
| PASS (fixture fixed) | `library_shelves` (runner, `VT_FOCUS=all`): **136 checks, 0 failures** after updating its stale fixture (`docs/evidence/library-shelves-20261111/verify.gd`: sign table from `SignLanguage`, counts from `Library.BOOKS`, display books carry their topic word, the "west computer desk" route replaced by one to the NEW BOOKS display). The first run of the updated fixture had 2 route failures from the new route ends: the west aisle route ran into the cosy room's rear corner plant in the old desk corner (now ends at z 50.6, before that dead end) and a guessed route between Rosa and the cart (dropped). Second run: PASS. This closes the CRASH recorded in the first-round section above |

Not run: the full suite.

Same day, after the run above: the game was named **Library Helper** (user; `phrases.games.library_rosa`
and the guide). Not re-run for this rename (data-only; `language` was not re-run). `docs/game/words.md`
still shows the heading "Shelf Mission" until `tools/vocabulary_report.gd -- --write` runs next
(the full suite does); the learning card links to that anchor until then.

## Tutorial polish, supermarket lot and logo — 18 November 2026

User's polish list ([evidence](../evidence/tutorial-polish-20261118/README.md),
[design](ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial)): tutorial timings and screen, face-to-face
close-up cuts, the market act, the basket, base step `tutorial_lot_clear` (`bake_unit.gd -- base`:
1 step, no errors; 15 motorcycles removed, the white car and the truck moved; reviewed with
`compare_scenes.gd`), the logo's brown gaps. Godot 4.7.2, isolated `HOME`, `dev_focus.txt` = `all`.

| Result | Checks |
| --- | --- |
| PASS | `tutorial` (runner, now `docs/evidence/tutorial-polish-20261118/verify.gd`): **168 checks, 0 failures**. On the way: a native crash from the check calling a freed shop node (check fixed) and a real race (the reply button could stay away when EN was held while the camera eased in; fixed in `tutorial.gd`). One graphical run before the last small change (cashier name, list ✕): 166 checks, 0 failures, views saved |
| PASS | `vehicle_arcade`, `zoo_vehicles` (updated to 16 parked cars, 28 road vehicles, the scooter for the motorcycle tests; first run found the white car on the lot's drive and the truck 0.3 units in the truck corridor, both fixed and rebaked) |
| PASS | `shop_basket`, `app_flow`, `day_night`, `interaction`, `vehicle_boarding`, `runtime_resources`, `language` (after adding the missing pinyin for 豚, from the capybara commit) |

Not run: the full suite. Not checked on a real phone.

## Bank interior refresh — 18 November 2026

[Record](TOWN_DESIGN_BRIEF.md#bank-interior-refresh--18-november-2026). Bake: `tools/bake_unit.gd -- bank`
(5 steps; 8 door parts stripped; 6 palette material files written), then once more for the sixth step `chair_backs`. Checks, run once each on the baked unit:

- `docs/evidence/bank-refresh-20261118/verify.gd` (on the first bake; `chair_backs` only recolours
  four meshes and was not re-checked; headless, `VT_FOCUS=all`, isolated `HOME`):
  144 checks, **1 failure: "mascot pig behind the reception desk"**: `Animals/PigBank` does not
  exist in the town (it is also absent from the before views), so the 28 Oct mascot check no longer
  applies; not caused by this change. Everything else passed, including doors registered, closed
  doors blocking and opened doors passable, rooms behind reachable, no "•" door labels, and the
  teller line, window-2 monitor and BearBanker unmoved.
  (A first run had two errors in the new check itself, door leaves measured in their own frame
  and an un-awaited coroutine; fixed and run once more.)
- The 28 Oct `bank-interior-20261028/verify.gd` is superseded by the new check (it looks for the
  word on the door roots, which are now the components). It is not in `tools/run_checks.py`.
- Views: `capture.gd` with `VT_FOCUS=bank` (only the bank loaded), noon, eye level: before and after
  sheets in the folder. Not checked: night, a phone, the full suite.

## Bank teller game — 18 November 2026

New minigame **Next, Please!** (name proposed) at the bank's teller window 2
([design](TOWN_DESIGN_BRIEF.md#bank-teller-game--18-november-2026),
[learning card](../game/minigames.md#next-please)); no building change, no bake. Godot 4.7.2,
isolated `HOME`:

| Result | Checks |
| --- | --- |
| PASS | `docs/evidence/bank-teller-20261118/verify.gd` (new, runner `bank_teller`), graphics, `VT_FOCUS=bank VT_SPAWN=none`: **93 checks, 0 failures** (amount stages, balances, change rule, every `teller.*` phrase in es/en/zh, the banker on the shared host, the fade behind window 2, customers walking up and queueing, the monitor balance, wrong "not enough", wrong count with the amount in words, retry keeping the tray, change with a $100 refused, bills-only money screen with no coins, the leave question and "no", the end in the lobby, leaving mid-game). Run twice: the first run (also 0 failures) showed "Ventanilla 2" wrapping on the idle monitor; fixed (smaller idle text) and run once more for the screenshots |
| Views | [customer asks](../evidence/bank-teller-20261118/customer-asks.png), [monitor balance](../evidence/bank-teller-20261118/monitor-balance.png), [money screen](../evidence/bank-teller-20261118/money-screen.png), [lobby view](../evidence/bank-teller-20261118/teller-view.png) |
| PASS | runner (`VT_FOCUS=all`): `runtime_resources`, `signs` |
| NEW (not from this change) | runner `language`: zh characters 便 逛 have no pinyin reading. They come from the existing `app.explore` line (隨便逛逛！), not from the teller phrases (24 new teller characters and 12 words were added to `data/pinyin_zh.json`) |
| PASS | `tools/vocabulary_report.gd -- --write` (`VT_FOCUS=all`): 5452 checks, 0 failures; `teller_bank` tests no words (generated amounts); files updated (`docs/game/words.md`, report) |

After merging `main` (1519cbd, the shared progression system) and adding `Board.add_miss` once
per missed customer: runner `bank_teller` PASS (headless), `runtime_resources` PASS, `language` the
same NEW 便 逛 as above.

After merging `main` (2a2da89, the bank interior refresh): `verify.gd` graphics,
`VT_FOCUS=bank VT_SPAWN=none`: **93 checks, 0 failures**; the four views above were re-rendered
on the recoloured bank (window 2, the monitor, BearBanker and the customer paths unchanged).

After merging `main` (f7b8c24, electronics makeover and docs cleanup): runner `bank_teller` and
`runtime_resources` PASS, `language` the same NEW 便 逛; `docs/game/words.md` regenerated to resolve
its conflict (`vocabulary_report.gd -- --write`, `VT_FOCUS=all`: 5451 checks, 0 failures).

Then (user, 18 Nov): the name was approved, and `tools/build_cjk_font.py` rebuilt
`fonts/NotoSansTC-SemiBold-subset.ttf` (1391 characters, 439 KB); `--check`: 1396 needed, 0 missing.

Not run: the full suite.

## Library Helper polish — 21 November 2026

User requests: a book zooms in on its cover by itself when picked up (gentle pace, a tap
anywhere closes, no ✕); the "EN" badge and gear 10 % bigger and held in from the right edge
(phone corners); the win line zooms in on Rosa and drops the "Remember …" recap; a new random
cart of 3–6 books once the player has walked away (replaces the 300 s rest); the second start
line reworded; a bigger right-shelf burst. Design record:
[third round](TOWN_DESIGN_BRIEF.md#library-return-cart-and-book-sorting-game--13-november-2026).

| Result | Check |
| --- | --- |
| PASS | `docs/evidence/library-polish-20261121/verify.gd` (new; runner `library_sorting` now points here), isolated HOME, `VT_FOCUS=library VT_SPAWN=none`, headless: **125 checks, 0 failures**. The same script with graphics (1280 × 800) rendered `talk-left`, `book-zoom`, `wrong-wobble`, `wrong-back-in-hand`, `right-shelf`, `win-zoom`, `cart-new-titles`, `headers`; that run had 4 failures in the walk-away step, from the check's own far spot (15.8 m from Rosa, inside the 16 m call distance), fixed in the check and passed headless |

Not run: the full suite; `docs/evidence/hand-hold-20261113/verify.gd` (books now open the close-up
on pick-up through `toggle()`; that check's inspect steps were not re-run).

Later the same day (user): the book close-up starts with the E press (0.75 s glide, no delay), a
game releasing the inspected book ends the close-up at once, and the new
[results screen](MINIGAMES.md#results-screen) follows Rosa's thanks.

| Result | Check |
| --- | --- |
| PASS | `docs/evidence/library-polish-20261121/verify.gd`, graphics, isolated HOME, `VT_FOCUS=library VT_SPAWN=none`: **132 checks, 0 failures** (adds: zoom on the E press, the results screen after the thanks with every word new in a fresh profile, the wrong first try as struggled, Continue, no results after "I'll help later", Play again starts a fresh cart). Render `results` (taken before zero stats were hidden: it still shows "0 Words practiced") |
| PASS | `docs/evidence/results-screen-20261121/verify.gd` (new, runner `results_screen`), graphics: **21 checks, 0 failures**; after hiding zero stats, headless (fit checks skipped): **18 checks, 0 failures**. Renders `results-laptop`, `results-see-all`, `results-practice`, `results-phone` (844 × 390) |

Three Chinese titles were reworded to characters in the font subset (*Case Closed!* 案子完成了！,
*Lesson Complete!* 上完課了！); the check fails if a results phrase needs a missing character.
Not run: the full suite; the hand-hold check. Touch was not tested
on a device, and the phone-corner inset was judged from the layout numbers, not on an iPhone.

## Results screen for every minigame — 21 November 2026

User: "wire them up". `scripts/learning/results_flow.gd` shows the results card for every learning
game that ends `completed`, after the NPC's thanks, with the game's title and line and a town
mission it completed (Quest updated! + XP); Play again relaunches the game through its host. The
board's `completed` now also covers games with no round target (Grocery Run), and Library Helper
and Desk Dash call the new `Board.complete()`: before this, these three never completed, so their
town missions (two of them starting missions) could not be done. Pastimes are unchanged. Seven
titles were proposals; the user approved them on 22 Nov 2026, changing two (Who's Who? *Family
Matched!*, On the Menu *Orders Received!*; [list](MINIGAMES.md#results-screen)).

| Result | Check |
| --- | --- |
| PASS | `docs/evidence/library-polish-20261121/verify.gd`, headless, isolated HOME, `VT_FOCUS=library VT_SPAWN=none`: **134 checks, 0 failures** (adds: the card waits for the thanks, then shows with the Library Helper mission) |
| PASS | `docs/evidence/results-screen-20261121/verify.gd`, headless: **22 checks, 0 failures** (adds: a finished Spot the Suspect shows *Case Closed!* with its mission and XP; nothing for a game ended early or a pastime; every learning game has a title and line). The graphics run before it stopped drawing frames after its fourth capture (no error; the known window stall) and was not repeated; it had rendered `results-quest` |
| PASS | `docs/evidence/activity-lifecycle-20261112/verify.gd`, headless: **6 checks, 0 failures** (the board's completed summary) |
| 3 FAIL (headless window) | `docs/evidence/passport-missions-20261121/verify.gd`, headless with `VT_FOCUS=library`: **77 checks, 3 failures**, all "page fits the window" against the 64 px headless window (the check is meant to run windowed); mission completion and rewards passed |

Godot exits with code 134 after printing each summary (abort on quit), as in the earlier runs today.
Not run: the full suite, the windowed missions check, and a real play-through of each game to its
end (only Library Helper's end was played in a check; the other games rely on the board signal).

## Town stamp places — 21 November 2026

User's list of coin spots, with three building changes: the supermarket storage room and staff
door, the bank's openable safe, and the enlarged chapel with a bell tower, ladder and ringable bell
([record](TOWN_DESIGN_BRIEF.md#stamp-places-storage-room-bank-safe-grand-chapel--21-november-2026),
[coin list](ACHIEVEMENTS.md#where-the-coins-are)). Units re-baked: `supermarket`, `bank`, `chapel`.

| Result | Check |
| --- | --- |
| PASS | `docs/evidence/stamp-places-20261121/verify.gd`, windowed, isolated HOME, `VT_FOCUS=all VT_SPAWN=none VT_NEARBY=0`: **132 checks, 0 failures** (18 coins at their spots, scale 1, no body or prop overlap, a real standing place in reach and sight; the safe: wheel turns first, door opens, coin only collectable when open; the staff door opens; a simulated ladder climb reaches the belfry; the bell rings and comes to rest). Pictures in that folder inspected |

Godot exits with code 137 after the summary (crash at quit, as in earlier runs). The log also
shows parse errors in `scripts/learning/teller_session.gd`, which another session was editing at the
time (not part of this work). Not run: the full suite, the language check, the web export and a
phone. The town map image was not re-baked for the bigger chapel.

## Soft sun and moon — 22 November 2026

Scope: the sky disc in `scripts/world/day_night.gd` and the new `shaders/sky_disc.gdshader`
([guide](performance/README.md#day-night-cycle--9-november-2026)). User, 21 Nov 2026: the solid sun
ball looked outdated and, on Low graphics, sat in front of fogged buildings.

- `python3 tools/run_checks.py --only day_night` (full town): **65 checks, 0 failures**, labelled
  CRASH by Godot's known exit abort (`recursive_mutex lock failed`). The first run also logged a
  non-finite transform error when the disc had zero size; guarded and run once more: no such
  error. Still logs 174 typed-array `has()` errors from the check's own cloud lookup (known noise).
- Rendered views (graphics window, isolated `HOME`, `dev_focus` = all):
  `docs/evidence/soft-sun-20261121/capture.gd` → `sheet-low.png`, `sheet-high.png` (street,
  plaza and raised view at 06:10, 06:40, 12:00, 17:45, 18:20, 18:35, 00:00). Trees and buildings
  now cover the sun; at 18:20 it sinks into the haze, at 18:35 only a faint glow remains; the
  moon has a small halo. Not checked on a phone or in the web build.

## Bigger stamp coins, collect error, Stamps page — 22 November 2026

User: "there's a bug when I obtain the town coin" (`_mover_box: Trying to assign invalid previously
freed instance`), "make the coin 50% bigger", and a better Town stamps page with the coin's real
face instead of a star.

- **Error:** `indoor_visibility.gd` tracks nodes that animate (the coin) as movers; after a
  collected coin freed itself, assigning it to a typed variable failed. It now checks validity
  before every typed assignment from a chunk.
- **Coin:** radius 0.3 → 0.45 m. Library, farm barn, furniture and electronics spots moved a
  little to stay clear of props; the bank coin stands still facing out (`face`) in the safe.
- **Stamps page:** progress strip and a 6 × 3 grid of coin faces (`passport_panel.gd`).
- **Chinese font:** `tools/build_cjk_font.py` rebuilt the subset: 34 characters were missing
  (some from other work), including 印 and 浮 in the Passport. `--check` now: 0 missing.
- The stamp-places check hung for good when its window was hidden behind others (it waited for
  `frame_post_draw`); it now uses `RenderingServer.force_draw()`.

| Result | Check |
| --- | --- |
| PASS | `docs/evidence/stamp-places-20261121/verify.gd`, windowed, isolated HOME, `VT_FOCUS=all VT_SPAWN=none VT_NEARBY=0`: **133 checks, 0 failures**; the log has no "previously freed" error (the bank coin is collected in the run). Pictures of the moved coins inspected |
| PASS | `docs/evidence/stamps-page-20261122/verify.gd`, windowed, `VT_FOCUS=library`: **22 checks, 0 failures** (coin faces, faded when not found, bar 5/18, fits 1280 × 800 and 900 × 560); pictures inspected |

Exit codes 137 after the summaries (crash at quit, as before). The other session's
`teller_session.gd` parse errors still show in the logs. Not run: the full suite, the passport
missions check, a web export or a phone.

## One set of flying controls, ▲ / ▼ buttons — 23 November 2026

User: one simple, consistent control for the plane on all devices, with ascend and descend buttons;
then the same for the helicopter ([flying controls](aircraft.md#flying-controls)). Easy flying and
the C expert mode were replaced by one scheme for both aircraft; ▲ / ▼ are HUD Buttons shown on
every device while flying (`touch_controls.gd`), W/S set the speed, and W alone takes off and
levels at 20 m. The plane's pitch correction is softened above 38 m/s (it bobbed at 48 m/s).

- `python3 tools/run_checks.py --only easy_flying,aircraft,vehicle_arcade,helicopter,runtime_resources`
  (full town, final code, once): `easy_flying` **17 checks, 0 failures** (5 new: ▲ / ▼ show in
  both aircraft and not on foot and hold up / down, faster / slower on the stick, take-off on the
  stick alone), `aircraft` **29, 0** (the F-flaps lines removed), `vehicle_arcade` **104, 0**,
  `helicopter` **34, 0**, `runtime_resources` **PASS**. The four town checks are labelled CRASH
  by Godot's known exit abort (`recursive_mutex lock failed`) after their summaries; it was not
  caused here (same abort on 21 Nov; suspect: the passport commit's lambda on the static
  `Missions.shared()` singleton). **P2.** While tuning, `easy_flying` was run four more times.
- Rendered views (graphics, isolated `HOME`): `docs/evidence/flying-controls-20261123/capture.gd`
  → helicopter with a mouse and with touch, the plane on the runway, the F1 guide. The plane's
  boarding toast was cut off at the right edge; shortened (not re-rendered).
- Not done: a hands-on play-test, a phone or the web build; multi-touch hold of ▼ with a second
  finger while the stick is held relies on the same GUI path as Run (not tested here).
  `docs/evidence/run-button-shop-20261114/verify.gd` still names the removed `_down_rect`
  (historical check, not in run_checks).

## Smaller plane, new flight model — 23 November 2026

User: the plane felt unnatural, its up / down tilt was inconsistent and it kept wobbling up and
down with no input; make it a smaller, slower plane, rewriting it if better. The aerodynamic
model plus its easy-flying autopilot was replaced by a steady arcade model (`turboprop.gd`
`fly_step()`; [flight model](aircraft.md#flight-model)), the plane is shown at 0.65 size with
BonBon to scale, and the chase camera is closer. `check_aircraft.gd` was rewritten for it.

- `python3 tools/run_checks.py --only aircraft,easy_flying,vehicle_arcade,vehicle_doors,vehicle_boarding,helicopter`
  (full town, once on the final code): `aircraft` **34 checks, 0 failures** (hands off for a
  minute: 0.0 m drift, 0 m/s vertical speed, 0 pitch change), `easy_flying` **17, 0**,
  `vehicle_arcade` **104, 0** (map edge: turned back 82 m past it), `vehicle_doors` **325, 0**,
  `vehicle_boarding` **181, 0**, `helicopter` **34, 0**. All six are labelled CRASH by the known
  exit abort after their summaries (see the entry above). Before that run, `aircraft` and
  `easy_flying` ran once each and failed 2 + 1 checks (test setups and a parked-height snap; fixed).
- Rendered views (graphics, isolated `HOME`): `docs/evidence/small-plane-20261123/capture.gd` →
  parked beside BonBon, cockpit, take-off, climb, turn and level flight, flown with the real
  Input actions in the chase view.
- Not done: a hands-on play-test, a phone or the web build. `render_aircraft.gd`'s four older
  previews were not re-rendered (they show the full-size plane).

## One graphics setting, flight view — 23 November 2026

User: one consistent graphics setting that works on a phone, everything built for High removed;
a height-based view from the air with no height limit and fog high up, without risking the frame
rate. [Setting, flight view and numbers](performance/README.md#one-graphics-setting-and-the-flight-view--23-november-2026),
[view from the air](aircraft.md#view-from-the-air). Code: `render_culling.gd` `apply_view()`,
`day_night.gd` `set_view_distance()`, `vehicle_controls.gd` `update_flight_view()`,
`player_controller.gd` `flight_tilt`; removed from `game_settings.gd`, `settings_panel.gd`,
`perf_readout.gd`, `nearby_units.gd`, `bake_town_map.gd`, `capture_app_art.gd` and the
`settings.graphics*` phrases.

- `python3 tools/run_checks.py --only runtime_resources,day_night,easy_flying,vehicle_arcade,app_flow,aircraft`
  (full town, isolated `HOME`): `runtime_resources` **PASS**, `day_night` **62 checks, 0
  failures** (no sun shadows, depth fog to 130 m; its High assertions removed), `easy_flying`
  **17, 0**, `vehicle_arcade` **104, 0**, `app_flow` **24, 0**, `aircraft` **36, 0** (new: view
  330 m and fog to 330 m at 100 m up, back to 130 m after leaving the plane). Town checks are
  labelled CRASH by the known exit abort after their summaries. `aircraft` first failed because
  base.scn had been re-baked with the plane already at 0.65 size and `_ready` scaled it again
  (0.65³); `turboprop.gd` now sets the size absolutely, then it passed.
- The chase view's downward tilt with height (`flight_tilt`) was added after those checks; it
  ran only in the capture below (no errors), not in a check.
- Rendered and measured (graphics, isolated `HOME`): `docs/evidence/flight-view-20261123/capture.gd`
  → on foot, plane at 40, 100, 200 and 300 m with draw calls per view (table in the performance
  guide: 773 draws on foot, about 4,700 flying low over the town, 1,277 at 300 m). Draw calls,
  not triangles, are the cost of the longer view.
- Not done: a phone or the web build (frame rate there is unknown), the full suite, a hands-on
  play-test. Historical evidence scripts that call the removed `set_graphics()` / `GameSettings.graphics`
  were left as they were.

## Lagoon fish under the water and the swan boat — 23 November 2026

User: the pond fish should not block the swan boat and should be under the water. Two causes
stopped a boat driven at the fish: `solidify_figures()` gives every animal, the fish included, a
solid `FigureBlocker` box at runtime (layer 256), which the boat's hull sweep hit; and
`Geometry2D.is_point_in_polygon()` reads isolated points as outside the lagoon outline (one at
-19.37, 119.57, where the stern corner lands with the bow over the fish), so `afloat()` stopped the
boat in open water.

- Base step `fish_under_water` (base.gd, base rebaked): the fish's top 0.03 below the surface
  (lowered 0.925 zoo units), meta `figure_blocker` false, which `fit_blocker()` now honours. The
  bed is 0.88 deep and the fish 1.01 tall, so its belly dips into the bed. `compare_scenes.gd`:
  only the Fish transform and metas changed (plus sign metas the bake always strips).
- `swan_boat.gd` `on_lagoon()`: an even-odd test replaces the engine call; it disagrees with it on
  3 of 200,000 random points (those glitches) and nowhere else.
- `docs/evidence/fish-under-water-20261123/capture.gd` (graphics, isolated `HOME`): fish top
  -0.446 below the surface -0.416; the boat, driven at full pedal from 14 units north, passes the
  fish and stops on the far bank (z 102.99; before the fix z 116.3, bow over the fish).
  [fish.png](../evidence/fish-under-water-20261123/fish.png),
  [boat_over_fish.png](../evidence/fish-under-water-20261123/boat_over_fish.png).
- `python3 tools/run_checks.py --only seats_swan_boats`: **0 failures**, labelled CRASH by the
  known exit abort after its summary.
- Not done: the full suite, a hands-on drive with the player steering. Other lagoon animals were
  not changed.
- Later the same day (user screenshot: a hard horizontal line under the horizon flying at night):
  while a view distance is set, the sky below the horizon takes the fog colour (`day_night.gd`
  `_apply()`, re-applied when `set_view_distance()` switches between fog and haze). `day_night`
  check once: **62 checks, 0 failures** (CRASH label = known exit abort). Rendered
  `VT_NIGHT=1 … flight-view-20261123/capture.gd` → `night-height-100-m.png`: the view's edge fades
  into the sky, no line. Not re-checked: dawn/dusk keyframes, where fog and horizon colours differ slightly.

## Word pictures in the journal and results card — 23 November 2026

User decision: the in-world word card stays text only; nouns get a picture of their own town
object in the journal (row column and detail) and on the results card
([word pictures](ARCHITECTURE_REVIEW_PART1.md#word-pictures)). Whole town (`VT_FOCUS=all`).
- `docs/evidence/word-pictures-20261123/verify.gd`, graphics, 1600 × 1000: **18 checks, 0
  failures**; 621 pictures drawn in 11.5 s (19 ms each). The first graphics run reported 539
  pictures missing: the Godot window was covered, drew no frames and the check's 30-frame wait
  gave up (now 240 frames; a covered window only delays drawing in the game). After the review
  of the contact sheets, Places & Rooms (blank name signs) got no pictures; headless once on
  the final code: **17 checks, 0 failures**, 586 of 795 words with a picture. Exits 134 (known
  exit abort) after the summary.
- `run_checks.py --only vocabulary_book,results_screen` (headless, final code): **93 checks, 0
  failures** and **22 checks, 0 failures**, both labelled CRASH by the known exit abort
  (`recursive_mutex lock failed`) after their summaries. `vocabulary_book`'s column indices were
  updated for the new picture column.
- Rendered: `journal-furniture.png`, `journal-food.png`, `detail-chair.png`, `results.png` in the
  evidence folder (the journal and results shots predate the Places & Rooms exclusion, which they
  do not show). Contact sheets were reviewed, not kept.
- Not checked: the shop order panel's product pictures (same `draw()`, refactor only), the web
  export and a phone, the full suite.
- Same day (user: turn the weak ones off): `"picture": false` on 147 words in `data/words.json`
  (new field in `tools/word_data.py`, which passes). Headless once: **19 checks, 0 failures**
  (new: every flagged word has no picture), 439 of 795 words with a picture; exit 134 (known
  exit abort) after the summary. Not re-rendered: the flags only remove pictures, the rest are
  drawn as before.
- Same day (user: the animals faced away): Animals are viewed from their +Z. Graphics once
  (1600 × 1000): **21 checks, 1 failure**, 439 pictures in 9.2 s (21 ms each); exit 137 (known
  exit abort) after the summary. The failure was the check's own: it tested the first Food
  row, now *oil* (`picture: false`, correctly blank); the check now tests the first row with a
  picture (not re-run). Contact sheets reviewed: most animals face the camera; cat, monkey,
  field mouse, kangaroo and dog still show their back or side. Views in the evidence folder
  re-rendered by this run.
- Same day, web cost: Web preset (`tools/deploy_web.py --out <scratch>`, not published) with a
  temporary probe in scratch edits only (a profile with the tutorial done, every unit added,
  then frame times and per-picture timings; the probe was removed from the tree right after
  the export), served locally, headless Chrome 157 (GPU, vsync on, 1280 × 800 at 2×), Apple
  Silicon laptop, `docs/evidence/day-night-20261109/web_measure.py`. Per 4–5 s phase:

  | Phase | Pictures drawn | Mean frame | Frames > 50 ms (worst) | `get_image()` mean / max |
  | --- | --- | --- | --- | --- |
  | Town, journal closed | 0 | 16.7 ms | 0 (18 ms) | – |
  | Open journal (All; top rows have no picture) | 0 | 16.7 ms | 0 (41 ms) | – |
  | Category Animals (first pictures) | 6 | 18.0 ms | 2 (248 ms) | 3.8 / 9.0 ms |
  | Category Food & Drink | 6 | 17.1 ms | 1 (115 ms) | 3.0 / 8.9 ms |
  | Furniture, Clothing, Kitchen & Dining | 5–8 each | 16.7 ms | 0 (21 ms) | 4.4–5.4 / 9.7 ms |
  | Journal idle; reopened (cached) | 0 | 16.7 ms | 0 (21 ms) | – |

  Copying an object's meshes took under 1.1 ms. The two long frames come only with the first
  pictures of the session (likely one-time shader compiles of the picture view; the journal
  rebuild alone, in later phases, showed none). Not measured: a phone, Safari/Firefox.
- Same day, fix (user): the loading warm-up draws two pictures (`word_pictures.gd warm_up()`,
  called from `app.gd _warm_up()`). The same probe and setup once more: warmed *lion* and
  *apple*; every phase 16.7 ms mean, **no frame over 50 ms** (worst 46 ms opening the journal,
  as before the fix; 22 ms Animals, 23 ms Food & Drink, was 248 and 115 ms); `get_image()` 3–8 ms
  mean, 13 ms max. Probe edits removed after the export. Not run: the native checks (the warm-up
  returns at once headless, and the word-pictures check loads Main without the app's loading
  screen).

## NPC registry, idle chatter, farmer, standing spots — 23 November 2026

Coordinator task (user decisions 23 Nov): one registry for every NPC (`data/npcs.json`, replaces
`data/house_characters.json`), idle chatter with brush-offs, the barn farmer, natural standing
spots. Guide: [NPCs](NPCS.md); evidence: [npc-registry-20261123](../evidence/npc-registry-20261123/README.md).
Whole town loaded (`dev_focus.txt` = `all`, VT_FOCUS=all, isolated HOME). Every Godot check
aborts at exit after its summary (`recursive_mutex lock failed`, signal 6, recorded in the civic
record above), so the runner shows CRASH; the labels are compared below.

| Result | Check |
| --- | --- |
| PASS | `npc_registry` (new, headless via the runner): **29 checks, 0 failures**, then the exit abort. Windowed render run: 29 checks, 0 failures; renders of the moved clerk, Dr. Li, the farmer and the chatter box inspected |
| PASS | `runtime_resources` 587 checked, 0 failures; `profiles` 38 / 0; `interaction` PASS; `flight_logic` 15 / 0 |
| PASS (exit abort) | `grammar_class` 111 / 0; `mahjong_table` 98 / 0; `bank_teller` 86 / 0; `bank_rework` 54 / 0 (second run: the first stopped on a parse error, `Session.MANAGER_HOME` read as a class member; fixed with static vars); `fitting_room` 36 / 0; `barn` 56 / 0; `plush_life` 22 / 0 |
| NEW (not from this change) | `language`: zh readings missing for characters of other sessions' text (逛 原 笛 囉 ...; every chatter and outfit character has one), and two `restaurants.gd` lines flagged as taught-language text (restaurants session) |
| TIMEOUT (not from this change) | `tutorial`: stale check, missing phrases `tutorial.more_to_show` / `to_supermarket` (recorded by the UI-fixes session the same day) |

Not run: the full suite, the web export, a hands-on play-test. The sports store and hospital
scenes were not re-baked (the registry moves the two NPCs at load).


## Walk-in hen house — 24 November 2026

User request (same day): the hen house at least 3× bigger and walk-in, a clear place to deposit
eggs, a button to drop one ([record](TOWN_DESIGN_BRIEF.md#walk-in-hen-house-crate-by-the-door-and-drop-button--24-november-2026)).
Barn re-baked (`tools/bake_unit.gd -- barn`, step `walk_in_hen_house`); the barn's box in
`data/nearby_units.json` set from a fresh `tools/nearby_units_data.gd` run (only the barn entry
taken, 59.4…88.8 × 73.4…85.7: the run also picked up other sessions' uncommitted changes). The
runner's `hen_house` check now runs `docs/evidence/hen-house-walkin-20261124/verify.gd`.
Runner with the whole town (`dev_focus.txt` = `all`, isolated HOME):

| Result | Check |
| --- | --- |
| PASS (exit abort) | `hen_house`: **66 checks, 0 failures**: floor 35 = 6.5× the old coop; BonBon's capsule fits outside the door, in the doorway, inside and by the nest boxes, not through the back wall; 11 spots, 12 cups, 6 hens (2 inside) in their yard; odds as before; every spot clear and reachable; taking an egg shows the toast, the crate arrow and the Drop button; crate delivery saved, arrow and Drop gone with an empty hand; Drop breaks the egg (toast, broken egg, no longer laid); carried off the farm: dropped, crate emptied. A first headless run had 1 failure (the arrow refreshed only every 0.25 s after delivery; `deliver()` now updates it at once) |
| PASS (exit abort) | `barn` 56 checks, 0 failures |
| PASS | `runtime_resources`, `interaction` |

"Exit abort" = the known `recursive_mutex lock failed` abort after the summary line (signal 6,
shown as CRASH by the runner); labels compared. Views (windowed run, VT_FOCUS=barn):
66 / 0 (exit 137 at teardown); `aerial`, `coop-door`, `inside`, `inside-to-door`,
`carrying-arrow`, `carrying-hud` (arrow over the crate, Drop button with its G badge, the toast)
and `dropped` inspected. An earlier windowed run stalled mid-pictures and was stopped. Not run: the full suite, the web
export, a touch device, a hands-on play-test (the checks call the egg's, crate's and Drop
button's actions directly).

## Hen house and eggs — 24 November 2026

User request: a hen house with hens that lay eggs to carry to a crate in the barn
([record](TOWN_DESIGN_BRIEF.md#hen-house-and-eggs--24-november-2026)). Barn re-baked
(`tools/bake_unit.gd -- barn`, step `hen_house`; 8 new palette materials); the barn's box in
`data/nearby_units.json` set from a fresh `tools/nearby_units_data.gd` run (only the barn entry
taken: the run also picked up other sessions' uncommitted building changes). Runner with the
whole town (`dev_focus.txt` = `all`, isolated HOME). Both Godot checks hit the known exit abort
after their summary (`recursive_mutex lock failed`, signal 6), so the runner shows CRASH; the
labels are compared below.

| Result | Check |
| --- | --- |
| PASS (exit abort) | `hen_house` (new): **49 checks, 0 failures**: coop, 11 spots, 12 cups, 6 hens in their yard; fresh profile finds eggs; odds over 2000 simulated 15-minute absences (mean 3.5, 5+ eggs rarer, cap 7 reached only over long absences, 3.1% golden); every spot clear and reachable by BonBon's capsule; egg to hand, to crate, saved; carried out of the farm gate: dropped, toast, broken egg, crate emptied. Windowed run (VT_FOCUS=barn): 49 / 0, views `docs/evidence/hen-house-20261124/` inspected |
| PASS (exit abort) | `barn` 56 checks, 0 failures |
| PASS | `runtime_resources` 592 checked, 0 failures; `interaction` PASS |

Not run: the full suite, the web export, touch, a hands-on play-test (the checks call the egg's
and crate's actions directly rather than pressing E).

## Next, Please! polish — 24 November 2026

Seated teller, one request line, thanks that move on by themselves, a hidden red alarm button
instead of "Call the police", teller chairs as seats, a wider staff door, no dialogue-box tail
([record](TOWN_DESIGN_BRIEF.md#next-please-polish--24-november-2026)). Bank baked
(`tools/bake_unit.gd -- bank`, steps `wider_staff_door`, `teller_seats`). Run with
`VT_FOCUS=bank` (not the full town), isolated HOME, graphics 1280 × 800.

| Result | Check |
| --- | --- |
| PASS (killed at exit, 137, after the summary) | `bank_teller_polish` (new): **36 checks, 0 failures** (second run; the first, 34 / 1, found the player still seated after leaving, fixed) |
| PASS (exit abort 134 after the summary) | `bank_teller` (18 Nov script, updated 24 Nov to the new flow: seated, one request, no "Check the account", no "Next!"): **85 checks, 0 failures** (86 before: the separate "monitor close-up" label merged into the account view). Its first run stopped on a parse error in the edit (a `:=` on an untyped value), fixed |
| FAIL 5 / 54, then a diagnostic run 0 / 54 | `bank_rework` (23 Nov script, updated 24 Nov the same way). First run: the manager's walk crossed the end of the wider staff door's open leaf (a real issue: her turn in the office, `MANAGER_DOOR`, moved from z 111.0 to 111.6), and four manager-scene labels failed (door opens, warning 1, the manager's close-up, warning 2) while the second visit and the firing passed. A copy of the script that logged the scene every 0.5 s after the payout (not the committed script) passed **54 checks, 0 failures**: she opened the door, walked out and gave both warnings. The four failures were not reproduced; the committed script was not run again (no re-runs for a pass). **P3:** watch for a timing race in the manager scene's first visit |

Not run: the full suite, `runtime_resources`, the web export, touch, a hands-on play-test.

## Vocabulary journal: sticker book, Places tab — 25 November 2026

[What was built and its rules](JOURNAL.md#built-so-far-25-nov-2026). `dev_focus.txt` = `all`;
every run with an isolated `HOME`, `VT_FOCUS=all`, `VT_SPAWN=none`; the full town.

| Result | Check |
| --- | --- |
| PASS | `vocabulary_report` with `--write` (headless): **5476 checks, 0 failures**; wrote the new `data/journal_places.json` (758 findable words, 42 not findable, 50 in 4 or more places). The same run also rewrote `report.csv`, `summary.md` and `docs/game/words.md`, only because Library Helper's runtime books now count as placed (car, cat … in the library) and the date; those three were left out of this change (unrelated; the next full run refreshes them) |
| PASS | `journal_sticker_book` (new; replaces `vocabulary_book`, whose table is gone): **50 checks, 0 failures** headless, and with graphics at 1280 × 800 (views in [`journal-sticker-book-20261125/`](../evidence/journal-sticker-book-20261125/)) |
| PASS | the same at 844 × 390 (phone landscape, `-844x390` views): **50 checks, 0 failures**. One earlier run at this size stalled for 10 minutes waiting for a drawn frame after its third view (the window was probably hidden; Godot draws nothing then) and was stopped; the next run completed |
| KNOWN-type, not this change | `language`: **5402 checks, 1 failure**: no pinyin reading for 掉 顆 舍, from the hen-house egg lines already committed (`data/phrases.json` at 278d40f1). This change's new Chinese characters (貼 詳 情) got readings in `data/pinyin_zh.json`. **P3:** add the three readings |

Not run: the full suite; `minigame_launcher`, `building_lookup` and `tutorial_polish`, which only
open and close the journal (`toggle_study_journal`, unchanged); the web export; real touch input
(swipes and taps were checked through the book's own handlers, not pushed screen events);
a hands-on play-test.

### Review fixes (same day)

A self-review found that game answers never counted as found (the book read only the studied
list, so airplane, car, soccer, tennis and bed could never be found). Fixed with: found = studied
or in the practice log of the language learned; `from_games` in the place index ("Found in a
game at"); ← → / Page Up / Page Down; footer key hints only with keyboard play; buttons at
least 44 px and text at least 11 px at the smallest scale; the word page's picture drawn at
256 px; a scrolling right side on the word page; fewer style allocations; README and
architecture-guide wording. Runs as above (isolated `HOME`, `VT_FOCUS=all`), each once when the
change was complete:

| Result | Check |
| --- | --- |
| PASS (exit abort) | `vocabulary_report --write`: **5475 checks, 0 failures**; `journal_places.json` gained `from_games` (airplane, bed, car, soccer, tennis). The run's report/word-list churn was reverted as before |
| PASS (exit abort) | `journal_sticker_book`, now 67 checks headless (+ 1 with graphics: Details fits the window): **67 / 0 headless, 68 / 0 at 1280 × 800 and at 844 × 390**. New: game-answer finding per language, the game-only word page, keys, keyboard-only hint, tap and text floors, the big picture request, Chinese learned (pinyin) with a Spanish interface and a Chinese interface (views `zh-chapter`, `zh-word-page`, `zh-ui-contents`) |
| Stalled, re-run | The first windowed runs at both sizes stalled waiting for a drawn frame (another session's Godot window opened over them; a covered window draws nothing). They were stopped and run once more with `--always-on-top`, which completed |
| Found and fixed | The first phone render showed Details pushing the album past the window bottom (taller buttons and text); the right side now scrolls, and the check above covers it |
| KNOWN-type, not this change | `language`: **5414 checks, 1 failure** (the same missing readings 掉 顆 舍) |

Remaining (P3): on a phone the Details table's "Translated" heading is clipped by the scroll bar;
the search placeholder capitalises language names in Spanish ("Chino o Español", the existing
`language.*` names). Old evidence scripts that drove the table no longer run and are not in
`run_checks.py`: `word-pictures-20261123/verify.gd`, `journal-speaker-20261124/capture.gd`,
`vocabulary-book-20261108/verify.gd` (and older ones using `set_journal_view`).
