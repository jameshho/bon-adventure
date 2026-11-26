extends RefCounted
## Bank own script (docs/guides/MODULAR_TOWN.md, "Changing a building"): code steps for the
## bank unit (scenes/town/bank.scn).
## Bake:  godot --headless --path . --script res://tools/bake_unit.gd -- bank
## Never rename or remove a baked step (add a new one that undoes it).
const STEPS := ["coplanar_gaps", "coplanar_gaps_2", "glass_windows", "palette_interior", "shared_doors", "door_labels", "atm_art", "vault_art", "chair_backs", "vault_safe", "rear_annex", "deposit_boxes", "staff_door", "heavy_vault_door", "teller_side_monitor", "coplanar_gaps_3", "wider_staff_door", "teller_seats", "door_sounds", "palette_snap"]

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

## The round vault door becomes a wall safe that opens (user, 21 Nov 2026: "make the safe openable,
## add a short animation to it as it opens"; the Bank's town stamp coin waits inside it,
## data/achievements.json). A steel drum stands out of the vault's back wall (z 51.72 to the wall
## at 52.38, the hole 1.08 across); the old door, wheel and four bolts move onto its mouth and hang
## on a pivot at the hinge side (x 30.52); the door gets a solid disc (it had only a pick area).
## The pivot is an ordinary hinged door of door_animator.gd (E, click or tap) whose door_state
## also names the wheel: opening, the wheel turns three quarters first, then the door swings out
## into the vault (to -z); closing, both together. The coin's "gate" is this pivot
## (stamp_coin.gd collects only while it is open).
const SAFE_CENTRE := Vector3(29.4, 1.5, 51.65)
const SAFE_HINGE_X := 30.52
const SAFE_DEPTH := Vector2(51.72, 52.38)
const SAFE_HOLE := 1.08

func vault_safe(town: Node3D, game) -> void:
	var bank := _bank(town)
	var door := bank.get_node_or_null("Vault door") as Node3D
	if door == null:
		push_error("bank vault_safe: no Vault door")
		return
	var pivot := Node3D.new()
	pivot.name = "Vault safe door"
	bank.add_child(pivot, true)
	pivot.owner = bank.owner
	pivot.position = Vector3(SAFE_HINGE_X, 0.0, SAFE_CENTRE.z)
	var shift := Vector3(0, 0, SAFE_CENTRE.z - door.position.z)
	for title in ["Vault door", "Vault wheel", "Vault bolt", "Vault bolt2", "Vault bolt3", "Vault bolt4"]:
		var part := bank.get_node_or_null(title) as Node3D
		if part == null:
			continue
		part.position += shift
		part.reparent(pivot, true)
	# The old round door was decoration (only its word-pick area): now solid, swinging with it.
	var body := StaticBody3D.new()
	body.name = "Vault door body"
	door.add_child(body, true)
	var disc_shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 1.12
	cylinder.height = 0.16
	disc_shape.shape = cylinder
	disc_shape.rotation_degrees = Vector3(90, 0, 0)
	body.add_child(disc_shape)
	var wheel := pivot.get_node_or_null("Vault wheel") as Node3D
	pivot.set_meta("door_state", {"open": false, "type": "hinge", "angle": -1.5,
			"spin": "Vault wheel" if wheel != null else "", "spin_angle": TAU * 0.75})
	# The drum: 16 iron staves round the hole, a dark back plate, a lip ring on the front.
	var drum := Node3D.new()
	drum.name = "Vault safe drum"
	bank.add_child(drum, true)
	drum.owner = bank.owner
	drum.position = Vector3(SAFE_CENTRE.x, SAFE_CENTRE.y, (SAFE_DEPTH.x + SAFE_DEPTH.y) * 0.5)
	var depth := SAFE_DEPTH.y - SAFE_DEPTH.x
	var staves := 16
	var stave_w := TAU * (SAFE_HOLE + 0.06) / staves + 0.02
	for k in staves:
		var a := TAU * (k + 0.5) / staves
		var at := Vector3(cos(a), sin(a), 0) * (SAFE_HOLE + 0.06)
		var stave := _box(drum, game, "Safe stave", at, Vector3(stave_w, 0.12, depth), Palette.IRON)
		stave.transform = Transform3D(Basis(Vector3.BACK, a + PI / 2.0), at)
	var back := CylinderMesh.new()
	back.top_radius = SAFE_HOLE + 0.02
	back.bottom_radius = SAFE_HOLE + 0.02
	back.height = 0.04
	back.radial_segments = 32
	_piece(drum, game, "Safe back plate", Vector3(0, 0, depth * 0.5 - 0.04), back, Color("2a3238"), Vector3(90, 0, 0))
	var lip := TorusMesh.new()
	lip.inner_radius = SAFE_HOLE - 0.01
	lip.outer_radius = SAFE_HOLE + 0.17
	lip.rings = 32
	_piece(drum, game, "Safe lip", Vector3(0, 0, -depth * 0.5 + 0.01), lip, Palette.TRIM, Vector3(90, 0, 0))
	# A small velvet shelf for the coin (the drum's lowest staves are its floor).
	_piece(drum, game, "Safe shelf", Vector3(0, -SAFE_HOLE + 0.12, 0.05), game.shared_box_mesh(Vector3(1.1, 0.04, depth - 0.12)), Color("8c2f39"))
	print("BANK vault_safe: pivot at %s, wheel %s, drum %d staves" % [pivot.position, wheel != null, staves])


