extends SceneTree
## Side-by-side before | after pictures of the light veil (25 Nov 2026, P3-15): for each name,
## veil-before-1280x800/<name>.png and veil-after-1280x800/<name>.png at half size, saved as
## veil-<name>.png here. godot --headless --path . --script res://docs/evidence/ui-scale-20261125/pair.gd
const BASE := "res://docs/evidence/ui-scale-20261125/"

func _initialize() -> void:
	for name in ["hud-card", "settings", "map", "passport"]:
		var a := Image.load_from_file(ProjectSettings.globalize_path(BASE + "veil-before-1280x800/" + name + ".png"))
		var b := Image.load_from_file(ProjectSettings.globalize_path(BASE + "veil-after-1280x800/" + name + ".png"))
		for im in [a, b]:
			im.convert(Image.FORMAT_RGB8)
			im.resize(im.get_width() / 2, im.get_height() / 2, Image.INTERPOLATE_LANCZOS)
		var out := Image.create(a.get_width() * 2 + 8, a.get_height(), false, Image.FORMAT_RGB8)
		out.fill(Color.WHITE)
		out.blit_rect(a, Rect2i(Vector2i.ZERO, a.get_size()), Vector2i.ZERO)
		out.blit_rect(b, Rect2i(Vector2i.ZERO, b.get_size()), Vector2i(a.get_width() + 8, 0))
		out.save_png(ProjectSettings.globalize_path(BASE + "veil-" + name + ".png"))
	print("PAIRS: done")
	quit(0)
