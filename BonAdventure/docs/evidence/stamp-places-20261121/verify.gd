extends SceneTree
## 21 Nov 2026 (user's list of coin spots): the 18 placed town stamp coins
## (scripts/world/stamp_places.gd, data/achievements.json "stamps") and the three building changes
## that came with them: the Bank's round safe that opens (bank.gd vault_safe), the Supermarket's
## storage room and its door (supermarket.gd storage_room), the bigger Chapel with its bell tower,
## ladder and ringable bell (chapel.gd grand_chapel, scripts/world/chapel_bell.gd).
## Checks, for every coin: it is in the town at its "at"; nothing solid inside it; a spot where
## BonBon's real body stands on a floor, sees it and is close enough to collect it. Then: the
## safe's coin stays while the safe is shut and is collected once it is open (the wheel turns
## first); the staff door opens; BonBon climbs the tower ladder into the belfry; the bell rings.
## With a window it also takes one picture per coin and the new places (pictures before the checks
## that collect coins).
##   HOME=<scratch> VT_FOCUS=all VT_SPAWN=none VT_NEARBY=0 godot --path . --resolution 1100x700 \
##     --script res://docs/evidence/stamp-places-20261121/verify.gd
## Writes saves only in the isolated HOME.
const OUT := "res://docs/evidence/stamp-places-20261121"
const StampPlaces := preload("res://scripts/world/stamp_places.gd")
const DoorAnimator := preload("res://scripts/core/door_animator.gd")
const Achievements := preload("res://scripts/learning/achievements.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")

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
## id -> the standing point (capsule centre, world) found for it.
var stands := {}

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
	print("body: radius %.2f m, height %.2f m" % [radius, height])
	var spots := StampPlaces.spots()
	var tracker = Achievements.shared()
	check(spots.size() == 18, "18 coins placed (%d)" % spots.size())
	check(tracker.ids_in("stamps").size() == spots.size(), "the Stamps page lists exactly the placed coins (%d)" % tracker.ids_in("stamps").size())
	for id in ["restaurants", "warehouse", "school"]:
		check(not spots.has(id) and not tracker.defs.has("stamp." + id), "%s: not on the user's list, no stamp" % id)
	check(tracker.defs.has("ring_bell"), "Exploration lists Ring the bell")
	# Every coin.
	for id in spots:
		var entry: Dictionary = spots[id]
		var coin := _coin(id, entry)
		check(coin != null, "%s: coin in the town" % id)
		if coin == null:
			continue
		var want: Vector3 = ap.to_global(Vector3(entry.at[0], entry.at[1], entry.at[2]))
		check(coin.global_position.distance_to(want) < 0.05 and absf(coin.radius - 0.45) < 0.001, "%s: at its spot (%s), radius 0.45 m" % [id, str(entry.at)])
		check(absf(coin.global_basis.get_scale().x - 1.0) < 0.01, "%s: coin keeps its size (scale 1)" % id)
		var hits := _hits(coin.global_position, _ball(coin.radius + 0.03))
		if entry.has("face"):
			# A still coin facing out: its disc (bob included), not a ball.
			var disc := BoxShape3D.new()
			disc.size = Vector3(coin.radius * 2.0 + 0.04, coin.radius * 2.0 + 0.2, 0.14)
			hits = _hits(coin.global_position, disc, coin.global_basis.orthonormalized())
			check(is_zero_approx(coin.spin_speed), "%s: stands still facing out" % id)
		check(hits.is_empty(), "%s: nothing solid inside the coin %s" % [id, hits])
		if id != "bank":
			var decor := _decor(coin.global_position, coin.radius)
			check(decor == "", "%s: no decoration through the coin %s" % [id, decor])
		if id == "bank":
			check(_stand(id, coin) == null, "bank: no spot sees the coin while the safe is shut")
			continue
		var stand = _stand(id, coin)
		check(stand != null, "%s: BonBon can stand where she sees and reaches it" % id)
	# Pictures before anything is collected.
	if graphics:
		await _pictures(spots)
	await _bank()
	await _storage()
	await _chapel()
	print("stamp_places verify: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## The first mesh (furniture, plants, lamps: things with or without collision) whose box reaches
## into the coin's box (its diameter); walls, floors and ceilings (big in two directions) do not count.
var _boxes: Array = []
func _decor(at: Vector3, half := 0.3) -> String:
	if _boxes.is_empty():
		for mi: GeometryInstance3D in ap.find_children("*", "GeometryInstance3D", true, false):
			if mi is MultiMeshInstance3D or mi is Label3D or mi is Sprite3D:
				continue
			var path := str(ap.get_path_to(mi))
			if path.contains("StampCoin_") or not (mi.is_visible_in_tree() or mi.has_meta("render_batched")):
				continue
			var b: AABB = mi.global_transform * mi.get_aabb()
			if int(b.size.x > 3.5) + int(b.size.y > 3.5) + int(b.size.z > 3.5) >= 2 or b.size.y < 0.03:
				continue
			_boxes.append([b, path])
	var me := AABB(at - Vector3.ONE * half, Vector3.ONE * half * 2.0)
	for e in _boxes:
		if (e[0] as AABB).intersects(me):
			return e[1]
	return ""

func _coin(id: String, entry: Dictionary) -> Node3D:
	var holder_path: String = str(entry.get("parent", StampPlaces.HOLDER))
	return ap.get_node_or_null(holder_path + "/StampCoin_" + id) as Node3D

func _ball(r: float) -> SphereShape3D:
	var s := SphereShape3D.new()
	s.radius = r
	return s

func _hits(at: Vector3, shape: Shape3D, basis := Basis.IDENTITY) -> Array:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collision_mask = 1
	q.transform = Transform3D(basis, at)
	q.exclude = [player.get_rid()]
	return space.intersect_shape(q, 4).map(func(h): return str(h.collider.name))

## A capsule centre (world) where BonBon stands on a floor 0.75-1.35 m under the coin, clear,
## with a free line of sight from her eyes (0.6 m over the centre) to the coin and her body within
## its pickup radius; the nearest such point, or null.
func _stand(id: String, coin: Node3D):
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = height
	var reach: float = coin.pickup_radius
	var best = null
	var best_d := 99.0
	for ix in range(-10, 11):
		for iz in range(-10, 11):
			var p := coin.global_position + Vector3(ix * 0.18, 0, iz * 0.18)
			var ray := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.4, p + Vector3.DOWN * 2.6, 1, [player.get_rid()])
			var floor_hit := space.intersect_ray(ray)
			if floor_hit.is_empty():
				continue
			# A real floor under the coin (it floats about a metre up), not a wall top or a bale.
			var drop: float = coin.global_position.y - floor_hit.position.y
			if drop < 0.75 or drop > 1.35:
				continue
			var centre: Vector3 = floor_hit.position + Vector3.UP * (height * 0.5 + 0.03)
			# Distance from the coin to the capsule's core segment, minus the body's radius.
			var seg_low := centre + Vector3.DOWN * (height * 0.5 - radius)
			var seg_high := centre + Vector3.UP * (height * 0.5 - radius)
			var closest := Geometry3D.get_closest_point_to_segment(coin.global_position, seg_low, seg_high)
			var gap := closest.distance_to(coin.global_position) - radius
			if gap > reach - 0.05:
				continue
			var d := Vector2(p.x - coin.global_position.x, p.z - coin.global_position.z).length()
			if d >= best_d:
				continue
			if not _hits(centre, capsule).is_empty():
				continue
			var sight := PhysicsRayQueryParameters3D.create(centre + Vector3.UP * 0.6, coin.global_position, 1, [player.get_rid()])
			if not space.intersect_ray(sight).is_empty():
				continue
			best = centre
			best_d = d
	if best != null:
		stands[id] = best
	return best