# --- Rear annex (user, 23 Nov 2026: docs/guides/TOWN_DESIGN_BRIEF.md "Bank rework") ---
# The bank grows BACKWARD only (user approval for this task): a lower annex behind the old back
# wall, 12 wide and 8.4 deep, on the open grass behind the bank (measured 23 Nov 2026: no road,
# path or neighbour until the beach about 23 units behind). The front, lobby and every lobby
# thing stay where they are. Site coordinates (bank-local, the old town frame): the old back wall
# is at z 52.385-52.615 (town x 141.4-141.6), the side walls at x 18.885-19.115 (town z 114) and
# x 30.885-31.115 (town z 102). Town = (89 + site z, y, 133 - site x).
#   - vault: the old vault (x 27.35-30.885) opens through the old back wall into the annex's
#     vault room (x 23.475-30.885, z 52.6-56.0); the round wall safe moves onto its back wall;
#   - safe-deposit room (z 56.15-60.77, full width) through a door in the vault's back wall:
#     walls of small boxes (look only: no words, nothing opens);
#   - manager's office: the old office (x 19.115-23.325) opens into the annex (to z 56.0); the
#     desk moves to its back; a staff door in its side wall leads behind the teller counter.
const ANNEX_BACK := 61.0          # outer face of the annex's back wall (site z)
const ANNEX_HEIGHT := 4.0         # wall top and ceiling (the old shell is 5.8)
const OLD_BACK := Vector2(52.385, 52.615)
const DEPOSIT_WALL := Vector2(56.0, 56.15)
const SPLIT_X := Vector2(23.325, 23.475)   # office | teller area and vault (the old divider line)
const DEPOSIT_DOOR_X := Vector2(28.3, 29.4)
## The wall safe (vault_safe step) moves from the old back wall to the vault room's back wall.
const SAFE_SHIFT := Vector3(-4.4, 0.0, 3.615)

## The first MeshInstance3D material under `path` (below the town), to match the shell exactly.
static func _material_of(town: Node3D, path: String) -> Material:
	var node := town.get_node_or_null(path)
	if node == null:
		return null
	var meshes: Array = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.push_front(node)
	return null if meshes.is_empty() else (meshes[0] as MeshInstance3D).material_override

## A box like _box() but drawn with `material` (the shell's own exterior materials).
static func _shell_box(bank: Node3D, game, title: String, pos: Vector3, size: Vector3, material: Material, solid := true) -> Node3D:
	var part := _box(bank, game, title, pos, size, Palette.WALL_CREAM, solid)
	if material != null:
		for mesh: MeshInstance3D in part.find_children("*", "MeshInstance3D", false, false):
			mesh.material_override = material
	return part

