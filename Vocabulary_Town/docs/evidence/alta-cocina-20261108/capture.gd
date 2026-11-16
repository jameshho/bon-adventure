extends SceneTree
## 11 Nov 2026: the "Restaurant poster textures" check is stale (poster removed by step
## dining_game_tables; see docs/evidence/restaurant-flow-20261111/capture.gd).
## Alta Cocina dining room refresh (8 Nov 2026; scripts/buildings/restaurants.gd
## dining_room_refresh): checks and views in one town load. Checks: the window glass is in front
## of the wall, the posters hang on the rear wall above the kitchen door and pass, the table and
## Twinkle moved inward, the plaster, corner posts, crown moulding and wainscot exist. Views:
## the west window, the entrance side, the room seen from the door, the rear wall.
## Uses Main, which saves progress and settings: run with an isolated HOME (README).
## HOME=<scratch>/home VT_FOCUS=restaurants godot --path . --resolution 1400x900 --script res://docs/evidence/alta-cocina-20261108/capture.gd
const FOLDER := "res://docs/evidence/alta-cocina-20261108/"
var failures := 0
var checks := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func frame(file: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(FOLDER + file + ".png")

func shot(camera: Camera3D, from: Vector3, at: Vector3, file: String, fov := 60.0) -> void:
	camera.fov = fov
	camera.global_position = from
	camera.look_at(at)
	await frame(file)

func run():
	if DisplayServer.get_name() == "headless": quit(1); return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(30): await process_frame
	game.set_process(false); game.player.set_physics_process(false); game.interaction.set_physics_process(false)
	await process_frame
	var room: Node3D = game.apartment.get_node("Restaurants/Pizza")
	var at := func(x: float, y: float, z: float) -> Vector3: return room.to_global(Vector3(x, y, z))
	var local := func(n: Node3D) -> Vector3: return room.to_local(n.global_position)
	# --- Checks --------------------------------------------------------------------------------
	var panes := 0
	for child in room.get_children():
		var m := child.get_child(0) as MeshInstance3D if child.get_child_count() > 0 else null
		if m != null and m.material_override is BaseMaterial3D and (m.material_override as BaseMaterial3D).albedo_color.to_html(false) == "b5d9f2":
			var z: float = local.call(child).z
			if z > -7.70 and z < -7.68:
				panes += 1
	check(panes == 4, "4 window panes sit in front of the wall face (%d)" % panes)
	for title in ["Restaurant poster tastes", "Restaurant poster textures", "Restaurant poster ingredients", "Restaurant menu board"]:
		var poster := room.get_node_or_null(title) as Node3D
		check(poster != null and absf(local.call(poster).z - 7.62) < .01 and local.call(poster).y > 4.0, "%s on the rear wall (%s)" % [title, local.call(poster) if poster else "missing"])
	var menu := room.get_node("Restaurant menu board") as Node3D
	check(absf(local.call(menu).x - 13.1) < 1.0, "MENÚ board above the kitchen door")
	var twinkle := room.get_node_or_null("BeagleWaiter") as Node3D
	check(twinkle != null and local.call(twinkle).z > -3.0, "Twinkle moved inward (%s)" % [local.call(twinkle) if twinkle else "missing"])
	var table := room.get_node_or_null("Table top") as Node3D
	check(table != null and local.call(table).distance_to(Vector3(-7.8, .84, -2.4)) < .05, "west window table moved inward")
	# Repeated part names are saved as @Node3D@n, so the parts are counted by size and place.
	var posts := 0
	var crowns := 0
	var wainscot := 0
	for child in room.get_children():
		var m := child.get_child(0) as MeshInstance3D if child.get_child_count() > 0 else null
		if m == null or not m.mesh is BoxMesh:
			continue
		var size: Vector3 = (m.mesh as BoxMesh).size
		var p: Vector3 = local.call(child)
		if is_equal_approx(size.x, .26) and is_equal_approx(size.z, .26) and size.y > 6.0:
			posts += 1
		elif is_equal_approx(size.y, .18) and absf(p.y - 6.35) < .01:
			crowns += 1
		elif is_equal_approx(size.y, 1.1) and is_equal_approx(size.z, .06) and absf(absf(p.z) - 7.67) < .01:
			wainscot += 1
	check(posts == 4, "4 corner posts (%d)" % posts)
	check(crowns == 4, "4 crown mouldings (%d)" % crowns)
	check(wainscot == 6, "front and rear wainscot panels (%d)" % wainscot)
	var plaster := 0
	for child in room.get_children():
		var m := child.get_child(0) as MeshInstance3D if child.get_child_count() > 0 else null
		if m != null and m.material_override is StandardMaterial3D and (m.material_override as StandardMaterial3D).albedo_texture is NoiseTexture2D:
			plaster += 1
	check(plaster >= 10, "plaster on the inside wall faces (%d)" % plaster)
	# --- Views ---------------------------------------------------------------------------------
	game.hud.hide()
	game.player.global_position = at.call(0, .3, 5.5)
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.far = 900.0
	camera.current = true
	await shot(camera, at.call(-8.5, 2.2, -3.0), at.call(-8.5, 3.0, -7.7), "window", 62.0)
	await shot(camera, at.call(-1.0, 2.4, 3.5), at.call(-6.0, 1.0, -6.0), "entrance-side", 75.0)
	await shot(camera, at.call(-4.0, 2.4, -6.6), at.call(10.0, 2.8, 4.5), "from-door", 80.0)
	await shot(camera, at.call(6.0, 3.2, -6.5), at.call(6.0, 3.6, 7.7), "rear-wall", 84.0)
	print("ALTA COCINA REFRESH: %d checks, %d failed" % [checks, failures])
	quit(1 if failures > 0 else 0)
