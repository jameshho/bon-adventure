# BonBon third-person conversion

Implemented October 18, 2026. Validated with the installed Godot 4.7.2 stable,
using the project's existing OpenGL Compatibility renderer on Apple M5.

## Behavior

BonBon is an editable instance in `scenes/main.tscn`. The reusable controller scene
is `scenes/player/bonbon_player.tscn`; the renamed model is
`scenes/characters/BonBon.tscn`. The model's original landmark-scale source and
plush mesh generation remain intact. The playable instance uses uniform unit
scale, retaining the proportions and original 0.76-radius, 2.2-height capsule.
The selection box remains present but inactive on the playable instance, and
the original static collider is disabled in favor of the matching character
collider. Other vocabulary pigs are unchanged. Historical backups are unchanged.

WASD is relative to the current camera yaw. Shift toggles sprint; H independently
toggles hyper speed, then restores the previous sprint setting. Each fresh Space
press permits another jump, including in midair. Motion uses acceleration,
deceleration and smooth facing. Procedural arm/foot/bob and jump poses operate
on ordinary editable scene nodes, without replacing or deforming the model.

Only right-drag orbits; releasing restores the visible cursor. Wheel zoom is
bounded to 3–14 units. A sphere-swept spring arm excludes BonBon, contracts against
obstacles, and eases out again. Collision may shorten the distance below the
requested zoom minimum in cramped interiors; the pivot stays above BonBon's head.
The starting position is on the clear approach to the house.

Left-click picks under the cursor; while right-dragging, it picks at the center
reticle. Interaction range is measured from BonBon, so zoom does not change reach.
Existing vocabulary, translations, doors, discovery missions, journal, minimap,
language switching, and save format remain in use. Help moved from H to F1.
Journal/map/help suspend movement, orbit, zoom, and world interaction.

Hyper mode adds a removable #00BFFF rim overlay, a bounded 24-point world-space
crossed ribbon, 40 short-lived blue-white particles, one shadowless local light,
and a selective cyan bloom pass before the HUD. Intensity follows actual
horizontal movement speed. Bloom is disabled entirely outside hyper mode;
original mesh materials are never modified. The selective bloom avoids relying
on version-specific renderer glow behavior (see the official
[Godot renderer overview](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)).

**10 Nov 2026 (user):** the bloom pass and local light were removed because they lit
up the sky and nearby objects. The rim glow, trail and particles stay.

## Validation

All 18 validation runs passed (17 suite runs, including both stair variants,
plus the BonBon UI integration check). 428 literal resource references resolve with
no missing files.

- `docs/evidence/town-checks/check_bonbon.gd`: actual physical WASD acceleration, sprint/hyper speed,
  combined midair jumps, camera-relative travel, facing, deceleration, key-repeat
  protection, orbit gating/release, zoom limits, modal input blocking, wall
  collision/recovery, original collision dimensions, material restoration,
  bounded trail memory and immediate toggle-off cleanup.
- `docs/evidence/town-checks/check_bonbon_ui.gd`: journal/map/help input gating, H/F1 routing, HUD status,
  escape dismissal and disabling the bloom pass.
- `docs/evidence/town-checks/check_interaction.gd`: cursor-based off-center physics picking, hover,
  translation/category cards, repeat-click close, shared door state, study
  signals, language refresh, offscreen dismissal and character-based range.
- Existing regression scripts cover the island, zoo, park bridge, house,
  public interiors, all 12 building types, 137 reusable vocabulary assets,
  96 shop displays, 43 civic displays, eight vehicle types, vocabulary aliases,
  categories, save normalization and town paths. School and hospital tests walk
  BonBon up and down both storeys without jumping.
- Legacy fixtures were updated to place the character near the camera and set
  explicit pointer coordinates. Stale counts were corrected to match previously
  removed vocabulary (11 sports displays, 2 science displays, 5 geography
  displays); the zoo check now accepts the existing species-specific meshes.
  The sofa test aims above the coffee table instead of through it. Fixtures that
  click real-world objects disconnect the progress-saving callback.
- Rendered captures from `docs/evidence/town-checks/capture_bonbon.gd` were visually inspected:
  `docs/evidence/bonbon-review/gameplay.png`, `bonbon.png`, and `hyper.png`.

The headless macOS engine prints a system-CA-certificate diagnostic at startup;
this also occurs outside the game code. The desktop rendering runs do not report
project script/shader errors. No network feature is used by these changes.

Validation is automated plus rendered screenshot inspection, not an exhaustive
manual playthrough of every object or a cross-device performance benchmark.
Other Godot 4 minor versions have not been run here.

Run the new checks from the project directory:

```sh
godot --headless --path . --script res://docs/evidence/town-checks/check_bonbon.gd
godot --headless --path . --script res://docs/evidence/town-checks/check_bonbon_ui.gd
godot --headless --path . --script res://docs/evidence/town-checks/check_interaction.gd
```

## Sitting on chairs and benches — 28 October 2026

