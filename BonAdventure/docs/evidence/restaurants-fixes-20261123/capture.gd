extends SceneTree
## Restaurants fixes (23 Nov 2026): the three facade signs, the Pizza and Burger entrance (outside
## and inside) and the taquería waiter, as the game draws them at noon. Needs a window; writes
## <prefix>-<view>.png into this folder (overwrites them).
##   HOME=<scratch>/home VT_FOCUS=restaurants VT_SPAWN=none godot --path . --resolution 1200x800 \
##     --script res://docs/evidence/restaurants-fixes-20261123/capture.gd -- prefix=after
const FOLDER := "res://docs/evidence/restaurants-fixes-20261123/"

var game
var camera: Camera3D
var args := {}

func _initialize(): run.call_deferred()

func settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func shoot(file: String, from: Vector3, at: Vector3) -> void:
	camera.global_position = from
	camera.look_at(at, Vector3.UP)
	await settle(4)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(FOLDER + "%s-%s.png" % [args.get("prefix", "view"), file]))
	print("CAPTURE ", file)

## A view square onto the front of `node` (front = the side its child label faces), `dist` away.
func front_view(file: String, sign_path: String, label_path: String, dist: float, up := 0.0) -> void:
	var town: Node3D = game.apartment
	var face := town.get_node_or_null(sign_path) as Node3D
	var label := town.get_node_or_null(label_path) as Node3D
	if face == null or label == null:
		print("MISSING ", sign_path)
		return
	var c := face.global_position
	var n := (label.global_position - c)
	n.y = 0
	n = n.normalized()
	await shoot(file, c + n * dist + Vector3(0, up, 0), c)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle(5)
	game.player.set_physics_process(false)
	game.player.visible = false
	game.interaction.set_physics_process(false)
	camera = Camera3D.new()
	camera.near = 0.05
	camera.fov = 58.0
	game.add_child(camera)
	camera.current = true
	game.day_night.pause()
	game.day_night.set_time(12 * 60)
	game.hud.hide()
	var town: Node3D = game.apartment
	await front_view("sign-pizza-burger", "Map facades/PIZZA AND BURGER/Sign face", "Map facades/PIZZA AND BURGER/PIZZA AND BURGER lettering", 14.0, -1.0)
	await front_view("sign-taqueria", "Map facades/TAQUERÍA/Sign face", "Map facades/TAQUERÍA/Facade lettering", 12.0, -1.0)
	# Pizza and Burger entrance: the facade door from the street, then from inside the shop.
	# The old facade door's head before the fix, the shared door after it.
	var head := town.get_node_or_null("Map facades/PIZZA AND BURGER/Door frame head") as Node3D
	if head == null:
		head = town.find_child("Pizza and Burger entrance", true, false) as Node3D
	var sign := town.get_node_or_null("Map facades/PIZZA AND BURGER/Sign face") as Node3D
	if head != null and sign != null:
		var lab := town.get_node("Map facades/PIZZA AND BURGER/PIZZA AND BURGER lettering") as Node3D
		var n := lab.global_position - sign.global_position
		n.y = 0
		n = n.normalized()
		var door := head.global_position - Vector3(0, head.global_position.y - 1.9, 0)
		var side := n.cross(Vector3.UP).normalized()
		await shoot("pizza-door-street", door + n * 7.0 + side * 2.0 + Vector3(0, .4, 0), door)
		await shoot("pizza-door-inside", door - n * 6.0 + Vector3(0, .5, 0), door)
		var entrance := town.find_child("Pizza and Burger entrance", true, false)
		if entrance != null:
			var leaves := entrance.find_children("Pizza and Burger entrance door*", "Node3D", true, false)
			print("DOOR leaves ", leaves.size(), " registered ", leaves.filter(func(l): return game.doors.has(l)).size())
			if not leaves.is_empty():
				game.DoorAnimator.toggle(game, leaves[0])
				await settle(90)
				await shoot("pizza-door-open", door + n * 5.0 + side * 1.5 + Vector3(0, .6, 0), door - n * 2.0)
	# The taquería waiter, from the dining room.
	var cat := town.get_node_or_null("Restaurants/Cafe/Taqueria/CatWaiter") as Node3D
	if cat != null:
		var p := cat.global_position
		var fwd := -cat.global_basis.z
		fwd.y = 0
		fwd = fwd.normalized()
		await shoot("taqueria-waiter", p + fwd * 3.2 + Vector3(0, 1.6, 0), p + Vector3(0, .9, 0))
		var side2 := fwd.cross(Vector3.UP).normalized()
		await shoot("taqueria-waiter-side", p + side2 * 3.0 + fwd * 1.0 + Vector3(0, 1.5, 0), p + Vector3(0, .9, 0))
	quit()