## A box from its min and max corners (site coordinates).
static func _span(bank: Node3D, game, title: String, from: Vector3, to: Vector3, colour: Color, solid := true) -> Node3D:
	return _box(bank, game, title, (from + to) * 0.5, (to - from).abs(), colour, solid)

static func _shell_span(bank: Node3D, game, title: String, from: Vector3, to: Vector3, material: Material, solid := true) -> Node3D:
	return _shell_box(bank, game, title, (from + to) * 0.5, (to - from).abs(), material, solid)

func rear_annex(town: Node3D, game) -> void:
	var bank := _bank(town)
	var wall_mat := _material_of(town, "RelocatedSites/Bank/Bank left wall")
	var roof_mat := _material_of(town, "RelocatedSites/Bank/Bank roof")
	var base_mat := _material_of(town, "Map facades/BANK/Bank side base")
	var cornice_mat := _material_of(town, "Map facades/BANK/Bank side cornice")
	var h := ANNEX_HEIGHT
	var cream := Palette.WALL_CREAM
	# The old back wall: kept above the annex roof and between the teller area and the annex;
	# open behind the vault and the office (headers at the partitions' 3.0 height).
	_remove(game, bank.get_node_or_null("Bank back wall"))
	var b0 := OLD_BACK.x
	var b1 := OLD_BACK.y
	_shell_span(bank, game, "Bank back wall upper", Vector3(19.0, h + 0.2, b0), Vector3(31.0, 5.8, b1), wall_mat)
	_shell_span(bank, game, "Bank back wall teller", Vector3(SPLIT_X.x, 0.0, b0), Vector3(27.35, h + 0.2, b1), wall_mat)
	_shell_span(bank, game, "Bank back wall office header", Vector3(19.0, 3.0, b0), Vector3(SPLIT_X.x, h + 0.2, b1), wall_mat)
	_shell_span(bank, game, "Bank back wall vault header", Vector3(27.35, 3.0, b0), Vector3(31.0, h + 0.2, b1), wall_mat)
	# Annex shell: two side walls and a back wall, a flat roof with the shell's cornice and plinth.
	_shell_span(bank, game, "Annex left wall", Vector3(18.885, 0.0, 52.5), Vector3(19.115, h, ANNEX_BACK), wall_mat)
	_shell_span(bank, game, "Annex right wall", Vector3(30.885, 0.0, 52.5), Vector3(31.115, h, ANNEX_BACK), wall_mat)
	_shell_span(bank, game, "Annex back wall", Vector3(18.885, 0.0, ANNEX_BACK - 0.23), Vector3(31.115, h, ANNEX_BACK), wall_mat)
	_shell_span(bank, game, "Annex roof", Vector3(18.8, h, b1), Vector3(31.2, h + 0.22, ANNEX_BACK + 0.1), roof_mat)
	_span(bank, game, "Annex ceiling", Vector3(19.115, h - 0.03, b1), Vector3(30.885, h, ANNEX_BACK - 0.23), Palette.TRIM, false)
	for side in [[18.785, 18.885], [31.115, 31.215]]:
		_shell_span(bank, game, "Annex cornice", Vector3(side[0], h - 0.22, 52.62), Vector3(side[1], h + 0.06, ANNEX_BACK + 0.1), cornice_mat, false)
		_shell_span(bank, game, "Annex plinth", Vector3(side[0] + (0.04 if side[0] < 19 else 0.0), 0.0, 52.62), Vector3(side[1] - (0.0 if side[0] < 19 else 0.04), 0.7, ANNEX_BACK + 0.06), base_mat, false)
	_shell_span(bank, game, "Annex cornice", Vector3(18.785, h - 0.22, ANNEX_BACK), Vector3(31.215, h + 0.06, ANNEX_BACK + 0.1), cornice_mat, false)
	_shell_span(bank, game, "Annex plinth", Vector3(18.825, 0.0, ANNEX_BACK), Vector3(31.175, 0.7, ANNEX_BACK + 0.06), base_mat, false)
	# Floors (tops at the lobby tiles' 0.034): stone in the vault and deposit room, wood in the office.
	_span(bank, game, "Vault room floor", Vector3(SPLIT_X.y, 0.0, 52.36), Vector3(30.885, 0.034, DEPOSIT_WALL.x), Palette.STONE)
	_span(bank, game, "Office annex floor", Vector3(19.115, 0.0, 52.36), Vector3(SPLIT_X.x, 0.034, DEPOSIT_WALL.x), Palette.WOOD)
	_span(bank, game, "Deposit room floor", Vector3(19.115, 0.0, DEPOSIT_WALL.x), Vector3(30.885, 0.034, ANNEX_BACK - 0.23), Palette.STONE.darkened(0.12))
	# Partitions: office | vault room, then the deposit room's wall with its door.
	_span(bank, game, "Office annex divider", Vector3(SPLIT_X.x, 0.0, b1), Vector3(SPLIT_X.y, h, DEPOSIT_WALL.x), cream)
	var d0 := DEPOSIT_WALL.x
	var d1 := DEPOSIT_WALL.y
	_span(bank, game, "Deposit wall", Vector3(19.115, 0.0, d0), Vector3(DEPOSIT_DOOR_X.x, h, d1), cream)
	_span(bank, game, "Deposit wall right", Vector3(DEPOSIT_DOOR_X.y, 0.0, d0), Vector3(30.885, h, d1), cream)
	_span(bank, game, "Deposit door head", Vector3(DEPOSIT_DOOR_X.x, 2.4, d0), Vector3(DEPOSIT_DOOR_X.y, h, d1), cream)
	var door: Node3D = preload("res://scenes/props/door.tscn").instantiate()
	door.name = "Deposit room"
	door.width = DEPOSIT_DOOR_X.y - DEPOSIT_DOOR_X.x
	door.height = 2.4
	door.wall_thickness = d1 - d0
	door.leaf_name = "Deposit room door"
	door.leaf_color = Palette.IRON
	door.leaf_thickness = 0.08
	door.vision_glass = true
	door.frame_color = Palette.IRON
	door.frame_width = 0.1
	door.handle_color = Palette.TRIM
	door.swing_to_front = true   # +z: into the deposit room
	door.position = Vector3((DEPOSIT_DOOR_X.x + DEPOSIT_DOOR_X.y) * 0.5, 0.0, (d0 + d1) * 0.5)
	bank.add_child(door, true)
	door.owner = bank.owner
	# The wall safe and its door move onto the vault room's back wall (the coin with them:
	# data/achievements.json "bank" at / face).
	for title in ["Vault safe door", "Vault safe drum"]:
		var part := bank.get_node_or_null(title) as Node3D
		if part != null:
			part.position += SAFE_SHIFT
	# Vault room: two steel shelves of banknote bundles along the office side (look only).
	var bundle_mesh: Mesh = game.shared_box_mesh(Vector3(0.28, 0.1, 0.16))
	var band_mesh: Mesh = game.shared_box_mesh(Vector3(0.05, 0.106, 0.166))
	for k in 2:
		var z := 52.95 + k * 1.45
		# The root is the shelf's back panel (solid); sides, boards and bundles are drawn on it.
		var shelf := _span(bank, game, "Vault shelf", Vector3(SPLIT_X.y + 0.01, 0.0, z), Vector3(SPLIT_X.y + 0.05, 2.0, z + 1.2), Palette.IRON)
		for side in [-0.585, 0.585]:
			_piece(shelf, game, "Shelf side", Vector3(0.25, 0.0, side), game.shared_box_mesh(Vector3(0.48, 2.0, 0.03)), Palette.IRON)
		for level in 3:
			var y := 0.45 + level * 0.6
			_piece(shelf, game, "Shelf board", Vector3(0.25, y - 1.0, 0), game.shared_box_mesh(Vector3(0.46, 0.03, 1.14)), Palette.STONE)
			for i in 4:
				for stack in 2:
					var at := Vector3(0.27, y - 1.0 + 0.065 + stack * 0.1, -0.42 + i * 0.28)
					_piece(shelf, game, "Banknote bundle", at, bundle_mesh, Palette.LEAF_DARK if (i + level) % 2 == 0 else Palette.LEAF, Vector3(0, 90, 0))
					_piece(shelf, game, "Bundle band", at, band_mesh, Palette.TRIM, Vector3(0, 90, 0))
	# Office: the old desk, chair and computer turn round to the back of the annex (the
	# manager stands beside them, teller_session.gd), a bookshelf, a window on the side wall.
	var turn := Transform3D(Basis(Vector3.UP, PI), Vector3(42.8, 0.0, 105.38))
	for title in ["Desk2", "Chair16", "Computer"]:
		var part := bank.get_node_or_null(title) as Node3D
		if part != null:
			part.transform = turn * part.transform
	# The bookshelf's root is its back panel (solid); sides, boards and binders are drawn on it.
	var shelf_root := _span(bank, game, "Office bookshelf", Vector3(19.4, 0.0, d0 - 0.03), Vector3(21.2, 2.2, d0), Palette.WOOD)
	for side in [-0.885, 0.885]:
		_piece(shelf_root, game, "Bookshelf side", Vector3(side, 0.0, -0.2), game.shared_box_mesh(Vector3(0.03, 2.2, 0.38)), Palette.WOOD)
	for level in 4:
		var board_y := -1.05 + level * 0.65
		_piece(shelf_root, game, "Bookshelf board", Vector3(0, board_y, -0.2), game.shared_box_mesh(Vector3(1.74, 0.03, 0.38)), Palette.WOOD_DARK)
		if level == 3:
			continue
		for i in 9:
			var colour: Color = [Palette.CORAL, Palette.accent("sky", SKY), Palette.accent("meadow", SKY), Palette.TRIM][(i + level) % 4]
			_piece(shelf_root, game, "Binder", Vector3(-0.75 + i * 0.12 + level * 0.04, board_y + 0.175, -0.2), game.shared_box_mesh(Vector3(0.08, 0.32, 0.28)), colour)
	var window: Dictionary = preload("res://scripts/buildings/glass_windows.gd").real_window(town, "bank", bank,
			town.to_local(bank.to_global(Vector3(19.0, 1.75, 54.2))), town.global_basis.inverse() * (bank.global_basis * Vector3.LEFT),
			{"name": "Office window", "width": 1.6, "height": 1.3, "wall_depth": 0.23, "frame_visible": true, "frame_color": Color("405d68")})
	if window.window != null:
		window.window.owner = bank.owner
	print("BANK rear_annex: annex to site z %.2f, window cut %s" % [ANNEX_BACK, window.cut])

