extends SceneTree
## Rendered views of the police lobby after the 8 Nov 2026 rearrangement (police.gd lobby_layout):
## reception against the right side wall, waiting chairs by the entrance, the word poster on the
## side wall, the lineup room door (closed and open) and its dark one-way window. Graphics required;
## since the follow-up (same day) also the beagle officer behind the moved reception and the
## modelled chairs (reception-officer, chairs-close, office-chair, interview-chairs). Isolated user directory (Main writes progress). Needs the police unit loaded.
## godot --path . --resolution 1280x800 --script res://docs/evidence/police-lobby-20261108/capture.gd
const FOLDER := "res://docs/evidence/police-lobby-20261108"

func _initialize() -> void:
	run.call_deferred()

func shot(title: String, frames := 20) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(FOLDER + "/" + title + ".png")
	print("shot ", title)

func view(camera: Camera3D, station: Node3D, from: Vector3, to: Vector3) -> void:
	camera.global_position = station.to_global(from)
	camera.look_at(station.to_global(to))

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
	camera.fov = 65.0
	camera.far = 900.0
	camera.current = true
	game.hud.hide()
	# From the entrance, looking in and to the right (low x).
	view(camera, station, Vector3(43.5, 1.7, 38.3), Vector3(36.0, 1.2, 46.0))
	await shot("entrance-right", 40)
	view(camera, station, Vector3(42.0, 1.7, 45.5), Vector3(33.2, 1.0, 41.0))
	await shot("reception")
	view(camera, station, Vector3(40.0, 1.6, 42.0), Vector3(38.3, .7, 37.6))
	await shot("waiting-chairs")
	view(camera, station, Vector3(37.5, 1.6, 46.0), Vector3(33.2, 1.6, 46.0))
	await shot("poster")
	view(camera, station, Vector3(39.6, 1.9, 41.0), Vector3(34.2, 1.3, 41.6))
	await shot("reception-officer")
	view(camera, station, Vector3(38.3, 1.3, 40.4), Vector3(38.3, .45, 38.2))
	await shot("chairs-close")
	view(camera, station, Vector3(50.8, 1.6, 50.6), Vector3(49.8, .5, 48.8))
	await shot("office-chair")
	view(camera, station, Vector3(47.6, 1.7, 55.9), Vector3(49.5, .5, 55.9))
	await shot("interview-chairs")
	view(camera, station, Vector3(40.5, 1.6, 47.0), Vector3(35.5, 1.4, 52.0))
	await shot("lineup-door-window")
	var door := station.get_node("Lineup room door")
	game.doors[door]["open"] = true
	await shot("lineup-door-open", 60)
	view(camera, station, Vector3(37.6, 1.6, 55.5), Vector3(37.6, 1.5, 50.0))
	await shot("from-inside-lineup")
	print("POLICE LOBBY CAPTURE done")
	quit()
