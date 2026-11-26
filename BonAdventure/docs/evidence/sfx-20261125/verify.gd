extends SceneTree
## Sound effects (25 Nov 2026; guide docs/guides/VOICE.md "Sound effects"): the stamp coin, eight
## door kinds, the chapel bell and the Library Helper's right and wrong shelf. Checks every new cue
## (loads, QOA, mono, not looping, length, bus, positional or flat, source and licence), every
## cue's licence, every binding's script signal (no arguments) and cue, door_animator.gd's door
## kinds, the kinds baked into the police, warehouse, bank and restaurants scenes, and that a
## stamp coin added to the tree gets its signal bound. Vehicle engines (added 25 Nov 2026): the car,
## truck, helicopter and plane loops (forward loop, QOA, mono, positional), sound.gd's engine_cue()
## for every vehicle kind in the town, and the engine hooks in driveable_vehicle.gd and
## turboprop.gd. Buttons (added 25 Nov 2026): the five button cues, the catalogue's kind map, the
## cue a BonStyle button of each kind gets (and an unstyled one: none), the meta override, and
## that a button added to the tree has its press hooked once (never pressed). Mahjong (added 25 Nov
## 2026): the tile, call (Cantonese, Polly) and win cues, the session's bindings, and whole hands
## played by four NPC players through mahjong_session.gd _on_game_changed() (the session is
## never added to the tree, so nothing is bound or played): its signals fire for the deal, the
## player's draws, every discard and each call, and a Mahjong call tucks the player's tray away.
## Silent: never plays a sound, never emits a
## bound signal, loads no town (the four unit scenes are instantiated, never added). Writes no
## files.
##   godot --headless --path . --script res://docs/evidence/sfx-20261125/verify.gd
const Sound := preload("res://scripts/core/sound.gd")
const DoorAnimator := preload("res://scripts/core/door_animator.gd")
const StampCoin := preload("res://scripts/world/stamp_coin.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")
const MahjongSession := preload("res://scripts/learning/mahjong_session.gd")
const MahjongGame := preload("res://scripts/learning/mahjong_game.gd")
const MahjongAI := preload("res://scripts/learning/mahjong_ai.gd")

