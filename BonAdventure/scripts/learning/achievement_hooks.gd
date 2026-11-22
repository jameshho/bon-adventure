extends RefCounted
## Reports the town's small activities to the achievement tracker (achievements.gd; guide:
## docs/guides/ACHIEVEMENTS.md#where-events-are-reported) and shows the unlock toasts.
##
## Two ways, both cheap:
##   install(main)  once: signals that already exist (the hand's picked_up, the tracker's
##                  unlocked -> the HUD toast).
##   tick(main)     four times a second (main.gd, with VehicleControls.update_home): player and
##                  vehicle STATES, noted on the change from off to on (sitting, lying, a swing,
##                  driving, flying the plane or the helicopter). No physics, no scans.
## Everything else is one line where it happens: Achievements.shared().note("<event>") (doors,
## taps, toilets, saving a word, the map, the guide arrow). A new activity: add it to
## data/achievements.json, its name to phrases.json achievements.<id>, and one note() call.
const Achievements := preload("res://scripts/learning/achievements.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
## Metres above its start pose at which a helicopter counts as flying.
const HELI_UP := 3.0

## The states seen at the last tick (event -> bool).
static var _was: Dictionary = {}

static func install(main) -> void:
	_was.clear()
	var tracker = Achievements.shared()
	var hand = main.player.get("hand") if main.player != null else null
	if hand != null and hand.has_signal("picked_up"):
		hand.picked_up.connect(func(_item) -> void: tracker.note("pick_up"))
	tracker.unlocked.connect(func(id: String, def: Dictionary) -> void: _toast(main, id, def))

static func _toast(main, id: String, def: Dictionary) -> void:
	if main == null or not is_instance_valid(main) or main.hud == null:
		return
	var tracker = Achievements.shared()
	var line := ""
	if def.group == "stamps":
		line = UiText.t("achievements.stamp_found", {"place": tracker.title(id),
				"n": tracker.unlocked_in("stamps"), "total": tracker.ids_in("stamps").size()})
	else:
		line = UiText.t("achievements.unlocked", {"name": tracker.title(id)})
	if int(def.get("xp", 0)) > 0:
		line += "  " + UiText.t("achievements.xp_gain", {"n": int(def.xp)})
	main.hud.flash_quest_message(line)

static func tick(main) -> void:
	var player = main.player
	if player == null:
		return
	var swing = main.seating.current_swing() if main.seating != null and main.seating.has_method("current_swing") else null
	var vehicle = main.active_vehicle if is_instance_valid(main.active_vehicle) else null
	var aircraft: bool = vehicle != null and vehicle.is_aircraft()
	_edge("sit_down", bool(player.seated) and not bool(player.lying) and swing == null)
	_edge("lie_down", bool(player.lying))
	_edge("swing", swing != null)
	_edge("drive_car", vehicle != null and not aircraft and vehicle.get("occupied") == true)
	_edge("fly_plane", vehicle != null and vehicle.get("fixed_wing") == true and vehicle.get("landed") == false)
	var heli_up := false
	if vehicle != null and vehicle.get("helicopter") == true:
		heli_up = vehicle.global_position.y - vehicle.start_pose().origin.y > HELI_UP
	_edge("fly_helicopter", heli_up)

## Notes `event` when `on` turns true (not again until it has been false).
static func _edge(event: String, on: bool) -> void:
	if on and not bool(_was.get(event, false)):
		Achievements.shared().note(event)
	_was[event] = on