## Walls of small safe-deposit boxes in the deposit room (look only: no words, nothing opens).
## Each wall is one steel cabinet (solid) with its doors and number plates drawn as two baked
## MultiMeshes of one unit box (scripts/objects/baked_multimesh.gd: a few hundred boxes cost two
## draws and about 50 KB in the scene; merged meshes cost over 1 MB, measured 23 Nov 2026).
func deposit_boxes(town: Node3D, game) -> void:
	var bank := _bank(town)
	var inner_back := ANNEX_BACK - 0.23
	var d1 := DEPOSIT_WALL.y
	# [title, start (floor, on the wall face), along, inward (into the room), length]
	var walls := [
		["Deposit boxes back", Vector3(19.45, 0.0, inner_back), Vector3.RIGHT, Vector3.BACK * -1.0, 11.1],
		["Deposit boxes left", Vector3(19.115, 0.0, d1 + 0.55), Vector3.BACK, Vector3.RIGHT, inner_back - 0.55 - d1 - 0.55],
		["Deposit boxes right", Vector3(30.885, 0.0, inner_back - 0.55), Vector3.FORWARD, Vector3.LEFT, inner_back - 0.55 - d1 - 0.55],
		["Deposit boxes front", Vector3(19.45, 0.0, d1), Vector3.RIGHT, Vector3.BACK, DEPOSIT_DOOR_X.x - 0.3 - 19.45],
	]
	var count := 0
	for wall in walls:
		count += _locker_wall(bank, game, wall[0], wall[1], wall[2], wall[3], wall[4])
	# A steel table in the middle, where a customer would open a box.
	var table := _span(bank, game, "Deposit table", Vector3(23.4, 0.9, 57.6), Vector3(26.6, 0.96, 59.0), Palette.IRON)
	_piece(table, game, "Table top", Vector3(0, 0.035, 0), game.shared_box_mesh(Vector3(3.1, 0.012, 1.3)), Palette.STONE)
	for x in [-1.45, 1.45]:
		_piece(table, game, "Table leg", Vector3(x, -0.45, 0), game.shared_box_mesh(Vector3(0.08, 0.9, 1.1)), Palette.IRON)
	print("BANK deposit_boxes: %d boxes" % count)

