# Improvement plan: task tracker

Statuses: Pending · Ready · In Progress · Blocked · Under Review · Testing · Completed · Deferred.

- **Ready** means the task has no unmet dependency and no open user decision. It still needs the user's go-ahead on the [master plan](MASTER_PLAN.md).
- **Blocked** names its blocker.

Owners:

| Owner | Area |
| --- | --- |
| A1 | Performance |
| A2 | Graphics |
| A3 | Animation |
| A4 | Gameplay |
| A5 | UI/UX |
| A6 | Learning |
| A7 | Architecture |
| A8 | Coordinator/QA |

Evidence:

| Tag | Meaning |
| --- | --- |
| **C** | Confirmed in code or a recorded measurement |
| **S** | Speculative |

Line numbers are from the audit at `11fc0121`. Re-check them before editing.

The common rollback for every task is to revert that milestone's single commit. Saves are only ever changed additively, so an older build still reads them.

## P0: data-loss risks

### ARCH-01 Checked temp writes (A7, C, status: Completed 25 Nov, `1505f82a`)
- **Objective:** a failed or short write never replaces a good save.
- **Files:** `scripts/core/save_store.gd` (`write_text`, around line 70).
- **Plan:**
  - Check `store_string()`'s result and `file.get_error()` before `close()`.
  - On failure, remove the `.tmp`, `push_warning` and return false without renaming.
- **Acceptance:** with a write that fails, the original file is byte-identical afterwards.
- **Tests:**
  - New `docs/evidence/save-robustness-<date>/verify.gd` (isolated `user://` per the README test configuration).
  - `profiles` and `player_place` checks.
- **Dependencies:** none.
- **Rollback:** revert.

### ARCH-02 Back up unparseable saves (A7, C/S trigger, status: Completed 25 Nov, `1505f82a`)
- **Objective:** a corrupt file is kept for recovery instead of being silently replaced with defaults on the next save.
- **Files:**
  - `scripts/core/save_store.gd` (`read_json`).
  - Callers stay unchanged.
  - `scripts/learning/vocabulary_progress.gd` (`save_studied_words` re-reads the file and must not drop other languages).
- **Plan:**
  - When the file exists but does not parse to a Dictionary or Array, copy it to `<file>.corrupt-<unix>` once and `push_warning`.
  - Optionally keep `<file>.bak` on each successful write and fall back to it. This is decided in the task.
- **Acceptance:** garbage written into `word_memory.json` and `settings.json` gives a backup file, and the game still starts.
- **Tests:** the save-robustness check, `practice_log`, `minigame_progression`.
- **Dependencies:** none.

### ARCH-03 Profile-index recovery (A7, C/S trigger, status: Completed 25 Nov, `1505f82a`)
- **Objective:** a broken or lost `profiles/index.json` never reuses `p1` and never copies the flat legacy saves over an existing profile folder.
- **Files:** `scripts/core/profile_manager.gd` (`load_index`, `create`, `has_legacy_saves`).
- **Plan:**
  - On a parse failure, back the file up and rebuild the profile list from the `user://profiles/p*` folders.
  - Set `next` above every existing folder.
  - Adopt legacy saves only into a folder that does not exist yet.
- **Acceptance:** a corrupt index leaves p1–p3 listed and their files unchanged.
- **Tests:** extend `docs/evidence/profiles-20261112/verify.gd`; `app_flow`.
- **Dependencies:** ARCH-02 (the backup helper).

## P1

### ARCH-04 Keep unknown studied-word keys (A7, C, Completed 25 Nov, `1505f82a`)
- **Objective:** a word that leaves `words.json`, or is renamed without an alias, no longer deletes progress from every profile.
- **Files:** `scripts/learning/vocabulary_progress.gd` (lines 18, 47), `scripts/core/main.gd:181` (read only).
- **Plan:**
  - Filter only in memory; save unknown keys back unchanged.
  - Do the same for bookmarks.
  - Progress counts use the filtered set.
- **Acceptance:** an unknown key survives load→save, and the journal count ignores it.
- **Tests:** `vocabulary_book`, `practice_log`, the save-robustness check.

### ARCH-05 Reset SessionWords on a profile switch (A7, C, Completed 25 Nov, `1505f82a`)
- **Objective:** the second player's results card lists their words. Today it stays connected to the freed PracticeLog of the first player.
- **Files:** `scripts/core/profile_manager.gd` (`reset_singletons`, lines 170–180); comment in `save_store.gd` `PROFILE_FILES`.
- **Plan:**
  - Add `session_words.gd` to `reset_singletons`.
  - Check `star_card.gd:46` (`Progress.shared()` connection) in the same pass.
  - Add a comment telling future singletons to register in the reset.
