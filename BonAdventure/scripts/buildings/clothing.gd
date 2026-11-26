extends RefCounted
## Clothing store own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## clothing unit (scenes/town/clothing.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- clothing
## Never rename or remove a baked step (add a new one that undoes it).
const STEPS := ["coplanar_gaps", "coplanar_gaps_2", "glass_windows", "shop_row_style", "palette_snap"]

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "clothing")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "clothing", 2)


## Window glass as the shared window component (12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate(town, "clothing")


## Game palette and shop row (user, 18 Nov 2026; docs/guides/TOWN_DESIGN_BRIEF.md "Game palette and
## shop row"): the storefront recoloured by role from scripts/core/game_palette.gd, accent "rose".
func shop_row_style(town: Node3D, game) -> void:
	var ShopRow := preload("res://scripts/buildings/shop_row.gd")
	print("shop_row clothing: ", ShopRow.restyle(town, game, "clothing"))


## Colours snapped to the game palette with the hue guard (P3-22, decision D14: approved by the
## user 26 Nov 2026 after the library/police trial; scripts/buildings/palette_snap.gd,
## docs/evidence/pastel-20261125/).
func palette_snap(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/palette_snap.gd").snap(town, "clothing")
