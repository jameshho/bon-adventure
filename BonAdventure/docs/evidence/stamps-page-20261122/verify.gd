extends SceneTree
## 22 Nov 2026 (user: "make the town stamp page look better and completed ones should show a coin
## logo, like the actual design of the coin, instead of a star"): the Passport's Town stamps page
## (scripts/ui/passport_panel.gd _build_stamps) with a few stamps found, in English and Chinese,
## at a laptop and a small landscape window.
## HOME=<scratch> VT_FOCUS=library VT_SPAWN=library godot --path . --resolution 1280x800 \
##   --script res://docs/evidence/stamps-page-20261122/verify.gd
## Writes saves only in the isolated HOME; pictures here.
const OUT := "res://docs/evidence/stamps-page-20261122"
const Achievements := preload("res://scripts/learning/achievements.gd")
var checks := 0
var failures := 0
var game

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 30: await process_frame
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(11 * 60.0)
	var tracker = Achievements.shared()
	for id in ["library", "police_station", "bank", "chapel", "playground"]:
		tracker.note("stamp." + id)
	var passport = game.passport
	passport.open("stamps")
	await settle()
	var ids: Array[String] = tracker.ids_in("stamps")
	check(ids.size() == 18, "18 placed stamps listed (%d)" % ids.size())
	for id in ids:
		var cell: Control = passport.window.find_child("Stamp " + id.validate_node_name(), true, false)
		var coin: TextureRect = cell.find_child("Coin", true, false) if cell else null
		var got: bool = tracker.is_unlocked(id)
		check(coin != null and coin.texture == passport.COIN_FACE and (coin.self_modulate.a > 0.9) == got, "%s: coin face, %s" % [id, "full colour" if got else "faded"])
	var bar: ProgressBar = passport.window.find_child("Stamp bar", true, false)
	check(bar != null and int(bar.value) == 5 and int(bar.max_value) == 18, "progress bar 5 / 18")
	check(passport.window.get_rect().end.y <= root.get_visible_rect().size.y + 1.0, "fits 1280 x 800 (%.0f px)" % passport.window.size.y)
	await shot("stamps-1280x800")
	if game.has_method("set_language"):
		pass
	root.size = Vector2i(900, 560)
	passport._layout()
	passport._rebuild()
	await settle()
	check(passport.window.get_rect().end.y <= 561.0 and passport.window.get_rect().end.x <= 901.0, "fits 900 x 560 (%.0f x %.0f)" % [passport.window.size.x, passport.window.size.y])
	await shot("stamps-900x560")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func settle() -> void:
	for i in 8: await process_frame

func shot(title: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [ProjectSettings.globalize_path(OUT), title])
	print("wrote ", title)
