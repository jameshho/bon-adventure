extends Node
## Web only: back to the same spot after the browser drops the game's graphics (WebGL context
## loss; user, 14 Nov 2026: "reduce + recover"). A page cannot bring a lost WebGL context back
## to Godot, so the page shell (the second script in the Web preset's html/head_include,
## export_presets.cfg) catches `webglcontextlost` before Godot's "please reload" alert, calls
## window.vtResume('lost'), shows a short notice (window.vtLostText) and reloads the page with
## sessionStorage RELOAD_FLAG set. The shell also calls window.vtResume('hide') when the page is
## hidden or closed.
##
## This node (made by app.gd once a profile is chosen) keeps the resume note: every
## SNAPSHOT_SECONDS while the player stands on the ground, and on each vtResume call, it writes
## {profile, x, y, z, yaw, time} to localStorage[STORE_KEY] (synchronous, so it is kept even when
## the page is frozen right after being hidden; learner saves themselves are already written at
## once by save_store.gd). After a reload with the flag, app.gd skips the title and "Who's
## playing?", loads that profile's town, places the player at the note (profiles that finished
## the tutorial; a tutorial starts as usual) and shows "app.graphics_back".
## Each vtResume call also saves the profile's place (player_place.gd, 14 Nov 2026).
## README.md "Web app (PWA)" describes the whole path; docs/guides/FINAL_VERIFICATION.md how it was tried.
##
## New builds (15 Nov 2026, user: the installed app should always run the newest version). The
## browser checks Godot's service worker each time the app opens, and the page shell asks again
## when the app comes back to the front. A new build installs beside the running one and waits;
## Godot reports it (JavaScriptBridge.pwa_update_available). Before the town is ready app.gd
## switches to it at once (JavaScriptBridge.pwa_update() reloads the page). In the town,
## offer_update() asks in the dialogue box (app.update_ready) when the player is free; Update
## writes the resume note and reloads with RELOAD_FLAG, so the new build starts at the same spot.
##
## Restarts by the browser (25 Nov 2026, user report: on a phone the game went back to the title
## four times in 15 minutes). A phone browser that runs short of memory kills the page without
## any event and opens it again, so the game started at the title. Each snapshot also sets
## localStorage[RUNNING_KEY]; the page shell removes it on `pagehide` (a reload, closing the tab,
## leaving the page) and sets window.bonLeaving, so a snapshot arriving after that does not set it
## again; the game's own reloads pass through pagehide too. A page that
## starts with the marker still set ended without pagehide: take() counts it in
## localStorage[RESTARTS_KEY] (shown by the ?perf=1 readout) and, when the note is at most
## CRASH_MAX_AGE_SECONDS old, resumes from it like a lost-graphics reload. take() looks only once
## per page, so switching profile (which reloads app.tscn, not the page) never resumes.
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")

const STORE_KEY := "bon-resume"
const RELOAD_FLAG := "bon-resume-now"
## The names before the Bon Adventure rename (16 Nov 2026). take() moves an old note to
## STORE_KEY once and removes the old key, and accepts the old flag (set by the old build just
## before it reloaded into this one).
const OLD_STORE_KEY := "vt-resume"
const OLD_RELOAD_FLAG := "vt-resume-now"
## Page code (one JS expression, also run by the evidence check in node) that moves the note.
const MOVE_OLD_NOTE_JS := "(function () { try { var old = localStorage.getItem('%s'); if (old !== null) { if (localStorage.getItem('%s') === null) { localStorage.setItem('%s', old); } localStorage.removeItem('%s'); } } catch (e) {} })()"
const SNAPSHOT_SECONDS := 5.0
## A note older than this is not used (the player came back much later: start normally).
const MAX_AGE_SECONDS := 30 * 60
## Set while the town runs; removed by the page shell on pagehide (see the header).
const RUNNING_KEY := "bon-running"
## Times (unix seconds) of the last restarts by the browser, newest last, at most RESTARTS_KEPT.
const RESTARTS_KEY := "bon-restarts"
const RESTARTS_KEPT := 20
## After a restart by the browser, a note at most this old is resumed from. Shorter than
## MAX_AGE_SECONDS: an app swiped away may also skip pagehide, and opened much later it should
## start at the title.
const CRASH_MAX_AGE_SECONDS := 5 * 60
## take() has run in this page (static: survives app.tscn reloads, not page reloads).
static var _taken := false

