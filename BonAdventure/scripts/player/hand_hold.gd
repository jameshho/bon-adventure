extends Node3D
## Left-hand holding for the player (user request, 13 Nov 2026; docs/guides/HAND_HOLD.md).
## player_controller.gd creates one as `player.hand`, a socket on BonBon's left mitten: it is a
## child of her "Arm" part, so the held item follows every arm pose (walking, running, jumping,
## sitting) with no extra animation. While something is held, animate_bonbon() asks arm_pose()
## for a holding pose: the arm a little forward and out, and a smaller walking swing; standing
## still the arm and the item are at rest.
##
##   var previous := player.hand.hold(book)        # any Node3D; returns what was held (detached)
##   player.hand.release(shelf_gap, gap_transform)  # put it somewhere (keeps its world size)
##   player.hand.release()                          # put it back where it was picked up
##   player.hand.held                               # the item, or null
##
## How an item sits in the hand is a PROFILE (rotation, grip point, arm pose, sway, inspection
## view), chosen by `kind` or the item's `hold_kind` meta/property: "book", "basket", else
## "default". Add a profile for a new kind of object. The item keeps its world size; its solid
## collision shapes are switched off while held (pick areas stay, so a click still names it)
## and restored on release. Only a held item that swings (sway > 0) costs any per-frame work.

signal held_changed(item: Node3D)

## BonBon-local point of the left mitten's palm (pig_art_variants.gd _arm(): the mitten spans
## x -0.98 ... -0.63, y 0.86 ... 1.22, z -0.16 ... 0.18; BonBon faces -Z, her left is -X).
const PALM := Vector3(-0.86, 0.95, 0.01)

## rotation: item turn in the hand (degrees, BonBon's frame: -Z forward, -X outward);
## grip: the point of the item's own bounding box (0..1 per axis) that sits in the palm;
## offset: palm to grip, BonBon units; arm: x forward lift (rad), y share of the walking swing,
## z outward lift (rad); sway: how freely it swings from the hand (0 = held firmly);
## inspect: the close-up pose (object_inspector.gd: yaw, tilt in degrees, fill of the view).
const PROFILES := {
	# Upright at her side, cover facing out, spine forward; the mitten grips it near its middle.
	"book": {"rotation": Vector3(0, 90, 0), "grip": Vector3(.5, .42, 1.0), "offset": Vector3(.04, 0, 0),
		"arm": Vector3(.1, .5, .16), "sway": 0.0, "inspect": {"yaw": 180.0, "tilt": 0.0, "fill": .78}},
	# Hanging from its handles, long side along her walking direction. Inspected from nearly
	# straight above (14 Nov 2026, user: see what is inside), filling the view.
	"basket": {"rotation": Vector3(0, 90, 0), "grip": Vector3(.5, .96, .5), "offset": Vector3(0, .03, 0),
		"arm": Vector3(.04, .45, .3), "sway": 1.0, "inspect": {"yaw": 180.0, "tilt": 80.0, "fill": 1.0}},
	"default": {"rotation": Vector3.ZERO, "grip": Vector3(.5, .5, .5), "offset": Vector3(-.05, 0, 0),
		"arm": Vector3(.15, .55, .12), "sway": 0.0, "inspect": {"yaw": 180.0, "tilt": 12.0, "fill": .7}},
}

## The held item (null when the hand is empty) and its profile.
var held: Node3D
var profile: Dictionary = PROFILES["default"]
## The node the item hangs from: it turns about the palm when the item sways.
var swing: Node3D
## The body whose forward motion makes a hanging item sway (BonBon's Visual).
var body: Node3D
var _home := {}
var _disabled_shapes: Array = []
var _angle := 0.0
var _spin := 0.0
var _last_pos := Vector3.ZERO
var _last_vel := Vector3.ZERO

## `arm`: BonBon's left "Arm" part (this socket becomes its child); `arm_rest`: its rest pose.
func setup(arm: Node3D, arm_rest: Transform3D, visual: Node3D) -> void:
	name = "LeftHand"
	body = visual
	rebind(arm, arm_rest)
	swing = Node3D.new()
	swing.name = "Swing"
	add_child(swing)
	set_process(false)

## Moves the socket onto another model's left arm (a profile's avatar replaces BonBon's model:
## player_controller.gd set_avatar()).
func rebind(arm: Node3D, arm_rest: Transform3D) -> void:
	if get_parent() != null:
		get_parent().remove_child(self)
	arm.add_child(self)
	position = arm_rest.affine_inverse() * PALM

func is_holding() -> bool:
	return held != null and is_instance_valid(held)

## Takes `item` in the hand; a held item is first detached and returned (not put back).
func hold(item: Node3D, kind := "") -> Node3D:
	var previous: Node3D = null
	if is_holding():
		previous = release(null, null, false)
	if item == null:
		return previous
	profile = PROFILES.get(_kind_of(item, kind), PROFILES["default"])
	var size_world := item.global_basis.get_scale() if item.is_inside_tree() else item.basis.get_scale()
	_home = {"parent": item.get_parent(), "transform": item.transform, "index": item.get_index() if item.get_parent() else -1}
	if item.get_parent() != null:
		item.get_parent().remove_child(item)
	swing.add_child(item)
	_disable_solids(item)
	# Keep the item's world size whatever BonBon's scale.
	var mine := swing.global_basis.get_scale()
	var turn := Basis.from_euler(profile.rotation * PI / 180.0)
	item.basis = turn * Basis.from_scale(Vector3(size_world.x / mine.x, size_world.y / mine.y, size_world.z / mine.z))
	var box := local_bounds(item)
	var grip: Vector3 = box.position + box.size * (profile.grip as Vector3)
	item.position = -(item.basis * grip) + (profile.offset as Vector3)
	held = item
	_angle = 0.0
	_spin = 0.0
	swing.rotation = Vector3.ZERO
	_last_pos = global_position
	_last_vel = Vector3.ZERO
	set_process(float(profile.sway) > 0.0)
	held_changed.emit(item)
	return previous

