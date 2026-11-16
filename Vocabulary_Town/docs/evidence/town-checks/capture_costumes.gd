extends SceneTree

# Contact sheets of plush outfits (data/plush_costumes.json) on all nine Home plushes.
# godot --path . --resolution 1200x1200 --script res://docs/evidence/town-checks/capture_costumes.gd -- [outfit ...] [stand] [output_dir]
# Builds its own small stage instead of Main, so it never reads or writes learner
# saves. Plushes sit in the shared seated pose from house_characters.gd (tails tucked)
# unless "stand" is given. Writes <outfit>_<view>.png (3 x 3 grid, one plush per tile);
# "none" renders the undressed plushes. Output defaults to user://costume-review/.

const SPECIES := ["pig", "lion", "bear", "cat", "samoyed", "sheep", "golden", "beagle", "crocodile"]
const TILE := Vector2i(400, 400)
const VIEWS := {"front": 0.0, "three_quarter": 0.75, "back": PI}

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var outfits: Array[String] = []
	var base := "user://costume-review"
	var stand := false
	for arg in OS.get_cmdline_user_args():
		if arg == "stand":
			stand = true
		elif arg.contains("/"):
			base = arg
		else:
			outfits.append(arg)
	if outfits.is_empty():
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/plush_costumes.json"))
		outfits.assign(data["outfits"].keys())
	DirAccess.make_dir_recursive_absolute(base)
	root.size = TILE
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("e9e4da")
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.6
	var world := WorldEnvironment.new()
	world.environment = environment
	stage.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.rotation = Vector3(-0.9, -0.5, 0.0)
	stage.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	(floor_mesh.mesh as PlaneMesh).size = Vector2(20, 20)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("9d9483")
	floor_mesh.material_override = floor_material
	stage.add_child(floor_mesh)
	var cam := Camera3D.new()
	cam.fov = 32
	stage.add_child(cam)
	cam.current = true
	var placer = load("res://scripts/characters/house_characters.gd").new()
	var costume_script = load("res://scripts/characters/plush_costume.gd")
	for outfit in outfits:
		var sheets := {}
		for key in VIEWS:
			sheets[key] = Image.create(TILE.x * 3, TILE.y * 3, false, Image.FORMAT_RGBA8)
		for index in range(SPECIES.size()):
			var npc: Node3D = load("res://scenes/characters/%s_plush.tscn" % SPECIES[index]).instantiate()
			stage.add_child(npc)
			if not stand:
				placer._sit(npc)
				npc.basis = Basis(Vector3.RIGHT, placer.SIT_RECLINE)
				for tail in npc.find_children("Tail*", "MeshInstance3D", false, false):
					tail.visible = false
			if outfit != "none":
				costume_script.dress(npc, outfit)
			var target := Vector3(0, 1.2, 0)
			for key in VIEWS:
				var angle: float = VIEWS[key]
				cam.global_position = target + Vector3(sin(angle), 0.12, -cos(angle)).normalized() * 6.2
				cam.look_at(target, Vector3.UP)
				for i in range(4):
					await process_frame
				await RenderingServer.frame_post_draw
				var shot := root.get_texture().get_image()
				shot.convert(Image.FORMAT_RGBA8)
				sheets[key].blit_rect(shot, Rect2i(Vector2i.ZERO, TILE), Vector2i(index % 3, index / 3) * TILE)
			npc.free()
		for key in VIEWS:
			sheets[key].save_png(base.path_join("%s_%s.png" % [outfit, key]))
		print("saved ", outfit)
	print("saved sheets to ", ProjectSettings.globalize_path(base))
	quit()
