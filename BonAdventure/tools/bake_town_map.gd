extends SceneTree
## Bakes the town map (wayfinding, 18 Nov 2026; docs/guides/MINIGAMES.md#town-map-and-guide-arrow):
## renders the whole town once from straight above (orthographic, noon, no fog) into
## assets/maps/town_map.png and writes data/town_map.json: the picture's frame in town
## coordinates and where each building's entrance and each minigame is. The game only shows the
## picture and these points (scripts/ui/town_map_panel.gd, guide_arrow.gd); nothing is drawn from
## the meshes at play time. Run again after a building, an entrance or a minigame NPC moves.
## Needs a window (it renders). Writes no saves with an isolated HOME (README "Checks"):
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none VT_NEARBY=0 godot --path . --resolution 1100x800 --script res://tools/bake_town_map.gd
## then `godot --headless --path . --import` so the game sees the new picture (or open the editor).
const ModularTown := preload("res://scripts/world/modular_town.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const IMAGE := "res://assets/maps/town_map.png"
const DATA := "res://data/town_map.json"
## The picture's longer side in pixels (loaded only while the map is open).
const PIXELS := 1400
## Town units of land and sea shown around the buildings' boxes (data/nearby_units.json).
const MARGIN := 34.0

## Each place on the map: its places.* phrase (the name shown) and its Main.ENTRANCES key. The
## restaurants unit is one place (three restaurants share one front).
const PLACES := [
	["home", "home"], ["supermarket", "supermarket"], ["library", "library"], ["bank", "bank"],
	["police_station", "police"], ["restaurants", "restaurants"], ["taqueria", "taqueria"],
	["airport", "airport"], ["control_tower", "tower"], ["warehouse", "warehouse"],
	["farm_barn", "barn"], ["school", "school"], ["hospital", "hospital"],
	["sports_store", "sports"], ["clothing_store", "clothing"], ["electronics_store", "electronics"],
	["furniture_store", "furniture"], ["bakery_cafe", "bakery"], ["chapel", "chapel"],
	["playground", "playground"], ["mystery_house", "mystery"],
]

var main: Node

func _initialize() -> void:
	run.call_deferred()

func settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func town2(town: Node3D, world: Vector3) -> Array:
	var p := town.to_local(world)
	return [snappedf(p.x, 0.1), snappedf(p.z, 0.1)]

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("bake_town_map.gd renders: run it with a window (no --headless)")
		quit(1)
		return
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await settle(10)
	var town: Node3D = main.apartment
	if not town.get_meta("reference_west_positive_x", false):
		push_error("town is not +X west: the map frame below assumes it")
	main.player.visible = false
	main.player.set_physics_process(false)
	main.hud.hide()
	main.day_night.pause()
	main.day_night.set_time(12 * 60)
	main.day_night.set_view_distance(0.0)
	if main.day_night.environment != null:
		main.day_night.environment.fog_enabled = false
	# No sun disc or clouds over the picture.
	if main.day_night.sky_disc != null:
		main.day_night.sky_disc.visible = false
	for pattern in main.day_night.CLOUD_PATTERNS:
		for cloud in town.find_children(pattern, "Node3D", true, false):
			cloud.visible = false
	# Everything drawn whatever its distance (this run only; nothing is saved).
	for node in town.find_children("*", "GeometryInstance3D", true, false):
		(node as GeometryInstance3D).visibility_range_end = 0.0
	# The frame: every unit's boxes plus a margin, north (+Z) up, west (+X) left.
	var boxes: Dictionary = preload("res://scripts/world/nearby_units.gd").data().get("boxes", {})
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for key in boxes:
		for b in boxes[key]:
			low = low.min(Vector2(b[0], b[1]))
			high = high.max(Vector2(b[2], b[3]))
	low -= Vector2(MARGIN, MARGIN)
	high += Vector2(MARGIN, MARGIN)
	var span := high - low
	var pixels := Vector2i(PIXELS, roundi(PIXELS * span.y / span.x)) if span.x >= span.y else Vector2i(roundi(PIXELS * span.x / span.y), PIXELS)
	var centre := (low + high) * 0.5
	# Render.
	var view := SubViewport.new()
	view.size = pixels
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.msaa_3d = Viewport.MSAA_4X
	root.add_child(view)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	view.add_child(camera)
	var scale := town.global_basis.get_scale().x
	camera.size = span.y * scale
	camera.near = 1.0
	camera.far = 900.0
	# Screen right = east (town -X), screen up = north (town +Z), looking straight down.
	var east := (town.global_basis * Vector3(-1, 0, 0)).normalized()
	var north := (town.global_basis * Vector3(0, 0, 1)).normalized()
	camera.global_transform = Transform3D(Basis(east, north, Vector3.UP), town.to_global(Vector3(centre.x, 0, centre.y)) + Vector3.UP * 400.0)
	camera.current = true
	await settle(12)
	await RenderingServer.frame_post_draw
	var image := view.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	image.save_png(ProjectSettings.globalize_path(IMAGE))
	# Places and games.
	var places := []
	for entry in PLACES:
		var e: Array = main.ENTRANCES[entry[1]]
		var site := ModularTown.building(town, e[0], e[1], e[2])
		if site == null:
			push_error("no building for " + str(entry[1]))
			continue
		places.append({"name": entry[0], "unit": e[0], "at": town2(town, site.to_global(e[3])), "door": town2(town, site.to_global(e[4]))})
	var games := {}
	var board = Board.shared()
	for id in board.activities.keys():
		var session: Object = board.session(id)
		var node: Node3D = null
		if session != null:
			var host = session.get("host")
			if host != null and host.get("npc") is Node3D:
				node = host.npc
		if node == null and str(id) == "electrical_box":
			# The first box (outside the home's garage); the game opens the nearest one.
			var found := main.get_tree().get_nodes_in_group(preload("res://scripts/world/electrical_box.gd").GROUP)
			if not found.is_empty():
				node = found[0]
		if node == null and str(id) == "radar_patrol":
			var e: Array = main.ENTRANCES["tower"]
			var site := ModularTown.building(town, e[0], e[1], e[2])
			if site != null:
				games[id] = town2(town, site.to_global(e[4]))
			continue
		if node == null:
			push_error("no place found for game " + str(id))
			continue
		games[id] = town2(town, node.global_position)
	var data := {
		"_comment": "Written by tools/bake_town_map.gd (do not edit by hand). frame: the picture assets/maps/town_map.png covers town x from west (left edge) to east and z from north (top edge) to south; places: each building's standing point outside its entrance (at) and its door, in town coordinates (Main's Apartment frame, +X west / +Z north); games: where each minigame's NPC (or box) stands. Used by scripts/ui/town_map_panel.gd and guide_arrow.gd.",
		"frame": {"west": snappedf(high.x, 0.1), "east": snappedf(low.x, 0.1), "north": snappedf(high.y, 0.1), "south": snappedf(low.y, 0.1), "pixels": [pixels.x, pixels.y]},
		"places": places,
		"games": games,
	}
	var file := FileAccess.open(DATA, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t") + "\n")
	file.close()
	print("TOWN MAP %dx%d px, %d places, %d games" % [pixels.x, pixels.y, places.size(), games.size()])
	quit(0)
