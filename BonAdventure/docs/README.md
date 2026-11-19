# Documentation map

Start with the [project README](../README.md) for running the game, controls and
safe test configuration, and [workspace instructions](../../AGENTS.md) before
editing. Read the relevant guide below rather than every historical report.

**Reviewing the game rather than changing it?** Start with the [game guide](game/README.md):
what is in the game today, one page each for playing, the town and the minigames, with one
current screenshot per feature and a status table. When a change is visible to players, update
its row and entry there too.

## Folder layout

Reorganised on 16 Nov 2026 (user request: easier to navigate); every file kept its name and
moved with `git mv`, and every reference was rewritten, so git history follows each file.

| Folder | What goes there | Rule for new files |
| --- | --- | --- |
| [`game/`](game/README.md) | The game guide: what is built, minigame learning cards (purpose, progression), the generated word list | Update when a change is visible to players; `words.md` is generated, never edited |
| [`guides/`](guides/) | Current reference documents listed in the table below, with their own folders (performance, public garden, helicopter, signs, licenses, vocabulary report) and [`design-references/`](guides/design-references/) for images the user supplied as designs | Update the existing guide; add a new one only for a distinct ongoing topic, and link it below |
| [`evidence/`](evidence/) | One folder per dated piece of work (`<topic>-<yyyymmdd>/`): its checks (`verify.gd`), capture scripts and screenshots. [`town-checks/`](evidence/town-checks/) holds the October town-wide checks and captures | Put each new check, capture script and screenshot set in a new `evidence/<topic>-<yyyymmdd>/` folder; never write files to the top of `docs/` |
| [`archive/`](archive/) | Superseded one-off reports kept as history | Move a guide here when a newer guide replaces it, and update links |

After moving, renaming or deleting a doc or screenshot, check the links (no Godot needed; exits 1
if any relative link or `#anchor` is broken): `python3 tools/check_doc_links.py` (a path such as
`docs/game` limits it). A link to a capture that was never kept reads "(capture not kept)".

## Current guides: where to make decisions