- **Acceptance:** after a switch, record one question and `SessionWords.summary()` is not empty.
- **Tests:** `results_screen`; a switch-profile step in `app_flow`.

### QA-00 / C0 Runner judges by the summary when Godot aborts on exit (A8, C, Completed 25 Nov, `cd9a6d62`)
- `tools/run_checks.py`: a SIGABRT after the summary line (`recursive_mutex lock failed`, Godot 4.7.2 on this Mac since 25 Nov) is judged by the summary and noted. Verified by re-judging the 25 Nov suite logs (CRASH 55 → PASS 53, KNOWN 2, NEW 10).

### QA-01 Register unregistered checks + save check (A8, C, Completed 25 Nov, `83433a41`)
- **Objective:** regressions in persisted learner data get caught.
- **Files:** `tools/run_checks.py` (CHECKS); new save-robustness verify (written in M1).
- **Plan:** register these checks:
  - `passport-missions-20261121`
  - `word-memory-20261124` (quick suite)
  - `sound-ui-20261124`
  - `voice-backbone-20261124`
  - `restaurant-retry-20261124`
- **Acceptance:** each runs once from the runner; results go in TEST_RESULTS.
- **Notes:** each new registration needs one run to set its baseline. Ask the user first.

### PERF-01 Repeatable performance probe + phone procedure (A1, C gap, Completed on desktop 25 Nov, `cd9a6d62`; web and phone runs not done)
- **Objective:** a baseline that every later change can be compared against.
- **Files:**
  - New `docs/evidence/perf-baseline-<date>/probe.gd` writing to `user://`. It never writes into the repo, unlike the old `benchmark.gd`.
  - A README section for the phone procedure (`?perf=1` at fixed spots).
- **Plan:** fixed views with draws, triangles, video MB, p50/p95 frame time and load time:
  - street at spawn
  - bedroom
  - mahjong yard
  - zoo look-back
  - flight at 40 and 100 m
- **Acceptance:** numbers are recorded in [PERFORMANCE_BASELINE.md](PERFORMANCE_BASELINE.md) with conditions. The phone numbers are taken by the user on their device.
- **Dependencies:** M0 known revision; `dev_focus.txt` = `all`.

### PERF-02 Drop unused static clay meshes from the web pack (A1, C, Completed 25 Nov, `5525310a`: 91.4 → 65.5 MB)
- **Result (25 Nov):** 20 static folders excluded (sheep kept); `deploy_web.py` now refuses a build whose scenes name anything the preset excludes (tested by pretending `hen/` is excluded: base.scn caught). Web export: `index.pck` **91.4 → 65.5 MB**; the build loads in the browser with no missing-file errors and the zoo animals drawn. Waiting for the user's commit approval.
- **Objective:** `index.pck` 91 → about 64 MB (−27 MB), well under GitHub's 100 MB file limit.
- **Files:** `export_presets.cfg` (`exclude_filter`), `tools/deploy_web.py` (`excluded_references` must refuse a build whose exported scenes name an excluded mesh).
- **Evidence (coordinator check):**
  - `base.scn` names `zebra_rig/`, `hen/`, `rooster/`, `chick/` and `monkey/`. No exported scene names static `zebra/`.
  - Keep `hen`, `rooster`, `chick` and `monkey`.
  - `sheep` is uncommitted work and may be placed soon, so leave it out of the filter until decided.
- **Plan:** verify every static folder with a byte search of all `scenes/town/*.scn` and building scenes before adding it.
- **Acceptance:** the export prints a smaller pck, and the zoo and farm animals all appear in the web build.
- **Tests:** one web export; zoo and farm in the browser.

### PERF-03 Web sculpt cache (A1, C, Pending: M0 baseline)
- **Objective:** stop re-sculpting plushes on every web launch and building load. Restaurants take 1,258 ms without the cache and 109 ms with it.
- **Files:** `scripts/characters/sculpt_cache.gd`, `addons/web_export/*` (script-hash manifest), possibly `plush_sculpt.gd`.
- **Risk:** medium (cache-key correctness, browser storage quota).
- **Acceptance:** a warm web launch loads a building without the hitch.
- **Tests:** web timing cold and warm; `app_flow`.

