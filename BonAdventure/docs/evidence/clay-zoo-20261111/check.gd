extends SceneTree
## Clay animals in the zoo (base step `clay_animals_roam`, 11 Nov 2026): every ParkZoo wanderer
## is configured, has a word with a study card and a fitted pick area, and roams for two
## simulated minutes inside its habitat and home range. With `views` it also saves rendered
## views of the wild-animal lawn and the meadow dog, and a close view of each animal that replaced
## an old one, to this folder (PNG only).
## Run with an isolated HOME (README), VT_FOCUS=all VT_SPAWN=none, and a time limit:
##   godot --path . --resolution 1200x800 --script res://docs/evidence/clay-zoo-20261111/check.gd [-- views]
const OUT := "res://docs/evidence/clay-zoo-20261111/"
const CLAY := ["Lion", "Giraffe", "Bear", "Elephant", "Cow", "Pig", "Duck", "Dog", "Panda", "Red Panda",
	"Gorilla", "Deer", "Kangaroo", "Rhinoceros", "Zebra", "Bear Cub", "Flamingo"]
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + label)

func shot() -> Image:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	root.size = Vector2i(1200, 800)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(40): await process_frame
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	var zoo: Node3D = game.apartment.get_node("ParkZoo")
	for name in ["GiraffeClayDisplay", "BlackBearAdultClayDisplay", "BlackBearCubClayDisplay", "PandaClayDisplay", "DuckClayDisplay"]:
		check(not zoo.has_node(name), "static display gone " + name)
	for name in CLAY:
		var animal: Node3D = zoo.get_node_or_null(name)
		check(animal != null and animal.get("_configured") == true, "clay animal wanders " + name)
		if animal == null: continue
		check(animal.get_child(0).scene_file_path.ends_with("_clay.tscn") or animal.get_child(0).scene_file_path.ends_with("_clay.scn"), "clay model " + name)
		var word: String = animal.get_meta("word_key", "")
		check(game.vocabulary.has(word), "word in vocabulary " + name + " (" + word + ")")
		game.interaction.show_word(animal)
		check(game.hud.current_spanish == game.vocabulary.get(word, "?"), "study card " + name)
	var movers: Array = get_nodes_in_group("wandering_animals")
	var far := {}
	for n in movers:
		n.set_process(false)
		far[n] = 0.0
	for i in range(7200):
		for n in movers:
			n._process(1.0 / 60)
			if not n.inside(n.position):
				check(false, "containment " + n.name)
			far[n] = maxf(far[n], Vector2(n.position.x - n.home.x, n.position.z - n.home.z).length())
	var lines := []
	for n in movers:
		lines.append("%s %.2f" % [n.name, far[n]])
		if CLAY.has(str(n.name)): check(far[n] > .25, "clay animal moved " + n.name)
	print("WALKERS %d: %s" % [movers.size(), ", ".join(lines)])
	if OS.get_cmdline_user_args().has("views"):
		game.player.get_node("Visual").hide()
		for layer in game.find_children("*", "CanvasLayer", true, false): layer.hide()
		var cam := Camera3D.new()
		game.add_child(cam)
		cam.current = true
		cam.fov = 50
		# The static displays faced the gate along the zoo's +Z: look back at them from there.
		var front: Vector3 = zoo.global_basis.z.normalized()
		var across: Vector3 = zoo.global_basis.x.normalized()
		var up := Vector3.UP
		var centre := Vector3.ZERO
		for name in ["Panda", "Red Panda", "Gorilla", "Deer", "Kangaroo", "Rhinoceros", "Zebra", "Bear Cub", "Flamingo", "Bear"]:
			centre += zoo.to_global(zoo.get_node(name).home) / 10.0
		var farm: Vector3 = zoo.to_global((zoo.get_node("Cow") as Node3D).home)
		var dog: Vector3 = (zoo.get_node("Dog") as Node3D).global_position
		for view in [["wild-overview", centre + front * 34 + up * 22, centre],
				["wild-front-left", centre + front * 12 + across * 6 + up * 4, centre + across * 6 + up * 1.5],
				["wild-front-right", centre + front * 12 - across * 7 + up * 4, centre - across * 7 + up * 1.5],
				["dog", dog + front * 3 + across * 2 + up * 1.5, dog + up * .5]]:
			cam.global_position = view[1]
			cam.look_at(view[2])
			var img: Image = await shot()
			img.save_png(OUT + view[0] + ".png")
		# One close view per animal that replaced an old one, from its current place.
		for name in ["Giraffe", "Elephant", "Bear", "Cow", "Pig", "Duck"]:
			var animal: Node3D = zoo.get_node(name)
			var height: float = (animal.get_meta("display_size") as Vector3).y * zoo.global_basis.get_scale().y
			cam.global_position = animal.global_position + (front * 2.2 + across * 1.2 + up * .8) * maxf(height, 1.2)
			cam.look_at(animal.global_position + up * height * .5)
			var close: Image = await shot()
			close.save_png(OUT + "close-" + name.to_lower() + ".png")
	print("CLAY ZOO CHECK: %d failures" % failures)
	game.free()
	quit()
