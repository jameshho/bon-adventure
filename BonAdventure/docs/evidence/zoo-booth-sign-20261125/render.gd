extends SceneTree
## Renders the zoo food booth's ANIMAL FOOD board in Spanish, English and Chinese (25 Nov 2026,
## base step zoo_food_booth_sign_fit: two lines on a taller board; check world_signs).
## Uses Main, which saves progress: run with an isolated HOME (README).
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --script res://docs/evidence/zoo-booth-sign-20261125/render.gd
const SignLanguage := preload("res://scripts/world/sign_language.gd")
const HERE := "res://docs/evidence/zoo-booth-sign-20261125/"
var game
var zoo: Node3D

func _initialize(): run.call_deferred()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func shot(file: String, eye: Vector3, target: Vector3) -> void:
	var cam := Camera3D.new()
	cam.fov = 55.0
	game.add_child(cam)
	cam.global_position = zoo.to_global(eye)
	cam.look_at(zoo.to_global(target), Vector3.UP)
	cam.make_current()
	await frames(8)
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(HERE + file))
	print("saved " + file)
	cam.queue_free()

func run():
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await create_timer(1.0).timeout
	zoo = game.apartment.get_node("ParkZoo")
	var label: Label3D = zoo.get_node("ZooFoodBooth/Booth sign")
	for lang in ["es", "en", "zh"]:
		SignLanguage.set_language(self, lang)
		await frames(2)
		print("%s: %s" % [lang, label.text.replace("\n", " / ")])
		await shot("booth-%s.png" % lang, Vector3(-83.0, 2.0, 120.5), Vector3(-75.3, 2.6, 124.2))
	SignLanguage.set_language(self, "es")
	await shot("booth-wide.png", Vector3(-87.0, 2.2, 118.0), Vector3(-75.0, 2.0, 124.2))
	quit()
