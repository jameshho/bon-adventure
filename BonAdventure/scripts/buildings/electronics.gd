extends RefCounted
## Electronics store own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## electronics unit (scenes/town/electronics.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- electronics
## Never rename or remove a baked step (add a new one that undoes it).
const STEPS := ["coplanar_gaps", "coplanar_gaps_2", "glass_windows", "shop_row_style", "clay_makeover", "bigger_products"]

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "electronics")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "electronics", 2)


## Window glass as the shared window component (12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate(town, "electronics")


## Game palette and shop row (user, 18 Nov 2026; docs/guides/TOWN_DESIGN_BRIEF.md "Game palette and
## shop row"): the storefront recoloured by role from scripts/core/game_palette.gd, accent "sky".
func shop_row_style(town: Node3D, game) -> void:
	var ShopRow := preload("res://scripts/buildings/shop_row.gd")
	print("shop_row electronics: ", ShopRow.restyle(town, game, "electronics"))


## Clay makeover (user, 18 Nov 2026: the store "needs a huge makeover"; design approved in chat;
## docs/guides/TOWN_DESIGN_BRIEF.md "Electronics store makeover — 18 November 2026"): the room
## rebuilt in the game palette with clay-like products, lit screens, six world signs, no prices,
## a plush clerk and a spot kept for a clerk minigame (scripts/buildings/electronics_makeover.gd).
func clay_makeover(town: Node3D, game) -> void:
	preload("res://scripts/buildings/electronics_makeover.gd").new().build(town, game)


## Small products 20% bigger and the small appliances as words (user, 23 Nov 2026: "make all the
## small items/products 20% bigger", keep the design; the rice cookers, toasters and blenders were
## not words): scripts/buildings/electronics_makeover.gd bigger(). Record:
## docs/guides/TOWN_DESIGN_BRIEF.md "Electronics store makeover", 23 Nov 2026 addendum.
func bigger_products(town: Node3D, _game) -> void:
	print("electronics bigger_products: ", preload("res://scripts/buildings/electronics_makeover.gd").new().bigger(town))
