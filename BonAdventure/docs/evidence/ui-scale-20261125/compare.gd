extends SceneTree
## Compares two capture.gd folders pixel for pixel (25 Nov 2026, UI-01): for each PNG in A, the
## number of differing pixels in B and their bounding box. Writes nothing.
##   godot --headless --path . --script res://docs/evidence/ui-scale-20261125/compare.gd -- before-1280x800 after-1280x800
const BASE := "res://docs/evidence/ui-scale-20261125/"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var a := ProjectSettings.globalize_path(BASE + args[0] + "/")
	var b := ProjectSettings.globalize_path(BASE + args[1] + "/")
	var same := 0
	var total := 0
	for file in DirAccess.get_files_at(a):
		if not file.ends_with(".png"):
			continue
		total += 1
		var one := Image.load_from_file(a + file)
		var two := Image.load_from_file(b + file) if FileAccess.file_exists(b + file) else null
		if two == null or one.get_size() != two.get_size():
			print("%-22s MISSING or other size" % file)
			continue
		var diff := 0
		var box := Rect2i()
		for y in one.get_height():
			for x in one.get_width():
				if one.get_pixel(x, y) != two.get_pixel(x, y):
					diff += 1
					box = Rect2i(x, y, 1, 1) if diff == 1 else box.expand(Vector2i(x, y))
		if diff == 0:
			same += 1
			print("%-22s identical" % file)
		else:
			print("%-22s %d pixels differ in %s" % [file, diff, str(box)])
	print("COMPARE %s vs %s: %d of %d identical" % [args[0], args[1], same, total])
	quit(0)
