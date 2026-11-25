extends SceneTree
## STALE since 24 Nov 2026 (walk-in coop; the runner uses ../hen-house-walkin-20261124/verify.gd).
## Hen house and eggs (24 Nov 2026, user): scripts/world/hen_house.gd, farm_egg.gd, the barn step
## `hen_house` (scripts/buildings/barn.gd). Checks: the coop, 11 egg spots, 12 crate cups and 6
## hens are in the barn unit; the hens wander inside their yard; a fresh profile finds eggs; the
## laying odds (2000 simulated 15-minute absences: about 3 to 4 eggs, never more than 7, about 3%
## golden); every spot is reachable by BonBon's body; an egg goes into the hand, then into the
## crate (saved); an egg carried out of the farm is dropped with the toast; the crate empties.
## With a window it also takes pictures (before the checks that move eggs).
##   HOME=<scratch> VT_FOCUS=barn VT_SPAWN=none VT_NEARBY=0 godot --path . --resolution 1200x800 \
##     --script res://docs/evidence/hen-house-20261124/verify.gd
## Writes saves only in the isolated HOME.
const OUT := "res://docs/evidence/hen-house-20261124"
const HenHouse := preload("res://scripts/world/hen_house.gd")
const FarmEgg := preload("res://scripts/world/farm_egg.gd")
const HandHold := preload("res://scripts/player/hand_hold.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")