const LOCKER_DEPTH := 0.5
const LOCKER_HEIGHT := 3.1
const LOCKER_PITCH := Vector2(0.38, 0.3)

## One cabinet of boxes standing against a wall; returns the number of boxes.
func _locker_wall(bank: Node3D, game, title: String, start: Vector3, along: Vector3, inward: Vector3, length: float) -> int:
	var axis_size := func(a: float, h: float, d: float) -> Vector3:
		return along.abs() * a + Vector3.UP * h + inward.abs() * d
	var centre := start + along * length * 0.5 + inward * LOCKER_DEPTH * 0.5 + Vector3.UP * LOCKER_HEIGHT * 0.5
	var cabinet := _box(bank, game, title, centre, axis_size.call(length, LOCKER_HEIGHT, LOCKER_DEPTH), Palette.IRON)
	var face := start + inward * LOCKER_DEPTH
	var doors := []
	var plates := []
	var columns := floori((length - 0.1) / LOCKER_PITCH.x)
	var margin := (length - columns * LOCKER_PITCH.x) * 0.5
	var count := 0
	for c in columns:
		var u := margin + (c + 0.5) * LOCKER_PITCH.x
		var y := 0.18
		var row := 0
		while y < LOCKER_HEIGHT - 0.2:
			# The bottom row holds big boxes (two high); the rest are small ones.
			var h := LOCKER_PITCH.y * (2.0 if row == 0 else 1.0)
			if y + h > LOCKER_HEIGHT - 0.1:
				break
			var mid := face + along * u + Vector3.UP * (y + h * 0.5) - centre
			doors.append(Transform3D(Basis.from_scale(axis_size.call(LOCKER_PITCH.x - 0.04, h - 0.04, 0.024)), mid + inward * 0.012))
			plates.append(Transform3D(Basis.from_scale(axis_size.call(0.12, 0.045, 0.01)), mid + inward * 0.028 + Vector3.UP * (h * 0.5 - 0.07)))
			count += 1
			y += h
			row += 1
	_instances(cabinet, game, "Deposit box doors", doors, Palette.ROOF)
	_instances(cabinet, game, "Deposit box plates", plates, Palette.TRIM)
	# A kick plate along the floor.
	_piece(cabinet, game, "Locker kick", face - centre + inward * 0.01 + Vector3.UP * 0.08 + along * length * 0.5, game.shared_box_mesh(axis_size.call(length, 0.14, 0.02)), Palette.STONE)
	return count

