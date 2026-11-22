extends SceneTree
## Rendered views of the soft sun / moon disc (21 Nov 2026; shaders/sky_disc.gdshader,
## scripts/world/day_night.gd). Needs a window; writes sheet-low.png and sheet-high.png into this
## folder (overwrites them). Run with an isolated HOME (README):
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1200x900 --script res://docs/evidence/soft-sun-20261121/capture.gd
## Rows: the street, the plaza and the raised view, each turned toward the disc (kept near the horizon when it is
## low). Columns: 06:10, 06:40, 12:00, 17:45, 18:20, 18:35, 00:00.
const FOLDER := "res://docs/evidence/soft-sun-20261121/"
const TILE := Vector2i(400, 300)
const TIMES := [[6, 10], [6, 40], [12, 0], [17, 45], [18, 20], [18, 35], [0, 0]]
## Town-space eye points: the street south of the plaza, the monument plaza and a raised view
## with a clear horizon.
const EYES := [Vector3(0, 2.5, 198), Vector3(-20, 2.2, 150), Vector3(38, 30, 185)]

var game
var camera: Camera3D

func _initialize(): run.call_deferred()

func frame_image() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func sheet(rows: Array, columns: int) -> Image:
	var out := Image.create(TILE.x * columns, TILE.y * rows.size(), false, Image.FORMAT_RGB8)
	for r in range(rows.size()):
		for c in range(rows[r].size()):
			var img: Image = rows[r][c]
			img.convert(Image.FORMAT_RGB8)
			img.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
			out.blit_rect(img, Rect2i(Vector2i.ZERO, TILE), Vector2i(c * TILE.x, r * TILE.y))
	return out

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	game.player.visible = false
	game.interaction.set_physics_process(false)
	camera = Camera3D.new()
	camera.fov = 70.0
	game.add_child(camera)
	camera.current = true
	game.hud.hide()
	var cycle = game.day_night
	cycle.pause()
	var town: Node3D = game.apartment
	for tier in [["low", 130.0], ["high", 0.0]]:
		var distance: float = tier[1]
		camera.far = distance if distance > 0.0 else 4000.0
		cycle.set_graphics(distance <= 0.0, distance)
		var rows := []
		for eye in EYES:
			var row := []
			camera.global_position = town.to_global(eye)
			game.player.global_position = camera.global_position - Vector3(0, 1.6, 0)
			await settle(20)
			for t in TIMES:
				cycle.set_time(t[0] * 60 + t[1])
				await settle(2)
				var toward: Vector3 = cycle._disc_dir.normalized()
				toward.y = clampf(toward.y, 0.08, 0.55)
				camera.look_at(camera.global_position + toward)
				await settle(4)
				row.append(await frame_image())
			rows.append(row)
		sheet(rows, TIMES.size()).save_png(FOLDER + "sheet-%s.png" % tier[0])
		print("SOFT SUN CAPTURE: %s written" % tier[0])
	quit(0)