func _bank() -> void:
	var tracker = Achievements.shared()
	var pivot := ap.get_node_or_null("RelocatedSites/Bank/Vault safe door") as Node3D
	var coin := ap.get_node_or_null("StampCoins/StampCoin_bank") as Node3D
	check(pivot != null and game.doors.has(pivot), "bank: the safe door is a hinged door (door_animator)")
	check(coin != null and coin.gate == pivot, "bank: the coin is gated by the safe door")
	if pivot == null or coin == null:
		return
	var bank := ap.get_node("RelocatedSites/Bank") as Node3D
	var wheel := pivot.get_node_or_null("Vault wheel") as Node3D
	check(pivot.get_node_or_null("Interactable") != null, "bank: the safe has an interactable (E, click, tap)")
	# Shut: standing right at the door collects nothing.
	_put(bank.to_global(Vector3(29.4, 0.05, 50.95)))
	await _seconds(0.6)
	check(not tracker.has_stamp("bank"), "bank: nothing collected through the shut safe door")
	_put(bank.to_global(Vector3(25.0, 0.05, 50.0)))
	await _seconds(0.2)
	DoorAnimator.toggle(game, pivot)
	await _seconds(0.25)
	check(wheel != null and wheel.rotation.z > 0.6 and absf(pivot.rotation.y) < 0.2, "bank: the wheel turns first (wheel %.2f, door %.2f)" % [wheel.rotation.z if wheel else 0.0, pivot.rotation.y])
	await _seconds(1.4)
	check(absf(pivot.rotation.y + 1.5) < 0.05, "bank: then the door swings open (%.2f)" % pivot.rotation.y)
	check(_stand("bank", coin) != null, "bank: open, BonBon can stand where she sees and reaches it")
	if graphics:
		coin.bob_height = 0.0
		var from: Vector3 = bank.to_global(Vector3(28.6, 1.55, 49.6))
		player.visible = false
		await _view(coin.global_position + Vector3(0, 0.2, 0), from, "bank-safe-open")
		player.visible = true
	_put(bank.to_global(Vector3(29.0, 0.05, 51.0)))
	await _seconds(0.8)
	check(tracker.has_stamp("bank"), "bank: collected once the safe is open")

