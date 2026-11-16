# Rooftop and jump update

> Historical implementation record. Use the [documentation map](../../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

Verified with Godot 4.7.2, GL Compatibility renderer.

- `check_rooftops.gd`: **264 checks, 0 failures**, including 36 real BonBon landing
  and repeat-jump cases, walking up all six home roof slopes, rooftop edge rays,
  helipad WASD movement, six successive midair jumps, landing reset, key-repeat
  rejection and noclip reset. Authored collision baking is idempotent.
- `check_home_refresh.gd`: 0 failures.
- `check_hospital_floors.gd`: 0 failures; real BonBon climbs/descends both storeys.
- `check_building_exteriors.gd`: all 12 building types and vocabulary picking pass.
- `check_interaction.gd`: targeting, cards, vocabulary signals and doors pass.
- `check_bonbon.gd`: 0 failures.
- Graphical startup and rendered home/hospital/helicopter previews verified.

Measured vertical rise above each launch point at 60 physics ticks per second:
1.64, 2.58, 3.24, 3.71, 4.03, 4.27 metres. The base jump remains 8.3 m/s and
22 m/s² gravity; height approaches a 3× base-height limit with diminishing gains.
Landing resets immediately; walking off a ledge still permits a base-strength jump.

The home ridge caps are visual trim above continuous sloped collision surfaces,
so BonBon can cross the ridge without catching on a raised box collider. All new
geometry is built from editable Godot meshes with shared materials, static
collision shapes, and no external textures or runtime model generation. The
helicopter is a parked static model, ready for later visual refinement.

Open `helicopter.png`, `home.png` and `hospital.png` for previews. Regenerate clean
previews using `docs/evidence/town-checks/capture_rooftops.gd` in a graphical Godot session.
