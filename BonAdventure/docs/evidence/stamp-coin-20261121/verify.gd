extends SceneTree
## 21 Nov 2026 (user): the town stamp coin (scripts/world/stamp_coin.gd) for review before it is
## placed, and the achievement tracker it reports to (scripts/learning/achievements.gd). A small
## stage of its own (no town): a corner of a cream wall, the coin floating at chest height.
## HOME=<scratch> godot --path . --resolution 1280x800 --script res://docs/evidence/stamp-coin-20261121/verify.gd
## (checks only; the pictures are town_view.gd's). Writes achievements.json only in
## the isolated HOME.
const OUT := "res://docs/evidence/stamp-coin-20261121"
const StampCoin := preload("res://scripts/world/stamp_coin.gd")
const Achievements := preload("res://scripts/learning/achievements.gd")
var checks := 0
var failures := 0
var graphics := false
var camera: Camera3D

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	var tracker = Achievements.shared()
	check(tracker.defs.has("game.library_rosa"), "a game.<id> achievement per minigame")
	check(tracker.defs.has("stamp.library"), "a stamp.<id> achievement per stamp")
	check(tracker.defs.has("fly_plane") and tracker.defs.has("mission_5"), "listed achievements load")
	check(not tracker.has_stamp("library"), "a new profile has no stamps")
	var stage := _stage()
	# A coin to look at (preview: never collected by walking) and one the test player walks into.
	var show: Node3D = StampCoin.make("library")
	show.preview = true
	show.position = Vector3(0, 1.15, 0)
	stage.add_child(show)
	await _frames(20)
	# Pictures: town_view.gd (the real town's light; this stage is only for the logic).
	show.collect()
	await _wait(0.9)
	check(is_instance_valid(show), "a preview coin stays after its collect animation")
	show.queue_free()
	var coin: Node3D = StampCoin.make("library")
	coin.position = Vector3(2.5, 1.15, 0)
	stage.add_child(coin)
	var player := CharacterBody3D.new()
	player.add_to_group("player")
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.4
	shape.shape = capsule
	player.add_child(shape)
	player.position = Vector3(6, 0.7, 0)
	stage.add_child(player)
	var unlocked: Array = []
	tracker.unlocked.connect(func(id: String, _def: Dictionary) -> void: unlocked.append(id))
	await _frames(5)
	check(not tracker.has_stamp("library"), "nothing collected from 3.5 m away")
	player.position = Vector3(2.5, 0.7, 0)
	await _frames(8)
	check(tracker.has_stamp("library"), "walking into the coin collects the stamp")
	check(unlocked.has("stamp.library"), "the unlocked signal names the stamp")
	check(tracker.xp() == 15, "a stamp gives 15 XP (got %d)" % tracker.xp())
	await _wait(1.0)
	check(not is_instance_valid(coin), "the collected coin removes itself")
	var again: Node3D = StampCoin.make("library")
	stage.add_child(again)
	check(not again.visible, "a collected stamp's coin does not show again")
	var saved = Achievements.new()
	saved.load_defs()
	saved.load_saved()
	check(saved.has_stamp("library") and saved.xp() == 15, "the stamp and XP are saved")
	var log: Array = saved.recent(5)
	check(not log.is_empty() and str(log[log.size() - 1].get("id")) == "stamp.library", "the log records the unlock")
	tracker.note("sit_down")
	tracker.note("sit_down")
	check(tracker.count("sit_down") == 2 and tracker.is_unlocked("sit_down"), "events count; their achievement unlocks once")
	for i in 5:
		tracker.note("mission")
	check(tracker.is_unlocked("mission_1") and tracker.is_unlocked("mission_5") and not tracker.is_unlocked("mission_20"), "count thresholds unlock in turn")
	print("stamp_coin: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _stage() -> Node3D:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("bfe3ee")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("fff4e0")
	environment.ambient_light_energy = 0.7
	env.environment = environment
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	stage.add_child(sun)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("d9c4a0")
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color("f3e6cc")
	for part in [[Vector3(0, -0.05, 0), Vector3(14, 0.1, 14), floor_mat], [Vector3(0, 1.6, -0.9), Vector3(5, 3.2, 0.2), wall_mat], [Vector3(-1.2, 1.6, 0.6), Vector3(0.2, 3.2, 3.0), wall_mat]]:
		var body := StaticBody3D.new()
		body.position = part[0]
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = part[1]
		box.material = part[2]
		mesh.mesh = box
		body.add_child(mesh)
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = part[1]
		shape.shape = box_shape
		body.add_child(shape)
		stage.add_child(body)
	camera = Camera3D.new()
	camera.fov = 60
	stage.add_child(camera)
	camera.make_current()
	return stage

func _place_camera(at: Vector3, look: Vector3) -> void:
	camera.position = at
	camera.look_at(look, Vector3.UP)

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _shot(title: String) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [ProjectSettings.globalize_path(OUT), title])
	print("wrote ", title)
