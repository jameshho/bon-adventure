# Improvement plan: master plan (25 Nov 2026)

**Status (25 Nov 2026): approved by the user; executing the [fast track](#fast-track-small-chunks-user-25-nov-2026) with parallel sessions.** The user's design answers are in [DECISION_LOG.md](DECISION_LOG.md). This folder tracks the whole-game improvement programme the user
asked for on 25 Nov 2026 (performance, graphics, animation, gameplay, UI, learning, architecture).
It does not replace the existing guides: decisions that get approved are recorded in their owning
guide (see [the documentation map](../../README.md#current-guides-where-to-make-decisions)), and
this folder links there.

| File | What it holds |
| --- | --- |
| [MASTER_PLAN.md](MASTER_PLAN.md) | This page: audit summary, priorities, milestones, decisions needed |
| [TASK_TRACKER.md](TASK_TRACKER.md) | Every task: ID, owner, objective, files, acceptance, tests, rollback, status |
| [DEPENDENCY_MAP.md](DEPENDENCY_MAP.md) | What must come before what, and the safe parallel groups |
| [FILE_OWNERSHIP.md](FILE_OWNERSHIP.md) | Which workstream may write which file; contended files |
| [PERFORMANCE_BASELINE.md](PERFORMANCE_BASELINE.md) | Recorded numbers (with dates) and the gaps to measure |
| [DECISION_LOG.md](DECISION_LOG.md) | Decisions made, and the ones waiting for the user |
| [TEST_RESULTS.md](TEST_RESULTS.md) | Checks run for this programme (none yet) |
| [SESSION_HANDOFF.md](SESSION_HANDOFF.md) | Where to pick up |

## How the audit was done

Seven read-only specialist audits ran in parallel on 25 Nov 2026 at commit `11fc0121`, with
uncommitted mahjong and sheep work in the tree. That work was ignored. Each audit read the code
and docs and looked at a few saved screenshots. **Godot was not launched**, so every finding is
either *confirmed in code*, *confirmed from a recorded measurement*, or *speculative*. No runtime
check confirms any of them yet.

The coordinator spot-checked the highest-impact claims in the code:

- the unchecked temp write in `save_store.gd`;
- `read_json` treating corrupt files like missing ones;
- profile-index recovery reusing `p1`;
- the web export filter and the clay mesh references;
- the absence of a stretch mode behind the phone UI size claim.

**Project facts:**

- Godot 4.7.2, GL Compatibility on desktop and mobile, physics interpolation on.
- One autoload (`ScriptRunExit`). Shared state lives in static `shared()` singletons.
- `main.gd` is the documented hub.
- The modular town is 1 base scene plus a scene per building.
- About 96k lines of GDScript.
- 15 minigames, 13 of them with an NPC host.
- 800 words in en/es/zh.
- Real FSRS-4.5 word memory, counted in steps.
- The web pack is 91 MB.

## What works well and must be preserved

These came out of all seven audits. Any task that touches them needs a before/after check.

- **Performance architecture.**
  - `render_culling.gd` static batching, door-leaf merging and the 40 m heavy range.
  - The web 3D scale floor.
  - `indoor_visibility.gd`.
  - `nearby_units.gd` home-first loading.
  - No sun shadows, and one graphics setting (user decision, 23 Nov).
  - WebGL context-loss recovery.
- **Art.**
  - Clay animal sculpts and plush faces.
  - Day-night keyframes, the sun/moon disc and the fog colour.
  - The cream/meadow UI built with `bon_style.gd`.
  - The coplanar-gap bake system.
- **Movement.**
  - `player_controller.gd` is frame-rate independent throughout, including the spring-arm settle and the teleport interpolation reset.
  - `clay_animator.gd` is the single data-driven rig animator.
  - Eye/Head ownership is respected everywhere.
- **Gameplay.**
  - The single focus pass in `interaction_controller.gd`.
  - The `minigame_host.gd` contract, used by every NPC game.
  - The zone door guard.
  - Vehicle safe exits.
  - `popup_stack.gd`.
  - Per-finger touch controls.
- **Learning and saves.**
  - The PracticeLog/WordMemory tracker contract, with nothing recorded in Native mode or while the test launcher is open.
  - The results card with no scores.
  - Tmp-then-rename writes.
  - `save_migration.gd`, which never overwrites.
  - Additive save schemas.

## Findings in one table

The full rows are in [TASK_TRACKER.md](TASK_TRACKER.md).

| Pri | ID | Task | Owner | Evidence |
| --- | --- | --- | --- | --- |
| P0 | ARCH-01 | Never rename a failed temp write over a good save | A7 | confirmed in code |
| P0 | ARCH-02 | Back up a save file that exists but does not parse, instead of overwriting it with defaults | A7 | confirmed in code (the trigger is rare) |
| P0 | ARCH-03 | A broken `profiles/index.json` must not reuse `p1` and copy old flat saves over it | A7 | confirmed in code (the trigger is rare) |
| P1 | ARCH-04 | Keep studied words whose key left `words.json` (filter in memory only) | A7 | confirmed in code |
| P1 | ARCH-05 | Reset `SessionWords` on a profile switch (the results card is empty for the second player) | A7 | confirmed in code; found by two audits |
| P1 | QA-01 | Register 5 existing unregistered checks; add a save-robustness check | A8 | confirmed |
| P1 | PERF-01 | One repeatable performance probe plus a phone procedure (baseline) | A1 | confirmed gap |
| P1 | PERF-02 | Exclude about 27 MB of unused static clay meshes from the web pack (91 → about 64 MB) | A1 | confirmed by reference scan |
| P1 | LEARN-01 | New-word gating counts every word ever met, so new words stall for existing profiles | A6 | confirmed in code |
| P1 | GAME-01 | Library Helper has no walk-away or leave: it soft-locks the HUD, word cards and other games | A4 | confirmed in code |
| P1 | UI-01 | One `BonStyle.factor()` instead of 17 copies (no visual change) | A5 | confirmed |
| P1 | UI-02 | Touch-size floor so phone buttons and rows are never about half size | A5 | arithmetic confirmed; needs a phone render |
| P1 | UI-03 | Drag-to-scroll the journal word list (an AGENTS.md rule it breaks) | A5 | confirmed in code |
| P1 | ANIM-01 | Nodes moved in `_process` with physics interpolation on (animals, NPC hop, gestures, rotors) | A3 | setting and code confirmed; the stutter is speculative |
| P1 | ANIM-02 | Wandering animals walk sideways or backwards before they turn, and their feet slide at start and stop | A3 | confirmed; already noted in ANIMAL_SYSTEM.md |
| P1 | GFX-01 | Soft contact ("blob") shadows, so characters and props stop floating | A2 | confirmed in screenshots; **visual change, needs approval** |
| P1 | PERF-03 | Web: plush sculpting reruns on every launch and building load (0.35–0.8 s hitches mid-walk) | A1 | confirmed from recorded timings |
| P1 | PERF-04 | Voice clips for all 3 languages ship in the pack (about 30 MB) | A1 | confirmed; **design decision** |
| P2 | GAME-02 | One Esc/✕ rule: `request_leave()` for every running game | A4 | confirmed |
| P2 | GAME-03 | Feeding Time! asks only once when you walk out | A4 | confirmed |
| P2 | GAME-04 | Radar and electrical box refuse silently while another game runs | A4 | confirmed |
| P2 | GAME-05 | Last-resort "unstuck" when a seat or vehicle exit stays blocked; a respawn ends the running game | A4 | speculative |
| P2 | LEARN-02 | Feeding Time! picks words with WordMemory like the other 9 games | A6 | confirmed |
| P2 | LEARN-03 | Time-based review between sessions | A6 | **design decision** |
| P2 | LEARN-04 | One meaning of "known word", shown in the journal and results | A6 | **design decision** |
| P2 | LEARN-05 | Grow tiny word pools (Stack & Pack tests 4 words) | A6 | confirmed; **user picks the games** |
| P2 | LEARN-06 | Levels for more games (designed, built only for 2) | A6 | **needs approval for each game** |
| P2 | UI-04 | F1 guide: scale it, and give touch players a version | A5 | confirmed |
| P2 | UI-05 | Move duplicated HUD and panel styling into `bon_style.gd` | A5 | confirmed |
| P2 | UI-06 | Scale the HUD status texts | A5 | confirmed |
| P2 | UI-07 | Tutorial: progress indicator; confirm before a permanent Skip | A5 | confirmed (Skip) |
| P2 | ANIM-03 | BonBon's gait rate follows distance, not a speed lerp (foot skate) | A3 | confirmed by arithmetic; **signature motion** |
| P2 | ANIM-04 | The calling NPC eases down from its hop | A3 | confirmed |
| P2 | ANIM-05 | Run the carried-item pendulum on physics ticks | A3 | confirmed logic |
| P2 | ANIM-06 | Lower the clay animator's update rate beyond about 25 m | A3/A1 | confirmed |
| P2 | ANIM-07 | Town NPCs face the player when talked to; rare idle gestures | A3 | **design decision** |
| P2 | GFX-02 | Fade instead of pop for plushes (20 m) and props (27 m) | A2/A1 | confirmed in code |
| P2 | GFX-03 | The sun shines through roofs indoors; fade it like the moon | A2 | confirmed in code |
| P2 | GFX-04 | Hard horizon seam in the flight view | A2 | confirmed in a screenshot |
| P2 | GFX-05 | Camera near plane scales with flight height (depth precision) | A2 | speculative |
| P2 | PERF-05 | Measure flight draws on a phone (5–6× the on-foot draws) | A1 | confirmed draws |
| P2 | PERF-06 | Shader warm-up for late-loaded buildings | A1 | partly confirmed |
| P2 | PERF-07 | Video memory only grows in a web session (free far plushes) | A1 | confirmed; high risk |
| P2 | ARCH-06 | Shape checks in `practice_log` loading; a version field on the next format change | A7 | confirmed |
| P2 | QA-02 | Update the stale "Current state" in FINAL_VERIFICATION and run one full suite | A8 | confirmed |
| P3 | (various) | Small items: per-frame trims, timer guards, touch Jump on seats, F9 in a game, out-of-range tap feedback, hinged-door check, glass sky colour, night glow, palette clustering, ground shader tones, shared clay materials, FSRS details, alias normalisation, clay build-tool merge, translate-button cleanup | various | see the tracker |

P0 here means data-loss risk. None of the three P0s has been seen in play: each needs a failed
write, a corrupt file or a lost index. They are cheap to fix and protect learner progress, so
they go first.

## Fast track: small chunks (user, 25 Nov 2026)

The user asked for the most improvement in the shortest time. Each chunk below:

- is one commit touching a handful of files;
- is verified with one targeted check (plus renders where the change is visible);
- writes files that no other chunk in its wave writes, so the chunks of a wave can run at the same time.

Chunks are ordered by player impact against effort. These chunks replace the milestone table
below as the working order; the milestone table is kept for the dependencies it records.

**Wave 0: prerequisite (do first, about 30 min)**

| Chunk | What the player gets | Tasks | Files | Check |
| --- | --- | --- | --- | --- |
| C0 | Nothing directly: check results become readable again. Godot crashes on exit (`recursive_mutex lock failed`) after a check prints its result, so the runner reports CRASH even for a pass | QA | `tools/run_checks.py` (trust the summary line when the exit crash follows it; report it separately) | re-read the 25 Nov suite logs |

**Wave 1: all small, run together (disjoint files)**

| Chunk | What the player gets | Tasks | Files | Check |
| --- | --- | --- | --- | --- |
| C1 | Progress can't be wiped by a bad write, a corrupt file or a lost profile list; the 2nd player's results card works; studied words survive word-list edits | ARCH-01…05 | `save_store.gd`, `profile_manager.gd`, `vocabulary_progress.gd` | new save-robustness check, `profiles`, `app_flow` |
| C2 | No more soft-lock in Library Helper; Esc/✕ asks to leave any game; radar and electrical box say "finish first" | GAME-01, 02, 04 | `library_session.gd`, `main.gd` (back handler), `radar_console.gd`, `electrical_box.gd`, `phrases.json` | library, `activity_lifecycle`, `interaction` |
| C3 | Web download 91 → about 64 MB | PERF-02 | `export_presets.cfg`, `deploy_web.py` | one web export, zoo in browser |
| C4 | New words come again for existing players; Feeding Time! reviews due words | LEARN-01, 02 | `word_memory.gd`, `zoo_feeding_session.gd` | word-memory check + simulation |
| C5 | Journal list scrolls by dragging (phones) | UI-03 | `vocabulary_book.gd` | drag/tap screenshots |
| C6 | Animals turn before walking, no sliding or stutter | ANIM-01 (animals), ANIM-02 | `park_animals.gd` | zoo render sequence, part2 |
| C7 | Interiors no longer sun-lit through roofs; clean sky while flying | GFX-03, 04 | `day_night.gd`, `data/day_night.json` | café/home at 3 times, flight captures |
| C8 | Touch Jump stands you up from seats, swings and see-saws | P3-04 | `seating_controller.gd`, `playground_swing.gd`, `playground_seesaw.gd` | seats check |

**Wave 2: bigger visible wins (each waits for the named wave-1 chunk)**

| Chunk | What the player gets | Tasks | After | Files |
| --- | --- | --- | --- | --- |
| C9 | Contact shadows under everyone and everything (approved D6) | GFX-01 | C6 | new shared material, `render_culling.gd`, player/plush/clay/vehicle scenes |
| C10 | NPCs face you when talking; NPC hop eases down | ANIM-07, 04 | none | `plush_life.gd`, `npc_chatter.gd`, `npc_presence.gd` |
| C11 | Known words shown in the journal and on the results card (D9) | LEARN-04 | C4, C5 | `vocabulary_book.gd`, `results_screen.gd`, `session_words.gd` |
| C12 | Words reviewed after time away (D8) | LEARN-03 | C4 | `word_memory.gd` |
| C13 | One UI scale formula, then a phone render to confirm the size problem (D5) | UI-01 (+ render) | C5 | `bon_style.gd` + about 17 UI files |
| C14 | Bigger word pools in Stack & Pack and Feel the Clues (D10) | LEARN-05 | none | their data files; words report |
| C15 | Feeding Time! "stay" keeps you in the zoo | GAME-03 | C4 | `zoo_feeding_session.gd` |
| C16 | BonBon's walk without foot slide (renders for the user, D13) | ANIM-03 | none | `player_controller.gd` |
| C17 | Light veil instead of dark shades; pastel ground tones (D14, before/after) | P3-15, P3-23 | C13 | `vocabulary_hud.gd`, `shaders/*.tres` |

**Wave 3: large (split further when started):** voice packs per language (D7), all designed
levels (D11), phone touch-size floor (after C13's render), web sculpt cache, shader warm-up,
palette tidy-up (D14), far-plush memory.

## Milestones (original proposed order)

Each milestone is small, verified once, recorded in [TEST_RESULTS.md](TEST_RESULTS.md) and
committed separately after the user says yes (AGENTS.md: ask before every commit).

| M | Scope | Tasks | Needs from the user | Verify |
| --- | --- | --- | --- | --- |
| **M0** | Known revision and baseline | Commit or park the uncommitted mahjong/sheep work. PERF-01 probe (one Godot run). One full suite (QA-02) | Approval for the runs and the commit of the in-flight work | Probe numbers, suite labels |
| **M1** | Save safety | ARCH-01, 02, 03, 04, 05, 06 + QA-01 save check | Go-ahead | New save-robustness check, `profiles`, `practice_log`, `app_flow`, `results_screen` |
| **M2** | Game exits | GAME-01, GAME-02, GAME-03, GAME-04 | Go-ahead; phrase wording (es/en/zh) | Library, zoo feeding, `activity_lifecycle`, `interaction` checks; one render |
| **M3** | Web pack | PERF-02 (then PERF-04 if approved) | Approval of the voice design | One web export (sizes), zoo in the web build |
| **M4** | Learning fixes | LEARN-01, LEARN-02 | Go-ahead | Word-memory check plus a simulated learner |
| **M5** | Touch UI | UI-01 (proof of concept: 3 files), then the rest of UI-01, UI-02, UI-03 | Approval of the phone sizing rule (it changes the phone look) | Screenshots at 1280×800 and 844×390, drag/tap |
| **M6** | Motion polish | ANIM-01, ANIM-02 (+ ANIM-04, 05, 06) | Go-ahead | Zoo/NPC render sequence, part2 animal check, frame-time capture |
| **M7** | Look | GFX-03, GFX-04, then a GFX-01 proof of concept on BonBon + one animal | Approval of contact shadows after seeing the proof of concept | Street, farm, zoo, café at 3 times of day; draw counts against M0 |
| **M8** | Web load | PERF-03, PERF-06 | Go-ahead (cache-size trade-off) | Cold and warm web timings |
| **M9+** | P2/P3 backlog and design decisions | as decided | Each design decision | per task |

## Decisions the user needs to make

These are listed in [DECISION_LOG.md](DECISION_LOG.md#open-decisions). The ones that block
milestones:

1. Approve the plan and the milestone order, or reorder it.
2. M0: commit, or set aside, the uncommitted mahjong/sheep work so everything starts from a known revision. Approve one probe run and one full suite.
3. Where these tracking files live. The proposal is this folder, `docs/guides/improvement-plan/`, which follows the `docs/` layout rule of guides with their own folders.
4. Parallel sessions or one session. The recommendation is one session working through milestones in order, with at most one side session for a non-overlapping group (see [DEPENDENCY_MAP.md](DEPENDENCY_MAP.md#parallel-groups)). Every check loads the whole town, and parallel worktrees each need their own import.
5. Design calls:
   - phone touch-size floor (UI-02);
   - contact shadows (GFX-01);
   - per-language voice packs (PERF-04);
   - time-based review (LEARN-03);
   - what "known" means (LEARN-04);
   - which word pools to grow (LEARN-05);
   - NPC idle and facing (ANIM-07);
   - BonBon gait (ANIM-03);
   - palette and ground tones (P3).
