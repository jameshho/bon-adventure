extends SceneTree
## The user's blueprint (top row) against the model (bottom row) for the eye (front 3/4, front,
## side) and the ear seen from the front, at the same scale: detail-comparison.png. Uses
## eye-close.png and ear.png from capture.gd.
##   godot --headless --path . --script res://docs/evidence/golden-retriever-clay-20261111/detail_compare.gd -- <blueprint image>
const DIR := "res://docs/evidence/golden-retriever-clay-20261111/"
const CW := 480
const CH := 450

func _initialize() -> void:
	var sheet := Image.load_from_file(OS.get_cmdline_user_args()[0])
	sheet.convert(Image.FORMAT_RGBA8)
	var eyes := Image.load_from_file(ProjectSettings.globalize_path(DIR + "eye-close.png"))
	var ear := Image.load_from_file(ProjectSettings.globalize_path(DIR + "ear.png"))
	eyes.convert(Image.FORMAT_RGBA8)
	ear.convert(Image.FORMAT_RGBA8)
	var out := Image.create(CW * 4, CH * 2, false, Image.FORMAT_RGBA8)
	# [blueprint centre x, y, blueprint px across the cell, model image, model panel]
	var cells := [[127.0, 395.5, 42.4, eyes, 0], [492.5, 395.5, 42.4, eyes, 1], [666.0, 395.5, 42.4, eyes, 2], [530.2, 417.6, 160.0, ear, 0]]
	for i in cells.size():
		var c: Array = cells[i]
		var w: float = c[2]
		var h := w * CH / CW
		var crop := sheet.get_region(Rect2i(int(c[0] - w * 0.5), int(c[1] - h * 0.5), int(w), int(h)))
		crop.resize(CW, CH, Image.INTERPOLATE_CUBIC)
		out.blit_rect(crop, Rect2i(0, 0, CW, CH), Vector2i(i * CW, 0))
		var mine: Image = (c[3] as Image).get_region(Rect2i(int(c[4]) * 640, 0, 640, 600))
		mine.resize(CW, CH, Image.INTERPOLATE_LANCZOS)
		out.blit_rect(mine, Rect2i(0, 0, CW, CH), Vector2i(i * CW, CH))
	out.save_png(DIR + "detail-comparison.png")
	quit()
