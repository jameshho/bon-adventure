extends SceneTree
## 21 Nov 2026 (user): the Passport (scripts/ui/passport_panel.gd) with town missions
## (scripts/learning/missions.gd), the achievement log and town stamps
## (scripts/learning/achievements.gd), the mission stars on the town map and the activity hooks
## (scripts/learning/achievement_hooks.gd).
## HOME=<scratch> VT_FOCUS=library,police,school VT_SPAWN=library godot --path . --resolution 1280x800 \
##   --script res://docs/evidence/passport-missions-20261121/verify.gd
## (headless: checks only). With graphics writes *.png here. Writes saves only in the isolated HOME.
const OUT := "res://docs/evidence/passport-missions-20261121"
const Missions := preload("res://scripts/learning/missions.gd")
const Achievements := preload("res://scripts/learning/achievements.gd")
const Hooks := preload("res://scripts/learning/achievement_hooks.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
var checks := 0
var failures := 0
var graphics := false
var game

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 30: await process_frame
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(11 * 60.0)
	var missions = Missions.shared()
	var tracker = Achievements.shared()
	var passport = game.passport
	check(passport != null and passport.corner_button.visible, "the Passport corner button shows")
	check(missions.slots.map(func(s): return s.game) == Missions.START, "a new profile starts with %s" % [Missions.START])
	for id in missions.candidates():
		check(UiText.has("missions." + id) and UiText.has("missions_desc." + id), "mission text for " + id)
	for id in tracker.order:
		check(tracker.title(id) != "" and not tracker.title(id).begins_with("achievements."), "a name for " + id)
	passport.open()
	await settle()
	check(passport.visible and game.locks_player() if game.has_method("locks_player") else passport.visible, "the Passport opens")
	await shot("missions-new")
	# A mission is done when its game finishes (here: the board's ended signal).
	game.passport.close()
	preload("res://scripts/learning/activity_board.gd").shared().ended.emit("library_rosa", {"completed": true, "rounds": 3, "target": 3})
	check(missions.is_done(1), "finishing Library Helper completes its mission")
	check(tracker.is_unlocked("mission_1") and tracker.is_unlocked("game.library_rosa"), "first mission and first game achievements unlock")
	check(tracker.xp() == 30 + 10 + 10, "XP: mission 30 + mission_1 10 + game 10 (got %d)" % tracker.xp())
	check(missions.seconds_left(1) > 590, "a new mission in about 10 minutes (%d s)" % missions.seconds_left(1))
	passport.open()
	await settle()
	var count_label: Label = passport._countdowns.get(1)
	check(count_label != null and (count_label.text.contains("10:00") or count_label.text.contains("9:5")), "the done card counts down (%s)" % (count_label.text if count_label else "none"))
	await shot("missions-one-done")
	missions.clock_offset = 601
	missions.refresh()
	check(not missions.is_done(1) and missions.slots[1].game != "library_rosa" and missions.slots[1].game not in [missions.slots[0].game, missions.slots[2].game], "after 10 minutes a different game fills the slot (%s)" % missions.slots[1].game)
	missions.clock_offset = 0
	# Go there: the guide arrow points at the mission's game.
	var target: String = missions.slots[0].game
	passport.go_there(target)
	check(not passport.visible and game.guide.active() and game.guide.target_game == target, "Go there closes the Passport and guides to " + target)
	game.guide.stop()
	# Activities: states noted on their change (the hooks' tick) and one-line events.
	game.player.seated = true
	Hooks.tick(game)
	game.player.seated = false
	Hooks.tick(game)
	check(tracker.is_unlocked("sit_down"), "sitting down is noted")
	check(game.hud.quest_toast.text.contains(UiText.t("achievements.sit_down")), "the unlock toast names it (%s)" % game.hud.quest_toast.text)
	tracker.note("stamp.library")
	tracker.note("stamp.police_station")
	tracker.note("open_map")
	passport.open("stamps")
	await settle()
	await shot("stamps")
	passport.show_page("explore")
	await settle()
	await shot("exploration")
	passport._log_page = "games"
	passport._rebuild()
	await settle()
	await shot("exploration-games")
	passport._log_page = "diary"
	passport._rebuild()
	await settle()
	await shot("exploration-diary")
	for page in ["missions", "stamps", "explore"]:
		passport.show_page(page)
		await settle()
		# On-screen fit needs a real window: headless runs have a fixed 64 x 64 root viewport
		# (README "Verification"), so the fit is checked only with graphics (25 Nov 2026).
		if DisplayServer.get_name() != "headless":
			check(passport.window.get_rect().end.y <= root.get_visible_rect().size.y + 1.0, "%s page fits the window (%.0f px)" % [page, passport.window.size.y])
	passport.close()
	if game.town_map != null:
		game.hud.toggle_map()
		await settle()
		await shot("map-mission-stars")
		game.hud.toggle_map()
	print("passport_missions: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func settle() -> void:
	for i in 6: await process_frame

func shot(title: String) -> void:
	if not graphics:
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [ProjectSettings.globalize_path(OUT), title])
	print("wrote ", title)
