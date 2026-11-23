extends SceneTree
## Makes the pictures of the screens before the town (PWA phase 3, 12 Nov 2026), so those
## screens need no 3D: the avatar portraits (assets/ui/avatars/<id>.webp, from
## plush_portraits.gd; the picker's 8 are cut from the user's mockup instead and skipped here,
## see assets/ui/avatars/source/cut_headshots.py), the loading shots (assets/ui/app/shot_N.webp) and the blurred backdrop
## of the splash and profile screens (assets/ui/app/backdrop.webp). Overwrites those files.
## Needs graphics (not --headless) and an isolated HOME (Main runs):
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --always-on-top --resolution 1280x720 --script res://tools/capture_app_art.gd
## VT_ART=shots skips the portraits (town shots and backdrop only). Re-run after a plush or the
## town around a shot changes; then let Godot import the files. The shots keep sun shadows and no
## short view distance (capture_shots()). Frames are drawn with force_draw() and vsync
## off, because a window behind others may stop drawing (--always-on-top helps too).
const Portraits := preload("res://scripts/ui/plush_portraits.gd")
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const HouseCharacters := preload("res://scripts/characters/house_characters.gd")
const AVATARS := "res://assets/ui/avatars/"
## Portraits cut from the user's character-grid mockup (cut_headshots.py IDS; 23 Nov 2026).
const MOCKUP_IDS := ["bonbon", "leo", "bruno", "miso", "awoo", "poppy", "twinkle", "cocodrilo"]
const APP := "res://assets/ui/app/"
const SHOT_SIZE := Vector2i(1280, 720)
## WebP quality of the shots: 0.5 keeps each one under about 70 KB for the web build (16 Nov 2026).
const SHOT_QUALITY := 0.5
## Loading shots (also the welcome tutorial's title cutscene): [file, node (relative to Main),
## camera offset from the look point (world), look height above the node, or a Vector3 offset
## from it]. The backdrop is the first shot, blurred. Retaken 16 Nov 2026 (user: show the
## current town): home street, zoo gate, Washington statue garden, supermarket.
const SHOTS := [
	# Friends at the front-yard mahjong table with the town behind (user, 13 Nov 2026: replaces
	# the outdated tiger model; this shot is also the title screen's blurred backdrop).
	["shot_1", "Apartment/RelocatedSites/Home/MahjongTable", Vector3(7.0, 2.5, -3.0), 0.9],
	# EL ZOOLÓGICO gate with the animals behind it.
	["shot_2", "Apartment/ParkZoo/ZooEntranceGate", Vector3(0.0, 4.0, 16.0), 2.5],
	# The Washington statue, tulip beds and lamps of the public garden, the farm barn behind.
	["shot_3", "Apartment/WashingtonStatue", Vector3(22.0, 6.0, 22.0), 3.0],
	# The SUPERMERCADO front with its entrance and trolleys.
	["shot_4", "Apartment/Buildings/MarketDisplays", Vector3(18.0, 4.0, 0.0), Vector3(15.15, 2.0, 0.0)],
]

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("capture_app_art: needs graphics (run without --headless)")
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for folder in [AVATARS, APP]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	# 1. Portraits.
	if OS.get_environment("VT_ART") != "shots":
		await capture_portraits()
	await capture_shots()
	quit(0)

func capture_portraits() -> void:
	var portraits := Portraits.new()
	root.add_child(portraits)
	for id in ProfileManager.avatar_ids():
		# Cut from the user's mockup instead: assets/ui/avatars/source/cut_headshots.py.
		if id in MOCKUP_IDS:
			continue
		var species := HouseCharacters.scene_of(id).get_file().trim_suffix("_plush.tscn")
		var texture := portraits.texture(species)
		for i in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := texture.get_image()
		image.save_webp(ProjectSettings.globalize_path(AVATARS + id + ".webp"))
		print("portrait ", id, " (", species, ")")
	portraits.queue_free()

## Town shots at midday, without the HUD. The game has one graphics setting since 23 Nov 2026
## (no sun shadows, a 130 m fogged view); these pictures keep the fuller look the shots had (the
## High setting until then): sun shadows and only a faint haze, set here for the shots alone.
func capture_shots() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 30:
		await process_frame
	print("town ready")
	game.day_night.set_time(11.5 * 60.0)
	game.day_night.pause()
	game.day_night.set_view_distance(0.0)
	game.day_night.sun.shadow_enabled = true
	for layer in game.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	var camera := Camera3D.new()
	camera.fov = 55.0
	game.add_child(camera)
	camera.make_current()
	for spec in SHOTS:
		var target := game.get_node_or_null(NodePath(spec[1])) as Node3D
		if target == null:
			print("capture_app_art: no node ", spec[1])
			continue
		var lift: Vector3 = spec[3] if spec[3] is Vector3 else Vector3.UP * float(spec[3])
		var look: Vector3 = target.global_position + lift
		camera.global_position = look + spec[2]
		camera.look_at(look, Vector3.UP)
		for i in 20:
			await process_frame
		print("framed ", spec[0])
		for i in 4:
			RenderingServer.force_draw(false)
		var image := root.get_texture().get_image()
		image.resize(SHOT_SIZE.x, SHOT_SIZE.y, Image.INTERPOLATE_LANCZOS)
		image.save_webp(ProjectSettings.globalize_path(APP + str(spec[0]) + ".webp"), true, SHOT_QUALITY)
		print("shot ", spec[0])
		if spec == SHOTS[0]:
			blurred(image).save_webp(ProjectSettings.globalize_path(APP + "backdrop.webp"), true, 0.7)

## A soft blur: halve the picture four times, then double it back three times (640 x 360; the
## screen stretches it smoothly).
static func blurred(image: Image) -> Image:
	var copy := image.duplicate() as Image
	var size := copy.get_size()
	for i in 4:
		size /= 2
		copy.resize(size.x, size.y, Image.INTERPOLATE_BILINEAR)
	for i in 3:
		size *= 2
		copy.resize(size.x, size.y, Image.INTERPOLATE_BILINEAR)
	return copy
