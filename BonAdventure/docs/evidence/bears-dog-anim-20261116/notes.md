# Clay rigs: black bear cub and adult, panda, red panda, golden retriever (16 Nov 2026)

Walking rigs for five clay zoo animals, after the zoo pig's
([method](../../guides/ANIMAL_SYSTEM.md#clay-animal-animation-16-nov-2026)).
**Not in the zoo yet**: the coordinating session places all rigs with one base step and one
bake, and writes the guides. Nothing in the town, `base.gd`, `park_animals.gd` or any guide was
changed; the display scenes and their `*_clay.gd` meshers were only read.

## Files

| Animal | Build tool | Rig scene | Meshes and skin |
| --- | --- | --- | --- |
| Bear cub | `tools/build_black_bear_clay_rig.gd` (both bears) | `scenes/animals/black_bear_clay_rigged.scn` | `clay_meshes/black_bear_rig/` |
| Adult bear | same | `scenes/animals/black_bear_adult_clay_rigged.scn` | `clay_meshes/black_bear_adult_rig/` |
| Panda | `tools/build_panda_clay_rig.gd` | `scenes/animals/panda_clay_rigged.scn` | `clay_meshes/panda_rig/` |
| Red panda | `tools/build_red_panda_clay_rig.gd` | `scenes/animals/red_panda_clay_rigged.scn` | `clay_meshes/red_panda_rig/` |
| Golden retriever | `tools/build_golden_retriever_clay_rig.gd` | `scenes/animals/golden_retriever_clay_rigged.scn` | `clay_meshes/golden_retriever_rig/` |

The four tools share `tools/clay_rig_tool.gd` (build, add the `ClayAnimator`, save meshes and
skin as separate files as the pig tool's `_save_parts`, plus helpers `eye()`, `leg()`,
`lean_deg()`, `chain_at()`). It also sets the root's `anim_aabb` meta from the display's size,
so the animator's on-screen notifier fits the adult bear (2.1 tall). Rebuild (each under 1 s):

    godot --headless --path . --script res://tools/build_<animal>_clay_rig.gd

Checks: `capture.gd` here (loads only the display and rig scenes, never the town; needs a drawn
window and an isolated HOME):

    godot --path . --resolution 1000x700 --script res://docs/evidence/bears-dog-anim-20261116/capture.gd [-- <prefab> ...]

Per animal: `<prefab>-compare.png` (display top, rig at rest bottom, 4 views),
`-weights.png` (vertices coloured by bone at rest and at the walk's extreme with the head turned;
colours in `report.json`), `-seams.png` (neck and hips close up at both extremes, head turned
±24°), `-walk.png` (8 frames from the side on a ground plane, 4 from the front 3/4), `-tail.png`
(walking from above and behind, 0.08 s apart: tail and ears), `-blink.png` (open, half, shut).

## Shared-script changes (additive; the pig is unchanged)

`scripts/characters/clay_animator.gd`:
- `leg_neutral_deg` and `tail_axis`: copied verbatim from the rig-hoofed session's planned edit
  (same text), so the merge is trivial. Walking swings each leg about upright instead of the
  display's mid-stride pose; standing keeps the display's pose.
- `keep_feet_down` (default false) + `foot_reach`: lifts a leg whenever its swing would put
  either end of a flat sole below the display's ground (a leaning leg turned upright reaches
  lower; a paw swung back tips its toes down). Without it the adult bear's claws went 2–3 cm
  into the ground.
- `wag_speed` (default `Vector2(2.2, 9.0)`, the pig's old hard-coded rate).
- Optional bone `tail2` (child of `tail`) and `tail_lag`: the second tail bone swings the same way,
  lagging, so a long tail bends like a whip. `_ready` caches `tail2`.

`scripts/characters/clay_rig.gd`:
- Optional `eyes.lids = {mesh, reach}`: triangles of that mesh within `reach` of an eye move into
  the eye's node as a second surface (own material), so they close with the eye. Without it the
  bears' lid lines and the panda's dark eye outline stayed open round a shut eye ("spectacles").

Pig check: rebuilding the pig with the changed scripts gave byte-identical meshes and skin
(`clay_meshes/pig_rig/`); its scene differed only by storing the new empty `leg_neutral_deg`, and
was restored from git (the pig files are not part of this branch).

## Per animal

Bone shapes are in each animal's own sheet pixels, placed with its mesher's coordinate helper
(`T()` with the cub's body squash, `Q()`, `PR()` × `PF`, `W()` / `FINE`). Legs: the pivot at the
top of the leg inside the shoulder or thigh; the capsule from just under the torso to the paw,
so the shoulder and haunch masses stay with the body and the skin bends where the leg leaves it.
Everything skinned shares one material and is merged into one surface `Skeleton3D/Clay`; noses
with their own material, eyes and face details ride the `Head` attachment unskinned.

| Animal | Bones | Skinned (one surface) | Triangles rig / display | Rest diff (mean levels, share > 8) |
| --- | --- | --- | --- | --- |
| Bear cub | root, body, head, tail, 4 legs | Body, Muzzle, Ears, Claws: 11.7k verts | 32.4k / 98.4k | 0.90–1.24, 0.2–0.8% |
| Adult bear | same | same: 13.6k verts | 36.3k / 114k | 0.86–1.27, 0.2–0.8% |
| Panda | root, body, head, tail, 4 legs | Body, Head (whole on the head bone), Ears: 7.5k verts | 22.8k / 59.0k | 1.82–2.12, 1.3–1.8% |
| Red panda | root, body, head, tail, tail2, 4 legs | Body, Head, Ears, Tail (2-bone chain): 16.8k verts | 35.7k / 99.0k | 1.16–1.31, 1.0–1.7% |
| Golden retriever | root, body, head, tail, tail2, ear_l, ear_r, 4 legs | Body, Ears (head + ear bones), Tail (2 bones): 19.4k verts | 72.0k / 189k | 0.83–0.97, 0.1–0.2% |

(The pig: 20.6k skinned verts, 39k triangles.) Simplify: bodies 25%, ears 30%, the bears'
muzzle and claws 35%, the dog's tail 30%; the red panda's tail 50% (at 30% the simplifier ate
2 cm of its rounded tip). The difference at rest is the thinning; shading matches by eye.

Animator settings (`ClayAnimator`, written by the tools):
- **Bears and panda**: a heavy, rolling lateral walk (one foot at a time, hind then front:
  `leg_phase` [0.25, 0.75, 0, 0.5] for fl, fr, bl, br), `swing_deg` 17, `roll_deg` 5, `bob` 4 px,
  `lift` 12 px, `nod_deg` 2.5, `shift_deg` 1.8, `tail_deg` 9 (the ball tail), no ear flop,
  `leg_neutral_deg` from each leg's lean, `keep_feet_down` with `foot_reach` 52 px (bears) / 44
  (panda).
- **Red panda**: the same lateral walk, lighter: `swing_deg` 22, `roll_deg` 3, `lift` 11 px; tail
  `tail_deg` 13, `wag_speed` (1.6, 5.5), `tail_lag` 1.1 (a slow swing that bends along the tail);
  `foot_reach` 32 px; `head_turn_deg` 26.
- **Golden retriever**: a lively trot (default diagonal pairs), `swing_deg` 26, `lift` 16 px,
  `bob` 6 px, `roll_deg` 2, `nod_deg` 4; tail `tail_deg` 24, `wag_speed` (5, 12), `tail_lag` 0.7;
  floppy ears `ear_deg` 11 (ear bones pivot at the root, the skull's top keeps the root on the
  head); `foot_reach` 28 px; `head_turn_deg` 28.

## What the images show

- Compare: rig at rest matches each display in all four views.
- Seams: no tears or gaps at the neck, shoulders or hips at either extreme with the head turned;
  the clay stretches over the shoulder and thigh. Heads that are separate meshes (panda, red
  panda) turn whole on their ball, overlapping the body as in the display.
- Walk: feet stay on or above the ground in all frames (after `keep_feet_down`); legs swing about
  upright; bears and panda roll; the dog trots with a springy bob.
- Tail/ears: the red panda's tail swings and bends; the dog's plume wags and its ears flop out
  and back in step.
- Blink: open, half, shut read cleanly on all five (bears and panda after `eyes.lids`).

## Open issues

- **Not checked**: in the town or zoo (not placed), frame times (no perf run; expect about the
  pig's cost per animal: one skinned surface each, 7.5k–19k skinned vertices), a web export, a
  phone, and idle (breathing and weight shift) beyond the code path the pig uses.
- Dog: 72k triangles in all, of which about 33k are the unskinned eyes, face details and nose
  (the display's own detail, static under `Head`). Skinned cost is like the pig's. If the dog is
  too heavy on phones, thin `Face details` at bake time (not tried).
- Dog ears flare visibly from above at the top of the flop (11°); lower `ear_deg` if it reads as
  flapping rather than floppy.
- Lower hind thighs follow the leg on all five (by design, so the leg bends below the haunch);
  on the cub the hind leg's share reaches fairly high up the thigh.
- The panda's and red panda's far paws are just off the ground in the display; the walk keeps
  them at least that high.
- Foot sliding on sharp turns with `park_animals.gd` is not tuned (`stride_scale` 1 for all).
- The bear cub and adult share bone code; the cub's body squash is applied to its bone shapes
  through the mesher's own `_body_squash()`, so a change there carries over on rebuild.