### PERF-04 Voice clips per language (A1, C, Ready: D7 per-language packs, 25 Nov)
- **Objective:** download only the voice languages in use. Today all 3 are about 30 MB.
- **Files:** `scripts/core/sound.gd`, export/pack step, `docs/guides/VOICE.md`.
- **Risk:** medium (offline PWA cache, language switch).
- **Tests:** offline, Safari, language switch.

### LEARN-01 New-word gating counts the current pool only (A6, C, Completed 25 Nov, `0bf1851f`; `dfd2be4c` stops word-less rounds starving word questions)
- **Objective:** existing profiles with 12 or more logged words get new words again.
- **Files:** `scripts/learning/word_memory.gd` (`learning_count`, around lines 120–125; seeding, lines 79–90).
- **Plan:**
  - Count "being learned" within the game's pool, or among recently reviewed words, and ignore keys missing from the lexicon.
  - Seed well-known words with stability at or above `LEARNED_STABILITY`. This only affects languages not yet seeded.
- **Acceptance:** a simulated learner moving between two games is offered new words in both.
- **Tests:** `word-memory-20261124/verify.gd` plus the new simulation case.
- **Dependencies:** best after ARCH-05 (same results flow); no file overlap.

### GAME-01 Library Helper can be left (A4, C, Completed 25 Nov, `aec3ae2a`)
- **Objective:** walking away from or leaving the library ends or asks to end the game, so the HUD, word cards and other games come back.
- **Files:**
  - `scripts/learning/library_session.gd`
  - `data/phrases.json` (`library.leave_*`, es/en/zh)
  - `scripts/core/minigame_wiring.gd` if a panel entry is needed
- **Plan:** reuse the host's `ask_leave` and the walk-away pattern from `minigame_host` / `zoo_feeding_session`. Do not write new leave code.
- **Acceptance:** leaving mid-game asks; "yes" restores the HUD; "stay" puts the player back.
- **Tests:** the library check; one render.

### UI-01 `BonStyle.factor()` (A5, C, Completed 25 Nov: the code is in `65385841`, not `aa99be5f`; see [SESSION_HANDOFF](SESSION_HANDOFF.md#commit-history-note-25-nov-2026-user-leave-it))
- **Objective:** one scale formula instead of about 17 copies with different floors. There is no visual change: each caller keeps its floor as a parameter.
- **Files:** `scripts/ui/bon_style.gd` plus the copies listed in the UI audit:
  - `day_clock`, `game_launcher`, `passport_panel`, `results_screen`, `town_map_panel`, `star_card`, `town_minimap`, `vocabulary_hud`
  - `instruction_strip`, `loading_screen`, `tap_hint`, `tutorial_cue`, `tutorial.gd`, `app_screens`, `interact_badge`
- **Plan:**
  1. Proof of concept on 3 files.
  2. Then the rest.
- **Acceptance:** screenshots at 1280×800 and 844×390 are identical before and after.

### UI-02 Touch-size floor on phones (A5, C arithmetic / S real device, Pending: the user's phone check per D5; the 844 × 390 render and sizes are done, [evidence](../../evidence/ui-scale-20261125/README.md#d5-phone-render-at-844--390-no-floor-added))
- **Objective:** buttons and rows are never below a finger size (about 44 px) on a landscape phone. With no stretch mode, `min(h/800, w/1100)` gives 0.5 at 844×390.
- **Files:** `bon_style.gd`, then panels one by one: `vocabulary_hud`, `vocabulary_book`, `settings_panel`, `results_screen`, `app_screens` …
- **Plan:**
  - A separate target factor, floored on touch. Mahjong's height lerp (`mahjong_panel.gd:835`) is the model.
  - Compact phone layouts where cards overflow.
- **Acceptance:**
  - Phone screenshots show targets of at least 44 px and no overflow.
  - Laptop screenshots are unchanged.
  - First confirm the size on a real phone, because the browser's pixel ratio decides the window size.

### UI-03 Journal drag-to-scroll (A5, C, Completed 25 Nov, `5ce06b9e`)
- **Note (25 Nov 2026):** the user approved a [journal redesign](../JOURNAL.md) with paged stickers and no scrolling list. Skip this task if that is built first.
- **Files:** `scripts/ui/vocabulary_book.gd` (`_on_list_input`, around lines 939–947).
- **Plan:** a drag on the rows moves `scroll.value`, with a tap slop as in `touch_controls`. Taps on the star and speaker still work.
- **Acceptance:** dragging scrolls, a tap opens the row, the wheel still works.
- **Tests:** a touch-emulated run; screenshots.

