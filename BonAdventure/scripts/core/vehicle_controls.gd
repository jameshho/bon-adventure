extends RefCounted
## Vehicles, the zoo and farm gates and the Home garage door: their interactables and what using
## them does. Moved out of main.gd (7 Nov 2026); Main keeps the public methods (checks call
## game.toggle_vehicle(), board_vehicle(), complete_vehicle_exit(), garage_door()) and the fields
## active_vehicle, driveable_vehicles, zoo_gate and farm_gate. Since 12 Nov 2026 each is an
## Interactable (interaction system, docs/guides/ARCHITECTURE_REVIEW_PART1.md#interaction-system): the
## focus pass picks it, E / a click / a tap uses it; the vehicle being driven claims E (Main).
const ModularTown := preload("res://scripts/world/modular_town.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
## Metres from the cabin or driver door within which E boards (as closest_vehicle used, to 12 Nov).
const BOARD_DISTANCE := 5.2
## Horizontal metres from a zoo / farm gate's centre within which E swings it.
const GATE_DISTANCE := 4.1

static func register_driveable_vehicles(main) -> void:
	# Existing vehicle instances stay in their original scenes and remain editable.
	# Every DriveableVehicle joins this group, including site-owned cars such as
	# Subi in the Home garage (RelocatedSites/Home), not only Vehicles/ children.
	main.driveable_vehicles.clear()
	for node in main.get_tree().get_nodes_in_group("driveable_vehicles"):
		var vehicle := node as DriveableVehicle
		if vehicle == null or not vehicle.has_meta("driveable_vehicle") or not main.apartment.is_ancestor_of(vehicle):
			continue
		main.driveable_vehicles.append(vehicle)
		if not vehicle.exit_finished.is_connected(main.complete_vehicle_exit):
			vehicle.exit_finished.connect(main.complete_vehicle_exit)
		if vehicle.map_edge_reached.get_connections().is_empty():
			# The plane past the map edge (turboprop.gd, 14 Nov 2026).
			vehicle.map_edge_reached.connect(func(_vehicle) -> void: main.hud.flash_quest_message(UiText.t("vehicle.map_edge")))
	main.zoo_gate = main.apartment.get_node_or_null("ParkZoo/ZooEntranceGate") as ZooGate
	main.farm_gate = main.apartment.get_node_or_null("ParkZoo/FarmEntranceGate") as ZooGate

static func make_interactables(main) -> void:
	for vehicle in main.driveable_vehicles:
		if is_instance_valid(vehicle):
			_vehicle_interactable(main, vehicle)
	for gate in [main.zoo_gate, main.farm_gate]:
		if is_instance_valid(gate):
			Interactable.attach(gate, {
				"kind": Interactable.Kind.OPEN,
				"prompt_distance": GATE_DISTANCE,
				"needs_facing": false,
				"priority": 0.3,
				"badge_offset": Vector3(0, 1.7, 0),
				"on_use": func() -> void: toggle_gate(main, gate),
			})
	var door := garage_door(main)
	if door != null:
		# Outside, or inside with no car to board beside it (the car's E wins there), or aimed at.
		Interactable.attach(door, {
			"kind": Interactable.Kind.OPEN,
			"prompt_distance": 2.4,
			"needs_facing": false,
			"priority": -0.5,
			"on_point": func(from: Vector3) -> Vector3: return from if door.is_near(from) else door.to_global(Vector3(0, 1.2, 0)),
			"on_badge": func() -> Vector3: return door.to_global(Vector3(0, 1.25, 0.15 if door.is_outside(main.player.global_position) else -0.15)),
			"on_check": func() -> Variant:
				var p: Vector3 = main.player.global_position
				return door.is_outside(p) or main.interaction.aimed_interactable_last() == Interactable.on(door) or not _free_vehicle_near(main, p),
			"on_use": func() -> void: toggle_garage_door(main, door),
		})

static func _free_vehicle_near(main, p: Vector3) -> bool:
	for vehicle in main.driveable_vehicles:
		if is_instance_valid(vehicle) and not vehicle.occupied and vehicle.entrance_distance(p) < BOARD_DISTANCE:
			return true
	return false

## A vehicle's interactable: within BOARD_DISTANCE of its cabin or driver door (entrance_distance),
## the badge beside the driver door (or the cabin when it has no animated door).
static func _vehicle_interactable(main, vehicle: DriveableVehicle) -> void:
	Interactable.attach(vehicle, {
		"kind": Interactable.Kind.BOARD if vehicle.fixed_wing or vehicle.helicopter else Interactable.Kind.DRIVE,
		"prompt_distance": BOARD_DISTANCE,
		"needs_facing": false,
		"priority": 0.5,
		"on_point": func(from: Vector3) -> Vector3:
			# A point at entrance_distance from `from`, level with it: the controller measures it.
			var away := vehicle.global_position - from
			away.y = 0.0
			return from + (away.normalized() if away.length() > 0.001 else Vector3.FORWARD) * vehicle.entrance_distance(from),
		"on_badge": func() -> Vector3:
			if vehicle.animated_boarding():
				return vehicle.boarding_step_point() + Vector3.UP * 1.3
			return vehicle.global_position + vehicle.global_basis.y * (2.2 if vehicle.helicopter else 1.6),
		"on_check": func() -> Variant: return not vehicle.occupied and not is_instance_valid(main.active_vehicle),
		"on_use": func() -> void: board(main, vehicle),
	})

## E while driving: leaves the vehicle. Otherwise boards the focused vehicle (checks call it beside
## a car). True when it acted.
static func toggle_vehicle(main) -> bool:
	var player = main.player
	var hud = main.hud
	if is_instance_valid(main.active_vehicle):
		var vehicle: DriveableVehicle = main.active_vehicle
		var exit_result: Dictionary = vehicle.safe_exit(player)
		if not exit_result.ok:
			hud.flash_quest_message(exit_result.reason)
			return true
		if exit_result.get("door", false):
			# Door, climb-out and walk-away play first; exit_finished completes it.
			vehicle.begin_exit(exit_result.point)
			player.begin_vehicle_exit(exit_result.point)
			return true
		complete_vehicle_exit(main, vehicle, exit_result.point)
		return true
	main.interaction.refresh_focus()
	var focus: Node = main.interaction.focus
	if focus == null or not focus.get_parent() is DriveableVehicle:
		return false
	return board(main, focus.get_parent())

## Boards `next_vehicle` (its interactable's use). A wall between the player and the cabin: the
## "walk to the entrance" line instead.
static func board(main, next_vehicle: DriveableVehicle) -> bool:
	var player = main.player
	var hud = main.hud
	if next_vehicle == null or next_vehicle.occupied or is_instance_valid(main.active_vehicle):
		return false
	var boarding_ray := PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*1.2,next_vehicle.global_position+Vector3.UP*1.5)
	boarding_ray.exclude = next_vehicle.collision_exceptions + [player.get_rid()]
	boarding_ray.collision_mask = 0xFFFFFEFF # characters beside a vehicle don't block boarding
	if not main.get_world_3d().direct_space_state.intersect_ray(boarding_ray).is_empty():
		hud.flash_quest_message(UiText.t("toast.walk_to_entrance"))
		return true
	main.interaction.clear_card()
	main.active_vehicle = next_vehicle
	next_vehicle.occupied = true
	next_vehicle.begin_boarding()
	player.board_vehicle(next_vehicle)
	if next_vehicle.fixed_wing:
		hud.flash_quest_message(UiText.t("toast.turboprop_easy" if DriveableVehicle.easy_flying else "toast.turboprop_help"))
	elif next_vehicle.helicopter:
		hud.flash_quest_message(UiText.t("toast.helicopter_easy" if DriveableVehicle.easy_flying else "toast.helicopter_help"))
	else:
		hud.flash_quest_message(UiText.t("toast.driving_help"))
		# At night the headlights come on by themselves (21 Nov 2026); F / Lights switches them.
		var day_night = main.get("day_night")
		if day_night != null and day_night.is_night(day_night.clock_minute() / 60.0):
			next_vehicle.set_headlights(true)
	return true