var checks := 0
var failures := 0
var graphics := false
var game
var ap: Node3D
var house: Node3D
var player: CharacterBody3D
var camera: Camera3D
var radius := .76
var height := 2.2

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func town(x: float, y: float, z: float) -> Vector3:
	return ap.to_global(Vector3(x, y, z))

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
	player = game.player
	for shape: CollisionShape3D in player.find_children("*", "CollisionShape3D", true, false):
		if shape.shape is CapsuleShape3D and not shape.disabled:
			radius = (shape.shape as CapsuleShape3D).radius * shape.global_basis.get_scale().x
			height = (shape.shape as CapsuleShape3D).height * shape.global_basis.get_scale().y
			break
	house = ap.get_node_or_null("Barn/Hen house")
	check(house != null and house.get_script() == HenHouse, "Barn/Hen house with hen_house.gd")
	if house == null:
		quit(1)
		return
	check(house.global_transform.is_equal_approx(ap.global_transform), "the hen house's frame is the town's")
	check(house.spots.size() == 11, "11 egg spots (%d)" % house.spots.size())
	check(house.slots.size() == 12, "12 egg cups in the crate (%d)" % house.slots.size())
	var hens: Array = house.get_node("Hens").get_children()
	check(hens.size() == 6, "6 hens (%d)" % hens.size())
	check(hens.all(func(h): return h.is_in_group("wandering_animals")), "every hen wanders")
	# A fresh profile: FIRST_ROLLS rolls made at load.
	var eggs := _eggs()
	check(eggs.size() == (house.state.eggs as Array).size() and eggs.size() <= HenHouse.CAP, "fresh profile: %d eggs laid and shown" % eggs.size())
	check(FileAccess.file_exists(SaveStore.path(HenHouse.FILE)), "hen_house.json saved")
	_odds()
	_reach()
	# Hens stay in their yard.
	for i in 240: await physics_frame
	var inside := hens.all(func(h): return HenHouse.HEN_YARD.grow(.05).has_point(Vector2(h.position.x, h.position.z)))
	check(inside, "after 4 s the hens are inside their yard")
	# Make sure there are at least three eggs for the rest (and for the pictures).
	while _eggs().size() < 3:
		house.state.eggs.append({"spot": _free_spot(), "gold": _eggs().size() == 1, "brown": _eggs().size() == 2})
		house._spawn(house.state.eggs.back(), false)
	if graphics:
		await _pictures_before()
	await _carry_and_deliver()
	await _drop()
	print("HEN HOUSE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _eggs() -> Array:
	return house.find_children("*", "Node3D", true, false).filter(func(n): return n.get_script() == FarmEgg and not n.delivered)

func _free_spot() -> int:
	var used := {}
	for e in house.state.eggs:
		used[int(e.spot)] = true
	for i in house.spots.size():
		if not used.has(i):
			return i
	return -1

## 2000 simulated absences of 15 minutes from an empty hen house, and 2000 of 2 hours.
func _odds() -> void:
	var saved: Dictionary = house.state.duplicate(true)
	var total := 0
	var most := 0
	var golds := 0
	var laid := 0
	var counts := {}
	for t in 2000:
		house.state = {"eggs": [], "rolled_at": 0}
		for r in 15:
			house._roll(false)
		var n: int = house.state.eggs.size()
		total += n
		counts[n] = int(counts.get(n, 0)) + 1
		laid += n
		golds += (house.state.eggs as Array).filter(func(e): return e.gold).size()
	var long_most := 0
	for t in 2000:
		house.state = {"eggs": [], "rolled_at": 0}
		for r in 120:
			house._roll(false)
		long_most = maxi(long_most, house.state.eggs.size())
		most = maxi(most, house.state.eggs.size())
	house.state = saved
	var mean := total / 2000.0
	print("15 min: mean %.2f eggs, spread %s; golden %.1f%%" % [mean, str(counts), 100.0 * golds / maxf(laid, 1)])
	check(mean > 3.0 and mean < 4.2, "15 minutes away: about 3 to 4 eggs (mean %.2f)" % mean)
	check(int(counts.get(5, 0)) + int(counts.get(6, 0)) + int(counts.get(7, 0)) < 2000 * .25, "15 minutes: 5 or more eggs is the rarer case")
	check(long_most == HenHouse.CAP, "never more than 7 eggs, and 7 can happen (most %d)" % long_most)
	var gold_share := float(golds) / maxf(laid, 1)
	check(gold_share > .015 and gold_share < .05, "about 3%% of eggs are golden (%.1f%%)" % (100.0 * gold_share))

## Each spot: nothing solid in the egg, and a free spot for BonBon's capsule within reach.
func _reach() -> void:
	var space := ap.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = height
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = capsule
	q.collision_mask = 1
	q.exclude = [player.get_rid()]
	var ball := SphereShape3D.new()
	ball.radius = FarmEgg.RADIUS * 1.3
	var qe := PhysicsShapeQueryParameters3D.new()
	qe.shape = ball
	qe.collision_mask = 1
	for i in house.spots.size():
		var spot: Node3D = house.spots[i]
		var egg_at := spot.to_global(Vector3(0, FarmEgg.RADIUS * FarmEgg.TALL, 0))
		qe.transform = Transform3D(Basis.IDENTITY, egg_at)
		var inside := space.intersect_shape(qe, 4)
		check(inside.is_empty(), "spot %d: nothing solid in the egg" % (i + 1))
		var ground := ap.to_global(Vector3(0, .12, 0)).y
		var found := false
		for ring in [.9, 1.15, 1.4]:
			for k in 16:
				var a := TAU * k / 16.0
				var stand := Vector3(egg_at.x + cos(a) * ring, ground + height * .5 + radius + .02, egg_at.z + sin(a) * ring)
				q.transform = Transform3D(Basis.IDENTITY, stand)
				if space.intersect_shape(q, 1).is_empty():
					found = true
					break
			if found:
				break
		check(found, "spot %d: BonBon can stand within 1.4 m of it (E range 1.6 m)" % (i + 1))

func _stand_at(p: Vector3, look: Vector3) -> void:
	player.velocity = Vector3.ZERO
	player.global_position = p
	player.look_at(Vector3(look.x, p.y, look.z), Vector3.UP)
	for i in 8: await physics_frame

func _carry_and_deliver() -> void:
	var hand: Node3D = HandHold.of_player(house)
	check(hand != null, "the player has a hand")
	var egg: Node3D = _eggs()[0]
	var before: int = house.state.eggs.size()
	await _stand_at(egg.global_position + Vector3(0, 1.0, 1.0), egg.global_position)
	egg.use()
	check(hand.held == egg, "E on an egg: it is in the hand")
	check(Interactable.on(house.crate).check() == true, "the crate takes the egg in the hand")
	await _stand_at(town(69.0, .16 + 1.2, 82.6), town(69.0, .9, 83.7))
	house.deliver()
	await process_frame
	check(hand.held == null and egg.get_parent() == house.slots[0], "E on the crate: the egg is in the first cup")
	check(house.state.eggs.size() == before - 1, "the delivered egg is no longer laid (%d -> %d)" % [before, house.state.eggs.size()])
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(SaveStore.path(HenHouse.FILE)))
	check(saved is Dictionary and (saved.eggs as Array).size() == before - 1, "and that is saved")
	var line: String = game.hud.quest_toast.text
	check(line == UiText.t("toast.egg_in_crate", {"count": "1"}) or line == UiText.t("toast.golden_egg"), "toast: %s" % line)
	check(Interactable.on(house.crate).check() is String, "with an empty hand the crate says what it is for")
	if graphics:
		# A second egg in the crate, BonBon holding a third (seen in her hand in crate.png).
		var second: Node3D = _eggs()[0]
		second.use()
		house.deliver()
		await process_frame
		var third: Node3D = _eggs()[0]
		third.use()
		await _shot(town(70.6, 2.1, 81.4), town(68.9, .8, 83.8), "crate")
		hand.release()

