extends Node3D
## A town stamp: a floating gold coin tucked in some corner of a building, collected once like an
## achievement (user, 21 Nov 2026; guide: docs/guides/ACHIEVEMENTS.md#town-stamps). Walking into
## it collects it: the coin spins up, rises and shrinks into a puff of gold sparks
## (success_burst.gd), Achievements.shared().note("stamp.<stamp_id>") records it (the HUD toast
## and XP follow from the unlock) and it never shows again for this profile.
##
## Use: add scenes/props/stamp_coin.tscn (or StampCoin.make(stamp_id)) anywhere and set stamp_id
## to an id of data/achievements.json "stamps". The shape is built in code (no model files); the
## face is assets/stamps/coin_face.svg (the user's coin picture, 21 Nov 2026: the pig head traced
## with vtracer, built by assets/stamps/source/build_coin_face.py), on both sides.
## Sound (25 Nov 2026): `collected` plays coin.stamp, a flat UI chime bound in data/sounds.json
## (flat, because the coin frees itself before a positional sound under it would end).
##
## Cost: the spin and bob run only while the coin is on screen (VisibleOnScreenNotifier3D); a
## coin off screen or collected does nothing. One small Area3D for the pickup, ~200 triangles.
const SELF := preload("res://scripts/world/stamp_coin.gd")
const Achievements := preload("res://scripts/learning/achievements.gd")
const SuccessBurst := preload("res://scripts/world/success_burst.gd")
const UiIcons := preload("res://scripts/ui/ui_icons.gd")
const FACE := preload("res://assets/stamps/coin_face.svg")
const GROUP := "stamp_coins"

## Emitted once when the coin is collected (the sound; never for a preview coin).
signal collected

## The stamp this coin gives (data/achievements.json "stamps").
@export var stamp_id := ""
## The picture on both faces: "pig" (the stamp face, coin_face.svg, the default), "star" (a raised
## star on plain gold) or any ui_icons.gd name (line art on plain gold).
@export var emblem := "pig"
## Coin radius in metres (thickness follows). 0.45 since 22 Nov 2026 (user: "50% bigger"; was 0.3).
@export var radius := 0.45
## Turns per second and the bob (metres up and down, seconds per bob).
@export var spin_speed := 0.35
@export var bob_height := 0.08
@export var bob_seconds := 2.4
## Metres from the coin's centre within which the player collects it.
@export var pickup_radius := 0.85
## Shown although already collected (the review scene; never in the town).
@export var preview := false

const GOLD := Color("f4c542")
const GOLD_DEEP := Color("c98a14")
const EMBLEM := Color("9a5d06")
const HALO := Color(1.0, 0.86, 0.4, 0.55)

## Optional: a hinged door (its pivot) the coin sits behind; it is collected only while that door
## stands open (rotated more than GATE_OPEN), so it cannot be picked up through the closed door
## (the Bank's safe; stamp_places.gd "gate").
var gate: Node3D
const GATE_OPEN := 0.5
var spinner: Node3D
var _time := 0.0
var _collected := false
var _area: Area3D

static func make(id: String, icon := "pig") -> Node3D:
	var coin: Node3D = SELF.new()
	coin.stamp_id = id
	coin.emblem = icon
	coin.name = "StampCoin_" + id
	return coin

func _ready() -> void:
	add_to_group(GROUP)
	if not preview and stamp_id != "" and Achievements.shared().has_stamp(stamp_id):
		_collected = true
		visible = false
		set_process(false)
		return
	_build()
	_time = randf() * bob_seconds
	set_process(false)
	var notifier := VisibleOnScreenNotifier3D.new()
	notifier.aabb = AABB(Vector3(-radius, -radius - bob_height, -radius) * 1.6, Vector3.ONE * radius * 3.2 + Vector3(0, bob_height * 2.0, 0))
	notifier.screen_entered.connect(set_process.bind(true))
	notifier.screen_exited.connect(set_process.bind(false))
	add_child(notifier)
	if not preview:
		_area = Area3D.new()
		_area.name = "Pickup"
		_area.collision_layer = 0
		_area.collision_mask = 1
		_area.monitorable = false
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = pickup_radius
		shape.shape = sphere
		_area.add_child(shape)
		add_child(_area)
		_area.body_entered.connect(_on_body)

