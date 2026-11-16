# Windows — shared glass component

User request, 12 November 2026: one reusable window with soft blue-gray, semi-transparent glass
in every building, performance first (web build), a cheaper fallback, and no redesign of the
buildings. Results: [verification record](FINAL_VERIFICATION.md#shared-glass-windows--12-november-2026).

## Files

| Piece | File |
| --- | --- |
| Window scene (drop into a wall opening) | `scenes/props/window.tscn` (root `Node3D`, script below; nothing else is saved) |
| Script: exports, builds the glass and frame at load | `scripts/world/glass_window.gd` |
| Shared glass (transparent, the default) | `materials/glass/window_glass.tres`, a `ShaderMaterial` with `materials/glass/window_glass.gdshader` (13 Nov 2026): one sheet, both faces drawn. Room face (and both faces when the window has no `outside`): `(0.66, 0.78, 0.86)`, alpha 0.30, slight reflection. Outdoors face: `(0.17, 0.20, 0.22)`, alpha 0.80, reflects a faked sky/ground gradient, more at grazing angles. No received shadows |
| Shared opaque glass (fallback, and panes on a wall) | `materials/glass/window_glass_opaque.tres`: `(0.45, 0.56, 0.63)`, opaque |
| Shared frame | `materials/glass/window_frame.tres` |
| Migration of the 13 buildings (bake step `glass_windows`; airport, warehouse and restaurants also `glass_windows_2`) | `scripts/buildings/glass_windows.gd` (`PANES`, `SEE_THROUGH`, `migrate()`; `migrate_leftovers()` for auto-named transparent panes; `replace()`) |
| Views and draw calls | `docs/evidence/windows-20261112/capture.gd` (sheets `<unit>.png` in that folder) |

The `.tscn` file is in snake case like the other prefabs (`electrical_box.tscn`). It is not
called `Window.tscn` because `Window` is a built-in Godot class.

## Using it

Instance `scenes/props/window.tscn` in the wall opening. Its origin is the centre of the pane,
the glass lies in the local XY plane and its thickness runs along Z. Sizes are in town units
(Apartment scale 1.3). Exports:

| Export | Default | Meaning |
| --- | --- | --- |
| `width`, `height`, `thickness` | 1.2, 1.4, 0.04 | pane size |
| `shape` | `RECT` | `ARCH` adds a half disc of radius `width / 2` on top (Alta Cocina) |
| `tint`, `transparency` | shared values | the room-side look (both sides when `outside` is `NONE`). A window that keeps the defaults uses the shared `.tres`; other looks are cached, one material per look (never one per window) |
| `outside` | `NONE` | which face looks outdoors: `FRONT` (+Z) or `BACK` (−Z). That face is drawn darker and more reflective |
| `outside_tint`, `outside_transparency` | `(0.17, 0.20, 0.22)`, 0.2 | the outdoors look. With `see_through` false or the opaque mode, an opaque window uses this tint when `outside` is set |
| `see_through` | true | false = this pane uses the shared opaque glass (its glass sits on a wall) |
| `frame_visible`, `frame_width`, `frame_depth`, `frame_color` | false, 0.08, 0.1, white | optional frame of four bars (eight short bars along an arch). Migrated windows keep their existing frames, so theirs stays off |

The window has no collision. Put a `StaticBody3D` beside it, or under it as the migration does,
when the opening must block. It joins the group `glass_windows`. In a building script step, use
`GlassWindows.replace(mesh, see_through)` to turn an existing box pane into a window, or add the
scene yourself. The bake strips the parts the script builds (`tools/bake_unit.gd`, "window parts"),
so a unit scene stores only the window root and its exports.

## Performance design

- **One material, one mesh.** Every see-through pane is the same unit `QuadMesh` (two
  triangles; an arch adds one flat half disc), scaled by its node, with the same material.
  `render_culling.gd` therefore merges all panes of a 24 m cell into one MultiMesh draw. Opaque
  panes are unit `BoxMesh`es that merge with the rest of the opaque town.
- **One sheet, two looks (13 Nov 2026).** The sheet has `cull_disabled`; the shader picks the look
  from `FRONT_FACING`, so the inside and the outdoors look cost no extra mesh, draw or pass.
  Windows with different outdoors sides use separate cached materials (`outside_face` uniform).
- **Transparency without sorting artifacts.** Panes with the same look have the same colour and
  alpha. Within one batch, the order of two overlapping panes does not change the result, and
  the glass writes no depth.
- **Cheap reflections.** The glass casts no shadow (sunlight reaches the rooms) and receives
  none. Its "reflection" is a sky/ground colour gradient chosen by the reflected view direction
  and lit like the rest of the surface (it dims at night): no screen texture, reflection probe,
  refraction or per-frame code. It uses only built-ins of the Compatibility renderer (web).
- **Opaque where nothing is behind.** 46 of the 84 panes sit directly on a wall (see below),
  so they stay in the opaque pass. Only the 38 real openings pay for transparency.
- **Fallback:** set the project setting `vocabulary_town/rendering/glass_mode` to `"opaque"`
  (in `project.godot`, or before Main loads). It is read when each window loads, and every window
  then uses `window_glass_opaque.tres`: no transparent pass at all, and the old tinted look.
  It is not switchable while the game runs.

## The 13 buildings (84 windows)

Views of every window from both sides at noon and 21:00 are in `docs/evidence/windows-20261112/`.

**See-through (38): a room or the outdoors is really behind the glass.** Airport terminal gate
glass (3 panes); the control tower's 11 stair-shaft and room windows, the cabin glass on all four
sides and the deck door glass (tower deck, 12 Nov 2026). Warehouse
reception windows (2) and glass entrance door. Electronics and
clothing store side windows (4 each). Alta Cocina's two arched windows: real openings since 12 Nov 2026
(below). Pizza y Hamburguesas front glass (two panes), east glass and both glass
door leaves.

**Opaque (46): the glass sits on a solid surface.** Every storefront facade (`Map facades/*`:
airport, school, sports, café, electronics, bank, library, Alta Cocina, taquería, police,
supermarket, clothing) stands in front of the building's front wall. The old bank, library,
police and supermarket windows sit in front of interior wall linings. The 14 barn windows sit on
the barn walls. The Alta Cocina kitchen window, the burger back-door window, the airport
boarding-door window and the warehouse hall-door window sit on walls or door leaves. Made
see-through, these showed a blank wall, so they use the shared opaque glass. They still use the
same component and tint.

**Alta Cocina — real arched windows (user, 12 Nov 2026: "i like the black", then "i want real
window").** Until then the facade's dark glass sat on the solid front wall, and inside a painted
view (lawn, river, bridge, towers, tree) hung behind clear glass. Restaurant steps
`fine_dining_real_windows`, `_2` and `_3` (the first two bakes stopped partway; the code says what
each did) now:
- cut both arched holes (x ±6.5..±10.5, y 0.6..3.9 plus a half disc of radius 2) through the front
  wall and its lining, as baked CSG meshes. The wall collision is unchanged, so the glass blocks;
- remove the painted view;
- one glass sheet per window since 13 Nov 2026 (steps `fine_dining_single_glass` and `_2`; the 12
  Nov one-way pair of layers is gone): the facade pane (z −8.1) has `outside = FRONT` (toward the
  street) with the dark outdoors look, and the shared clear look toward the room. The room-side
  panes were removed; their frames stay. In the opaque `glass_mode` the pane is solid dark.
Both window frames (facade and room) are visible through the glass from either side.
Views (street, room, close-up, street at an angle, noon and 21:00, plus an ordinary electronics
window from both sides): `docs/evidence/fine-dining-glass-20261112/` (`capture.gd`). The earlier steps
`fine_dining_dark_glass` and `_2` (dark opaque facade pane) are superseded by these.

**Other see-through windows** keep `outside = NONE` (same light look from both sides), because
which side is outdoors has not been set for them. Setting it per window (37 panes) is an open
follow-up.

Left as they were (not window glass): emissive "Window light" and cell-window light panels
(police, bank), the warehouse's frosted clerestory strips (lit panels on both faces of a solid
wall), the police lineup's one-way glass (a game element), display-case and fridge glass,
vehicles and products.

**Open issue (needs a user decision, not done):** seeing into the bank, library, police,
supermarket, school, sports, café, barn and the restaurant facades would need openings cut in
the walls and linings behind those panes. That changes building structures and interiors, so
it is a separate design task.
