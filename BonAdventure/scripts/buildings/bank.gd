extends RefCounted
## Bank own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## bank unit (scenes/town/bank.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- bank
## Never rename or remove a baked step (add a new one that undoes it).
const STEPS := ["coplanar_gaps", "coplanar_gaps_2", "glass_windows", "palette_interior", "shared_doors", "door_labels", "atm_art", "vault_art", "chair_backs"]

## Faces that shared a plane and flickered are set apart (10 Nov 2026,
## scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "bank")

## Second pass: faces a first move brought into a new plane, and labels widened for translated
## text (10 Nov 2026, scripts/buildings/coplanar_gaps.gd).
func coplanar_gaps_2(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "bank", 2)


## Window glass as the shared window component (12 Nov 2026, docs/guides/WINDOWS.md).
func glass_windows(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/glass_windows.gd").migrate(town, "bank")


# --- Interior refresh (user, 18 Nov 2026: docs/guides/TOWN_DESIGN_BRIEF.md "Bank interior refresh") ---
# Bank-site coordinates (the old town frame of RelocatedSites/Bank): hall x 19.12-30.88,
# z 37.62-52.38; the door is at z 37.5, the teller line at z 47.95, the vault behind z 48.8.
# The teller line stays where it is (the teller game, scripts/learning/teller_session.gd, uses
# its town coordinates); it is only recoloured.
const Palette := preload("res://scripts/core/game_palette.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const HALL := AABB(Vector3(19.1, 0.0, 37.6), Vector3(11.8, 5.8, 14.8))
const SKY_LIGHT := 0
const SKY := 1
const SKY_DEEP := 2

static func _bank(town: Node3D) -> Node3D:
	return ModularTown.building(town, "bank")

## Old interior colour -> palette colour (the 28 Oct interior, bank_interior.gd in git history).
static func _palette_map() -> Dictionary:
	return {
		"f6ecd8": Palette.WALL_CREAM,                 # wall paint, counter tops, teller fascia
		"d0dcd2": Palette.WALL_CREAM,                 # office partitions
		"aebdc0": Palette.WALL_CREAM,                 # vault side wall
		"f8f1e3": Palette.TRIM,                       # ceiling
		"2f6fc0": Palette.accent("sky", SKY),         # bands, panels, signs, number plates
		"3f6db3": Palette.accent("sky", SKY),         # sofa cushions
		"1f3f78": Palette.accent("sky", SKY_DEEP),    # runner, sofa bases, teller chairs, clock rim
		"b58e7d": Palette.accent("sky", SKY_DEEP),    # queue ropes
		"8eab97": Palette.accent("sky", SKY_LIGHT),   # consultation chairs
		"c9a36a": Palette.STONE,                      # runner border
		"efe6d6": Palette.STONE,                      # planters
		"c8915a": Palette.WOOD,                       # counters, desks, window frames
		"8f5e34": Palette.WOOD_DARK,                  # skirting, mullions, rails, drawers
		"2d2f3a": Palette.IRON,                       # monitors, chair posts
		"8a8f87": Palette.IRON,                       # queue posts
		"d8453a": Palette.CORAL,                      # red binders and brochures
		"3f9a45": Palette.accent("meadow", SKY),      # green binders and brochures
		"f2c231": Palette.CORAL_LIGHT,                # yellow brochures
		"73b3f2": Palette.BLUE_LIGHT,                 # monitor screens
		"4f9a45": Palette.LEAF_DARK,                  # plants
		"5fae4f": Palette.LEAF,
	}

## Interior surfaces in the game palette, sky accent (user choice, 18 Nov 2026). Only plain
## opaque materials of nodes inside the hall (and the Interior root) change; prefabs (desk,
## chair, computer), characters and the exterior keep theirs.
func palette_interior(town: Node3D, game) -> void:
	var bank := _bank(town)
	var colours := _palette_map()
	var count := 0
	for child in bank.get_children():
		if not child is Node3D or child.name == "BearBanker":
			continue
		if child.name != "Interior" and not HALL.has_point((child as Node3D).position):
			continue
		var meshes: Array = child.find_children("*", "MeshInstance3D", true, false)
		if child is MeshInstance3D:
			meshes.append(child)
		for mesh: MeshInstance3D in meshes:
			if _in_prefab(mesh, child) or mesh.mesh == null or mesh.mesh.get_surface_count() != 1:
				continue
			var old := mesh.material_override as StandardMaterial3D
			if old == null:
				# Imported meshes (the consultation chairs) carry their colour on the surface.
				old = mesh.mesh.surface_get_material(0) as StandardMaterial3D
			if old == null or old.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or old.emission_enabled:
				continue
			var key := old.albedo_color.to_html(false)
			if not colours.has(key):
				continue
			var mat: StandardMaterial3D = game.material_for(colours[key])
			if old.cull_mode != mat.cull_mode:
				mat = mat.duplicate()
				mat.cull_mode = old.cull_mode
			mesh.material_override = mat
			count += 1
	print("BANK palette_interior: recoloured ", count)

static func _in_prefab(mesh: Node, top: Node) -> bool:
	var node := mesh.get_parent()
	while node != null and node != top.get_parent():
		if node.scene_file_path != "" or node.name == "BearBanker":
			return true
		node = node.get_parent()
	return false

## A box under the bank (Main's shared box mesh and palette material).
static func _box(bank: Node3D, game, title: String, pos: Vector3, size: Vector3, colour: Color, solid := true) -> Node3D:
	var part: Node3D = game.box(title, pos, size, colour, "", solid)
	part.reparent(bank, false)
	part.position = pos
	return part

## A mesh-only part under `parent` (no collision, no word: it belongs to the parent's word root).
static func _piece(parent: Node3D, game, title: String, pos: Vector3, mesh: Mesh, colour: Color, rot := Vector3.ZERO) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = title
	part.mesh = mesh
	part.material_override = game.material_for(colour)
	part.position = pos
	part.rotation_degrees = rot
	parent.add_child(part, true)
	return part

static func _remove(game, node: Node) -> void:
	if node == null:
		return
	game.doors.erase(node)
	node.get_parent().remove_child(node)
	node.free()

## The manager office and vault get the shared doors (docs/guides/DOORS.md; the bank is the first
## building to use them). The 28 Oct sliding slabs only covered part of each opening; short wall
## pieces now close the rest, so each door fills its frame with no gap. The component roots keep
## the old names; their leaves are "<name> door" (word "door").
func shared_doors(town: Node3D, game) -> void:
	var bank := _bank(town)
	_remove(game, bank.get_node_or_null("Manager office"))
	_remove(game, bank.get_node_or_null("Vault entrance"))
	var wall := Palette.WALL_CREAM
	# Office front (z 47.9, 0.15 thick, 3.0 high): "Manager front wall" ends at x 20.85, the
	# "Manager divider" starts at x 23.325. Opening 20.85-22.05; the pocket leaf slides into the
	# new wall on its right.
	_box(bank, game, "Office door wall", Vector3(22.6875, 1.5, 47.9), Vector3(1.275, 3.0, 0.15), wall)
	_box(bank, game, "Office door head", Vector3(21.45, 2.7, 47.9), Vector3(1.2, 0.6, 0.15), wall)
	var office: Node3D = preload("res://scenes/props/sliding_door.tscn").instantiate()
	office.name = "Manager office"
	office.width = 1.2
	office.height = 2.4
	office.wall_thickness = 0.15
	office.leaf_name = "Manager office door"
	office.leaf_color = Palette.WOOD
	office.frame_color = Palette.TRIM
	office.handle_color = Palette.IRON
	office.vision_glass = true
	office.slide = 1   # TO_RIGHT: +x, into the new wall
	office.position = Vector3(21.45, 0.0, 47.9)
	bank.add_child(office, true)
	office.owner = bank.owner
	# Vault front (z 48.8): from the vault side wall (x 27.275) to the right wall (x 30.88), 0.2
	# thick. A steel hinged door 1.3 wide, swinging into the vault.
	_box(bank, game, "Vault front wall", Vector3(27.7375, 1.5, 48.8), Vector3(0.925, 3.0, 0.2), wall)
	_box(bank, game, "Vault front wall right", Vector3(30.19, 1.5, 48.8), Vector3(1.38, 3.0, 0.2), wall)
	_box(bank, game, "Vault door head", Vector3(28.85, 2.7, 48.8), Vector3(1.3, 0.6, 0.2), wall)
	var vault: Node3D = preload("res://scenes/props/door.tscn").instantiate()
	vault.name = "Vault entrance"
	vault.width = 1.3
	vault.height = 2.4
	vault.wall_thickness = 0.2
	vault.leaf_name = "Vault entrance door"
	vault.leaf_color = Palette.ROOF
	vault.leaf_thickness = 0.12
	vault.frame_color = Palette.IRON
	vault.frame_width = 0.12
	vault.handle_color = Palette.TRIM
	vault.swing_to_front = true   # +z: into the vault
	vault.position = Vector3(28.85, 0.0, 48.8)
	bank.add_child(vault, true)
	vault.owner = bank.owner

## No floating labels over doors (user rule, 12 Nov 2026: the prompt is a bare "E"). The ATM sign,
## which stood edge-on to the lobby and read backwards from the tellers, now faces the lobby.
func door_labels(town: Node3D, game) -> void:
	var bank := _bank(town)
	for title in ["Manager office • E upgrade sign", "Vault entrance • E upgrade sign"]:
		_remove(game, bank.get_node_or_null(title))
	var sign := bank.get_node_or_null("ATM sign lettering") as Label3D
	if sign != null:
		sign.transform = Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(29.175, 2.64, 41.45))
		sign.double_sided = false
		sign.modulate = Palette.TRIM

## ATMs: a deep-sky cabinet with a cream front, an iron bezel round a glowing screen, a keypad and
## an ATM board over both machines. Words (atm, screen, card reader, cash) and positions unchanged;
## the fronts face -x (the lobby).
func atm_art(town: Node3D, game) -> void:
	var bank := _bank(town)
	var glow: StandardMaterial3D = game.material_for(Palette.BLUE_LIGHT).duplicate()
	glow.emission_enabled = true
	glow.emission = Palette.BLUE_LIGHT
	glow.emission_energy_multiplier = 0.6
	for suffix in ["", "2"]:
		var atm := bank.get_node_or_null("ATM" + suffix) as Node3D
		if atm == null:
			continue
		for mesh: MeshInstance3D in atm.find_children("*", "MeshInstance3D", false, false):
			mesh.material_override = game.material_for(Palette.accent("sky", SKY_DEEP))
		# Front face at x 29.2 (local -0.45); parts sit just proud of it.
		_piece(atm, game, "ATM front", Vector3(-0.46, -0.07, 0), game.shared_box_mesh(Vector3(0.02, 1.9, 0.86)), Palette.TRIM)
		_piece(atm, game, "ATM bezel", Vector3(-0.48, 0.53, 0), game.shared_box_mesh(Vector3(0.02, 0.6, 0.68)), Palette.IRON)
		_piece(atm, game, "ATM keypad", Vector3(-0.5, -0.06, 0.12), game.shared_box_mesh(Vector3(0.05, 0.2, 0.26)), Palette.IRON)
		for row in 3:
			for col in 3:
				_piece(atm, game, "ATM key", Vector3(-0.535, 0.0 - row * 0.055, 0.04 + col * 0.075), game.shared_box_mesh(Vector3(0.02, 0.035, 0.05)), Palette.TRIM)
		_piece(atm, game, "ATM top band", Vector3(-0.47, 1.06, 0), game.shared_box_mesh(Vector3(0.02, 0.16, 0.86)), Palette.accent("sky", SKY))
		var screen := bank.get_node_or_null("ATM display" + suffix) as Node3D
		if screen != null:
			for mesh: MeshInstance3D in screen.find_children("*", "MeshInstance3D", false, false):
				mesh.material_override = glow
		for part in [["ATM card slot", Palette.IRON], ["ATM cash slot", Palette.STONE]]:
			var node := bank.get_node_or_null(String(part[0]) + suffix) as Node3D
			if node != null:
				for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", false, false):
					mesh.material_override = game.material_for(part[1])
	# One board over both machines (their tops are at y 2.34), carrying the ATM sign.
	_box(bank, game, "ATM sign board", Vector3(29.2, 2.64, 41.45), Vector3(0.04, 0.6, 2.6), Palette.accent("sky", SKY_DEEP), false)

## The vault: a round steel door with a wheel and bolts on the back wall, and the three safes
## turned into safe-deposit lockers along the vault's left wall (clear of the entrance door's
## swing). Word roots (Vault door, Vault wheel, Deposit safe 1-3, Safe handle 1-3) are kept.
func vault_art(town: Node3D, game) -> void:
	var bank := _bank(town)
	var centre := Vector3(29.4, 1.5, 52.27)
	var door := bank.get_node_or_null("Vault door") as Node3D
	if door != null:
		door.position = centre
		var disc := CylinderMesh.new()
		disc.top_radius = 1.05
		disc.bottom_radius = 1.05
		disc.height = 0.14
		disc.radial_segments = 32
		for mesh: MeshInstance3D in door.find_children("*", "MeshInstance3D", false, false):
			mesh.mesh = disc
			mesh.rotation_degrees = Vector3(90, 0, 0)
			mesh.material_override = game.material_for(Palette.ROOF)
		for shape: CollisionShape3D in door.find_children("*", "CollisionShape3D", true, false):
			if shape.shape is BoxShape3D:
				var box := BoxShape3D.new()
				box.size = Vector3(2.1, 2.1, 0.14)
				shape.shape = box
		var ring := TorusMesh.new()
		ring.inner_radius = 1.04
		ring.outer_radius = 1.18
		ring.rings = 32
		_piece(door, game, "Vault door ring", Vector3(0, 0, 0.0), ring, Palette.IRON, Vector3(90, 0, 0))
		var hinge_mesh: Mesh = game.shared_box_mesh(Vector3(0.18, 0.34, 0.12))
		for y in [-0.55, 0.55]:
			_piece(door, game, "Vault door hinge", Vector3(1.12, y, -0.05), hinge_mesh, Palette.IRON)
	var wheel := bank.get_node_or_null("Vault wheel") as Node3D
	if wheel != null:
		wheel.position = centre + Vector3(0, 0, -0.14)
		var rim := TorusMesh.new()
		rim.inner_radius = 0.3
		rim.outer_radius = 0.36
		rim.rings = 24
		for mesh: MeshInstance3D in wheel.find_children("*", "MeshInstance3D", false, false):
			mesh.mesh = rim
			mesh.rotation_degrees = Vector3(90, 0, 0)
			mesh.material_override = game.material_for(Palette.TRIM)
		for angle in [0, 60, 120]:
			_piece(wheel, game, "Wheel spoke", Vector3.ZERO, game.shared_box_mesh(Vector3(0.66, 0.05, 0.04)), Palette.TRIM, Vector3(0, 0, angle))
		var hub := CylinderMesh.new()
		hub.top_radius = 0.09
		hub.bottom_radius = 0.09
		hub.height = 0.08
		_piece(wheel, game, "Wheel hub", Vector3(0, 0, -0.02), hub, Palette.IRON, Vector3(90, 0, 0))
	var bolts := ["Vault bolt", "Vault bolt2", "Vault bolt3", "Vault bolt4"]
	for i in bolts.size():
		var bolt := bank.get_node_or_null(bolts[i]) as Node3D
		if bolt == null:
			continue
		var a := deg_to_rad(45.0 + 90.0 * i)
		bolt.position = centre + Vector3(cos(a) * 0.82, sin(a) * 0.82, -0.09)
		bolt.rotation_degrees = Vector3(90, 0, 0)
		for mesh: MeshInstance3D in bolt.find_children("*", "MeshInstance3D", false, false):
			mesh.material_override = game.material_for(Palette.STONE)
	# Safes: 0.8 wide, 0.7 deep, 1.5 high; fronts (local -z) now face +x, along x 27.3-28.0.
	var locker_door: Mesh = game.shared_box_mesh(Vector3(0.22, 0.3, 0.02))
	var keyhole: Mesh = game.shared_box_mesh(Vector3(0.04, 0.05, 0.02))
	var turn := Basis(Vector3.UP, -PI / 2.0)
	for i in 3:
		var suffix := "" if i == 0 else str(i + 1)
		var safe := bank.get_node_or_null("Deposit safe" + suffix) as Node3D
		if safe == null:
			continue
		var z := 49.95 + 0.8 * i
		safe.transform = Transform3D(turn, Vector3(27.65, 0.8, z))
		for mesh: MeshInstance3D in safe.find_children("*", "MeshInstance3D", false, false):
			mesh.material_override = game.material_for(Palette.IRON)
		for row in 3:
			for col in 3:
				var at := Vector3((col - 1) * 0.25, -0.45 + row * 0.35, -0.36)
				_piece(safe, game, "Locker door", at, locker_door, Palette.ROOF)
				_piece(safe, game, "Locker keyhole", at + Vector3(0.06, 0, -0.015), keyhole, Palette.TRIM)
		var handle := bank.get_node_or_null("Safe handle" + suffix) as Node3D
		if handle != null:
			# Above the lockers, on the front.
			handle.transform = Transform3D(turn, Vector3(28.04, 1.38, z))

## The consultation chairs' backs (a darker green, 729b86, missed by palette_interior) match
## their seats: sky light.
func chair_backs(town: Node3D, game) -> void:
	var bank := _bank(town)
	for suffix in ["", "2", "3", "4"]:
		var back := bank.get_node_or_null("Chair back" + suffix)
		if back == null:
			continue
		for mesh: MeshInstance3D in back.find_children("*", "MeshInstance3D", false, false):
			mesh.material_override = game.material_for(Palette.accent("sky", SKY_LIGHT))
