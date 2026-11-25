# Passport: missions, town stamps and the achievement log

Built 21 November 2026 (user request, from the user's passport mockup in chat). The mockup gave
the **content**; the look is the game's own ([UI art style](UI_STYLE.md), user: "match the existing
design"). This page is the developer reference: what exists, where it lives, how to add to it.
Player-facing summary: [game guide](../game/playing.md#passport-missions-stamps-and-achievements).

## Decisions (user, 21 Nov 2026)

| Topic | Decision | Status |
| --- | --- | --- |
| Missions | Three at a time, each points at one minigame in character-driven words ("Help Officer Rocco catch a suspect!") | Built |
| New player | Spot the Suspect, Library Helper, Desk Dash | Built |
| After a mission | Its card turns grey with a check and "A new mission in 9:59", counting down; 10 real minutes later a new one fills the slot | Built |
| Daily reset | The mockup's "Resets in 14 h" was **not** adopted: the 10-minute rule replaces it (assumed; the question went unanswered) | Built as assumed |
| Optional | Any order, or none; every game still plays from its NPC and the ▶ picker | Built |
| Rewards | Each mission rewards on its own (XP); nothing for finishing all three | Built |
| Rotation | Prefer games not played recently; sometimes a familiar favourite | Built |
| Go there | Puts a waypoint: the existing guide arrow to the game | Built |
| Map | A gold star on the town map for each active mission | Built |
| XP | A total shown only in the Passport (assumed; the question went unanswered) | Built as assumed |
| Town stamps | A floating coin "in some corner of each building, like an achievement". **Component first, for the user's review; the user then says where each goes** | Coin **approved** (21 Nov 2026, pig face); **18 placed** at the user's spots the same day ([list](#where-the-coins-are)) |
| Exploration | A log of every activity: all missions, all minigames, the small interactions, flying the plane and the helicopter, with tracking | Built (13 activities) |

## Files

| What | File |
| --- | --- |
| The tracker: events, achievements, XP, the log | `scripts/learning/achievements.gd` |
| What can be achieved, and the stamp list | `data/achievements.json` |
| Where the town's activities are reported | `scripts/learning/achievement_hooks.gd` (and one-line calls, [below](#where-events-are-reported)) |
| Missions: slots, rotation, completion | `scripts/learning/missions.gd` |
| The Passport window and its corner button | `scripts/ui/passport_panel.gd` |
| The stamp coin | `scripts/world/stamp_coin.gd`, `scenes/props/stamp_coin.tscn` |
| Placing the coins in the town (from `stamps[*].at`) | `scripts/world/stamp_places.gd` (installed by `main.gd`) |
| The coin's face (both sides) | `assets/stamps/coin_face.svg`, built by `assets/stamps/source/build_coin_face.py` from the traced pig (`source/pig_head_traced.svg`, `source/trace_pig.py`) and the user's picture `source/coin_face_reference.webp` ([how](#the-coin-face)) |
| Mission stars on the map | `scripts/ui/town_map_panel.gd` (`draw_star()`) |
| Text (all three languages) | `data/phrases.json` groups `passport`, `missions`, `missions_desc`, `achievements`, `achievements_hint` |
| Saves (per profile) | `achievements.json`, `missions.json` (`scripts/core/save_store.gd` PROFILE_FILES) |
| Checks | `docs/evidence/stamp-coin-20261121/verify.gd`, `docs/evidence/passport-missions-20261121/verify.gd`, `docs/evidence/stamp-places-20261121/verify.gd`, `docs/evidence/stamps-page-20261122/verify.gd` |

## Events and achievements

The model has two layers, so new achievements rarely need code:

- An **event** is something that happened, reported with one line:
  `Achievements.shared().note("fly_plane")`. Every event is counted
  (`events[event] = {count, first, last}`, unix seconds), even with no achievement on it yet.
- An **achievement** (`data/achievements.json` `achievements`) unlocks the first time its event
  (`"event"`, default its own id) has happened `"times"` times (default 1). Several can share an
  event: `mission_1`, `mission_5`, `mission_20` all count `mission`. On unlock it adds its `"xp"`
  once and emits `unlocked(id, def)`; `achievement_hooks.gd` turns that into the HUD toast
  ("Achievement: Take a seat +5 XP").
- **Generated, not listed**: `game.<activity id>` for every activity of `data/activities.json`
  (event: a session of that game finished with its target reached, from the board's `ended`
  signal) and `stamp.<id>` for every entry of `stamps`. A new minigame therefore appears in the
  log by itself.
- Groups (the Exploration page's tabs): `explore` (Things to do), `games`, `missions`; `stamps`
  has its own page.

### The log

`achievements.json` keeps `log`: the newest last, at most 300 lines, each
`{"at", "kind", "id", "xp"?}`. Logged: every unlock (`kind: unlock`), every finished minigame
and mission (`kind: event`, ids starting `game.` or `mission`), every XP gain (`kind: xp`, id
= the achievement or `mission.<game>`). Repeats of small events (sitting down again) are only
counted, not logged, to keep the log readable. The Passport's **Diary** tab shows the newest 9.
For debugging, read the file in the profile folder (`user://profiles/<id>/achievements.json`).

### Where events are reported

| Event | Reported by |
| --- | --- |
| `sit_down`, `lie_down`, `swing` | `achievement_hooks.gd tick()` from the player's `seated` / `lying` and `seating.current_swing()` |
| `drive_car`, `fly_plane`, `fly_helicopter` | `tick()`: the active vehicle; the plane when its `landed` is false, the helicopter 3 m above its start pose |
| `pick_up` | `install()`: the hand's `picked_up` signal (`hand_hold.gd`) |
| `open_door` | `door_animator.gd toggle()` (opening only) |
| `use_faucet` | `faucet.gd use()` (turning on) |
| `flush_toilet` | `flush_control.gd use()` (a flush started) |
| `save_word` | `vocabulary_hud.gd toggle_bookmark()` (saving, not unsaving) |
| `open_map` | `town_map_panel.gd open()` |
| `follow_guide` | `guide_arrow.gd` on arrival |
| `game.<id>` | `achievements.gd` from `activity_board.gd ended` (completed; since 21 Nov 2026 also Grocery Run, Library Helper and Desk Dash, which never completed before: [why](MINIGAMES.md#results-screen)) |
| `mission` | `missions.gd complete()` |
| `stamp.<id>` | `stamp_coin.gd collect()` |
| `ring_bell` | `chapel_bell.gd ring()` (the chapel's tower bell, 21 Nov 2026) |
| `farm_egg`, `golden_egg` | `hen_house.gd deliver()`: an egg (a golden one) put in the barn's egg crate (24 Nov 2026; no achievement or reward yet, counted for later stars: [record](TOWN_DESIGN_BRIEF.md#hen-house-and-eggs--24-november-2026)) |

`tick()` runs four times a second from `main.gd` (with `VehicleControls.update_home`) and notes
a state only when it turns on, so sitting for a minute counts once.

### Adding an activity

1. Add it to `data/achievements.json` `achievements` (`group`, `icon` from `ui_icons.gd`, `xp`).
2. Add its name and how-to to `phrases.json` `achievements.<id>` and `achievements_hint.<id>`
   (`es`, `en`, `zh`).
3. Report it: one `note("<id>")` where it happens, or a state in `achievement_hooks.gd tick()`.
4. The Exploration page shows it at once; check the page still fits (3 columns; about 15 per
   tab before it needs a new tab).

Counting starts when the line is added: old saves do not get credit for earlier play.

## Missions

`missions.gd`, saved as `{"slots": [{"game", "since", "done_at"}]}` (`done_at` 0 = active).

- Done when the slot's game **finishes with its target reached**, by any route (its NPC or the ▶
  picker), from the board's `ended` signal. Rewards: `mission_xp` of the activity in
  `data/activities.json` (default 30) through `achievements.add_xp()`, and the `mission` event.
  The first finish of a game also unlocks `game.<id>` (+10 XP), shown on the card as "First time!".
- 600 s of real time after `done_at`, `refresh()` (called when the Passport opens and every second
  while it is open) rolls a new game: a learning game (pastimes never) not in another slot and
  not the one just done; 75 % of the time among the three finished least recently (never played
  first), 25 % among the three most played.
- Go there: `guide_arrow.gd go_to_game(id)` (the NPC, or the game's map spot until its building
  is loaded).
- New mission text: `phrases.json` `missions.<game id>` (said as the NPC's request) and
  `missions_desc.<game id>` (what to do, and where). The check fails if a learning game has none.

## Town stamps

`stamp_coin.gd`: a gold coin (radius 0.45 m since 22 Nov 2026, user: "50% bigger"; was 0.3; a gold edge) with the pig face on both sides,
spinning slowly and bobbing at chest height. Walking into it (an `Area3D`, 0.85 m, the player
group) collects it: `note("stamp.<id>")` (+15 XP, toast "Town stamp found: Library (3/21)"), a
spin-up, rise and shrink, gold sparks (`success_burst.gd`), then it frees itself. A collected
stamp's coin never shows again for that profile. Cost: it animates only while on screen
(`VisibleOnScreenNotifier3D`); built in code, no model files.

- **Placement is data, not baked.** `stamp_places.gd` reads each `stamps` entry with a `unit` and
  an `at` (town coordinates, the coin's centre) and, when that unit loads
  (`main.when_unit_loaded`), adds `StampCoin.make(id)` there. Optional fields: `parent` (a node
  path under the town whose transform the coin follows, e.g. the control tower's elevator car),
  `gate` (a node path: the coin cannot be collected until that node has turned more than 0.5 rad,
  e.g. the bank safe's door), `face` (a town point the coin looks at; it then stands still: the
  bank safe is too shallow for the 0.9 m coin to spin), `reach` (pickup radius) and `where` (a
  note for developers). Coins
  without a `parent` go under one Apartment node, `StampCoins`, never under a unit root (a coin
  there skewed the unit bounds of `data/nearby_units.json`). A bake (`bake_world_only`) never
  installs coins.
- An entry with `"at": null` is **not placed and not listed** on the Stamps page.
- To move or add one: edit its `at` (no bake needed), then run the check below, which finds a
  real standing spot within reach, line of sight and no overlap with props.
- `preview = true` shows a coin that cannot be collected and never hides (review renders only).

### Where the coins are

User's list, 21 Nov 2026; pictures `docs/evidence/stamp-places-20261121/coin-<id>.png`.

| Stamp | Spot | Building change made for it |
| --- | --- | --- |
| home | corner of the study | |
| supermarket | the back storage room | storage room fitted out (racks, boxes, pallets, hand truck, lights) and the staff door made a working shared door ([record](TOWN_DESIGN_BRIEF.md#stamp-places-storage-room-bank-safe-grand-chapel--21-november-2026)) |
| library | a corner | |
| bank | behind the safe: a steel drum behind the vault's round door; the coin stands still facing out (22 Nov) | the round door swings open on use after its wheel turns (gate on the coin) |
| police_station | corner of the suspect ID room | |
| taqueria | corner of the kitchen | |
| airport | inside the men's bathroom | |
| control_tower | inside the elevator (rides with the car) | |
| farm_barn | second floor (hayloft), inside | |
| hospital | corner of the roof | |
| sports_store, clothing_store, electronics_store | a corner | |
| furniture_store | corner of the bedroom section | |
| bakery_cafe | corner in the back | |
| chapel | the belfry, beside the bell | chapel enlarged, a ground-standing bell tower with a climbable ladder and a ringable bell (ladder moved inside the tower 23 Nov 2026) |
| playground | top of the slide | |
| mystery_house | behind Madame Luna | |

Not placed (not in the user's list): restaurants (Alta Cocina), warehouse, school.

22 Nov 2026: with the coin 50 % bigger, four spots moved a little to stay clear of props
(library +0.12, farm barn 0.6, furniture store +0.12, electronics store 0.84 units along the
counter) and the bank coin rose to the drum's middle.
- `emblem`: `"pig"` (default, the face below); `"star"` or a `ui_icons.gd` name gives the first
  design (plain gold, raised rim, an emblem, a soft glow sprite), kept for other uses.

### The coin face

User, 21 Nov 2026: their picture of a gold coin with BonBon's head is the face; "use vtracer on the
pig head", the rest designed to fit the game; then no white accents, head centred. Views: `docs/evidence/stamp-coin-20261121/town-coin-*.png`.

1. `assets/stamps/source/trace_pig.py` crops the head from `coin_face_reference.webp`, clears the
   gold around it, maps every pixel to five flat colours (face, pink for cheeks / ears / snout,
   outline, eyes and nostrils; thin dark streaks of the snout ring become outline), smooths the
   borders and traces it with **vtracer** (colour, spline) into `source/pig_head_traced.svg`
   (27 shapes, 40 KB). vtracer's Python wheel crashed on Homebrew Python 3.15; it works in a
   venv of the system Python 3.9: `/usr/bin/python3 -m venv <dir> && <dir>/bin/pip install vtracer pillow`.
2. `assets/stamps/source/build_coin_face.py` (plain Python) writes `assets/stamps/coin_face.svg`
   (512 × 512): a gold disc with a light outer band and groove, a warm inner face and the pig in
   the centre. (The first version also had a gloss, cream sparkle marks, sprigs and a star from the
   picture; the user had them removed and the head centred the same day.)
3. Godot imports `coin_face.svg` (mipmaps on). The coin's faces are quads with it as albedo
   (alpha scissor), little shine (metallic 0.05, roughness 0.55) and a faint emission; no glow
   sprite, which washed the face out under the town's light.

`assets/stamps/source/` has a `.gdignore`: the picture, the trace and the scripts are not imported
or exported.

## The Passport window

`passport_panel.gd`: the corner button (a booklet, top-right second row left of the map,
`top_slot(3)`; hidden in minigames, the welcome tutorial and behind full-screen windows), Esc and ✕
close it (minigame_wiring.gd PANELS; it locks the player while open). Three pages, all fitting a
1280 × 800 window without scroll bars: **Missions**, **Town stamps** (22 Nov 2026: a progress strip with
"n / total" and a gold bar, then a 6 × 3 grid; a found stamp shows the real coin face,
`coin_face.svg`, on a cream card with a gold rim; one not found yet a faded coin with "?" and the
place name in muted letters; [picture](../evidence/stamps-page-20261122/stamps-1280x800.png)), **Exploration** (tabs Things to do / Games / Missions with "n/total", and Diary).
Header: title and total XP. Built with BonStyle (`flat()`, `flat_button()`, `button()`), sized by
min(h / 800, w / 1100), every button at least 52 px.

## Open items

| Priority | Item |
| --- | --- |
| Done | Stamp coins placed (21 Nov 2026, 18 of 21; check 132 checks, 0 failures) |
| Done | 22 Nov 2026: collecting a coin printed `_mover_box: Trying to assign invalid previously freed instance`: `indoor_visibility.gd` lists animating nodes (the coin) as movers and assigned the freed coin to a typed variable; it now checks the node is valid first |
| P2 | Restaurants (Alta Cocina), warehouse and school have no coin: ask the user for spots or drop them |
| P2 | The chapel bell is silent: its `rung` signal is ready for a sound cue in `data/sounds.json` |
| P2 | No keyboard shortcut for the Passport (the button only); a key needs a new input action |
| P2 | XP has no use yet (no levels or rewards to spend it on) |
| P3 | Mission stars on the map can overlap a place's name pill (the School star) |
| P3 | Not tested on a real phone or the web export |
