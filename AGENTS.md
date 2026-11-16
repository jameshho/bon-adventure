# Spanish Vocabulary Town development

The Godot project is `BonAdventure/`; run project-relative commands there.
Start with its `README.md` task table and `docs/README.md` documentation map,
then read only the relevant sections of
`docs/guides/ARCHITECTURE_REVIEW_PART1.md`, `docs/evidence/part2/HANDOFF.md` and
`docs/guides/FINAL_VERIFICATION.md`. Historical reports describe older snapshots.

## Design reference for AI agents

For town/building design work, first read the
[master design blueprint](BonAdventure/docs/guides/TOWN_DESIGN_BRIEF.md#start-here-current-approved-design).
Exception (user, 16 Nov 2026): each minigame's **purpose and progression** design is owned by
its learning card in the [game guide's minigames page](BonAdventure/docs/game/minigames.md);
record new decisions on those there (rule and code details still go in the game's design
record). Never hand-write word lists in docs: `data/words.json` and the game data files are the
only word source, and the guide's [words page](BonAdventure/docs/game/words.md) is generated
by `tools/vocabulary_report.gd -- --write`.
It owns the approved programs, dimensional decisions, preservation boundaries and
execution order. Follow its links to architectural standards, measured capacity
and implementation ownership; do not reconstruct decisions from historical reports.
Distinguish approved design from built/verified state. Update the master reference
when the user changes a design decision; never promote an unapproved option to a
requirement. Existing school/supermarket dimension approval does not approve other
building resizes or deferred interior/vocabulary work.

## Work narrowly

- Inspect the current implementation and relevant tests before changing it.
  Use `rg` with targeted paths. Exclude `.godot/` and generated images from
  routine searches; do not read the huge world scenes in full. Earlier versions
  live in git history; do not add backup copies or ZIPs to the repository.
- Reuse existing scenes, Main's geometry/material helpers, landscape ribbons and
  the interaction controller. Prefer small changes; do not reorganize the project
  or invent a new layer because a file is large.
- Preserve unrelated work, assets, building positions/interiors, word keys, saves,
  controls, doors and vehicles. Do not rewrite historical reports to claim new passes.

## Ownership and conventions

- Entry: `scenes/app.tscn` (profiles, loading, then the [welcome tutorial](BonAdventure/docs/guides/ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial) for a new profile; since 12 Nov 2026) → `scenes/main.tscn` → `scripts/core/main.gd`. Since 6 Nov 2026 the world is
  the [modular town](BonAdventure/docs/guides/MODULAR_TOWN.md): `scenes/town/base.scn` plus
  one scene per building (`data/buildings.json`); these scenes are the source of truth.
  Change a building with a step in its own script `scripts/buildings/<unit>.gd` and
  `tools/bake_unit.gd -- <unit>` ([how](BonAdventure/docs/guides/MODULAR_TOWN.md#changing-a-building)).
  The old startup passes (`world_refinements.gd`, the interior scripts), the full bake and
  the old saved worlds were deleted on 6 Nov 2026; read them in git history if needed, never
  restore them to build the town.
- Follow existing file-local GDScript style, exported movement settings and shared
  constants. Convert between model, town and world coordinates explicitly.
  Apartment scale is 1.3; the current town uses +X west / +Z north. Read the guide
  before using canonical reference coordinates or serialized Transform3D values.
- UI should be easy to click (user decision, 4 Nov 2026): large tap targets, and text and layout that scale with the
  window (see `money_panel.gd`: scale = min(height/800, width/1100)). The main target is a LAPTOP window.
  Since 9 Nov 2026 (user) the UI should also work on touch/mobile: size lists, rows, scroll bars and
  buttons for a finger (e.g. the journal: rows 56 px, scroll bar 24 px × scale), and never rely on hover
  or a mouse wheel alone. Avoid scroll bars where possible (fit the content, page it or use
  tabs/filters); when a list must scroll, it also scrolls by dragging the list itself. Since 12 Nov 2026
  (user, PWA restructure) the game is also a mobile web app (PWA) in LANDSCAPE: touch controls, the Web
  export preset and saves that survive in the browser are targets
  ([web app](BonAdventure/README.md#web-app-pwa)). Portrait/vertical phone layouts are not; ask
  before designing or testing for them. Since 13 Nov 2026 (user) a touch device held upright on the web
  shows the landscape game turned 90° (the Web preset's `html/head_include`); that is not a
  portrait layout, so keep designing for landscape only.
- For minigames, start with [Building a minigame](BonAdventure/docs/guides/MINIGAMES.md#building-a-minigame):
  a new or changed game uses the shared `minigame_host.gd` (NPC, "!", talking, offers, leave question)
  and `minigame_zone.gd` (in-world fade, placing, doorway), not copies from older sessions.
- **Reuse first** (user, 13 Nov 2026): before adding anything the player can use, hold, open or
  sit on, or anything a character does with its body, eyes or face, read
  [Reusable components](BonAdventure/docs/guides/COMPONENTS.md) and use or extend the component
  listed there (`interactable.gd`, `door_animator.gd` and the door scenes, `hand_hold.gd`,
  `seating_controller.gd`, `plush_life.gd`). Do not write a parallel version. Follow its
  ownership table: eyes are written only by `plush_life.gd`, and a plush's `Head` node (the
  face, pivot at the feet) is never rotated. Update that page when a component changes.
- For animals, reuse `scenes/animals/`, preserve picking and wandering origins, and
  use species display sizes in `park_animals.gd` (`ANIMAL_HEIGHTS`). Do not rescale mascot pigs
  or give every species the same dimensions.
- For buildings, preserve interior roots and door metadata; inspect prefab and
  saved overrides, site/map/quest bindings and clear entrance/vehicle corridors.
- For vocabulary/props, follow the architecture guide's data procedure. Reuse
  prefabs; keep mesh and collision under one word root. Dictionary/category keys,
  aliases, catalog and cached scene metadata must agree. No new duplicate synonyms.

## Verify and document

- Establish a relevant baseline before gameplay edits. Run resource loading plus
  targeted checks, then inspect actual rendered views for visual changes. Static
  checks or headless runs do not verify appearance. Protect learner saves using the
  README's isolated test configuration; inspect tests for output-file writes.
- Budget verification. Every check loads the whole town and takes minutes, so
  run each relevant check once, when the change is complete, and render one batch
  of views. Don't re-run flaky graphical checks to get a pass: record the result
  and move on. Ask before running baseline comparisons or extra suites.
- Report exact checks and limitations. Existing vehicle and metadata failures are
  documented in `FINAL_VERIFICATION.md`; compare labels, not only exit status.
  Never describe the full suite as clean when known failures remain.
- Update the existing authoritative guide when behavior, ownership, controls,
  dimensions, data schema or verification changes. Link to details instead of
  copying them into multiple files. Preserve useful dated evidence, mark stale
  guidance, and record unresolved issues with priorities. Avoid a new hierarchy.
- The [game guide](BonAdventure/docs/game/README.md) (since 16 Nov 2026) is the user's
  review view of what is built and the owner of minigame purpose and progression. When a
  change is visible to players, update its status row, its short entry (a few lines plus
  links, never the details), its learning card if it is a minigame and, if there is a newer
  one, its screenshot link. After changing a game's words, rerun the vocabulary report with
  `--write` and commit `docs/game/words.md` with the change.
- Docs folders (16 Nov 2026, [layout](BonAdventure/docs/README.md#folder-layout)):
  `docs/game/` (game guide), `docs/guides/` (current references), `docs/evidence/`
  (one `<topic>-<yyyymmdd>/` folder per piece of work: its `verify.gd`, captures and
  screenshots) and `docs/archive/` (superseded reports). Put new checks and screenshots in a
  new `docs/evidence/<topic>-<yyyymmdd>/` folder and never write files to the top of `docs/`.
  A branch started before 16 Nov 2026 must move its new docs files and fix old `docs/` paths
  when it merges.

## Development focus switch

`BonAdventure/dev_focus.txt` limits which building units load (see the README); other
buildings are absent entirely, inside and out.
It must read `all` for final verification, full-suite runs and commits. If it lists
buildings, say so in any verification report and never describe that run as the full town.
Before a visual check of a building, make sure that building is listed in `dev_focus.txt`
(otherwise it will not appear); note the original value and restore it when finished.
Baking (`tools/bake_unit.gd`) ignores the switch. A pre-commit hook refuses commits while the
file lists buildings or `spawn=`.

## Git

- The repository root is this folder (`Bon Adventure/`); run git commands here.
- History (16 Nov 2026): this repository (`jameshho/bon-adventure`) starts with one commit. Everything
  "in git history" from before that is in the private `jameshho/vocabulary-town` repository and the
  local bundle `/Users/james/Documents/Codex/vocabulary-town-full-history-20261116.bundle`.
- **Always ask the user before every commit.** Show the changed files and the
  proposed commit message, then wait for an explicit yes. Approval covers only
  that one commit. Never push, rewrite history or change branches without asking.
  Exception (user, 6 Nov 2026): during the
  [modular town restructure](BonAdventure/docs/guides/MODULAR_TOWN.md), commit verified,
  reasonably sized chunks without asking each time; ask when unsure.
- Commit one finished, verified piece of work at a time, not every small edit.
