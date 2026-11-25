extends Node3D
## One egg laid by the hens of the farm's hen house (user, 24 Nov 2026; owner hen_house.gd, record:
## docs/guides/TOWN_DESIGN_BRIEF.md#hen-house-and-eggs--24-november-2026). Built in code, never
## baked: hen_house.gd makes one per laid egg at its spot and frees it when it is delivered or
## dropped. E, a click or a tap (its Interactable) takes it in the player's left hand (hand_hold.gd
## profile "egg"); on the egg in the hand, puts it back in its nest. The egg crate by the coop door takes
## it from the hand; the Drop button (drop()) breaks it. A golden egg (rare) shines; it is otherwise the same.
const Interactable := preload("res://scripts/core/interactable.gd")
const HandHold := preload("res://scripts/player/hand_hold.gd")
const SELF := preload("res://scripts/world/farm_egg.gd")

## Egg size in town units (the hen is about 0.62 tall): radius across, stretched up by TALL.
const RADIUS := .065
const TALL := 1.3
const WHITE := Color("f4ead8")
const BROWN := Color("d9a774")
const GOLD := Color("f4c542")

var golden := false
## The spot (hen_house.gd "Egg spots" child index) the egg lies at.
var spot := -1
## In the crate: no longer picked up.
var delivered := false
## The hen house that laid it (hen_house.gd sets it): the Drop button breaks it through there.
var house: Node

static var _materials := {}

static func make(at_spot: int, is_golden: bool, brown: bool) -> Node3D:
	var egg: Node3D = SELF.new()
	egg.spot = at_spot
	egg.golden = is_golden
	egg.name = "Golden egg" if is_golden else "Egg"
	egg.set_meta("brown", brown)
	return egg

func _ready() -> void:
	set_meta("hold_kind", "egg")
	var mesh := MeshInstance3D.new()
	mesh.name = "Shell"
	var shape := SphereMesh.new()
	shape.radius = RADIUS
	shape.height = RADIUS * 2.0
	shape.radial_segments = 16
	shape.rings = 8
	mesh.mesh = shape
	# Fuller at the bottom: stretched up and its centre raised so it rests on the nest.
	mesh.scale = Vector3(1, TALL, 1)
	mesh.position.y = RADIUS * TALL
	mesh.material_override = _material("gold" if golden else ("brown" if get_meta("brown", false) else "white"))
	add_child(mesh)
	# The pick area (layer 2, like the vocabulary prefabs): a click or tap names the egg.
	var area := Area3D.new()
	area.name = "Pick"
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = false
	var hit := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = RADIUS * 1.8
	hit.shape = ball
	hit.position.y = RADIUS * TALL
	area.add_child(hit)
	add_child(area)
	Interactable.attach(self, {
		"prompt_distance": 1.6,
		"priority": 1.0,
		"badge_offset": Vector3(0, RADIUS * TALL * 2.0 + .18, 0),
		"on_point": func(_from: Vector3) -> Vector3: return _home_point(),
		"on_badge": func() -> Vector3: return _home_point() + Vector3(0, .25, 0),
	})

## E, a click or a tap: into the hand (whatever the hand held goes back first); the egg already in
## the hand goes back to its nest.
func use() -> void:
	HandHold.toggle(self)

## The Drop button (hold_inspect_ui.gd, G) while the egg is in the hand: it falls and breaks.
func drop() -> void:
	if house != null and is_instance_valid(house):
		house.drop_held(self)

func can_interact() -> Variant:
	return not delivered

## Where range is measured to: the egg, or for the egg in the hand its empty nest (so E near the
## crate means the crate, and E at the nest puts it back).
func _home_point() -> Vector3:
	var hand := HandHold.of_player(self) if is_inside_tree() else null
	if hand != null and hand.held == self:
		var home: Variant = hand.home_transform()
		if home is Transform3D:
			return (home as Transform3D).origin
	return global_position

static func _material(kind: String) -> StandardMaterial3D:
	if _materials.has(kind):
		return _materials[kind]
	var m := StandardMaterial3D.new()
	m.roughness = .55
	match kind:
		"gold":
			m.albedo_color = GOLD
			m.metallic = .75
			m.roughness = .25
			m.emission_enabled = true
			m.emission = Color("ffd84a")
			m.emission_energy_multiplier = .45
		"brown":
			m.albedo_color = BROWN
		_:
			m.albedo_color = WHITE
	_materials[kind] = m
	return m
