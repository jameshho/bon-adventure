extends RefCounted
## Home own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## home unit (scenes/town/home.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- home
## Never rename or remove a baked step (add a new one that undoes it).
const STEPS := ["solid_roofs", "bath_fixtures", "mahjong_table", "mahjong_chair_back", "toilet_flush_control", "electrical_box", "coplanar_gaps", "coplanar_gaps_2", "interaction_metas", "house_expansion", "house_furnishing", "door_heights", "family_bath_layout", "family_bath_window", "family_bath_door_inward", "clear_walkway_plants", "garage_bicycle_removed", "record_player"]
## The mahjong table in the front yard (user request, 9 Nov 2026; docs/guides/MAHJONG.md): its centre in
## town coordinates (west of the entry path, north of the front door, near the spawn point),
## sizes in town units. Seat 0 (the player's, Mei's until a game starts) is on the north side;
## seats 1-3 follow the order of play (counter-clockwise from above: +X, south, -X).
const MAHJONG_CENTER := Vector3(-3.6, 0.0, 51.0)
## Plush scale, like the oak dining table (top 1.06, chairs 1.85 from the centre, seats 0.55): the
## seated plush players are about 1.7 tall.
const MAHJONG_TOP := 1.0
const MAHJONG_SIZE := 2.0
const MAHJONG_CHAIR_DISTANCE := 1.75
const MAHJONG_SEAT := 0.55
const MAHJONG_SEATS := [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0)]
const BathFixtures := preload("res://scripts/world/bath_fixtures.gd")

## Collision for the decorative roofs and canopies (7 Nov 2026; scripts/buildings/roof_solids.gd).
func solid_roofs(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/roof_solids.gd").add(town, [
		"RelocatedSites/Home/Home roof",
	])

## Working toilets and faucets (user request, 8 Nov 2026; docs/guides/TOWN_DESIGN_BRIEF.md "Bathroom
## fixtures"). In both bathrooms the three-shape toilet (base, seat, cistern) becomes the rounded
## interactive toilet, its cistern against the back wall, word "toilet"; the flat washbasin disc
## becomes a vessel basin (same root, word "sink", pick area) with a brass faucet behind it, spout
## toward the door side (+Z). The kitchen's two tap pieces (both word "faucet") become one chrome
## gooseneck faucet in the same place, keeping the "Sink tap" name.
func bath_fixtures(town: Node3D, _game) -> void:
	var site: Node3D = town.get_node("RelocatedSites/Home")
	var toilets := []
	var basins := []
	for child in site.get_children():
		match str(child.get_meta("word_key", "")):
			"toilet": toilets.append(child)
			"sink":
				if child.position.x < 0: basins.append(child)
	if toilets.size() != 2 or basins.size() != 2:
		push_error("bath_fixtures: expected 2 toilets and 2 bathroom sinks, found %d / %d" % [toilets.size(), basins.size()])
		return
	for old in toilets:
		var base: Vector3 = old.position
		var room := "Guest bathroom" if base.z < 0 else "Family bathroom"
		# The seat and cistern are siblings at fixed offsets from the base (24 Oct layout).
		for part in site.get_children():
			if part == old or not part is Node3D: continue
			var offset: Vector3 = part.position - base
			if offset.distance_to(Vector3(0, .32, 0)) < .01 or offset.distance_to(Vector3(0, .52, -.45)) < .01:
				_free(part)
		var index: int = old.get_index()
		_free(old)
		# Back of the new cistern against the wall behind (-Z).
		var from := site.to_global(Vector3(base.x, 1.0, base.z))
		var ray := PhysicsRayQueryParameters3D.create(from, site.to_global(Vector3(base.x, 1.0, base.z - 3.0)))
		var hit := town.get_world_3d().direct_space_state.intersect_ray(ray)
		var back := base.z - .6
		if not hit.is_empty():
			back = site.to_local(hit.position).z + .01
		var toilet := BathFixtures.add_toilet(site, room + " toilet", Vector3(base.x, .03, back), 0.0, "home")
		site.move_child(toilet, index)
		print("bath_fixtures: %s at z %.2f (wall hit: %s)" % [toilet.name, back, not hit.is_empty()])
	for basin in basins:
		var room := "Guest bathroom" if basin.position.z < 0 else "Family bathroom"
		# Vanity top (y .975) under the old disc (centre y 1.02, 0.16 high).
		var top := .975
		for mesh in basin.get_children():
			if mesh is MeshInstance3D: _free(mesh)
		var bowl := MeshInstance3D.new()
		bowl.name = "Vessel basin"
		bowl.mesh = BathFixtures.vessel_basin()
		bowl.material_override = BathFixtures.finish("porcelain")
		basin.add_child(bowl)
		bowl.position.y = top - basin.position.y
		var spot := Vector3(basin.position.x, top, basin.position.z - .5)
		var faucet := BathFixtures.add_faucet(site, room + " faucet", spot, 0.0, "home_basin", top + BathFixtures.VESSEL_FLOOR)
		site.move_child(faucet, basin.get_index() + 1)
	# Kitchen: island worktop top y 1.26, sink slab top 1.30; the old tap stood at x 12.08 with
	# its spout reaching -X over the sink.
	var tap: Node3D = site.get_node("Sink tap")
	var tap_index := tap.get_index()
	var tap_spot := Vector3(tap.position.x, 1.26, tap.position.z)
	_free(site.get_node("Tap spout"))
	_free(tap)
	var kitchen := BathFixtures.add_faucet(site, "Sink tap", tap_spot, -PI * .5, "kitchen", 1.30)
	site.move_child(kitchen, mini(tap_index, site.get_child_count() - 1))

