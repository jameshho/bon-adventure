extends SceneTree
## Renders signs with Chinese as the native language and Spanish as the foreign one, before and
## while holding L (9 Nov 2026). Graphics required, isolated HOME (removes user://settings.json):
## HOME=<scratch>/home VT_FOCUS="hospital, school, supermarket" VT_SPAWN=none godot --path . --resolution 1600x1000 --script res://docs/evidence/signs-20261109/capture.gd
## Writes <view>-es.png and <view>-zh-peek.png next to this script.
const GameSettings := preload("res://scripts/core/game_settings.gd")
func _initialize(): run.call_deferred()

func shot(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/signs-20261109/" + name + ".png")

## A camera `distance` in front of the first sign label whose source text is `source`.
func aim(camera: Camera3D, source: String, distance: float) -> bool:
	for label in get_nodes_in_group("translated_signs"):
		if label.get_meta("sign_source") == source and label.is_visible_in_tree():
			camera.global_position = label.global_position + label.global_basis.z.normalized() * distance
			camera.look_at(label.global_position, Vector3.UP)
			return true
	print("not found: " + source)
	return false

func run():
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	await process_frame
	var settings = GameSettings.shared()
	settings.set_languages("zh", "es")
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	for view in [["supermarket", "SUPERMARKET", 6.0], ["hospital-directory", "PLANTA 1\n1 · RECEPCIÓN  ·  2 · URGENCIAS\n3 · EXÁMENES  ·  SALA DE ESPERA", 3.0], ["school-poster", "today", 2.6]]:
		if not aim(camera, view[1], view[2]):
			continue
		settings.set_peek(false)
		await shot(view[0] + "-es")
		# The HUD ends a peek with nothing held; hold the button for the shot.
		var button: Button = game.hud.peek_button
		button.button_down.emit()
		game.hud.set_process(false)
		await shot(view[0] + "-zh-peek")
		game.hud.set_process(true)
		button.button_up.emit()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	print("SIGN CAPTURE done")
	quit()
