extends SceneTree
## Zoo zones (base step `zoo_zones`, 12 Nov 2026): every wild-animal-lawn animal stands in its
## design zone, wanders only inside that zone's habitat and still moves in two simulated minutes;
## all ParkZoo wanderers stay contained; the zone signs and the arch are translated signs.
## With `views` it saves rendered views (PNG only) to this folder.
## Run with an isolated HOME (README), VT_FOCUS=all VT_SPAWN=none:
##   godot --path . --resolution 1200x800 --script res://docs/evidence/zoo-zones-20261112/check.gd [-- views]
const OUT := "res://docs/evidence/zoo-zones-20261112/"
const Base := preload("res://scripts/buildings/base.gd")
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

func zone_of(name: String) -> String:
	var at: Vector2 = Base.ZONE_HOMES[name]
	for title in Base.ZOO_ZONES:
		if (Base.ZOO_ZONES[title][0] as Rect2).has_point(at): return title
	return ""

func run() -> void:
	root.size = Vector2i(1200, 800)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(40): await process_frame
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	var zoo: Node3D = game.apartment.get_node("ParkZoo")
	check(zoo.has_node("ZooZones"), "zone scenery present")
	check(not zoo.has_node("Habitat sign"), "old WILD ANIMALS board removed")
	for title in Base.ZOO_ZONES:
		check(zoo.has_node("Zone ground " + title), "zone ground " + title)
	var signs := 0
	for label in zoo.get_node("ZooZones").find_children("*", "Label3D", true, false):
		if label.is_in_group("translated_signs"): signs += 1
	check(signs == 5, "five translated zone/arch signs (%d)" % signs)
	for name: String in Base.ZONE_HOMES:
		var animal: Node3D = zoo.get_node_or_null(name)
		check(animal != null and animal.get("_configured") == true, "animal wanders " + name)
		if animal == null: continue
		var zone := zone_of(name)
		var rect: Rect2 = Base.ZOO_ZONES[zone][0]
		check(zone != "" and rect.encloses(animal.habitat) and animal.habitat.has_area(), "habitat inside %s: %s" % [zone, name])
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
		if Base.ZONE_HOMES.has(str(n.name)): check(far[n] > .25, "zone animal moved " + n.name)
	print("WALKERS %d: %s" % [movers.size(), ", ".join(lines)])
	if OS.get_cmdline_user_args().has("views"):
		game.player.get_node("Visual").hide()
		for layer in game.find_children("*", "CanvasLayer", true, false): layer.hide()
		var cam := Camera3D.new()
		game.add_child(cam)
		cam.current = true
		cam.fov = 50
		for view in [["overview", Vector3(-78, 30, 141), Vector3(-78, 0, 104)],
				["savanna", Vector3(-90, 8, 108), Vector3(-91, 1, 92)],
				["forest", Vector3(-66, 8, 108), Vector3(-65, 1, 92)],
				["bamboo", Vector3(-90, 7, 131), Vector3(-91, 1, 114)],
				["plains", Vector3(-66, 7, 131), Vector3(-65, 1, 114)],
				["entrance", Vector3(-78, 2.6, 135), Vector3(-78, 2.4, 126)],
				["plaza", Vector3(-78, 3.5, 115.5), Vector3(-78, 1.2, 104)]]:
			cam.global_position = zoo.to_global(view[1])
			cam.look_at(zoo.to_global(view[2]))
			var img: Image = await shot()
			img.save_png(OUT + view[0] + ".png")
	print("ZOO ZONES CHECK: %d failures" % failures)
	game.free()
	quit()