## A baked MultiMesh of unit boxes under `parent`, one per transform (parent-local).
static func _instances(parent: Node3D, game, title: String, poses: Array, colour: Color) -> void:
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = game.shared_box_mesh(Vector3.ONE)
	instances.instance_count = poses.size()
	var data := PackedFloat32Array()
	var bounds := AABB()
	for i in poses.size():
		var pose: Transform3D = poses[i]
		var b := pose.basis
		data.append_array([b.x.x, b.y.x, b.z.x, pose.origin.x, b.x.y, b.y.y, b.z.y, pose.origin.y, b.x.z, b.y.z, b.z.z, pose.origin.z])
		bounds = AABB(pose.origin, Vector3.ZERO) if i == 0 else bounds.expand(pose.origin)
	var node := MultiMeshInstance3D.new()
	node.set_script(preload("res://scripts/objects/baked_multimesh.gd"))
	node.set("instance_buffer", data)
	node.name = title
	node.multimesh = instances
	node.custom_aabb = bounds.grow(0.5)
	node.material_override = game.material_for(colour)
	parent.add_child(node, true)

## A staff door in the manager office's side wall (the old "Manager divider", x 23.325-23.475,
## z 47.9-52.3, 3.0 high): the player reaches the teller side of the counter through the office
## (user, 23 Nov 2026), and the manager walks the same way in the teller game. It opens at
## z 50.0-50.95, behind window 3's chair, and swings into the office, hinged on its back jamb
## (z 50.95): the open leaf lies along that jamb, clear of the walk from the office door.
const STAFF_DOOR_Z := Vector2(50.0, 50.95)

