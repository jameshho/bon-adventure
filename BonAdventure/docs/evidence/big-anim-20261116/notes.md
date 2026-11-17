# Big clay animals walk: elephant, giraffe, lion (16 Nov 2026)

These are walking rigs for three big clay zoo animals, built the way the pig was
([pig method](../../guides/ANIMAL_SYSTEM.md#clay-animal-animation-16-nov-2026)).
**None of them is in the zoo yet.** The coordinating session adds every rig with one base step
and one bake, and writes the guides. This file is the record until then.

Each build tool only reads its display scene and its `<prefab>_clay.gd` mesher; neither is
changed. Rebuild a rig after its display changes:

    godot --headless --path . --script res://tools/build_<prefab>_clay_rig.gd

Each tool writes `scenes/animals/<prefab>_clay_rigged.scn`. Its meshes and skin go to
`scenes/animals/clay_meshes/<prefab>_rig/`, as for the pig. Every rig has `Head/LeftEye` and
`Head/RightEye` for blinking, a `ClayAnimator` with that species' settings, and an `anim_aabb`
meta that sizes the on-screen notifier to the animal (the default box fits a pig).

## Shared-script changes (additive; the pig is unchanged)

- `clay_rig.gd`: two new spec keys.
  - `merge_into: {part: other part}` joins a part to another part's surface whatever its
    material.
  - `blends: {part: blend}` gives one part its own blend softness.
- `clay_animator.gd`: new exported settings. Their defaults keep the old behaviour.
  - `leg_neutral_deg`: a per-leg angle added while walking. The displays stand mid-stride, so a
    reaching leg swings about a more upright angle once the animal walks.
  - `feet` (renamed `foot_contacts` when the four branches were merged) and `foot_stretch`: a per-leg rest contact point. Each leg bone is scaled along y
    (`_plant()`) so its foot stays on the ground through the stance and lifts by `lift` in the
    swing, instead of sinking or floating as it swings about its pivot. At rest the scale is
    exactly 1.
  - `tail_axis` (default up) and `tail_chain` / `tail_lag`: extra tail bones that wave a beat
    later.
  - `ear_axis` (default forward) and `ear_fan_seconds` (0 = off): a slow ear fan.
  - `neck`, `neck_share` and `neck_pump_deg`: the look is shared along the neck bones, and the
    neck pumps in step while walking.
  - `trunk`, `trunk_sway_deg`, `trunk_curl_deg` and `trunk_seconds`: per-bone sway and curl,
    each bone a little behind the one before.
- Pig check: the HEAD animator and this one gave identical bone poses for the pig rig. The
  maximum difference was 0.0 over 60 poses (6 walk phases with a head turn, headless). The pig
  rig was not rebuilt.

## Checks

`capture.gd` (this folder) loads only the six animal scenes. Run it with an isolated `HOME` and
a 1000×700 window:

    godot --path . --resolution 1000x700 --script res://docs/evidence/big-anim-20261116/capture.gd [-- elephant giraffe lion]

It writes `report.json` and these images per species:

- `<s>-compare.png`: the display (top) and the rig at rest (bottom), four views.
- `<s>-seams.png`: close-ups at swing phases 0.25 and 0.75 with the head fully turned each way.
  The views are the neck from the side, the hips, the face from the front 3/4 (trunk / neck /
  mane), from above, and from below.
- `<s>-walk.png`: 8 frames of a cycle from the side, plus 4 from the 3/4, on a ground plane.
- `<s>-idle.png`: 6 frames 0.6 s apart.
- `<s>-blink.png`: open, half, shut.

`walk_lowest` in `report.json` is the lowest skinned vertex in each walk frame, computed on the
CPU from the skin binds. Like the pig's capture, the run does not exit after "BIG ANIM REPORT
done"; stop it then. The final images come from the last run of each species, with the rigs as
committed.

## Elephant

- **Bones (14):** root, body, head (with the tusks and lower lip), trunk_1 → trunk_2 → trunk_3,
  tail, ear_l and ear_r (vertical hinge at the ear root, on the head), and four legs (on the
  root). The shapes are in the sheet's pixels through `ElephantClay.T()`. Blend is 12 px.
- **Surfaces:** one skinned surface (`Clay`) holds Body, Ears, Tail tuft and Face details. The
  face details (lids, brows, smile, trunk wrinkles) are skinned to the head and trunk so the
  wrinkles stay on the swaying trunk (`merge_into`). The eyes are rigid on `Head`.
- **Triangles:** 35.1k skinned (Body 24.8k at 20%, Ears 7.7k at 20%, details 2.2k, tuft 0.4k).
  The display has 136k.
- **Settings:**
  - Lateral-sequence walk: `leg_phase` fl 0.25, fr 0.75, bl 0, br 0.5 (left hind, left fore,
    right hind, right fore).
  - Swing 13°, neutral 40% of each leg's rest lean, `foot_stretch` 0.7–1.12, lift 14 px.
  - Bob 3 px, roll 1.4°, breath 4.2 s, head turn 14°.
  - Ears fan 9° about the vertical every 3.4 s.
  - Trunk sway 5° and curl 4° per bone (3.6 s period, in step while walking).
  - The tail swings sideways about a level axis.
- **Rest difference** (mean levels / share of pixels > 8 levels): 0.91 / 0.22%, 1.12 / 0.38%,
  0.84 / 0.19%, 0.79 / 0.17%.
- **Feet:**
  - The display's own feet already reach y −0.166, below its y-0 ground line, at rest.
  - In the walk the lowest point is −0.153 to −0.172. Each leg stays at its own rest level
    (checked per leg).
  - The first try (60% neutral, stretch ≥ 0.8) let the reaching near front leg sink 0.15 below
    its rest; that was fixed.
- **Open issues:**
  - The reaching near front leg is shortened to 0.70 at the back of its stance; it reads as a
    shorter, more upright leg (no knee bone).
  - The walk swing is small (heavy and slow by design).

## Giraffe

- **Bones (14):** root, body, neck_1 → neck_2 → neck_3 → head (with the horns), ear_l and
  ear_r, tail, and four legs. Blend is 11 px; 7 px was tried first. Neck capsules overlap at
  each joint so the weights blend along the neck.
- **Surfaces:** one skinned surface holds Body, Ears, Mane and Tail tuft. The mane and tuft
  (hair material: roughness 0.95, specular 0.2) join the clay surface with `merge_into`, so they
  bend with the neck and tail. Eyes and face details are rigid on `Head`.
  `-- hair-own` builds them as a second surface instead.
- **Triangles:** 46.2k skinned (Body 41.0k at 50%, Mane 2.8k, Ears 1.5k, tuft 0.8k). The display
  has 97k.
  - At 30% the spot edges added a mean difference of 2.3–3.3 levels, so the body is kept at
    50%.
- **Settings:**
  - Pace: `leg_phase` fl 0, fr 0.5, bl 0, br 0.5 (both legs on one side together).
  - Swing 16°, neutral 50%, stretch 0.75–1.12, lift 9 px.
  - Roll 2.6°, bob 2 px.
  - Head turn 30°, 60% of it on the three neck bones; neck pump 2.2° per bone.
  - Tail 16° about a level axis; ears flop 8°.
- **Rest difference:** 1.23 / 3.3%, 0.76 / 0.9%, 1.50 / 5.3%, 1.79 / 7.3%.
  - With the hair as its own surface: 2.56 / 2.7%, 2.71 / 2.7%, 2.50 / 2.8%, 2.27 / 2.4%
    (at 30% body).
  - Most of the remaining share of changed pixels is the mane and tuft looking slightly glossier
    in the clay material.
- **Feet:**
  - At rest the lowest point is −0.019.
  - In the walk it is −0.019 to −0.035, at most 1.6 cm lower.
  - The far front leg keeps its lifted display pose at rest and reaches the ground in its stance.
- **Open issues:**
  - The hair is slightly glossier than on the display. The user can choose `-- hair-own` (a
    second skinned surface) if that matters.
  - Faint horizontal bands on the front of the neck are in the static display too (mesher), not
    from the rig.
  - Legs scaled along y light slightly differently (normals are not re-normalised for the
    non-uniform scale); this was hard to see in the renders.

## Lion

- **Display:** `scenes/animals/lion_clay.scn` (`base.gd` `clay_meshes_external` finds the lion
  as `.scn`). The bone shapes use `LionClay.Q()` (true sheet pixels).
- **Bones (13):** root, body (with the filler between the thighs), neck (inside the mane's ring),
  head, tail → tail_2 (the tuft rides tail_2), ear_l and ear_r, and four legs. Blend is 10 px.
- **Mane:** skinned across body, neck and head with a softer 22 px blend. The collar and the
  front lobes turn with the face; the back ring stays on the shoulders. The seams sheet shows no
  gap or slide at a 22° turn.
- **Surfaces:** two skinned surfaces, `Clay` (Body, Ears, Tail tuft) and `Mane`. The mane keeps
  its own matte hair material (roughness 1.0, specular 0.15; a user decision, 11 Nov 2026).
  - Joined to the clay surface it read shinier: rest difference 3.4–5.0 levels and 16–27% of
    pixels, against 1.05–1.27 / 0.3–0.6% with its own surface.
  - `-- mane-merged` builds the one-surface variant.
  - This is one surface more than the brief asked for. The coordinator or the user should decide
    (cost: about one extra skinned surface, see the pig's perf.json).
- **Triangles:** Clay 19.3k (Body 17.6k at 40%, Ears 1.0k, tuft 0.7k) and Mane 7.3k (30%). The
  display has 70k.
- **Settings:**
  - Lateral-sequence walk (`leg_phase` 0.25, 0.75, 0, 0.5).
  - Swing 14°, neutral 30%, stretch 0.72–1.12, lift 12 px.
  - Roll 1.8°, bob 3 px.
  - Head turn 22°, 45% of it on the neck.
  - Tail 13° with tail_2 0.8 rad behind; ears flop 6°.
- **Rest difference:** 1.05 / 0.44%, 1.27 / 0.57%, 1.05 / 0.47%, 1.14 / 0.34%.
- **Feet:**
  - At rest the lowest point is −0.044 (the display's paws).
  - In the walk it is −0.043 to −0.069. The big round paws tilt with the leg, so a toe or heel
    dips up to 2.6 cm below rest.
  - Swing 18° dipped 5 cm and was reduced to 14°.
- **Open issues:**
  - The 2.6 cm paw dip.
  - The crouched display pose gives a short, low stride; the walk reads but is subtle.

## Not checked

- Frame time (no perf run).
- The town: the rigs are not placed there.
- Wandering with `park_animals.gd`: speed and stride matching. `stride_scale` is 1 for all
  three; tune it in the zoo.
- The web export.
- The check suite was not run, because there is no town change.
- The new tool scripts have no `.uid` files yet. The editor or `--import` adds them; the
  worktree's `.godot` import was not run.
