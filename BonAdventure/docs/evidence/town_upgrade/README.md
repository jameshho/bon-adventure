# Vocabulary Town upgrade

> Historical implementation record. Use the [documentation map](../../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

Implemented and verified in Godot 4.7.2 on 2026-10-18. The existing main scene, vehicle instance, town artwork, vocabulary keys and save format are retained. Upgrades are applied when the main scene builds, through `scripts/world/town_upgrade.gd` and `vocabulary_completion.gd`.

## Where to go

- **Supermarket:** west side of the civic shops, center **(-33, 43)**, entrance **(-33, 34)**. The existing structure moved two town units toward the promenade and expanded from 14 × 15 to 19.6 × 18 units. All storefront geometry moved together. There are wide central/side aisles, low grocery gondolas, cold cases, carts, checkout equipment, prices and section labels. The quest destination and both maps reflect this location.
- **Bank:** **(25, 45)**. Reception, waiting seats and queue lead to teller windows; manager office and walk-in vault are at the rear. Aim at the room doors and press **E**. Closing doors reopen if BonBon occupies their path.
- **Police station:** **(43, 45)**. Reception and waiting area lead past officer desks to the interview room, equipment/records and holding cell. The central corridor and room approaches fit BonBon's collision capsule.
- **Helicopter:** the original hospital rooftop helipad, hospital center **(-32, 116)**. **E** boards, **W/S** accelerates forward/back, **A/D** turns, **Space/Ctrl** ascends/descends. Release controls to brake into hover. Land on both skids and stop before **E** exits; unsafe or blocked exits explain why they are refused. The camera follows smoothly and retains obstacle collision.
- **Reachable cloud:** above the front-yard/Main Street edge near **(18.5, 22)**. Approach from the home side, move toward it and press **Space three times** as you rise. The existing repeated-jump ability reaches it without noclip or a vehicle. All 25 original cloud puffs now have shaped solid collision; the last five form this low cloud. Clouds remain stationary.
- **Additional vocabulary:** contextual household, school, hospital, shopping and outdoor objects; an anatomy teaching model at the hospital forecourt and a small chapel at **(46.5, 75)** restore vocabulary absent from the saved town.

Coordinates are local town X/Z; the town uses a 1.3 world scale. Press **M** for the live map and **F1** for controls.

## Verification

- **501/501 vocabulary entries** have an actual picker hit from a clear standing capsule on a supporting surface, with study-card Spanish and category checked against the dictionary.
- **41 regression checks** exercise the actual main scene: preserved original vocabulary, legacy progress aliases, building/corridor access, closed/open doors and occupied-doorway safety, smooth flight/hover/ascent/descent, original helipad lift-off, swept rotor/overhead collisions, elevated landing, safe and blocked exits, actual main-scene boarding/exit, camera collision, cloud falling landings, ground-to-cloud repeated jumps and walking/jumping on clouds.
- Graphical main-scene launch and the regression suite ran with the OpenGL Compatibility renderer on Apple M5. The delivered `market.png`, `bank.png`, `police.png` and `cloud.png` are Godot viewport captures.
- Existing `docs/evidence/town-checks/check_vehicle_collision.gd` passed: all eight original vehicle types block BonBon from four directions, allow walking around, and remain selectable.
- All six existing progress files found were compared with their backups and were byte-for-byte unchanged. Original dictionary/category values are preserved; only `cloud` was added. Tests disconnect progress-writing study signals.

See `test_results.txt`, `coverage.md`, `coverage.csv` and `coverage.json` for evidence. Coverage is based on sampled physical standing and sight-line tests, not a complete navigation walk from spawn to each of 501 entries. Individual recognition of every stylized/legacy model has not been manually reviewed; the changed interiors and low cloud were visually reviewed. No automated failures remain. Headless Godot emitted a macOS system-certificate warning; the graphical run did not, and no script errors were reported.

## Re-run

From the project folder, using your Godot executable:

```sh
godot --headless --path . --log-file /tmp/town-regression.log --script docs/evidence/town_upgrade/verify.gd
godot --path . --log-file /tmp/town-graphical.log --script docs/evidence/town_upgrade/verify.gd
godot --headless --path . --log-file /tmp/town-vehicles.log --script docs/evidence/town-checks/check_vehicle_collision.gd
```

Keep the graphical window visible so macOS continues drawing screenshot frames. `verify.gd -- --audit-only` updates the JSON coverage without running movement tests. Tests read existing progress but do not study/save words.

## Backups

`backups/town_upgrade_20261018/` contains the original versions of every edited existing source/data file, hashes of the original data files, and copies of the six existing progress files. New files are the two upgrade scripts and this delivery folder. To undo, restore the backed-up source/data files; the original saved town scenes were not rewritten. Restore progress backups only if independently needed, since the upgrade did not change progress.
