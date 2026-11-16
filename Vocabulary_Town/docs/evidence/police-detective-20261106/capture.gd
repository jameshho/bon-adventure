extends SceneTree
## Rendered views of the enlarged police station and the two detective games (6 Nov 2026).
## Graphics required; isolated user directory (Main writes progress). Writes PNGs here.
## godot --path . --resolution 1280x800 --script res://docs/evidence/police-detective-20261106/capture.gd
const FOLDER := "res://docs/evidence/police-detective-20261106"

func _initialize() -> void:
	run.call_deferred()

func shot(title: String, frames := 10) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(FOLDER + "/" + title + ".png")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	var station: Node3D = game.apartment.get_node("RelocatedSites/Police")
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.fov = 60.0
	camera.far = 900.0
	camera.current = true
	game.hud.hide()
	# [name, eye, target] in design units (scripts/buildings/police.gd) (mirrored into the station).
	var Interior = preload("res://scripts/buildings/police.gd")
	for spec in [
		["exterior", Vector3(47, 16, 14), Vector3(43, 0, 44)],
		["exterior-rear", Vector3(30, 14, 72), Vector3(43, 2, 50)],
		["lobby", Vector3(43, 2.2, 38.4), Vector3(43, 1.2, 52)],
		["lobby-left", Vector3(48, 2.2, 39), Vector3(36, 1.2, 46)],
		["lineup-room", Vector3(47.5, 2.0, 50.5), Vector3(49.3, 1.0, 58.5)],
		["evidence-room", Vector3(38.6, 2.4, 46.3), Vector3(35, .8, 41)],
		["poster-appearance", Vector3(48.5, 2.0, 49), Vector3(48.5, 1.9, 52)],
	]:
		camera.global_position = station.to_global(Interior.mirror_point(spec[1]))
		camera.look_at(station.to_global(Interior.mirror_point(spec[2])))
		await shot(spec[0])
	# Plan: straight down with the roof hidden.
	var hidden: Array = []
	for node in station.find_children("*", "Node3D", true, false):
		var title := String(node.name).to_lower()
		if node is Node3D and (title.contains("roof") or title.contains("fascia") or title.contains("cornice") or title.contains("ceiling")):
			node.visible = false
			hidden.append(node)
	camera.global_position = station.to_global(Vector3(43, 40, 48.6))
	camera.look_at(station.to_global(Vector3(43, 0, 48.5)), station.global_basis * Vector3(0, 0, 1))
	camera.fov = 38.0
	# Batched meshes cannot be hidden: clip everything above room height instead.
	var world_scale: float = station.global_basis.get_scale().y
	camera.near = (40.0 - 3.2) * world_scale
	await shot("plan")
	camera.near = .05
	for node in hidden:
		node.visible = true
	camera.fov = 60.0
	# Posters seen from the lobby.
	for node in station.get_node("Interior").get_children():
		if String(node.name) == "Police poster evidence":
			var face: Vector3 = (node as Node3D).global_basis.z.normalized()
			camera.global_position = (node as Node3D).global_position - face * 2.6 + Vector3(0, .1, 0)
			camera.look_at((node as Node3D).global_position)
			await shot("poster-evidence")
	# The games, with the HUD and card.
	game.hud.show()
	var lineup = game.get_node("PoliceDetective_lineup")
	lineup.start_game()
	await shot("lineup-game", 60)
	lineup.select((int(lineup.round.target) + 1) % 5)
	lineup.accuse()
	await shot("lineup-wrong", 20)
	lineup.select(int(lineup.round.target))
	lineup.accuse()
	await shot("lineup-right", 20)
	# A close look at the suspects, the hover light under suspect 2, then the word summary.
	var stage: Node3D = station.find_child("LineupStage", true, false)
	lineup._camera.global_position = stage.to_global(Vector3(0, 1.6, -3.4))
	lineup._camera.look_at(stage.to_global(Vector3(0, 1.3, 0)))
	lineup._hovered = 1
	lineup._mark(lineup._hover_ring, 1)
	await shot("lineup-suspects", 30)
	lineup._hovered = -1
	lineup._mark(lineup._hover_ring, -1)
	lineup._camera.global_transform = stage.get_parent().get_node("LineupCamera").global_transform.orthonormalized()
	for k in 3:
		lineup.select(int(lineup.round.target))
		lineup.accuse()
		lineup.next_round()
	lineup.select(int(lineup.round.target))
	lineup.accuse()
	lineup.next_round()
	await shot("lineup-summary", 20)
	lineup.end_game("")
	await shot("after-lineup", 40)
	# The evidence game was redesigned on 8 Nov 2026; its views (and the new poster) are made by
	# docs/evidence/police-evidence-20261108/capture.gd. The evidence-*.png here show the 6 Nov game.
	print("POLICE DETECTIVE CAPTURE done")
	quit()
