extends RefCounted
## Positive feedback for a right answer on a 3D object (user, 21 Nov 2026: "reusable, the one we
## have for the library game"): gold sparks puffing out towards the viewer and, with celebrate(),
## a small hop of the object itself. Moved out of library_session.gd (a book shelved right); also
## used by the welcome tutorial's shopping list (tutorial_shop.gd, a right item picked). Sound-ready:
## a cheer can hook in at celebrate() once the game has audio.

## Sparks per burst and their size (metres).
const SPARKS := 10
const SPARK_RADIUS := .035
const SPARK_COLOR := Color("ffd34d")
## How far the sparks fly across and up, and out towards the viewer (metres, frame units).
const SPREAD := Vector2(.42, .38)
const LIFT := .1
const OUT := .16
## The hop: height (metres) and timing.
const HOP := .07

static var _mesh: SphereMesh

## Gold sparks puffing out of `frame.origin`: across its X, up its Y and out along its -Z (the
## viewer's side). Added under `parent`, freed after half a second.
static func sparks(parent: Node3D, frame: Transform3D, scale := 1.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	if _mesh == null:
		_mesh = SphereMesh.new()
		_mesh.radius = SPARK_RADIUS
		_mesh.height = SPARK_RADIUS * 2.0
		_mesh.radial_segments = 8
		_mesh.rings = 4
		var glow := StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.albedo_color = SPARK_COLOR
		_mesh.material = glow
	var basis := frame.basis.orthonormalized()
	for i in SPARKS:
		var spark := MeshInstance3D.new()
		spark.mesh = _mesh
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		spark.top_level = true
		parent.add_child(spark)
		spark.global_position = frame.origin
		spark.scale = Vector3.ONE * scale
		var angle := TAU * i / SPARKS + randf_range(-.25, .25)
		var local := Vector3(cos(angle) * SPREAD.x, sin(angle) * SPREAD.y + LIFT, -OUT) * scale
		var to := frame.origin + basis * local
		var tween := spark.create_tween().set_parallel()
		tween.tween_property(spark, "global_position", to, .5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "scale", Vector3.ONE * .01, .45).set_delay(.2)
		tween.chain().tween_callback(spark.queue_free)

## `node` hops once (HOP * scale up, a bounce down) and sparks puff out of `at` (global) towards
## `viewer` (a global point, e.g. the camera on screen).
static func celebrate(node: Node3D, at: Vector3, viewer: Vector3, scale := 1.0) -> void:
	if node == null or not node.is_inside_tree():
		return
	var home := node.position
	var up := (node.get_parent() as Node3D).global_basis.inverse() * Vector3.UP if node.get_parent() is Node3D else Vector3.UP
	var tween := node.create_tween()
	tween.tween_property(node, "position", home + up.normalized() * HOP * scale, .11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", home, .14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var toward := viewer - at
	if toward.length() < .01:
		toward = Vector3.BACK
	sparks(node, Transform3D(Basis.looking_at(toward, Vector3.UP if absf(toward.normalized().y) < .98 else Vector3.BACK), at), scale)
