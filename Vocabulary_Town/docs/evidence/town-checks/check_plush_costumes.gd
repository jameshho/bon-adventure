extends SceneTree
## Plush outfits (data/plush_costumes.json, scripts/characters/plush_costume.gd).
## Loads Main: run in an isolated test copy (README "Verification").
## godot --headless --path . --script res://docs/evidence/town-checks/check_plush_costumes.gd
## 1. Every outfit on every plush, in the shared seated pose: pieces exist, carry no
##    collision, garments (shirts, aprons, overalls, ties) stay outside the unsmoothed body (fur and wool included),
##    caps and straw-hat crowns clear the ears, pressed hair stays under the hat and tucked parts
##    (Leo's mane) stay inside the shirt.
## 2. In Main: every character has its unique id as node name and `character_id`;
##    dressing the placed Home plushes changes neither their transforms nor
##    the extents placement reads, clicks still resolve to the name card without
##    counting as study, and hover highlighting reaches the costume.

const SPECIES := ["pig", "lion", "bear", "cat", "samoyed", "sheep", "golden", "beagle", "crocodile"]
const PlushCostume := preload("res://scripts/characters/plush_costume.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func to_npc(npc: Node3D, mesh: Node3D) -> Transform3D:
	var t := mesh.transform
	var parent := mesh.get_parent()
	while parent != npc:
		t = (parent as Node3D).transform * t
		parent = parent.get_parent()
	return t

func points(npc: Node3D, mesh: MeshInstance3D) -> PackedVector3Array:
	var t := to_npc(npc, mesh)
	var result := PackedVector3Array()
	for v in mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		result.append(t * v)
	return result

func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/plush_costumes.json"))
	var placer = load("res://scripts/characters/house_characters.gd").new()
	for species in SPECIES:
		check(data["species"].has(species + "_plush"), "Fit anchors for " + species)
		for outfit in data["outfits"]:
			var npc: Node3D = load("res://scenes/characters/%s_plush.tscn" % species).instantiate()
			root.add_child(npc)
			placer._sit(npc)
			var label := "%s/%s" % [species, outfit]
			# Raw body reach per (height band, direction): no smoothing, so fur peaks count.
			var reach := {}
			for mesh in npc.get_node("Torso").find_children("*", "MeshInstance3D", true, false):
				for p in points(npc, mesh):
					var key := Vector2i(roundi(p.y / 0.01), posmod(roundi(atan2(p.z, p.x) / TAU * 48.0), 48))
					reach[key] = maxf(reach.get(key, 0.0), Vector2(p.x, p.z).length())
			var costume := PlushCostume.dress(npc, outfit)
			var pieces := costume.find_children("*", "MeshInstance3D", true, false)
			check(pieces.size() > 3, "Pieces built: " + label)
			check(costume.find_children("*", "CollisionObject3D", true, false).is_empty(), "No costume collision: " + label)
			var inside := 0
			for piece in pieces:
				if not (piece.name.begins_with("Shirt") or piece.name.begins_with("Apron") or piece.name.begins_with("Overalls") or piece.name.begins_with("Bib") or piece.name.begins_with("Tie")):
					continue
				for p in points(npc, piece):
					var key := Vector2i(roundi(p.y / 0.01), posmod(roundi(atan2(p.z, p.x) / TAU * 48.0), 48))
					if Vector2(p.x, p.z).length() < reach.get(key, 0.0) - 0.005:
						inside += 1
			check(inside == 0, "Garments outside the body: %s (%d vertices inside)" % [label, inside])
			for path in data["species"][species + "_plush"].get("tuck", {}).get("shirt", []):
				var collar := float(data["species"][species + "_plush"]["collar_y"])
				var out := 0
				for p in points(npc, npc.get_node(str(path))):
					if p.y < collar - 0.02 and Vector2(p.x, p.z).length() > costume._radius(costume._body, atan2(p.z, p.x), p.y) + PlushCostume.CLEARANCE:
						out += 1
				check(out == 0, "Tucked under the shirt: %s %s (%d vertices out)" % [label, path, out])
			var band := costume.find_children("CapBand*", "MeshInstance3D", true, false)
			if not band.is_empty():
				var box: AABB = to_npc(npc, band[0]) * (band[0] as MeshInstance3D).get_aabb()
				var crown: AABB = to_npc(npc, costume.find_children("CapCrown*", "MeshInstance3D", true, false)[0]) * costume.find_children("CapCrown*", "MeshInstance3D", true, false)[0].get_aabb()
				# The crown's own width per 0.02 height band (a toque's puffy top is wider
				# than its body, so its bounding box would be too strict lower down).
				var crown_node: MeshInstance3D = costume.find_children("CapCrown*", "MeshInstance3D", true, false)[0]
				var widths := {}
				for p in points(npc, crown_node):
					var k := roundi(p.y / 0.02)
					widths[k] = maxf(widths.get(k, 0.0), Vector2(p.x, p.z - box.get_center().z).length())
				var hits := 0
				for ear in npc.find_children("*Ear", "MeshInstance3D", true, false):
					for p in points(npc, ear):
						var flat := Vector2(p.x, p.z - box.get_center().z).length()
						var k := roundi(p.y / 0.02)
						var width := maxf(widths.get(k, 0.0), maxf(widths.get(k - 1, 0.0), widths.get(k + 1, 0.0)))
						if (p.y > box.position.y and p.y < box.end.y and flat < box.size.x * 0.5) or (p.y > crown.position.y and p.y < crown.end.y and flat < width):
							hits += 1
				check(hits == 0, "Cap clears the ears: %s (%d ear vertices inside)" % [label, hits])
				# Pressed hair (Leo's mane, Poppy's wool) stays below the band under the cap.
				for path in data["species"][species + "_plush"].get("press", {}).get("cap", []):
					var poking := 0
					for p in points(npc, npc.get_node(str(path))):
						if p.y > box.position.y + 0.01 and Vector2(p.x, p.z - box.get_center().z).length() < crown.size.x * 0.5:
							poking += 1
					check(poking == 0, "Hair stays under the cap: %s %s (%d vertices out)" % [label, path, poking])
			# Straw hat: the crown clears the ears (they poke through the brim by design)
			# and pressed hair stays under the brim.
			var straw := costume.find_children("StrawCrown*", "MeshInstance3D", true, false)
			if not straw.is_empty():
				var crown: AABB = to_npc(npc, straw[0]) * (straw[0] as MeshInstance3D).get_aabb()
				var brim_node: MeshInstance3D = costume.find_children("StrawBrim*", "MeshInstance3D", true, false)[0]
				var brim: AABB = to_npc(npc, brim_node) * brim_node.get_aabb()
				var hits := 0
				for ear in npc.find_children("*Ear", "MeshInstance3D", true, false):
					for p in points(npc, ear):
						if p.y > crown.position.y and p.y < crown.end.y and Vector2(p.x, p.z - crown.get_center().z).length() < crown.size.x * 0.5:
							hits += 1
				check(hits == 0, "Straw hat crown clears the ears: %s (%d ear vertices inside)" % [label, hits])
				for path in data["species"][species + "_plush"].get("press", {}).get("straw_hat", []):
					var poking := 0
					for p in points(npc, npc.get_node(str(path))):
						var d := Vector2(p.x, p.z - brim.get_center().z).length()
						if d < brim.size.x * 0.48 and p.y > costume._brim_under(d) + 0.002:
							poking += 1
					check(poking == 0, "Hair stays under the straw hat: %s %s (%d vertices out)" % [label, path, poking])
			npc.free()
	await integration()
	print("Plush costume check: %d checks, %d failures" % [checks, failures.size()])
	for failure in failures:
		print("FAIL ", failure)
	quit(1 if failures.size() > 0 else 0)

func integration() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	for i in range(3):
		await physics_frame
	var placer = load("res://scripts/characters/house_characters.gd").new()
	var outfits: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/plush_costumes.json"))["outfits"].keys()
	var studied := [0]
	game.interaction.word_studied.connect(func(_key: String) -> void: studied[0] += 1)
	# Only the plushes: HouseCharacters also holds the "Bedtime" helper node (since 20faa87).
	var npcs: Array = game.get_node("HouseCharacters").get_children().filter(func(n: Node) -> bool: return n is Node3D)
	check(npcs.size() == 9, "Nine Home plushes")
	var ids := {}
	for spec in JSON.parse_string(FileAccess.get_file_as_string("res://data/house_characters.json"))["characters"]:
		check(not ids.has(spec["id"]), "Unique character id: " + str(spec["id"]))
		ids[spec["id"]] = true
	for npc in npcs:
		check(ids.has(str(npc.name)) and npc.get_meta("character_id", "") == str(npc.name), "Node named by its id: " + str(npc.name))
	for i in range(npcs.size()):
		var npc: Node3D = npcs[i]
		var before: Transform3D = npc.global_transform
		var down: float = placer._extent(npc, Vector3.DOWN)
		var away: float = placer._extent(npc, npc.global_basis.z)
		var costume: Node3D = npc.get_node_or_null("Costume")
		if costume == null:
			costume = PlushCostume.dress(npc, outfits[i % outfits.size()])
		check(npc.global_transform.is_equal_approx(before), "Dressing keeps placement: " + npc.name)
		check(is_equal_approx(placer._extent(npc, Vector3.DOWN), down) and is_equal_approx(placer._extent(npc, npc.global_basis.z), away), "Placement extents ignore the costume: " + npc.name)
		var target: Node3D = game.interaction.vocabulary_target(npc.get_node("StudyArea"), game.apartment, game.doors)
		check(target == npc and target.has_meta("character_name"), "Click resolves to the name card: " + npc.name)
		game.interaction.show_word(npc)
		game.interaction.highlight_object(npc, true)
		var piece: MeshInstance3D = costume.get_child(0)
		check(piece.material_overlay != null, "Hover highlight covers the costume: " + npc.name)
		game.interaction.highlight_object(npc, false)
	check(studied[0] == 0, "Name cards do not count as study (%d emitted)" % studied[0])
	game.queue_free()
	await process_frame
