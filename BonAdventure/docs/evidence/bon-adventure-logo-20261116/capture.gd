extends SceneTree
## Rendered title page with the Bon Adventure logo (16 Nov 2026) at laptop and landscape-phone
## sizes: title_<w>x<h>.png in this folder (overwritten). Draws only the screens before the town
## (no profiles are made or read). Needs graphics:
## godot --path . --resolution 1280x720 --script res://docs/evidence/bon-adventure-logo-20261116/capture.gd
const AppScreens := preload("res://scripts/ui/app_screens.gd")
const OUT := "res://docs/evidence/bon-adventure-logo-20261116/"
## Laptop windows, then phones held sideways (CSS pixels and device pixels of an 844 x 390 phone).
const SIZES := [Vector2i(1280, 720), Vector2i(1440, 900), Vector2i(1100, 620), Vector2i(844, 390), Vector2i(667, 375), Vector2i(2532, 1170)]

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var screens = AppScreens.new()
	layer.add_child(screens)
	screens.show_splash()
	for size in SIZES:
		root.size = size
		for i in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		var name := "title_%dx%d" % [size.x, size.y]
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
		print("captured ", name, " ", root.get_texture().get_image().get_size())
	quit(0)
