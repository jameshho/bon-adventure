extends SceneTree
## 23 Nov 2026 (user: "I don't like the fact that the ladder is outside ... remove the last one
## or two rows of the chairs in the chapel and then add a ladder that would connect up to the
## bell"): chapel.gd step inner_ladder. Checks: four pew rows left (the two by the door gone); the
## doorway from the nave into the hollow tower is open for BonBon's body; the ladder stands inside
## the tower; BonBon climbs from the tower floor through the hatch onto the belfry floor and stays
## there; walking back into the hatch takes the ladder down to the floor; the bell still rings;
## the Chapel coin has nothing solid in it. With a window it also takes pictures.
##   HOME=<scratch> VT_FOCUS=chapel VT_SPAWN=none VT_NEARBY=0 godot --path . --resolution 1100x700 \
##     --script res://docs/evidence/chapel-ladder-20261123/verify.gd
## Writes saves only in the isolated HOME.
const OUT := "res://docs/evidence/chapel-ladder-20261123"
const StampPlaces := preload("res://scripts/world/stamp_places.gd")

var checks := 0
var failures := 0
var graphics := false
var game
var ap: Node3D
var space: PhysicsDirectSpaceState3D
var player: CharacterBody3D
var radius := 0.76
var height := 2.2
var camera: Camera3D

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 40: await physics_frame
	for key in game.pending_units.duplicate():
		await game.add_unit(key)
	for i in 10: await physics_frame
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(11 * 60.0)
	ap = game.apartment
	space = ap.get_world_3d().direct_space_state
	player = game.player
	for shape: CollisionShape3D in player.find_children("*", "CollisionShape3D", true, false):
		if shape.shape is CapsuleShape3D and not shape.disabled:
			radius = (shape.shape as CapsuleShape3D).radius * shape.global_basis.get_scale().x
			height = (shape.shape as CapsuleShape3D).height * shape.global_basis.get_scale().y
			break
	var site := ap.get_node("RelocatedSites/Chapel") as Node3D
	var tower := site.get_node_or_null("Bell tower") as Node3D
	var ladder := tower.get_node_or_null("Tower ladder") as Node3D if tower else null
	var bell := tower.get_node_or_null("Chapel bell") as Node3D if tower else null
	check(ladder != null and bell != null, "chapel: tower, ladder and bell stand")
	if ladder == null or bell == null:
		_end()
		return
	# Pews.
	var pews := site.get_children().filter(func(n): return n.get_meta("word_key", "") == "pew")
	var rows := {}
	for p in pews:
		rows[snappedf(p.position.z, 0.01)] = true
	check(pews.size() == 8 and rows.size() == 4, "pews: 8 in 4 rows (%d in %d)" % [pews.size(), rows.size()])
	check(rows.keys().min() > 74.0, "pews: the two rows by the door are gone (first row z %.2f)" % rows.keys().min())
	# Ladder inside the tower.
	var lp: Vector3 = tower.to_local(ladder.global_position)
	check(absf(lp.x) < 1.5 and absf(lp.z) < 1.5, "ladder: inside the tower (%s)" % lp.snapped(Vector3.ONE * 0.01))
	check(ladder.is_in_group("ladders") and not ladder.has_meta("ladder_exit") and absf(float(ladder.get_meta("ladder_height")) - 6.09) < 0.01, "ladder: a hatch ladder up 6.09")
	# Where the old ladder's parapet gap was (south side, middle, knee height): solid now.
	var gap_ray := PhysicsRayQueryParameters3D.create(tower.to_global(Vector3(0, 6.8, -0.9)), tower.to_global(Vector3(0, 6.8, -2.4)), 1)
	check(not space.intersect_ray(gap_ray).is_empty(), "tower: the south parapet is whole (no gap outside)")
	# The way in: a body-sized capsule fits at points along the path from the aisle to the ladder.
	var foot: Vector3 = ladder.to_global(Vector3(0, 0, 0.75))
	var path := [site.to_global(Vector3(44.0, 0.15, 71.25)), site.to_global(Vector3(41.2, 0.15, 71.25)), site.to_global(Vector3(40.35, 0.15, 71.25)), tower.to_global(Vector3(0.8, 0.15, 0.6)), foot]
	var blocked := []
	for at: Vector3 in path:
		var hits := _hits(at + Vector3.UP * (height * 0.5 + 0.06), _capsule())
		if not hits.is_empty():
			blocked.append("%s %s" % [site.to_local(at).snapped(Vector3.ONE * 0.01), hits])
	check(blocked.is_empty(), "doorway: BonBon's body fits from the aisle through the doorway to the ladder %s" % [blocked])
	# Walk in from the aisle: hold the move east and see her reach the tower.
	_put(path[0])
	var walked := await _walk_to(tower, 9.0)
	check(walked, "doorway: BonBon walks from the aisle into the tower (at %s)" % tower.to_local(player.global_position).snapped(Vector3.ONE * 0.01))
	if graphics:
		player.visible = false
		await _view(site.to_global(Vector3(40.3, 1.4, 71.25)), site.to_global(Vector3(47.5, 1.9, 77.5)), "nave-to-tower-door")
		await _view(tower.to_global(Vector3(0, 3.5, -1.4)), tower.to_global(Vector3(1.2, 1.4, 1.3)), "tower-ladder")
		await _view(tower.to_global(Vector3(0, 6.3, -0.8)), tower.to_global(Vector3(0.9, 7.8, 1.3)), "belfry-hatch")
		await _view(tower.to_global(Vector3(0, 5.0, 0)), site.to_global(Vector3(31.0, 4.0, 60.0)), "tower-outside")
		player.visible = true
	# Climb.
	_put(ladder.to_global(Vector3(0, 0.05, 0.75)))
	player.rotation.y = ladder.global_rotation.y
	await _seconds(0.3)
	Input.action_press("climb_up")
	var belfry_y: float = tower.to_global(Vector3(0, 6.24, 0)).y
	var up := false
	var t := 0.0
	while t < 10.0 and not up:
		await physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		var local: Vector3 = tower.to_local(player.global_position)
		up = player.is_on_floor() and _feet() > belfry_y - 0.1 and absf(local.x) < 1.5 and absf(local.z) < 1.5
	Input.action_release("climb_up")
	await _seconds(0.6)
	var at_top: Vector3 = tower.to_local(player.global_position)
	check(up, "climb: BonBon climbs through the hatch onto the belfry floor (%.1f s; at %s)" % [t, at_top.snapped(Vector3.ONE * 0.01)])
	check(_feet() > belfry_y - 0.1 and player.is_on_floor(), "climb: and stands up there (feet %.2f over the floor)" % (_feet() - belfry_y))
	var rang := [0]
	bell.rung.connect(func() -> void: rang[0] += 1)
	bell.get_node("Interactable").activate()
	await _seconds(0.25)
	check(rang[0] == 1, "bell: rings from the belfry")
	if graphics:
		await _view(player.global_position + Vector3.UP * 0.5, tower.to_global(Vector3(-1.0, 8.0, 1.2)), "belfry-after-climb")
	# Down: walk back toward the hatch (S at the head) until she is on the tower floor.
	await _seconds(2.0)
	Input.action_press("climb_down")
	var down := false
	t = 0.0
	var floor_y: float = tower.to_global(Vector3(0, 0.15, 0)).y
	while t < 12.0 and not down:
		await physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		down = player.is_on_floor() and absf(_feet() - floor_y) < 0.15
	Input.action_release("climb_down")
	check(down, "climb down: back on the tower floor (%.1f s)" % t)
	# The coin.
	var spots := StampPlaces.spots()
	if spots.has("chapel"):
		var a: Array = spots.chapel.at
		var coin_at := ap.to_global(Vector3(a[0], a[1], a[2]))
		var cl: Vector3 = tower.to_local(coin_at)
		check(_hits(coin_at, _ball(0.48)).is_empty(), "coin: nothing solid in the Chapel coin (tower %s)" % cl.snapped(Vector3.ONE * 0.01))
		check(not (cl.x > -0.8 and cl.x < 0.8 and cl.z < -0.15), "coin: not over the hatch")
	_end()

