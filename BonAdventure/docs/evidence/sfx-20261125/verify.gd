extends SceneTree
## Sound effects (25 Nov 2026; guide docs/guides/VOICE.md "Sound effects"): the stamp coin, eight
## door kinds, the chapel bell and the Library Helper's right and wrong shelf. Checks every new cue
## (loads, QOA, mono, not looping, length, bus, positional or flat, source and licence), every
## cue's licence, every binding's script signal (no arguments) and cue, door_animator.gd's door
## kinds, the kinds baked into the police, warehouse, bank and restaurants scenes, and that a
## stamp coin added to the tree gets its signal bound. Vehicle engines (added 25 Nov 2026): the car,
## truck, helicopter and plane loops (forward loop, QOA, mono, positional), sound.gd's engine_cue()
## for every vehicle kind in the town, and the engine hooks in driveable_vehicle.gd and
## turboprop.gd. Silent: never plays a sound, never emits a
## bound signal, loads no town (the four unit scenes are instantiated, never added). Writes no
## files.
##   godot --headless --path . --script res://docs/evidence/sfx-20261125/verify.gd
const Sound := preload("res://scripts/core/sound.gd")
const DoorAnimator := preload("res://scripts/core/door_animator.gd")
const StampCoin := preload("res://scripts/world/stamp_coin.gd")