const DOOR_KINDS := ["room", "sliding", "cell", "locker", "cabinet", "safe", "vault", "glass"]
## cue -> [bus, positional, longest seconds]
const CUES := {
	"coin.stamp": ["UI", false, 1.0],
	"answer.correct": ["UI", false, 1.0],
	"answer.wrong": ["UI", false, 1.0],
	"bell.chapel": ["SFX", true, 4.05],
	"ui.confirm": ["UI", false, 0.5],
	"ui.decline": ["UI", false, 0.5],
	"ui.tap": ["UI", false, 0.5],
	"ui.select": ["UI", false, 0.5],
	"ui.delete": ["UI", false, 0.5],
	"mahjong.discard": ["SFX", false, 0.5],
	"mahjong.draw": ["SFX", false, 0.5],
	"mahjong.shuffle": ["SFX", false, 2.3],
	"mahjong.win": ["SFX", false, 2.05],
	"mahjong.call.pung": ["SFX", false, 1.0],
	"mahjong.call.chow": ["SFX", false, 1.0],
	"mahjong.call.kong": ["SFX", false, 1.0],
	"mahjong.call.sik": ["SFX", false, 1.0],
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
	"res://scripts/learning/mahjong_session.gd": {"hand_dealt": "mahjong.shuffle", "tile_drawn": "mahjong.draw",
		"tile_discarded": "mahjong.discard", "called_pung": "mahjong.call.pung", "called_chow": "mahjong.call.chow",
		"called_kong": "mahjong.call.kong", "called_win": "mahjong.call.sik", "you_won": "mahjong.win"},
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
			check(clip.get_length() > 0.03 and clip.get_length() <= want[2], "%s: %.2f s (at most %.2f)" % [cue_id, clip.get_length(), want[2]])
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
	# Buttons: every kind's cue exists; each BonStyle kind gets its cue; an unstyled button none.
	for kind in sound.button_kinds:
		check(sound.cues.has(str(sound.button_kinds[kind])), "button kind %s -> %s exists" % [kind, sound.button_kinds[kind]])
	var made: Array = []
	for pair in [["primary", "ui.confirm"], ["back", "ui.decline"], ["danger", "ui.delete"], ["minor", "ui.tap"],
			["soft", "ui.tap"], ["soft_quiet", "ui.tap"], ["quiet", "ui.tap"]]:
		var styled: Button = BonStyle.button("x", pair[0], "", 1.0)
		made.append(styled)
		check(sound.button_cue(styled) == pair[1], "%s button -> %s (%s)" % [pair[0], pair[1], sound.button_cue(styled)])
	var tile: Button = BonStyle.tile(null, "x", false, 1.0)
	var toggle := Button.new()
	BonStyle.style_toggle(toggle, 1.0)
	var box := CheckBox.new()
	BonStyle.style_check(box, 1.0)
	var pick := OptionButton.new()
	BonStyle.style_option(pick, 1.0)
	for node in [tile, toggle, box, pick]:
		made.append(node)
		check(sound.button_cue(node) == "ui.select", "%s -> ui.select (%s)" % [node.get_class(), sound.button_cue(node)])
	var plain := Button.new()
	made.append(plain)
	check(sound.button_cue(plain) == "", "an unstyled button is silent")
	var no_choice: Button = BonStyle.button("x", "minor", "", 1.0)
	no_choice.set_meta("sound", "ui.decline")
	made.append(no_choice)
	check(sound.button_cue(no_choice) == "ui.decline", "meta sound overrides the kind")
	var hushed: Button = BonStyle.button("x", "primary", "", 1.0)
	hushed.set_meta("sound", "none")
	made.append(hushed)
	check(sound.button_cue(hushed) == "", "meta sound none is silent")
	var shop: Script = load("res://scripts/ui/shop_order_panel.gd")
	check(shop.source_code.contains('button.set_meta("sound", "ui.decline")'), "the dialogue's 'no' choice declines")
	var hooked: Button = BonStyle.button("x", "primary", "", 1.0)
	root.add_child(hooked)
	await process_frame
	check(hooked.has_meta("sound_button") and hooked.get_signal_connection_list("pressed").size() >= 1, "a button added to the tree has its press hooked")
	sound._bind(hooked)
	var to_sound := 0
	for info in hooked.get_signal_connection_list("pressed"):
		if info["callable"].get_object() == sound:
			to_sound += 1
	check(to_sound == 1, "hooked once (%d)" % to_sound)
	hooked.free()
	for node in made:
		node.free()
	# Mahjong: whole NPC hands through the session's change watcher (never in the tree).
	_mahjong_hands()
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

## Plays hands with four NPC players (any fan, so they end sooner) through a session that is not
## in the tree, counting its sound signals; a stub panel records the tray tucking away.
func _mahjong_hands() -> void:
	var stub := GDScript.new()
	stub.source_code = "extends Node\nvar hidden := false\nfunc set_hand_hidden(h: bool) -> void:\n\thidden = h\n"
	stub.reload()
	var counts := {}
	var wins := 0
	var tucked := 0
	for seed in 12:
		var session = MahjongSession.new()
		var panel: Node = stub.new()
		session.panel = panel
		for signal_name in ["hand_dealt", "tile_drawn", "tile_discarded", "called_pung", "called_chow", "called_kong", "called_win"]:
			session.connect(signal_name, func() -> void: counts[signal_name] = int(counts.get(signal_name, 0)) + 1)
		var g = MahjongGame.new()
		session.game = g
		session._seen = session._snapshot()
		g.changed.connect(session._on_game_changed)
		var rng := RandomNumberGenerator.new()
		rng.seed = 900 + seed
		var draws_before := int(counts.get("tile_drawn", 0))
		g.start(rng, seed % 4, 0)
		check(int(counts.get("tile_drawn", 0)) == draws_before, "the deal makes no draw sound (hand %d)" % seed)
		for i in 3000:
			if g.phase == "over":
				break
			_mahjong_step(g)
		check(g.phase == "over", "mahjong hand %d ends" % seed)
		if int(g.result.get("winner", -1)) >= 0:
			wins += 1
			if panel.hidden:
				tucked += 1
		else:
			check(not panel.hidden, "a drawn hand leaves the tray (hand %d)" % seed)
		panel.free()
		session.free()
	print("SFX MAHJONG: %s, %d wins" % [counts, wins])
	check(int(counts.get("tile_discarded", 0)) > 100, "discards sound (%d)" % int(counts.get("tile_discarded", 0)))
	check(int(counts.get("tile_drawn", 0)) > 10, "the player's draws sound (%d)" % int(counts.get("tile_drawn", 0)))
	check(int(counts.get("tile_drawn", 0)) < int(counts.get("tile_discarded", 0)) / 2, "only the player's draws sound")
	check(int(counts.get("called_pung", 0)) + int(counts.get("called_chow", 0)) + int(counts.get("called_kong", 0)) > 0, "calls sound")
	check(int(counts.get("called_win", 0)) == wins and wins > 0, "every win calls (%d of %d)" % [int(counts.get("called_win", 0)), wins])
	check(tucked == wins, "a Mahjong call tucks the tray away (%d of %d)" % [tucked, wins])

func _mahjong_step(g) -> void:
	match str(g.phase):
		"turn":
			var action := MahjongAI.turn_action(g, g.turn)
			match str(action.type):
				"win": g.declare_self_win(g.turn)
				"kong": g.declare_kong(g.turn, int(action.tile))
				_: g.discard(g.turn, int(action.tile))
		"claim":
			for seat in g.waiting.keys():
				g.respond(seat, MahjongAI.claim_answer(g, seat, g.waiting[seat]))
