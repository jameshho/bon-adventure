# Warehouse and the Warehouse Worker minigame

Game name (user, 10 Nov 2026; [all names](MINIGAMES.md#minigame-index)): **Stack & Pack** · *Carga y descarga* · 搬搬抬抬.

Current guide for the warehouse (*el almacén*) between the school and the airport, and for
the Warehouse Worker minigame planned inside it. The decision summary lives in the
[master blueprint](TOWN_DESIGN_BRIEF.md#warehouse-and-warehouse-worker-minigame--5-november-2026);
all minigames are indexed in [MINIGAMES.md](MINIGAMES.md). Keep this file current when the
building, the minigame design or their ownership changes.

## Status

| Phase | Scope | Status |
| --- | --- | --- |
| 1 | Site, school move, building shell, furnished reception, empty hall | **Built 5 Nov 2026** ([evidence](#phase-1-evidence)) |
| 2 | Vocabulary data (words, phrases, grammar forms, posters in reception) | **Built 5 Nov 2026** ([words](#vocabulary-built-phase-2), [evidence](#phase-2-evidence)); task sentences came with Phase 5 |
| 3 | Hall equipment and normal-warehouse stock | **Built 5 Nov 2026** ([equipment](#hall-equipment-phase-3), [evidence](#phase-3-evidence)) |
| 4 | Separate minigame copy, transitions, supervisor, dialogue, task card, exit question | **Built 5 Nov 2026** ([how it works](#the-game-frame-phase-4), [evidence](#phase-4-evidence)) |
| 5 | Physics objects, carrying, carts, task generator and validator | **Built 5 Nov 2026** ([goods](#goods-carrying-and-trolleys-phase-5), [tasks](#tasks-and-checks-phase-5), [evidence](#phase-5-evidence)) |
| 6 | Full checks and documentation | **Run 5 Nov 2026**: warehouse checks pass; the full suite is not clean ([record](FINAL_VERIFICATION.md#warehouse-phase-6-full-suite--5-november-2026)) |
| — | Goods and equipment resize in the minigame copy | **Built 8 Nov 2026** ([what changed](#goods-resize-8-nov-2026)) |
| — | Rack C out, task plan, hints, exits, drop rules, task card, *brown* / *medium* | **Built 8 Nov 2026** ([what changed](#task-plan-8-nov-2026)) |
| — | Half-depth redesign (30 × 14.5), reception at the east end, two loading bays, one shelf / table / cabinet; five placing tasks | **Built 14 Nov 2026, user-approved** ([redesign](#redesign-14-nov-2026), [minigame](#minigame-14-nov-2026)); not committed |
| — | Plain cardboard box out of the game; shelf with two clear levels; tap a level to place a box | **Built 21 Nov 2026** ([what changed](#shelf-and-placing-21-nov-2026)); not committed |

## Shelf and placing (21 Nov 2026)

User request, 21 Nov 2026: take *la caja de cartón* out of the game to avoid confusion; the top
shelf was hard to hit on a phone; "the shelf should have clear two levels".

- **Goods:** four boxes, green (the reference in the wall bay), red, blue and yellow. The plain
  box and its phrase `warehouse.thing_box_cardboard` are gone, and the boxes no longer carry
  the word *cardboard box*: a task practises only its colour (Stack & Pack now tests 4 words:
  [words](../game/words.md#stack--pack)). The town's own cardboard boxes (the pallet outside)
  keep the word. With three movable boxes the 2-of-5 share rule still plans 5 tasks.
- **Shelf look** (`warehouse.gd` `shelf()`, town warehouse rebaked by step `two_level_shelf`):
  decks at 0.3 and 1.1 (were 0.25 and 1.05), 0.05 thick; the uprights end just above the top
  deck with yellow caps (the frame and top beam that rose to 2.0 and read as a third level are
  gone); a dark blue-grey back panel between the decks; three light painted places on each deck
  (`SHELF_SLOTS`); yellow beams under each deck.
- **Placing** (`warehouse_goods.gd` `_shelf_place()`): while carrying, a click or tap anywhere
  on the shelf's front counts, from the floor up to a box's height above the top deck and a
  little past each end. At or above the top deck's front beam means the top level, lower the
  bottom level; the box goes on the free painted place of that level nearest the aim. Before,
  only the thin top of a deck counted, and a tap on a deck's edge or on a box there dropped the
  box on the floor in front. Something well in front of the shelf (the table, a box on the
  floor) still takes the aim; a full level falls back to the old rules. The put-down ghost is
  light blue (white was lost on the light places).

Checks: `verify_game.gd` (four boxes, no word, aiming at each level, a full level, the floor);
`verify.gd` unchanged. Renders: [town shelf](../evidence/warehouse-shelf-20261121/town-shelf.png),
[copy, both levels](../evidence/warehouse-shelf-20261121/copy-shelf-both-levels.png),
[carrying, ghost on a top place](../evidence/warehouse-shelf-20261121/carry-ghost-top.png)
(`docs/evidence/warehouse-shelf-20261121/capture.gd`). Record:
[FINAL_VERIFICATION](FINAL_VERIFICATION.md#warehouse-shelf-and-placing--21-november-2026).

## Redesign (14 Nov 2026)

User-approved 14 Nov 2026 ([blueprint](TOWN_DESIGN_BRIEF.md#warehouse-redesign--14-november-2026)).
Built by the `half_depth_redesign` step of `scripts/buildings/warehouse.gd` (baked into
`scenes/town/warehouse.scn`); dimensions live in `scripts/world/warehouse.gd`. Warehouse-local
frame: +X west, +Z north, front wall on z = 0 facing the lot; left/right are as seen from the
front looking in (left = west).

| Part | As built |
| --- | --- |
| Footprint | 30 wide (x −15..15) × **14.5 deep** (z 0..14.5); hall 8 high, reception 4.2. The land behind (old z 14.5..29) is ground. Site at town (−35, 0, 220.8) unchanged. |
| Reception | **Inside the footprint at the east end** (x −15..−8.3, z 0..14.5), partition x −8.3..−8.0. Glass sliding entrance at x −12.2 in the front wall with its ramp, canopy, lamps and planters; the hinged **hall door** in the partition (z 2.7..4.5) swings into the reception. Desk group (desk, computer, phone, package, clipboard, chair, Paty) turned to face the entrance at the back (desk ≈ (−11.5, 10.4)); **scale and ruler on the counter**; waiting chairs and plant on the east wall; verbs poster on the rear wall; positions and colours/sizes posters on the partition; RECEPTION on the east wall, WAREHOUSE over the hall door. Paty's `seat_point` moved with her. |
| Hall | A **low divider** (x 3.0, 1.2 high, yellow cap) with a **5 wide opening** (z 4.5..9.5). Right (east) section x −8..3: **empty**. Left (west) section x 3..14.7: **one shelf** (4 × 1, two levels, three box places each, capacity 6) against the rear wall at x 9.5, **one table** (3 × 1.4) at (8.5, 6.0), the **two-door supply cabinet** at (5.2, 13.75). Nothing else. Three pendant lamps, two trusses. |
| Loading bays | **Two** roll-up doors on the hall front, A x −7.2..−3.4 and B x −2.2..1.6 (4.6 high), each with yellow jambs, a hood and a lamp; three bollards; one concrete apron from the wall to the lot (z −5.8) with yellow bay lines. The drivable box truck backs up to **bay A**; **bay B is empty** (markings only). Both corridors to the lot are clear. |
| Outside | Ramón between the entrance and bay A (≈ (−8.9, −2.3)); a **trolley with a container** west of bay B; a pallet with cardboard boxes; sign ALMACÉN on the hall front at x 8.5. |
| Removed | Racks A–C, measuring table, floor scale, conveyor, IN/OUT areas, trolley lanes, the hall stock (crates, fruit, bottles, packages, containers). Each of their words still has an object elsewhere in town (checked: `FORMER_WORDS` in `docs/evidence/warehouse-20261114/verify.gd`); *container* and *trolley* now live outside the warehouse. |

Not done here (outside this unit, `scenes/town/base.scn`; recorded in [open items](#open-items)):
the parked car and motorcycle in the warehouse lot, the map entry `Warehouse entrance
connection` (still points at the old entrance x = 0), and the site bounds (still z 215..249.9,
which is why the zone polygon also still reaches z 253).

Checks: `docs/evidence/warehouse-20261114/verify.gd` (`warehouse`) and `verify_game.gd`
(`warehouse_game`), which replace `docs/evidence/warehouse-20261105/verify*.gd` (the old layout; kept as
history, no longer runnable). Renders: [front with both bays](../evidence/warehouse-20261114/front-bays.png),
[front wide](../evidence/warehouse-20261114/front-wide.png), [reception](../evidence/warehouse-20261114/reception-desk.png),
[reception partition](../evidence/warehouse-20261114/reception-partition.png),
[counter](../evidence/warehouse-20261114/reception-counter.png), [hall right](../evidence/warehouse-20261114/hall-right.png),
[hall left](../evidence/warehouse-20261114/hall-left.png), [shelf, both levels](../evidence/warehouse-20261114/shelf-both-levels.png),
[minigame mid-task](../evidence/warehouse-20261114/minigame-mid-task.png). Record:
[FINAL_VERIFICATION](FINAL_VERIFICATION.md#warehouse-redesign--14-november-2026).

## Minigame (14 Nov 2026)

User-approved 14 Nov 2026. **Five tasks** (`warehouse_ramon` progress 5), all *Pon … * placing
tasks of four kinds, written by the existing generator (`warehouse_tasks.gd`, entries
restricted to `POSITIONS`) and checked by the existing goal checks:

| Entry | Example | Done when |
| --- | --- | --- |
| `on` | *Pon la caja azul sobre la mesa.* | on the table (at most 3 there) |
| `next_to` | *Pon la caja roja al lado de la caja verde.* | on the floor within about 1.2 of the green box, any side |
| `right` | *Pon la caja roja a la derecha de la caja verde.* | on its right **as seen standing in front of the wall bay facing the box and the west wall**, i.e. north (+z) (`warehouse_goods.gd` `side_axis()`) |
| `top_shelf` | *Pon la caja amarilla en el estante de arriba.* | on the upper shelf level (at most 3) |

Goods: four boxes of one size since 21 Nov 2026 ([the plain one was removed](#shelf-and-placing-21-nov-2026)):
**green** (the reference, standing in the one painted wall bay on the west wall, never moved by
a task), **red**, **blue** and **yellow**; the other three start in random places (floor,
table, a shelf level). The cabinet still opens and shuts on E / click (no task). Ramón's flow is kept:
the offer, the task card, "try again / tell me" when a different box is picked up (tell me
marks the right box), two hint levels (card "?" and *¿Me das una pista?*), the leave question,
E on the ways out (hall door, entrance, both roll-up doors) and *¿Me ayudas otra vez?* at the
end. The task plan rules of [8 Nov](#task-plan-8-nov-2026) still apply (a box at most in 2 of 5
tasks). Removed: weighing, measuring, questions, trolleys, containers, racks A/B, IN/OUT,
conveyor, two-verb and give-me tasks. The player starts by the divider opening at (4.6, 7.0)
facing the left section; Ramón's twin stands at (4.3, 11.0).

## Approved decisions (user, 5 Nov 2026)

- **Site:** between the school and the airport. **The school moves 10 units toward the
  hospital** (user: it makes the map more balanced).
- **Look:** the user's reference images, but silver / light-gray metal instead of green; a
  reception with a front desk and a seated NPC; a second door into a large, high, open
  hall; the hall stays **empty** until the minigame and equipment list are approved.
- **Two modes:** normal exploration of the town building, and a **separate minigame copy**
  of the same architecture with its own movable objects; nothing moved in the minigame
  affects the normal warehouse.
- **Session:** ten tasks (five until 8 Nov 2026; user: "10 rounds long so i can really test
  out the game"). When all are done Ramón, back outside, thanks the player and asks *¿Me ayudas
  otra vez?* with Yes (a new game at once) / No (goodbye). **No coins** (ignored). **No
  first-try counting**: the session only checks that all the tasks get done. A wrong attempt is answered with a choice such
  as "Do you want to try again, or shall I point out what went wrong?" (like the cashier's
  "¿Qué salió mal?"). Leaving early asks for confirmation; approaching the exit alone never
  ends the session.
- **Register:** the supervisor says **tú** (*pon, busca, empuja*).
- **Supervisor** (Claude's choice, delegated by the user): a **lion plush, male, named
  Ramón**, word *el jefe* (boss) once approved, standing outside the warehouse; offer chance
  100 % for testing. Receptionist: **Paty**, a golden-retriever plush (female), seated at
  the desk; word *la empleada* (employee) once approved.
- **Left / right** (delegated): *a la izquierda de* / *a la derecha de* count as practice
  of the existing words `left` ("a la izquierda") and `right` ("a la derecha"); no new
  near-duplicate entries.
- **Cart controls:** E on the handle grabs the cart, **W pushes** it forward along its own
  axis, **S pulls** it back, E lets go. Weighing and measuring end with three number
  choices.
- **Vocabulary scope:** only A1–A2 words used almost daily (user, 5 Nov 2026: the first
  proposal had too many).
- **Normal-warehouse loose boxes** (user undecided): static for now; revisit after the
  minigame physics works (Phase 3).

## Site and layout

> **Stale since 14 Nov 2026:** the building is now 30 × 14.5 with the reception inside the footprint at the east end and two loading bays; see [Redesign (14 Nov 2026)](#redesign-14-nov-2026). Kept as the 5 Nov record.

Town-local coordinates (+X west, +Z north, town units; Apartment scale 1.3).

| Item | Where |
| --- | --- |
| School | compact target moved from x 0 to **x 10** (`data/reference_layout.json` `compact_layout.sites.School`): walls x −2.2..22.2. Its lot, drive, entrance walk, facade, bus, fire truck, foundation shrubs (`FOUNDATION_PLANTING`), zone (`data/zones.json` `school`, x −6..26) and street crossing (x 10) moved with it |
| Warehouse | root `Apartment/Warehouse` at **(−35, 0, 220.8)**, the annex front aligned with the school front. Footprint x −50..−20, z 220.8..249.8 |
| Gaps | hospital ↔ school 19, school ↔ warehouse 17.8, warehouse ↔ control tower about 15 |
| Lot | `Warehouse parking` 26 × 12 at (−35, 209), drive at x −35, entrance walk from the lot |
| Zone | `warehouse`, x −53..−17, z 202..253 (priority 100; the coast fallback excludes it) |
| Moved for the site | street tree `Trees/Tree_9` to (−55.5, 226); the bench at (14, 210) to x −6 (the school lot now covers its old spot) |

Building, in the warehouse's local frame (entrance on local z = 0):

| Part | Size and features |
| --- | --- |
| Hall | 30 wide × 22 deep (z 7..29), walls 8 high, flat roof with parapet. Silver ribbed cladding (`c3c9cf`, ribs `a9b1ba`), charcoal plinth and fascia, a thin safety-yellow line, high **frosted** clerestory windows on the rear and side walls (nothing outside shows through them: needed for the minigame copy) |
| Reception annex | 12 × 7, 4.2 high, smooth light panels; glass sliding entrance (E) under a charcoal canopy with a low concrete ramp up to the floor (step `entrance_ramp`, 10 Nov 2026: the 0.15 floor edge had blocked walking in), two framed windows, wall lamps, two planters |
| Sign | charcoal panel above the annex with a package icon and **WAREHOUSE** (shows **ALMACÉN** in Spanish through `sign_translations.json`) |
| Roll-up door | 5 × 5 on the hall front, east of the annex; closed, yellow jambs, bollards and a concrete loading apron to the lot |
| Reception | warm lining, blue-gray wainscot, tiled floor, ceiling lights; desk on the west side (computer, phone, clipboard) with Paty seated behind it; two waiting chairs and a plant on the east side; RECEPTION and WAREHOUSE signs. The walk from the entrance to the hall door (x = 0) stays clear |
| Hall door | hinged steel door with a vision panel and yellow kick plates (E), swinging into the reception |
| Hall | polished concrete with saw-cut joints, blue-gray wainscot under a yellow line, ribbed painted panels, steel columns on a 5 × 5.5 bay grid, three roof trusses, purlins, six pendant lamps with lights. **No equipment yet** |

## Hall equipment (Phase 3)

> **Stale since 14 Nov 2026:** racks A–C, the measuring table, floor scale, conveyor, IN/OUT areas, trolley lanes and the hall stock were removed; the hall now has one shelf, one table and the cabinet ([redesign](#redesign-14-nov-2026)).

Approved by the user 5 Nov 2026 ("add el contenedor, and proceed"), with the town
warehouse lightly stocked and no forklift. Hall-local coordinates (x west, z north; the
hall door is at x 0, z 7). The main aisle (x = 0) and cross aisle (z = 18) stay clear.

| Fixture (shared with the minigame copy, `hall_equipment()`) | Where | Word |
| --- | --- | --- |
| Racks A, B, C: 4 m long, decks at 0.25 / 0.95 / 1.65 m (bottom, middle, top), yellow beams and letter plates | rear wall, x 9 / 3.5 / −3.5, z 27.3 | each deck *shelf* |
| Work table, 2 × 1 m, top 0.9 m, open underneath | x 4.5, z 12 | *table* |
| Measuring table with a 1 m ruler | x 11, z 12 | *table*, *ruler* |
| Weighing station: floor scale 1.1 m square, readout pillar ("Scale readout", kg) | x 8, z 15.2 | *scale* |
| Supply cabinet, two doors (closed; opening comes with Phase 5) | rear wall, x −8.5 | *cabinet* |
| Conveyor belt, 7 m (decoration) | east wall, z 20–27 | *conveyor belt* |
| IN area (ENTRADA) by the roll-up door and OUT area (SALIDA), yellow outlines, names from `phrases.posters.zone_in/out` | x −13..−8 and −4.5..−1.5, z 8–12 | none |
| Two trolley lanes running south into the areas | x −10.5 and −3, z 12.3–16.5 | none |

Outside: a box truck (word *truck*) backed up to the closed roll-up door; the Phase 2
trolley moved from the apron into the hall. Town stock (`hall_stock()`, static, town only):
cardboard boxes (plain and red, green, blue), packages, a crate of apples and a crate of
bananas, containers (blue with three bottles, yellow; a red one on the conveyor), a package
on the work table and a trolley in each lane. New word: **container / el contenedor /
收納箱** (Around the House, an open plastic bin). The minigame copy adds a yellow floor letter in
front of each rack and three painted wall bays ([refinements](#refinements-after-play-testing-5-nov-2026)).

## Ownership

| Part | Owner |
| --- | --- |
| Whole building, lot, drive, walk, map entry, site clearing | `scripts/world/warehouse.gd`, called by `world_refinements.gd::build()` right after `compact_town()` |
| Shared architecture (floor, walls, roofs, doors, windows, columns, trusses, lamps) | `warehouse.gd::architecture(parent)`. Phase 4 builds the minigame copy with the same function, so the two cannot drift apart |
| Exterior-only detail | `warehouse.gd::exterior()` (not part of the minigame copy) |
| Reception furnishing and Paty | `warehouse.gd::furnish_reception()`, `receptionist()` (uses `house_characters.gd`'s seated pose); skipped when `dev_focus.txt` lists buildings without `warehouse` |
| Doors | Main's door registry (`game.doors`): the entrance slides, the hall door is hinged |
| Room name, map label | `reference_layout.site_bounds["Warehouse"]` and a map entry `WAREHOUSE`; text from `places.warehouse` in `data/phrases.json` |
| School position | `data/reference_layout.json` `compact_layout.sites.School` |

## The game frame (Phase 4)

Built 5 Nov 2026 (user: "go ahead"). `scripts/learning/warehouse_session.gd` runs it;
`warehouse.gd` `build_copy()` builds the copy; `scripts/ui/warehouse_task_card.gd` draws
the card. Activity `warehouse_ramon` (chance 1.0, 10 tasks since 8 Nov 2026) in `data/activities.json`.

1. **Offer.** Ramón shows the gold "!" within 30 m. Talking: *greeting* with *¡Claro!
   ¡Vamos!* / *Not now*; another running activity gets *common.finish_first*.
2. **Into the copy.** The screen fades to black (0.35 s), the player's position, facing and
   camera are saved, Ramón outside is hidden and the copy is built **300 units above the
   real warehouse** (`COPY_LIFT`, same orientation): shell and hall equipment, Ramón's twin and a
   `Session` node holding the game's goods (Phase 5). The copy's doors are not registered, so they stay
   shut. The player stands at the station (hall-local 0.6, 8.1) facing into the hall. (A floor
   arrow there showing a fixed "forward" was removed 5 Nov 2026: directions now come from
   wall bays.)
3. **Playing.** The task card (top centre, half the window wide) shows *Tarea 1 de 5*, the
   progress bar, the translate bubble, a leave button and the task; Ramón's *intro* plays.
   Talking to his twin repeats the task with *Seguir* / *Salir*. The minimap and room name
   show the real warehouse (the player's `map_position` meta = position − lift). Leaving
   the hall's bounds (falling, flying, noclip) puts the player back at the station.
4. **Leaving.** The card's exit button, Esc (the card is on the popup stack) or *Salir*
   always ask *¿Quieres salir del almacén? Las tareas no se guardan.* first. *Sí, salir*
   fades back to the saved spot, frees the whole copy, shows Ramón again and he says
   *Está bien. ¡Gracias por venir!*. A language change ends the game at once (goodbye).
5. **Tasks.** `task_done()` counts a finished task, writes the next one and at 5 ends with
   *complete* (Phase 5, below).

## Goods, carrying and trolleys (Phase 5)

> **Partly stale since 14 Nov 2026:** goods are five boxes; trolleys, containers, the scale and measuring readouts are gone ([minigame](#minigame-14-nov-2026)). Carrying and putting down are unchanged.

Built 5 Nov 2026 (user: "yes go ahead"). `scripts/learning/warehouse_goods.gd`, a child of
the session while a game runs, builds a fresh random arrangement into the copy and frees
it with the copy. Nothing touches the town warehouse.

| Thing | Behaviour |
| --- | --- |
| *Superseded 8 Nov 2026 ([goods resize](#goods-resize-8-nov-2026)): six boxes in three fixed sizes, a suitcase and a barrel, no bottle.* Four boxes (red, blue, green, yellow; word *cardboard box*), a big and a small package, a bottle | `RigidBody3D`, rotation locked except about the vertical, so they slide and turn but never tumble. Box lengths 50–75 cm (depth ¾ of the length, height 40–55 cm; enlarged 5 Nov 2026) and distinct weights of 2–18 kg are drawn per game; big package 65 cm, small 40 cm. Walking into one pushes it at a walking speed set from the player's slide collisions (1.0 m/s for light goods down to 0.35 m/s for heavy ones, times the town scale); an impulse per frame was smaller than floor friction and moved nothing. Bodies live in a top-level node in world space because physics bodies cannot sit under the town's 1.3 scale |
| Wall bays | Three grey painted floor rectangles (1.7 × 1.6 m, white outline) against the side walls: east wall at z 15.25 and 20.75, west wall at z 15.25. Two random boxes start in two bays, the big package in the third half the time. Every reference for *delante / detrás / a la izquierda / a la derecha / al lado de* stands in a bay (user, 5 Nov 2026: the reference is next to the wall, for less confusion). No task moves or picks up a thing standing in a bay, so the references stay (the player may still move them; directional tasks then wait until something stands in a bay again) |
| Containers, blue and yellow (1.1 × 0.4 × 0.8; 2.2 × 0.85 × 1.6 since 8 Nov 2026) | Static open bins on two of ten floor spots kept clear of the lanes, areas, tables, scale and racks. The bottle starts in one (since 8 Nov: a small box or the small package) |
| Two trolleys, one per lane | `AnimatableBody3D`, handle on the north end. Each starts inside or outside its area (IN lane x −10.5, OUT lane x −3) |
| Supply cabinet | The copy's doors get hinges on their outer edges and swing 100°; starts open or shut |
| Scale and measuring table | The scale's screen shows the kilograms on it; a new screen on the measuring table shows the length (cm) of what lies on it |

**Controls.** E, a click or a tap (since 12 Nov 2026 goods, trolleys, the cabinet and the exits
are [interactables](ARCHITECTURE_REVIEW_PART1.md#interaction-system) with the "E" badge; while
carrying or holding a trolley the session's `warehouse` input claim takes E and the click):
- on an aimed item within about 2.6 m: pick it up. It floats in front of the player and a
  faint white ghost shows where it will land;
- while carrying: put it down on the aimed level surface within 3.4 m (floor, shelf, table,
  scale, another item, a trolley; inside a container it centres), else on the floor in front.
  E on Ramón while carrying talks to him instead (to hand things over);
- on a trolley: grab it. **W pushes** it forward along its lane into its area, **S pulls**
  it back, **E lets go**; the player stays behind the handle and normal walking is off;
- on the cabinet: open or shut it.

A toast explains carrying (first pick-up) and the trolley keys (each grab). Goods that fall
out of the hall come back to a floor spot.

## Tasks and checks (Phase 5)

> **Stale since 14 Nov 2026:** only four placing entries remain (`on`, `next_to`, `right`, `top_shelf`) in a five-task game ([minigame](#minigame-14-nov-2026)); the 38-entry generator and Ramón's questions described here were removed.

`scripts/learning/warehouse_tasks.gd` writes and checks tasks; it contains no language.
Each task draws one of the 38 primary entries uniformly among those not used yet this game
and builds it from the arrangement **as it is now**, so it can be done and is not already
done. Sentences are phrases in `data/phrases.json` group `warehouse`: ready-made noun
phrases for the things (`thing_*`: *la caja roja*, *el estante B*, *la zona de SALIDA*),
places (`place_*`, with a `{ref}`) and tú templates (`task_*`). Nouns are repeated instead of
clitic pronouns, and the Spanish rules module's `polish()` writes *de el → del*, *a el → al*
(see [the language guide](ARCHITECTURE_REVIEW_PART1.md#adding-or-changing-a-language)).

| Entries | Task | Done when |
| --- | --- | --- |
| 16 positions, and poner / dejar / mover / ordenar | *Pon la caja azul debajo de la mesa.* (any position; a verb entry picks a position) | the item is put down and at rest in the forgiving area |
| sacar, quitar, guardar, llevar | *Saca la botella del contenedor azul.* / *Quita … de la mesa / del estante A.* / *Guarda … en …* / *Lleva … a la zona de SALIDA.* | out of it, off it, inside it, inside the area |
| levantar, recoger, buscar, encontrar | *Levanta el paquete grande.* (recoger only for things on the floor) | the player is carrying it |
| traer, dar | *Tráeme … , por favor.* / *Dame …* | it is beside Ramón, or he is talked to while it is carried (he takes it) |
| empujar, jalar | *Empuja el carrito hasta la zona de ENTRADA.* / *Jala el carrito fuera de …* | the trolley's centre is in / clearly out of its area |
| pesar, medir | *Pesa … en la báscula.* / *Mide … en la mesa de medir.* (only while the device is free) | at rest alone on it, Ramón asks *¿Cuánto pesa / mide …?* with three choices (kilos ±1–4, centimetres ±5–15); the right one |
| abrir, cerrar | *Abre / Cierra el gabinete.* | the cabinet is open / shut |
| ir | *Ve al estante C.* | the player stands in front of that rack |
| estar | *Busca … y dime dónde está.* | talking to Ramón: *¿Dónde está …?* with three places (inside a container, on the table or scale, on the top / bottom shelf, in an area), the right one |

**Question variants** (added 5 Nov 2026 after play-testing; each replaces the plain task
for its entry about half the time and only when the arrangement makes the answer unique):

| Entry | Variant | Answer |
| --- | --- | --- |
| buscar | *Busca la caja que está en el estante de arriba. ¿De qué color es?* (the box is named by its place) | one of three colours |
| dentro, sobre / encima, estante de arriba / de abajo | *Ve a ver qué hay dentro del contenedor azul y dímelo.* (exactly one thing there) | one of three things |
| pesar | *Pesa el paquete grande y el paquete pequeño en la báscula. ¿Qué paquete es más pesado?* (or lighter; boxes or packages) | after both have been read on the scale, one of the two |
| medir | *Mide la caja roja y la caja azul en la mesa de medir. ¿Qué caja es más grande?* (or smaller) | after both were on the measuring table, one of the two |

Boxes in the plain tasks are also sometimes named by place (*la caja que está sobre la
mesa*) instead of colour. Ramón asks number and comparison questions without zooming to
his face, so the screen stays in view.

**Directions** (changed 5 Nov 2026, user decision): the reference always stands in a wall
bay, and directions are as seen standing in front of it facing the wall: *delante* = out
from the wall, *detrás* = between it and the wall, *a la izquierda / a la derecha* along the
wall (`warehouse_goods.gd` `side_axis()`; things outside a bay fall back to the old station
frame). Areas: beside the reference up to 1.8 m out and within its width plus 0.4 m;
*next to* within 1.2 m on any side; shelves by the deck the item stands on.

**Wrong attempts** (no first-try counting). Putting the task's item down in the wrong place,
picking up a different thing for a find/lift task, handing Ramón the wrong thing or a wrong
answer makes Ramón say *Mmm, …* and offer **Intentar otra vez** / **Dime qué salió mal**.
Telling shows a green marker on the place (*Mira: … tiene que estar …*) or the thing, or for
numbers points at the screen (*Mira la pantalla: dice 6 kilos.*) with the choices again.
A finished task gets *¡Muy bien! Siguiente tarea.*

## Minigame design (approved plan)

> **Superseded 14 Nov 2026** by the simplified [minigame](#minigame-14-nov-2026). Kept as the 5 Nov plan.

**Two copies, one architecture.** The normal warehouse is in town. When the player accepts
Ramón's request, the screen fades, the player's position and facing are saved, Ramón
outside is hidden, and a copy of the hall built by `architecture()` appears at a fixed spot
far offshore, with a fresh random arrangement of task objects under its own `Session` node
and Ramón's twin at a fixed station. The player is teleported in and the camera reset.
Ending the session (all the tasks, leaving early, or a language change) fades back to the
saved spot outside and frees the whole copy, so no state leaks and the next session starts
clean. Falling or noclipping out of the copy returns the player to Ramón's station, not to
the supermarket spawn. The minimap shows the real warehouse meanwhile.

**Reused systems:** `activity_board.gd` (`warehouse_supervisor`, chance 1.0 for testing),
`npc_presence.gd` ("!", hop, face camera), `shop_order_panel.gd` (dialogue, translate
bubble, choices), `progress_bar.gd` (tasks done of 10), `popup_stack.gd` (Esc), the Lexicon
and `phrases.json` for every line in every language, the interaction controller's
`shop_clerk` talk target and aiming. New: fade-and-teleport, physics objects (none existed
before), the task card and the task generator.

**Objects and controls.** Boxes and packages are light physics bodies that slide and stop
and only turn about the vertical axis (no tumbling); walking into one nudges it. E on an
aimed box within about 2.5 m picks it up; it floats steadily in front of the player; a
faint outline shows where it will land on the aimed surface (floor, shelf level, table,
cart, another box); E places it, snapping to a slot when close. Carts move only along
their own lane (controls above), stop at obstacles and stay inside the lane. Anything lost
reappears at a recovery spot.

**Directions.** *Delante, detrás, a la izquierda de, a la derecha de* always use the
warehouse's fixed orientation as seen from Ramón's station (a floor arrow there shows it),
never the camera. *Superseded 5 Nov 2026 (user): the reference stands next to a wall and
directions are as seen facing that wall; see [tasks and checks](#tasks-and-checks-phase-5).* Checks use forgiving areas next to the reference object.

**Task generation.** Per task, draw one of the primary entries uniformly, pick at random
among the templates that use it and can be done in the current arrangement, and fill the
other slots at random. Every entry has at least one template. Generated arrangements keep
the exit and cart lanes clear and never make a target unreachable or ambiguous. Example
session:

1. *Busca la caja verde y ponla en el estante de abajo.*
2. *Empuja el carrito hasta la puerta.*
3. *La botella está dentro de la caja azul. Sácala y déjala encima de la mesa.*
4. *Pesa el paquete pequeño.* → *¿Cuánto pesa?* (three choices)
5. *Pon la caja amarilla detrás de la caja roja.*

As built (Phase 5) the sentences differ slightly: they repeat the noun instead of
pronouns (*Saca la botella del contenedor azul.*), trolleys go into or out of the painted
areas rather than "to the door", and things are named by colour or size; see
[tasks and checks](#tasks-and-checks-phase-5).

## Vocabulary

**Primary (user list, 38).** 22 verbs (poner, sacar, quitar, guardar, dejar, llevar,
traer, mover, levantar, empujar, jalar, recoger, buscar, encontrar, ordenar, pesar,
medir, abrir, cerrar, ir, estar, dar) for a new **Actions** category shown as infinitives,
and 16 position expressions in **Time & Directions**, of which *a la izquierda de* and
*a la derecha de* count toward the existing `left` / `right`. Verbs get a poster in the
reception (words without an object need one, like the school posters). Instructions are
tú commands; as built (Phase 5) they repeat the noun instead of attached pronouns
(*ponla, sácala*), so no new grammar forms were needed. Chinese uses 把 sentences; every new
word and phrase has English, Spanish and Chinese (Claude drafts the Chinese and pinyin).

### Vocabulary built (Phase 2)

Approved 5 Nov 2026 (user: A1–A2, daily words only). 50 new words in `data/words.json`
(634 words, 22 categories), each with English, Spanish and a drafted Chinese text:

| Group | Words | Where they are clickable |
| --- | --- | --- |
| **Actions** (new category, 22) | the verbs above, as infinitives | verbs poster, reception east wall |
| Time & Directions (+14) | on top of, under, in front of, behind, inside, outside, next to, on, on the top / bottom shelf, at the top / bottom, up, down (*left* / *right* already existed) | positions poster, back wall east of the hall door |
| **Colors & Descriptions** (new category, 8) | red, blue, green, yellow, big, small, heavy, light (key `light (weight)`, shown "light (not heavy)") | colours and sizes poster, back wall west of the hall door |
| Around the House (+2) | cardboard box (*la caja de cartón*), package (*el paquete*) | the pallet boxes outside; a parcel on the reception desk |
| Places & Rooms (+1) | warehouse (*el almacén*) | every solid wall and roof of the building (`exterior_word`, like the school) |
| People (+2) | boss (*el jefe / la jefa*), employee (*el empleado / la empleada*), with m/f forms | Ramón; Paty |

Changes from the proposal, forced by the one-translation-per-word rule
(`docs/evidence/town-checks/check_vocabulary_translations.py`):
- *la caja* is already the **checkout counter**, so the box word is **cardboard box /
  la caja de cartón / 紙箱**.
- *el carrito* is already **trolley** (the hospital cart), so the warehouse platform cart
  reuses `trolley` instead of adding a duplicate "cart".

Other Phase 2 data: category phrases `categories.actions` / `colors_descriptions`; poster
titles `posters.verbs_title`, `places_title`, `describe_title`; outfit `warehouse_worker`
(`data/plush_costumes.json`: blue-gray work shirt, yellow safety vest, name tag, charcoal
cap; it also appears in the clothing store mirror's outfit cycle, named by
`outfits.warehouse_worker`); 12 pinyin readings. Paty no longer shows a name card: a click
teaches *empleada*-family word **employee**; Ramón (lion plush, outside right of the
entrance) teaches **boss**. Phase 5 needed no verb or adjective forms: task sentences are
whole phrases (see [tasks](#tasks-and-checks-phase-5)).

Weights and sizes ("5 kilos", "40 centímetros") are generated language, not words.

## Phase 1 evidence

Renders (5 Nov 2026, full town): [front](../evidence/warehouse-20261105/front.png),
[front east](../evidence/warehouse-20261105/front-east.png), [front west](../evidence/warehouse-20261105/front-west.png),
[rear](../evidence/warehouse-20261105/rear.png), [north street aerial](../evidence/warehouse-20261105/street-aerial.png),
[north street from above](../evidence/warehouse-20261105/street-top.png),
[reception desk](../evidence/warehouse-20261105/reception-desk.png),
[reception to hall door](../evidence/warehouse-20261105/reception-door.png),
[hall from the door](../evidence/warehouse-20261105/hall-from-door.png), [hall wide](../evidence/warehouse-20261105/hall-wide.png),
[hall to the front](../evidence/warehouse-20261105/hall-to-front.png). Reproduce with
`godot --path . --resolution 1400x900 --script res://docs/evidence/warehouse-20261105/capture.gd`
(isolated HOME). Check results: [verification record](FINAL_VERIFICATION.md#warehouse-phase-1-building-and-school-move--5-november-2026).

## Phase 2 evidence

Renders (5 Nov 2026, full town, Spanish shown): [verbs poster](../evidence/warehouse-20261105/poster-verbs.png),
[positions poster](../evidence/warehouse-20261105/poster-positions.png),
[colours and sizes poster](../evidence/warehouse-20261105/poster-describe.png),
[Ramón](../evidence/warehouse-20261105/words-ramon.png), [trolley](../evidence/warehouse-20261105/words-trolley.png),
[pallet boxes](../evidence/warehouse-20261105/words-boxes.png), [desk package and Paty](../evidence/warehouse-20261105/words-desk.png).
Reproduce with `docs/evidence/warehouse-20261105/capture_words.gd`. Check results:
[verification record](FINAL_VERIFICATION.md#warehouse-phase-2-vocabulary--5-november-2026).

## Phase 3 evidence

Renders (5 Nov 2026, full town): [hall from the door](../evidence/warehouse-20261105/hall3-from-door.png),
[hall wide](../evidence/warehouse-20261105/hall3-wide.png), [hall to the front](../evidence/warehouse-20261105/hall3-to-front.png),
[racks A and B](../evidence/warehouse-20261105/hall3-racks.png), [rack C and cabinet](../evidence/warehouse-20261105/hall3-rack-c.png),
[tables and scale](../evidence/warehouse-20261105/hall3-stations.png), [IN / OUT and lanes](../evidence/warehouse-20261105/hall3-loading.png),
[truck](../evidence/warehouse-20261105/truck.png). Reproduce with `docs/evidence/warehouse-20261105/capture_hall.gd`.
Checks: [verification record](FINAL_VERIFICATION.md#warehouse-phase-3-hall-equipment--5-november-2026).

## Phase 4 evidence

Renders (5 Nov 2026, with the HUD): [Ramón calling](../evidence/warehouse-20261105/game-ramon-calling.png),
[offer](../evidence/warehouse-20261105/game-offer.png), [intro in the copy](../evidence/warehouse-20261105/game-intro.png),
[station and card](../evidence/warehouse-20261105/game-station.png), [Ramón's twin](../evidence/warehouse-20261105/game-twin.png),
[leave question](../evidence/warehouse-20261105/game-leave.png), [back outside](../evidence/warehouse-20261105/game-back.png).
Reproduce with `docs/evidence/warehouse-20261105/capture_game.gd`; flow check `verify_game.gd`.
Checks: [verification record](FINAL_VERIFICATION.md#warehouse-phase-4-game-frame--5-november-2026).

## Phase 5 evidence

Renders (5 Nov 2026, with the HUD): [goods from the station](../evidence/warehouse-20261105/game5-goods.png),
[carrying](../evidence/warehouse-20261105/game5-carry.png), [holding a trolley](../evidence/warehouse-20261105/game5-trolley.png),
[wrong place](../evidence/warehouse-20261105/game5-wrong.png), [green marker](../evidence/warehouse-20261105/game5-hint.png),
[weight question](../evidence/warehouse-20261105/game5-weigh.png), [measuring screen](../evidence/warehouse-20261105/game5-measure.png),
[open cabinet](../evidence/warehouse-20261105/game5-cabinet.png). Reproduce with
`docs/evidence/warehouse-20261105/capture_tasks.gd`; flow check `verify_game.gd`. Checks:
[verification record](FINAL_VERIFICATION.md#warehouse-phase-5-goods-and-tasks--5-november-2026).

## Refinements after play-testing (5 Nov 2026)

User request: put the reference box for *right of the red box*-type tasks next to a wall,
make all boxes bigger, play-test and improve the interior and question types. Built:
wall bays and wall-relative directions, bigger boxes and containers ([goods](#goods-carrying-and-trolleys-phase-5)),
floor letters A–C in front of the racks (the station's floor arrow removed), the colour /
what / comparison questions ([tasks](#tasks-and-checks-phase-5)), walking that really pushes
goods, and trolleys at 2.6 m/s (were 1.8: a two-second push stopped short of the area).

`docs/evidence/warehouse-20261105/playtest.gd` plays with real input (W key events, the pointer put
on things, E through Main). Last run: walked to a box and E picked it up; aimed at the floor
right of a bay box and E put it there (*beside right* true); walking into a floor box moved it
1.03 m (the first play-test moved nothing: the per-frame impulse was smaller than floor
friction); W pushed a trolley 5.07 m into its area; E let go, opened the cabinet; colour and
comparison questions were asked. Views: [aiming](../evidence/warehouse-20261105/play-aim.png),
[put down by a bay box](../evidence/warehouse-20261105/play-placed.png), [colour question](../evidence/warehouse-20261105/play-color.png),
[comparison](../evidence/warehouse-20261105/play-compare.png), [carrying](../evidence/warehouse-20261105/play-carry.png),
[trolley](../evidence/warehouse-20261105/play-trolley.png), [cabinet](../evidence/warehouse-20261105/play-cabinet.png).
Checks: [verification record](FINAL_VERIFICATION.md#warehouse-play-test-refinements--5-november-2026).

## Goods resize (8 Nov 2026)

> **Stale since 14 Nov 2026** (the copy's equipment and goods were replaced; [minigame](#minigame-14-nov-2026)).

User decisions, 8 Nov 2026 (recorded in the
[master blueprint](TOWN_DESIGN_BRIEF.md#warehouse-and-warehouse-worker-minigame--5-november-2026)).
The player pig measures **2.23 m tall in the world = 1.71 hall units** (1.10 wide), from its
visible mesh in the running game (`docs/evidence/warehouse-20261108/measure_pig.gd`). Hall units below.
**Only the minigame copy changed:** `warehouse.gd` `hall_equipment()` now builds the copy alone;
the town's baked warehouse (`scenes/town/warehouse.scn`) keeps the 5 Nov equipment and stock.

| Thing | Now | Before |
| --- | --- | --- |
| Boxes (word *cardboard box*) | *Eight since the [fourth round](#boxes-only-tote-containers-and-click-to-use-8-nov-2026).* Six per game, each a different colour from red, blue, green, yellow, **brown**, orange. Three **fixed sizes**: one **big** 1.3 × 1.4 × 1.2 (130 cm; about 0.8 of the pig's height), three **medium** 0.75 × 0.55 × 0.55 (75 cm), two **small** 0.4 × 0.3 × 0.3 (40 cm) | four colours, random 50–75 cm |
| Big box | **Trolley-only**: frozen on one trolley's deck and moved with it; things stacked on it ride along. E on it shows *¡Es muy pesada! Muévela con el carrito.* No task lifts, carries, weighs, measures or shelves it; it is a reference for *on top of* (*Pon la caja roja pequeña encima de la caja azul grande.*) and for *¿Qué hay encima de …?*. Half the games start with a small box on it | — |
| Packages | *Removed in the [fourth round](#boxes-only-tote-containers-and-click-to-use-8-nov-2026).* big 0.7 × 0.45 × 0.55 (70 cm), small 0.45 × 0.25 × 0.35 (45 cm) | 65 and 40 cm |
| Suitcase (word *suitcase*, new here) | 0.65 × 0.95 × 0.34 (enlarged the same day from 0.5 × 0.7 × 0.25), upright hard shell, red / blue / purple / pink / black | — |
| Barrel (word *barrel*, new here) | Ø 0.8 × 1.1 (enlarged the same day from Ø 0.6 × 0.85), a painted steel drum, blue / red / green / yellow / orange | — |
| Bottle | **Removed** | in a container |
| Containers | 2.2 × 0.85 × 1.6, walls below the player's eyes; a put-down aimed inside lands where aimed (kept off the walls), not always in the middle. One starts with a small box or the small package in it | 1.1 × 0.4 × 0.8 |
| Trolleys | deck 1.4 × 1.8 (fits the big box); lane lines 1.7 apart | 0.7 × 1.1 |
| Racks | 4.4 long, 1.0 deep, decks at 0.25 / 1.0 / 1.75 (0.68 free between decks; taller goods, the suitcase and the barrel, never go on a shelf) | 4.0, 0.9, decks 0.25 / 0.95 / 1.65 |
| Work table | 3.0 × 1.4 (only goods lower than 0.7 go under it) | 2.0 × 1.0 |
| Measuring table | 3.0 × 1.2, 2 m ruler; screen 0.8 × 0.45 on a taller post | 2.0 × 0.9, 1 m ruler |
| Scale | 1.6 square plate; display 0.8 × 0.45 at 1.75 | 1.1, display at 1.3 |
| Wall bays | 2.2 × 1.9, **all three on the wall to the player's left on entering** (+x, west), at z 14.5, 19.25 and 24.0 (user: one side is easier to find); the two bay boxes are medium boxes | 1.7 × 1.6; two on the west wall, one on the east |
| Conveyor belt | the motor is grey (`RACK_UPRIGHT`), no yellow parts (user: they confused a search for yellow things). Rack beams, lane lines, floor areas and the yellow container stay yellow | yellow motor |
| Looks | Cartons: a darker edge shell with inset faces, flap seam, tape over the top and down both ends, a shipping label with lines and a barcode on the front, hand holes on medium and big boxes; packages get a tape cross and a barcode label. Barrel: three raised hoops, steel rim, lid with filler cap, white label band, dark bottom rim. Suitcase: darker frame with inset shells, three ribs per side, a zip line, corner guards, wheels, a retracted pull handle and a side handle (`warehouse_goods.gd` `_carton_look()`, `_barrel_look()`, `_suitcase_look()`) | one coloured box with a tape strip |
| Hall | **unchanged** (30 × 22; user: do not shrink) | |

**Names.** Item ids name their phrase (`warehouse_tasks.gd` `thing()`): `box_<size>_<colour>`
→ `thing_box` *la caja {color} {size}* / *the {size} {color} box* / *{color}的{size}紙箱*, with
`color_f_*` and `box_size_*` (*grande, mediana, pequeña*); `suitcase_<colour>` → *la maleta
{color}*; `barrel_<colour>` → *el barril {color}* with masculine `color_m_*`. *Which box is
bigger / smaller?* and its hint name boxes by colour only (`thing_box_plain`), since the size
would give the answer away. Colour answers include *Marrón* and *Naranja*.

**Task rules added.** *On top of* only puts a thing on something larger than it, with flat tops
(boxes, packages, the big box); shelves only take goods under 0.68 high; *under the table* only
goods under 0.7; *measure* only boxes and packages; *which box is bigger* compares two boxes of
different sizes. The variant *¿Qué hay encima de …?* joins the *what* questions.

**Not done.** ~~Words *brown* and *medium* are not vocabulary entries~~ (done the same day,
[below](#task-plan-8-nov-2026)); the town warehouse's posters and stock were not changed. The drafted Chinese and the Spanish adjective order (*la caja roja pequeña*) need a
speaker's check. The too-heavy toast fired in the check but was not visible in the render.

Evidence (8 Nov 2026, with the HUD; `docs/evidence/warehouse-20261108/capture.gd`):
[hall from the station](../evidence/warehouse-20261108/hall-from-station.png),
[wall bays on the left wall](../evidence/warehouse-20261108/bays-left-wall.png),
[pig and big box](../evidence/warehouse-20261108/big-box-and-pig.png), [container](../evidence/warehouse-20261108/container.png),
[scale and measuring table](../evidence/warehouse-20261108/scale-and-measure.png), [racks](../evidence/warehouse-20261108/racks.png),
[conveyor without yellow](../evidence/warehouse-20261108/conveyor.png),
[goods close-up: barrel, suitcase, package, boxes](../evidence/warehouse-20261108/goods-close.png),
[carrying a medium box](../evidence/warehouse-20261108/carry-medium.png). The capture calls
`RenderingServer.force_draw()` for each view: waiting for `frame_post_draw` hung when macOS
stopped drawing the window.
Checks: [verification record](FINAL_VERIFICATION.md#warehouse-goods-resize--8-november-2026).

## Task plan (8 Nov 2026)

> **Still current** for the plan rules (written before the game, replayed, backups, share limit, hints); since 14 Nov 2026 a game has 5 tasks, so the limit is 2 of 5.

User request, 8 Nov 2026 (a numbered list of improvements; "Preview dialog" was confirmed to
mean the task card). **Minigame copy only**, like the resize above.

**Layout.** The copy has **racks A and B only**; the blue and yellow containers stand side by
side where rack C was (`Warehouse.GAME_RACKS`, `GAME_CONTAINERS`: x −2.15 and −4.85, z 27.25;
0.6 from the rear wall, clear of the main aisle, open at the front and both ends; colours in
random order). Tasks name only racks A and B. The town's baked warehouse keeps rack C.

**Ten tasks planned before the game** (`warehouse_tasks.gd` `plan()`). The copy and its goods
are built under the fade; then all ten tasks are written against `warehouse_plan.gd`, a view
of the arrangement that moves things where each planned task leaves them (into the container,
onto the table, to Ramón…), so each task can be done and is not already done in its turn.
Where a result cannot be predicted (a thing lifted and put down anywhere, "on a shelf" of any
rack, a thing that rode on a moved thing), that thing is left out of later tasks. Rules:
- each entry is still drawn uniformly at random among those not used yet (as before);
- **no thing in more than 2 of 10 tasks** (20%), and no place (the same reference, area, rack
  or device) more than twice;
- not the same thing or the same place in two tasks in a row (relaxed only after 20 tries);
- `validate()` replays the whole list from the starting arrangement before it is used.
Up to 40 tries per arrangement; if none keeps every rule the session builds a **new
arrangement** (at most 3, `ARRANGE_TRIES`) and, failing that, uses the best list and reports
the problem with `push_warning` (`plan_problems`), never silently. **Backups:** when a task's
turn comes `still_valid()` checks it against the live warehouse; if the player's moves made
it impossible or already done, `backup()` writes a replacement under the same rules.

**Wording.** *Ordena el almacén:* is gone: the verb *organizar* left the task entries (37 now:
21 verbs, 16 positions; the word stays in the dictionary). *La mesa* is now *la mesa de trabajo*
(the measuring table is a second table). *Busca / Encuentra…* end *y levántala / levántalo*
(they finish when it is picked up; `it_f` / `it_m`). *Pesa / Mide…* end *y dime cuánto pesa /
mide*. *Recoge … del piso* no longer picks a thing standing in a container. Every thing is
named by kind and colour (boxes also by size) or by where it is when no other thing of its kind
is there; container names always carry their colour.

**Dropping and placing.** Putting a thing down in the wrong place is **not a mistake**: no
message, no penalty (the old *wrong_place* reaction is gone). A placing task counts once the
thing has been let go and stays still in the right place for 0.5 s (`SETTLE_SECONDS`): passing
through, or putting it there and picking it up again at once, does not count. Picking up the
wrong thing when asked to find or lift a certain one still asks *try again / tell me*.

**Hints.** A **?** button on the task card and *¿Me das una pista?* when talking to Ramón (with
*Seguir* / *Salir*) call the same `give_hint()`; the level is shared and starts again with each
task. Level 1: a general clue from the real state, such as *Pista: la caja verde pequeña está
en el centro del almacén* (11 hall areas, `area_of()`), the area of the place once the thing is
carried, or what to do (trolley keys, the scale and its screen, where the racks or the cabinet
are). Level 2: the thing marked green; once it is carried, its place marked green with *Mira:
… tiene que estar …*. Asking again at level 2 marks what fits now. The task and the game go
on. Hints do not change practice tracking.

**Leaving through a door.** E on the hall door, the entrance door or the roll-up loading gate
shows the existing leave question (*¿Quieres salir del almacén?*); *No* returns to the game with
its progress. While carrying, E puts the thing down instead, so a put-down by a door never
asks. Only the copy's doors are marked (`warehouse_exit` in `build_copy()`).

**Task card review.** Reviewed in the renders below. The bar's own count (*0/5*) repeated the
title and read as a second number: hidden (`progress_bar.gd` `show_count`, default on for
other games). The exit button was the engine's grey default: the new ? and the exit now share
the card's outline style, with tooltips (*Pista*, *Salir*). Text sizes and the scaling rule
are unchanged. The intro now says *Si necesitas una pista, pulsa ? o habla conmigo.*

**Vocabulary.** *brown* (*marrón*, 啡色) and *medium* (*mediano*, 中型) are dictionary words
(Colors & Descriptions), so the vocabulary book lists them. A task now practises its thing's
word **plus the colour and size its sentence names** (`words()`: *Levanta la caja azul mediana*
→ cardboard box, medium, blue); a colour question practises the colour asked. The vocabulary
report counts these for `warehouse_ramon` (16 tested words, was 3). *brown* and *medium* have
**no object in town yet** (report flag `unplaced`): the colours poster in the town warehouse's
reception would need them, which is town-warehouse work (not done).

Evidence (8 Nov 2026, with the HUD; `docs/evidence/warehouse-20261108/capture_round3.gd`):
[hall and task card](../evidence/warehouse-20261108/r3-hall-from-station.png),
[containers where rack C was](../evidence/warehouse-20261108/r3-containers-at-rack-c.png),
[first hint](../evidence/warehouse-20261108/r3-hint-1.png), [second hint, green marker](../evidence/warehouse-20261108/r3-hint-2.png),
[leave question at the loading gate](../evidence/warehouse-20261108/r3-leave-at-gate.png).
Checks: [verification record](FINAL_VERIFICATION.md#warehouse-goods-resize--8-november-2026).

## Boxes only, tote containers and click to use (8 Nov 2026)

> **Partly stale since 14 Nov 2026:** no totes; click to use is unchanged.

User decisions, 8 Nov 2026 (game copy only; the town warehouse is unchanged):

- **Every cardboard thing is a box** (*la caja*). The tan package also read as "brown", and
  *tan* is not taught, so the two packages became two more boxes: **eight boxes** (one big,
  four medium, three small) in **eight different colours** (red, blue, green, yellow, brown,
  orange, purple, pink; `warehouse_goods.gd` `BOX_COLORS` / `BOX_MIX`), plus the suitcase and
  the barrel: still ten goods. The small thing that starts in a container is a small box; the
  third wall bay holds a third medium box half the time. *Which package is heavier* is gone;
  the box comparisons stay. Removed phrases: `thing_package_big/small`, `thing_package_at`,
  `task_/ask_heavier_package`, `task_/ask_lighter_package`. The word *package* is still in the
  dictionary and on the reception desk, but no game tests it now; Ramón's greeting still says
  *paquetes*.
- **Containers look like plastic totes** (user: "a solid same color thing", inside and outside
  hard to tell apart). `_container()` keeps the same colliding floor and walls and adds: a
  lighter rim that lips out over the walls round the opening, dark inner walls and an even
  darker inner floor, vertical ribs and a band under the rim outside, black hand grips on the
  ends, a white label front and back, and a dark base.
- **Box print:** flap edges on the top, a darker band along the bottom, and printed "this way
  up" arrows on the ends of medium and big boxes (`_carton_look()`). The barrel and suitcase
  looks are unchanged.
- **Left click does what E does** in the game (pick up, put down where clicked, trolleys,
  cabinet, leave at a door, talk to Ramón) and **never opens a word card** while the game runs
  (`main.gd` `use_pressed()`, shared with the E key). The carry toast says *Haz clic donde
  quieras dejarlo (o pulsa E)*. The HUD help line still says "Click Study" (the town-wide help).

Evidence (`docs/evidence/warehouse-20261108/capture_round4.gd`, with the HUD):
[containers](../evidence/warehouse-20261108/r4-containers.png),
[container from above](../evidence/warehouse-20261108/r4-container-above.png),
[all goods in a row](../evidence/warehouse-20261108/r4-goods-row.png),
[goods closer](../evidence/warehouse-20261108/r4-goods-close.png), [hall](../evidence/warehouse-20261108/r4-hall.png).
Checks: [verification record](FINAL_VERIFICATION.md#warehouse-goods-resize--8-november-2026).

## Fifth round: bigger goods, two-verb tasks, pushing, the upright ruler (8 Nov 2026)

> **Mostly stale since 14 Nov 2026:** no two-verb tasks, trolleys or ruler in the game; pushing goods by walking is unchanged.

User decisions, 8 Nov 2026 (game copy only, except the two rules for every minigame):

- **Goods about a fifth bigger** (user: "still 20-30% too small"), hall units: big box 1.6 ×
  1.7 × 1.45, medium 0.92 × 0.66 × 0.68 (still under the shelves' 0.68 free height and the
  table), small 0.5 × 0.38 × 0.38, suitcase 0.8 × 1.16 × 0.42, barrel Ø 1.0 × 1.35. The trolley
  deck widened to 1.75 for the big box. Carried goods float half their depth further ahead.
- **Weight follows size** (`WEIGHTS`): small 2-5 kg, medium 6-12, suitcase 13-16, barrel
  17-20, big 30-40. *Which box is heavier / lighter* weighs two boxes of one size.
- **Reach:** pick up / grab from 3.3 hall units (was 2.6). **Put-down where clicked:** the aim
  ray now ignores the carried thing (it used to catch the click, so things landed in front of
  the player); a level surface takes the thing there, a side (wall, box) puts it on the floor
  just off that side, anywhere within 10 hall units.
- **Two verbs in one task:** lift / pick up / look for / find become *Levanta la caja roja y
  ponla sobre la mesa de trabajo.* (a placing goal chosen like other placing tasks); bring /
  give become *Tráeme el barril naranja y ponlo delante de mí, por favor.* (a floor circle
  1.7 in front of Ramón, `boss_front()`). Picking the thing up, or talking to Ramón while
  carrying it, makes him say *¡Bien! Ahora ponla …* (`warehouse.lift_then`). Planned, checked
  and hinted as placing tasks (`warehouse_tasks.gd` `_two_verbs()`, `_goal_for()`).
- **Pushing by weight** (`_nudge()`): small boxes scoot ahead and sideways faster than walking;
  medium ones move at about half walking speed, sliding aside; the suitcase and barrel creep.
  Walking into a trolley (or the big box on it) rolls it along its lane only, slowly (0.9,
  loaded 0.55 hall units/s); grabbed with E or a click it moves at 3.4 (was 2.6).
- **Upright ruler instead of the measuring table** (user: it was mixed up with the work
  table): a base plate 1.6 square with a 2.2 m yellow ruler on its west edge, marks every
  10 cm, the screen on top facing the hall (`warehouse.gd` `measuring_post()`, copy only; the
  town keeps its table). It reads the **height** of what stands on the plate (meta `height`):
  big 170, medium 66, small 38 cm. Tasks: *Mide … con la regla*; hints: *la base de la regla*.
- **Praise on the task card** (user, 8 Nov 2026: one box, not a second at the bottom): a
  finished task shows *¡Muy bien! Siguiente tarea.* in green on the card for 1.6 s, with the
  progress bar already moved on, then the next task (`warehouse_task_card.gd` `praise()`,
  `PRAISE_SECONDS`); no task is watched meanwhile. *Find* tasks lost their tail *: está en
  algún lugar del almacén*, and a thing taken out of / off its place is named by colour and
  size, not by that place ("la caja que está dentro del contenedor amarillo fuera del
  contenedor amarillo"). Evidence: [praise on the card](../evidence/warehouse-20261108/r6-praise-on-card.png),
  [next task](../evidence/warehouse-20261108/r6-next-task.png) (`capture_round6.gd`).
- **Every minigame:** no word cards while a game runs, and a line without choices (the
  goodbye) closes itself once the player walks 3 m away ([shared systems](MINIGAMES.md#shared-systems)).

Evidence (`docs/evidence/warehouse-20261108/capture_round5.gd`, with the HUD):
[all goods in a row](../evidence/warehouse-20261108/r5-goods-row.png), [upright ruler reading 66 cm](../evidence/warehouse-20261108/r5-ruler.png)
(the pig hides the box on the plate), [two-verb task](../evidence/warehouse-20261108/r5-two-verb-task.png),
[Ramón after the pick-up](../evidence/warehouse-20261108/r5-lift-then.png).
Checks: [verification record](FINAL_VERIFICATION.md#warehouse-goods-resize--8-november-2026).

## Open items

1. P1: the full suite (Phase 6) shows new vehicle, interaction, aircraft and hospital failures,
   not traced ([record](FINAL_VERIFICATION.md#warehouse-phase-6-full-suite--5-november-2026)); Part 2's
   parking-area count needs 14 for the warehouse lot. The play-test script
   drives real key events and the pointer, but a human hands-on try (feel of carrying reach,
   push speed, reading the bays) is still needed.
2. P2: the drafted Chinese texts and pinyin for the 50 new words need a native check.
   The building word answers from inside the hall and reception walls too (as the school does).
3. P2: walking through both doors and around the copy is checked with a player-sized
   capsule and teleports, not with real keyboard movement.
4. P3: the hall's six omni lights and its primitive parts (now with equipment and stock)
   were not measured for frame time.

5. P1 (14 Nov 2026, needs a `base` change, outside the warehouse unit): one parked car and one
   motorcycle in the warehouse lot as DriveableVehicles, clear of the bays and the drive (the lot
   is in `scenes/town/base.scn`; vehicles workstream).
6. P2 (14 Nov 2026, base): the map's `Warehouse entrance connection` still meets the old
   entrance at x = 0; it should end at the new entrance x −12.2. The site bounds still reach
   z 249.9 (the building ends at 235.3); the zone polygon was kept to match them.
7. P3 (14 Nov 2026): the old checks and capture scripts in `docs/evidence/warehouse-20261105/` and
   `docs/evidence/warehouse-20261108/` use removed constants and no longer run; they are history.

8. P2 (14 Nov 2026): *brown* and *medium* (dictionary words added 8 Nov for the old game) are
   now placed nowhere and used by no game; remove them or give them a use (user decision).

### Standalone delivery truck — 5 November 2026

`warehouse.gd::delivery_truck()` now instances `scenes/props/vehicles/box_truck.tscn`
at the former procedural truck transform. It remains a decorative *truck* vocabulary
object. Cab/cargo/chassis and future rear-door hinges are separate. See the
[vehicle guide](ZOO_VEHICLE_IMPLEMENTATION.md#integrated-vehicle-doors-and-warehouse-box-truck--5-november-2026)
for geometry, node contracts, collision limitations and verification.

### Drivable delivery truck — 8 November 2026

User request: the truck outside the warehouse can be driven. `box_truck.tscn` is now a
`DriveableVehicle` (`driveable_vehicle.gd`, word key *truck*, road profile `truck`: 4.2 t, top
speed 22 m/s): E at the driver door boards, W/S/A/D drive, E leaves, like the other road vehicles.
Structure: the root sits on the ground and faces −X (the road-vehicle convention); the former
model (`Cabin`, `Cargo`, `Chassis`) is the child `Model`, turned 90° and lifted 1.85. Four
`Tire*` nodes (word *wheel*, as on the fire truck) carry the road wheels; `StudyArea` holds the
cab and cargo boxes the physics sweeps. Only the driver door (left cab door) is a boarding door:
the passenger and rear cargo doors have `boarding_door = false` (`tools/bake_unit.gd` keeps such a
mark instead of marking every `vehicle_door.gd` leaf). `vehicle_door_spec` on the root gives the
boarding step and seat. Baked step `drivable_truck` of `scripts/buildings/warehouse.gd` lowered
the instance by 1.85 and turned it −90°, so its place and heading in the lot are unchanged
(cab toward −Z, backed up to the roll-up door). The cargo box is still not loadable.
Check: `docs/evidence/warehouse-20261108/truck_drive.gd` (19 checks, all passing on 8 Nov 2026) and its
`truck-*.png` views.
