extends SceneTree
## Renders the minigame test launcher and the supermarket cashier's gold "!" (9 Nov 2026,
## docs/guides/MINIGAMES.md#test-launcher). Needs graphics (not --headless) and an isolated HOME:
## HOME=<scratch>/home godot --path . --resolution 1280x800 --script res://docs/evidence/minigame-launcher-20261109/capture.gd
const Board := preload("res://scripts/learning/activity_board.gd")
const OUT := "res://docs/evidence/minigame-launcher-20261109/"

func _initialize(): run.call_deferred()

func shot(file: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + file))
	print("saved " + file)

func run():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 30:
		await process_frame
	# The cashier calling from behind the till.
	var cashier = Board.shared().session("cashier_supermarket")
	cashier.offered = true
	var npc: Node3D = cashier.cashier
	var forward := -npc.global_basis.z
	forward.y = 0.0
	game.player.global_position = npc.global_position + forward.normalized() * 4.0 + Vector3(0, .1, 0)
	var look: Vector3 = npc.global_position - game.player.global_position
	game.player.rotation.y = atan2(-look.x, -look.z)
	game.player.camera_yaw = game.player.rotation.y
	game.player.reset_camera()
	await create_timer(1.0).timeout
	await shot("cashier-calling.png")
	# The launcher window, with one game's rounds changed.
	game.game_launcher.open()
	game.game_launcher._step("warehouse_ramon", 1)
	await shot("launcher.png")
	game.game_launcher.close()
	await shot("corner-button.png")
	quit(0)
