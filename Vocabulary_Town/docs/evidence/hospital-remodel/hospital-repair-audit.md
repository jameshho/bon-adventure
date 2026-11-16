# Hospital observation and repair plan

## Observation completed before edits

Inspected actual Main renders of front, front-left, rear, hallway, stair enclosure,
landing and default player camera. Used the user's screenshot as a symptom reference.

1. **P1 — stair usability:** 3-unit flights and 2.1-unit turn landings allow the capsule along a scripted centerline but offer poor steering/camera space. Default camera at the upper landing contracts to **1.08** world units versus the requested 6.5. Previous centerline tests did not certify normal third-person usability.
2. **P1 — stair surfaces:** thin, separated tread boards expose the opposing flight and undersides. Rotated solid guards extend beyond flight ends into the turn zone. The enclosure/low turnaround ceiling confines camera and obscures signs.
3. **P1 — facade layering:** the generic runtime facade adds opaque blue window plates on top of broad transparent prefab window strips. Interior headers/signs remain visible around those plates, producing a patchwork exterior.
4. **P2 — duplicated identity:** prefab and runtime passes both add crosses, signage and entrance canopies. The roof crown competes with the retained helipad and gives the facade an oversized top ornament.
5. **P2 — unfinished surfaces:** large transparent side strips lack solid piers; the retained annex is an unarticulated blank box. Stair gaps and small landing connections make the interior appear unfinished.

## Repair plan

1. Retain the approved room program, front entrance, elevator, hospital envelope,
   learning content, bed asset and helicopter systems.
2. Replace switchbacks with a wider straight flight rising across the existing
   middle-left bay into the annex. Provide front and rear hallway access on each
   floor, broad landing areas, a return route through the annex, continuous solid
   stair surfaces and shorter rail ends. No footprint expansion or player shrink.
3. Use a single hospital facade owner: actual wall openings and framed windows,
   one entrance sign/canopy, a restrained cross below roof level, and matching
   annex windows. Remove competing generic hospital decoration.
4. Test the normal player movement/camera, off-center routes, both stair access
   routes and ascent/descent; rerun elevator, learning and helicopter regression
   checks. Inspect matching full-geometry views, not only cutaways.
5. Record measured results and before/after screenshots; update the current
   hospital guide and authoritative design/verification records.

## Completed repairs

- Replaced the 3-unit switchbacks with 4.2-unit straight flights, 28 closed treads,
  continuous sloped collision and slim rails. Rise/run: 5.6/8.4, incline 33.69°.
- Added front and rear hall approaches to the stairs on every floor, connected by
  the existing annex gallery. The enlarged route stays inside the existing envelope.
- Removed competing facade window plates, canopies and roof ornament. Added solid
  window piers, consistent frames, annex windows, and sealed floor seams.
- Retained room purposes, vocabulary, elevator mechanics and rooftop helicopter.
- Updated the generator, scene, facade ownership, tests and current design guides.
  The newer request explicitly supersedes the earlier compact-switchback requirement.


## Verification

Supersedes the earlier compact-switchback geometry and its centerline-only usability
evidence. Full Main inspected in graphical Godot 4.7.2, Compatibility, with isolated
learner saves. No world rebake or player-controller changes.

- Hospital route/elevator suite: **717 checks, 0 failures**.
- Normal W/controller stair access: **0 failures**, front/rear approaches on all
  three floors, offset ascent lanes and descent. Graphical default pitch -0.22:
  672 flight samples, spring-arm minimum 2.0703 and median 5.9236 world units
  (requested distance 6.5). A second pitch -0.35 run also passed.
- Learning wing: **24 displays, 0 failures**, passages, picking and cards.
- Runtime resources: **310 checked, 0 failures**.
- Interaction fixture: PASS targeting, highlights, cards, signals, doors, dismissal/range.
- Helicopter physics: **34 checks, 0 failures**.
- Final cutaway capture: 23 setup checks, 0 failures; visually reviewed floors 1–3.
- Reviewed full-geometry front, side, rear, hall, stairs, and normal player views.
  Final annex bands close the exterior seams that exposed rail fragments.

Limits: camera collision still retracts at nearby walls; the stationary upper-landing
view measures 2.0549 vs 1.0824 at the former switchback landing. These are different
landing geometries, not a claim that every possible camera orbit is unobstructed.
One earlier input run lost movement after another Godot window was launched; isolated
graphical reruns passed. Run input tests without a competing focused Godot window.
Sandboxed headless logs contain environment log-directory/certificate warnings.
The broad legacy regex `check_project.py` is **not clean**: 3,013 diagnostics in the
pre-screenshot-copy run, including generated output-path prefixes and legacy saved
scene parent/load-step checks. They are not equivalent to runtime load failures;
this repair does not certify or repair that whole-project checker.


## Screenshots

| View | Before | After |
| --- | --- | --- |
| Exterior | [Before](hospital-front-left-before.png) | [After](hospital-front-left-after.png) |
| Stair enclosure | [Before](hospital-stair-room-before.png) | [After](hospital-stair-room-after.png) |
| Player landing | [Before](hospital-player-landing-before.png) | [After](hospital-player-landing-after.png) |

[Normal ascent](hospital-player-ascent1-after.png) · [Upper arrival](hospital-player-arrival3-after.png)

Updated floor cutaways: [Floor 1](floor1.png) · [Floor 2](floor2.png) · [Floor 3](floor3.png).
Cutaways hide upper geometry and use English annotations for review; game signs remain Spanish.
All images are Godot renders of actual Main, not generated mockups.
