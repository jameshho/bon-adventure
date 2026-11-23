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
| [`evidence/`](evidence/) | One folder per dated piece of work (`<topic>-<yyyymmdd>/`): its checks (`verify.gd`), capture scripts and screenshots. [`town-checks/`](evidence/town-checks/) holds the October town-wide checks and captures. The 26 folders without a date (`part2`, `pig-options`, `town_upgrade`, …) are mostly from before 27 Oct 2026, where git history starts, so their dates are unknown; check scripts write to them by path, so they keep their names | Put each new check, capture script and screenshot set in a new `evidence/<topic>-<yyyymmdd>/` folder; never write files to the top of `docs/` |
| [`archive/`](archive/) | Superseded one-off reports kept as history | Move a guide here when a newer guide replaces it, and update links |

After moving, renaming or deleting a doc or screenshot, check the links (no Godot needed; exits 1
if any relative link or `#anchor` is broken): `python3 tools/check_doc_links.py` (a path such as
`docs/game` limits it). A link to a capture that was never kept reads "(capture not kept)".

## Current guides: where to make decisions

One line per task (tightened 18 Nov 2026; the README links here for everything past its entry
points). The linked guide holds the details, ownership and checks; the dated design records in
the [master blueprint](guides/TOWN_DESIGN_BRIEF.md#start-here-current-approved-design) are history
once a newer record or guide covers the same thing. Add a line here, not a paragraph.

### Rules, structure and shared systems

| Task | Read | Key files |
| --- | --- | --- |
| Code ownership, coordinates, assets, data | [Architecture and editing rules](guides/ARCHITECTURE_REVIEW_PART1.md#current-editing-rules-parts-23) (the opening assessment is dated history) | |
| World structure, focus mode, changing a building | [Modular town](guides/MODULAR_TOWN.md), [changing a building](guides/MODULAR_TOWN.md#changing-a-building) | `scenes/town/`, `scripts/buildings/<unit>.gd`, `tools/bake_unit.gd`, `dev_focus.txt` |
| Main entry point: minigame panels, vehicles, gates, doors, room names | [Ownership](guides/ARCHITECTURE_REVIEW_PART1.md#architecture-and-ownership) | `scripts/core/main.gd`, `minigame_wiring.gd`, `vehicle_controls.gd`, `scripts/world/room_names.gd` |
| Words, languages, phrases, grammar, numbers | [Vocabulary data procedure](guides/ARCHITECTURE_REVIEW_PART1.md#vocabulary-data-procedure), [usage report](guides/vocabulary-report/summary.md), [word list](game/words.md) | `data/words.json` (only word source), `data/phrases.json`, `data/languages.json`, `scripts/language/`, `tools/language_check.gd` |
| Any 2D UI: screens, cards, dialogue box, buttons | [UI art style](guides/UI_STYLE.md), [mockups](guides/design-references/ui/) | `scripts/ui/bon_style.gd` |
| Dialogue box, translate bubble, Esc / popup stack, Settings, offers | [Shared dialogue, popups and settings](guides/ARCHITECTURE_REVIEW_PART1.md#shared-dialogue-popups-and-settings--4-november-2026) | `scripts/core/game_settings.gd`, `scripts/ui/popup_stack.gd`, `scripts/language/ui_text.gd`, `data/activities.json` |
| **Anything interactive or any character behaviour** (use, open, hold, sit, eyes) | [Reusable components](guides/COMPONENTS.md) (read before writing a new one) | `interactable.gd`, `door_animator.gd`, `hand_hold.gd`, `seating_controller.gd`, `plush_life.gd` |
| Holding and inspecting items | [Holding and inspecting](guides/HAND_HOLD.md) | `scripts/player/hand_hold.gd`, `object_inspector.gd` |
| Doors (migration paused) | [Doors](guides/DOORS.md) | door, double door and sliding door scenes |
| Windows and glass | [Windows](guides/WINDOWS.md) | `scenes/props/window.tscn`, `scripts/world/glass_window.gd`, step `glass_windows` |
| World signs and translations | [Spanish signs](guides/spanish-signs-20261027/README.md), [readability rule](guides/BUILDING_DESIGN_BLUEPRINT.md#sign-readability), [component](guides/COMPONENTS.md#world-signs) | `scripts/world/world_sign.gd`, `sign_language.gd`, `data/sign_translations.json` |
| Rendering, lighting, sky, day-night, web performance | [Performance](guides/performance/README.md), [day-night cycle](guides/performance/README.md#day-night-cycle--9-november-2026) | `scripts/world/day_night.gd`, `data/day_night.json`, `scripts/ui/day_clock.gd` |
| Web app (PWA), touch, export | [Web app](../README.md#web-app-pwa) | `export_presets.cfg` (preset **Web**), `tools/deploy_web.py` |
| Checks, known failures, unresolved issues | [Verification: current state](guides/FINAL_VERIFICATION.md#current-state--18-november-2026), [how to run](../README.md#verification) | `tools/run_checks.py`, `data/expected_check_failures.json`, `tools/check_doc_links.py` |

### Town and building design

| Task | Read | Key files |
| --- | --- | --- |
| **Start here for all town/building design** | [**Master design blueprint**](guides/TOWN_DESIGN_BRIEF.md#start-here-current-approved-design) | |
| Building size and interior capacity | [Measured dimension review](guides/BUILDING_DIMENSION_REVIEW.md) | |
| Building appearance, town map, new-building briefs | [Design blueprint](guides/BUILDING_DESIGN_BLUEPRINT.md), [saved user map](guides/design-references/town-map-blueprint.png), [brief template](guides/BUILDING_SPEC_TEMPLATE.md) | |
| Reusing building parts | [Component catalog](guides/BUILDING_COMPONENT_CATALOG.md) | |
| Home layout, doors, house plushes and outfits | [Reference home](guides/REFERENCE_HOME.md) | `scripts/buildings/home.gd`, `data/npcs.json`, `data/plush_costumes.json` |
| School floor plan, Grammar Classroom room | [Single rear-half divider](guides/TOWN_DESIGN_BRIEF.md#school-single-divider-layout--26-october-2026), [classroom](guides/GRAMMAR_CLASS.md) | `scripts/buildings/school.gd` |
| Hospital | [Three floors, stairs and elevator](guides/HOSPITAL_THREE_FLOORS.md), [ward doctors](guides/TOWN_DESIGN_BRIEF.md#hospital-ward-doctors--1-november-2026) | `scripts/buildings/hospital.gd` |
| Supermarket | [2 Nov refit](guides/TOWN_DESIGN_BRIEF.md#supermarket-refit-fruit-checkout-by-the-door-and-clerks--2-november-2026), [product art](guides/TOWN_DESIGN_BRIEF.md#supermarket-product-art--8-november-2026), [original fit-out](guides/TOWN_DESIGN_BRIEF.md#supermarket-interior-review--26-october-2026) | `scripts/buildings/supermarket.gd` |
| Warehouse | [Warehouse](guides/WAREHOUSE.md) | `scripts/buildings/warehouse.gd`, `scripts/world/warehouse.gd` |
| Police station | [Interior](guides/TOWN_DESIGN_BRIEF.md#police-station-interior--28-october-2026), [enlargement](guides/TOWN_DESIGN_BRIEF.md#police-station-enlargement-and-detective-games--6-november-2026), [officer](guides/TOWN_DESIGN_BRIEF.md#police-officer-crocodile-plush-at-the-station-entrance--1-november-2026) | `scripts/buildings/police.gd` |
| Airport terminal and control tower | [Terminal](guides/TOWN_DESIGN_BRIEF.md#airport-terminal-interior--28-october-2026), [tower](guides/TOWN_DESIGN_BRIEF.md#airport-control-tower--29-october-2026), [ladder, lift doors, swivel seats](guides/TOWN_DESIGN_BRIEF.md#tower-stair-walls-and-ladder-flush-lift-doors-swivel-seats-standable-bridge--30-october-2026), [roof deck](guides/TOWN_DESIGN_BRIEF.md#control-tower-roof-and-observation-deck--12-november-2026) | `scripts/buildings/airport.gd` |
| Restaurants (fine dining, Pizza, Burger, taquería, Alta Cocina) | [Relocation](guides/TOWN_DESIGN_BRIEF.md#restaurants-and-police-relocation--28-october-2026), [taquería, pool, sidewalks](guides/TOWN_DESIGN_BRIEF.md#mexican-restaurant-taquería--28-october-2026), [Alta Cocina and plush staff](guides/TOWN_DESIGN_BRIEF.md#alta-cocina-italian-remodel-and-plush-staff--1-november-2026) | `scripts/buildings/restaurants.gd` |
| Shops: sports, clothing, electronics, café and bakery, bank, furniture | [Sports](guides/TOWN_DESIGN_BRIEF.md#sports-store-interior--28-october-2026), [clothing](guides/TOWN_DESIGN_BRIEF.md#clothing-store-interior--28-october-2026), [electronics](guides/TOWN_DESIGN_BRIEF.md#electronics-store-refresh--1-november-2026), [café](guides/TOWN_DESIGN_BRIEF.md#café-and-bakery-interior--28-october-2026), [bank](guides/TOWN_DESIGN_BRIEF.md#bank-interior--28-october-2026), [furniture](guides/TOWN_DESIGN_BRIEF.md#furniture-showroom--29-october-2026), [staff](guides/TOWN_DESIGN_BRIEF.md#shop-staff-bank-sports-store-furniture-showroom--1-november-2026) | `scripts/buildings/<unit>.gd` |
| Storefronts and the shop-row look | [Exterior redesign](guides/TOWN_DESIGN_BRIEF.md#storefront-exterior-redesign--1-november-2026), [game palette and shop row](guides/TOWN_DESIGN_BRIEF.md#game-palette-and-shop-row--18-november-2026) | `scripts/buildings/shop_row.gd` |
| Farm barn | [Record](guides/TOWN_DESIGN_BRIEF.md#farm-barn-gambrel-roof-hayloft-and-supplies-interior--1-november-2026) | `scripts/buildings/barn.gd` |
| Playground and rideable swings | [Record and swing controls](guides/TOWN_DESIGN_BRIEF.md#playground-rebuild-and-rideable-swings--1-november-2026) | `scripts/buildings/playground.gd`, `scripts/world/playground_swing.gd` |
| Mystery House | [Record](guides/TOWN_DESIGN_BRIEF.md#mystery-house-and-mystery-doors--9-november-2026) | `scripts/buildings/mystery.gd` |
| Toilets, faucets and their sounds | [Bathroom fixtures](guides/TOWN_DESIGN_BRIEF.md#bathroom-fixtures--8-november-2026) | `scripts/world/bath_fixtures.gd`, `toilet.gd`, `faucet.gd`, `data/sounds.json` |
| Electrical boxes | [Electrical box](guides/ELECTRICAL_BOX.md) | `scripts/world/electrical_box.gd` |
| Coast, island, boulders, crabs | [Record](guides/TOWN_DESIGN_BRIEF.md#coast-deserted-island-boulders-and-crabs--29-october-2026) | `scenes/town/base.scn`, `scripts/buildings/base.gd`, `shaders/sand.gdshader` |
| Roads, sidewalks, streetlights | [Streets polish](guides/TOWN_DESIGN_BRIEF.md#streets-polish--28-october-2026) | `scripts/buildings/base.gd` |
| Garden (history before the modular town) | [Public garden](guides/public-garden/README.md) | `scenes/town/base.scn` |

### Minigames

| Task | Read | Key files |
| --- | --- | --- |
| Passport: missions, town stamps, achievements, XP | [Passport guide](guides/ACHIEVEMENTS.md) | `scripts/learning/achievements.gd`, `missions.gd`, `scripts/ui/passport_panel.gd`, `scripts/world/stamp_coin.gd`, `data/achievements.json` |
| **Any minigame: index, building or changing one** | [Minigame index](guides/MINIGAMES.md), [building a minigame](guides/MINIGAMES.md#building-a-minigame), [purpose and progression](game/minigames.md) | `scripts/learning/minigame_host.gd`, `minigame_zone.gd`, `scripts/ui/game_launcher.gd` |
| Customer order (supermarket) | [Record](guides/TOWN_DESIGN_BRIEF.md#customer-order-minigame--3-november-2026) | `data/shops.json`, `scripts/learning/shop_*.gd` |
| Cashier money, Spanish amounts; the supermarket till (checkout, free shopping) | [Record](guides/TOWN_DESIGN_BRIEF.md#cashier-money-minigame--4-november-2026), [checkout 21 Nov](guides/TOWN_DESIGN_BRIEF.md#grocery-checkout-and-free-shopping--21-november-2026) | `scripts/learning/currency.gd`, `cashier_session.gd`, `scripts/ui/money_panel.gd` |
| Hospital family game | [Record](guides/TOWN_DESIGN_BRIEF.md#hospital-family-game--4-november-2026), [ownership](guides/ARCHITECTURE_REVIEW_PART1.md#hospital-family-game-ownership--4-november-2026) | `data/family_game.json`, `scripts/learning/family_session.gd` |
| Airport flight game | [Record](guides/TOWN_DESIGN_BRIEF.md#airport-flight-game--5-november-2026), [ownership](guides/ARCHITECTURE_REVIEW_PART1.md#airport-flight-game-ownership--5-november-2026) | `data/flight_game.json`, `scripts/learning/flight_*.gd`, `game_clock.gd` |
| Alta Cocina restaurant game | [Record](guides/TOWN_DESIGN_BRIEF.md#alta-cocina-restaurant-game--6-november-2026), [11 Nov flow](guides/TOWN_DESIGN_BRIEF.md#restaurant-game-reception-tables-and-order-tablet--11-november-2026), [ownership](guides/ARCHITECTURE_REVIEW_PART1.md#restaurant-game-ownership--6-november-2026) | `data/restaurant_game.json`, `scripts/learning/restaurant_*.gd` |
| Police detective games | [Record](guides/TOWN_DESIGN_BRIEF.md#police-station-enlargement-and-detective-games--6-november-2026), [ownership](guides/ARCHITECTURE_REVIEW_PART1.md#police-detective-games-ownership--6-november-2026) | `data/detective_game.json`, `scripts/learning/police_detective_session.gd` |
| Warehouse Worker | [Warehouse](guides/WAREHOUSE.md) | `scripts/learning/warehouse_session.gd` |
| Grammar Classroom | [Grammar Classroom](guides/GRAMMAR_CLASS.md) | `scripts/learning/grammar_session.gd`, `data/grammar_class/` |
| Hong Kong mahjong | [Mahjong](guides/MAHJONG.md) | `scripts/learning/mahjong_session.gd`, `data/mahjong.json` |
| Mystery Doors | [Record](guides/TOWN_DESIGN_BRIEF.md#mystery-house-and-mystery-doors--9-november-2026) | `scripts/learning/mystery_session.gd` |
| Radar Patrol | [Radar Patrol](guides/RADAR_PATROL.md) | |
| Library Helper | [Index row](guides/MINIGAMES.md), [record](guides/TOWN_DESIGN_BRIEF.md#library-return-cart-and-book-sorting-game--13-november-2026) | `scripts/learning/library_session.gd`, `scripts/buildings/library.gd` |
| Welcome tutorial | [Welcome tutorial](guides/ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial) | `data/tutorial.json`, `scripts/learning/tutorial.gd` |

### Characters, animals and vehicles

| Task | Read | Key files |
| --- | --- | --- |
| Animals: movement, sizes, clay models, adding species | [Animal system](guides/ANIMAL_SYSTEM.md) | `scenes/animals/`, `scripts/world/park_animals.gd` |
| Player BonBon | [BonBon](guides/BONBON_VALIDATION.md) | |
| Every NPC (registry, positions, idle chatter, how to add one) | [NPCs](guides/NPCS.md) | `data/npcs.json`, `scripts/characters/npc_registry.gd`, `npc_chatter.gd`, `tools/npc_report.py` |
| Plush characters and sculpts | [Reference home](guides/REFERENCE_HOME.md), [components](guides/COMPONENTS.md) | `scripts/characters/plush_sculpt.gd`, `house_characters.gd`, `plush_costume.gd` |
| Road vehicles | [Road physics and boarding](guides/ZOO_VEHICLE_IMPLEMENTATION.md) | |
| Helicopter | [Rotor physics](guides/helicopter_inertia/README.md) (older motion tests are historical) | |
| Airplane | [Turboprop](guides/aircraft.md) | |

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
