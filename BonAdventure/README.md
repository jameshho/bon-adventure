# Bon Adventure: Little Town of Words

The game's name since 16 Nov 2026 (user decision; earlier Vocabulary Town): see [Name](#name). An offline Spanish vocabulary exploration game built with Godot 4.x and GDScript.
Validated with **Godot 4.7.2**, using the **GL Compatibility** renderer. No external
runtime packages are required. Python 3 is used by optional authoring tools and
static checks; it is not needed to play.

Open `project.godot` in Godot, let imports finish, and Play Project (F5) or, from this
directory, `godot --path .`: since 12 Nov 2026 that runs `scenes/app.tscn` (the Bon Adventure logo with Play,
character select, languages for a new character, loading screen, town). Running `scenes/main.tscn` (F6) still starts
the town directly with the last used profile (or the flat `user://` saves).

## Name

**Bon Adventure: Little Town of Words** (user decision, 16 Nov 2026), "Bon Adventure" for short
(the installed app's label). The logo is `assets/branding/bon_adventure_logo.webp`, cleaned from
the user's picture in `assets/branding/source/` (`clean_logo.py`, then on 18 Nov 2026
`clear_logo_pockets.gd` made the brown gaps between the animals transparent); the app icons are the user's pig-head picture (`assets/branding/source/app_icon_source.webp`)
([evidence](docs/evidence/bon-adventure-logo-20261116/README.md)). Shown so far on the title page
(`app.title` is its fallback text) and, through `tools/deploy_web.py`, as the web page's title and
the PWA manifest's `name` / `short_name`. The player character is **BonBon** (邦邦, a girl;
user, 16 Nov 2026). `project.godot` `config/name` is "Bon Adventure" since 16 Nov 2026 (desktop
saves move with it, see [the save move](#controls-and-learning)); a saved avatar that is no longer
a house character (such as the pig's id before the rename) loads as BonBon, and the web resume
note moved from `vt-resume` to `bon-resume`.

## Start here

| Task | Read |
| --- | --- |
| AI development (rules, git, verification budget) | [Workspace instructions](../AGENTS.md) |
| What is in the game now (playing, town, minigames, status) | [Game guide](docs/game/README.md) |
| **Find the guide and key files for any task** | [Documentation map: current guides](docs/README.md#current-guides-where-to-make-decisions) (one line per task) |
| Town and building design | [**Master design blueprint**](docs/guides/TOWN_DESIGN_BRIEF.md#start-here-current-approved-design) |
| Architecture, ownership, coordinates, adding data | [Architecture and editing rules](docs/guides/ARCHITECTURE_REVIEW_PART1.md) |
| World structure, changing a building | [Modular town](docs/guides/MODULAR_TOWN.md#changing-a-building) |
| Words, languages, phrases | [Vocabulary data procedure](docs/guides/ARCHITECTURE_REVIEW_PART1.md#vocabulary-data-procedure) |
| Minigames | [Minigame index](docs/guides/MINIGAMES.md), [building a minigame](docs/guides/MINIGAMES.md#building-a-minigame) |
| 2D UI | [UI art style](docs/guides/UI_STYLE.md) |
| Anything interactive or any character behaviour | [Reusable components](docs/guides/COMPONENTS.md) |
| Checks, known failures, priorities | [Verification: current state](docs/guides/FINAL_VERIFICATION.md#current-state--18-november-2026), [running checks](#verification) |
| Running, controls, web app | [What runs](#what-runs), [controls](#controls-and-learning), [web app](#web-app-pwa) |

The [documentation map](docs/README.md) separates current guides, verification
tools and historical evidence. Use current guides for editing decisions and the
latest relevant section of the verification record for recorded checks and limits.

## What runs

**Modular town (6 Nov 2026, [guide](docs/guides/MODULAR_TOWN.md)).** `scenes/main.tscn` instances
`scenes/town/base.scn` (ground, roads, garden, zoo, vehicles) as `Apartment` with uniform scale
**1.3**. `scripts/world/modular_town.gd` then loads the building units listed in
`data/buildings.json` (`scenes/town/<unit>.scn`) and puts every part back at its old node path;
Main restores door states, the reference layout (`reference_world_layout.gd::restore()`) and sign
translation. The old startup passes (`public_garden.gd`, `reference_home.gd`,
`world_refinements.gd` and the interior scripts it calls) were baked once into these scenes and
then **deleted** with the old saved worlds and bake tools (6 Nov 2026; in git history). To change a building, edit its unit scene in the editor or add a step
to its own script `scripts/buildings/<unit>.gd` and bake just that building
([how](docs/guides/MODULAR_TOWN.md#changing-a-building)):

```sh
godot --headless --path . --script res://tools/bake_unit.gd -- police
```

The base world (ground, roads, garden, zoo, vehicles, and the map/layout data in its
`baked_layout` meta) is baked the same way with `-- base` and its own script
`scripts/buildings/base.gd`; review any bake with `tools/compare_scenes.gd`
([how](docs/guides/MODULAR_TOWN.md#changing-the-base-world)).

UI creation and runtime garden batching follow world construction. The compact layout's
rigid relocations come from `data/reference_layout.json`'s `compact_layout` section; see the
[current layout rules](docs/guides/ARCHITECTURE_REVIEW_PART1.md#coordinates-roads-and-visual-standards).

**Fast boot for chosen buildings (development only).** `dev_focus.txt` (next to `project.godot`,
tracked) lists the building units to load, for example `restaurants, police`; every other
building (interior **and** exterior) is left out, while the base world always loads. Unit names
are the keys of `data/buildings.json` (`tower` is an alias of `airport`). `all` (the committed
default) or an empty file loads everything; the environment variable `VT_FOCUS` overrides the file.
Reset it to `all` before committing or running final verification. Shop and minigame sessions of
missing buildings print a warning and stay off. The player spawns outside the home's front door
(the supermarket door until 25 Nov 2026; the supermarket when the home is not loaded)
unless the file also has `spawn=<name>`: any building name (`police`, `school`, `airport`, `warehouse`, ... plus `mystery`), `restaurant` (Alta Cocina door), `burger`/`pizza` (same door) or `taqueria`; the building must be listed or `all` (places in
`main.gd` `ENTRANCES`, shared with the saved-place respawn since 14 Nov 2026, plus `tower`; door points measured 10 Nov 2026 and checked in rendered views 10 Nov 2026; `VT_SPAWN` overrides). Headless boot, 6 Nov 2026 (Apple M5): full town
16.0 s before → 8.5 s modular; `restaurants, police` 7.5 s before → 4.0 s modular. Windowed to
the first drawn frame: `restaurants, police` about 11 s → 3.9 s, full town 11.5 s → 5.4 s, once
the character cache is filled (`user://sculpt_cache/`, about 58 MB, safe to delete;
`VT_SCULPT_CACHE=0` turns it off; [details](docs/guides/MODULAR_TOWN.md#boot-time-follow-up--6-november-2026)).

**Nearby loading (web, Low graphics; 17 Nov 2026).** A profile that finished the tutorial starts
with only the buildings near its saved spot and adds the others as the player comes within 150 m
(`scripts/world/nearby_units.gd`; `VT_NEARBY=1` / `0` forces it on / off natively). It reads
`data/nearby_units.json`: run `tools/nearby_units_data.gd` again after a building's footprint
changes or a minigame moves to another building
([details](docs/guides/performance/README.md#built--17-november-2026)).

`town_complete.tscn`, `town_reference.tscn` and `town_editable.tscn` are preserved
inputs to older/rebuild workflows. Do not switch Main to one of them or run a baker
as a routine edit: regeneration can overwrite authored scene overrides. See the
[architecture guide](docs/guides/ARCHITECTURE_REVIEW_PART1.md) for ownership and bake guards.

## Project layout

- `scenes/`: main/world snapshots, buildings, animals, player, vehicles and vocabulary prefabs.
- `scripts/`: core orchestration; player, interaction, learning, UI and world passes.
- `data/`: translations, categories, aliases, learning catalog and reference layout.
- `assets/`, `shaders/`: shared resources and render effects.
- `tools/`: optional generators and explicit scene bakers.
- `docs/`: indexed guides, checks and dated evidence; start at `docs/README.md`.
- `.godot/` is generated cache. Earlier versions are kept in git history, not in backup folders or ZIPs.

## Controls and learning

| Action | Control |
| --- | --- |
| Walk / turn | WASD, camera-relative. Follow camera (since 14 Nov 2026, user: easier for young players; `player_controller.gd` `follow_view()`): walking sideways (A / D or the stick) slowly turns the view that way (`follow_turn_speed`, 1.1 rad/s; 0.55 × indoors), so one hand steers; walking forward or toward the camera turns nothing; dragging the view pauses it for 2 s (`follow_pause_seconds`). On foot only. Settings → "Camera follows me" (on by default, saved) switches it off. Check (also the word card): `docs/evidence/follow-camera-word-card-20261114/verify.gd`, windowed |
| Toggle sprint / hyper speed (hyper speed [hidden](#hidden-features) since 14 Nov 2026) | Shift / H. Since 14 Nov 2026 (user) also the on-screen **Run** button, bottom right left of the jump slot, with a mouse and on touch screens: lit while running, hidden in vehicles, while seated and during minigames (`touch_controls.gd`). Walking 7.2 m/s, running 12 m/s (were 6 and 10; `player_controller.gd`). While flying the plane a red **Reset** button shows in the same corner (calls the plane's `reset_to_start()` when it has one). While driving a road vehicle (21 Nov 2026) a **Lights** button sits in the Run slot (headlights, also F) and, in the police car, ambulance and fire truck, a **Siren** button above it (siren and flashing lights, also Q) ([vehicle lights](docs/guides/ZOO_VEHICLE_IMPLEMENTATION.md#headlights-siren-and-flashing-lights--21-november-2026)). Check `docs/evidence/run-button-shop-20261114/verify.gd` |
| Jump; stronger consecutive midair jumps | Space |
| Toggle infinite (midair) jump, default off since 14 Nov 2026 (was on); off = ground jumps only | I |
| Climb a ladder / hop off it | W–S (or ↑↓) / Space |
| Orbit / zoom | Hold right mouse / wheel; since 13 Nov 2026 also drag with the left button on the world (a press still clicks; past 8 px the view turns; for trackpads) (the web build hides the cursor instead of locking it, so browsers show no "press Esc" banner; 13 Nov 2026) |
| Hospital elevator | Click cabin/landing buttons; 1/2/3 inside, E at landing |
| Study a pointed-at object | Left click or tap. Since 14 Nov 2026 (user) any click or tap, on the card or anywhere else, closes the card and does nothing else (it used to need a click on the same object or on nothing); moving, dragging the view with the mouse or looking away still close it. Since 23 Nov 2026 (user: a tap on the tiger while jumping did nothing) a card opened while walking or in the air stays open while the player keeps moving; once they stand still, the next step closes it (`interaction_controller.gd` `selected_while_moving`). The card scales with the window like the panels (720 × 340 with a 68 px word at 1100 × 800; it was a fixed 560 × 258 with a 40 px word), for phones |
| Door, nearby zoo/farm gate, board/exit vehicle, sit/stand (also on a toilet), flush a toilet (aim at its lever or push plate; a click works too), turn a faucet on/off | E, context-dependent |
| Swivel a swivel chair / swan boat pedal + steer | A–D / W–S + A–D |
| Playground swing: sit, kick in time, brake and stand | E, W–S, E |
| Accelerate / brake then reverse / steer | W / S / A–D |
| Road vehicle service brakes / recover if falling | Space / R |
| Fly the plane or helicopter (one set of controls on every device since 23 Nov 2026; [flying controls](docs/guides/aircraft.md#flying-controls)): up / down; faster / slower (helicopter forward / back); turn; let go flies level or hovers; on the runway W or up takes off | Space or on-screen ▲ / Shift, Ctrl or on-screen ▼; W–S; A–D |
| Help guide / journal / town map (the map was [hidden](#hidden-features) 14–18 Nov 2026; since 18 Nov 2026 a baked picture: tap a place, Go there starts a guide arrow, also Go there in the minigame picker; the map button sits top right, left of ▶; [guide](docs/guides/MINIGAMES.md#town-map-and-guide-arrow)); the F1 guide also has a finger-sized ✕ top right (since 14 Nov 2026, for touch). The journal's book button sits top right under the gear; the ? help button is hidden since 14 Nov 2026 (user) | F1 / J / M |
| FPS counter (Native mode, "Show everything in my language", is a checkbox in Settings) | F3 |
| See the town's signs, building names and posters in the native language while held (not saved; also the badge button, e.g. "EN", left of the gear for touch; hidden in Native mode). Since 9 Nov 2026; the old L mode cycle was removed 7 Nov 2026 | hold L |
| Minigame picker (every game, chosen rounds; a player feature since 10 Nov 2026, it was a debug-only test launcher; [guide](docs/guides/MINIGAMES.md#minigame-picker)); also the ▶ button top right, under the peek badge (bottom-right cluster until 14 Nov 2026) | F9 |
| Drop the held item, when it can be dropped (a farm egg breaks; since 24 Nov 2026; also the Drop button above Inspect, [hand hold](docs/guides/HAND_HOLD.md)) | G |
| Zone walls (off by default; remappable `toggle_zone_walls`) | B |
| Noclip; rise/descend while active | N; Space/Ctrl |
| Close the topmost window, card or minigame (its ✕); with nothing open, open Settings (Native mode checkbox, languages); release orbit | Esc |
| Close the minigame picker, F1 help, map, journal and Settings by moving (since 10 Nov 2026) | W / A / S / D / Space |
| Touch screens (since 12 Nov 2026, PWA phase 5; `scripts/ui/touch_controls.gd`, shown on a touch screen or after the first touch, hidden while the player is locked): walk, drive, steer a boat or swivel a chair / E (use) / jump, brake / hyper speed on/off (since 13 Nov 2026; lit blue while on) | joystick: floating since 13 Nov 2026, modelled on Roblox's DynamicThumbstick since 14 Nov 2026 — a finger anywhere in the left 40 % of the screen (Roblox's start area; the left half until 14 Nov 2026; not on the minimap or the dialogue box) starts it exactly there and it glides home bottom left (dimmed) when the finger lifts; since 14 Nov 2026 (later that day) the ring is smaller (0.6 × a corner button, was 0.95); since 23 Nov 2026 (user) 30 % bigger (0.78 ×) and resting higher and further right, off the corner (centre 1.74 radii from the left and 1.44 from the bottom, about 260 × 220 px on a 2000 × 1140 phone, was 1.1 and 1.1; [capture](docs/evidence/joystick-position-20261123/phone-touch.png)) and a finger past its edge pulls the stick along one radius behind, so turning round is quick (inside the ring it stays put); since 21 Nov 2026 (user) the pull stops at the screen edges, so the ring stays on screen (never pulled closer than 6 px to an edge, nor further out than where the finger landed; the start is never moved, and the knob stays inside the ring); short throw: a 6 % dead zone, full speed from 70 % of the drawn radius (the same distances as before), evenly in between, and the player walks at that share of the speed (keys are unchanged); a finger that lifts without moving (under a third of the ring's radius, at least 14 px) clicks there; only a finger on the rest of the world turns the view / round E button (centred above jump) / jump button in the bottom-right corner, 25 % bigger than the other corner buttons (both were left of the corner cluster until 14 Nov 2026, user) / lightning button above E (hidden since 14 Nov 2026: [hidden features](#hidden-features)). The dialogue box always wins (14 Nov 2026, user): a finger on it, its buttons, the quit question or the cart is never the stick's or a button's, and the E and jump buttons stand above the box if it reaches them (a button under the shop's cart card hides instead, 14 Nov 2026). The word card wins too (16 Nov 2026, user): a finger on it never starts the stick or turns the view and closes it on release, as does any finger that lands while it shows (unless the card closed meanwhile, e.g. the tutorial's `card_seconds`: then that release clicks nothing). A finger on any real HUD Button (Run, Reset, the corner buttons, the card's star and translate bubble) is the Button's, also a second finger while the first holds the stick (16 Nov 2026, user: Run did nothing then). The Run button (left of jump, also with a mouse) and the plane's red Reset are described under "Toggle sprint" above. A panel with its own way out hides the touch controls while it shows (`TOUCH_HIDE` group; the fitting room's outfit picker since 14 Nov 2026) |
| Talking (14 Nov 2026, user): while the dialogue box waits for an answer (it shows choices: Next, Yes / Not now, ...) the player stands still; keys and the stick do nothing and the touch controls hide until it closes. A line without choices (a tutorial hint, a goodbye) leaves the player free (`Main.talk_locked()`). While the box shows any line, a click or tap opens no word card (`interaction_controller.gd` `dialogue_open`), except the one object a tutorial step asks for (its `word_filter`) | — |
| Touch: look around / zoom / click (the "E" badge, an interactable, a word card) | drag one finger on the world / pinch / tap |

The F1 guide (`build_help_content` in `scripts/ui/vocabulary_hud.gd`) lists every key above
in grouped cards; since 25 Nov 2026 (improvement plan UI-04) it also has a Touch view of the
on-screen controls (opened by default on a touch device, and from Settings' **Controls** button),
scales with the window and is paged instead of scrolled
([renders](docs/evidence/f1-guide-20261125/README.md)). Its TOGGLES card shows live ON/OFF pills for sprint, hyper speed, infinite jump,
noclip, zone walls and FPS; defaults are all off (infinite jump was on until 14 Nov 2026; the hyper speed row is left out while [hidden](#hidden-features); the M row is back since 18 Nov 2026 with the baked town map). Native mode is off
by default (the player's choice is saved in `user://settings.json`, see
[Shared dialogue, popups and settings](docs/guides/ARCHITECTURE_REVIEW_PART1.md#shared-dialogue-popups-and-settings--4-november-2026)).
Since 12 Nov 2026 (PWA phase 2) the player and Main keys are InputMap actions in `project.godot`
(`move_forward/back/left/right`, `climb_up/down`, `jump`, `descend`, `sprint`, `use`, `back`,
`help`, `map`, `journal`, `peek`, `games`, `drop`, `debug_fps/noclip/hyper/infinite_jump`, plus
`toggle_zone_walls`), so touch buttons can fire the same actions; movement keys are physical
(layout-independent) as before, the others logical. Vehicles, seats, swings and minigames still
read their own keys. Mouse orbit, zoom and clicks are unchanged.
Esc goes through Main's popup stack only: a new popup must be registered in `Main.make_popups()` (a minigame panel: in `scripts/core/minigame_wiring.gd` `PANELS`). Add new keys as an action in `project.godot`, to this table and to `help_sections()`, and update the pill from
the owning script (see `set_help_state`).

Movement speeds, jump limits and camera range are exported on the player scene.
The helicopter is driveable, with inertia and collision probes; it is not a static
prop. Safe-exit checks can prevent disembarking at an unsafe position.

Picking belongs to `interaction_controller.gd`; it resolves scene metadata and
aliases, displays dictionary translations/categories, then emits `word_studied`.
Main updates progress. Main owns the shared door
registry and animation; vehicle and gate controllers own their motion.

All word data lives in one file, `data/words.json`: 635 words in 22 categories
(5 Nov 2026; each with a written rule), 13 aliases, and prefab sizes for generated learning
props. Scenes store only each object's `word_key`. Validate and re-format with
`python3 tools/word_data.py`; report usage with `tools/vocabulary_report.gd` ([vocabulary usage report](docs/guides/ARCHITECTURE_REVIEW_PART1.md#vocabulary-usage-report)). The journal (J) is a sticker book ([vocabulary journal](docs/guides/JOURNAL.md#places-tab), 25 Nov 2026): a chapter per place with every word as a sticker (a silhouette until found), a word page with the right / wrong counts per game, search and the ★ Pocket. Shared discoveries count across areas; area totals count
unique words from actual learnable objects. Learning is discovery/study plus the shop "customer order" minigame (missions were
removed 3 Nov 2026; see [customer order](docs/guides/TOWN_DESIGN_BRIEF.md#customer-order-minigame--3-november-2026)); there is
no separate quiz/scoring system implemented here.

**Startup flow (12 Nov 2026, PWA restructure phase 3).** `scenes/app.tscn` (`scripts/core/app.gd`)
is `run/main_scene`. Since 13 Nov 2026 (user: title and Play, choose a character, then the game):
title (the Bon Adventure logo and a Play button; Enter or Space) → "Pick your character": the saved characters
(up to 3 profiles; tap one to continue; under each, its language and words found) and "New player", or straight the grid of the 9 house
characters when nothing is saved → for a new character, "Choose your languages": an "I speak" row
and an "I want to learn" row of large tiles, one per playable language in `data/languages.json`
(its badge, its English name and its own name; the picked tile is green with a gold border and a
check). Picking the other side's language swaps the two, so they never match; a new character
starts with `languages.json`'s pair, English → Spanish → loading screen → town. Since 14 Nov 2026
(user: every player reads English) these screens are always in `languages.json`'s native
language, English (`Lexicon.default_native`), not in a profile's choice; a page that would not
fit the window (a small landscape phone) is rebuilt smaller.
There are no name fields: a new profile is named after its character. Since 15 Nov 2026 (user)
the title, character and loading screens show "Last update on 11-15 at 19:25" small in the
bottom-right corner: every export writes its local date and time into the pack
(`addons/web_export/build_stamp.gd` → `res://build_stamp.txt`, read by
`scripts/core/build_stamp.gd`); a run from the project shows nothing. When the town is built
the loading screen stays up ("Getting everything ready…", `app.gd` `_warm_up()`): the camera turns
once around the player so every direction is drawn (shaders compile on first draw, a stall on
the web), then it waits for 20 steady frames (under 1/24 s; at most 8 s) before play starts. The screens are `scripts/ui/app_screens.gd` (text `app.*` in
`data/phrases.json`) and `scripts/ui/loading_screen.gd`; their pictures (avatar portraits in
`assets/ui/avatars/`, loading shots and the blurred backdrop in `assets/ui/app/`) are made by
`tools/capture_app_art.gd` (except the 8 picker portraits, cut from the user's
mockup since 23 Nov 2026 by `assets/ui/avatars/source/cut_headshots.py`; vtracer traces 22 Nov) (graphics, isolated `HOME`; re-run after a plush or a shot's
surroundings change). The app instantiates the unchanged `main.tscn` with `staged_loading`
set: the units load one per frame (`modular_town.gd` `load_units(town, on_step)`) and Main
reports `loading_progress` / `town_ready` (no threads, so this works on the web build). Home
first (13 Nov 2026): a profile that will play the tutorial starts with only the home and the
supermarket, and the other buildings are added one at a time during the tutorial
([how](docs/guides/MODULAR_TOWN.md#units-added-while-the-game-runs-home-first--13-november-2026)). The
profile's avatar replaces BonBon's model (`player_controller.gd` `set_avatar()`; the node keeps
the name `Visual/BonBon`). Settings changes the native language too (since 14 Nov 2026, user; it was
shown locked from 12 Nov 2026, chosen once per profile) and has a "Switch player" button that reloads the app scene. Checks: `app_flow` (full
suite); rendered views `docs/evidence/app-flow-20261112/capture.gd`.

**Welcome tutorial (12 Nov 2026, PWA restructure phase 6).** Once the town has loaded, a profile
that has not finished it plays "Welcome to Bon Adventure": waking on the bed, BonBon's house tour and two
hiding friends (one behind the family bathtub's shower curtain), buying fruit at the
supermarket, and the word "statue" in the park, ending with the journal. It speaks the native
language; key words and the friends' greetings are in the language being learned. Skip (top
centre) ends it outside the home; Settings' "Replay the welcome tour" plays it again. Steps and
places: `data/tutorial.json`; code `scripts/learning/tutorial.gd` and `tutorial_shop.gd`
([guide](docs/guides/ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial)). Check: `tutorial` (full suite).

**Profiles and saves (12 Nov 2026, PWA restructure phase 1).** Up to 3 local profiles, listed in
`user://profiles/index.json` (`scripts/core/profile_manager.gd`: name, profile name, avatar =
a `data/npcs.json` id; ids are never reused). Each profile keeps the save files
below in `user://profiles/<id>/`; `scripts/core/save_store.gd` owns that list, the paths and the
atomic writes (temporary file + rename). With no profile the files stay directly in `user://`
(the paths named below: checks and tools, which run with an isolated `HOME`, and old installs);
the first profile created adopts copies of them and the originals stay as a backup. Main uses
the selected profile, else the last used one. `tools/bake_unit.gd` bakes with saves read-only.
Device-wide settings belong in `user://device.json`. Check: `profiles` (quick suite).
Since 18 Nov 2026 each profile also keeps its minigame levels and stars in `game_progress.json`
([progression](docs/guides/MINIGAMES.md#progression); no file means level 1 everywhere, so older saves need no migration).
Since 14 Nov 2026 (user) each profile also keeps the player's last place in `player_place.json`:
reopening a game that finished the welcome tutorial puts the player back where they stood: since
25 Nov 2026 (user) inside a building at the same spot when it is clear (else outside its
entrance; always the entrance for a place saved in a minigame), outdoors at the nearest safe
spot (vehicles are not saved; a driver stands beside where the vehicle was), else outside the
home (the supermarket until 25 Nov 2026). Saved every 10 s after moving, on quit, profile switch,
app pause, when the web page is hidden and with Settings' **Save** button (25 Nov 2026, user:
"Saved! You'll start here next time."); never without a profile (checks, tools). Details:
[saved place](docs/guides/ARCHITECTURE_REVIEW_PART1.md#saved-place-and-respawn). Check: `player_place` (full suite).

Progress is kept per foreign language as canonical-key arrays in
`user://vocabulary_progress_by_language.json` (`{"es": [...]}`); the older single array
`user://vocabulary_apartment_progress.json` is read once as the Spanish progress and left
untouched as a backup ([Stage 3](docs/guides/ARCHITECTURE_REVIEW_PART1.md#shared-dialogue-popups-and-settings--4-november-2026)).
Saved words (bookmarks) are one list for every language; they are the journal's ★ Pocket (the
book button, top right, opens the journal; 9 Nov 2026).
Old installs may still have an unused `user://vocabulary_town_quests_v21.json`; nothing reads it any more.

The project was renamed from "Vocabulary Town v0.21 - Discovery Missions" to "Vocabulary Town"
(4 Nov 2026) and to "Bon Adventure" (16 Nov 2026). Godot keys `user://` to that name on desktop, so
`scripts/core/save_migration.gd` runs first in `App._ready()` and `Main._ready()`: when the new
folder has no saves at all (no profiles, no `device.json`, no flat save files), it copies the
whole tree of the newest earlier folder that has saves, profiles included (never overwriting;
Godot's logs and shader cache stay behind; the old folder stays as a backup). In a browser
`user://` is the site's IndexedDB whatever the name, so web saves need no move; the Web preset
deletes the old `Vocabulary Town-sw-cache-*` offline cache once a `Bon Adventure` one exists. Add the
old name to `PREVIOUS_NAMES` there if the project is renamed again.
Preserve the application's existing name and alias migration to keep save compatibility.

### Web app (PWA)

Since 12 Nov 2026 (PWA restructure phase 7) the **Web** preset in `export_presets.cfg` builds an
installable web app for desktop and landscape phones and tablets (portrait is not a target; a
phone held upright shows the landscape game turned 90°, see below):
single-threaded (GitHub Pages cannot send COOP/COEP headers), `progressive_web_app/enabled`
(standalone, landscape, background `#142a38`, offline cache by Godot's service worker), Godot's
on-screen keyboard for text fields on phones, and only relative paths, so it runs from any
sub-path (`https://<user>.github.io/<repo>/`). Export:
`godot --headless --path . --export-release "Web" <folder>/index.html` (an isolated `HOME` needs
the export templates copied in), then serve the folder over HTTPS or `localhost`.
- **Hosting on GitHub Pages (user, 13 Nov 2026: one public repository; this replaces the
  separate build repository planned on 12 Nov):** repository
  <https://github.com/jameshho/bon-adventure> (public), game at
  <https://jameshho.github.io/bon-adventure/>, which since 16 Nov 2026 (user) redirects to the
  custom domain <https://boomingpodcast.com/> (Route 53 A/AAAA records and `www` CNAME point at
  Pages; `deploy_web.py` writes the `CNAME` file so a deploy keeps the domain). The source is on `main`, the exported files on
  the `gh-pages` branch, which Pages serves. `tools/deploy_web.py` exports to a folder outside the
  repository, adds `.nojekyll` and refuses files over GitHub's 100 MB limit; with `--publish` it
  makes `gh-pages` one parentless commit holding only the build (about 125 MB; old builds do not
  pile up) without touching the working tree. It never pushes:
  `git push --force origin gh-pages` after checking the build.
- **Size:** `addons/web_export/` (an export plugin, web only) saves every scene file over 256 KB
  compressed in the pck, remapped from its own path; the project files are untouched. The pck is
  86 MB instead of 169 MB (the baked town `scenes/town/base.scn`: 72 → 40 MB); `index.wasm` is
  40 MB. The plugin loads and saves each scene, which keeps instance overrides. Since 13 Nov 2026
  the preset also leaves out the 17 clay zoo animal scenes (`scenes/animals/*_clay.*`, 33 MB):
  `base.scn` stores them as plain nodes (base step `clay_animals_unpacked`), so the pck is 54 MB
  (about 48 MB sent gzipped). `deploy_web.py` refuses a build whose scenes still name one.
- **Chinese font (13 Nov 2026):** browsers give the game no system fonts, so Chinese showed as
  empty boxes on the web. `fonts/NotoSansTC-SemiBold-subset.ttf` (Noto Sans TC at weight 600,
  [SIL OFL 1.1](docs/guides/licenses/noto-sans-tc-OFL.txt), about 320 KB in the pck) holds only the
  characters in `data/`, `scripts/` and `scenes/` that Noto Sans lacks; `scripts/ui/cjk_font.gd`
  adds it as the built-in font's fallback and `fonts/NotoSans-SemiBold.ttf.import` lists it for
  the pinyin font. **After adding Chinese text, run** `python3 tools/build_cjk_font.py` (needs
  `pip install fonttools`; `--check` lists Chinese characters the subset lacks). ✕ ✗ ☾ ⌄ ❦ are
  in neither font and still need a system font.
- **Scenes stay text in exports** (`editor/export/convert_text_resources_to_binary=false`): the
  binary conversion dropped instance overrides equal to the default value, so the player's
  scale-1 BonBon came out at `BonBon.tscn`'s town scale (19.5×) and filled the screen.
- **Landscape only, turned in portrait (user, 13 Nov 2026):** iPhone home-screen apps and Safari
  ignore the manifest's landscape orientation. So on a touch device held upright, a script in the
  Web preset's `html/head_include` (in `export_presets.cfg`; no double quotes in it) reports a
  landscape window to Godot (`innerWidth`/`innerHeight` swapped, so the adaptive canvas resize
  policy sizes the canvas landscape), turns the canvas 90° with CSS (its top edge down the
  screen's right side), and in a capture listener gives every touch, mouse, pointer and wheel
  event the turned canvas's coordinates before Godot reads it (it rewrites the event's fields;
  no synthetic events). Godot and every menu, joystick and button see a normal landscape screen;
  turned sideways, the page is untouched. The first touch also asks for
  `screen.orientation.lock('landscape')`, which only some browsers allow. Desktop pages
  (no touch points) are never turned. Tried in the app's Chromium browser at 390 × 844 with touch
  emulation; not yet on a real iPhone. (A "turn your phone sideways" cover was built earlier the
  same day and replaced by this at the user's request.)
- **Icons:** `assets/ui/app/icon_<size>.png`, a pastel pig drawn as a vector in
  `tools/app_icon.svg` and rendered by `tools/make_app_icons.gd` (needs graphics; 13 Nov 2026).
  `config/icon` is the 192 px one.
- **Graphics and speed (one setting since 23 Nov 2026):** one graphics setting for every device,
  the phone-friendly one (no sun shadows, a 130 m fogged view that grows when flying high). Add
  `?perf=1` to the address (or press F3, or Settings → Show FPS) for an fps / draw-call readout
  ([setting and numbers](docs/guides/performance/README.md#one-graphics-setting-and-the-flight-view--23-november-2026)).
- **WebGL context loss (14 Nov 2026, user: "reduce + recover"):** a phone browser can drop the
  game's graphics (low memory, or the tab was in the background), and Godot then only showed
  "WebGL context lost, please reload the page". *Reduce:* on the web, Label3D font sizes share a
  few steps (`render_culling.gd` `share_label_sizes()`): GPU memory 392 → 373 MB for the full
  town; the readout (`?perf=1`) shows "GPU … MB"; what else fills it is measured in the
  [performance guide](docs/guides/performance/README.md#gpu-memory-on-the-web--14-november-2026).
  *Recover:* a second script in the Web preset's `html/head_include` catches `webglcontextlost`
  before Godot's alert, lets the game write its resume note, shows "Reloading the graphics…"
  (`app.graphics_lost`, the player's language) and reloads about a second later (once the page
  is visible again). `scripts/core/web_resume.gd` keeps the note (profile, position, heading) in
  `localStorage["bon-resume"]` (`vt-resume` before 16 Nov 2026; an old note is moved once) every 5 s while the player stands on the ground on foot, and when
  the page is hidden or closed; after such a reload `app.gd` skips the title and "Who's playing?",
  loads that profile's town and puts the player back (a profile still in the tutorial starts it
  as usual), then shows `app.graphics_back`. A note older than 30 min, or an ordinary reload,
  starts normally. Three losses within two minutes wait for a tap ("Tap to reload") instead of
  reloading again by themselves. Learner saves are unchanged: they are written at once as before. When the page is
  hidden the profile's [saved place](docs/guides/ARCHITECTURE_REVIEW_PART1.md#saved-place-and-respawn) is
  written too (14 Nov 2026), so a closed tab reopens near the same spot.
- **Restarts by the browser (25 Nov 2026, user report: on a phone the game went back to the
  title four times in 15 minutes):** a phone browser short of memory kills the page with no
  event and opens it again, so the game started at the title. In the town `web_resume.gd` sets
  `localStorage["bon-running"]` with each resume note; the Web preset's `html/head_include`
  removes it on `pagehide` (a reload, closing or leaving the page; `window.bonLeaving` stops the
  game's late note from setting it again). A page that starts with it still set was killed:
  `WebResume.take()` (once per page) records it in `localStorage["bon-restarts"]` and, with a note
  at most 5 min old, loads that profile's town at the note like a lost-graphics reload (an app
  swiped away may skip `pagehide` too, so reopening it within 5 min also resumes). The `?perf=1`
  readout shows "restarts N in 1 h" and, since the same day, "RAM": on the web the page's whole
  WebAssembly memory (kept by the preset as `window.bonWasmMemory`; it only grows), 412 MB in
  the town in the app's Chromium browser. This recovers; it does not stop the kills: the town's
  memory still grows as nearby units load (never freed; see the
  [performance guide](docs/guides/performance/README.md#gpu-memory-on-the-web--14-november-2026)).
  Tried in the app's Chromium browser (record in
  [FINAL_VERIFICATION](docs/guides/FINAL_VERIFICATION.md#web-restarts-save-button-and-home-spawn--25-november-2026)); not yet on a phone.
- **New builds reach installed apps (15 Nov 2026, user):** Godot's service worker serves the
  game from its cache, and each export has a new `CACHE_VERSION`. The browser checks the worker
  when the app opens, and the Web preset's second `html/head_include` script asks again
  (`registration.update()`) each time the app comes back to the front, because an installed app
  is often only paused. A new build installs beside the running one and waits; Godot reports it
  (`JavaScriptBridge.pwa_update_available`). Before the town is ready (title, characters,
  loading) `app.gd` switches to it at once (`JavaScriptBridge.pwa_update()` reloads the page). In
  the town `web_resume.gd` asks in the dialogue box, in the native language, once the player is
  free (no other line or card, minigame, welcome tutorial or vehicle): "A new version of Bon Adventure
  is ready…" (`app.update_ready`), Update / Not now. Update keeps the spot like a lost-graphics
  reload and starts the new build there; Not now (or ✕) is not asked again that launch, and the
  next launch uses the new build. Each update downloads the whole `index.pck` and `index.wasm`
  again (about 94 MB). GitHub Pages' cache can hide a new build for about 10 minutes after a push.
  Offline, the cached build keeps running. *Tried (15 Nov 2026)* in a separate headless Chrome
  (its own empty profile, `localhost`), replacing the served build each time: on the title
  screen the page switched to the new build by itself; in the town (after Skip tutorial) the
  question showed, the page did not reload until Update, then came back in the front yard on the
  new build with only its cache left. Not tried on a phone or an installed (home-screen) app.
- **Saves:** every save is written at once (`save_store.gd`); in a browser `user://` is the
  site's IndexedDB (`/userfs`) and Godot copies each written file there on the next frame, so
  nothing waits in memory when the tab is hidden or closed. `app.gd` asks the browser to keep
  that storage (`navigator.storage.persist()`) when a profile starts; browsers grant it mostly
  to installed or often used sites, and clearing site data still deletes the profiles.
- **Tried (12 Nov 2026)** in the app's built-in Chromium browser from a sub-path: at
  1280 × 800 (new profile with Sunny as avatar, town after about 45 s) and at 740 × 360 with
  touch emulation (profile list, town, touch controls shown); profiles survived reloads.
  **Not tried:** installing, offline play (that browser blocks service workers), a real phone
  and its on-screen keyboard. The page title and manifest name are
  "Bon Adventure: Little Town of Words" since 16 Nov 2026, written by `tools/deploy_web.py` (Godot
  would use `config/name`, the short "Bon Adventure"), with the
  manifest's `short_name` "Bon Adventure" (the label under the installed icon).

## Hidden features

Since 14 Nov 2026 (user: trimming the game for phones) these features are switched off in
[`scripts/core/features.gd`](scripts/core/features.gd). Switched off means not built and not
loaded at all; the code stays so each one can come back (set its switch to `true`) or be
deleted after review. Every place that reads a switch says `Features.` in the code, so
`rg "Features\." scripts` finds them all.

| Switch | What is gone while it is `false` | Where the code lives | Why / measured |
|---|---|---|---|
| `MINIMAP` | The minimap in the top-left corner (and tapping it to open the map); the place line and words found move up into its spot | `main.gd` `make_ui()`, `scripts/ui/town_minimap.gd`, `vocabulary_hud.gd` `minimap_side` | It rebuilt the town outline from every mesh (~0.1 s each time, several times while loading) and redrew it while the player moved: on an M-series Mac 8.4 ms → 64 ms per frame while turning (native probe, 14 Nov 2026) |
| `FULL_MAP` (**on again since 18 Nov 2026**) | While `false`: the town map (M, the map button, the F1 guide's M row). Since 18 Nov 2026 (wayfinding, user) it is `true` and the map is a picture baked by `tools/bake_town_map.gd` (`assets/maps/town_map.png`, loaded only while open, and `data/town_map.json`), not the live drawing; the map button moved to the second top-right row, left of ▶. The guide arrow is built either way | `main.gd` (`make_ui()`, the `map` action, `popups.watch`), `vocabulary_hud.gd` (map overlay, `map_button`, help rows), `scripts/ui/town_map_panel.gd`, `guide_arrow.gd` ([guide](docs/guides/MINIGAMES.md#town-map-and-guide-arrow)) | The old drawing shared the minimap's code (8.4 → 64 ms a frame while turning). The baked map measured on 18 Nov 2026: [evidence](docs/evidence/wayfinding-20261118/README.md) |
| `HYPER_SPEED` | Hyper speed: the H key, the touch lightning button, the F1 guide's H row and the blue HUD line | `player_controller.gd` (`debug_hyper`), `touch_controls.gd` (`_hyper_rect`), `vocabulary_hud.gd` (help rows) | Trim; no measurable speed effect (a flag). Development checks that set `player.hyper_enabled` directly still move fast |
| `INFINITE_JUMP_AT_START` | Infinite jump is off when a game starts (it was on); the I key still turns it on | `player_controller.gd` `infinite_jump_enabled` | User decision; no speed effect |

The runner's `building_lookup`, `map_facades` and `electrical_box` skip their map and minimap
parts while these switches are off (16 Nov 2026). Older checks that still use the map or the
minimap (expect those labels to fail while hidden):
`docs/evidence/map_upgrade/verify.gd`, `docs/evidence/world_expansion/capture_map.gd`,
`docs/evidence/ui-settings-20261104/verify_town.gd`,
`docs/evidence/minigame-launcher-20261109/verify.gd`, `docs/evidence/mahjong-20261109/play.gd` and the language
captures (`docs/evidence/language-ui-20261104`, `docs/evidence/chinese-ui-20261104`, `docs/evidence/grammar-class-20261106`).
The map phrases (`map.*`, `help.map`) are used again by the baked map since 18 Nov 2026;
`hud.map_hint`, `map.legend`, `help.hyper` and `hud.move_hyper*` stay in `data/phrases.json` unused.
The minimap (`town_minimap.gd`) is still off; the full map no longer uses it.

## Verification

From this directory, run the check runner (added 6 Nov 2026):

```sh
python3 tools/run_checks.py            # quick: resources, language, compact layout, part 2, public garden (about 35 s)
python3 tools/run_checks.py full       # everything below (about 8 min on an Apple M5, one check at a time)
python3 tools/run_checks.py --list     # suites and check ids
python3 tools/run_checks.py --only part2,aircraft
```

Each check runs as its own process with an isolated `HOME` (learner saves are never
touched; deleted afterwards unless `--keep-home`), `VT_FOCUS=all`, `VT_SPAWN=none`,
`VT_SCULPT_CACHE=0`, `--fixed-fps 60` where the check needs it, and a timeout (default
300 s, `--timeout`). Logs go to `$TMPDIR/vt-checks/<time>/` (`--out` for another scratch
folder; the runner refuses a folder inside the project). It reads each log's failure labels
(`FAIL: <label>` lines, `push_error()` messages raised from the check's own script, `ERROR:`
lines of the Python checks) and compares them with
[`data/expected_check_failures.json`](data/expected_check_failures.json):

| Result | Meaning |
| --- | --- |
| PASS | no failures |
| KNOWN | only expected failures |
| NEW | failures not in the file; their labels are printed |
| FIXED (in details) | expected labels that no longer fail: remove them from the file |
| CRASH / TIMEOUT | exited on a signal or without its summary line, or "stalled": killed 30 s after a `SCRIPT ERROR` in the check's own script left the log quiet (since 16 Nov 2026; such an error ends the check, which used to wait for the timeout) / killed after the timeout |
| SKIPPED | marked `broken` in the file (`--include-broken` runs it) |

The exit code is 1 only for NEW, CRASH or TIMEOUT. `--jobs 2` runs two checks at once
(faster; physics timing then shares the CPU, so prefer the default for a record).

`full` = `quick` plus interaction, aircraft, helicopter, zoo vehicles, road physics,
hospital remodel and departments, the hospital elevator call buttons (`elevator_call_button`, 9 Nov 2026), seats and swan boats, both vocabulary Python checks,
park terrain, barn, police detective / interior / officer, map facades, vehicle boarding
and doors, the building address book (`check_building_lookup.gd`), the two warehouse checks, the Grammar Classroom check, the airport flight game logic (`flight_logic`, 7 Nov 2026), the vocabulary report's unknown-key check (`vocabulary_report`), world signs in every language (`signs`, 9 Nov 2026), building access
(`check_building_access.gd`: door registry, approved school/supermarket dimensions, entrance
walk paths, school and market word picks; it replaced the six October snapshot checks on
7 Nov 2026), and `check_rooftops` (reworked 7 Nov 2026; it used to hang). Not included on purpose: `check_animals.gd`
(writes `docs/evidence/animals-review/measurements.json`), capture and render scripts (overwrite
PNGs).

- **Add a check:** inspect it for file writes first; then add one row to `CHECKS` in
  `tools/run_checks.py` (id, script, suite, `fps`, a `summary` regex whose group `n` is the
  failure count, optional label `prefix` to strip and `timeout`). Run it alone with `--only`.
- **Update expected failures:** only for a failure that is understood or recorded in the
  [verification record](docs/guides/FINAL_VERIFICATION.md): add `{"label"|"prefix"|"regex": ...,
  "count": n, "reason": ..., "since": "YYYY-MM-DD"}` under the check's id (`"any": true` with
  a count for checks whose records give only a number; `"flaky": true` for random ones).
  Remove entries the runner reports as FIXED. Never add an entry just to make a run pass.

To run one check by hand, use the same environment: `HOME=<scratch>/home VT_FOCUS=all
VT_SPAWN=none godot --headless --path . [--fixed-fps 60] --script res://docs/evidence/<folder>/<check>.gd`.
Without an isolated `HOME`, checks that instantiate Main can write study progress into the
learner's saves.

Headless runs have a 64 × 64 root viewport that cannot be resized (traced 9 Nov 2026): UI
scaled from the window clamps to its minimum, and clicks pushed at real screen positions fall
outside it and are dropped. Check real clicks and on-screen fit with graphics only
(`DisplayServer.get_name() == "headless"`), as `vocabulary-book-20261108/verify.gd` does.

Graphical views: `godot --path . --resolution 1200x900 --script res://docs/evidence/part2/capture.gd`.
This overwrites the six Part 2 preview PNGs. Some historical tests also write their
own result files. Inspect side effects first.

Windowed `--script` runs end with a hard exit (13 Nov 2026): on macOS, Godot 4.7.2 aborted
while quitting after every windowed town run (a `recursive_mutex::lock` throw inside
`-[NSApplication terminate:]`), which left a "Godot quit unexpectedly" dialog and a crash
report each time. The autoload `scripts/core/script_run_exit.gd` now kills the process as the
tree closes, so these runs exit with **137** instead of their `quit()` code, and a
SceneTree script's `_finalize()` does not run. Anything printed or saved before `quit()` is
kept. Read the log's labels, not the exit status. Headless runs (including `tools/run_checks.py`) and the game itself are
unaffected. `VT_SOFT_EXIT=1` turns the hard exit off (for example to reproduce the abort).

The [verification record](docs/guides/FINAL_VERIFICATION.md)
distinguishes current passes, existing failures and checks not performed.

### Hospital surface and stair repair — 26 October 2026

The user authorized replacing the cramped switchbacks and repairing interior/exterior
surfaces. The implemented straight stairs have front and rear approaches on every
floor. See the [current hospital guide](docs/guides/HOSPITAL_THREE_FLOORS.md) for dimensions, facade ownership,
normal-control tests and screenshots. This supersedes earlier switchback guidance.

Zone layout inspection (Stage 1 only): [zone inventory, rationale, editing and review edges](docs/guides/ARCHITECTURE_REVIEW_PART1.md#zone-boundaries--stage-1-inspection-28-october-2026).

Journal organization: [categories, area indexing, overrides and verification](docs/guides/ARCHITECTURE_REVIEW_PART1.md#category-and-area-journal--stage-2-28-october-2026).

Chair/bench sitting: **E** to sit or stand; [animation, authoring and checks](docs/guides/BONBON_VALIDATION.md#sitting-on-chairs-and-benches--28-october-2026).
Playground swings: **E** to sit, **W** / **S** in time to swing higher, **E** to get off ([controls](docs/guides/TOWN_DESIGN_BRIEF.md#playground-rebuild-and-rideable-swings--1-november-2026)).
