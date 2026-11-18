# Shared meshes — 17 November 2026

Results and what was shared: [GPU memory on the web](../../guides/performance/README.md#gpu-memory-on-the-web--14-november-2026).

- `measure.gd`: video memory and mesh bytes of the full town (Low, 1280×800), byte-identical copies
  by owner. Before = the scenes from before the re-bake with `VT_MESH_SHARE=0`; after = the
  current scenes. Both measured natively on an Apple M5 in a scratch copy of the project with the
  committed `render_culling.gd` (another session's uncommitted batching/MSAA change was in the
  checkout at the time and printed script errors). Not measured on a phone or in a browser.
- `capture.gd`: the views here (camera placed in front of each target; the player is hidden):
  `same-kind-*.png` (two cats and two beagles in different rooms that share one torso mesh;
  the beagle waiter's view also shows the beagle bartender behind), `costume-*.png` (shared
  garments: pilot, chef, cashier), `mystery-mysterydoor-*.png` (Mystery House doors and trim from
  the re-baked `mystery.scn`). Inspected: faces, eyes, colour points and costumes look as before.
