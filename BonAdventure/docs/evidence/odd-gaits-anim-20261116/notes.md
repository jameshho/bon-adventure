# Clay gorilla, kangaroo, duck and flamingo walking rigs (16 Nov 2026)

Rigs for the four clay zoo animals whose gaits the pig's trot does not fit, built the pig's way
(`docs/guides/ANIMAL_SYSTEM.md#clay-animal-animation-16-nov-2026`). **Not in
the zoo yet**: the coordinating session places all rigs with one base step and one bake, and
writes the guides. The display scenes and their `*_clay.gd` meshers were only read.

## Files

| Species | Build tool | Rig scene | Meshes and skin |
| --- | --- | --- | --- |
| Gorilla | `tools/build_gorilla_clay_rig.gd` | `scenes/animals/gorilla_clay_rigged.scn` | `scenes/animals/clay_meshes/gorilla_rig/` |
| Kangaroo | `tools/build_kangaroo_clay_rig.gd` | `scenes/animals/kangaroo_clay_rigged.scn` | `scenes/animals/clay_meshes/kangaroo_rig/` |
| Duck | `tools/build_duck_clay_rig.gd` | `scenes/animals/duck_clay_rigged.scn` | `scenes/animals/clay_meshes/duck_rig/` |
| Flamingo | `tools/build_flamingo_clay_rig.gd` | `scenes/animals/flamingo_clay_rigged.scn` | `scenes/animals/clay_meshes/flamingo_rig/` |

`tools/clay_rig_common.gd` holds what the four tools share (build, animator settings, the pig
tool's `_save_parts`, triangle count, and `eye_frames()`: the eye nodes are placed from the
display's own `Eyes` mesh, split at x = 0, centred on each half, z along its mean normal, y up,
because the meshers place the eyes with internal ray casts). Rebuild one with
`godot --headless --path . --script res://tools/build_<prefab>_clay_rig.gd` (0.1–0.5 s).
Each rig: `Skeleton3D/Clay` (one merged skinned surface), `Head` (BoneAttachment3D with
`LeftEye`, `RightEye` and `Face details`), `Footprint`, `ClayAnimator`; root meta `anim_aabb`
sized to the animal for the animator's on-screen notifier.

## Shared-script changes

`scripts/characters/clay_rig.gd`: none.

`scripts/characters/clay_animator.gd`, additive only; new exports in the group "Other gaits",
each defaulting to empty / 0 / false:
- `leg_neutral_deg` (per leg, the angle the walk swings about instead of the rest pose: the
  gorilla display stands mid-stride, right limbs forward),
