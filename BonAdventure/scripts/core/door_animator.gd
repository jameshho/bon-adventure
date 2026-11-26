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
	if state["open"]:
		preload("res://scripts/learning/achievements.gd").shared().note("open_door")
	# A heavy door sounds its close when it shuts (_heavy_swing), the others at once. A double
	# door sounds once, from the leaf that was used.
	if state["open"] or float(state.get("seconds", 0.0)) <= 0.0:
		play_sound(node, state, bool(state["open"]))
	# A double door's leaves move together (scripts/world/double_door.gd).
	for partner in node.get_meta("door_partners", []):
		if is_instance_valid(partner) and main.doors.has(partner):
			main.doors[partner]["open"] = state["open"]

## Door sounds (user, 25 Nov 2026: "each door should have different sound"): a door's kind is its
## state "sound" (door.gd `sound`, or a building step: "locker", "cell", "cabinet", "safe",
## "vault", "glass"), else hinge doors are "room" and sliding doors ("safe_slide") "sliding".
## Drawers and curtains have none (silent); "none" silences any door. The cues are
## data/sounds.json door.<kind>.open / door.<kind>.close, played at the leaf (sound.gd).
static func sound_kind(state: Dictionary) -> String:
	if state.has("sound"):
		var kind := str(state["sound"])
		return "" if kind == "none" else kind
	match str(state.get("type", "")):
		"hinge":
			return "room"
		"slide":
			return "sliding" if bool(state.get("safe_slide", false)) else ""
	return ""

## The cue a door plays when it opens (true) or closes, or "" for a silent door.
static func sound_cue(state: Dictionary, opening: bool) -> String:
	var kind := sound_kind(state)
	return "" if kind == "" else "door.%s.%s" % [kind, "open" if opening else "close"]

## For building steps: gives the door_state on `node` (a door scene root: its `sound`) a sound
## kind. Returns false when there is no such door.
static func set_sound_kind(game, node: Node, kind: String) -> bool:
	if node == null:
		return false
	if node.get_script() != null and "sound" in node and node.has_method("leaves"):
		node.sound = kind
		return true
	if not node.has_meta("door_state"):
		return false
	var state: Dictionary = node.get_meta("door_state").duplicate(true)
	state["sound"] = kind
	node.set_meta("door_state", state)
	if game != null and game.get("doors") is Dictionary and game.doors.has(node):
		game.doors[node]["sound"] = kind
	return true

static func play_sound(node: Node3D, state: Dictionary, opening: bool) -> void:
	var cue := sound_cue(state, opening)
	var sound = preload("res://scripts/core/sound.gd").shared()
	if cue != "" and sound != null and sound.cues.has(cue):
		sound.play_at(cue, node)

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
			# A safe (21 Nov 2026, bank.gd vault_safe): "spin" names a child wheel that turns
			# "spin_angle" about its own Z when opening; the door waits until it has nearly done.
			if str(state.get("spin", "")) != "" and _spin(obj, state, delta):
				continue
			if float(state.get("seconds", 0.0)) > 0.0:
				_heavy_swing(obj, state, delta)
				continue
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

## A heavy hinged door (state "seconds" > 0; door.gd swing_seconds, the bank vault, 23 Nov 2026):
## a timed swing over "seconds" that starts slowly, then settles softly (smootherstep, eased in
## a little more), so the door seems to weigh a lot. Reversing mid-swing goes back from where it
## is. Progress 0 (shut) to 1 (open) is kept in state "swing".
static func _heavy_swing(obj: Node3D, state: Dictionary, delta: float) -> void:
	var goal := 1.0 if bool(state["open"]) else 0.0
	var t: float = float(state.get("swing", 0.0))
	if t == goal:
		return
	t = move_toward(t, goal, delta / float(state["seconds"]))
	state["swing"] = t
	obj.rotation.y = float(state.get("angle", -1.75)) * heavy_curve(t)
	if t == 0.0:
		# Shut: the heavy door's close sound (toggle() leaves it until now).
		play_sound(obj, state, false)

## The heavy swing's shape: 0 -> 0, 1 -> 1, flat at both ends; a slow, creaking first third.
static func heavy_curve(t: float) -> float:
	var s := t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
	return s * s * (3.0 - 2.0 * s) if t < 0.5 else s

## Turns a hinged door's "spin" wheel toward its state; true while an opening door must wait.
static func _spin(obj: Node3D, state: Dictionary, delta: float) -> bool:
	var wheel := obj.get_node_or_null(NodePath(str(state.spin))) as Node3D
	if wheel == null:
		return false
	var opening := bool(state["open"])
	var turn: float = float(state.get("spin_angle", TAU)) if opening else 0.0
	if absf(wheel.rotation.z - turn) > 0.001:
		wheel.rotation.z = lerpf(wheel.rotation.z, turn, minf(1.0, 7.0 * delta))
	return opening and absf(wheel.rotation.z - turn) > 0.6