### ANIM-01 Interpolation-safe movers (A3, C/S, Completed 25 Nov: animals `e24d9cea`, hop/gestures/swing `c4c7c7ea` + `65385841`)
- **Objective:** no stutter from nodes moved in `_process` while physics interpolation is on.
- **Files:**
  - `scripts/world/park_animals.gd` (around lines 327–360)
  - `scripts/learning/npc_presence.gd` (63–74)
  - `scripts/characters/plush_life.gd` (gesture tweens)
  - `scripts/world/driveable_vehicle.gd` (rotors, around line 653)
  - `scripts/player/hand_hold.gd` (combine with ANIM-05)
- **Plan:** per mover, either `physics_interpolation_mode = OFF` or physics-process tweens and steps. Check `clay_animator` speed sampling.
- **Acceptance:** a frame-time sweep at 60/120 Hz shows smooth motion, and the zoo and NPC renders are unchanged.

### ANIM-02 Animals turn before they walk; ease in and out (A3, C, Completed 25 Nov, `e24d9cea`)
- **Files:** `scripts/world/park_animals.gd` (around lines 241 and 349–360). Check whether exported defaults are saved in `base.scn` (a bake may be needed).
- **Plan:**
  - Speed is multiplied by `clamp(cos(heading_error),0,1)`.
  - `move_toward` acceleration reaches full speed in about 0.25 s.
  - Use `1-exp(-k*dt)` smoothing (the P3 item).
- **Acceptance:** a render sequence shows no crab-walk; the part2 animal check and `zoo_vehicles` pass.
- **Conflict:** PERF items in `park_animals.gd` wait until this is done (see [ownership](FILE_OWNERSHIP.md)).

### GFX-01 Contact shadows (A2, C, Deferred: built 25 Nov, then removed uncommitted at the user's request after a zoo play-test, D6 reversed)
- **Objective:** characters, animals and props stop floating. Sun shadows stay off.
- **Files:**
  - One new shared material/shader in `materials/`
  - Attached through existing scenes: the player, `plush_sculpt.gd`, clay scenes, vehicles
  - `render_culling.gd` (ranges)
  - Read COMPONENTS.md first
- **Plan:**
  1. Proof of concept on BonBon and one animal.
  2. Measure draws against M0.
  3. Then roll out.
- **Acceptance:** the user approves the look; the draw and frame-time increase is recorded and accepted.

## P2

Owner, evidence and status are given for each. Each task is specified fully only when its milestone starts.

