extends SceneTree
## Building parts vanishing at a distance (user report, 25 Nov 2026: "the house looks broken when
## not rendered properly ... a common issue across buildings"). Loads the town as the game does
## (render trim and indoor visibility included), then views each unit's building from four sides
## at street distance and lists the unit's meshes that the render trim hides nearer than SHORT_LIMIT.
## Needs a window; writes <tag>-<unit>.png sheets into this folder (overwrites them).
##   HOME=<scratch>/home VT_FOCUS=home VT_SPAWN=none godot --path . --resolution 1200x700 \
##     --script res://docs/evidence/building-ranges-20261125/capture.gd -- tag=before [units=home] [unranged]
## `unranged`: clear every short range in the units' boxes first (what the building looks like
## with nothing hidden), for comparison.
const ModularTown := preload("res://scripts/world/modular_town.gd")
const NearbyUnits := preload("res://scripts/world/nearby_units.gd")
const FOLDER := "res://docs/evidence/building-ranges-20261125/"
const TILE := Vector2i(600, 350)
const SHORT_LIMIT := 45.0
## Camera distance from the building box centre (town units), and its sideways shift.
const DISTANCE := 42.0
const SIDE := 16.0

var game
var camera: Camera3D
var town: Node3D
var args := {}

func _initialize(): run.call_deferred()

func frame_image() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

## The unit's footprint (town XZ) from data/nearby_units.json, as one rectangle.
func unit_rect(unit: String) -> Rect2:
	var rect := Rect2()
	var first := true
	for b in NearbyUnits.data().boxes.get(unit, []):
		var r := Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1])
		rect = r if first else rect.merge(r)
		first = false
	return rect

func in_rect(node: GeometryInstance3D, rect: Rect2) -> bool:
	# Box centre, not origin: a static batch sits at the town origin with its pieces in the cell.
	var p := town.to_local((node.global_transform * node.get_aabb()).get_center())
	return rect.grow(1.0).has_point(Vector2(p.x, p.z))

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var tag: String = args.get("tag", "view")
	var units: Array = Array(args.get("units", "home").split(","))
	game = load("res://scenes/main.tscn").instantiate()
	# town_ready can be emitted inside add_child (no loading screen outside the app).
	var ready_flag := [false]
	game.town_ready.connect(func(): ready_flag[0] = true)
	root.add_child(game)
	while not ready_flag[0]:
		await process_frame
	town = game.apartment
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
	for unit in units:
		var rect := unit_rect(unit)
		report(unit, rect)
		if args.has("unranged"):
			for node: GeometryInstance3D in town.find_children("*", "GeometryInstance3D", true, false):
				if node.visibility_range_end > 0.0 and node.visibility_range_end <= SHORT_LIMIT and in_rect(node, rect):
					node.visibility_range_end = 0.0
		var centre := rect.get_center()
		var target := Vector3(centre.x, 3.0, centre.y)
		var shots: Array[Image] = []
		for dir in [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 0, -1)]:
			var eye: Vector3 = target + dir * float(args.get("distance", DISTANCE)) + Vector3(0, -1.2, 0) + dir.cross(Vector3.UP) * SIDE
			camera.global_position = town.to_global(eye)
			camera.look_at(town.to_global(target), Vector3.UP)
			await settle(6)
			shots.append(await frame_image())
		var out := Image.create(TILE.x * 2, TILE.y * 2, false, Image.FORMAT_RGB8)
		for i in range(shots.size()):
			var img := shots[i]
			img.convert(Image.FORMAT_RGB8)
			img.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
			out.blit_rect(img, Rect2i(Vector2i.ZERO, TILE), Vector2i((i % 2) * TILE.x, (i / 2) * TILE.y))
		out.save_png(ProjectSettings.globalize_path(FOLDER + "%s-%s.png" % [tag, unit]))
		print("RANGES %s %s sheet written" % [tag, unit])
	quit(0)

## Counts the unit's visible meshes hidden nearer than SHORT_LIMIT, by range, and names the
## biggest of them (the ones a viewer notices).
func report(unit: String, rect: Rect2) -> void:
	var by_range := {}
	var big := []
	for node: GeometryInstance3D in town.find_children("*", "GeometryInstance3D", true, false):
		var r := node.visibility_range_end
		# Merged originals are hidden; their batch carries the same range.
		var drawn := node.is_visible_in_tree() or node.has_meta("render_batch")
		if r <= 0.0 or r > SHORT_LIMIT or not drawn or node is MultiMeshInstance3D or not in_rect(node, rect):
			continue
		by_range[snappedf(r, 0.5)] = by_range.get(snappedf(r, 0.5), 0) + 1
		var box := node.global_transform * node.get_aabb()
		big.append([box.get_longest_axis_size(), str(town.get_path_to(node)), r])
	big.sort_custom(func(a, b): return a[0] > b[0])
	print("RANGES %s: short-ranged visible meshes by range %s" % [unit, by_range])
	for i in range(mini(60, big.size())):
		print("RANGES %s   %.2f m  range %.1f  %s" % [unit, big[i][0], big[i][2], big[i][1]])
