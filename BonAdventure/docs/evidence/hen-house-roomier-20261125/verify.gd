extends SceneTree
## Roomier hen house with clay hens (user, 25 Nov 2026: "the new hen should replace the old ones,
## remove all the old ones and related files"; "improve the interior of the hen house and make it
## bigger by 20%. also fix the flickering, the baskets in the house is flickering"): the base step
## `hen_clay_roams` (scripts/buildings/base.gd) and the barn step `roomier_hen_house`
## (scripts/buildings/barn.gd). Adapted from ../hen-house-walkin-20261124/verify.gd, whose egg,
## crate, Drop and off-farm checks it keeps.
## New checks: every coop size is the walk-in coop's times 1.2; the farm hen ParkZoo/Hen and the
## six hen-house hens are the clay hen (same size, word "hen"), the old hen scene and the still
## clay display are gone; no two hen-house faces of different colours share a plane where they
## overlap (the flicker). With a window it also takes pictures.
##   HOME=<scratch> VT_FOCUS=barn VT_SPAWN=none VT_NEARBY=0 godot --path . --resolution 1200x800 \
##     --script res://docs/evidence/hen-house-roomier-20261125/verify.gd
## Writes saves only in the isolated HOME.
const OUT := "res://docs/evidence/hen-house-roomier-20261125"
const Barn := preload("res://scripts/buildings/barn.gd")
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
	_walk_in()
	var hens: Array = house.get_node("Hens").get_children()
	check(hens.size() == 6, "6 hens (%d)" % hens.size())
	check(hens.all(func(h): return h.is_in_group("wandering_animals")), "every hen wanders")
	var coop_rect := Rect2(Barn.ROOMY_COOP.x - Barn.ROOMY_W2, Barn.ROOMY_COOP.z - Barn.ROOMY_D2, Barn.ROOMY_W2 * 2, Barn.ROOMY_D2 * 2)
	check(hens.filter(func(h): return coop_rect.has_point(Vector2(h.position.x, h.position.z))).size() == 2, "two hens live inside the coop")
	_clay_hens(hens)
	_flicker()
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
	# Make sure there are at least five eggs for the rest (and for the pictures).
	while _eggs().size() < 5:
		house.state.eggs.append({"spot": _free_spot(), "gold": _eggs().size() == 1, "brown": _eggs().size() == 2})
		house._spawn(house.state.eggs.back(), false)
	if graphics:
		await _pictures_before()
	await _carry_and_deliver()
	await _drop()
	print("HEN HOUSE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## The coop's size and that BonBon walks in: the capsule is free at the doorway and inside.
func _walk_in() -> void:
	var sizes := {"width": [Barn.WALK_W2, Barn.ROOMY_W2], "depth": [Barn.WALK_D2, Barn.ROOMY_D2],
		"eave": [Barn.WALK_EAVE - Barn.LAWN, Barn.ROOMY_EAVE - Barn.LAWN], "ridge": [Barn.WALK_RIDGE - Barn.LAWN, Barn.ROOMY_RIDGE - Barn.LAWN],
		"doorway width": [Barn.WALK_DOOR_W2, Barn.ROOMY_DOOR_W2], "doorway height": [Barn.WALK_DOOR_H, Barn.ROOMY_DOOR_H]}
	for key in sizes:
		check(is_equal_approx(sizes[key][1], sizes[key][0] * 1.2), "coop %s is 1.2 times the walk-in coop's (%.2f -> %.2f)" % [key, sizes[key][0], sizes[key][1]])
	check(Barn.ROOMY_DOOR_H > height / 1.3 + .4, "doorway %.1f high for BonBon %.2f (town units)" % [Barn.ROOMY_DOOR_H, height / 1.3])
	var space := ap.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = height
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = capsule
	q.collision_mask = 1
	q.exclude = [player.get_rid()]
	var c := Barn.ROOMY_COOP
	var points := {"outside the door": Vector3(c.x - Barn.ROOMY_W2 - 1.0, 0, c.z), "in the doorway": Vector3(c.x - Barn.ROOMY_W2, 0, c.z),
		"just inside": Vector3(c.x - Barn.ROOMY_W2 + 1.0, 0, c.z), "the middle": Vector3(c.x, 0, c.z), "by the nest boxes": Vector3(c.x + 2.2, 0, c.z)}
	for label in points:
		var p: Vector3 = points[label]
		var at := town(p.x, .12, p.z)
		q.transform = Transform3D(Basis.IDENTITY, at + Vector3(0, height * .5 + radius * 0 + .05, 0))
		check(space.intersect_shape(q, 1).is_empty(), "BonBon's body fits %s" % label)
	# The walls are solid: the body does not fit through the back wall.
	q.transform = Transform3D(Basis.IDENTITY, town(c.x + Barn.ROOMY_W2, .12, c.z) + Vector3(0, height * .5 + .05, 0))
	check(not space.intersect_shape(q, 1).is_empty(), "the back wall is solid")

## The farm hen and the hen-house hens are the clay hen; the old hen is gone.
func _clay_hens(hens: Array) -> void:
	var zoo: Node3D = ap.get_node("ParkZoo")
	var farm_hen: Node3D = zoo.get_node_or_null("Hen")
	check(farm_hen != null and farm_hen.has_node("ClayHen") and str(farm_hen.get_meta("word_key", "")) == "hen", "ParkZoo/Hen is the clay hen with the word hen")
	check(zoo.get_node_or_null("HenClayDisplay") == null, "the still clay hen display is gone")
	check(not ResourceLoader.exists("res://scenes/animals/hen.tscn"), "the old hen scene is deleted")
	var height := func(h: Node3D) -> float: return (h.call("_visible_bounds") as AABB).size.y * (ap.global_transform.affine_inverse() * h.global_transform).basis.get_scale().y
	var want: float = height.call(farm_hen)
	var clay := hens.filter(func(h): return h.has_node("ClayHen") and h.scene_file_path == "" and str(h.get_meta("word_key", "")) == "hen" and h.has_node("VocabularyArea"))
	check(clay.size() == 6, "all 6 hen-house hens are clay hens with the word and a picking area (%d)" % clay.size())
	check(hens.all(func(h): return absf(height.call(h) - want) < .01), "the hen-house hens are the farm hen's height (%.3f)" % want)
	var stray := ap.find_children("*", "", true, false).filter(func(n): return n.scene_file_path.ends_with("/hen.tscn"))
	check(stray.is_empty(), "nothing in the town instances the old hen (%d)" % stray.size())

## Flicker: faces of two different-coloured parts lying in one plane, facing the same way and
## overlapping. Read from the saved scenes/town/barn.scn (the running town batches static boxes
## into MultiMeshes): each axis-aligned box and upright cylinder under the hen house, hens left
## out, gives its six (or two cap) faces in the hen house frame; tilted parts are skipped.
func _flicker() -> void:
	var unit: Node = (load("res://scenes/town/barn.scn") as PackedScene).instantiate()
	var saved: Node3D = unit.find_child("Hen house", true, false)
	var faces := []
	var count := 0
	for mesh: MeshInstance3D in saved.find_children("*", "MeshInstance3D", true, false):
		if saved.get_node("Hens").is_ancestor_of(mesh):
			continue
		if not (mesh.mesh is BoxMesh or mesh.mesh is CylinderMesh):
			continue
		var xf := Transform3D.IDENTITY
		var node: Node = mesh
		while node != saved:
			xf = (node as Node3D).transform * xf
			node = node.get_parent()
		var b := xf.basis.orthonormalized()
		var aligned := true
		for axis in 3:
			var v := b[axis]
			if not (is_equal_approx(absf(v.x), 1.0) or is_equal_approx(absf(v.y), 1.0) or is_equal_approx(absf(v.z), 1.0)):
				aligned = false
		if not aligned:
			continue
		if mesh.mesh is CylinderMesh and not is_equal_approx(absf(b.y.y), 1.0):
			continue
		count += 1
		var box: AABB = xf * mesh.get_aabb()
		var colour: Color = (mesh.material_override as StandardMaterial3D).albedo_color if mesh.material_override is StandardMaterial3D else Color.WHITE
		for axis in 3:
			if mesh.mesh is CylinderMesh and axis != 1:
				continue
			for side in [-1, 1]:
				var plane: float = box.position[axis] if side < 0 else box.end[axis]
				faces.append([axis, side, plane, box, colour, mesh])
	var bad := []
	for i in faces.size():
		for j in range(i + 1, faces.size()):
			var f: Array = faces[i]
			var g: Array = faces[j]
			if f[0] != g[0] or f[1] != g[1] or f[5] == g[5] or absf(f[2] - g[2]) > .002 or (f[4] as Color).is_equal_approx(g[4]):
				continue
			var overlap := 1.0
			for axis in 3:
				if axis == f[0]:
					continue
				overlap *= minf(f[3].end[axis], g[3].end[axis]) - maxf(f[3].position[axis], g[3].position[axis])
			var lap0 := minf(f[3].end[(f[0] + 1) % 3], g[3].end[(f[0] + 1) % 3]) - maxf(f[3].position[(f[0] + 1) % 3], g[3].position[(f[0] + 1) % 3])
			var lap1 := minf(f[3].end[(f[0] + 2) % 3], g[3].end[(f[0] + 2) % 3]) - maxf(f[3].position[(f[0] + 2) % 3], g[3].position[(f[0] + 2) % 3])
			if lap0 > .001 and lap1 > .001 and overlap > 1e-5:
				bad.append("%s / %s" % [f[5].get_parent().name, g[5].get_parent().name])
	for line in bad.slice(0, 12):
		print("  coplanar: ", line)
	check(count > 150 and bad.is_empty(), "no two hen-house parts of different colours flicker in one plane (%d axis-aligned parts, %d pairs)" % [count, bad.size()])
	unit.free()

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
	for i in 30: await process_frame
	check(game.hud.quest_toast.text == UiText.t("toast.egg_take_to_crate"), "toast on taking it: %s" % game.hud.quest_toast.text)
	check(house._arrow.visible, "an arrow shows over the crate while the egg is carried")
	check(game.hold_ui.drop_button.visible, "the Drop button shows")
	check(Interactable.on(house.crate).check() == true, "the crate takes the egg in the hand")
	var t := Barn.ROOMY_CRATE_TABLE
	await _stand_at(town(t.x - 1.1, .12 + 1.2, t.z - .3), town(t.x, .9, t.z))
	house.deliver()
	await process_frame
	check(hand.held == null and egg.get_parent() == house.slots[0], "E on the crate: the egg is in the first cup")
	for i in 30: await process_frame
	check(not house._arrow.visible and not game.hold_ui.drop_button.visible, "empty hand: no arrow, no Drop button")
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
		for i in 30: await process_frame
		await _shot(town(t.x - 3.2, 2.4, t.z - 2.4), town(t.x, 1.2, t.z), "carrying-arrow")
		await _player_view("carrying-hud")
		hand.release()
		for i in 30: await process_frame

func _drop() -> void:
	# The Drop button: the egg breaks at BonBon's feet.
	var hand0: Node3D = HandHold.of_player(house)
	var first: Node3D = _eggs()[0]
	var count: int = house.state.eggs.size()
	await _stand_at(first.global_position + Vector3(0, 1.0, 1.0), first.global_position)
	first.use()
	for i in 30: await process_frame
	game.hold_ui.drop_held()
	await process_frame
	check(hand0.held == null and (not is_instance_valid(first) or first.is_queued_for_deletion()), "Drop: the egg leaves the hand")
	check(house.state.eggs.size() == count - 1, "Drop: the egg is no longer laid")
	check(game.hud.quest_toast.text == UiText.t("toast.egg_dropped"), "Drop: toast %s" % game.hud.quest_toast.text)
	check(house.get_node_or_null("Broken egg") != null, "Drop: a broken egg lies at her feet")
	for i in 220: await process_frame

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
	var c := Barn.ROOMY_COOP
	await _shot(town(70.0, 11.0, 90.0), town(81.0, .5, 77.0), "aerial")
	await _shot(town(74.5, 2.6, 80.5), town(c.x - 1.0, 1.4, c.z), "coop-door")
	await _shot(town(c.x - 3.8, 1.7, c.z - .2), town(c.x + 4.0, .9, c.z + .2), "inside")
	await _shot(town(c.x + 3.2, 2.1, c.z - 2.3), town(c.x - 4.0, .9, c.z + 1.2), "inside-to-door")
	await _shot(town(c.x + 1.2, 1.5, c.z + .6), town(c.x + 3.6, .9, c.z - .3), "nest-boxes")
	await _shot(town(c.x - 1.0, 1.8, c.z + 1.2), town(c.x - .6, 1.0, c.z - 2.8), "roost")
	await _shot(town(c.x + 1.0, 1.6, c.z - .8), town(c.x - 2.6, .4, c.z + 2.2), "feeder-dust-bath")
	await _shot(town(66.0, 2.4, 88.0), town(81.0, 1.0, 77.5), "from-barn-door")
	var farm_hen: Node3D = ap.get_node("ParkZoo/Hen")
	farm_hen.set_process(false)
	var hp := farm_hen.global_position
	await _shot(hp + Vector3(1.6, 1.3, -2.2), hp + Vector3(0, .5, 0), "farm-hen")
	game.hud.show()

## BonBon walked in the doorway, the game's own camera behind her.
func _player_view(file: String) -> void:
	var c := Barn.ROOMY_COOP
	if camera != null:
		camera.current = false
	game.camera.current = true
	player.velocity = Vector3.ZERO
	player.global_position = town(c.x - Barn.ROOMY_W2 - 1.6, .12 + 1.2, c.z + .6)
	player.look_at(town(Barn.ROOMY_CRATE_TABLE.x, 1.2, Barn.ROOMY_CRATE_TABLE.z) * Vector3(1, 0, 1) + Vector3(0, player.global_position.y, 0), Vector3.UP)
	for i in 60: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "/" + file + ".png")

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