## A square wooden mahjong table with a green felt top and a raised rim, and four chairs with red
## cushions (word "chair", sit metas; meta mahjong_seat 0-3). Runtime parts (players, tiles) are
## added by mahjong_session.gd; the saved table holds only furniture.
func mahjong_table(town: Node3D, game) -> void:
	var site: Node3D = town.get_node("RelocatedSites/Home")
	var table := Node3D.new()
	table.name = "MahjongTable"
	site.add_child(table)
	table.position = site.to_local(town.to_global(MAHJONG_CENTER))
	table.set_meta("mahjong_table", true)
	var wood := Color("6b4226")
	var half := MAHJONG_SIZE * 0.5
	var top := _part(game, table, "Mahjong table top", Vector3(0, MAHJONG_TOP - 0.04, 0), Vector3(MAHJONG_SIZE, 0.08, MAHJONG_SIZE), wood, true)
	top.set_meta("word_key", "table")
	(top.get_child(1) as Node).set_meta("word", "table")
	_part(game, top, "Felt", Vector3(0, 0.042, 0), Vector3(MAHJONG_SIZE - 0.16, 0.004, MAHJONG_SIZE - 0.16), Color("1f6b45"), false)
	for side in 4:
		var along := Vector3(MAHJONG_SIZE, 0.05, 0.08) if side % 2 == 0 else Vector3(0.08, 0.05, MAHJONG_SIZE)
		var at := Vector3(0, 0.065, (half - 0.04) * (1 if side == 0 else -1)) if side % 2 == 0 else Vector3((half - 0.04) * (1 if side == 1 else -1), 0.065, 0)
		_part(game, top, "Rim", at, along, Color("4a2c18"), false)
	for corner in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
		_part(game, table, "Mahjong table leg", Vector3(corner.x * (half - 0.14), (MAHJONG_TOP - 0.08) * 0.5 - 0.04, corner.y * (half - 0.14)), Vector3(0.12, MAHJONG_TOP - 0.0, 0.12), wood, true)
	for seat in 4:
		var outward: Vector3 = MAHJONG_SEATS[seat]
		var chair := Node3D.new()
		chair.name = "Mahjong chair %d" % (seat + 1)
		table.add_child(chair)
		chair.position = outward * MAHJONG_CHAIR_DISTANCE
		# The chair's -Z faces the table.
		chair.basis = Basis.looking_at(-outward, Vector3.UP)
		chair.set_meta("word_key", "chair")
		chair.set_meta("mahjong_seat", seat)
		chair.set_meta("sit_position", Vector3(0, MAHJONG_SEAT, 0))
		chair.set_meta("sit_forward", Vector3(0, 0, -1))
		var cushion := _part(game, chair, "Seat", Vector3(0, MAHJONG_SEAT - 0.04, 0), Vector3(0.68, 0.08, 0.66), Color("b23a3a"), true)
		(cushion.get_child(1) as Node).set_meta("word", "chair")
		(cushion.get_child(1) as Node).set_meta("root", chair)
		_part(game, chair, "Chair back", Vector3(0, MAHJONG_SEAT + 0.42, 0.31), Vector3(0.68, 0.8, 0.08), Color("7a4a2a"), true)
		for corner in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
			_part(game, chair, "Chair leg", Vector3(corner.x * 0.29, (MAHJONG_SEAT - 0.08) * 0.5 - 0.03, corner.y * 0.28), Vector3(0.06, MAHJONG_SEAT - 0.02, 0.06), Color("5a361f"), false)