const DOOR_KINDS := ["room", "sliding", "cell", "locker", "cabinet", "safe", "vault", "glass"]
## cue -> [bus, positional, longest seconds]
const CUES := {
	"coin.stamp": ["UI", false, 1.0],
	"answer.correct": ["UI", false, 1.0],
	"answer.wrong": ["UI", false, 1.0],
	"bell.chapel": ["SFX", true, 4.05],
}
## unit scene -> [node name, expected kind]; a door scene's kind is its `sound`.
const BAKED := {
	"police": [["Holding cell", "cell"], ["Locker door", "locker"]],
	"warehouse": [["Cabinet hinge west", "cabinet"], ["Cabinet hinge east", "cabinet"]],
	"bank": [["Vault safe door", "safe"], ["Vault entrance", "vault"]],
	"restaurants": [["Pizza and Burger entrance", "glass"]],
}
## engine loop cue -> the vehicle kinds (driveable_vehicle.gd engine_kind()) it plays for.
const ENGINES := {
	"vehicle.engine": ["car", "taxi", "police car", "ambulance", "motorcycle", "van"],
	"vehicle.truck": ["truck", "bus", "school bus", "fire truck"],
	"vehicle.helicopter": ["helicopter"],
	"vehicle.plane": ["plane"],
}
## script -> signal -> cue (data/sounds.json bindings added 25 Nov 2026).
const BOUND := {
	"res://scripts/world/stamp_coin.gd": {"collected": "coin.stamp"},
	"res://scripts/world/chapel_bell.gd": {"rung": "bell.chapel"},
	"res://scripts/learning/library_session.gd": {"shelved_right": "answer.correct", "shelved_wrong": "answer.wrong"},
	"res://scripts/world/mystery_door.gd": {"opened": "door.room.open", "slammed": "door.room.close"},
}

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func _initialize() -> void:
	var sound = Sound.new()
	root.add_child(sound)
	await process_frame
	var expected := CUES.duplicate()
	for kind in DOOR_KINDS:
		for which in ["open", "close"]:
			expected["door.%s.%s" % [kind, which]] = ["SFX", true, 1.55]
	var bytes := 0
	for cue_id in expected:
		var want: Array = expected[cue_id]
		var cue: Dictionary = sound.cues.get(cue_id, {})
		check(not cue.is_empty(), cue_id + ": in the catalogue")
		check(str(cue.get("bus", "")) == want[0], "%s: on the %s bus" % [cue_id, want[0]])
		check(AudioServer.get_bus_index(want[0]) >= 0, "%s: bus %s exists" % [cue_id, want[0]])
		check(cue.has("distance") == want[1], "%s: %s" % [cue_id, "positional" if want[1] else "flat"])
		check(not bool(cue.get("loop", true)), cue_id + ": cue says no loop")
		check(str(cue.get("source", "")) != "" and str(cue.get("licence", "")) != "", cue_id + ": source and licence")
		var clip = sound.stream(cue_id)
		check(clip is AudioStreamWAV, cue_id + ": loads as AudioStreamWAV")
		if clip is AudioStreamWAV:
			check(clip.loop_mode == AudioStreamWAV.LOOP_DISABLED, cue_id + ": imported without a loop")
			check(clip.format == AudioStreamWAV.FORMAT_QOA, cue_id + ": imported as QOA")
			check(not clip.stereo, cue_id + ": mono")
			check(clip.get_length() > 0.2 and clip.get_length() <= want[2], "%s: %.2f s (at most %.2f)" % [cue_id, clip.get_length(), want[2]])
			bytes += clip.data.size()
	print("SFX: %d new cues, %.1f KB imported" % [expected.size(), bytes / 1024.0])
	for cue_id in sound.cues:
		var cue: Dictionary = sound.cues[cue_id]
		check(str(cue.get("licence", "")) != "", cue_id + ": every cue has a licence")
	# Bindings: each script has each signal (no arguments: the cue and node are bound after) and
	# each cue exists. A door is not bound: door_animator.gd plays it.
	for script_path in BOUND:
		check(sound.bindings.has(script_path), script_path + ": bound")
		var play: Dictionary = sound.bindings.get(script_path, {}).get("play", {})
		var script: Script = load(script_path)
		for signal_name in BOUND[script_path]:
			check(str(play.get(signal_name, "")) == BOUND[script_path][signal_name], "%s %s -> %s" % [script_path.get_file(), signal_name, BOUND[script_path][signal_name]])
			check(script.has_script_signal(signal_name), "%s has signal %s" % [script_path.get_file(), signal_name])
			for info in script.get_script_signal_list():
				if info["name"] == signal_name:
					check(info["args"].is_empty(), "%s %s has no arguments" % [script_path.get_file(), signal_name])
	for binding in sound.bindings.values():
		for kind in ["play", "start", "stop"]:
			for signal_name in binding.get(kind, {}):
				check(sound.cues.has(str(binding[kind][signal_name])), "binding cue %s exists" % binding[kind][signal_name])
	# Door kinds: the defaults and the override.
	check(DoorAnimator.sound_cue({"type": "hinge"}, true) == "door.room.open", "hinge door: room")
	check(DoorAnimator.sound_cue({"type": "hinge", "seconds": 3.2}, false) == "door.room.close", "heavy door without a kind: room")
	check(DoorAnimator.sound_cue({"type": "slide", "safe_slide": true}, false) == "door.sliding.close", "sliding door: sliding")
	check(DoorAnimator.sound_cue({"type": "slide"}, true) == "", "drawer: silent")
	check(DoorAnimator.sound_cue({"type": "curtain"}, true) == "", "curtain: silent")
	check(DoorAnimator.sound_cue({"type": "hinge", "sound": "none"}, true) == "", "sound none: silent")
	check(DoorAnimator.sound_cue({"type": "hinge", "sound": "locker"}, false) == "door.locker.close", "kind override")
	# The kinds baked into the unit scenes (instantiated, never added to the tree).
	for unit in BAKED:
		var scene: PackedScene = load("res://scenes/town/%s.scn" % unit)
		var top: Node = scene.instantiate()
		for pair in BAKED[unit]:
			var found := top.find_children(pair[0], "", true, false)
			check(not found.is_empty(), "%s: %s found" % [unit, pair[0]])
			for node in found:
				var kind := ""
				if node.has_meta("door_state"):
					kind = str(node.get_meta("door_state").get("sound", ""))
				elif "sound" in node:
					kind = str(node.sound)
				check(kind == pair[1], "%s: %s sounds %s (%s)" % [unit, pair[0], pair[1], kind])
		top.free()
	# Vehicle engines: forward loops, each vehicle kind finds its cue ("van" has none: the default).
	var engine_bytes := 0
	var defaults := 0
	for cue_id in ENGINES:
		var cue: Dictionary = sound.cues.get(cue_id, {})
		check(not cue.is_empty(), cue_id + ": in the catalogue")
		check(str(cue.get("bus", "")) == "SFX" and cue.has("distance"), cue_id + ": positional on SFX")
		check(bool(cue.get("loop", false)), cue_id + ": cue says loop")
		check(str(cue.get("source", "")) != "" and str(cue.get("licence", "")) != "", cue_id + ": source and licence")
		var tune: Dictionary = cue.get("engine", {})
		check(float(tune.get("pitch_top", 0.0)) > float(tune.get("pitch_idle", 9.0)), cue_id + ": pitch rises with speed")
		if bool(tune.get("default", false)):
			defaults += 1
		var clip = sound.stream(cue_id)
		check(clip is AudioStreamWAV, cue_id + ": loads as AudioStreamWAV")
		if clip is AudioStreamWAV:
			check(clip.loop_mode == AudioStreamWAV.LOOP_FORWARD, cue_id + ": imported as a forward loop")
			check(clip.format == AudioStreamWAV.FORMAT_QOA, cue_id + ": imported as QOA")
			check(not clip.stereo, cue_id + ": mono")
			check(clip.get_length() >= 0.5 and clip.get_length() <= 3.05, "%s: %.2f s loop" % [cue_id, clip.get_length()])
			engine_bytes += clip.data.size()
		for kind in ENGINES[cue_id]:
			check(sound.engine_cue(kind) == cue_id, "%s engine -> %s (%s)" % [kind, cue_id, sound.engine_cue(kind)])
	check(defaults == 1, "exactly one default engine (%d)" % defaults)
	print("SFX: %d engine loops, %.1f KB imported" % [ENGINES.size(), engine_bytes / 1024.0])
	var vehicle: Script = load("res://scripts/world/driveable_vehicle.gd")
	var plane: Script = load("res://scripts/world/turboprop.gd")
	for method in ["engine_kind", "engine_level", "engine_running", "update_engine_sound"]:
		check(_has_method(vehicle, method), "driveable_vehicle.gd has " + method)
	for method in ["engine_level", "engine_running"]:
		check(_own_method(plane, method), "turboprop.gd overrides " + method)
	# A stamp coin added to the tree is bound (its signal connected); nothing is emitted.
	var coin: Node3D = StampCoin.make("")
	root.add_child(coin)
	await process_frame
	check(coin.has_meta("sound_bound"), "stamp coin bound when added")
	check(coin.get_signal_connection_list("collected").size() == 1, "stamp coin's collected connected once")
	coin.queue_free()
	await process_frame
	check(not sound.is_playing(), "nothing plays in the check")
	check(sound.get_child_count() == 0, "no player made in the check")
	print("SFX CHECK: %d checks, %d failures" % [checks, failures])
	sound.queue_free()
	quit(1 if failures > 0 else 0)

func _has_method(script: Script, method: String) -> bool:
	for info in script.get_script_method_list():
		if info["name"] == method:
			return true
	return false

func _own_method(script: Script, method: String) -> bool:
	return script.source_code.contains("func %s(" % method)