func _build() -> void:
	spinner = Node3D.new()
	spinner.name = "Spinner"
	add_child(spinner)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = GOLD
	gold.metallic = 0.55
	gold.roughness = 0.32
	gold.emission_enabled = true
	gold.emission = GOLD_DEEP
	gold.emission_energy_multiplier = 0.35
	var rim_gold := gold.duplicate() as StandardMaterial3D
	rim_gold.albedo_color = GOLD_DEEP.lerp(GOLD, 0.45)
	var thick := radius * 0.2
	if emblem == "pig":
		_build_face_coin(gold, thick)
	else:
		_build_emblem_coin(gold, rim_gold, thick)
	for child in spinner.get_children():
		(child as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The pig face is colourful enough on its own: a glow sprite in front of it washed it out
	# (21 Nov 2026). Plain emblem coins keep the soft glow so they read from across a room.
	if emblem == "pig":
		return
	var halo := Sprite3D.new()
	halo.name = "Halo"
	halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	halo.shaded = false
	halo.double_sided = true
	halo.modulate = HALO
	halo.pixel_size = radius * 3.4 / 64.0
	halo.texture = _halo_texture()
	halo.render_priority = -1
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halo)

## The stamp face: a gold disc whose two faces carry coin_face.svg (its own rims and grooves).
func _build_face_coin(gold: StandardMaterial3D, thick: float) -> void:
	var edge := gold.duplicate() as StandardMaterial3D
	edge.albedo_color = Color("e3a020")
	var disc := MeshInstance3D.new()
	disc.name = "Disc"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius * 0.995
	cylinder.bottom_radius = radius * 0.995
	cylinder.height = thick * 0.8
	cylinder.radial_segments = 40
	cylinder.rings = 1
	cylinder.material = edge
	disc.mesh = cylinder
	disc.rotation.x = PI * 0.5
	spinner.add_child(disc)
	var look := StandardMaterial3D.new()
	look.albedo_texture = FACE
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	look.alpha_scissor_threshold = 0.5
	# Little shine and glow: more washes the face's outline out under the town's light (21 Nov 2026).
	look.metallic = 0.05
	look.roughness = 0.55
	look.emission_enabled = true
	look.emission_texture = FACE
	look.emission_energy_multiplier = 0.08
	look.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	for side in [1.0, -1.0]:
		var face := MeshInstance3D.new()
		face.name = "Face" + ("Front" if side > 0.0 else "Back")
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * radius * 2.0
		quad.material = look
		face.mesh = quad
		face.position.z = side * (thick * 0.4 + 0.002)
		if side < 0.0:
			face.rotation.y = PI
		spinner.add_child(face)

## Plain gold with a raised rim and an emblem ("star" or a ui_icons.gd line icon).
func _build_emblem_coin(gold: StandardMaterial3D, rim_gold: StandardMaterial3D, thick: float) -> void:
	# The disc: a short cylinder turned so its faces look along ±Z.
	var disc := MeshInstance3D.new()
	disc.name = "Disc"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius * 0.9
	cylinder.bottom_radius = radius * 0.9
	cylinder.height = thick * 0.8
	cylinder.radial_segments = 32
	cylinder.rings = 1
	cylinder.material = gold
	disc.mesh = cylinder
	disc.rotation.x = PI * 0.5
	spinner.add_child(disc)
	# The raised rim.
	var rim := MeshInstance3D.new()
	rim.name = "Rim"
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.82
	torus.outer_radius = radius
	torus.rings = 32
	torus.ring_segments = 8
	torus.material = rim_gold
	rim.mesh = torus
	rim.rotation.x = PI * 0.5
	rim.scale = Vector3(1.0, thick / (radius * 0.18), 1.0)
	spinner.add_child(rim)
	# The emblem, pressed into both faces.
	var picture := _star_texture() if emblem == "star" else UiIcons.texture(emblem, 128)
	for side in [1.0, -1.0]:
		var face := MeshInstance3D.new()
		face.name = "Emblem" + ("Front" if side > 0.0 else "Back")
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * radius * 1.15
		var ink := StandardMaterial3D.new()
		ink.albedo_texture = picture
		ink.albedo_color = EMBLEM
		ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		ink.alpha_scissor_threshold = 0.4
		ink.metallic = 0.4
		ink.roughness = 0.4
		quad.material = ink
		face.mesh = quad
		face.position.z = side * (thick * 0.4 + 0.003)
		if side < 0.0:
			face.rotation.y = PI
		spinner.add_child(face)

