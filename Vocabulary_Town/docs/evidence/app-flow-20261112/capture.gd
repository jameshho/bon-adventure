extends SceneTree
## Rendered views of the screens before the town (PWA phase 3, 12 Nov 2026): splash, avatar
## picker, languages (also languages_picked: Chinese picked to learn), "Pick your character"
## with two profiles, the delete question and the loading screen; since 14 Nov 2026 the
## language page also at landscape-phone size (languages_phone, 844 x 390). (names.png is the
## removed name page, 12 Nov 2026.) Overwrites the PNGs in this folder. Needs graphics and an
## isolated HOME (it creates profiles):
## HOME=<scratch>/home godot --path . --resolution 1280x720 --script res://docs/evidence/app-flow-20261112/capture.gd
const AppScreens := preload("res://scripts/ui/app_screens.gd")
const LoadingScreen := preload("res://scripts/ui/loading_screen.gd")
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const OUT := "res://docs/evidence/app-flow-20261112/"

func _initialize() -> void:
	run.call_deferred()

func shot(name: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("captured ", name)

func run() -> void:
	if FileAccess.file_exists("user://profiles/index.json"):
		print("capture: refusing to run, profiles exist (use an isolated HOME)")
		quit(1)
		return
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var screens = AppScreens.new()
	layer.add_child(screens)
	screens.show_splash()
	await shot("splash")
	screens.show_new_profile()
	screens._draft.avatar = "sunny"
	screens._show("avatar")
	await shot("avatar")
	screens._show("languages")
	print("new profile languages: ", screens._draft.native, " -> ", screens._draft.foreign)
	await shot("languages")
	screens._pick_language("foreign", "zh")
	await shot("languages_picked")
	var laptop := root.size
	root.size = Vector2i(844, 390)
	screens._pick_language("foreign", "es")
	await shot("languages_phone")
	root.size = laptop
	var manager = ProfileManager.shared()
	manager.create("Ana", "Ana", "sunny")
	manager.create("Ben", "Benji", "cocodrilo")
	screens.show_profiles()
	await shot("profiles")
	screens._delete_id = "p2"
	screens._show("delete")
	await shot("delete")
	layer.queue_free()
	var loading = LoadingScreen.new()
	root.add_child(loading)
	loading.set_progress(0.45)
	for i in 120:
		await process_frame
	await shot("loading")
	SaveStore.remove_tree("user://profiles")
	quit(0)