var main: Node
var _callback: JavaScriptObject
var _elapsed := 0.0
## A new build waits (offer_update()); asked once the player is free, at most once a launch.
var _update_waiting := false
var _update_line: Dictionary = {}
var _update_check := 0.0
const UPDATE_YES := "app_update_yes"
const UPDATE_NO := "app_update_no"


## The resume note to use now, or {} (not the web, no reload after a lost context or a restart
## by the browser, an old note, a profile that is gone, or not this page's first call). Clears
## the reload flag and the running marker, so a later reload starts normally.
static func take() -> Dictionary:
	if not OS.has_feature("web") or _taken:
		return {}
	_taken = true
	JavaScriptBridge.eval(move_old_note_js(), true)
	var flag: Variant = JavaScriptBridge.eval("(function () { try { var f = sessionStorage.getItem('%s') || sessionStorage.getItem('%s'); sessionStorage.removeItem('%s'); sessionStorage.removeItem('%s'); return f || ''; } catch (e) { return ''; } })()" % [RELOAD_FLAG, OLD_RELOAD_FLAG, RELOAD_FLAG, OLD_RELOAD_FLAG], true)
	var crashed := _take_running_marker()
	var max_age := MAX_AGE_SECONDS
	if str(flag) != "1":
		if not crashed:
			return {}
		max_age = CRASH_MAX_AGE_SECONDS
	var text: Variant = JavaScriptBridge.eval("(function () { try { return localStorage.getItem('%s') || ''; } catch (e) { return ''; } })()" % STORE_KEY, true)
	var note: Variant = JSON.parse_string(str(text)) if str(text) != "" else null
	if not note is Dictionary:
		return {}
	var age := Time.get_unix_time_from_system() - float(note.get("time", 0.0))
	if age > max_age or ProfileManager.shared().get_profile(str(note.get("profile", ""))).is_empty():
		return {}
	return note


## True when the last page ended without pagehide (RUNNING_KEY still set); records that restart
## in RESTARTS_KEY. Removes the marker either way.
static func _take_running_marker() -> bool:
	var js := "(function () { try { var on = localStorage.getItem('%s') === '1'; localStorage.removeItem('%s'); if (on) { var list = JSON.parse(localStorage.getItem('%s') || '[]'); list.push(Date.now() / 1000); localStorage.setItem('%s', JSON.stringify(list.slice(-%d))); } return on ? '1' : ''; } catch (e) { return ''; } })()"
	return str(JavaScriptBridge.eval(js % [RUNNING_KEY, RUNNING_KEY, RESTARTS_KEY, RESTARTS_KEY, RESTARTS_KEPT], true)) == "1"


## Restarts by the browser in the last `seconds` (the ?perf=1 readout), and the newest's time.
static func recent_restarts(seconds: float) -> Array:
	if not OS.has_feature("web"):
		return []
	var text: Variant = JavaScriptBridge.eval("(function () { try { return localStorage.getItem('%s') || '[]'; } catch (e) { return '[]'; } })()" % RESTARTS_KEY, true)
	var list: Variant = JSON.parse_string(str(text))
	var now := Time.get_unix_time_from_system()
	var recent := []
	if list is Array:
		for t in list:
			if now - float(t) <= seconds:
				recent.append(float(t))
	return recent


## MOVE_OLD_NOTE_JS with the key names filled in.
static func move_old_note_js() -> String:
	return MOVE_OLD_NOTE_JS % [OLD_STORE_KEY, STORE_KEY, STORE_KEY, OLD_STORE_KEY]


## The notice texts the page shell shows, in the player's native language.
static func set_page_texts() -> void:
	if not OS.has_feature("web"):
		return
	var lexicon = Lexicon.shared()
	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		return
	window.vtLostText = lexicon.phrase("app.graphics_lost", lexicon.native)
	window.vtTapText = lexicon.phrase("app.tap_to_reload", lexicon.native)


func _ready() -> void:
	set_page_texts()
	_callback = JavaScriptBridge.create_callback(_on_page_event)
	var window := JavaScriptBridge.get_interface("window")
	if window != null:
		window.vtResume = _callback
	set_process(false)


## Starts keeping notes for this town.
func watch(town: Node) -> void:
	main = town
	set_page_texts()
	set_process(true)
	var panel = town.shop_panel
	if panel != null and not panel.choice_pressed.is_connected(_on_update_choice):
		panel.choice_pressed.connect(_on_update_choice)
		panel.dialogue_closed.connect(_on_update_closed)


