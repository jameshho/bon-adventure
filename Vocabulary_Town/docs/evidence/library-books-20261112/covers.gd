extends SceneTree
## 12 Nov 2026 library book covers: the 24 picture books of scenes/props/book.tscn side by side,
## lit like a room, without loading the town (fast check of the cover pictures).
## godot --path . --resolution 1500x1000 --script res://docs/evidence/library-books-20261112/covers.gd
## Writes covers.png into this folder (overwrites it). Reads and writes no saves.
const Book := preload("res://scripts/world/library_book.gd")
const BOOK_SCENE := preload("res://scenes/props/book.tscn")
const OUT := "res://docs/evidence/library-books-20261112/covers.png"

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("e9dcc4")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 1, 1)
	env.environment.ambient_light_energy = .55
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_energy = .9
	world.add_child(sun)
	sun.look_at_from_position(Vector3(1, 2, -3), Vector3.ZERO, Vector3.UP)
	var titles: Array = Book.COVERS.keys()
	var spacing := Vector2(Book.PICTURE.x + .08, Book.PICTURE.y + .08)
	for i in titles.size():
		var book: Node3D = BOOK_SCENE.instantiate()
		book.title = titles[i]
		book.size = Vector3(Book.PICTURE.x, Book.PICTURE.y, .18)
		book.spine_color = Color("6f4fa6")
		world.add_child(book)
		# Cover faces -Z; the camera looks along +Z, so +X is to the viewer's left.
		book.position = Vector3((2.5 - i % 6) * spacing.x, (1.5 - i / 6) * spacing.y - Book.PICTURE.y * .5, 0)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = spacing.y * 4 + .05
	world.add_child(camera)
	camera.look_at_from_position(Vector3(0, 0, -3), Vector3.ZERO, Vector3.UP)
	camera.current = true
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT)
	print("COVERS ", OUT)
	quit()
