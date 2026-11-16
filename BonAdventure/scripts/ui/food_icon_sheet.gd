extends Control
## Draws a grid of cells (each {"art": …} or {"property": id}) on card-coloured squares.
## Own file since 6 Nov 2026 (was food_icons.gd's inner class), so the modular town can save
## the restaurant posters; food_icons.gd sheet() builds it.
@export var cells: Array = []
@export var cell := 128
@export var columns := 8
@export var paper := Color("fffaf0")

func _draw() -> void:
	var FoodIcons = load("res://scripts/ui/food_icons.gd")
	for i in cells.size():
		var at := Vector2((i % columns) * cell, int(i / columns) * cell)
		draw_rect(Rect2(at, Vector2(cell, cell)), paper)
		var box := Rect2(at + Vector2(cell, cell) * .08, Vector2(cell, cell) * .84)
		var entry: Dictionary = cells[i]
		if entry.has("art"):
			FoodIcons.draw_dish(self, entry.art, box)
		else:
			FoodIcons.draw_property(self, str(entry.property), box)