func _storage() -> void:
	var leaf := ap.get_node_or_null("RelocatedSites/Supermarket/MarketInterior/Staff wall/Staff door/Staff door leaf") as Node3D
	check(leaf != null and game.doors.has(leaf), "supermarket: the staff door is a shared hinged door")
	if leaf == null:
		return
	check(ap.get_node_or_null("RelocatedSites/Supermarket/MarketInterior/Storage room") != null, "supermarket: the storage room is furnished")
	DoorAnimator.toggle(game, leaf)
	await _seconds(1.0)
	check(absf(leaf.rotation.y) > 1.3, "supermarket: the staff door opens (%.2f)" % leaf.rotation.y)
	if graphics:
		var interior := ap.get_node("RelocatedSites/Supermarket/MarketInterior") as Node3D
		player.visible = false
		await _view(interior.to_global(Vector3(-37.7, 1.4, 56.5)), interior.to_global(Vector3(-37.4, 2.0, 50.6)), "storage-door-open")
		await _view(interior.to_global(Vector3(-27.0, 1.2, 58.0)), interior.to_global(Vector3(-41.5, 2.6, 54.2)), "storage-room")
		player.visible = true

func _chapel() -> void:
	var tracker = Achievements.shared()
	var tower := ap.get_node_or_null("RelocatedSites/Chapel/Bell tower") as Node3D
	check(tower != null, "chapel: the bell tower stands")
	if tower == null:
		return
	var ladder := tower.get_node_or_null("Tower ladder") as Node3D
	var bell := tower.get_node_or_null("Chapel bell") as Node3D
	check(ladder != null and ladder.is_in_group("ladders") and is_equal_approx(float(ladder.get_meta("ladder_height", 0.0)), 6.2), "chapel: the ladder is a climbable ladder up 6.2")
	check(bell != null and bell.get_node_or_null("Interactable") != null, "chapel: the bell has an interactable")
	var site := ap.get_node("RelocatedSites/Chapel") as Node3D
	var floor_box := site.get_node_or_null("Chapel floor") as Node3D
	if graphics:
		player.visible = false
		await _view(site.to_global(Vector3(44.0, 4.5, 74.0)), site.to_global(Vector3(28.5, 3.2, 56.0)), "chapel-outside")
		await _view(site.to_global(Vector3(46.5, 1.6, 80.0)), site.to_global(Vector3(46.5, 2.6, 70.3)), "chapel-inside")
		await _view(ladder.to_global(Vector3(0, 2.5, 0)), ladder.to_global(Vector3(-1.6, 1.4, 4.2)), "chapel-ladder")
		player.visible = true
	# Climb: stand at the ladder's foot facing it and hold climb_up.
	_put(ladder.to_global(Vector3(0, 0.05, 0.75)))
	player.rotation.y = ladder.global_rotation.y
	await _seconds(0.3)
	Input.action_press("climb_up")
	var belfry_y: float = tower.to_global(Vector3(0, 6.2, 0)).y
	var inside := false
	var t := 0.0
	while t < 9.0 and not inside:
		await physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		var local: Vector3 = tower.to_local(player.global_position)
		inside = player.is_on_floor() and player.global_position.y > belfry_y - 0.1 and absf(local.x) < 1.35 and absf(local.z) < 1.35
	Input.action_release("climb_up")
	await _seconds(0.5)
	var local: Vector3 = tower.to_local(player.global_position)
	check(inside, "chapel: BonBon climbs the ladder into the belfry (%.1f s; at %s)" % [t, local.snapped(Vector3.ONE * 0.01)])
	check(player.global_position.y > belfry_y - 0.1, "chapel: and stays up there (feet %.2f m over the belfry floor)" % (player.global_position.y - height * 0.0 - belfry_y))
	if bell != null:
		var rang := [0]
		bell.rung.connect(func() -> void: rang[0] += 1)
		bell.get_node("Interactable").activate()
		await _seconds(0.25)
		check(rang[0] == 1 and absf(bell.rotation.x) > 0.2, "chapel: the bell rings and swings (%.2f)" % bell.rotation.x)
		check(tracker.count("ring_bell") == 1, "chapel: Ring the bell is noted")
		if graphics:
			player.visible = false
			await _view(bell.global_position + Vector3(0, -0.6, 0), tower.to_global(Vector3(0.9, 7.6, -1.2)), "chapel-belfry")
			player.visible = true
		await _seconds(2.4)
		check(absf(bell.rotation.x) < 0.01, "chapel: the bell comes to rest")