func _drop() -> void:
	var hand: Node3D = HandHold.of_player(house)
	var egg: Node3D = _eggs()[0]
	var before: int = house.state.eggs.size()
	await _stand_at(egg.global_position + Vector3(0, 1.0, 1.0), egg.global_position)
	egg.use()
	check(hand.held == egg, "a second egg in the hand")
	# Out of the farm gate (north fence, z 109) onto the path.
	await _stand_at(town(66.0, 1.4, 112.0), town(66.0, 1.0, 118.0))
	for i in 30: await process_frame
	check(hand.held == null and not is_instance_valid(egg) or (is_instance_valid(egg) and egg.is_queued_for_deletion()), "out of the farm: the egg is gone from the hand")
	check(house.state.eggs.size() == before - 1, "the dropped egg is no longer laid")
	check(game.hud.quest_toast.visible and game.hud.quest_toast.text == UiText.t("toast.egg_dropped"), "toast: %s" % game.hud.quest_toast.text)
	check(house.get_node_or_null("Broken egg") != null, "a broken egg lies on the path")
	check(house._in_crate.is_empty(), "leaving the farm empties the crate")
	if graphics:
		var splat: Node3D = house.get_node_or_null("Broken egg")
		await _shot(splat.global_position + Vector3(-2.2, 2.6, 2.4), splat.global_position, "dropped")

func _pictures_before() -> void:
	game.hud.hide()
	await _shot(town(91.0, 9.0, 88.0), town(76.0, .5, 78.0), "aerial")
	await _shot(town(79.0, 1.6, 82.2), town(79.0, .8, 77.0), "coop-front")
	await _shot(town(74.0, 1.5, 79.8), town(79.0, .8, 76.4), "coop-ramp")
	await _shot(town(79.0, 1.6, 71.2), town(79.0, .6, 76.0), "coop-back")
	await _shot(town(66.0, 2.2, 88.0), town(69.0, .9, 83.4), "barn-door")
	game.hud.show()

func _shot(from: Vector3, at: Vector3, file: String) -> void:
	if camera == null:
		camera = Camera3D.new()
		game.add_child(camera)
		camera.fov = 60.0
		camera.far = 900.0
	camera.current = true
	camera.global_position = from
	camera.look_at(at)
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "/" + file + ".png")
	camera.current = false
