extends SceneTree
## Rendered views after the BonBon rename (16 Nov 2026): the title page, the avatar
## picker (BonBon picked by default), "Pick your character" with a profile saved before the
## rename (an avatar id that is no longer a house character, shown as BonBon), BonBon at the default spawn (the supermarket entrance when no place is saved) and the fitting-room outfit
## picker ("BonBon's own look"). Overwrites the PNGs in this folder. Needs graphics, the whole
## town and an isolated HOME (it creates a profile):
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1280x720 --script res://docs/evidence/bonbon-rename-20261116/capture.gd
const AppScreens := preload("res://scripts/ui/app_screens.gd")
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const BoothScript := preload("res://scripts/world/fitting_booth.gd")
const OUT := "res://docs/evidence/bonbon-rename-20261116/"

func _initialize() -> void:
	run.call_deferred()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func shot(name: String) -> void:
	await frames(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("captured ", name)

func run() -> void:
	if FileAccess.file_exists("user://profiles/index.json"):
		print("capture: refusing to run, profiles exist (use an isolated HOME)")
		quit(1)
		return
	# A profile list written before the rename.
	SaveStore.write_json("user://profiles/index.json", {"schema": 1, "next": 2, "last": "p1",
		"profiles": [{"id": "p1", "name": "Ana", "profile_name": "Ana", "avatar": "old_pig"}]})
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var screens = AppScreens.new()
	layer.add_child(screens)
	screens.show_splash()
	await shot("title")
	screens.show_profiles()
	await shot("profiles_old_save")
	screens.show_new_profile()
	await shot("avatar_picker")
	layer.queue_free()
	SaveStore.remove_tree("user://profiles")
	ProfileManager._shared = null

	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(30)
	var model: Node3D = game.player.get_node("Visual/BonBon")
	print("player node: ", game.player.name, " model: ", model.name, " ", model.get_meta("display_name", ""))
	await frames(90)
	await shot("bonbon_spawn")

	var booth: Node3D
	for node in game.apartment.find_children("*", "Node3D", true, false):
		if node.get_script() == BoothScript:
			booth = node
			break
	var seat: Dictionary = {}
	if booth != null:
		for s in game.seating.seats:
			if s.node == booth.pouf:
				seat = s
	if seat.is_empty():
		print("capture: no fitting cabin seat found")
		quit(1)
		return
	game.player.global_position = seat.point + seat.forward * 0.9
	game.player.velocity = Vector3.ZERO
	await frames(4)
	game.interaction.activate_focus()
	for i in 240:
		await process_frame
		if booth.active: break
	await frames(90)
	await shot("outfit_picker")
	quit(0)