| ID | Owner | Ev. | Status | Objective | Files | Acceptance / tests |
| --- | --- | --- | --- | --- | --- | --- |
| GAME-02 | A4 | C | Completed (`aec3ae2a`) | Esc/✕ calls `request_leave()` on any running game before opening Settings | `main.gd` (back handler), `library_session`, `zoo_feeding_session`, `shop_session` | `activity_lifecycle` + each game's check |
| GAME-03 | A4 | C | Completed (`aec3ae2a`) | Feeding Time! "stay" outside the zoo puts the player back, or asks again | `zoo_feeding_session.gd` (around lines 280–291) | zoo feeding check |
| GAME-04 | A4 | C | Completed (`aec3ae2a`) | Radar and electrical box say "finish first" instead of a dead E | `scripts/objects/radar_console.gd`, `scripts/world/electrical_box.gd` (`can_interact`) | `interaction` check |
| GAME-05 | A4 | S | Pending | A last-resort unstuck from a blocked seat or vehicle exit; a respawn ends the running game | `player_place.gd`, `main.gd` (around lines 856–862), `seating_controller.gd`, `driveable_vehicle.gd` | `player_place`, `vehicle_arcade` |
| LEARN-02 | A6 | C | Completed (`0bf1851f`) | Feeding Time! orders its pool with `WordMemory.order` | `zoo_feeding_session.gd` (lines 149–171) | targeted check (a due animal first) |
| LEARN-03 | A6 | C | Ready (D8) | Wall-clock term in review timing (an additive `last_played_unix`) | `word_memory.gd` | word-memory check |
| LEARN-04 | A6 | C | Ready (D9) | One meaning of "known" (stability ≥ learned), shown in the journal and results | `vocabulary_book.gd`, `results_screen.gd`, `session_words.gd` | screenshots |
| LEARN-05 | A6 | C | Completed for Stack & Pack (`ab47d0ae`, 4 → 8 words); Feel the Clues left as it is (user) | Grow tiny pools (Stack & Pack 4, Feel the Clues 6, Mystery Doors 11) from the data files, never hand lists | game data files, `activities.json`, then `vocabulary_report.gd -- --write` | per game |
| LEARN-06 | A6 | C | Ready (D11: all designed levels) | Build designed levels for more games | `data/activities.json`, sessions | `minigame_progression` |
| UI-04 | A5 | C | Pending (UI-01) | F1 guide scales and has a touch version (from Settings) | `vocabulary_hud.gd` (around lines 1135–1290), `settings_panel.gd` | screenshots at both sizes |
| UI-05 | A5 | C | Pending (UI-01) | `corner_button`, `style_scrollbar`, `keycap` in BonStyle; local helpers go through `BonStyle.flat()` | `bon_style.gd`, `vocabulary_hud`, `touch_controls`, `vocabulary_book`, `family_panel`, `flight_panel`, `outfit_picker`, `day_clock`, `electrical_box_panel`, `elevator_floor_picker` | before/after screenshots of every HUD state |
| UI-06 | A5 | C | Completed (`b6b98c3a`) | HUD status texts scale | `vocabulary_hud.gd` (`_layout_hud`) | screenshots |
| UI-07 | A5 | C/S | Built (branch `claude/tutorial-progress-c8eee1`, commit pending) | Tutorial progress ("Part n of 3" pill beside Skip); Skip asks first on the shared quit card (Stay green left, Skip coral right; steps and player held meanwhile) | `tutorial.gd`, `shop_order_panel.gd` (`_refresh_quit`), `phrases.json` | `tutorial` 179/0 with the confirm, `app_flow` PASS; [views](../../evidence/tutorial-progress-20261125/README.md) |
| ANIM-03 | A3 | C | Completed (`1f737622`, user kept it after renders) | BonBon's gait phase follows distance (cadence only, poses unchanged) | `player_controller.gd` (around lines 646–668) | walk/sprint/slow-stick render strip |
| ANIM-04 | A3 | C | Completed (`65385841`) | The calling NPC eases down from its hop | `npc_presence.gd` (lines 68–70) | host check, render |
| ANIM-05 | A3 | C | Completed (`65385841`) | Carried-item pendulum on physics ticks | `hand_hold.gd` (lines 245–260) | carry check |
| ANIM-06 | A3/A1 | C | Pending (PERF-01) | Clay animator at a reduced rate beyond about 25 m | `clay_animator.gd` (lines 190–195) | zoo perf capture |
| ANIM-07 | A3 | C | Completed (`c4c7c7ea`) | NPCs face the player when talked to (whole-figure yaw, never Head); no idle gestures | `plush_life.gd`, `npc_chatter.gd`, COMPONENTS.md | NPC registry check, renders |
| GFX-02 | A2/A1 | C | Pending (PERF-01) | Dither fade at plush and prop range ends; LODs for heavy clay meshes if Compatibility allows | `render_culling.gd`, clay mesh bakes | walk-in frame sequence, draws |
| GFX-03 | A2 | C | Completed (`634bc575`) | Sun fades indoors as the moon does; indoor fill adjusted | `day_night.gd` (`_apply_fill`), `data/day_night.json` | café, home, hospital at 08/12/18:30 |
| GFX-04 | A2 | C | Completed (`634bc575`) | No horizon seam while flying (`fog_sky_affect` / `sky_curve` above 130 m) | `day_night.gd`, maybe `vehicle_controls.gd` | flight captures 40/100/200 m, day and night |
| GFX-05 | A2 | S | Ready | Near plane grows with flight height | `vehicle_controls.gd` | flicker diff at 100 m |
| PERF-05 | A1 | C/S | Pending (PERF-01) | Measure flight on a phone; lower `FLIGHT_VIEW_MAX` or the ranges if slow | `vehicle_controls.gd`, `render_culling.gd` | flight captures |
| PERF-06 | A1 | C/S | Pending (PERF-01) | Warm up material variants for late buildings | `app.gd`, `main.gd` (`add_unit`) | cold web timing |
| PERF-07 | A1 | C | Pending (PERF-01) | Free or hide far plushes in long web sessions (option C) | `nearby_units.gd`, plush code | video MB over a session; high risk |
| ARCH-06 | A7 | C/S | Pending (M1) | `practice_log` checks shapes before typed assignment; `"v"` field on the next format change | `practice_log.gd` (lines 62–70) | `practice_log` |
| QA-02 | A8 | C | Completed (25 Nov suite at `dfd2be4c`: PASS 73, KNOWN 3, NEW 1, CRASH 1) | FINAL_VERIFICATION "Current state" states the gap since 16 Nov; one full suite with `dev_focus=all` | `FINAL_VERIFICATION.md` | suite labels against the expected-failures list |

