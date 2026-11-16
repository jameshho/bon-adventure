extends SceneTree
## World signs readability (16 Nov 2026): inventory and rendered views of the supermarket signs.
## Graphics required (the inventory also runs headless with -- inventory):
##   HOME=<scratch>/home VT_FOCUS=supermarket VT_SPAWN=none godot --path . --resolution 1280x720 \
##       --script res://docs/evidence/world-signs-20261116/capture.gd -- <prefix> [low] [web]
## Writes <prefix>-<view>.png and <prefix>-inventory.txt into this folder only.
##   low: the LOW graphics tier as the game applies it (MSAA off). web: also 3D at 0.8 of the
##   window's pixels, as the web build's LOW tier renders.
## Each inventory line: node, text, font_size, pixel_size, outline, letter height (font_size x
## pixel_size, metres, the em size; capitals are about 0.7 of it), billboard, and the on-screen
## capital height in pixels from the entrance view point (the player's eye) at this window height.
const FOLDER := "res://docs/evidence/world-signs-20261116"

func _initialize(): run.call_deferred()

func run():
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[0] if args.size() > 0 else "before"
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(30): await process_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.hud.hide()
	var culling = game.get("render_culling")
	if "low" in args and culling != null:
		culling.apply_graphics("low")
	elif culling != null:
		culling.apply_graphics("high")
	if "web" in args:
		root.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		root.scaling_3d_scale = 0.8
	var market: Node3D = game.apartment.get_node("RelocatedSites/Supermarket")
	var town: Node3D = game.apartment
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.far = 900.0
	camera.fov = 70.0
	var screen_h: float = root.get_visible_rect().size.y
	# [name, eye, target, fov] market-local (door on the z=34.25 front wall, +X left on entering).
	var views := [
		["front-near", Vector3(-33, 1.6, 26.0), Vector3(-33, 4.0, 34.25), 70.0],
		["front-far", Vector3(-33, 1.6, 8.0), Vector3(-33, 4.0, 34.25), 70.0],
		["entrance", Vector3(-33, 1.6, 35.5), Vector3(-33, 2.6, 50), 70.0],
		["left-departments", Vector3(-33, 1.6, 40.0), Vector3(-22, 2.6, 50), 70.0],
		["right-departments", Vector3(-33, 1.6, 40.0), Vector3(-44, 2.6, 52), 70.0],
		["rear", Vector3(-33, 1.6, 46.0), Vector3(-33, 2.8, 59.5), 70.0],
	]
	var eye: Vector3 = market.to_global(Vector3(-33, 1.6, 35.5))
	var lines: Array = ["# Supermarket Label3D signs, %s, window height %d px, eye at the entrance (1.6 m)" % [prefix, screen_h]]
	lines.append("node | text | font_size | pixel_size | outline | em (m) | billboard | cap px at entrance")
	var labels: Array = []
	for part in ["RelocatedSites/Supermarket", "Buildings/MarketDisplays", "Map facades/SUPERMARKET"]:
		if town.has_node(part):
			labels.append_array(town.get_node(part).find_children("*", "Label3D", true, false))
	var meshes: Array = []
	for part in ["RelocatedSites/Supermarket", "Buildings/MarketDisplays", "Map facades/SUPERMARKET"]:
		if town.has_node(part):
			meshes.append_array(town.get_node(part).find_children("*", "MeshInstance3D", true, false))
	for label: Label3D in labels:
		var em := label.font_size * label.pixel_size * label.global_transform.basis.get_scale().y
		var dist := eye.distance_to(label.global_position)
		var px := 0.7 * em / (2.0 * dist * tan(deg_to_rad(camera.fov) / 2.0)) * screen_h
		lines.append("%s | %s | %d | %.4f | %d | %.3f | %d | %.1f px at %.1f m | colour %s outline %s | board %s" % [
			str(town.get_path_to(label)), label.text.replace("\n", " / "), label.font_size,
			label.pixel_size, label.outline_size, em, label.billboard, px, dist,
			label.modulate.to_html(false), label.outline_modulate.to_html(false), _board(label, meshes)])
	# Whole-town summary: how many labels per em size band.
	var bands := {}
	for label: Label3D in town.find_children("*", "Label3D", true, false):
		var em := label.font_size * label.pixel_size * label.global_transform.basis.get_scale().y
		var band := "<0.10" if em < 0.1 else ("0.10-0.20" if em < 0.2 else ("0.20-0.40" if em < 0.4 else ">=0.40"))
		bands[band] = int(bands.get(band, 0)) + 1
	lines.append("")
	lines.append("Town Label3D em bands (m): %s" % JSON.stringify(bands))
	var file := FileAccess.open(FOLDER + "/" + prefix + "-inventory.txt", FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("\n".join(lines))
	if DisplayServer.get_name() == "headless" or "inventory" in args:
		quit()
		return
	for spec in views:
		camera.fov = spec[3]
		camera.global_position = market.to_global(spec[1])
		camera.look_at(market.to_global(spec[2]))
		for i in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(FOLDER + "/" + prefix + "-" + spec[0] + ".png")
	print("WORLD SIGNS CAPTURE done")
	quit()

## The nearest mesh just behind the label (within 0.4 m of its plane, containing its centre):
## "name WxH m colour".
func _board(label: Label3D, meshes: Array) -> String:
	var best := ""
	var best_d := 0.4
	var at := label.global_position
	for mesh: MeshInstance3D in meshes:
		if mesh.mesh == null:
			continue
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		var grown := box.grow(0.4)
		if not grown.has_point(at):
			continue
		var inside := box.grow(0.02)
		var d := 0.0 if inside.has_point(at) else 0.39
		var size := box.size
		if size.length() > 12.0:
			continue
		if best == "" or d < best_d or (d == best_d and size.length() < 4.0):
			best_d = d
			var colour := ""
			var mat = mesh.get_active_material(0)
			if mat is StandardMaterial3D:
				colour = (mat as StandardMaterial3D).albedo_color.to_html(false)
			best = "%s %.2fx%.2fx%.2f %s" % [mesh.name, size.x, size.y, size.z, colour]
	return best