## Lets go of the held item and returns it. With no `target` it goes back where it was picked
## up (same parent and transform); with a target it moves there, at `global_xf` if given, else
## where it is now. `put_down` false only detaches it (hold() uses this for a swap).
func release(target: Node = null, global_xf: Variant = null, put_down := true) -> Node3D:
	if not is_holding():
		held = null
		return null
	var item := held
	var now := item.global_transform
	held = null
	set_process(false)
	swing.rotation = Vector3.ZERO
	swing.remove_child(item)
	_restore_solids()
	if put_down:
		var parent: Node = target if target != null else _home.get("parent")
		if parent != null and is_instance_valid(parent):
			parent.add_child(item)
			if target == null:
				if int(_home.get("index", -1)) >= 0:
					parent.move_child(item, mini(int(_home.index), parent.get_child_count() - 1))
				item.transform = _home.transform
			else:
				item.global_transform = global_xf if global_xf is Transform3D else now
	_home = {}
	held_changed.emit(null)
	return item

## Where release() with no target would put the held item back (world transform), or null.
func home_transform() -> Variant:
	var parent: Node = _home.get("parent")
	if not is_holding() or not parent is Node3D or not is_instance_valid(parent):
		return null
	return (parent as Node3D).global_transform * (_home.transform as Transform3D)

## Holds `item` and returns the one it replaces, detached (the caller places it).
func swap(item: Node3D, kind := "") -> Node3D:
	return hold(item, kind)

## The player's hand, found from any node in the tree (null without a player, e.g. a fixture).
static func of_player(from: Node) -> Node3D:
	var player := from.get_tree().get_first_node_in_group("player") if from != null and from.is_inside_tree() else null
	return player.get("hand") if player != null else null

## The standard use() of a holdable item (its Interactable's action): E, a click or a tap takes
## `item` in the player's hand, first putting back whatever the hand held; on the item already
## in the hand, puts it back where it was picked up. New holdable objects call this instead of
## writing their own take / put-back code (docs/guides/COMPONENTS.md#holding-items).
static func toggle(item: Node3D) -> void:
	var hand := of_player(item)
	if hand == null:
		return
	if hand.held == item:
		hand.release()
		return
	if hand.is_holding():
		hand.release()
	hand.hold(item)

## The holding arm pose for animate_bonbon(): x forward lift, y walking-swing share, z out lift.
func arm_pose() -> Vector3:
	return profile.arm if is_holding() else Vector3(0, 1, 0)

## The close-up options for object_inspector.gd.
func inspect_options() -> Dictionary:
	return profile.get("inspect", {})

## The bounding box of an item's visible meshes in its own frame (its unscaled local space).
static func local_bounds(item: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var to_item := item.global_transform.affine_inverse() if item.is_inside_tree() else Transform3D.IDENTITY
	for node in [item] + item.find_children("*", "VisualInstance3D", true, false):
		if not node is VisualInstance3D or node is Label3D:
			continue
		var visual := node as VisualInstance3D
		var xf: Transform3D = to_item * visual.global_transform if item.is_inside_tree() else _path_xf(item, visual)
		var part: AABB = xf * visual.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box if not first else AABB(Vector3(-.1, 0, -.1), Vector3(.2, .2, .2))

static func _path_xf(top: Node3D, node: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != top:
		if n is Node3D:
			xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return xf

func _kind_of(item: Node3D, kind: String) -> String:
	if kind != "":
		return kind
	if item.has_meta("hold_kind"):
		return str(item.get_meta("hold_kind"))
	var own = item.get("hold_kind")
	return str(own) if own != null else "default"

func _disable_solids(item: Node3D) -> void:
	_disabled_shapes.clear()
	for shape in item.find_children("*", "CollisionShape3D", true, false):
		if shape.get_parent() is PhysicsBody3D and not shape.disabled:
			shape.set_deferred("disabled", true)
			_disabled_shapes.append(shape)

func _restore_solids() -> void:
	for shape in _disabled_shapes:
		if is_instance_valid(shape):
			shape.set_deferred("disabled", false)
	_disabled_shapes.clear()

## A hanging item swings about the palm like a pendulum, pushed by the hand's forward and
## backward acceleration (walking, stopping, turning) and settling when she stands still.
func _process(delta: float) -> void:
	if delta <= 0.0 or not is_holding():
		return
	var pos := global_position
	var vel := (pos - _last_pos) / delta
	var accel := (vel - _last_vel) / delta
	_last_pos = pos
	_last_vel = vel
	var forward := -(body.global_basis.z.normalized()) if body != null else Vector3.FORWARD
	var push := clampf(accel.dot(forward), -40.0, 40.0)
	var freedom: float = profile.sway
	# θ'' = -ω²θ - cθ' - a/L (a forward push swings the bottom backward).
	_spin += (-36.0 * _angle - 5.0 * _spin - push * 0.9 * freedom) * delta
	_angle = clampf(_angle + _spin * delta, -.35 * freedom, .35 * freedom)
	# BonBon faces -Z: a negative turn about her X axis moves the bottom backward (+Z).
	swing.rotation.x = _angle
