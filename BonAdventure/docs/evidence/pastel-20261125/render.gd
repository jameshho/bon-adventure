extends SceneTree
## Before/after views for the pastel trial (P3-22 palette snap, P3-23 ground tones; decision D14).
## Loads the town as the game does at noon, views each unit's building from four sides (the same
## lot boxes as docs/evidence/building-ranges-20261125/capture.gd) plus views of the ground, and writes <tag>-<unit>.png / <tag>-ground.png into this folder (overwrites them).
## `ground=pastel` applies the proposed ground tones (PASTEL_GROUND) to the shared shader
## materials in memory before the shots; building colours come from the saved (baked) scenes.
## Building views: four diagonal corners at a distance from the lot's size; ground views: a raised
## look over each unit's lot (grass, paving, road), so the same spots work for any unit.
## Needs a window; uses Main, which saves progress: run with an isolated HOME (README).
##   HOME=<scratch>/home VT_FOCUS=library,school VT_SPAWN=none godot --path . --audio-driver Dummy --resolution 1200x700 \
##     --script res://docs/evidence/pastel-20261125/render.gd -- tag=before units=library,school
const NearbyUnits := preload("res://scripts/world/nearby_units.gd")
const FOLDER := "res://docs/evidence/pastel-20261125/"
const TILE := Vector2i(600, 350)
## Proposed ground tones (P3-23): shader file -> old base_color (or "*") -> {parameter: colour}.
## Road and paving materials are stored in base.scn (one per old colour), grass and sand are files.
const PASTEL_GROUND := {
	"grass.gdshader": {"*": {"base_color": Color("8cbf6a"), "lush_color": Color("74ad57"), "dry_color": Color("b5cc78")}},
	"sand.gdshader": {"*": {"base_color": Color("e3c993"), "light_color": Color("efdbb0"), "wet_color": Color("c4a676"), "shade_color": Color("d5b984"), "pebble_color": Color("bcae98")}},
	"road.gdshader": {"586b6e": {"base_color": Color("66767d")}, "65777a": {"base_color": Color("72838a")}},
	"paving.gdshader": {"d2cbb7": {"base_color": Color("e6dcc6")}, "a8aba8": {"base_color": Color("c4c2bb")}, "dbc8a6": {"base_color": Color("ead9b8")}},
}

var game
var camera: Camera3D
var town: Node3D
var args := {}

func _initialize(): run.call_deferred()

func frame_image() -> Image:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
	return img

func settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func unit_rect(unit: String) -> Rect2:
	var rect := Rect2()
	var first := true
	for b in NearbyUnits.data().boxes.get(unit, []):
		var r := Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1])
		rect = r if first else rect.merge(r)
		first = false
	return rect

func shoot(eye: Vector3, target: Vector3) -> Image:
	camera.global_position = town.to_global(eye)
	camera.look_at(town.to_global(target), Vector3.UP)
	await settle(6)
	return await frame_image()

func sheet(shots: Array, file: String) -> void:
	var out := Image.create(TILE.x * 2, TILE.y * ceili(shots.size() / 2.0), false, Image.FORMAT_RGB8)
	for i in range(shots.size()):
		out.blit_rect(shots[i], Rect2i(Vector2i.ZERO, TILE), Vector2i((i % 2) * TILE.x, (i / 2) * TILE.y))
	out.save_png(ProjectSettings.globalize_path(FOLDER + file))
	print("PASTEL wrote ", file)

## Applies PASTEL_GROUND to every ground material the loaded town draws (each shared material once).
func pastel_ground() -> void:
	var done := {}
	for node: GeometryInstance3D in town.find_children("*", "GeometryInstance3D", true, false):
		var materials := [node.material_override]
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			for surface in (node as MeshInstance3D).mesh.get_surface_count():
				materials.append((node as MeshInstance3D).get_active_material(surface))
		for material in materials:
			if not material is ShaderMaterial or done.has(material) or material.shader == null:
				continue
			done[material] = true
			var table: Dictionary = PASTEL_GROUND.get(material.shader.resource_path.get_file(), {})
			var old = material.get_shader_parameter("base_color")
			var key: String = old.to_html(false) if old is Color else ""
			var params: Dictionary = table.get(key, table.get("*", {}))
			for param in params:
				material.set_shader_parameter(param, params[param])
			if not params.is_empty():
				print("PASTEL ground: %s %s" % [material.shader.resource_path.get_file(), key])

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var tag: String = args.get("tag", "view")
	game = load("res://scenes/main.tscn").instantiate()
	var ready_flag := [false]
	game.town_ready.connect(func(): ready_flag[0] = true)
	root.add_child(game)
	while not ready_flag[0]:
		await process_frame
	town = game.apartment
	if args.get("ground", "") == "pastel":
		pastel_ground()
	game.player.set_physics_process(false)
	game.player.visible = false
	game.interaction.set_physics_process(false)
	camera = Camera3D.new()
	camera.near = 0.05
	camera.far = game.player.camera.far
	camera.fov = game.player.camera.fov
	game.add_child(camera)
	camera.current = true
	game.day_night.pause()
	game.day_night.set_time(12 * 60)
	game.hud.hide()
	await settle(10)
	var ground := []
	for unit in Array(args.get("units", "").split(",", false)):
		var rect := unit_rect(unit)
		var centre := Vector3(rect.get_center().x, 0.0, rect.get_center().y)
		var reach := rect.size.length() * 0.5 + 10.0
		var shots := []
		for corner in [Vector3(1, 0, 1), Vector3(-1, 0, 1), Vector3(-1, 0, -1), Vector3(1, 0, -1)]:
			shots.append(await shoot(centre + corner.normalized() * reach + Vector3(0, 4.0, 0), centre + Vector3(0, 3.0, 0)))
		# Inside: from the lot's centre at eye height towards two corners (the interior colours).
		for corner in [Vector3(1, 0, 1), Vector3(-1, 0, -1)]:
			shots.append(await shoot(centre + Vector3(0, 1.7, 0) - corner * 1.5, centre + corner * 8.0 + Vector3(0, 1.2, 0)))
		sheet(shots, "%s-%s.png" % [tag, unit])
		ground.append(await shoot(centre + Vector3(1, 0, 1).normalized() * reach * 1.6 + Vector3(0, reach * 0.9, 0), centre))
		ground.append(await shoot(centre + Vector3(-1, 0, -1).normalized() * reach * 1.6 + Vector3(0, reach * 0.9, 0), centre))
	sheet(ground, "%s-ground.png" % tag)
	quit(0)
