# BonBon rename, Phase A (16 Nov 2026)

User decision (16 Nov 2026): the pig player character is **BonBon** (邦邦, still a girl) and
the game is **Bon Adventure: Little Town of Words**. Phase A renamed the code, scenes, data,
save keys and evidence scripts; the docs text is a separate phase. Git history is not rewritten.

## What changed

- Files: `scenes/characters/BonBon.tscn`, `scenes/player/bonbon_player.tscn`,
  `scripts/player/bonbon_effects.gd`, `assets/ui/avatars/bonbon.webp`, and the evidence checks
  `town-checks/check_bonbon.gd`, `check_bonbon_ui.gd`, `capture_bonbon.gd` (with their `.uid`).
- Nodes: `BonBonPlayer`, `Visual/BonBon`; the hospital's doctor plush, named after the
  old name, is `BonBonDoctor` (hospital step `rename_doctor_plush`, baked; only that name changed).
- Data: house character `bonbon` / "BonBon", tutorial guide `bonbon`, outfit phrase
  `outfits.bonbon_s_own_look` ("El look de BonBon" / "BonBon's own look" / "邦邦自己的打扮"),
  the grammar sentence "Yo ___ BonBon." (zh 我是邦邦。), pinyin 邦邦 Bāngbāng, every line that named
  the game → "Bon Adventure", and the full map's title (`map.title`) too.
- Saves:
  - `project.godot` `config/name` "Vocabulary Town" → "Bon Adventure". `save_migration.gd`
    copies the whole old `user://` tree, profiles included.
  - A saved avatar that is no longer a house character (such as the pig's old id) is rewritten to
    "bonbon" when profiles load (user, 16 Nov 2026: no alias, so the old name is not kept).
  - The web resume note moved from `localStorage` `vt-resume` → `bon-resume` (the old key is
    moved once and then removed); the reload flag moved from `vt-resume-now` → `bon-resume-now`
    (the old flag is still accepted).
  - The Web preset deletes the old `Vocabulary Town-sw-cache-*` cache.
- URLs: README and `tools/deploy_web.py` name `jameshho/bon-adventure` and
  `https://jameshho.github.io/bon-adventure/` (the repository itself is not renamed yet).

## Verification (16 Nov 2026, full town, `dev_focus.txt` = all, isolated HOME)

- `verify_saves.gd`: **20 checks, 0 failures** ([log](verify_saves.log)). It covers an old
  "Vocabulary Town" folder with a profile whose avatar id is unknown (`old_pig`), `device.json` and a log, the fallback,
  and the resume-key move (the page code run in macOS JavaScript with a localStorage stand-in;
  not tried in a real browser).
- `tools/run_checks.py --only runtime_resources,language,profiles,app_flow,player_place,tutorial,fitting_room,plush_life,vocabulary_report,grammar_class`:
  **PASS 10**, no failures (run with the first version, an alias for the old avatar id; after
  the fallback replaced it, `verify_saves.gd` and `profiles` were run again: both pass).
- The vocabulary report left `docs/game/words.md` unchanged. Two rows of
  `docs/guides/vocabulary-report/report.csv` (book, bookshelf) changed: they come from the library
  shelves already on main, not from this rename.
- `town-checks/check_bonbon.gd`: **6 failures** (`Hyper aura enabled`,
  `Hyper is significantly faster than sprint`, `Hyper and sprint coexist`,
  `Hyper sprint and midair jump coexist`, `Moving hyper mode draws trail`, `Consecutive jump 2`).
  `check_bonbon_ui.gd`: **3 failures** (`H toggles hyper and updates HUD`,
  `Map blocks world picking`, `Map close restores gameplay`). All nine test features switched
  off on 14 Nov 2026 (`scripts/core/features.gd`: `HYPER_SPEED`, `FULL_MAP`,
  `INFINITE_JUMP_AT_START` are false). They are not caused by the rename. These checks are not in
  `run_checks.py` and still expect those features.
- Rendered views (`capture.gd`, 1280 × 720): [title](title.png),
  [a profile saved with the pig's old avatar id, shown as BonBon](profiles_old_save.png) (rendered
  with the alias; the fallback gives the same profile), [avatar picker](avatar_picker.png),
  [BonBon at the default spawn](bonbon_spawn.png) (the supermarket entrance: with no saved place
  the town starts there, not in the house), [fitting-room picker](outfit_picker.png). The capture
  process ended with exit 137 after the last shot was saved.

Not run: the rest of the full suite, a web export, a real browser or phone.
