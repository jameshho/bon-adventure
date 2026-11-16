extends SceneTree
## 9 Nov 2026 interiors polish: the same views of the sports store, furniture store, Pizza and
## Burger, police station and hospital (reference), before and after.
## HOME=<scratch> VT_FOCUS="sports, furniture, restaurants, police, hospital" VT_SPAWN=none \
##   godot --path . --resolution 1280x800 --script res://docs/evidence/interiors-polish-20261109/capture.gd -- <before|after> [unit ...]
## Writes <prefix>-<unit>-<view>.png into this folder (overwrites them). Reads no saves.
## Views are in each building's own frame (town units, the frame's scale 1.3 is applied):
## [name, camera, target, fov (perspective) or size (orthographic top), top view?]
const VIEWS := {
	"sports": ["Buildings/SportsStore", [
		["entrance", Vector3(0, 2.0, -11.4), Vector3(0, 1.0, 6), 78.0, false],
		["left", Vector3(-2.5, 2.3, -10.5), Vector3(5.5, .9, 1), 78.0, false],
		["right", Vector3(2.5, 2.3, -10.5), Vector3(-5.5, .9, 1), 78.0, false],
		["rear", Vector3(0, 2.3, 0), Vector3(0, 1.1, 12), 80.0, false],
		["back-to-door", Vector3(0, 2.6, 10.5), Vector3(0, .9, -8), 80.0, false],
		["close-balls", Vector3(-1.2, 2.0, -6.8), Vector3(-3.2, 1.25, -6.8), 55.0, false],
		["close-fitness", Vector3(1.0, 2.0, 1.2), Vector3(4.2, 1.1, 1.8), 60.0, false],
		["close-bike", Vector3(2.8, 1.8, -9.6), Vector3(6.0, .8, -10.0), 60.0, false],
		["top", Vector3(0, 40, 0), Vector3(0, 0, 0), 27.0, true],
	]],
	"furniture": ["Buildings/FurnitureStore", [
		["entrance", Vector3(0, 2.0, -13.8), Vector3(0, 1.0, 4), 78.0, false],
		["living", Vector3(-2.5, 2.0, -13), Vector3(-8, 1.0, -8), 80.0, false],
		["dining", Vector3(2.5, 2.0, -13), Vector3(8, 1.0, -9), 80.0, false],
		["office", Vector3(3, 2.0, -4.5), Vector3(9, 1.0, -1), 80.0, false],
		["lighting", Vector3(2.5, 2.0, 3), Vector3(8, 1.4, 8), 85.0, false],
		["bedroom", Vector3(-5.8, 2.2, 3.2), Vector3(-10.5, .8, .5), 85.0, false],
		["back-to-door", Vector3(0, 2.4, 10), Vector3(0, 1.0, -12), 80.0, false],
		["close-sofa", Vector3(-3.3, 1.9, -10.6), Vector3(-6.0, .7, -9.3), 60.0, false],
		["close-bed", Vector3(-7.4, 2.1, -1.6), Vector3(-10.6, .7, .5), 60.0, false],
		["close-wardrobe", Vector3(-8.6, 1.9, 2.4), Vector3(-11.5, 1.1, 3.85), 60.0, false],
		["close-dining-side", Vector3(11.2, 1.6, -10.2), Vector3(8.3, .6, -10.2), 60.0, false],
		["top", Vector3(0, 40, -1.5), Vector3(0, 0, -1.5), 28.0, true],
	]],
	"restaurants": ["Restaurants/Burger", [
		["entrance", Vector3(3, 2.0, -7.3), Vector3(-1, 1.0, 2), 80.0, false],
		["dining-east", Vector3(1, 2.2, -6.8), Vector3(13, .9, -2), 78.0, false],
		["dining-west", Vector3(5, 2.2, -6.8), Vector3(-11, .9, -2), 78.0, false],
		["counter", Vector3(-6, 2.0, -3.5), Vector3(-7, 1.4, 2.5), 75.0, false],
		["kitchen", Vector3(-2.2, 2.3, 3.0), Vector3(-11, .9, 8), 80.0, false],
		["close-table", Vector3(-9.6, 1.8, -6.3), Vector3(-11, .85, -5), 55.0, false],
		["close-booth", Vector3(11.4, 1.9, -3.2), Vector3(14.0, .9, -2.0), 60.0, false],
		["close-fridge", Vector3(0, 1.6, -1.2), Vector3(0, 1.1, 1.4), 60.0, false],
		["top", Vector3(0, 40, 1), Vector3(0, 0, 1), 32.0, true],
	]],
	"police": ["RelocatedSites/Police", [
		["entrance", Vector3(43, 2.2, 38.3), Vector3(43, 1.2, 52), 80.0, false],
		["lobby-right", Vector3(45.5, 2.2, 38.6), Vector3(35, 1.2, 47), 80.0, false],
		["lobby-left", Vector3(40.5, 2.2, 38.6), Vector3(48, 1.2, 46), 80.0, false],
		["evidence", Vector3(46.5, 2.0, 40), Vector3(52.5, 1.0, 44), 80.0, false],
		["close-evidence-shelf", Vector3(49.6, 1.8, 42.3), Vector3(52.6, 1.3, 42.3), 60.0, false],
		["top", Vector3(43, 40, 48.5), Vector3(43, 0, 48.5), 26.0, true],
	]],
	"hospital": ["Buildings/Hospital", [
		["entrance", Vector3(0, 2.0, -11.5), Vector3(0, 1.2, 2), 80.0, false],
		["reception", Vector3(2.0, 2.2, -6.5), Vector3(8, 1.0, -8.5), 80.0, false],
		["waiting", Vector3(-2.0, 2.2, -6.5), Vector3(-8, 1.0, -8.5), 80.0, false],
		["floor2-room", Vector3(1.5, 7.6, -6.5), Vector3(8, 6.4, -9), 80.0, false],
		["close-soccer-ball", "Floor1/Room4/SoccerBall", Vector3(.9, .7, -.9), 50.0, false],
	]],
	# Shared prefab check only (sneakers), not part of the polish.
	"clothing": ["Buildings/ClothingStore", [
		["close-sneakers", "LearningDisplays/Sneakers", Vector3(0, .9, -1.4), 50.0, false],
	]],
}
const HIDE_FOR_TOP := ["roof", "ceiling", "parapet", "awning", "canopy", "ridge"]

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var args := Array(OS.get_cmdline_user_args())
	var prefix: String = args[0] if args.size() > 0 else "after"
	var units: Array = args.slice(1)
	if units.is_empty(): units = VIEWS.keys()
	var out := "res://docs/evidence/interiors-polish-20261109"
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 4: await process_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.player.visible = false
	game.hud.hide()
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.far = 400.0
	for unit in units:
		var spec: Array = VIEWS[unit]
		var top: Node3D = game.apartment.get_node_or_null(spec[0])
		if top == null:
			print("CAPTURE %s missing (dev_focus?)" % unit); continue
		var hidden: Array = []
		for view in spec[1]:
			var is_top: bool = view[4]
			if is_top:
				for n in [top] + top.find_children("*", "Node3D", true, false):
					var nm := String(n.name).to_lower()
					if n is VisualInstance3D or n.get_child_count() > 0:
						for word in HIDE_FOR_TOP:
							if nm.contains(word) and n.visible:
								n.visible = false; hidden.append(n); break
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL if is_top else Camera3D.PROJECTION_PERSPECTIVE
			camera.size = float(view[3]) * 1.3
			camera.fov = float(view[3])
			var up := Vector3.UP
			if is_top: up = (top.global_basis * Vector3(0, 0, 1)).normalized()
			if view[1] is String:
				# A close-up of one node: the camera sits at a world offset from its centre.
				var target: Node3D = top.get_node(view[1])
				var aim := target.global_position + Vector3(0, .15, 0)
				camera.global_position = aim + view[2]
				camera.look_at(aim, up)
			else:
				camera.global_position = top.to_global(view[1])
				camera.look_at(top.to_global(view[2]), up)
			game.player.global_position = camera.global_position - Vector3(0, 1.4, 0)
			for i in 8: await process_frame
			await RenderingServer.frame_post_draw
			var file := "%s/%s-%s-%s.png" % [out, prefix, unit, view[0]]
			root.get_texture().get_image().save_png(file)
			print("CAPTURE ", file)
			if is_top:
				for n in hidden: n.visible = true
				hidden.clear()
	print("CAPTURE done")
	quit()
