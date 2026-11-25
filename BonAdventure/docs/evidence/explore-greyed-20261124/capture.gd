extends SceneTree
## The language page with Just explore! off and on (user, 24 Nov 2026: "I want to learn" is
## greyed out while exploring), and after tapping a greyed language (explore turns off).
## Needs graphics and an isolated HOME:
## HOME=<scratch>/home godot --path . --resolution 1280x720 --script res://docs/evidence/explore-greyed-20261124/capture.gd
const AppScreens := preload("res://scripts/ui/app_screens.gd")
const CjkFont := preload("res://scripts/ui/cjk_font.gd")
const OUT := "res://docs/evidence/explore-greyed-20261124/"

func _initialize() -> void:
	run.call_deferred()

func shot(name: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("captured ", name)

func run() -> void:
	if FileAccess.file_exists("user://profiles/index.json"):
		print("capture: refusing to run, profiles exist (use an isolated HOME)")
		quit(1)
		return
	CjkFont.install()
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var screens = AppScreens.new()
	layer.add_child(screens)
	screens.show_new_profile()
	screens._show("languages")
	await shot("languages_learn")
	screens._draft.explore = true
	screens._rebuild()
	await shot("languages_explore")
	screens._draft.explore = false
	screens._pick_language("foreign", "zh")
	print("explore after tapping a greyed language: ", screens._draft.get("explore"))
	await shot("languages_after_tap")
	quit(0)
