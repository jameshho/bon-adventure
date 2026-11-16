extends SceneTree
## Rendered views of the electrical box (9 Nov 2026; docs/guides/ELECTRICAL_BOX.md). Graphical, uses
## Main (isolated HOME, as the README says) and OVERWRITES the PNGs in this folder:
##   HOME=<scratch>/home VT_FOCUS=home VT_SPAWN=none godot --path . --resolution 1280x800 --script res://docs/evidence/electrical-box-20261109/capture.gd
## Views: the box on the garage wall from the path, mid-zoom with the door opening, the wire
## screen as it opens, mid-game (two wires in, one being dragged), the success message, and the
## repaired box afterwards (green lamp).
const Session := preload("res://scripts/learning/electrical_box_session.gd")
const OUT := "res://docs/evidence/electrical-box-20261109/"

func _initialize(): run.call_deferred()

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func shot(name: String) -> void:
	await process_frame
	await process_frame
	# A window in the background may stop drawing: draw this frame now.
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(OUT + name + ".png")
	print("saved ", name)

func run():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(30): await process_frame
	if game.day_night != null:
		game.day_night.set_time(10.5 * 60.0)
		game.day_night.pause()
	var box: Node3D = game.apartment.get_node("RelocatedSites/Home/Electrical box")
	var f: Vector3 = box.facing()
	# Off to one side along the wall, so BonBon does not stand in front of the box.
	var along: Vector3 = f.cross(Vector3.UP).normalized()
	var feet: Vector3 = box.front_center() + f * 2.4 + along * 1.6
	feet.y = box.global_position.y - 1.25 * 1.3 + 0.1
	game.player.global_position = feet
	game.player.velocity = Vector3.ZERO
	var look: Vector3 = (box.front_center() - feet) * Vector3(1, 0, 1)
	var yaw := atan2(-look.x, -look.z)
	game.player.rotation.y = yaw
	game.player.camera_yaw = yaw
	game.player.camera_pitch = -0.12
	game.player.camera_distance = 4.5
	game.player.reset_camera()
	await wait(1.5)
	# Aim the camera at the box whatever the yaw convention: try four yaws, keep the best.
	var best := yaw
	var best_dot := -2.0
	for k in 4:
		game.player.camera_yaw = yaw + k * PI * 0.5
		await wait(0.4)
		var d: float = -game.player.camera.global_basis.z.dot((box.front_center() - game.player.camera.global_position).normalized())
		if d > best_dot:
			best_dot = d
			best = game.player.camera_yaw
	game.player.camera_yaw = best
	await wait(0.8)
	# The exterior view from a separate camera off to the side (the follow camera sits behind
	# BonBon, who would hide the box), then back to the player camera.
	var side_cam := Camera3D.new()
	side_cam.fov = game.player.camera.fov
	root.add_child(side_cam)
	side_cam.global_position = box.front_center() + f * 3.2 - along * 1.4 + Vector3(0, 0.5, 0)
	side_cam.look_at(box.front_center() + along * 0.6 - Vector3(0, 0.3, 0))
	side_cam.make_current()
	await shot("1-box-on-wall")
	game.player.camera.make_current()
	side_cam.queue_free()
	print("blocker: '", preload("res://scripts/learning/activity_board.gd").shared().blocker("electrical_box"), "' seated ", game.player.seated)
	print("opened: ", box.use(), " panel ", game.electrical_box_panel.visible)
	await wait(Session.ZOOM_SECONDS * 0.6)
	await shot("2-zooming-door-opening")
	await wait(Session.ZOOM_SECONDS * 0.4 + 0.5)
	print("state ", game.electrical_box_session.state, " cam ", root.get_viewport().get_camera_3d().name)
	await shot("3-wires-start")
	var panel = game.electrical_box_panel
	var n: int = panel.wires.size()
	panel.drop_on_row(0, panel.wires[0].right)
	panel.drop_on_row(1, panel.wires[1].right)
	# Wire 2 held most of the way to a wrong socket.
	box.set_tip(2, box.socket((panel.wires[2].right + 1) % n).lerp(box.rest(2), 0.2) + Vector3(0, 0, 0.015))
	await wait(0.3)
	await shot("4-dragging")
	panel.drop_on_row(2, panel.wires[2].right)
	panel.drop_on_row(3, panel.wires[3].right)
	await wait(0.5)
	await shot("5-repaired")
	await wait(Session.SUCCESS_SECONDS + Session.RETURN_SECONDS + 0.5)
	await shot("6-back-repaired-box")
	quit()