static func complete_vehicle_exit(main, vehicle: DriveableVehicle, point: Vector3) -> void:
	if vehicle != main.active_vehicle:
		return
	vehicle.occupied = false
	vehicle.finish_exit()
	main.player.leave_vehicle(point)
	main.active_vehicle = null
	main.interaction.clear_card()
	main.hud.flash_quest_message(UiText.t("toast.exited"))

static func toggle_gate(main, gate: ZooGate) -> void:
	gate.toggle_gate()
	main.hud.flash_quest_message(UiText.t("toast.zoo_open" if gate.is_open else "toast.zoo_closed"))

static func garage_door(main) -> Node3D:
	return ModularTown.building(main.apartment, "home", 0, "Garage door")

static func toggle_garage_door(main, door: Node3D) -> void:
	door.toggle()
	main.hud.flash_quest_message(UiText.t("toast.garage_opening" if door.is_open else "toast.garage_closing"))

## Four times a second (from update_home): a helicopter or plane nobody is flying that is more than
## DriveableVehicle.AIRCRAFT_RESET_DISTANCE from the player, away from where it started, goes back
## there (user, 14 Nov 2026; crashes reset in the vehicle itself). Cars stay where they were left.
static func update_aircraft(main) -> void:
	var p: Vector3 = main.player.global_position
	for vehicle in main.driveable_vehicles:
		if not is_instance_valid(vehicle) or not vehicle.is_aircraft() or vehicle.occupied or vehicle == main.active_vehicle or vehicle.crashed:
			continue
		if vehicle.global_position.distance_to(p) > DriveableVehicle.AIRCRAFT_RESET_DISTANCE \
				and vehicle.global_position.distance_to(vehicle.start_pose().origin) > 2.0:
			vehicle.reset_to_start()

