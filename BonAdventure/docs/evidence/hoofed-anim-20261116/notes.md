# Hoofed clay animals walk: cow, zebra, deer, rhino (16 Nov 2026)

Rigs for four clay zoo animals, made the pig's way
(docs/guides/ANIMAL_SYSTEM.md#clay-animal-animation-16-nov-2026-the-zoo-pig-walks). **Not in
the zoo yet**: the coordinating session places all rigs with one base step and one bake and
writes the guides. Nothing in `base.gd`, `base.scn`, `main.gd`, `park_animals.gd`, the display
scenes, the `*_clay.gd` meshers or the guides was changed.

## Files

| Species | Build tool | Output |
| --- | --- | --- |
| cow | `tools/build_cow_clay_rig.gd` | `scenes/animals/cow_clay_rigged.scn` + `clay_meshes/cow_rig/` (0.69 MB) |
| zebra | `tools/build_zebra_clay_rig.gd` | `scenes/animals/zebra_clay_rigged.scn` + `clay_meshes/zebra_rig/` (0.94 MB) |
| deer | `tools/build_deer_clay_rig.gd` | `scenes/animals/deer_clay_rigged.scn` + `clay_meshes/deer_rig/` (0.55 MB) |
| rhino | `tools/build_rhino_clay_rig.gd` | `scenes/animals/rhino_clay_rigged.scn` + `clay_meshes/rhino_rig/` (0.98 MB) |

`tools/clay_rig_bake.gd` is the tools' shared last step (build with `clay_rig.gd`, add the
`ClayAnimator` with the species' settings, set the root's `anim_aabb` meta from the display's
bounds + 0.15, save meshes and skins as separate files like the pig tool's `_save_parts`).
Rebuild one: `godot --headless --path . --script res://tools/build_<p>_clay_rig.gd` (0.5–2 s).
Each root has `Skeleton3D/Clay` (one merged skinned surface), `Head/LeftEye`, `Head/RightEye`,
`Head/Face details`, `Footprint` and `ClayAnimator`.

### Shared-file changes (additive; the pig is unchanged)

`scripts/characters/clay_animator.gd`, new exports, all defaults = the pig's old behaviour:
- `leg_neutral_deg` (per leg, default empty = 0): the walk swings about this angle, faded in
  with the walk, and the leg is raised by `leg_length · (1/cos − 1)` so a straightened slanted
  leg does not sink. For displays modelled mid-stride (deer, rhino).
- `feet` (per leg, default empty): optional foot bones (children of the legs) counter-rotated
  by the leg's swing, so wide hooves/feet stay level (rhino toenails dug ~4 cm in without it).
- `tail_axis` (default `Vector3.UP`): `FORWARD` swings a hanging tail like a pendulum.
- optional `neck` bone with `neck_share` (default 0.4; no effect without a "neck" bone): the
  neck takes that share of the head's turn and nod.

`scripts/characters/clay_rig.gd`: new spec key `attach` ({mesh: bone}, default none): rigid
pieces go unskinned under a `BoneAttachment3D` named `<Bone>Attach` (deer antlers and tail pom,
which have their own softer material and would otherwise be a second skinned surface).

Check that the pig is unchanged: rebuilding it with the edited files wrote byte-identical
`clay_meshes/pig_rig/*.res` (the rebuilt `pig_clay_rigged.scn` was then restored from git).

## Per species

Bone shapes are in each sheet's pixels with the mesher's own placement functions (cow `W()`,
zebra `V()`, deer `D()`·`FIT`, rhino `T()` and `Hd()` for the enlarged head). All four: root;
body; head; tail; four legs (diagonal trot from the pig); ears on the head.

| | cow | zebra | deer | rhino |
| --- | --- | --- | --- | --- |
| Extra bones | – | neck | neck, 4 feet | 4 feet |
| blend (sheet px) | 10 | 10 | 9 | 12 |
| Rigid on head | muzzle, horns | muzzle, tongue | antlers (attach) | both horns |
| Other parts | udder rigid on body; hooves blended over legs; tuft on tail | mane blended head/neck/body; hooves on legs; tuft on tail | tail pom on tail (attach); hooves in the body mesh, on the feet | toenails in the body mesh, on the feet; tuft on tail |
| swing / lift / bob | 20° / 10 px / 4 px | 24° / 13 / 4 | 22° / 16 / 5 | 18° / 8 / 3 |
| head turn / neck share | 22° / – | 26° / 0.45 | 28° / 0.45 | 18° / – |
| tail | 12° pendulum | 14° pendulum | 20° side swish | 14° pendulum |
| ears | 9° | 7° | 9° | 10° |
| leg_neutral_deg | – | – | +1.4, −3.4, +13.6, −9.2 (from the display's stride) | from the display's stride (far pair a step ahead) |
| Thinning | body 25%, ears 50%, hooves 25%, rest 50% | body closed then 12% (below), rest 25–50% | body 25%, ears 50% | body 25%, ears 25%, horns 50% |

Results (`report.json`, from `capture.gd`):

| | display tris | rig tris (all meshes) | skinned surfaces | rest diff, mean levels (4 views) | px > 8 levels | lowest y rest → walk |
| --- | ---: | ---: | ---: | --- | --- | --- |
| cow | 113k | 40k | 1 | 0.99–1.21 | 0.6–0.8% | −0.018 → −0.018 |
| zebra | 313k | 55k | 1 | 1.50–1.69 | 1.5–1.9% | −0.003 → −0.003 |
| deer | 73k | 31k | 1 | 1.84–2.16 | 1.6–2.0% | 0.000 → −0.006 |
| rhino | 186k | 55k | 1 | 0.62–0.76 | 0.1–0.4% | −0.037 → −0.039 |

"Lowest y" is the lowest vertex of the skinned surface by CPU skinning over 8 walk phases; the
displays themselves reach a little below y 0 inside the hooves (cow, rhino), so the check is
that walking goes no lower than rest. Before foot bones the rhino reached −0.077 and the deer
−0.015.

**Zebra body.** The painted stripes split triangles along their edges without splitting the
neighbours: ~33k T-junctions (100k open edges) in a 286k-triangle body. The simplifier keeps
open edges, so it stopped at 97k and pulled the shape out of true (rest diff 9.5 levels; the
hooves looked swollen because the leg flare above them had shrunk). The zebra tool now closes
each T-junction with zero-area triangles on a copy (`_closed`; 32.5k of them) before thinning;
the closed body thins to 40k with a rest diff of 1.5–1.7.

## Images (looked at)

- `<p>-compare.png`: display (top) vs rig at rest (bottom), four views. Matches; the deer's
  and cow's ears keep their rims at 50% thinning (at 25% they looked smaller).
- `<p>-seams.png`: rows = swing phase 0.25 with the head turned left and 0.75 turned right;
  neck (side, rear 3/4), hips (side, from behind below), from above, from below. No tears or
  gaps: the cow's short neck and the rhino's neck folds stretch; the zebra's and deer's long
  necks bend through the neck bone with the mane following; the udder stays on the belly
  between the swinging hind legs.
- `<p>-walk.png`: 8 side frames of a cycle and 4 from the front 3/4. Trot reads on all four;
  the deer's mid-stride legs straighten into the walk; rhino and deer feet stay flat.
- `<p>-blink.png`: open, half, shut from the front and 3/4 (plush_life.gd squashes the eyes;
  the painted outline stays, as on the pig).

## Not checked / open issues

- Not in the zoo or town; no frame-time measurement (each is one skinned surface like the pig,
  so the pig's ~0.2 ms render CPU per visible animated animal should roughly hold; the zebra
  and rhino have about 40% more skinned vertices than the pig).
- Not checked on a web export or phone; no check suite run (no town change).
- Hooves of cow and zebra tilt with the leg (no foot bones); at the swing extremes the hoof
  rises with the leg, so they do not sink, but the toe points down slightly in the air.
- Rhino legs are short: even at 18° the stride is small from a distance; tune `swing_deg` /
  `stride_scale` in the zoo if feet slide.
- The deer's display tail pom and antlers are unthinned (attached, not skinned).
- About 800 T-junctions on the zebra body remain open (chains longer than 6 edges or bent).
