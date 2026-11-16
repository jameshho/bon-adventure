extends Node
## Head portraits of the plush characters for 2D screens (the hospital family game). Each
## species is rendered ONCE into a small off-screen SubViewport (its own 3D world: the
## plush, a camera in front of its head and two lights) and the viewport's texture is
## reused for every card of that species; nothing is saved to disk, so a changed plush
## sculpt shows up on the next run. Add this node anywhere in the scene tree, then call
## texture(species). Species are the plush scene names: "pig" -> scenes/characters/pig_plush.tscn.
const SIZE := 192
const SCENE := "res://scenes/characters/%s_plush.tscn"
## Pixel size of new portraits (tools/make_app_icons.gd renders bigger ones).
var size := SIZE

var _views: Dictionary = {}

func texture(species: String) -> Texture2D:
	if not _views.has(species):
		_views[species] = _render(species)
	var view: SubViewport = _views[species]
	return view.get_texture() if view != null else null

func _render(species: String) -> SubViewport:
	var path := SCENE % species
	if not ResourceLoader.exists(path):
		push_warning("plush_portraits: no plush scene for '%s'" % species)
		return null
	var view := SubViewport.new()
	view.name = "Portrait_" + species
	view.size = Vector2i(size, size)
	view.own_world_3d = true
	view.transparent_bg = true
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(view)
	var plush: Node3D = load(path).instantiate()
	view.add_child(plush)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1, 1, 1)
	environment.ambient_light_energy = 0.55
	var world := WorldEnvironment.new()
	world.environment = environment
	view.add_child(world)
	# The plush faces -Z (house_characters.gd::worker turns -Z toward its facing).
	var head := _bounds(plush.get_node_or_null("Head") if plush.has_node("Head") else plush)
	var centre := head.get_center()
	var reach := maxf(head.size.x, head.size.y) * 0.62 + 0.05
	var camera := Camera3D.new()
	camera.fov = 40.0
	view.add_child(camera)
	camera.position = centre + Vector3(0, reach * 0.12, -reach / tan(deg_to_rad(camera.fov / 2.0)))
	camera.look_at(centre, Vector3.UP)
	var key := DirectionalLight3D.new()
	view.add_child(key)
	key.look_at_from_position(centre + Vector3(1.0, 1.6, -2.0), centre, Vector3.UP)
	key.light_energy = 1.1
	return view

## World-space box of the visible meshes under `node` (tails excluded).
func _bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh_instance in node.find_children("*", "MeshInstance3D", true, false):
		if mesh_instance.mesh == null or "Tail" in str(mesh_instance.get_path()):
			continue
		var part: AABB = mesh_instance.global_transform * mesh_instance.mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	if first:
		box = AABB(Vector3(-0.3, 0.5, -0.3), Vector3(0.6, 0.6, 0.6))
	return box