## A box under `parent`: [mesh, body] children like Main.box(), the body solid or absent.
static func _part(game, parent: Node3D, title: String, pos: Vector3, size: Vector3, color: Color, solid: bool) -> Node3D:
	var root := Node3D.new()
	root.name = title
	parent.add_child(root, true)
	root.position = pos
	var mesh := MeshInstance3D.new()
	mesh.mesh = game.shared_box_mesh(size)
	mesh.material_override = game.material_for(color)
	root.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		body.set_meta("object_name", title)
		body.set_meta("root", root)
		root.add_child(body)
	return root

static func _free(node: Node) -> void:
	node.get_parent().remove_child(node)
	node.free()

## Awoo's (samoyed, seat 2, south side) fur touched the table edge: her chair moves
## MAHJONG_CHAIR_BACK further from the table (user, 9 Nov 2026). The session seats her from the
## chair, so she follows it.
const MAHJONG_CHAIR_BACK := 0.2
func mahjong_chair_back(town: Node3D, _game) -> void:
	var chair := town.get_node_or_null("RelocatedSites/Home/MahjongTable/Mahjong chair 3")
	if chair == null:
		push_error("mahjong_chair_back: Mahjong chair 3 not found")
		return
	chair.position += Vector3(MAHJONG_SEATS[2]) * MAHJONG_CHAIR_BACK

## Toilets get a separate flush control (9 Nov 2026, user: E near the toilet sits, E or a click on
## the lever / push plate flushes): rebuilds each baked toilet's parts from bath_fixtures.gd.
func toilet_flush_control(town: Node3D, _game) -> void:
	BathFixtures.rebuild_toilets(town.get_node("RelocatedSites/Home"))

## An electrical box on the outside of the garage's side wall, facing the entry path (user
## request, 9 Nov 2026; docs/guides/ELECTRICAL_BOX.md). Site coordinates: the garage's west-side wall
## (toward the front door) is at x 6, z 17-23; the box hangs at ELECTRICAL_BOX_Z, its centre
## ELECTRICAL_BOX_Y above the ground, with a conduit down to the ground. Its back is placed on
## the wall face found by a ray from the path side.
const ELECTRICAL_BOX_SCENE := preload("res://scenes/props/electrical_box.tscn")
const ELECTRICAL_BOX_Z := 20.6
const ELECTRICAL_BOX_Y := 1.25
func electrical_box(town: Node3D, _game) -> void:
	var site: Node3D = town.get_node("RelocatedSites/Home")
	var from := site.to_global(Vector3(3.0, ELECTRICAL_BOX_Y, ELECTRICAL_BOX_Z))
	var ray := PhysicsRayQueryParameters3D.create(from, site.to_global(Vector3(7.5, ELECTRICAL_BOX_Y, ELECTRICAL_BOX_Z)))
	var hit := town.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty():
		push_error("electrical_box: no garage wall found at z %.1f" % ELECTRICAL_BOX_Z)
		return
	var face: float = site.to_local(hit.position).x
	var box: Node3D = ELECTRICAL_BOX_SCENE.instantiate()
	box.name = "Electrical box"
	box.set("box_id", "home_garage")
	box.set("conduit", ELECTRICAL_BOX_Y - 0.36)
	site.add_child(box, true)
	# The box's front (+Z) faces the path (-X).
	box.position = Vector3(face - 0.005, ELECTRICAL_BOX_Y, ELECTRICAL_BOX_Z)
	box.rotation = Vector3(0, -PI * 0.5, 0)
	print("electrical_box: wall face at x %.3f (%s)" % [face, hit.collider.get_parent().name])

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "home")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "home", 2)

## The old hover-hint and click metas baked on this unit's nodes go (12 Nov 2026, interaction
## system; scripts/buildings/interaction_metas.gd): their objects have Interactables now.
func interaction_metas(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/interaction_metas.gd").strip(town, "home")

## Bigger home (user request and floor-plan sketch, 12 Nov 2026; docs/guides/REFERENCE_HOME.md "Bigger
## home — 12 November 2026"): east wing (master bedroom, hallway, bathroom, office), garage twice
## as wide, guest suite in place of the guest bath, two west bedrooms, the pool moved east with a
## hot tub at its west end. Built by scripts/buildings/home_expansion.gd; the base step
## `home_expansion_ground` cuts the ground under the moved pool. Faces it leaves in one plane are
## set apart afterwards (coplanar pass 3).
func house_expansion(town: Node3D, game) -> void:
	preload("res://scripts/buildings/home_expansion.gd").new().build(town, game)
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "home", 3)

