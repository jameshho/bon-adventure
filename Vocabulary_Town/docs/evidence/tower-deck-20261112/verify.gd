extends SceneTree
## Control tower roof, observation deck and west deck door (12 Nov 2026; airport.gd `tower_deck`,
## docs/guides/TOWN_DESIGN_BRIEF.md "Control tower roof and observation deck — 12 November 2026").
##   HOME=<scratch>/home VT_FOCUS=airport VT_SPAWN=none godot --path . --fixed-fps 60 \
##     --resolution 1200x800 --script res://docs/evidence/tower-deck-20261112/verify.gd
## With a window it also writes the PNG views into this folder (overwrites them); headless it
## only checks. Checks: old ledge/rail/top slab gone; door registered, pickable, and blocking
## when shut; a real-size capsule (radius .76, height 2.2 world) walks from the control room
## through the open door and once round the deck at floor level; the railing stops it; nothing of
## another building inside the deck's air space; faces sharing a plane on the tower
## (coplanar_gaps.gd finder; the headphone ear-cup pads are older and known).
const DoorAnimator := preload("res://scripts/core/door_animator.gd")
const Interaction := preload("res://scripts/player/interaction_controller.gd")
const FOLDER := "res://docs/evidence/tower-deck-20261112/"
const FLOOR := 22.0
var failures := 0
var checks := 0
var game
var room: Node3D
var space: PhysicsDirectSpaceState3D

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func make_walker(p: Vector3) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .76
	capsule.height = 2.2
	shape.shape = capsule
	shape.position = Vector3(0, 1.1, 0)
	body.add_child(shape)
	body.floor_snap_length = .3
	body.collision_layer = 0
	body.collision_mask = 1
	game.add_child(body)
	body.global_position = room.to_global(p)
	return body

## Walks toward each room-local waypoint; returns how far from the last one it stopped (room units).
func walk(body: CharacterBody3D, points: Array, frames := 600) -> float:
	for wp in points:
		var target: Vector3 = room.to_global(wp)
		for frame in range(frames):
			var d := target - body.global_position
			d.y = 0
			if d.length() < .3: break
			body.velocity.x = d.normalized().x * 6.0
			body.velocity.z = d.normalized().z * 6.0
			body.velocity.y -= 30.0 / 60.0
			body.move_and_slide()
			await physics_frame
	var last: Vector3 = room.to_global(points[-1])
	return (last - body.global_position).slide(Vector3.UP).length() / 1.3

func local_y(body: Node3D) -> float:
	return room.to_local(body.global_position).y

func settle_door(door: Node3D) -> void:
	for i in 40:
		DoorAnimator.animate(game, 1.0 / 30.0)
		await physics_frame