## Puts the player where `note` says (a profile that has finished the tutorial).
func place(town: Node, note: Dictionary) -> void:
	var player: Node3D = town.player
	player.global_position = Vector3(float(note.get("x", 0.0)), float(note.get("y", 0.0)), float(note.get("z", 0.0)))
	player.velocity = Vector3.ZERO
	player.camera_yaw = float(note.get("yaw", 0.0))
	player.rotation.y = player.camera_yaw
	player.reset_camera()


## "app.graphics_back" in the HUD's message line.
func tell_back(town: Node) -> void:
	var lexicon = Lexicon.shared()
	town.hud.flash_quest_message(lexicon.phrase("app.graphics_back", lexicon.native))


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= SNAPSHOT_SECONDS:
		_elapsed = 0.0
		snapshot()
	if not _update_line.is_empty() and main.shop_panel.current_line() != _update_line:
		_update_line = {}  # another line took the box over: ask again later
	if _update_waiting and _update_line.is_empty():
		_update_check -= delta
		if _update_check <= 0.0:
			_update_check = 2.0
			_ask_update()


func _on_page_event(_args: Array) -> void:
	snapshot()
	# The profile's saved place too (player_place.gd), so a closed tab reopens near this spot.
	if is_instance_valid(main) and main.get("place_keeper") != null:
		main.place_keeper.save_now()
	# Mei's mahjong game at the table (mahjong_session.gd), so a closed tab can carry it on.
	var mahjong: Node = main.get_node_or_null("MahjongSession") if is_instance_valid(main) else null
	if mahjong != null:
		mahjong.save_now()


## Writes the resume note when the player stands on the ground on foot (not driving, seated,
## flying with noclip or in a minigame); otherwise the last such note stays.
func snapshot() -> void:
	if not is_instance_valid(main) or main.get("player") == null:
		return
	var player: CharacterBody3D = main.player
	if is_instance_valid(main.active_vehicle) or player.seated or player.noclip_enabled \
			or not player.is_on_floor() or bool(main.hud.in_minigame):
		return
	var note := {
		"profile": ProfileManager.shared().active_id,
		"x": player.global_position.x, "y": player.global_position.y, "z": player.global_position.z,
		"yaw": player.camera_yaw,
		"time": Time.get_unix_time_from_system(),
	}
	# The marker only while the page is not being left (the shell's bonLeaving: this call can
	# run just after its pagehide listener removed the marker).
	JavaScriptBridge.eval("try { localStorage.setItem('%s', %s); if (!window.bonLeaving) { localStorage.setItem('%s', '1'); } } catch (e) {}" % [STORE_KEY, JSON.stringify(JSON.stringify(note)), RUNNING_KEY], true)


# --- New builds ------------------------------------------------------------------------------

## A new build is installed and waiting: ask in the town when the player is free.
func offer_update() -> void:
	_update_waiting = true

## The question, unless something else has the player's attention (a line or card in the box,
## a minigame, the welcome tutorial, a vehicle).
func _ask_update() -> void:
	if not is_instance_valid(main) or main.shop_panel == null:
		return
	var panel = main.shop_panel
	if panel.is_dialogue_visible() or panel.is_quit_open() or panel.is_cart_visible() \
			or bool(main.hud.in_minigame) or is_instance_valid(main.active_vehicle):
		return
	var tutorial: Node = main.get_node_or_null("Tutorial")
	if tutorial != null and bool(tutorial.get("running")):
		return
	var lexicon = Lexicon.shared()
	_update_line = lexicon.native_line("app.update_ready")
	panel.show_dialogue(lexicon.line("app.title"), _update_line, [
		{"id": UPDATE_YES, "label": lexicon.native_line("app.update_now"), "icon": "check"},
		{"id": UPDATE_NO, "label": lexicon.native_line("common.reply_no"), "icon": "no"}])

func _on_update_choice(id: String) -> void:
	if id != UPDATE_YES and id != UPDATE_NO:
		return
	_close_update_line()
	if id == UPDATE_YES:
		update_now()

## The box's ✕ (or walking off) counts as "Not now".
func _on_update_closed() -> void:
	if not _update_line.is_empty() and main.shop_panel.current_line() == _update_line:
		_close_update_line()

## Not asked again this launch; the next launch uses the new build anyway.
func _close_update_line() -> void:
	main.shop_panel.hide_dialogue()
	_update_line = {}
	_update_waiting = false

## Keeps the spot (as for lost graphics) and switches to the waiting build.
func update_now() -> void:
	_on_page_event([])
	JavaScriptBridge.eval("try { sessionStorage.setItem('%s', '1'); } catch (e) {}" % RELOAD_FLAG, true)
	JavaScriptBridge.pwa_update()
