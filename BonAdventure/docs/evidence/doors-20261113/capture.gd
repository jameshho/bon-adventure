extends SceneTree
## Views of every migrated door from both sides (docs/guides/DOORS.md): front and back of each door,
## closed, written as one contact sheet per run to docs/evidence/doors-20261113/<VT_SHEET>.png
## (default "after"). Reads the door list from docs/evidence/doors-20261113/views.json (world centre and
## normal per door). Graphical run (overwrites the sheet):
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none VT_SHEET=after godot --path . \
##     --resolution 1600x1000 --script res://docs/evidence/doors-20261113/capture.gd
const FOLDER := "res://docs/evidence/doors-20261113/"
const CELL := Vector2i(320, 240)
var game

func _initialize(): run.call_deferred()

func run() -> void:
	var views: Array = JSON.parse_string(FileAccess.get_file_as_string(FOLDER + "views.json"))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	for i in 3: await physics_frame
	game.day_night.set_time(game.day_night.DAY_MINUTES * 0.5)
	game.day_night.pause()
	game.hud.visible = false
	var cam := Camera3D.new()
	cam.fov = 60
	game.add_child(cam)
	cam.current = true
	var cols := 6
	var shots: Array[Image] = []
	for v in views:
		var c := Vector3(v.c[0], v.c[1], v.c[2])
		var n := Vector3(v.n[0], v.n[1], v.n[2])
		var dist: float = v.get("dist", 4.2)
		for s in [1.0, -1.0]:
			cam.look_at_from_position(c + n * s * dist + Vector3(0, 0.6, 0), c)
			for i in 4: await process_frame
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			img.resize(CELL.x, CELL.y)
			shots.append(img)
	var rows := ceili(shots.size() / float(cols))
	var sheet := Image.create(CELL.x * cols, CELL.y * rows, false, shots[0].get_format())
	for i in shots.size():
		sheet.blit_rect(shots[i], Rect2i(Vector2i.ZERO, CELL), Vector2i((i % cols) * CELL.x, (i / cols) * CELL.y))
	var sheet_name := OS.get_environment("VT_SHEET")
	sheet.save_png(FOLDER + (sheet_name if sheet_name != "" else "after") + ".png")
	print("DOOR CAPTURE: ", shots.size(), " views")
	quit()
