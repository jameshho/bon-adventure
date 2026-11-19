extends SceneTree
## Rendered views of the UI art style on the mahjong panel and the electrical box (user, 18 Nov
## 2026; docs/guides/UI_STYLE.md, the money panel's pattern): a mahjong turn with a Pung call, the
## Mahjong! offer and the result card (sample data on the panel, at the home), then the electrical
## box's wire screen and its "Repaired!" pill. Overwrites the PNGs it names in this folder. Needs
## graphics and an isolated HOME:
## HOME=<scratch>/home VT_FOCUS=home VT_SPAWN=none godot --path . --resolution 1280x720 --script res://docs/evidence/ui-style-20261118/capture_games.gd
const OUT := "res://docs/evidence/ui-style-20261118/"
const Session := preload("res://scripts/learning/electrical_box_session.gd")

func _initialize() -> void:
	run.call_deferred()

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func shot(name: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("captured ", name)

func line(foreign: String, native: String) -> Dictionary:
	return {"foreign": foreign, "native": native}

func run() -> void:
	if DisplayServer.get_name() == "headless" or FileAccess.file_exists("user://profiles/index.json"):
		print("capture: needs graphics and an isolated HOME")
		quit(1)
		return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 30:
		await process_frame
	if game.day_night != null:
		game.day_night.set_time(10.5 * 60.0)
		game.day_night.pause()
	# Mahjong panel with sample data (the session needs the whole table flow).
	game.hud.in_minigame = true
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var mahjong = preload("res://scripts/ui/mahjong_panel.gd").new()
	layer.add_child(mahjong)
	mahjong.letters = ["E", "S", "W", "N"]
	mahjong.open()
	mahjong.set_info([line("Juego de 3 fan", "3-fan game"), line("Tu viento: Este", "Your wind: East")], [-1, 27])
	mahjong.set_scores([{"name": line("Tú", "You"), "face": "pig", "total": 12, "change": ""}])
	mahjong.set_hand([0, 1, 2, 4, 4, 9, 10, 11, 18, 18, 27, 27, 31], -1, false)
	mahjong.set_actions([{"id": "pung", "label": line("Pung", "Pung"), "data": 4, "tiles": [4, 4, 4]}, {"id": "pass", "label": line("Pasar", "Pass")}])
	await shot("panel_mahjong")
	mahjong.set_actions([{"id": "win", "label": line("¡Mahjong!", "Mahjong!"), "worth": line("Vale 4 fan", "Worth 4 fan")}, {"id": "keep", "label": line("Seguir jugando", "Keep playing")}])
	await shot("panel_mahjong_win")
	mahjong.show_result({"title": line("¡Ganaste!", "You win!"), "lines": [line("Del muro", "From the wall"), line("Todo pung: 3 fan", "All pungs: 3 fan")], "total": line("Total: 4 fan", "Total: 4 fan"),
		"scores": [{"name": line("Tú", "You"), "face": "pig", "total": "+16", "change": "+16"}, {"name": line("Mei", "Mei"), "face": "cat", "total": "-8", "change": "-8"}]},
		line("Otra vez", "Play again"), line("Salir", "Leave"))
	await shot("panel_mahjong_result")
	mahjong.queue_free()
	game.hud.in_minigame = false
	# Electrical box at the home garage.
	var box: Node3D = game.apartment.get_node_or_null("RelocatedSites/Home/Electrical box")
	if box != null:
		var f: Vector3 = box.facing()
		game.player.global_position = box.front_center() + f * 2.0 - Vector3(0, 1.5, 0)
		game.player.velocity = Vector3.ZERO
		await wait(0.5)
		box.use()
		await wait(Session.ZOOM_SECONDS + 0.5)
		await shot("panel_electrical")
		var panel = game.electrical_box_panel
		for i in panel.wires.size():
			panel.drop_on_row(i, panel.wires[i].right)
		await wait(0.5)
		await shot("panel_electrical_done")
	print("UI STYLE GAMES CAPTURE done")
	quit(0)