**Playground swings — 1 November 2026.** A seat with meta `playground_swing` (its pivot,
`scripts/world/playground_swing.gd`) is a moving seat: the swing places BonBon from the seat's
transform each physics frame (tilting with it) and sets `player.seat_focus` for the camera;
the seating controller turns W / S presses into kicks and makes E brake before standing level.
[Controls and tuning](TOWN_DESIGN_BRIEF.md#playground-rebuild-and-rideable-swings--1-november-2026).

**Sofas and wheelchairs — 31 October 2026.** `SEAT_WORDS` in `seating_controller.gd`
adds every `sofa` and `wheelchair` word root (hint: “E: sit on sofa/wheelchair”). A
sofa with several cushions gives one seat per cushion, all facing the sofa's front
(−Z), and E takes the nearest; an aimed sofa or seat still wins over other furniture.
Wheelchairs are only seats; they do not roll.

Press **E** near a chair or bench to sit; press **E** again to stand. A contextual
“E: sit on chair/bench” hint appears within reach. Right-drag camera orbit and wheel
zoom still work while seated. WASD, jump and noclip cannot move BonBon out of the
seated pose; use E to stand. Journal/map/help continue to block world actions.
Sitting never studies a word or advances a mission; left-click study is unchanged.

### Design and animation

BonBon uses separate sculpted mesh parts, not a humanoid skeleton. The implementation
therefore reuses the existing procedural arm/foot animation approach, with a gentle
body lean, relaxed arms and raised forward feet. No external animation asset,
retargeted skeleton, model replacement or new dependency was needed.

Official Godot references consulted:

- [Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html): supports
  interpolation toward dynamically chosen values. Each sit/stand creates a new,
  physics-process Tween with sine ease-in/out, rather than reusing completed tweens.
- [PhysicsDirectSpaceState3D](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate3d.html):
  ray queries check sight lines and floor support; shape intersection queries check
  whether BonBon's standing capsule fits at a proposed exit.

Sit transition: 0.55 seconds with a 0.4-second facing turn. Stand transition: 0.45
seconds. `player_controller.gd` owns pose blending, camera tracking and restoration
of the original arm/foot transforms, collision masks, movement and hyper effects.
The ordinary walking/jump pose code does not run while seated. Repeated E input
cannot interrupt an unfinished transition. Furniture collision geometry is unchanged;
only BonBon's collision is suspended during the seated state/transitions.

### Seat registration and editing

`scripts/player/seating_controller.gd` is attached by Main after world construction
and interaction setup, before garden render batching. It recognizes chair, bench
and armchair word roots plus named or explicitly marked decorative chair seats.
Flat mesh surfaces determine the actual world-space seat height. Nearby back panels
or the seat's local forward direction determine facing. Duplicate anchors are
collapsed. The inspected runtime town registers **170 seats**, including generated
restaurant chairs without vocabulary labels. Public-garden source meshes survive
batching, so their seat anchors remain valid.

The restaurant builders (`restaurant_interiors.gd`, `restaurant_venues.gd`; deleted 6 Nov 2026, the chairs are now baked in `scenes/town/restaurants.scn`) mark
all generated chairs with `sit_enabled=true` and an explicit local `sit_forward`.
This avoids relying on names, since repeated generated names can become
`@Node3D@...`. These are interaction tags only; no new word keys or colliders are
added. Existing seat geometry, tables and town placement are preserved.

Optional Node3D metadata for authoring exceptions:

- `sit_enabled: bool`: include a decorative chair in seat discovery.
- `sit_disabled: bool`: exclude the tagged candidate.
- `sit_position: Vector3`: explicit local seat-surface point, converted to world space.
- `sit_forward: Vector3`: local facing vector (normally `Vector3.FORWARD`).

Automatic recognition uses broad, shallow mesh surfaces, so unusual custom chairs
should use explicit position/facing metadata and be visually checked. This is not
a skeleton-aware seating/IK system; BonBon retains her plush proportions. Restart
Main after changing seats because registration occurs once after construction.

### Interaction priority and exit safety

Main retains existing E priorities: exit an active vehicle first; if seated, stand;
otherwise nearby gates, pointed-at doors, nearby seating, then vehicle boarding.
Within reach, a pointed-at seat is preferred; otherwise the closest seat is chosen.
The maximum horizontal reach is 2.8 world units, with a 1.65-unit vertical limit
and a clear body-level sight line. Noclip and riding a vehicle prevent sitting.
The elevator's input handler ignores seated BonBon so it cannot consume the E needed
to stand. Its normal landing/cabin controls remain unchanged.

Standing first tries the original approach position, then nearby front/side/rear
positions. Each candidate needs a supporting floor, suitable slope, correct floor
height, clear sight line and room for the original standing capsule. If all exits
are blocked, BonBon stays seated and the HUD explains why. Saved collision masks and
pose are restored only as the stand transition completes. This feature has no save
state: loading the game starts with the normal standing player.

### Verification

Godot 4.7.2 Compatibility, temporary copy with the isolated user directory
`VocabularyTownChecks/sitting-20261028`. No vocabulary-study or quest-save calls in
the sitting checks. Current runtime town includes the user's other restaurant and
layout work; that work was retained.

- Existing `check_bonbon.gd`: **0 failures both before and after** (movement, jumps,
  camera, collision and effects fixture).
- New `check_sitting.gd`: **211 checks, 0 failures**, **170 registered seats**.
  Real garden bench and home chair exercised through Main's E handler: sit/stand,
  repeat input, transition completion, masks, jump/noclip guards, modal journal,
  fully blocked exits, clear recovery, wall-blocked approach and no learning changes.
- `check_bonbon_ui.gd`: **0 failures**.
- `check_interaction.gd`: **PASS** for picking, cards, doors, signals and range.
- `check_runtime_resources.gd`: **328 resources, 0 failures**.
- Graphical captures: before, mid-transition, seated and standing again on the
  actual garden bench and home lounge chair. Both E transitions succeeded and the
  seated pose was visually inspected. [Bench](../evidence/town-checks/sitting-bench.png), [chair](../evidence/town-checks/sitting-chair.png).
- `git diff --check`: clean.

Existing SpatialMaterial remapping warnings and restricted headless log/certificate
warnings remain. No exhaustive manual test of every registered seat, full vehicle
suite, or performance benchmark is claimed. Exit clearance is checked when standing
starts; the current short transition does not reserve space against later-moving
objects. No commit was made as part of this task.