## P3: optional

All of these are **Pending**. Each is small and taken up when its file is already open for a higher task.

Done on 25 Nov: P3-01 in part (settled zoo gate, cached player in the crab: `e8a8edfe`), P3-04 (`a0ae5a25`), P3-15 (`9298019b`), and P3-17's bug (a peek in the flight game now counts as translated: `89f59536`; the bridge refactor is still open).

| ID | Owner | Ev. | Item | Files |
| --- | --- | --- | --- | --- |
| P3-01 | A1 | C | Per-frame trims: room lookup on the 0.25 s timer, cached door type, settled zoo gate, cached player in crab, far-animal skip | `main.gd`, `door_animator.gd`, `zoo_gate.gd`, `crab.gd`, `park_animals.gd` |
| P3-02 | A1 | S | Merge same-material static meshes per cell (L, high risk) | `render_culling.gd`, `indoor_visibility.gd` |
| P3-03 | A1/A2 | C | A coarser second mesh for the heaviest clay animals (zebra 313k tris) | clay build tools, `base.scn` |
| P3-04 | A4 | C | Touch Jump stands you up (`is_action_pressed("jump")`) | `seating_controller.gd`, `playground_swing.gd`, `playground_seesaw.gd` |
| P3-05 | A4 | C | F9 picker during a game: check `in_minigame` or offer "Stop" | `main.gd`, `game_launcher.gd` |
| P3-06 | A4 | C | "Walk closer" toast on an out-of-range tap | `interaction_controller.gd`, `phrases.json` |
| P3-07 | A4 | S | Hinged doors check the player before closing | `door_animator.gd` |
| P3-08 | A4 | C | Grocery Run walk-out moves to the zone door guard (only when the store is next edited) | `shop_session.gd` |
| P3-09 | A7 | S | `is_instance_valid` guards in SceneTreeTimer lambdas | teller, zoo feeding, police, electrical, cashier sessions |
| P3-10 | A7 | C | Typed `main.shop_panel` access instead of `main.get(...)` | `touch_controls.gd` |
| P3-11 | A7 | C | One `tools/build_clay.gd -- <animal>` | `tools/build_*_clay.gd` |
| P3-12 | A6 | C | FSRS details: lapse on first Again; tune the constants by play | `word_memory.gd` |
| P3-13 | A6 | C/S | Normalise aliases in the log and memory (non-destructive) | `practice_log.gd`, `word_memory.gd` |
| P3-14 | A6 | C | "Words due" nudge on the Passport (**decision**) | `missions.gd`, `passport_panel.gd` |
| P3-15 | A5 | C | Light veil instead of dark shades, per UI_STYLE (D14: try, before/after) | `vocabulary_hud.gd`, `bon_style.gd` |
| P3-16 | A5 | S | Name the icon-only HUD buttons for touch players | `vocabulary_hud.gd` |
| P3-17 | A5 | C | `translate_button.gd` becomes a non-visual peek bridge | `translate_button.gd` |
| P3-18 | A3 | S | Bob or waddle for wandering animals without a rig (after the sheep/hen work lands) | `park_animals.gd` |
| P3-19 | A3 | C | Ease BonBon's jump pose; optional 3-step blink | `player_controller.gd`, `plush_life.gd` |
| P3-20 | A2 | C | Glass reflects the time of day (one shared material write) | `day_night.gd` |
| P3-21 | A2 | S | Night-only glow, kept only if cheap on phones | `day_night.gd` |
| P3-22 | A2 | C | Palette clustering report, then snapping per building (D14: try, before/after) | `tools/material_palette.gd`, bakes |
| P3-23 | A2 | S | Ground shader tones toward the pastel palette (D14: try, before/after) | `shaders/*.tres` |
| P3-24 | A2 | C | Three shared clay materials (after the sheep work lands) | `scenes/animals/*_clay.tscn` |
| P3-25 | A2/A8 | C | Mark the 14 Nov "Graphics tiers" entry superseded; relabel `performance/latest.png` | `FINAL_VERIFICATION.md`, performance README |