## Bathrooms, bedrooms, curtains and ceiling lamps refitted (user review, 13 Nov 2026;
## scripts/buildings/home_furnishing.gd).
func house_furnishing(town: Node3D, game) -> void:
	preload("res://scripts/buildings/home_furnishing.gd").new().build(town, game)

## Doors back to their height before the house was raised (user, 13 Nov 2026: the raise stretched
## the 11 door mounts 1.8x, to 6.45 world units against a 2.3 player). Each "<X> door frame"
## mount returns to scale 1 (3.58 world; handles as built) and the wall part above it (header or
## lintel, already stretched to the new ceiling) grows down to the door's old head line. Rooms,
## windows and ceilings keep their height.
func door_heights(town: Node3D, _game) -> void:
	var k: float = preload("res://scripts/buildings/home_expansion.gd").HOUSE_SCALE
	var site: Node3D = town.get_node("RelocatedSites/Home")
	var to_site := site.global_transform.affine_inverse()
	var mounts: Array = []
	for child in site.get_children():
		if not (child is Node3D and String(child.name).ends_with("door frame")):
			continue
		if not child.find_children("*", "", true, false).any(func(n): return n.has_meta("door_state")):
			continue
		var mount := child as Node3D
		mount.scale.y /= k
		for part in mount.find_children("*", "Node3D", true, false):
			var lower := String(part.name).to_lower()
			if lower.contains("handle") or lower.contains("knob") or lower.contains("lever"):
				part.scale.y *= k
		mounts.append(mount)
	var headers := 0
	for child in site.get_children():
		if not child is Node3D or mounts.has(child) or child.get_children().any(func(c): return c is Label3D):
			continue
		var box := AABB()
		var first := true
		for mesh in child.find_children("*", "MeshInstance3D", true, false) + ([child] if child is MeshInstance3D else []):
			if mesh.mesh == null: continue
			var b: AABB = (to_site * mesh.global_transform) * mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		# A header: a thin wall piece that starts at a stretched door's head line (2.5..3.3 before
		# the raise) and reaches the ceiling.
		if first or box.position.y < 2.5 * k or box.position.y > 3.3 * k or minf(box.size.x, box.size.z) > .5 or box.size.y < 1.0:
			continue
		for mount in mounts:
			var at: Vector3 = mount.position
			if at.x > box.position.x - .25 and at.x < box.end.x + .25 and at.z > box.position.z - .25 and at.z < box.end.z + .25:
				var node := child as Node3D
				var bottom := box.position.y / k
				var scale_by := (box.end.y - bottom) / box.size.y
				node.position.y = bottom + (node.position.y - box.position.y) * scale_by
				node.scale.y *= scale_by
				headers += 1
				print("door_heights: %s over %s now %.2f..%.2f" % [node.name, mount.name, bottom, box.end.y])
				break
	print("door_heights: %d doors, %d headers" % [mounts.size(), headers])

## The family bathroom (the welcome tutorial's) re-laid so its shower curtain faces the doorway
## and the toilet stands against the wall facing the room (user, 13 Nov 2026;
## home_furnishing.gd relay_family_bath()).
func family_bath_layout(town: Node3D, game) -> void:
	preload("res://scripts/buildings/home_furnishing.gd").new().relay_family_bath(town, game)

## The family bathroom's window beside the toilet replaced by wall, the toilet centred on it (user,
## 13 Nov 2026; home_furnishing.gd remove_family_bath_window()).
func family_bath_window(town: Node3D, game) -> void:
	preload("res://scripts/buildings/home_furnishing.gd").new().remove_family_bath_window(town, game)

