# Character standardization and rigging experiment (18 Nov 2026)

**Status: EXPERIMENT, waiting for the user's review.** Nothing in the game uses these files. No
production scene, sculpt, costume data or `player_controller.gd` was changed.

## Deliverables

| # | File | What it shows |
| --- | --- | --- |
| 1 | `experiment-1-front.png` (before: `baseline-1-front.png`) | The nine side by side, orthographic camera, same light, feet on one ground, names below, at in-game scale |
| 2 | `experiment-2-back.png` | The same row with the camera directly behind it (so the order reads right to left) |
| 3 | `experiment-3-side.png` | Each character turned 90° on its spot, all facing screen right |
| 4 | `experiment-4-costume.png`, `-costume-side.png`, `-costume-stride.png`, `-costume-closeup.png` | The same T-shirt and cap on all nine; mid-stride at full swing; close-ups |
| 5 | `5-walk-bonbon.gif`, `5-walk-leo.gif`, `5-walk-leo-run.gif`, `5-walk-poppy.gif`, `5-walk-miso.gif`, `5-walk-sheet.png`, `walk-report.json` | Original walk (left) and experiment (right): same character, speed, camera and 32 frames at 30 fps. Miso wears the costume and turns a full circle |

Measurements: `baseline-report.json` and `experiment-report.json` (anchors per character).

## How the characters work today

- **No skeleton.** Each plush is a procedural sculpt (`plush_sculpt.gd` / `pig_sculpt.gd` and
  one script per species). All nine share one layout: `Torso` (body and head), `Head` (face
  group), `Arm`, `Arm_2`, `Foot`, `Foot_2` and `Tail`. Every part's origin is at the floor
  between the feet, facing −Z ([components guide](../../guides/COMPONENTS.md#plush-characters)).
  That layout already gives every character the same ground point and the same part names.
- **One walk for everyone.** The walk is `player_controller.gd` `animate_bonbon()`. Arms turn
  ±0.42 rad × gait weight about a shoulder point. Feet slide 0.16 forward and lift 0.12. The
  body bobs `|sin| × 0.055`. Gait speed is 7–15 rad/s. Avatars use this same code, and NPCs
  don't walk. Turning rotates the whole player. The only character-specific number is the
  shoulder pivot, which is BonBon's `(±0.65, 1.22, 0)` for every avatar.
- **Costumes already fit every body.** `plush_costume.gd` measures each wearer's mesh, fur and
  wool included, and builds shirts, hats and other pieces from shared code. Per species it
  stores only a few typed anchors in `data/plush_costumes.json`: collar, shoulder, hand,
  hide/tuck/press. For the player only, `dress_player()` moves the sleeves onto the arms.

## Was a new rig needed?

**No.** The current system already works as a shared attachment rig with per-species overrides.
This experiment kept it and fixed the two places where it was not truly shared:

1. **Measured anchors** (`rig.gd measure()`). Each figure's shoulder (the inner top corner of
   the arm mesh), hand, hip, foot, height and torso come from its own meshes. Only the collar
   stays art-directed. For BonBon the measured shoulder is `(0.644, 1.22, −0.01)`, which is the
   walk's own constant.
2. **One walk with a per-character pivot** (`rig.gd walk()`). It is `animate_bonbon()`'s
   arithmetic unchanged, except that the arms turn about the measured shoulder.
3. **Costumes use the same anchors** (`exp_costume.gd`), and sleeves are moved onto the arms
   for any walker (`attach_sleeves()`, a generalized `dress_player()`).

Walk fidelity: the mean pixel difference between original and experiment is 0.0002 for BonBon,
which is identical within anti-aliasing. It is 0.0009 for Leo walking and 0.0013 for Leo
running. With the old pivot, avatar arms turned about a point 0.10–0.21 away from their real
shoulder (Leo 0.21, Poppy 0.19, Miso 0.18, Twinkle 0.18, Cocodrilo 0.10, Sunny 0.10). At
walking speed that is barely visible. Poppy (0.011) and Miso (0.010) differ more because their
sculpts changed.

## Proportion changes

- **BonBon, Leo, Bruno, Sam, Cocodrilo: unchanged.** Same meshes.
- **Poppy, Miso, Sunny, Twinkle:** only arm height, arm size and paw size changed
  (`variants/*.gd`, which extend the production sculpts). Face, body, ears, tail and colours
  are untouched.

| | shoulder y | arm length | paw width |
| --- | --- | --- | --- |
| Reference band (BonBon, Bruno, Sam, Cocodrilo) | 1.16–1.22 | 0.35–0.37 | 0.36–0.44 |
| Poppy | 1.04 → 1.13 | 0.26 → 0.32 | 0.30 → 0.35 |
| Miso | 1.08 → 1.15 | 0.31 → 0.34 | 0.36 → 0.39 |
| Sunny | 1.20 | 0.33 → 0.35 | 0.32 → 0.38 |
| Twinkle | 1.16 | 0.31 → 0.34 | 0.32 → 0.37 |

Leo is the exception in the reference band (shoulder 1.04, under the mane). He was kept as he is.
Heights still range from 2.21 to 2.35 (mane and wool), as decided on 13 Nov 2026.

## Costume findings

- **BonBon's typed costume anchors are stale.** `[0.70, 0.92]` and `[0.935, 0.854]` describe an
  old nub arm, so the baseline sleeves stand off her shoulders like flaps (compare the two
  `*-4-costume-closeup.png`). The measured anchors put them on her shoulders. The other eight
  typed anchors agree with the measurement to within 5 mm.
- **NPC sleeves don't follow the arms today.** Only the player gets them moved onto the arms.
  The experiment does this for every walker. In `5-walk-miso.gif` the sleeves and cap stay on
  through the stride and the full turn.
- **Remaining fitting problems:**
  - On fur and wool (Sam, Poppy, Sunny) the shirt is bulky and its neckline is wavy.
  - The cap's seat changes between characters: it sinks into Leo's and Poppy's hair, which is
    intended (`hat_sink`), and perches high on Twinkle.
  - Short sleeves (share 0.32) are mostly hidden under the shirt's flare.
  - The cap's oval badge reads small.

## Limitations

- **Arm swing only.** The walk is rendered in place with `rig.gd`'s copy of `animate_bonbon()`,
  not by driving the real player. The feet slide by design, as in the original.
- **Not seen in game.** Nothing was checked on the web or a phone, or inside the town.
  `dev_focus.txt` was untouched (`all`), and no town checks were run.
- **Poppy's claw lines.** Claws are placed at the old paw size, so a bigger paw may hide them
  partly.
- **The front lineup is slightly brighter than the side view.** The cameras see the lit ground
  plane at slightly different angles.
- **Adopting this is a separate piece of work.** It would mean:
  - `player_controller.gd` takes its pivot from the model (`bind_model()`).
  - `plush_costume.gd` measures shoulder and hand, or the data is corrected.
  - `dress_player()`'s sleeve step becomes shared.
  - The variant numbers go into the four production sculpts.
  - The sculpt cache rebuilds by itself.

## Reproduce

```
HOME=<scratch>/home VT_SCULPT_CACHE=0 VT_MESH_SHARE=0 VT_FRAMES=<scratch>/frames \
  godot --path . --resolution 960x540 --script res://docs/evidence/character-rig-20261118/showcase.gd -- baseline|experiment|walk
python3 docs/evidence/character-rig-20261118/make_gif.py <scratch>/frames 840 460 docs/evidence/character-rig-20261118 BonBon Leo Leo-run Poppy Miso
```
