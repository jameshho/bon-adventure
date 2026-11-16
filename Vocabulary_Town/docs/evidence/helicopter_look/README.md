# Black Hawk-inspired helicopter appearance

> Historical implementation record. Use the [documentation map](../../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

Restyled the existing hospital helicopter with a matte dark-olive, faceted fuselage, divided cockpit glazing, twin engine nacelles and exhausts, side cabin doors and rails, tapered tail boom, tail stabilizer, three wheels, four main-rotor blades and crossed tail-rotor blades. This is a stylized interpretation suited to the town's low-poly art, not a scale replica.

The original scene path, vocabulary key, animated rotor pivots and controller are retained. Rotor extents remain within the existing protective swept volumes; body collision hulls are derived from the new geometry. The original helicopter scene is preserved in backups/black_hawk_look_20261018/scenes/props/vehicles/helicopter.tscn, under the ignored backups directory. No learner-save files were edited.

`build.gd` reproducibly creates the editable scene. `preview.gd` loads the actual main scene and captures front/rear views on the hospital helipad without recording vocabulary progress. `front.png` and `rear.png` show the result in Godot.

Validation: the 41-check town suite passed with 501/501 vocabulary coverage, including original helipad takeoff, safe landing/exiting and cloud behavior. The 21-check helicopter motion suite passed. Graphical main-scene previews were inspected for body shape, glass visibility, rotor placement and gear. The full regression caught a roof-name-based automatic collider on the antenna; its name was corrected so it no longer acquires an unregistered self-collider.
