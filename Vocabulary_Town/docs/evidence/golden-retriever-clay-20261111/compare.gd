extends SceneTree
## Stacks the user's blueprint over turnaround.png for a side-by-side check (comparison.png).
##   godot --headless --path . --script res://docs/evidence/golden-retriever-clay-20261111/compare.gd -- <blueprint image>
func _initialize() -> void:
	var dir := "res://docs/evidence/golden-retriever-clay-20261111/"
	var sheet := Image.load_from_file(OS.get_cmdline_user_args()[0])
	sheet.convert(Image.FORMAT_RGBA8)
	sheet = sheet.get_region(Rect2i(0, 240, sheet.get_width(), 560))
	var mine := Image.load_from_file(ProjectSettings.globalize_path(dir + "turnaround.png"))
	mine.convert(Image.FORMAT_RGBA8)
	mine.resize(sheet.get_width(), mine.get_height() * sheet.get_width() / mine.get_width(), Image.INTERPOLATE_LANCZOS)
	var out := Image.create(sheet.get_width(), sheet.get_height() + mine.get_height(), false, Image.FORMAT_RGBA8)
	out.blit_rect(sheet, Rect2i(Vector2i.ZERO, sheet.get_size()), Vector2i.ZERO)
	out.blit_rect(mine, Rect2i(Vector2i.ZERO, mine.get_size()), Vector2i(0, sheet.get_height()))
	out.save_png(dir + "comparison.png")
	quit()