func staff_door(town: Node3D, game) -> void:
	var bank := _bank(town)
	_remove(game, bank.get_node_or_null("Manager divider"))
	_build_staff_door(bank, game, STAFF_DOOR_Z)

## The divider wall pieces and the hinged staff door in the opening `span` (site z).
func _build_staff_door(bank: Node3D, game, span: Vector2) -> void:
	var cream := Palette.WALL_CREAM
	_span(bank, game, "Manager divider", Vector3(SPLIT_X.x, 0.0, 47.9), Vector3(SPLIT_X.y, 3.0, span.x), cream)
	_span(bank, game, "Manager divider back", Vector3(SPLIT_X.x, 0.0, span.y), Vector3(SPLIT_X.y, 3.0, OLD_BACK.x), cream)
	_span(bank, game, "Staff door head", Vector3(SPLIT_X.x, 2.2, span.x), Vector3(SPLIT_X.y, 3.0, span.y), cream)
	var door: Node3D = preload("res://scenes/props/door.tscn").instantiate()
	door.name = "Staff door"
	door.width = span.y - span.x
	door.height = 2.2
	door.wall_thickness = SPLIT_X.y - SPLIT_X.x
	door.leaf_name = "Staff door leaf"
	door.leaf_color = Palette.WOOD
	door.frame_color = Palette.TRIM
	door.handle_color = Palette.IRON
	door.swing_to_front = false   # local front (+Z) is the teller side (+x): it swings into the office
	door.transform = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3((SPLIT_X.x + SPLIT_X.y) * 0.5, 0.0, (span.x + span.y) * 0.5))
	bank.add_child(door, true)
	door.owner = bank.owner

## The vault's entrance swings slowly and heavily (user, 23 Nov 2026: suspense): about 3 s,
## starting slowly (door.gd swing_seconds, door_animator.gd heavy swing).
func heavy_vault_door(town: Node3D, _game) -> void:
	var vault := _bank(town).get_node_or_null("Vault entrance")
	if vault == null:
		push_error("bank heavy_vault_door: no Vault entrance")
		return
	vault.swing_seconds = 3.2
	vault.leaf_thickness = 0.2

## Window 2's monitor moves aside (toward window 1) and turns toward the teller's eye, so one
## view in the teller game shows the account on it and the customer's face behind the glass
## (user, 23 Nov 2026; teller_session.gd MONITOR_CENTRE / VIEW_EYE). Town coordinates: the
## monitor's centre (137.21, 1.41, 107.7) goes to MONITOR_CENTRE, turned MONITOR_YAW about y.
## Its parts (monitor, screen, stand) are unnamed children of Interior, found by place and size.
const MONITOR_OLD := Vector3(137.21, 1.41, 107.7)

func teller_side_monitor(town: Node3D, _game) -> void:
	var teller := preload("res://scripts/learning/teller_session.gd")
	var bank := _bank(town)
	var interior := bank.get_node("Interior")
	var to_town := town.global_transform.affine_inverse()
	var moved := []
	for child in interior.get_children():
		if not child is Node3D:
			continue
		var meshes: Array = child.find_children("*", "MeshInstance3D", true, false)
		if child is MeshInstance3D:
			meshes.append(child)
		if meshes.is_empty():
			continue
		var box: AABB = (to_town * meshes[0].global_transform) * meshes[0].mesh.get_aabb()
		var c := box.get_center()
		# The monitor, its screen and its stand (the keyboard, lower and nearer the glass, stays).
		if box.size.x < 0.2 and box.size.z < 0.6 and absf(c.z - MONITOR_OLD.z) < 0.3 and c.x > 137.12 and c.x < 137.3 and c.y > 1.15 and c.y < 1.6:
			moved.append(child)
	var place := Transform3D(Basis(), teller.MONITOR_CENTRE) * Transform3D(Basis(Vector3.UP, deg_to_rad(teller.MONITOR_YAW)), Vector3.ZERO) * Transform3D(Basis(), -MONITOR_OLD)
	for child: Node3D in moved:
		child.global_transform = town.global_transform * place * (to_town * child.global_transform)
	if moved.size() != 3:
		push_error("bank teller_side_monitor: expected 3 monitor parts, found %d" % moved.size())
	print("BANK teller_side_monitor: moved ", moved.map(func(n): return n.name))