func _end() -> void:
	print("chapel ladder verify: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## Holds a move toward the tower (east) until her centre is inside it or the time runs out.
func _walk_to(tower: Node3D, limit: float) -> bool:
	var t := 0.0
	var inside := false
	player.rotation.y = 0.0
	while t < limit and not inside:
		var target: Vector3 = tower.to_global(Vector3(0, 0, 0.6))
		var dir := Vector3(target.x - player.global_position.x, 0, target.z - player.global_position.z)
		player.camera_yaw = atan2(-dir.x, -dir.z)
		Input.action_press("move_forward")
		await physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		var local: Vector3 = tower.to_local(player.global_position)
		inside = absf(local.x) < 1.0 and absf(local.z) < 1.3
	Input.action_release("move_forward")
	return inside

func _feet() -> float:
	return player.global_position.y

func _put(at: Vector3) -> void:
	player.velocity = Vector3.ZERO
	player.global_position = at + Vector3.UP * 0.02

func _seconds(s: float) -> void:
	var end := Time.get_ticks_msec() + int(s * 1000.0)
	while Time.get_ticks_msec() < end:
		await physics_frame

func _ball(r: float) -> SphereShape3D:
	var s := SphereShape3D.new()
	s.radius = r
	return s

func _capsule() -> CapsuleShape3D:
	var c := CapsuleShape3D.new()
	c.radius = radius
	c.height = height
	return c

func _hits(at: Vector3, shape: Shape3D) -> Array:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collision_mask = 1
	q.transform = Transform3D(Basis.IDENTITY, at)
	q.exclude = [player.get_rid()]
	return space.intersect_shape(q, 4).map(func(h): return str(h.collider.name))

func _view(look: Vector3, from: Vector3, title: String) -> void:
	if camera == null:
		camera = Camera3D.new()
		camera.fov = 70
		game.add_child(camera)
	camera.make_current()
	camera.global_position = from
	camera.look_at(look, Vector3.UP)
	for i in 12:
		await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("%s/%s.png" % [ProjectSettings.globalize_path(OUT), title])
	print("wrote ", title)