func _put(at: Vector3) -> void:
	player.velocity = Vector3.ZERO
	player.global_position = at + Vector3.UP * 0.02

func _seconds(s: float) -> void:
	var end := Time.get_ticks_msec() + int(s * 1000.0)
	while Time.get_ticks_msec() < end:
		await physics_frame

# --- Pictures ---------------------------------------------------------------------------------

func _pictures(spots: Dictionary) -> void:
	camera = Camera3D.new()
	camera.fov = 70
	game.add_child(camera)
	camera.make_current()
	player.visible = false
	for id in spots:
		var coin := _coin(id, spots[id])
		if coin == null:
			continue
		# From BonBon's eyes where she stands to collect it, at least 1.5 m back.
		var at: Vector3 = coin.global_position
		var eye: Vector3 = (stands[id] + Vector3.UP * 0.6) if stands.has(id) else at + Vector3(0, 0.6, -1.5)
		if id == "bank":
			var bank := ap.get_node("RelocatedSites/Bank") as Node3D
			eye = bank.to_global(Vector3(29.4, 1.7, 49.9))
		var toward := Vector3(eye.x - at.x, 0, eye.z - at.z)
		var from := eye
		if toward.length() < 1.6:
			# Back to 1.6 m along the same line, but never through a wall.
			toward = toward.normalized() if toward.length() > 0.01 else Vector3.BACK
			var level := Vector3(at.x, eye.y, at.z)
			var want := level + toward * 1.6
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(level, want, 1, [player.get_rid()]))
			from = want if hit.is_empty() else level + toward * maxf(0.5, level.distance_to(hit.position) - 0.25)
		var was := [coin.spin_speed, coin.bob_height, coin.rotation]
		coin.spin_speed = 0.0
		coin.bob_height = 0.0
		if not spots[id].has("face"):
			coin.look_at(from, Vector3.UP)
		await _view(at, from, "coin-" + id.replace("_", "-"))
		coin.spin_speed = was[0]
		coin.bob_height = was[1]
		coin.rotation = was[2]
	player.visible = true

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
	# force_draw, not frame_post_draw: macOS stops drawing a window hidden behind others, and
	# waiting for its next frame hung the run for good (22 Nov 2026).
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("%s/%s.png" % [ProjectSettings.globalize_path(OUT), title])
	print("wrote ", title)