## Four times a second (main._process): the Home roof lifts while the learner is under it. (The
## garage door's arrival prompt became its "E" badge, 12 Nov 2026.)
static func update_home(main) -> void:
	var player = main.player
	var hud = main.hud
	update_aircraft(main)
	var home := ModularTown.building(main.apartment, "home")
	if home != null and home.has_node("Home roof"):
		var p: Vector3=home.to_local(player.global_position)
		# Lift the decorative roof only while the learner is under it (house, garage, west wing),
		# not on the pool terrace or the lawn beside it. The roof is solid since 7 Nov 2026
		# (it starts at y 4.0, where the walls end): standing on it keeps it in place.
		# 10 Nov 2026: the rectangles are the wall lines, not the roof outline: the 0.6 m eaves
		# made the roof vanish for anyone outside beside a wall (front door, pool glazing).
		# 12 Nov 2026 (bigger home, home_expansion.gd): main hall x -11..16 z -3..17, east wing
		# x 16..26 z -3..14, garage x 6..26 z 14..23, guest suite x -11..-2.5 z -12..-3.
		# 13 Nov 2026: the house is 1.8x taller; the roof starts at y 7.2 (home_expansion.gd HOUSE_TOP).
		var under_roof := p.y < 7.1 and (
			Rect2(-11.0, -3.0, 27.0, 20.0).has_point(Vector2(p.x, p.z))
			or Rect2(16.0, -3.0, 10.0, 17.0).has_point(Vector2(p.x, p.z))
			or Rect2(6.0, 14.0, 20.0, 9.0).has_point(Vector2(p.x, p.z))
			or Rect2(-11.0, -12.0, 8.5, 9.0).has_point(Vector2(p.x, p.z)))
		home.get_node("Home roof").visible = not under_roof
	var door := garage_door(main)
	if door != null and not door.on_blocked.is_valid():
		door.on_blocked = func(): hud.flash_quest_message(UiText.t("toast.garage_stopped"))