- `lower_legs` + `bend_deg` (a child bone below the knee that folds back while its leg swings:
  the flamingo's ankle),
- `feet` (foot bones kept level, so toes and knuckles do not dig in),
- `ground_lock` (lifts a leg so its foot pivot never drops below its rest height; a limb that
  leans at rest is longer vertically as it swings through upright),
- `hop`, `hop_pitch_deg`, `tail_lift_deg` (the "root" bone rises once a cycle, the body pitches,
  the tail lifts in the air and counters the body's pitch so it never dips into the ground),
- `twist_deg` (body yaw in step) and `sway` (body side shift; default 0.02, the value that was
  hard-coded before),
- `head_bob` (head forward and back twice a cycle),
- `neck` + `neck_sway_deg` (a neck bone chain shares half the head's look and sways in an S).

`_ready` also looks up `root` and the new bone lists; the local `sway` in `_pose` is renamed
`drift`. **Pig unchanged**: `pig_check.gd` poses two rigged pigs, one with this animator and
one with the animator of commit 6815754 (same settings and state), at 8 phases of the walk:
every bone pose differs by 0.0. (`pig-walk.png`, re-rendered as the pilot did, differs from the
pilot's `walk.png` by 0.58–0.62 levels mean, 0.3–0.5% of pixels: render-run noise or the rig
rebuilt since that image, not the animator, as the bone check shows.)

## Per species

Triangles: rigged (all meshes) against the display. Rest difference: `compare.png` pixel
difference between display and rig at rest over 4 views, mean levels of 255 / share of pixels
more than 8 levels apart (the thinning; the pig's was 0.66–0.74 / 0.10–0.18%). Lowest point: the
lowest skinned vertex over 16 phases of the cycle (`report.json`); the displays themselves dip a
few mm below 0.

### Gorilla: knuckle-walk
- Bones: root; body (torso, pecs, buttocks, belly); head (crest, ears rigid on it); arm_l/arm_r
  with hand_l/hand_r; leg_l/leg_r with foot_l/foot_r. Blend 14 sheet px. The arm and leg
  columns stop 0.8 radius above the wrist or ankle so the levelled hand or foot is not dragged
  round (before that fix the feet sank 2.4 cm).
- Gait: lateral sequence, `leg_phase` arm_l 0.25, arm_r 0.75, leg_l 0, leg_r 0.5; swing 15°,
  neutral angles per pair from the display (`rest_angle`), hands and feet level, ground lock;
  roll 4°, twist 5° (the rolling shoulder), bob, sway; head turn 28°.
- Triangles 33,429 (display 105,009); body thinned to 20%.
- Rest difference 1.06–1.13 / 0.45–0.66%. Lowest point −8.3 mm (display at rest −6 mm).

### Kangaroo: hop
- Bones: root; body (torso and arms; pivot at the hips so the pitch does not push the tail
  base down); head; ear_l/ear_r (blended with the head); tail; leg_l/leg_r (haunch to heel) with
  foot_l/foot_r (the long feet). Blend 9 sheet px.
- Gait: both legs phase 0.75 (back to forward in the air), hop 55 sheet px (about 0.31 town
  units) once a cycle, pitch 5°, tail lift 16°, feet level, ground lock, stride_scale 1.3.
- Triangles 21,790 (display 72,764).
- Rest difference 1.12–1.51 / 0.40–0.94%. Lowest point +4 mm on the ground half of the cycle,
  up to 0.35 in the air.

### Duck: waddle
- Bones: root; body (wings rigid on it); head (bill, lower bill, crest); tail; leg_l/leg_r
  with foot_l/foot_r (legs mesh blended over the four). Blend 9 sheet px.
- Gait: legs half a cycle apart, swing 26°, roll 9°, twist 7°, sway, head bob 7 sheet px,
  nod 4°, tail wag 14°; feet level, ground lock.
- Triangles 30,268 (display 205,636): the duck is meshed 12 times finer than life, so every
  part is thinned hard (body 8%).
- Rest difference 0.90–0.96 / 0.42–0.54%. Lowest point −1.9 mm (display at rest −2 mm).

### Flamingo: slow stride, S-neck
- Bones: root; body (wings rigid on it); neck_1 → neck_2 → head (beak, crest); leg_l/leg_r
  (feathered thigh to the knobbly ankle) → shin_l/shin_r → foot_l/foot_r. Blend 6 sheet px.
- Gait: legs half a cycle apart, swing 17°, ankle bend 38° while swinging, feet level, ground
  lock; neck sway 5° alternating along the chain; head bob 6 sheet px; small roll and twist.
- Triangles 35,664 (display 124,270).
- Rest difference 1.45–1.85 / 1.1–2.6%: the highest of the four (thin legs and beak edges
  after thinning; the shading matches in `flamingo-compare.png`). Lowest point +2.7 mm.

## Images

`<s>-compare.png` (display top, rig bottom), `<s>-walk.png` (8 frames side, 4 front 3/4, a
ground plate at y 0), `<s>-seams.png` (both gait extremes with the head turned: upper body,
legs, from above, from below), `<s>-blink.png` (open, half, shut; front and 3/4),
`pig-walk.png`. Looked at: no tears or gaps at the neck, shoulders, hips, ankles or the
flamingo's neck chain; feet on the ground plate; the head turn and blink work on all four.

Run: `capture.gd` (isolated HOME, window shown, loads only these scenes), once, after the fixes
above; `pig_check.gd` once, headless.

## Open issues

1. Not in the zoo and not seen in town light, wandering with `park_animals.gd`, on the web or a
   phone; no frame-time measurement (each is one skinned surface like the pig, so about the
   pig's cost per visible animal; the duck and kangaroo have fewer triangles than the pig's
   39k, the gorilla and flamingo similar).
2. Shut eyes: the eye squashes inside the outline and lashes laid on the face (`Face details`),
   so a shut eye shows a slit inside its ring (flamingo, duck, gorilla lid lines). The pig has
   the same limit; a lid mesh would be a mesher change.
3. The kangaroo's display is posed mid-step (far leg forward, heel lifted); both legs swing
   together about their own rest angles, so the hop keeps that stagger. The gorilla's arms
   keep the display's twisted shoulders.
4. `stride_scale` (0.64 walkers, 1.3 kangaroo) is set from the leg geometry, not measured
   against a wanderer's speed: check foot sliding in the zoo.
5. Duck waddle roll reads mostly from the front; the side view shows the steps and head bob.