## Faces the annex brought into one plane (coplanar_gaps.gd, third pass).
func coplanar_gaps_3(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/coplanar_gaps.gd").separate(town, "bank", 3)

## The staff door was 0.95 wide (about 1.24 m in the world), narrower than BonBon's body (1.52 m):
## the player could not get behind the counter (user, 24 Nov 2026). Rebuilt 1.3 wide, as the
## vault door: town x 138.85-140.15, clear of window 3's chair (x 138.15) and the back counter
## (x 140.8). teller_session.gd MANAGER_DOOR / MANAGER_SPOT follow its middle.
const WIDE_STAFF_DOOR_Z := Vector2(49.85, 51.15)

func wider_staff_door(town: Node3D, game) -> void:
	var bank := _bank(town)
	for title in ["Staff door", "Manager divider", "Manager divider back", "Staff door head"]:
		var node := bank.get_node_or_null(title)
		if node == null:
			push_error("bank wider_staff_door: no " + title)
		_remove(game, node)
	_build_staff_door(bank, game, WIDE_STAFF_DOOR_Z)

## The three teller chairs become seats (user, 24 Nov 2026: "make those seats behind the counter
## actual seats"; the teller game seats the player on window 2's, teller_session.gd). They were
## baked with sit_disabled while the teller side could not be reached. The seat parts are named
## by window (1 at town z 106.5, 2 at 107.7, 3 at 108.9); the chair back behind each seat gives
## the facing (the glass, -x), as for any chair (seating_controller.gd).
func teller_seats(town: Node3D, _game) -> void:
	var interior := _bank(town).get_node("Interior")
	var to_town := town.global_transform.affine_inverse()
	var found := 0
	for child in interior.get_children():
		if not child is Node3D or not child.has_meta("sit_disabled"):
			continue
		var at: Vector3 = (to_town * (child as Node3D).global_transform).origin
		if absf(at.x - 137.9) > 0.05 or absf(at.y - 0.51) > 0.05:
			continue   # a chair back
		var window := 1 + roundi((at.z - 106.5) / 1.2)
		child.name = "Teller chair seat %d" % window
		child.remove_meta("sit_disabled")
		child.set_meta("sit_enabled", true)
		found += 1
	if found != 3:
		push_error("bank teller_seats: expected 3 teller chair seats, found %d" % found)
	print("BANK teller_seats: %d seats" % found)

## Door sounds (user, 25 Nov 2026: "each door should have different sound"): the safe's dial
## and handle, the vault's heavy creak and thud (door_animator.gd set_sound_kind; cues door.safe.*
## and door.vault.* in data/sounds.json; the vault's thud plays when it has shut).
func door_sounds(town: Node3D, game) -> void:
	var DoorAnimator := preload("res://scripts/core/door_animator.gd")
	var bank := _bank(town)
	var tagged := int(DoorAnimator.set_sound_kind(game, bank.get_node_or_null("Vault safe door"), "safe"))
	tagged += int(DoorAnimator.set_sound_kind(game, bank.get_node_or_null("Vault entrance"), "vault"))
	if tagged != 2:
		push_error("bank door_sounds: expected 2 doors, tagged %d" % tagged)
	print("BANK door_sounds: %d doors" % tagged)


## Colours snapped to the game palette with the hue guard (P3-22, decision D14: approved by the
## user 26 Nov 2026 after the library/police trial; scripts/buildings/palette_snap.gd,
## docs/evidence/pastel-20261125/).
func palette_snap(town: Node3D, _game) -> void:
	preload("res://scripts/buildings/palette_snap.gd").snap(town, "bank")