| Task | Authoritative document | How to use it |
| --- | --- | --- |
| Code ownership, world coordinates, assets or vocabulary | [Architecture and editing rules](guides/ARCHITECTURE_REVIEW_PART1.md#current-editing-rules-parts-23) | Follow the current editing rules; the opening assessment is dated history. |
| World structure: base world, building units, focus mode, changing a building | [Modular town guide](guides/MODULAR_TOWN.md), [changing a building](guides/MODULAR_TOWN.md#changing-a-building) | Since 6 Nov 2026 the town loads from `scenes/town/` (one scene per building); change a building in its unit scene or with `scripts/buildings/<unit>.gd` + `tools/bake_unit.gd`. The old startup passes, full bake and old saved worlds were deleted that day (git history). |
| **Start here for all town/building design** | [**Master design blueprint**](guides/TOWN_DESIGN_BRIEF.md#start-here-current-approved-design) | Approved decision summary, detailed programs, boundaries and next-agent workflow. Other design documents support this entry point. |
| Building dimensions before exterior work | [Measured capacity review](guides/BUILDING_DIMENSION_REVIEW.md) | Implemented school/market dimensions, preservation and verification; historical capacity budgets and unapproved options. |
| Building design and town map | [Design blueprint](guides/BUILDING_DESIGN_BLUEPRINT.md) | Use the design goals and priorities; confirm implementation in source. Current coordinates belong to the architecture guide. |
| Reusing building parts | [Component catalog](guides/BUILDING_COMPONENT_CATALOG.md) | Find inspected components and ownership before creating geometry. |
| Planning a building change | [Building brief template](guides/BUILDING_SPEC_TEMPLATE.md) | Fill out only the relevant brief; it is not an implementation report. |
| School floor plan | [Single rear-half divider](guides/TOWN_DESIGN_BRIEF.md#school-single-divider-layout--26-october-2026) | Current partition layout, ownership and checks. |
| Hospital interior | [Current hospital guide](guides/HOSPITAL_THREE_FLOORS.md) | Floor programs, colours and floor signs, generator, elevator controls/source license, wide stairs, department displays and cutaway checks. |
| Supermarket interior | [Implemented nine-department layout](guides/TOWN_DESIGN_BRIEF.md#supermarket-interior-review--26-october-2026) | Runtime ownership, fixtures, circulation, verification and scope. |
| Home interior | [Reference home](guides/REFERENCE_HOME.md) | Use the original design reference and current runtime ownership. |
| Animal movement and size | [Animal system](guides/ANIMAL_SYSTEM.md) | Measured BonBon/snake reference, all species scales, wandering profiles, boundaries and checks. |
| Player model and movement | [BonBon](guides/BONBON_VALIDATION.md) | Find implementation and focused checks; results describe the recorded run. |
| Road vehicles | [Road physics and boarding](guides/ZOO_VEHICLE_IMPLEMENTATION.md) | Use current controls, physics ownership and checks. |
| Helicopter | [Rotor physics](guides/helicopter_inertia/README.md) | Use the replacement controller guide; older motion tests are historical. |
| Airplane | [Turboprop](guides/aircraft.md) | Use controls, boarding, physics and attribution. |
| Taquería, home pool, raised sidewalks | [Design brief records](guides/TOWN_DESIGN_BRIEF.md#mexican-restaurant-taquería--28-october-2026), check `docs/evidence/town-polish-20261028/verify.gd` | Mexican restaurant program and new words; sunken pool and curbed sidewalk ownership. |
| All minigames | [Minigame index](guides/MINIGAMES.md), [Building a minigame](guides/MINIGAMES.md#building-a-minigame) | One table of every minigame: NPC, place, learning goals, words and shared systems; links to each design record. How to build one on the shared NPC host and in-world zone. |
| Warehouse and Warehouse Worker minigame | [Warehouse guide](guides/WAREHOUSE.md), checks `docs/evidence/warehouse-20261114/verify.gd`, `verify_game.gd` (14 Nov 2026 redesign) | Building between the moved school and the airport, its words, posters and hall equipment, the Warehouse Worker game (frame, physics goods, trolleys, task generator and checks); phases and status. |
| Grammar Classroom minigame | [Grammar Classroom guide](guides/GRAMMAR_CLASS.md), check `docs/evidence/grammar-class-20261106/verify.gd`; deferred shared component [future_minigame_zone.md](guides/future_minigame_zone.md) | Lana's class in the remodelled general classroom: question banks per language, desks as answers, board, countdown, feedback, leave question. |
| Radar Patrol | [Radar Patrol guide](guides/RADAR_PATROL.md), check `docs/evidence/radar-patrol-20261109/rules.gd` | Arcade pastime on the control-tower radars: rules, scoring, files, restyled radars. |
| **Any 2D UI: screens, cards, dialogue box, buttons** | [UI art style](guides/UI_STYLE.md), mockups in [`design-references/ui/`](guides/design-references/ui/), views `docs/evidence/ui-style-20261118/capture.gd` | The one cream-and-meadow look (user, 18 Nov 2026): palette, Fredoka, parts and rules; build with `scripts/ui/bon_style.gd`. Phase 1 (start screens, loading, dialogue box) approved 18 Nov 2026; phase 2 (Settings, journal, HUD, minigame panels) follows. |
| **Anything interactive or any character behaviour** | [Reusable components](guides/COMPONENTS.md), check `docs/evidence/plush-rig-20261113/verify.gd` | One index of the shared components (interaction, doors and drawers, holding, sitting, eyes / blinking / gestures) with examples, the plush rig and the ownership table. Read before writing a new one. |
| Holding and inspecting items | [Holding and inspecting guide](guides/HAND_HOLD.md), check `docs/evidence/hand-hold-20261113/verify.gd` | Left-hand holder for the player with per-object hold profiles; the Inspect button and the reusable close-up inspector. |
| Doors (in progress) | [Doors guide](guides/DOORS.md), views `docs/evidence/doors-20261113/` | Shared door, double door and sliding door components (13 Nov 2026); building migration paused, steps listed. |
| Windows and glass | [Windows guide](guides/WINDOWS.md), views `docs/evidence/windows-20261112/capture.gd` | One shared window component and glass material for every building; which panes are see-through; the opaque fallback mode. |
| Electrical boxes | [Electrical box guide](guides/ELECTRICAL_BOX.md), check `docs/evidence/electrical-box-20261109/verify.gd` | Reusable wall box with a 3D wire-repair puzzle: placing more boxes, exports, files, verification. |
| Hong Kong mahjong | [Mahjong guide](guides/MAHJONG.md), checks `docs/evidence/mahjong-20261109/verify.gd` (rules), `play.gd` (table) | Mei's table in front of the home: user decisions, fan table, flow, ownership, NPC strength, open issues. |
| Cashier money minigame | [Design record](guides/TOWN_DESIGN_BRIEF.md#cashier-money-minigame--4-november-2026), checks `docs/evidence/cashier-money-20261104/verify.gd` and `verify_town.gd` | Samoyed cashier asks for an amount in Spanish; the player clicks bills and coins into a tray; reusable for the bank. |
| Customer order minigame | [Design record](guides/TOWN_DESIGN_BRIEF.md#customer-order-minigame--3-november-2026), checks `docs/evidence/customer-order-20261103/verify.gd` and `verify_town.gd` | Supermarket clerk asks the player to fetch a random list; order and cart rows show product pictures (8 Nov 2026); replaces missions. |
| Furniture showroom | [Design record](guides/TOWN_DESIGN_BRIEF.md#furniture-showroom--29-october-2026), check `docs/evidence/furniture-interior-20261029/verify.gd` | Enlarged to 24 × 26 with approval; flat green-trim exterior; eight new words; zone `furniture` unchanged. |
| Coast, deserted island, boulders, crabs | [Design record](guides/TOWN_DESIGN_BRIEF.md#coast-deserted-island-boulders-and-crabs--29-october-2026), check `docs/evidence/coast-20261029/verify.gd` | East-coast island, wavier sand edge with new sand shader, 14 boulders, 10 crabs; word *crab* added with approval. |
| Sports store interior | [Design record](guides/TOWN_DESIGN_BRIEF.md#sports-store-interior--28-october-2026), check `docs/evidence/sports-interior-20261028/verify.gd` | Fitted into the unchanged 14 × 24 shell; no zoning change. |
| Clothing store interior | [Design record](guides/TOWN_DESIGN_BRIEF.md#clothing-store-interior--28-october-2026), check `docs/evidence/clothing-interior-20261028/verify.gd` | Fitted into the unchanged shell; no zoning change. |
| Electronics store interior | [Design record](guides/TOWN_DESIGN_BRIEF.md#electronics-store-refresh--1-november-2026), check `docs/evidence/electronics-interior-20261101/verify.gd` | Refitted 1 Nov 2026 as a real electronics shop in the unchanged shell; no new words. |
| Bank interior | [Design record](guides/TOWN_DESIGN_BRIEF.md#bank-interior--28-october-2026), check `docs/evidence/bank-interior-20261028/verify.gd` | Unchanged 12 × 15 shell; vault, office, doors and inside ATMs kept. |
| Shop staff (bank, sports, furniture) | [Design record](guides/TOWN_DESIGN_BRIEF.md#shop-staff-bank-sports-store-furniture-showroom--1-november-2026), check `docs/evidence/shop-staff-20261101/verify.gd` | Costumed bear banker and golden/sheep salespeople; apron variants in `plush_costumes.json`; words *banker*, *salesperson*. |
| Hospital ward doctors | [Design record](guides/TOWN_DESIGN_BRIEF.md#hospital-ward-doctors--1-november-2026), check `docs/evidence/hospital-doctors-20261101/verify.gd` | Pig (BonBon), cat and beagle in the existing `doctor` outfit on floors 1–3; word *doctor*; no new keys. |
| Police officer at the station | [Design record](guides/TOWN_DESIGN_BRIEF.md#police-officer-crocodile-plush-at-the-station-entrance--1-november-2026), check `docs/evidence/police-officer-20261101/verify.gd` | Blocky `police_officer.tscn` retired at runtime; crocodile plush in the `police` outfit beside the entrance; word *police officer*; no new keys. |
| Farm barn | [Design record](guides/TOWN_DESIGN_BRIEF.md#farm-barn-gambrel-roof-hayloft-and-supplies-interior--1-november-2026), check `docs/evidence/barn-20261101/verify.gd`, views `capture.gd` | Gambrel roof (ridge 10.5), hayloft with climbable ladder, tools / hay / supplies; nine new words. |
| Police station interior | [Design record](guides/TOWN_DESIGN_BRIEF.md#police-station-interior--28-october-2026), check `docs/evidence/police-interior-20261028/verify.gd` | Unchanged 12 × 15 shell; interview room, cell and doors kept. |
| Airport terminal interior | [Design record](guides/TOWN_DESIGN_BRIEF.md#airport-terminal-interior--28-october-2026), check `docs/evidence/airport-interior-20261028/verify.gd` | Unchanged terminal; new Travel word category. |
| Airport control tower | [Design record](guides/TOWN_DESIGN_BRIEF.md#airport-control-tower--29-october-2026), check `docs/evidence/control-tower-20261029/verify.gd` | Walkable 22-high tower (lift + stair, open shaft, hidden radar room, discreet door), narrow shaft with wide glass control room; four new words (stairs, elevator, radar, headset); lift is the shared hospital elevator script. Roof, wrap-around observation deck and west sliding deck door: [record](guides/TOWN_DESIGN_BRIEF.md#control-tower-roof-and-observation-deck--12-november-2026), check `docs/evidence/tower-deck-20261112/verify.gd`. |
| Tower ladder/walls, lift doors, swivel seats, bridge perches | [Design record](guides/TOWN_DESIGN_BRIEF.md#tower-stair-walls-and-ladder-flush-lift-doors-swivel-seats-standable-bridge--30-october-2026), check `docs/evidence/tower-bridge-seats-20261030/verify.gd` | Stair now ends at 16.5 (walled), ladder + hatch to the control room, empty level 16.5; ladder climbing and A/D swivel are new player/seat controls. |
| Café and bakery interior | [Design record](guides/TOWN_DESIGN_BRIEF.md#café-and-bakery-interior--28-october-2026), check `docs/evidence/bakery-cafe-interior-20261028/verify.gd` | Fitted into the unchanged 14 × 22 shell; no zoning change. |
| Fine dining, Pizza and Burger, police relocation | [Restaurant and police record](guides/TOWN_DESIGN_BRIEF.md#restaurants-and-police-relocation--28-october-2026), check `docs/evidence/restaurants-20261028/verify.gd` | Merged fine-dining room, L-shaped Pizza and Burger, police moved south of the supermarket; zones and signs. |
| Roads, sidewalks, streetlights, driving feel | [Streets polish](guides/TOWN_DESIGN_BRIEF.md#streets-polish--28-october-2026), check `docs/evidence/streets-20261028/verify.gd` | Road-edge drives/walks, curb ramps, road/paving shaders, street furniture, vehicle tuning. |
| Words: add, edit, delete | [Vocabulary data procedure](guides/ARCHITECTURE_REVIEW_PART1.md#vocabulary-data-procedure) and [vocabulary usage report](guides/ARCHITECTURE_REVIEW_PART1.md#vocabulary-usage-report) ([current result](guides/vocabulary-report/summary.md)) | `data/words.json` is the only word source; the report lists where each word is placed, which games test or show it, unplaced words, unknown keys and duplicates. |
| World signs | [Spanish signs](guides/spanish-signs-20261027/README.md) | Translation table, language toggle, fit rule and how to add a sign. |
| Garden construction | [Public garden](guides/public-garden/README.md) | Find source/bake boundaries; use architecture rules for subsequent layout changes. |
| Rendering, lighting and sky | [Performance](guides/performance/README.md) | Find batching, sun/sky/environment ownership, tuning notes and benchmark/check scripts. |
| Checks and unresolved issues | [Verification record](guides/FINAL_VERIFICATION.md) | Read the latest relevant dated section, including limitations; earlier pass counts do not certify today's project. |

For vocabulary, use the architecture guide's
[data procedure](guides/ARCHITECTURE_REVIEW_PART1.md#vocabulary-data-procedure).
The current inventory lives in one file, `data/words.json` (see the
[vocabulary usage report](guides/vocabulary-report/summary.md) for unplaced words and duplicates). Old removal lists and audit counts are not an
inventory or a request to restore deleted words.

## Verification tools and evidence

Checks and capture scripts live in their `evidence/` folders and are run by path
(`res://docs/evidence/<folder>/<script>.gd`); move one only together with every reference to
it (the runner, guides, other scripts). Run checks with the runner, `python3 tools/run_checks.py [quick|full]`: it isolates saves,
applies timeouts and compares failure labels with
[`data/expected_check_failures.json`](../data/expected_check_failures.json), reporting only
NEW, FIXED, crashed and timed-out checks ([how, and how to add a check](../README.md#verification)).
Inspect a check before adding it: some write learner progress, result files or screenshots.
Headless checks do not establish visual appearance.

| Files | Purpose |
| --- | --- |
| `check_*.gd`, `check_*.py` | Focused runtime or static checks. Select by affected feature and consult the verification record for known failures. |
| `docs/evidence/part2/verify.gd`, feature-folder `verify.gd` / `verify.py` | Feature regression checks; older assumptions may have been superseded. |
| `capture_*.gd`, `render_*.gd`, feature capture/preview scripts | Generate rendered evidence; may overwrite existing images. |
| `docs/guides/performance/benchmark.gd`, `docs/guides/performance/check_rendering.gd` | Performance measurement and rendering regression. |
| [Food fixture](evidence/town-checks/FOOD_SHOPPING_VOCAB_ADDITIONS.json), [travel fixture](evidence/town-checks/TRANSPORT_NAV_TIME_ADDITIONS.json) | Required inputs for `check_food_shopping_vocab.py` and `check_transport_navigation_time.py`. Keep in sync with intentional changes to their tested content. |
| PNG/GIF images, `validation.txt`, `test_results.txt`, other result files | Dated evidence, not current test status. Keep design references distinct from screenshots. |
| [Licenses](guides/licenses/) | Retained third-party attribution; see vehicle guides for usage. UI font `fonts/NotoSans-SemiBold.ttf`: [SIL Open Font License 1.1](guides/licenses/noto-sans-OFL.txt). Chinese fallback `fonts/NotoSansTC-SemiBold-subset.ttf` (Noto Sans TC subset, [OFL 1.1](guides/licenses/noto-sans-tc-OFL.txt); [regenerate](../README.md#web-app-pwa) with `tools/build_cjk_font.py`). |

## Historical implementation records

These explain earlier changes or preserve useful evidence. Their coordinates,
counts, active-scene statements and validation claims belong to that snapshot.
Use the current guides above before applying any instructions from them.

| Topic | Records |
| --- | --- |
| Runtime refinement pass and animal sizes | [Part 2 handoff](evidence/part2/HANDOFF.md) (layout superseded; guard/ownership rules retained in architecture) |
| Earlier town layouts | [Natural town](evidence/town-redesign/README.md), [reference expansion](evidence/world_expansion/README.md), [town upgrade](evidence/town_upgrade/README.md), [coverage snapshot](evidence/town_upgrade/coverage.md) (their `verify.gd` checks were retired 6 Nov 2026 with the old worlds) |
| Earlier building and interior work | [Exterior repairs](archive/BUILDING_EXTERIORS.md), [civic expansion](archive/CIVIC_EXPANSION.md), [zoo/interiors](archive/ZOO_INTERIOR_UPDATE.md), [library/market](evidence/library-market-review/README.md) |
| Earlier home and island work | [Home/navigation](archive/HOME_AND_NAVIGATION_REFRESH.md), [house polish](archive/HOUSE_INTERIOR_REVIEW.md), [island](archive/ISLAND_UPDATE.md), [home/pig fixes](evidence/home-pig-fixes/README.md) |
| Pig and helicopter appearance | [Pig landmark](archive/PIG_RENAME_AND_LANDMARK.md), [pig comparisons](evidence/pig-options/README.md), [helicopter appearance](evidence/helicopter_look/README.md) |
| Earlier repairs and mechanics | [Runtime fixes](archive/BUGFIX_CHECK_2026-10-18.md), [editor imports](evidence/editor_import/README.md), [rooftops](evidence/rooftop-review/README.md), [superseded helicopter motion](evidence/helicopter_motion/README.md) |
| Migration and generated learning assets | [Migration](archive/MIGRATION.md), [learning update](archive/LEARNING_UPDATE.md) (old rebuild sequence; not routine editing instructions) |

## Maintaining documentation

Update the existing guide for a behavior or ownership change. Add dated checks and
unresolved priorities to `FINAL_VERIFICATION.md`, without rewriting earlier results.
Add a link here only when a separate guide has a distinct ongoing purpose. Keep
paths stable for tools; avoid new completion reports that duplicate the guides. New files go
in the folder the [layout](#folder-layout) names; nothing new at the top of `docs/`.

Cleanup on 25 October 2026 removed nine superseded vocabulary cleanup/audit/expansion
reports, seven unused removal/mapping/validation JSON files and the obsolete
`QA_REPORT.md`. Current data, active checks, their two vocabulary fixtures, design
references, licenses and useful dated implementation evidence were retained.
The older numbered-copy manifest in `docs/guides/public-garden/duplicate-cleanup.json` records
paths at the time of that earlier cleanup; it is not a list of files required today.

### Hospital surface and stair repair — 26 October 2026

The user authorized replacing the cramped switchbacks and repairing interior/exterior
surfaces. The implemented straight stairs have front and rear approaches on every
floor. See the [current hospital guide](guides/HOSPITAL_THREE_FLOORS.md) for dimensions, facade ownership,
normal-control tests and screenshots. This supersedes earlier switchback guidance.

Zone editing and Stage 1 inspection: [inventory, rationale, priorities, cutouts and checks](guides/ARCHITECTURE_REVIEW_PART1.md#zone-boundaries--stage-1-inspection-28-october-2026). Stage 1 boundaries were approved; Stage 2 is implemented.

Journal category/area ownership and verification: [Stage 2 guide](guides/ARCHITECTURE_REVIEW_PART1.md#category-and-area-journal--stage-2-28-october-2026). The journal's table, filters, scores and word detail: [vocabulary book](guides/ARCHITECTURE_REVIEW_PART1.md#vocabulary-book) (8 Nov 2026).