## The family bathroom door opens into the bathroom, not into the living room (user, 13 Nov 2026,
## welcome tutorial review): its hinge door's open angle (door_state "angle", door_animator.gd)
## changes sign.
func family_bath_door_inward(town: Node3D, game) -> void:
	var site: Node3D = town.get_node("RelocatedSites/Home")
	var leaf: Node3D = site.find_child("Family bathroom door", true, false)
	if leaf == null or not leaf.has_meta("door_state"):
		push_error("home.gd family_bath_door_inward: no Family bathroom door with a door_state")
		return
	var state: Dictionary = leaf.get_meta("door_state").duplicate(true)
	var before := float(state.get("angle", -1.75))
	state["angle"] = -before
	leaf.set_meta("door_state", state)
	if game.get("doors") is Dictionary and game.doors.has(leaf):
		game.doors[leaf]["angle"] = -before
	print("family_bath_door_inward: angle %.2f -> %.2f" % [before, -before])

## Potted plants off the walking lines (user, 14 Nov 2026: "remove all the plants that are blocking
## the walkway or the entrance of the door"). Each houseplant (home_expansion.gd houseplant(),
## home_furnishing.gd plant(): an ivory pot and three foliage spheres, no collision) at these
## site [x, z] spots goes: in front of the guest suite door (the tutorial's first doorway), in the
## middle of the living room floor, in the east hall, and just inside the master bedroom, suite
## bathroom and family bathroom doors (under 1.3 from the opening). Plants in room corners, the
## dining table and side table pieces and the terrace and porch topiaries stay.
const WALKWAY_PLANTS := [Vector2(-3.9, -1.8), Vector2(5.0, 13.0), Vector2(16.4, 9.0), Vector2(19.0, 6.9), Vector2(-6.3, -2.4), Vector2(-5.6, 7.6)]
const PLANT_COLORS := ["f7f3e9", "4e863e"]
func clear_walkway_plants(town: Node3D, _game) -> void:
	var site: Node3D = town.get_node("RelocatedSites/Home")
	var freed := 0
	for spot in WALKWAY_PLANTS:
		var parts: Array = []
		for child in site.get_children():
			if not child is Node3D or child.position.y > 1.1 or child.get_child_count() != 1:
				continue
			if Vector2(child.position.x, child.position.z).distance_to(spot) > .3:
				continue
			var mesh := child.get_child(0) as MeshInstance3D
			if mesh == null or not (mesh.mesh is CylinderMesh or mesh.mesh is SphereMesh):
				continue
			var material := mesh.material_override as BaseMaterial3D
			if material == null and mesh.mesh.get_surface_count() > 0:
				material = mesh.mesh.surface_get_material(0) as BaseMaterial3D
			if material != null and material.albedo_color.to_html(false) in PLANT_COLORS:
				parts.append(child)
		if parts.size() != 4:
			push_error("home.gd clear_walkway_plants: %d plant pieces at %s (expected 4)" % [parts.size(), spot])
			continue
		for part in parts:
			part.get_parent().remove_child(part)
			part.free()
		freed += 1
	print("clear_walkway_plants: %d plants removed" % freed)

## The garage bicycle (home_expansion.gd garage(), prefab "Garage bicycle") is removed (user,
## 23 Nov 2026), with its meshes, collision and word root. The word "bicycle" stays in the
## sports store.
func garage_bicycle_removed(town: Node3D, _game) -> void:
	var site: Node3D = town.get_node("RelocatedSites/Home")
	var removed := 0
	for node in site.get_children():
		if String(node.name).begins_with("Garage bicycle"):
			site.remove_child(node)
			node.free()
			removed += 1
	assert(removed == 1, "garage_bicycle_removed: expected 1 bicycle, found %d" % removed)
	print("garage_bicycle_removed: removed %d" % removed)

## A record player on its own walnut stand beside the TV's media console (user request, 25 Nov
## 2026; scripts/world/record_player.gd, docs/guides/COMPONENTS.md "Record player"): against the
## living room's west wall (x -5), north of the console (z 2.8..6.0), clear of the family
## bathroom door (z 8.46..10.54); its front (+Z) faces the room (+X). E, a click or a tap opens
## the song card.
const RECORD_PLAYER_SCENE := preload("res://scenes/props/record_player.tscn")
const RECORD_PLAYER_AT := Vector3(-4.6, 0.03, 6.7)
func record_player(town: Node3D, _game) -> void:
	var site: Node3D = town.get_node("RelocatedSites/Home")
	var console := site.get_node_or_null("Media console") as Node3D
	assert(console != null, "record_player: no Media console in the home")
	var player: Node3D = RECORD_PLAYER_SCENE.instantiate()
	player.name = "Record player"
	site.add_child(player, true)
	player.position = RECORD_PLAYER_AT
	player.rotation = Vector3(0, PI * 0.5, 0)
	print("record_player: at %s beside the console at %s" % [player.position, console.position])
