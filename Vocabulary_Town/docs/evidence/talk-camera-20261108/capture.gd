extends SceneTree
## Talking camera and dialogue box study (8 Nov 2026). Graphics required, isolated HOME:
## HOME=<scratch>/home godot --path . --resolution 1600x1000 --script res://docs/evidence/talk-camera-20261108/capture.gd
## For every minigame NPC: the player walks up in front, the talk camera zooms in and the
## shared dialogue box shows a yes/no question. Writes <npc>-<variant>.png next to this
## script. VT_TALK_VARIANTS (comma list) picks extra camera candidates to compare with the
## built-in one ("after"): eye level/height/distance studies, see candidate().
const OUT := "res://docs/evidence/talk-camera-20261108/"
var game
var failures := 0

func _initialize(): run.call_deferred()

func shot(name: String) -> void:
	for i in range(30): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")
	print("shot ", name)

## A candidate: camera `elevation` degrees above the face, `distance` away, framed so the
## face sits `screen_y` of the way down the screen.
func candidate(presence, elevation: float, distance: float, screen_y: float) -> Transform3D:
	var t: Transform3D = presence.face_transform()
	var npc: Node3D = presence.npc
	var face: Vector3 = npc.global_position + Vector3(0, maxf(presence.marker_rest_y * npc.global_basis.get_scale().y - 0.45, 0.6) - 0.3, 0)
	var flat: Vector3 = t.origin - face
	flat.y = 0
	flat = flat.normalized()
	var e := deg_to_rad(elevation)
	var eye := face + flat * distance * cos(e) + Vector3.UP * distance * sin(e)
	var basis := Basis.looking_at(face - eye, Vector3.UP)
	var extra := atan((0.5 - screen_y) * 2.0 * tan(deg_to_rad(presence.FACE_FOV) * 0.5))
	basis = Basis(basis.x, -extra) * basis
	return Transform3D(basis, eye)

func run():
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	var variants: Array = ["after"]
	for v in OS.get_environment("VT_TALK_VARIANTS").split(",", false):
		variants.append(v)
	var seen_shop := 0
	var panel = game.shop_panel
	for session in game.get_children():
		if not "presence" in session or session.presence == null:
			continue
		var presence = session.presence
		var npc: Node3D = presence.npc
		if npc == null or not npc.is_inside_tree():
			continue
		var id: String = str(npc.name).to_lower().replace(" ", "_")
		print("session ", session.name, " npc ", id)
		if session.get_script().resource_path.ends_with("shop_session.gd"):
			seen_shop += 1
			if seen_shop > 2:
				continue
		for approach in [["front", 0.0], ["side", 70.0]]:
			var forward := -npc.global_basis.z
			forward.y = 0
			forward = forward.normalized().rotated(Vector3.UP, deg_to_rad(approach[1]))
			game.player.global_position = npc.global_position + forward * 2.4
			game.player.look_at(npc.global_position, Vector3.UP)
			for variant in variants:
				print("  zoom ", id, " ", approach[0])
				presence.zoom_to_face(true)
				await create_timer(0.6).timeout
				if variant != "after":
					var parts: PackedStringArray = variant.split("_")
					presence._talk_camera.global_transform = candidate(presence, float(parts[0]), float(parts[1]), float(parts[2]))
				panel.show_dialogue("Speaker", {"foreign": "¿Quieres ayudarme con mi trabajo hoy?", "native": "Do you want to help me with my work today?"}, [{"id": "a", "label": {"foreign": "Sí", "native": "Yes"}, "icon": "check"}, {"id": "b", "label": {"foreign": "Ahora no", "native": "Not now"}, "icon": "no"}])
				await shot("%s-%s-%s" % [id, approach[0], variant])
				print("  %s %s: player model %s" % [id, approach[0], "hidden" if not game.player.visual.visible else "shown"])
				panel.hide_dialogue()
				print("  zoom out")
				presence.zoom_to_face(false)
				await create_timer(0.5).timeout
				if not game.player.visual.visible:
					failures += 1
					print("FAIL: player model not shown again after ", id)
	panel.show_quit({"foreign": "¿Quieres dejar de ayudar? No vas a terminar la tarea.", "native": "Stop helping? You won't finish the task."}, {"foreign": "Sí, salir", "native": "Yes, leave"}, {"foreign": "No, seguir", "native": "No, keep going"})
	await shot("quit-card")
	print("TALK CAMERA: %d failures" % failures)
	quit(1 if failures > 0 else 0)