func run() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	for i in 3: await physics_frame
	var town: Node3D = game.apartment
	room = town.get_node("Airport/ControlTower/Interior")
	space = game.get_world_3d().direct_space_state
	# Parts.
	check(room.get_node_or_null("Cabin top slab") == null and room.get_node_or_null("Cabin top fascia") == null and room.get_node_or_null("Cabin ledge") == null and room.get_node_or_null("Cabin rail") == null, "old top slab, fascia, ledge and thin rail removed")
	check(room.get_node_or_null("Tower roof slab") != null and room.get_node_or_null("Faceted roof cap") != null, "new roof slab and cap")
	var door: Node3D = room.get_node_or_null("Deck door")
	check(door != null and game.doors.has(door) and str(game.doors[door].get("type")) == "slide", "deck door registered as a sliding door")
	if door == null:
		print("TOWER DECK VERIFY: ", checks, " checks, ", failures, " failures")
		quit(1)
		return
	var leaf: Node = door.get_node("Deck door leaf")
	check(Interaction.vocabulary_target(leaf, town, game.doors) == door and str(door.get_meta("word_key", "")) == "door", "pointing at the leaf picks the door (word door)")
	# Air space: nothing outside the tower within the deck ring, from the deck slab to above the roof.
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(15.6, 7.6, 15.6) * 1.3
	query.shape = box
	query.transform = Transform3D(Basis(), room.to_global(Vector3(0, 21.5 + 3.8, 0)))
	query.collide_with_areas = false
	var strangers := []
	for hit in space.intersect_shape(query, 256):
		if not room.is_ancestor_of(hit.collider): strangers.append(town.get_path_to(hit.collider))
	check(strangers.is_empty(), "deck and roof air space holds only the tower %s" % [strangers.slice(0, 3)])
	# Door shut: the walker is stopped at the glass line.
	var body := make_walker(Vector3(1.2, FLOOR, -1.0))
	for i in 10: await physics_frame
	var left := await walk(body, [Vector3(4.6, FLOOR, 0.0), Vector3(4.6, FLOOR, .9), Vector3(6.6, FLOOR, .9)], 240)
	check(left > 1.0, "closed door blocks the way out (stopped %.2f short)" % left)
	game.doors[door]["open"] = true
	await settle_door(door)
	check(absf(room.to_local(door.global_position).z - (.88 - 1.5)) < .02, "door slides 1.5 south when opened (z %.2f)" % room.to_local(door.global_position).z)
	left = await walk(body, [Vector3(6.6, FLOOR, .9)])
	check(left < .4 and absf(local_y(body) - FLOOR) < .1, "walker steps out through the open door onto the deck (%.2f short, y %.2f)" % [left, local_y(body)])
	var lowest := local_y(body)
	var ring := [Vector3(6.6, FLOOR, 6.6), Vector3(-6.6, FLOOR, 6.6), Vector3(-6.6, FLOOR, -6.6), Vector3(6.6, FLOOR, -6.6), Vector3(6.6, FLOOR, .9)]
	var all_ok := true
	for wp in ring:
		left = await walk(body, [wp])
		lowest = minf(lowest, local_y(body))
		all_ok = all_ok and left < .4
		check(left < .4, "walker reaches deck corner/waypoint %s (%.2f short)" % [wp, left])
	check(all_ok and lowest > FLOOR - .1, "whole lap at deck level (lowest y %.2f)" % lowest)
	left = await walk(body, [Vector3(10.0, FLOOR, .9)], 180)
	var x := room.to_local(body.global_position).x
	check(x < 7.5 - .5 and x > 6.0, "railing stops the walker (x %.2f)" % x)
	left = await walk(body, [Vector3(6.6, FLOOR, .9), Vector3(4.6, FLOOR, .9)])
	check(left < .4, "walker comes back in (%.2f short)" % left)
	body.free()
	game.doors[door]["open"] = false
	await settle_door(door)
	check(absf(room.to_local(door.global_position).z - .88) < .02, "door slides shut")
	# Faces sharing a plane on the tower.
	var finder = load("res://scripts/buildings/coplanar_gaps.gd").new()
	var plan: Dictionary = finder.plan(town)
	var tower_pairs := []
	for r in plan.pairs:
		var a: String = town.get_path_to(r[1][4])
		var b: String = town.get_path_to(r[2][4])
		if a.contains("ControlTower") or b.contains("ControlTower"):
			if a.contains("EarCup") or a.contains("Padding"): continue
			tower_pairs.append("%s | %s" % [a, b])
	for p in tower_pairs: print("TOWER COPLANAR ", p)
	print("TOWER COPLANAR pairs (ear-cup pads excluded): ", tower_pairs.size())
	print("TOWER DECK CHECKS: ", checks, " checks, ", failures, " failures")
	if DisplayServer.get_name() != "headless":
		await renders(town, door)
	print("TOWER DECK VERIFY: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)

func renders(town: Node3D, door: Node3D) -> void:
	game.set_process(true)
	game.player.visible = false
	game.hud.hide()
	var cycle = game.day_night
	cycle.pause()
	cycle.set_time(13 * 60 + 44)
	var camera := Camera3D.new()
	camera.near = .08
	camera.fov = 60
	game.add_child(camera)
	camera.current = true
	# [file, eye (room-local), target (room-local), door open]
	var views := [
		["below_southwest", Vector3(-14, 4, -22), Vector3(0, 22, 0), false],
		["below_west", Vector3(26, 10, -6), Vector3(4, 23, 0), false],
		["far_south", Vector3(-20, 18, -70), Vector3(0, 22, 0), false],
		["deck_west_door", Vector3(7.0, 23.6, -4.6), Vector3(5.5, 23.2, 1.2), false],
		["deck_west_door_open", Vector3(7.0, 23.6, -4.6), Vector3(5.5, 23.2, 1.2), true],
		["deck_along_north", Vector3(6.6, 23.7, 6.6), Vector3(-6.6, 23.0, 6.6), true],
		["inside_to_door", Vector3(1.0, 23.8, -1.5), Vector3(5.5, 23.2, 1.0), true],
		["roof_above", Vector3(-16, 36, -14), Vector3(0, 27, 0), false],
	]
	for v in views:
		game.doors[door]["open"] = v[3]
		for i in 40:
			DoorAnimator.animate(game, 1.0 / 30.0)
			await process_frame
		camera.global_position = room.to_global(v[1])
		camera.look_at(room.to_global(v[2]), Vector3.UP)
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(FOLDER + v[0] + ".png"))
		print("TOWER VIEW ", v[0])
	game.doors[door]["open"] = false
