extends SceneTree
## The view from the air (23 Nov 2026, vehicle_controls.gd update_flight_view(); one graphics
## setting, render_culling.gd): the plane flown level over the middle of the town at several
## heights (after one measure on foot at the centre), the chase view (tilted down with height)
## and the HUD as played. For each: a screenshot and the average
## draw calls, triangles and frame time over 120 frames (this Mac, not a phone), printed as
## "VIEWCOST". Overwrites the PNGs here. VT_NIGHT=1: only the plane at 100 m at 10:54 pm, saved
## as night-height-100-m.png (the sky below the horizon takes the fog colour, no seam; 23 Nov). Graphics and an isolated HOME:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1560x720 --script res://docs/evidence/flight-view-20261123/capture.gd
const DIR := "res://docs/evidence/flight-view-20261123/"
const HEIGHTS := [40, 100, 200, 300]
func _initialize(): run.call_deferred()
func run():
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 40: await process_frame
	var night := OS.get_environment("VT_NIGHT") == "1"
	game.day_night.set_time((22.9 if night else 14.0) * 60.0)
	game.day_night.pause()
	var town: Node3D = game.apartment
	var bounds: Rect2 = town.get_meta("reference_map_bounds")
	var centre: Vector3 = town.to_global(Vector3(bounds.get_center().x, 0, bounds.get_center().y))
	# Baseline: on foot at the centre, looking north (the usual 130 m view).
	game.player.global_position = centre + Vector3(0, 2, -120)
	game.player.camera_yaw = PI
	if not night:
		await measure(game, "on foot")
	var plane: Node3D = game.apartment.get_node("Vehicles/Turboprop")
	game.player.global_position = plane.boarding_step_point()
	game.toggle_vehicle()
	for i in 200: await physics_frame
	for height in ([100] if night else HEIGHTS):
		# Start 120 m south of the centre, flying north over it.
		var start: Vector3 = centre + Vector3(0, 0, -120)
		start.y = town.global_position.y + float(height)
		plane.global_transform = Transform3D(Basis.looking_at(Vector3(0, 0, 1), Vector3.UP).scaled(plane.global_basis.get_scale()), start)
		plane.flight_velocity = Vector3(0, 0, plane.CRUISE)
		plane.airspeed = plane.CRUISE
		plane.landed = false
		game.player.reset_camera()
		await measure(game, ("night-" if night else "") + "height %d m" % height)
	quit()

func measure(game: Node, what: String) -> void:
	for i in 240: await process_frame
	var draws := 0.0
	var tris := 0.0
	var started := Time.get_ticks_usec()
	for i in 120:
		await process_frame
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		tris += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var ms := (Time.get_ticks_usec() - started) / 120000.0
	print("VIEWCOST %s: view %.0f m, %.0f draws, %.2f M tris, %.1f ms/frame" % [what, game.player.camera.far, draws / 120.0, tris / 120.0 / 1.0e6, ms])
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(DIR + what.replace(" ", "-") + ".png"))