static var _halo: Texture2D
static var _star: Texture2D

## A filled five-point star with a lighter inner bevel, white (tinted by the material).
static func _star_texture() -> Texture2D:
	if _star == null:
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="128" height="128">' \
			+ '<path d="M12 1.8l3.1 6.4 7 1-5.1 4.9 1.2 7-6.2-3.3-6.2 3.3 1.2-7L1.9 9.2l7-1z" fill="#ffffff" stroke="#ffffff" stroke-width="1.2" stroke-linejoin="round"/></svg>'
		var image := Image.new()
		image.load_svg_from_string(svg)
		image.generate_mipmaps()
		_star = ImageTexture.create_from_image(image)
	return _star

static func _halo_texture() -> Texture2D:
	if _halo == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.45, Color(1, 1, 1, 0.35))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(0.5, 0.0)
		texture.width = 64
		texture.height = 64
		_halo = texture
	return _halo

func _process(delta: float) -> void:
	if _collected or spinner == null:
		return
	_time += delta
	spinner.rotation.y = fmod(_time * spin_speed * TAU, TAU)
	spinner.position.y = sin(_time / bob_seconds * TAU) * bob_height
	if gate != null:
		_check_gate()

func _on_body(body: Node) -> void:
	if body.is_in_group("player") and gate_open():
		collect()

func gate_open() -> bool:
	return gate == null or not is_instance_valid(gate) or absf(gate.rotation.y) > GATE_OPEN

## A gated coin: the player may already stand at it when the door opens.
func _check_gate() -> void:
	if gate == null or _area == null or not gate_open():
		return
	for body in _area.get_overlapping_bodies():
		if body.is_in_group("player"):
			collect()
			return

## Collects the stamp: records it, then the spin-up and sparks; the coin frees itself.
func collect() -> void:
	if _collected:
		return
	_collected = true
	if _area != null:
		_area.set_deferred("monitoring", false)
	if stamp_id != "" and not preview:
		Achievements.shared().note("stamp." + stamp_id)
	if not preview:
		collected.emit()
	set_process(false)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(spinner, "rotation:y", spinner.rotation.y + TAU * 3.0, 0.7).set_ease(Tween.EASE_IN)
	tween.tween_property(spinner, "position:y", spinner.position.y + 0.9, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(spinner, "scale", Vector3.ONE * 0.2, 0.7).set_delay(0.25)
	var halo := get_node_or_null("Halo")
	if halo != null:
		tween.tween_property(halo, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(func() -> void:
		var view := get_viewport().get_camera_3d()
		var frame := Transform3D(Basis.IDENTITY, spinner.global_position)
		var toward := view.global_position - spinner.global_position if view != null else Vector3.BACK
		if toward.length() > 0.01 and absf(toward.normalized().y) < 0.98:
			# -Z towards the viewer: the sparks puff out at the camera (success_burst.gd).
			frame = Transform3D(Basis.looking_at(toward, Vector3.UP), spinner.global_position)
		SuccessBurst.sparks(get_parent() as Node3D, frame, 2.2, 16, 0.7)
		if preview:
			return
		queue_free())
