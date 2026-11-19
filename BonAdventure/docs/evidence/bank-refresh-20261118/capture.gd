extends SceneTree
## Bank interior refresh (18 Nov 2026, docs/guides/TOWN_DESIGN_BRIEF.md "Bank interior refresh"):
## eye-level views of the bank interior at noon, as the game draws them. Needs a window; writes
## <prefix>-<view>.png and <prefix>-sheet.png into this folder (overwrites them).
##   HOME=<scratch>/home VT_FOCUS=bank VT_SPAWN=none godot --path . --resolution 1200x800 \
##     --script res://docs/evidence/bank-refresh-20261118/capture.gd -- prefix=before [apply=step1,step2]
## `apply`: run those bank.gd steps at load (a preview before the unit is baked).
const ModularTown := preload("res://scripts/world/modular_town.gd")
const FOLDER := "res://docs/evidence/bank-refresh-20261118/"
const TILE := Vector2i(600, 400)
## Bank-site coordinates (the old town frame: hall x 19.12-30.88, z 37.62-52.38; door at z 37.5).
const VIEWS := {
	"doorway": [Vector3(25.0, 1.75, 38.4), Vector3(25.0, 1.4, 50.0)],
	"tellers": [Vector3(25.3, 1.7, 43.2), Vector3(25.3, 1.6, 48.5)],
	"office": [Vector3(24.6, 1.7, 44.6), Vector3(21.6, 1.4, 48.0)],
	"vault": [Vector3(25.8, 1.7, 44.4), Vector3(28.8, 1.4, 48.8)],
	"atms": [Vector3(25.6, 1.7, 41.4), Vector3(29.6, 1.3, 41.5)],
	"inside-vault": [Vector3(28.6, 1.8, 49.4), Vector3(29.4, 1.0, 52.3)],
	"waiting": [Vector3(27.5, 1.9, 43.0), Vector3(20.0, 1.0, 44.0)],
	"lobby-from-back": [Vector3(25.2, 2.2, 46.4), Vector3(25.0, 1.3, 38.0)],
}

var game
var camera: Camera3D
var args := {}

func _initialize(): run.call_deferred()

func settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func frame_image() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var prefix: String = args.get("prefix", "view")
	game = load("res://scenes/main.tscn").instantiate()
	if args.has("apply"):
		game.set_meta("editing_snapshot", true)
	root.add_child(game)
	await game.ensure_unit("bank")
	if args.has("apply"):
		var script = load("res://scripts/buildings/bank.gd").new()
		for step in String(args.apply).split(","):
			script.call(step, game.apartment, game)
		preload("res://scripts/world/render_culling.gd").new().build(game)
	await settle(5)
	game.player.set_physics_process(false)
	game.player.visible = false
	game.interaction.set_physics_process(false)
	camera = Camera3D.new()
	camera.near = 0.05
	camera.fov = 70.0
	game.add_child(camera)
	camera.current = true
	game.day_night.pause()
	game.day_night.set_time(12 * 60)
	game.hud.hide()
	var bank: Node3D = ModularTown.building(game.apartment, "bank")
	if bank == null:
		print("BANKREFRESH bank missing")
		quit(1)
		return
	var tiles := []
	for view in VIEWS:
		var pair: Array = VIEWS[view]
		camera.global_position = bank.to_global(pair[0])
		camera.look_at(bank.to_global(pair[1]))
		await settle(12)
		var img := await frame_image()
		img.save_png(ProjectSettings.globalize_path(FOLDER + prefix + "-" + view + ".png"))
		img.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
		img.convert(Image.FORMAT_RGB8)
		tiles.append(img)
	var sheet := Image.create(TILE.x * 2, TILE.y * ((tiles.size() + 1) / 2), false, Image.FORMAT_RGB8)
	for i in range(tiles.size()):
		sheet.blit_rect(tiles[i], Rect2i(Vector2i.ZERO, TILE), Vector2i((i % 2) * TILE.x, (i / 2) * TILE.y))
	sheet.save_png(ProjectSettings.globalize_path(FOLDER + prefix + "-sheet.png"))
	print("BANKREFRESH done")
	quit(0)
