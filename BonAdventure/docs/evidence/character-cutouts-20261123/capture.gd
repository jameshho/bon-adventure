extends SceneTree
## Rendered views of the character picker after the 8 headshots were cut straight from the
## user's mockup (23 Nov 2026; assets/ui/avatars/source/cut_headshots.py): the character grid
## (also in a 1700 x 950 window) and the saved players. Overwrites the PNGs in this folder. Needs graphics and an isolated HOME
## (it creates a profile):
## HOME=<scratch>/home godot --path . --resolution 1280x720 --script res://docs/evidence/character-cutouts-20261123/capture.gd
const AppScreens := preload("res://scripts/ui/app_screens.gd")
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const CjkFont := preload("res://scripts/ui/cjk_font.gd")
const OUT := "res://docs/evidence/character-cutouts-20261123/"

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
	await shot("avatar")
	# A large window (the user's resize report, 23 Nov 2026): the portraits stay smooth.
	DisplayServer.window_set_size(Vector2i(1700, 950))
	await shot("avatar_large")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var manager = ProfileManager.shared()
	for avatar in ["leo", "miso", "cocodrilo"]:
		manager.create(avatar.capitalize(), avatar.capitalize(), avatar)
	GameSettings.shared().set_languages("en", "es")
	screens.show_profiles()
	await shot("profiles")
	quit(0)
