extends RefCounted
## Cabinet doors, room doors and drawers (main.doors: node -> door_state). Moved out of main.gd
## (7 Nov 2026); each is an interactable whose use flips state["open"] (make_interactables).

const Interactable := preload("res://scripts/core/interactable.gd")
const InteractIcons := preload("res://scripts/ui/interact_badge.gd")

## How far below its middle a curtain's "E" badge sits (the curtain's own units).
const CURTAIN_BADGE_DROP := 0.9

## Every registered door is an interactable (12 Nov 2026; interaction_controller.gd): E, a click
## or a tap opens or closes it. The "E" badge sits on the middle of the leaf.
static func make_interactables(main) -> void:
	for node in main.doors:
		if is_instance_valid(node):
			make_interactable(main, node)

static func make_interactable(main, node: Node3D) -> void:
	var badge: Vector3 = InteractIcons.local_center(node)
	# A shower curtain hangs from a high rail: its middle is above the height E reaches
	# (interaction_controller.gd MAX_RISE), so its badge sits at hand height (13 Nov 2026).
	if main.doors.has(node) and str(main.doors[node].get("type", "")) == "curtain":
		badge.y -= CURTAIN_BADGE_DROP
	Interactable.attach(node, {
		"kind": Interactable.Kind.OPEN,
		"prompt_distance": 2.4,
		"priority": -0.5,
		"badge_offset": badge,
		"on_use": func() -> void: toggle(main, node),
	})

## Opens a closed door and closes an open one.
static func toggle(main, node: Node3D) -> void:
	if not main.doors.has(node):
		return
	var state: Dictionary = main.doors[node]
	state["open"] = not bool(state["open"])
	main.doors[node] = state
	# A double door's leaves move together (scripts/world/double_door.gd).
	for partner in node.get_meta("door_partners", []):
		if is_instance_valid(partner) and main.doors.has(partner):
			main.doors[partner]["open"] = state["open"]

## Collects every saved door_state below `node` into main.doors, closed.
static func restore_editor_door_states(main, node: Node) -> void:
	if node.has_meta("door_state"):
		var state: Dictionary = node.get_meta("door_state").duplicate(true)
		state["open"] = false
		if state.get("type") == "slide":
			# Keep a drawer's new editor position as its closed position.
			state["origin"] = node.position
		main.doors[node] = state
	for child in node.get_children():
		restore_editor_door_states(main, child)

## Animates every door toward its state without teleporting geometry. A closing "safe_slide"
## door that would hit the player opens again.
static func animate(main, delta: float) -> void:
	var doors: Dictionary = main.doors
	for obj in doors.keys():
		if not is_instance_valid(obj):
			continue
		var state: Dictionary = doors[obj]
		var alpha: float = minf(1.0, 8.0 * delta)
		if str(state["type"]) == "hinge":
			var target: float = float(state.get("angle", -1.75)) if bool(state["open"]) else 0.0
			if absf(angle_difference(obj.rotation.y, target)) < 0.001:
				if obj.rotation.y != target: obj.rotation.y = target
				continue
			obj.rotation.y = lerp_angle(obj.rotation.y, target, alpha)
		elif str(state["type"]) == "curtain":
			# Shower curtains (13 Nov 2026, home_furnishing.gd): the node's origin is the end fixed
			# to the wall and the cloth runs along local +X; closed (open = false) it is bunched
			# at the wall (scale.x = "rest"), opened it is drawn along the rail ("drawn").
			var width: float = float(state.get("drawn", 1.0)) if bool(state["open"]) else float(state.get("rest", .2))
			if absf(obj.scale.x - width) < .0005:
				if obj.scale.x != width: obj.scale.x = width
				continue
			obj.scale.x = lerpf(obj.scale.x, width, alpha)
		else:
			var offset: Vector3 = state["shift"] if bool(state["open"]) else Vector3.ZERO
			var dest: Vector3 = state["origin"] + offset
			if obj.position.distance_squared_to(dest) < 0.000001:
				if obj.position != dest: obj.position = dest
				continue
			var next_position:Vector3 = obj.position.lerp(dest, alpha)
			if state.get("safe_slide",false) and not bool(state["open"]):
				var query:=PhysicsShapeQueryParameters3D.new()
				var door_shape:CollisionShape3D=obj.find_children("*","CollisionShape3D",true,false)[0]
				var shape:=BoxShape3D.new()
				shape.size=door_shape.shape.size*obj.global_basis.get_scale().abs()
				query.shape=shape
				query.transform=Transform3D(obj.global_basis.orthonormalized(),obj.get_parent().to_global(next_position))
				for hit in main.get_world_3d().direct_space_state.intersect_shape(query):
					if hit.collider==main.player:
						state["open"]=true
						main.hud.flash_quest_message(preload("res://scripts/language/ui_text.gd").t("toast.doorway_occupied"))
						break
				if state["open"]: continue
			obj.position = next_position
