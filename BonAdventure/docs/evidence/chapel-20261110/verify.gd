extends SceneTree
## Chapel rebuild (10 Nov 2026; scripts/buildings/chapel.gd step `rebuild`): old parts gone, the
## CHAPEL sign unobstructed from the front walk, words, floors and roof, the entrance and aisle
## clear, and a walk with W from the lawn up the aisle onto the chancel. Drives Main with real key
## events. Main saves progress: run with an isolated user directory (README).
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --fixed-fps 60 --script res://docs/evidence/chapel-20261110/verify.gd
const CHAPEL = preload("res://scripts/buildings/chapel.gd")
var failures := 0
var checks := 0
var game

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(10): await physics_frame
	var town: Node3D = game.apartment
	var site: Node3D = town.get_node(CHAPEL.SITE)
	var facade: Node3D = town.get_node(CHAPEL.FACADE)
	var front: Node3D = facade.get_node_or_null(CHAPEL.FRONT_HOLDER)
	check(front != null, "chapel front built under the map facade")
	# --- old parts gone
	for path in ["Faceted roof cap", "Portico lintel", "Portico column", "Chapel tower", "Sign frame"]:
		check(facade.get_node_or_null(path) == null, "old front part removed: " + path)
	for path in ["CHURCH upgrade sign", "Church plaque", "Pew back", "Organ pipe"]:
		check(site.get_node_or_null(path) == null, "old site part removed: " + path)
	check(front != null and front.global_transform.is_equal_approx(site.global_transform), "front holder shares the site's frame")
	# --- the sign: translated lettering over the door, nothing in front of it
	var labels: Array = facade.find_children("Facade lettering", "Label3D", true, false)
	check(labels.size() == 1 and String(labels[0].text) in ["CHAPEL", "CAPILLA", "小教堂"], "one CHAPEL sign (%s)" % [labels.map(func(l): return l.text)])
	if labels.size() == 1:
		var label: Label3D = labels[0]
		var sign_parts := {}
		for title in ["Sign face", "Sign frame"]:
			for node in front.find_children(title, "Node3D", false, false):
				sign_parts[node] = true
		var blockers: Array = []
		var meshes: Array = town.find_children("*", "MeshInstance3D", true, false)
		for eye_local in [Vector3(CHAPEL.CX, 1.6, 60.5), Vector3(CHAPEL.CX - 3.0, 1.4, 62.0), Vector3(CHAPEL.CX + 3.0, 1.4, 62.0), Vector3(CHAPEL.CX, 1.3, 65.0)]:
			var eye: Vector3 = site.to_global(eye_local)
			for dx in [-1.4, 0.0, 1.4]:
				for dy in [-0.22, 0.22]:
					var target: Vector3 = label.to_global(Vector3(dx / 1.0, dy, 0))
					for m in meshes:
						if not m.is_visible_in_tree() or m.mesh == null or sign_parts.has(m.get_parent()):
							continue
						var box: AABB = m.global_transform * m.mesh.get_aabb()
						if box.get_center().distance_to(target) > 40.0:
							continue
						if box.intersects_segment(eye, target.lerp(eye, 0.01)):
							blockers.append("%s from %s" % [town.get_path_to(m), eye_local])
		check(blockers.is_empty(), "nothing between the front walk and the sign %s" % [blockers.slice(0, 4)])
	# --- words
	var words := {}
	for parent in [site, facade]:
		for node in parent.find_children("*", "Node3D", true, false):
			if node.has_meta("word_key"):
				words[String(node.get_meta("word_key"))] = words.get(String(node.get_meta("word_key")), 0) + 1
	print("chapel words ", words)
	for word in ["wall", "roof", "ceiling", "church", "pew", "altar", "candle", "flame", "lectern", "donation box", "slot", "flag", "step", "tile", "floor", "window", "door", "rug", "cross", "book", "flower", "planter", "ceiling light"]:
		check(words.has(word) and game.vocabulary.has(word), "teaches " + word)
	check(words.get("pew", 0) == 8, "eight pews (%d)" % words.get("pew", 0))
	var altar: Node3D = site.get_node_or_null("Altar")
	if altar != null:
		game.interaction.show_word(altar)
		check(game.hud.current_spanish == game.vocabulary["altar"], "study card shows " + str(game.hud.current_spanish))
	check(facade.get_meta("exterior_word", "") == "church", "front shows the exterior word church")
	check(game.get_tree().get_nodes_in_group(CHAPEL.NIGHT_LIGHTS).filter(func(n): return site.is_ancestor_of(n) or facade.is_ancestor_of(n)).size() == 14, "two lanterns and twelve chandelier lights glow at night")
	# --- floors and roof
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	var top := CHAPEL.FLOOR + CHAPEL.DAIS_H
	for spec in [["nave", Vector3(44.0, 0, 70.6), CHAPEL.FLOOR], ["aisle", Vector3(CHAPEL.CX, 0, 76.4), CHAPEL.FLOOR], ["threshold", Vector3(CHAPEL.CX, 0, 69.2), CHAPEL.FLOOR], ["chancel", Vector3(43.2, 0, 80.2), top]]:
		var from: Vector3 = site.to_global(spec[1] + Vector3(0, 4.0, 0))
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 8))
		var y: float = site.to_local(hit.position).y if not hit.is_empty() else -9.0
		check(absf(y - spec[2]) < .03, "%s floor at %.2f (expected %.2f)" % [spec[0], y, spec[2]])
	for p in [Vector3(43.0, 0, 72.0), Vector3(50.0, 0, 79.0), Vector3(CHAPEL.CX, 0, 74.5)]:
		var sky: Vector3 = site.to_global(p + Vector3(0, 30, 0))
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(sky, sky + Vector3.DOWN * 40))
		var y: float = site.to_local(hit.position).y if not hit.is_empty() else -9.0
		check(y > CHAPEL.EAVE, "roof closes the top at %s (hit %.2f)" % [p, y])
	# --- entrance and aisle clear for BonBon
	var body: CapsuleShape3D = game.player.get_node("PlayerCollision").shape
	var blocked := []
	for i in range(31):
		var z := lerpf(64.0, 77.0, i / 30.0)
		# The entrance ramp rises from z FRONT - 1.6 to the floor; probe above it there.
		var floor_y := CHAPEL.FLOOR if z > CHAPEL.FRONT - 1.6 else 0.0
		var probe := PhysicsShapeQueryParameters3D.new()
		probe.shape = body
		probe.transform = Transform3D(Basis.IDENTITY, site.to_global(Vector3(CHAPEL.CX, floor_y, z)) + Vector3.UP * (body.height * .5 + .12))
		probe.exclude = [game.player.get_rid()]
		if not space.intersect_shape(probe, 1).is_empty():
			blocked.append(snappedf(z, .1))
	check(blocked.is_empty(), "path, door and aisle clear %s" % [blocked])
	# The old flat-roofed chapel's runtime outline (base step chapel_old_outline, 12 Nov 2026)
	var outline := []
	for node in town.get_children():
		if str(node.name).begins_with("Building outline"):
			var c: Vector3 = site.to_local(node.global_position)
			if c.x > 40.0 and c.x < 53.0 and c.z > 68.0 and c.z < 82.0:
				outline.append(str(node.name))
	check(outline.is_empty(), "no old building outline on the chapel %s" % [outline])
	# --- hold W from the lawn: through the door, up the aisle, onto the chancel
	var walker = game.player
	walker.global_position = site.to_global(Vector3(CHAPEL.CX, 0.1, 64.0))
	walker.velocity = Vector3.ZERO
	var heading: Vector3 = site.to_global(Vector3(0, 0, 1)) - site.to_global(Vector3.ZERO)
	walker.camera_yaw = atan2(-heading.x, -heading.z)
	walker.camera_rig.rotation.y = walker.camera_yaw
	for i in range(10): await physics_frame
	key(KEY_W, true)
	var inside_at := -1
	for i in range(900):
		await physics_frame
		var p: Vector3 = site.to_local(walker.global_position)
		if inside_at < 0 and p.z > 70.0:
			inside_at = i
		if p.z > 78.3:
			break
	key(KEY_W, false)
	for i in range(30): await physics_frame
	var end: Vector3 = site.to_local(walker.global_position)
	print("walk end ", end, " inside after ", inside_at, " frames")
	check(inside_at > 0, "walks in through the door")
	check(end.z > 78.0 and absf(end.y - top) < .12, "walks up the aisle onto the chancel (y %.2f, z %.2f)" % [end.y, end.z])
	print("CHAPEL VERIFY: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
