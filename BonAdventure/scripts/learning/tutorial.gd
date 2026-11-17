extends Node
## "Welcome to Bon Adventure", the welcome tutorial (PWA restructure phase 6, 12 Nov 2026; guide:
## docs/guides/ARCHITECTURE_REVIEW_PART1.md#welcome-tutorial). One director plays the steps of
## data/tutorial.json, once per profile: the player wakes on their bed, BonBon (the guide) shows
## the house and two hiding friends, the group shops for fruit (scripts/learning/tutorial_shop.gd)
## and walks to the park, where the player learns the word "statue" and opens the journal.
##
## Self-contained: it reuses the dialogue box (shop_order_panel.gd), the face camera
## (npc_presence.gd), the fade and placing (minigame_zone.gd), doors, the cart and money panels,
## and never changes or registers a minigame. While it runs the activity board's `hold` keeps
## every other NPC quiet (no "!", no game starts). Its cast are standing plushes of the house
## characters (house_characters.gd worker()); the seated house twins and the props in "hide" (the
## mahjong table, 14 Nov 2026) are hidden meanwhile.
## Words it teaches (shower curtain, the fruit, statue) are studied through the interaction
## controller's word_studied, so they reach the journal; nothing goes to the practice log.
##
## Word cards (clicking a plain object to learn its word) stay off until the park act's "words"
## step (user, 13 Nov 2026), so the house tour and the shop are not interrupted by cards. BonBon (the
## guide) is a TALK interactable throughout: E, a click or a tap on her while the player has
## something to do repeats where to go next (the step's "where" line, or the shop's phase).
##
## Right after waking (16 Nov 2026, user) BonBon teaches the two controls: turning the view
## (dragging) and walking (the joystick or W A S D). The wording follows the device (a step's
## "touch_line" / "touch_where" on a touch screen: hud.touch_mode), the matching control pulses
## (scripts/ui/tutorial_cue.gd; the joystick itself, touch_controls.gd highlight_stick()) and the
## step ends once the player has tried it, so it never blocks.
##
## Progress lives in the active profile ("tutorial": {"act", "done"}, profile_manager.gd), saved
## at the start of each act (the checkpoint). Skip ends it and puts the player outside the home;
## Settings' "Replay" starts it again (app.gd). Checks and tools that load main.tscn directly have
## no profile and never see it.
const DATA := "res://data/tutorial.json"
const NODE_NAME := "Tutorial"
const HOLD := "tutorial"
const NEXT := "tutorial_next"
## Metres per second the cast walks.
const WALK_SPEED := 1.8
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const HouseCharacters := preload("res://scripts/characters/house_characters.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const DoorAnimator := preload("res://scripts/core/door_animator.gd")
const NpcPresence := preload("res://scripts/learning/npc_presence.gd")
const MinigameZone := preload("res://scripts/learning/minigame_zone.gd")
const LoadingScreen := preload("res://scripts/ui/loading_screen.gd")
const TutorialShop := preload("res://scripts/learning/tutorial_shop.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const InteractIcons := preload("res://scripts/ui/interact_badge.gd")
const MinigameHost := preload("res://scripts/learning/minigame_host.gd")
const RenderCulling := preload("res://scripts/world/render_culling.gd")
const TutorialCue := preload("res://scripts/ui/tutorial_cue.gd")
const GOLD := Color("fff1c5")
const FILL := Color(0.08, 0.16, 0.22, 0.88)
const EDGE := Color("7abfb3")

signal finished(skipped: bool)

var main
var data: Dictionary = {}
var panel
var zone
var lexicon
var running := false
## The act being played (its checkpoint is saved).
var act := 0
## role ("guide", "friend_1", "friend_2") -> house character id, and -> its standing plush.
var cast: Dictionary = {}
var actors: Dictionary = {}
## Word keys studied since the tutorial started (word_studied).
var studied: Dictionary = {}
## The step being played (for checks and debugging).
var step: Dictionary = {}
var shop
## Increases when the tutorial stops: every await checks it and gives up when it changed.
var _run := 0
var _line: Dictionary = {}
var _next := false
var _closed := false
var _world: Node3D
var _cast_root: Node3D
var _faces: Dictionary = {}
var _hidden: Array = []
var _skip_layer: CanvasLayer
var _skip_button: Button
var _cutscene: CanvasLayer
## "confine" step: the player stays inside these world XZ rects (none = free); `_confine_line`
## flashes when the player is held back (at most every CONFINE_FLASH_MS).
var _confine: Array[Rect2] = []
var _confine_line := ""
var _confine_flashed := -100000
## "lock" step: doors whose interactable says the step's line instead of opening.
var _locked: Array = []
## Doors a "door" step opened (door_animator.gd); _stop() closes those still open.
var _opened: Array = []
## A wait step's "cue" (the control that pulses) and the hint step whose line it shows, kept to
## switch the wording when the device turns out to be a touch screen (the first touch).
var cue: Control
var _cue_layer: CanvasLayer
var _hint_spec: Dictionary = {}
var _hint_touch := false
const CONFINE_FLASH_MS := 2500
## Behind the loading screen (app.gd, 17 Nov 2026, user: the first dialogue boxes in the house
## lagged on the web): `covered` while the loading screen is still up. The act's first "place"
## step then puts the player and the cast in place at once (no fade) and sets `prepared`; the
## steps wait there until release(). Meanwhile app.gd draws warm_views() and warm_dialogue(), so
## the first close-ups, rooms and the dialogue box are ready (their shaders compiled) when play
## starts.
var covered := false
var prepared := false
## Cast members built so far, of `cast_total` (app.gd's loading bar while `covered`).
var cast_built := 0
var cast_total := 0
## Steps that may run while `covered` (nothing on screen, nothing for the player to read).
const COVERED_STEPS := ["place", "door", "lock", "confine", "words"]
## warm_views(): the look round each spot of the act, at about the follow camera's height.
const WARM_SPOT_HEADINGS := 4
const WARM_EYE_HEIGHT := 1.8
const WARM_SPOT_GAP := 1.5

## Starts the tutorial for Main's active profile when it has not finished it (or `restart`: from
## the beginning, Settings' Replay). Returns the director, or null when there is nothing to play.
## `covered`: the loading screen is still up (app.gd): play stops at the first place step until
## release().
static func begin(game, restart := false, covered := false) -> Node:
	var manager = ProfileManager.shared()
	if manager.active_id == "":
		return null
	var progress: Dictionary = manager.active_profile().get("tutorial", {})
	if not restart and bool(progress.get("done", false)):
		return null
	var director: Node = game.get_node_or_null(NODE_NAME)
	if director == null:
		director = load("res://scripts/learning/tutorial.gd").new()
		game.add_child(director)
		director.setup(game)
	director.covered = covered
	director.start(0 if restart else int(progress.get("act", 0)))
	return director

func setup(game) -> void:
	name = NODE_NAME
	# After the player moves each physics frame (the confine step holds it back).
	process_physics_priority = 100
	main = game
	panel = game.shop_panel
	lexicon = Lexicon.shared()
	data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	zone = MinigameZone.new()
	add_child(zone)
	zone.setup(game.player, game, "TutorialFade")
	_world = Node3D.new()
	_world.name = "TutorialCast"
	game.add_child(_world)
	panel.choice_pressed.connect(func(id: String) -> void:
		if id == NEXT:
			_next = true)
	panel.dialogue_closed.connect(func() -> void:
		# The box's ✕ only asks; the line's owner hides it (minigame_host.gd does the same).
		if running and not _line.is_empty() and panel.current_line() == _line:
			panel.hide_dialogue()
			_closed = true)
	game.interaction.word_studied.connect(func(key: String) -> void: studied[key] = true)
	_make_skip_button()
	_cue_layer = CanvasLayer.new()
	_cue_layer.name = "TutorialCueLayer"
	_cue_layer.layer = 59
	add_child(_cue_layer)
	cue = TutorialCue.new()
	_cue_layer.add_child(cue)

## Plays from act `from_act` (a checkpoint) to the end.
func start(from_act: int) -> void:
	if running:
		_stop()
	running = true
	_run += 1
	prepared = false
	act = clampi(from_act, 0, data.acts.size() - 1)
	studied.clear()
	_unlock_all()
	_confine.clear()
	main.interaction.word_filter = Callable()
	Board.shared().hold = HOLD
	main.interaction.word_cards = false
	main.interaction.clear_card()
	# Its word cards close by themselves (user, 14 Nov 2026); _stop() puts the default back.
	main.interaction.card_seconds = float(data.get("card_seconds", 0.0))
	for child in main.get_children():
		if child.has_method("end_activity"):
			child.end_activity()
	var run := _run
	await _cast_actors()
	if run != _run:
		return
	_skip_layer.visible = true
	_play(_run)

## Skip: ends the tutorial for this profile and puts the player outside the home.
func skip() -> void:
	if not running:
		return
	var spot: Dictionary = data.skip_to
	_stop()
	_save({"act": 0, "done": true})
	# A fade already running (a place step) ends first, and the player gets up from a bed or
	# seat (the stand-up movement would otherwise carry them back after placing).
	var ends := Time.get_ticks_msec() + 3000
	while (zone.fading or main.player.seated or main.player.sit_transition) and Time.get_ticks_msec() < ends:
		if main.player.seated and not main.player.sit_transition:
			main.seating.stand()
		await get_tree().process_frame
	await zone.fade_through(func() -> void: zone.place_player(_space(spot.space), _vec(spot.at), _look(spot.look)))
	finished.emit(true)

func _play(run: int) -> void:
	while act < data.acts.size():
		_save({"act": act, "done": false})
		if act == 0:
			_reset_props()
		for spec in data.acts[act].steps:
			step = spec
			if covered and not COVERED_STEPS.has(str(spec.do)):
				await _hold_until_released()
			await _do(spec)
			if run != _run:
				return
		act += 1
	_stop()
	_save({"act": 0, "done": true})
	finished.emit(false)

## Behind the loading screen: everything is in place; wait until app.gd lifts the screen.
func _hold_until_released() -> void:
	prepared = true
	await until(func() -> bool: return not covered)

## The loading screen is gone (app.gd): play on.
func release() -> void:
	covered = false

func _alive(run: int) -> bool:
	return run == _run and running and is_inside_tree()

## Waits until `test` is true (checked every frame); false when the tutorial stopped meanwhile.
func until(test: Callable) -> bool:
	var run := _run
	while _alive(run) and not test.call():
		await get_tree().process_frame
	return _alive(run)

# --- Steps ---------------------------------------------------------------------------------------

func _do(spec: Dictionary) -> void:
	match str(spec.do):
		"place":
			await _place(spec)
		"say":
			await say(_speaker(str(spec.who)), _text(spec), str(spec.who) if spec.get("face", false) else "")
		"hint":
			_hint_spec = spec
			_hint_touch = is_touch()
			hint(_speaker(str(spec.who)), _text(spec))
		"wait":
			await _wait(spec)
		"door":
			var door := _door(spec)
			if door != null and not main.doors[door].get("open", false):
				DoorAnimator.toggle(main, door)
				_opened.append(door)
		"walk":
			_walk(actors.get(str(spec.who)), spec)
		"cutscene":
			await _play_cutscene(str(spec.line))
		"words":
			main.interaction.word_cards = bool(spec.get("on", true))
			# "only": the one word key a click may open (the statue step, user 13 Nov 2026).
			var only := str(spec.get("only", ""))
			main.interaction.word_filter = (func(obj: Node3D) -> bool: return main.interaction.word_key(obj) == only) if only != "" else Callable()
		"lock":
			_lock(spec)
		"confine":
			_set_confine(spec)
		"shop":
			shop = TutorialShop.new()
			add_child(shop)
			shop.setup(self, data.shop)
			await shop.play()
			if is_instance_valid(shop):
				shop.queue_free()
			shop = null
		_:
			push_error("tutorial.json: unknown step '%s'" % spec.do)

## True on a touch screen (or after the first touch): steps then use their "touch_line" and
## "touch_where" phrases (16 Nov 2026).
func is_touch() -> bool:
	return bool(main.hud.touch_mode)

## A step's phrase id for `key` ("line", "where"): its "touch_" twin on a touch screen.
func phrase_id(spec: Dictionary, key: String) -> String:
	if is_touch() and spec.has("touch_" + key):
		return str(spec["touch_" + key])
	return str(spec.get(key, ""))

## The line of a say or hint step: native narration, or a line in the language being learned.
func _text(spec: Dictionary) -> Dictionary:
	var spec_line := phrase_id(spec, "line")
	var values := {}
	values["name"] = _speaker(str(spec.get("who", "")))
	if spec.get("learning", false):
		if spec.has("word"):
			values["word"] = lexicon.word(str(spec.word), lexicon.foreign)
		return lexicon.line(spec_line, values)
	if spec.has("word"):
		# The key word in the language being learned, coloured with its meaning (14 Nov 2026).
		values["word"] = {"learn": {"word": str(spec.word)}}
	return narration(spec_line, values)

## A line in the player's native language (the tutorial's own voice): the same text in both
## slots, so every Display Mode shows it; the box shows no reading or translation for it.
## {"learn": ...} values and `terms` are words in the language being learned, which the box
## colours and explains (Lexicon.native_line()).
func narration(id: String, values: Dictionary = {}, terms: Array = []) -> Dictionary:
	return lexicon.native_line(id, values, terms)

func _speaker(role: String) -> String:
	var id := str(cast.get(role, ""))
	return HouseCharacters.name_of(id) if id != "" else ""

## Shows `line` with a Next button and waits for it (or the box's ✕ or walking away). `face`:
## the role whose face the camera shows meanwhile.
func say(speaker: Variant, line: Dictionary, face := "", node: Node3D = null) -> void:
	_show(speaker, line, [{"id": NEXT, "label": narration("app.next"), "icon": "next"}])
	var presence := _face(face, node)
	if presence != null and not presence.is_zoomed():
		# The last close-up eases back first: a new one would take its camera as the one to
		# return to (npc_presence.gd keeps the camera that was current).
		var ends := Time.get_ticks_msec() + 800
		await until(func() -> bool: return get_viewport().get_camera_3d() == main.camera or Time.get_ticks_msec() > ends)
		if get_viewport().get_camera_3d() == main.camera:
			presence.zoom_to_face(true)
	await until(func() -> bool: return _next or _closed or not panel.is_dialogue_visible() or panel.current_line() != _line)
	if presence != null:
		presence.zoom_to_face(false)
	if panel.is_dialogue_visible() and panel.current_line() == _line:
		panel.hide_dialogue()

## Shows `line` without buttons; it stays while the player does what it asks.
func hint(speaker: Variant, line: Dictionary) -> void:
	_show(speaker, line, [])

func _show(speaker: Variant, line: Dictionary, choices: Array) -> void:
	_line = line
	_next = false
	_closed = false
	panel.show_dialogue(speaker, line, choices)

func _face(role: String, node: Node3D) -> Node:
	var target: Node3D = node if node != null else actors.get(role)
	if target == null:
		return null
	if not _faces.has(target):
		var presence := NpcPresence.new()
		add_child(presence)
		presence.setup(target, main.player)
		_faces[target] = presence
	return _faces[target]

func _wait(spec: Dictionary) -> void:
	var player: Node3D = main.player
	match str(spec.for):
		"stand":
			await until(func() -> bool: return not player.seated)
		"near":
			var point: Vector3
			if spec.has("who"):
				point = (actors[str(spec.who)] as Node3D).global_position
			else:
				point = _space(str(spec.space)).to_global(_vec(spec.at))
			await until(func() -> bool: return _flat(player.global_position, point) <= float(spec.radius))
		"door":
			var door := _door(spec)
			if door != null:
				await until(func() -> bool: return bool(main.doors[door].get("open", false)))
		"use":
			var node: Node = main.apartment.get_node_or_null(NodePath(str(data.get(str(spec.node), spec.node))))
			if node == null:
				push_error("tutorial: no node for %s" % spec.node)
				return
			# A door-registry node (door_animator.gd; the bathtub curtain): used = its state flips.
			if not main.doors.has(node):
				push_error("tutorial: %s is not in Main.doors" % spec.node)
				return
			var before := bool(main.doors[node].get("open", false))
			var ok: bool = await until(func() -> bool: return bool(main.doors[node].get("open", false)) != before)
			if ok and spec.has("study"):
				main.interaction.word_studied.emit(str(spec.study))
		"study":
			await until(func() -> bool: return studied.has(str(spec.word)))
		"view", "move":
			await _try_control(spec)
		"journal":
			var open := bool(spec.open)
			await until(func() -> bool: return main.hud.is_journal_open() == open)
			# Done asking: the hint leaves the open journal clear.
			if panel.is_dialogue_visible() and panel.current_line() == _line:
				panel.hide_dialogue()

## "view": waits until the player has turned the view by hand ("turn" radians, player
## look_turned: a mouse or finger drag) or zoomed ("zoom" metres of camera distance); "move":
## until they walked "distance" metres. The control pulses meanwhile (the step's "cue", default
## its "for"); a first touch switches BonBon's line to the touch wording. Done: the cue goes and
## the hint leaves the screen clear.
func _try_control(spec: Dictionary) -> void:
	var player: Node3D = main.player
	var kind := str(spec.for)
	var turned: float = player.look_turned
	var distance: float = player.camera_distance
	var from: Vector3 = player.global_position
	var shown := [is_touch()]
	_show_cue(str(spec.get("cue", kind)))
	await until(func() -> bool:
		if is_touch() != shown[0]:
			shown[0] = is_touch()
			_show_cue(str(spec.get("cue", kind)))
			if not _hint_spec.is_empty() and panel.is_dialogue_visible() and panel.current_line() == _line and _hint_touch != shown[0]:
				_hint_touch = shown[0]
				hint(_speaker(str(_hint_spec.who)), _text(_hint_spec))
		if kind == "view":
			return player.look_turned - turned >= float(spec.get("turn", 0.6)) or absf(player.camera_distance - distance) >= float(spec.get("zoom", 1.5))
		return not player.seated and _flat(player.global_position, from) >= float(spec.get("distance", 1.5)))
	_show_cue("")
	if panel.is_dialogue_visible() and panel.current_line() == _line:
		panel.hide_dialogue()

## Shows a control cue ("view", "move"; "" hides it): tutorial_cue.gd, and on a touch screen the
## joystick's own pulse for "move".
func _show_cue(what: String) -> void:
	if is_instance_valid(cue):
		cue.show_cue(what, is_touch())
	var stick := _touch_controls()
	if stick != null:
		stick.highlight_stick(what == "move")

func _touch_controls() -> Node:
	var ui: Node = main.hud.get("ui_root")
	var stick: Node = ui.get_node_or_null("TouchControls") if ui != null else null
	return stick if stick != null and stick.has_method("highlight_stick") else null

## The nearest door of a space to [x, z] (doors are registered in Main.doors).
func _door(spec: Dictionary) -> Node3D:
	var space := _space(str(spec.space))
	var at := Vector3(float(spec.at[0]), 0.0, float(spec.at[1]))
	var best: Node3D = null
	for door in main.doors:
		if not is_instance_valid(door) or not space.is_ancestor_of(door):
			continue
		var local: Vector3 = space.to_local(door.global_position)
		if best == null or _flat(local, at) < _flat(space.to_local(best.global_position), at):
			best = door
	return best

func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

# --- Locked doors and confining ---------------------------------------------------------------

## "lock": every door of the space (main.doors; not the shower curtains) except the ones named
## in "open" answers with the step's "line" instead of opening (user, 13 Nov 2026: the house tour
## only opens the rooms it uses). A later lock step replaces the list; _stop() unlocks all.
func _lock(spec: Dictionary) -> void:
	_unlock_all()
	if spec.get("off", false):
		return
	var space := _space(str(spec.get("space", "home")))
	var open: Array = spec.get("open", [])
	var line := str(spec.get("line", ""))
	for door in main.doors:
		if not is_instance_valid(door) or not space.is_ancestor_of(door):
			continue
		if str(main.doors[door].get("type", "")) == "curtain" or open.has(str(door.name)):
			continue
		var item: Node = Interactable.on(door)
		if item == null:
			continue
		item.on_check = func() -> Variant: return lexicon.phrase(line, lexicon.native) if line != "" else false
		_locked.append(item)

func _unlock_all() -> void:
	for item in _locked:
		if is_instance_valid(item):
			item.on_check = Callable()
	_locked.clear()

## "confine": "rects" ([x0, z0, x1, z1] in the space) the player must stay inside, or "hold":
## true (stay where they are: the statue step); neither = free again. "line" flashes when the
## player is held back.
func _set_confine(spec: Dictionary) -> void:
	_confine.clear()
	_confine_line = str(spec.get("line", ""))
	if spec.get("hold", false):
		var at: Vector3 = main.player.global_position
		_confine.append(Rect2(at.x, at.z, 0.0, 0.0))
		return
	var space := _space(str(spec.get("space", "world")))
	for r in spec.get("rects", []):
		var a: Vector3 = space.to_global(Vector3(float(r[0]), 0.0, float(r[1])))
		var b: Vector3 = space.to_global(Vector3(float(r[2]), 0.0, float(r[3])))
		_confine.append(Rect2(minf(a.x, b.x), minf(a.z, b.z), absf(b.x - a.x), absf(b.z - a.z)))

func _physics_process(_delta: float) -> void:
	if _confine.is_empty() or not running:
		return
	var player: Node3D = main.player
	var p := Vector2(player.global_position.x, player.global_position.z)
	var best := p
	var best_distance := INF
	for rect in _confine:
		var q := Vector2(clampf(p.x, rect.position.x, rect.end.x), clampf(p.y, rect.position.y, rect.end.y))
		var d := q.distance_squared_to(p)
		if d < best_distance:
			best_distance = d
			best = q
	if best_distance <= 0.000001:
		return
	player.global_position = Vector3(best.x, player.global_position.y, best.y)
	if player is CharacterBody3D:
		player.velocity = Vector3(0.0, player.velocity.y, 0.0)
	var now := Time.get_ticks_msec()
	if _confine_line != "" and now - _confine_flashed > CONFINE_FLASH_MS and best_distance > 0.0004:
		_confine_flashed = now
		main.hud.flash_quest_message(lexicon.phrase(_confine_line, lexicon.native))

# --- Places and the cast ---------------------------------------------------------------------

## "home" (or any unit: its site's local space), else "world" (world metres).
func _space(space_name: String) -> Node3D:
	if space_name == "world":
		return _world
	var site: Node3D = ModularTown.building(main.apartment, space_name)
	return site if site != null else _world

func _vec(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))

func _look(values: Array) -> Vector3:
	return Vector3(float(values[0]), 0.0, float(values[1]))

## Fades out, puts the player (at a spot, then on the bed beside it) and the cast in place,
## fades in.
func _place(spec: Dictionary) -> void:
	var space := _space(str(spec.space))
	if covered:
		# Behind the loading screen: no fade, then hold (the close-up waits for the screen to lift).
		_place_now(spec, space)
		await _hold_until_released()
		_open_on(spec)
		return
	var run := _run
	await zone.fade_through(func() -> void:
		# Skipped or replayed while the screen went dark: leave the player alone.
		if run != _run:
			return
		_place_now(spec, space)
		_open_on(spec))

func _place_now(spec: Dictionary, space: Node3D) -> void:
	if spec.has("player"):
		zone.place_player(space, _vec(spec.player.at), _look(spec.player.look))
	# Lying down needs the player beside the bed ("player" above).
	if spec.has("bed"):
		var bed := _bed(space, Vector3(float(spec.bed[0]), 0.0, float(spec.bed[1])))
		if bed != null:
			main.seating.sit_on(bed)
	for role in spec.get("cast", {}):
		var where: Dictionary = spec.cast[role]
		put(role, space.to_global(_vec(where.at)), space.global_basis * _look(where.look), bool(where.get("ground", true)))
		# A fixed close-up camera spot (npc_presence.gd meta talk_camera_at): the bathtub
		# friend's face is walled in, so the automatic one swung round to the side.
		var actor: Node3D = actors.get(role)
		if actor != null:
			if where.has("camera"):
				actor.set_meta("talk_camera_at", space.to_global(_vec(where.camera)))
			elif actor.has_meta("talk_camera_at"):
				actor.remove_meta("talk_camera_at")

## "open_on": the screen comes up already zooming in on that cast member's face (the opening:
## BonBon talking, not the player in bed; user, 14 Nov 2026). The next "say" step with "face" on
## the same role keeps that close-up and zooms back out after its line.
func _open_on(spec: Dictionary) -> void:
	if spec.has("open_on"):
		var presence := _face(str(spec.open_on), null)
		if presence != null:
			presence.zoom_to_face(true)

## Camera views the act will show up to its cutscene (app.gd draws them behind the loading
## screen, 17 Nov 2026): every cast member's face close-up, then a look round
## (WARM_SPOT_HEADINGS) from each spot of the act: the player's and the cast's places, the "wait"
## spots and the walks. Each view is {"transform": Transform3D, "fov": degrees}.
func warm_views() -> Array:
	var views: Array = []
	for role in actors:
		var presence := _face(role, null)
		if presence != null:
			views.append({"transform": presence.face_transform(), "fov": NpcPresence.FACE_FOV})
	var spots: Array[Vector3] = []
	for spec in data.acts[act].steps:
		if str(spec.do) == "cutscene":
			break
		var space := _space(str(spec.get("space", "world")))
		match str(spec.do):
			"place":
				if spec.has("player"):
					spots.append(space.to_global(_vec(spec.player.at)))
				for role in spec.get("cast", {}):
					spots.append(space.to_global(_vec(spec.cast[role].at)))
			"walk":
				for point in spec.path:
					spots.append(space.to_global(Vector3(float(point[0]), 0.0, float(point[1]))))
			"wait":
				if spec.has("at") and spec.has("space"):
					var at: Array = spec.at
					spots.append(space.to_global(_vec(at) if at.size() == 3 else Vector3(float(at[0]), 0.0, float(at[1]))))
	var kept: Array[Vector3] = []
	var fov: float = main.camera.fov
	for spot in spots:
		if kept.any(func(other: Vector3) -> bool: return _flat(other, spot) < WARM_SPOT_GAP):
			continue
		kept.append(spot)
		var eye := _ground(spot) + Vector3.UP * WARM_EYE_HEIGHT
		for i in WARM_SPOT_HEADINGS:
			var look := Vector3.FORWARD.rotated(Vector3.UP, TAU * float(i) / WARM_SPOT_HEADINGS)
			views.append({"transform": Transform3D(Basis.looking_at(look + Vector3.DOWN * 0.25, Vector3.UP), eye), "fov": fov})
	return views

## Shows the dialogue box with a Next button for a moment and hides it (app.gd, behind the
## loading screen): its first drawing (fonts at the box's size, styles, icons) happens then.
func warm_dialogue() -> void:
	panel.show_dialogue(_speaker("guide"), narration("tutorial.good_morning"), [{"id": NEXT, "label": narration("app.next"), "icon": "next"}])
	await get_tree().process_frame
	await get_tree().process_frame
	if _line.is_empty() or panel.current_line() != _line:
		panel.hide_dialogue()

func _bed(space: Node3D, at: Vector3) -> Node3D:
	var best: Node3D = null
	for node in space.get_children():
		if node is Node3D and str(node.get_meta("word_key", "")) == "bed":
			if best == null or _flat(node.position, at) < _flat(best.position, at):
				best = node
	return best

## Moves an actor to `spot` (its feet on the ground below, or exactly there without
## `on_ground`) looking along `facing` (global).
func put(role: String, spot: Vector3, facing: Vector3, on_ground := true) -> void:
	var actor: Node3D = actors.get(role)
	if actor == null:
		return
	var lift: float = actor.get_meta("tutorial_lift", 0.0)
	actor.global_position = (_ground(spot) if on_ground else spot) + Vector3.UP * lift
	var flat := Vector3(facing.x, 0, facing.z)
	if flat.length() > 0.01:
		actor.global_basis = Basis.looking_at(flat.normalized(), Vector3.UP)

## The ground (or floor, or bathtub) under `point`.
func _ground(point: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2.5, point + Vector3.DOWN * 6.0)
	query.exclude = [main.player.get_rid()]
	query.collision_mask = 1
	var hit: Dictionary = main.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else point

## Walks an actor along fixed waypoints (no navigation; the data keeps the way clear).
func _walk(actor: Node3D, spec: Dictionary) -> void:
	if actor == null:
		return
	var space := _space(str(spec.space))
	var lift: float = actor.get_meta("tutorial_lift", 0.0)
	var tween := actor.create_tween()
	var from := actor.global_position
	for point in spec.path:
		var to := _ground(space.to_global(Vector3(float(point[0]), 0.0, float(point[1])))) + Vector3.UP * lift
		var a := from
		tween.tween_callback(func() -> void:
			var way := Vector3(to.x - a.x, 0, to.z - a.z)
			if way.length() > 0.01:
				actor.global_basis = Basis.looking_at(way.normalized(), Vector3.UP))
		tween.tween_property(actor, "global_position", to, maxf(_flat(a, to) / WALK_SPEED, 0.05))
		from = to
	# "look": the way the walker turns once there (the whole body; a plush's Head is never turned).
	if spec.has("look"):
		var facing: Vector3 = space.global_basis * _look(spec.look)
		tween.tween_callback(func() -> void:
			actor.global_basis = Basis.looking_at(Vector3(facing.x, 0, facing.z).normalized(), Vector3.UP))

## Who plays each role: the guide and the friends of tutorial.json; a friend who is the player's
## avatar is replaced by the next house character (data order) not already in the cast.
func _cast_actors() -> void:
	var avatar := str(ProfileManager.shared().active_profile().get("avatar", ""))
	var everyone: Array = HouseCharacters.ids()
	cast = {"guide": str(data.guide)}
	var taken: Array = [str(data.guide), avatar] + Array(data.friends)
	for i in data.friends.size():
		var id := str(data.friends[i])
		if id == avatar:
			for other in everyone:
				if not taken.has(other):
					id = other
					taken.append(other)
					break
		cast["friend_%d" % (i + 1)] = id
	_clear_cast()
	_cast_root = Node3D.new()
	_cast_root.name = "Cast"
	_world.add_child(_cast_root)
	var maker := HouseCharacters.new()
	cast_built = 0
	cast_total = cast.size()
	for role in cast:
		# Behind the loading screen one plush per frame (each sculpts its meshes, about 0.7 s on a
		# first launch), so the bar moves between them.
		if covered and cast_built > 0:
			var run := _run
			await get_tree().process_frame
			if run != _run:
				return
		var id: String = cast[role]
		var spec: Dictionary = HouseCharacters.spec_of(id)
		var actor: Node3D = maker.worker(str(spec.scene), str(spec.get("costume", "")), "", _cast_root, role, Vector3.ZERO, Vector3.FORWARD)
		actor.remove_meta("word_key")
		actor.set_meta("character_name", str(spec.name))
		actor.set_meta("character_species", str(spec.get("species", "")))
		# worker() rests the plush's lowest point on the spot: keep that lift when moving it.
		actor.set_meta("tutorial_lift", actor.global_position.y)
		actors[role] = actor
		# Solid like every other character (user, 14 Nov 2026: NPCs you cannot walk past): the
		# town's figures get their blocker when they are placed, the cast is made later.
		HouseCharacters.fit_blocker(actor)
		_hide_twin(id)
		if role == "guide":
			_make_guide_talker(actor)
		cast_built += 1
	# Props out of the way while it runs (tutorial.json "hide": the mahjong table and its
	# players, user 14 Nov 2026); _clear_cast() brings them back.
	for path in data.get("hide", []):
		var prop := main.apartment.get_node_or_null(NodePath(str(path))) as Node3D
		if prop != null:
			_hide(prop)
		else:
			push_error("tutorial: no node %s to hide" % path)

## BonBon as the shared TALK interactable (interactable.gd; the same settings as a minigame
## host's talker, minigame_host.gd add_talker): available while where_line() has a line.
func _make_guide_talker(actor: Node3D) -> void:
	Interactable.attach(actor, {
		"kind": Interactable.Kind.TALK,
		"prompt_distance": MinigameHost.TALK_DISTANCE,
		"priority": 1.0,
		"badge_offset": Vector3(0, InteractIcons.head_height(actor), 0),
		"on_point": func(_from: Vector3) -> Vector3: return actor.global_position,
		"on_check": func() -> Variant: return where_line() != "",
		"on_use": _talk_to_guide,
	})

## The phrase id of where to go next while the player has something to do: the current wait
## step's "where" (tutorial.json), or the shop trip's phase (tutorial_shop.gd where()); "" while a
## line with a button, a fade or the cutscene plays.
func where_line() -> String:
	if not running or zone.fading or is_instance_valid(_cutscene):
		return ""
	match str(step.get("do", "")):
		"wait":
			return phrase_id(step, "where")
		"shop":
			return shop.where() if is_instance_valid(shop) else ""
	return ""

## BonBon turns to the player and says where to go next; the line stays up like a hint.
func _talk_to_guide() -> void:
	var id := where_line()
	var actor: Node3D = actors.get("guide")
	if id == "" or actor == null:
		return
	var way: Vector3 = main.player.global_position - actor.global_position
	way.y = 0.0
	if way.length() > 0.05:
		actor.global_basis = Basis.looking_at(way.normalized(), Vector3.UP)
	hint(_speaker("guide"), narration(id))

func _hide_twin(id: String) -> void:
	var twin := main.get_node_or_null("HouseCharacters/" + id) as Node3D
	if twin != null:
		_hide(twin)

## Hides `node` until _clear_cast(): not drawn (nor its render-batched copies), not solid, and its
## interactables (seats, talkers) are no candidates.
func _hide(node: Node3D) -> void:
	if not node.visible:
		return
	var layers := {}
	for body in node.find_children("*", "CollisionObject3D", true, false):
		layers[body] = body.collision_layer
		body.collision_layer = 0
	var items := {}
	for item in node.find_children("Interactable", "", true, false):
		if item.get("enabled") == true:
			items[item] = true
			item.enabled = false
	node.visible = false
	RenderCulling.show_batched(node, false)
	_hidden.append({"node": node, "layers": layers, "items": items})

func _clear_cast() -> void:
	for entry in _hidden:
		if is_instance_valid(entry.node):
			entry.node.visible = true
			RenderCulling.show_batched(entry.node, true)
			for body in entry.layers:
				if is_instance_valid(body):
					body.collision_layer = entry.layers[body]
			for item in entry.get("items", {}):
				if is_instance_valid(item):
					item.enabled = true
	_hidden.clear()
	for door in _opened:
		if is_instance_valid(door) and main.doors.has(door) and main.doors[door].get("open", false):
			DoorAnimator.toggle(main, door)
	_opened.clear()
	for presence in _faces.values():
		if is_instance_valid(presence):
			presence.zoom_to_face(false)
			presence.queue_free()
	_faces.clear()
	# The close-ups go now, not after their ease back: the player's camera shows.
	if is_instance_valid(main.camera) and get_viewport().get_camera_3d() != main.camera:
		main.camera.make_current()
	if is_instance_valid(_cast_root):
		_cast_root.queue_free()
	actors.clear()

## Act 1 needs the family bathtub's curtain drawn along its rail, hiding the tub (the home's own
## curtain, home_furnishing.gd; in door_animator.gd terms "open" = drawn, and it starts bunched
## at the wall).
func _reset_props() -> void:
	var curtain: Node = main.apartment.get_node_or_null(NodePath(str(data.get("curtain", ""))))
	if curtain != null and main.doors.has(curtain) and not main.doors[curtain].get("open", false):
		DoorAnimator.toggle(main, curtain)

# --- Cutscene, skip button, end ------------------------------------------------------------

## A few seconds of Bon Adventure: the loading screen's town pictures with the title over them.
## It is also the loading screen for the buildings the tutorial has not used yet (16 Nov 2026,
## user: app.gd _load_rest() adds Main's pending_units while it is up): it stays at least
## cutscene_seconds and until they are all in (at most cutscene_max_seconds), with the progress
## bar under the title while any are loading.
func _play_cutscene(title_id: String) -> void:
	_cutscene = LoadingScreen.new()
	add_child(_cutscene)
	var total := float(main.pending_units.size())
	_cutscene.show_title(lexicon.phrase(title_id, lexicon.native), total > 0.0)
	var started := Time.get_ticks_msec()
	var least: float = started + float(data.get("cutscene_seconds", 7.0)) * 1000.0
	var most: float = started + float(data.get("cutscene_max_seconds", 60.0)) * 1000.0
	await until(func() -> bool:
		var now := Time.get_ticks_msec()
		if total > 0.0 and is_instance_valid(_cutscene):
			_cutscene.set_progress(1.0 - main.pending_units.size() / total)
		return now >= most or (now >= least and main.pending_units.is_empty()))
	if is_instance_valid(_cutscene):
		_cutscene.finish()
	_cutscene = null

func _make_skip_button() -> void:
	_skip_layer = CanvasLayer.new()
	_skip_layer.name = "TutorialSkip"
	_skip_layer.layer = 60
	_skip_layer.visible = false
	add_child(_skip_layer)
	_skip_button = Button.new()
	_skip_button.focus_mode = Control.FOCUS_NONE
	_skip_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = FILL.lightened(0.12) if state != "normal" else FILL
		box.border_color = EDGE
		box.set_border_width_all(2)
		box.set_corner_radius_all(14)
		box.content_margin_left = 22
		box.content_margin_right = 22
		_skip_button.add_theme_stylebox_override(state, box)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color"]:
		_skip_button.add_theme_color_override(color_name, GOLD)
	_skip_button.pressed.connect(skip)
	_skip_layer.add_child(_skip_button)

func _process(_delta: float) -> void:
	if not _skip_layer.visible:
		return
	# Finger sized and scaled with the window (money_panel.gd's rule), top centre.
	var screen := get_viewport().get_visible_rect().size
	var f := clampf(minf(screen.y / 800.0, screen.x / 1100.0), 0.6, 3.0)
	_skip_button.text = lexicon.phrase("tutorial.skip", lexicon.native)
	_skip_button.add_theme_font_size_override("font_size", roundi(24 * f))
	_skip_button.custom_minimum_size = Vector2(150, 56) * f
	_skip_button.size = _skip_button.get_minimum_size()
	# Below the HUD clock; out of the way of the journal, map, help and Settings.
	_skip_button.position = Vector2((screen.x - _skip_button.size.x) * 0.5, 74.0 * f)
	_skip_button.visible = not (main.hud.is_journal_open() or main.hud.is_map_open() or main.hud.is_help_open() or main.settings_panel.visible)

## Ends the tutorial (skip or the last step): the cast leaves, the house twins come back, and
## everything it opened closes.
func _stop() -> void:
	running = false
	_run += 1
	if is_instance_valid(shop):
		shop.stop()
		shop.queue_free()
	shop = null
	if is_instance_valid(_cutscene):
		_cutscene.queue_free()
	_cutscene = null
	if not _line.is_empty() and panel.is_dialogue_visible() and panel.current_line() == _line:
		panel.hide_dialogue()
	_line = {}
	_hint_spec = {}
	_show_cue("")
	_clear_cast()
	_skip_layer.visible = false
	_unlock_all()
	_confine.clear()
	main.interaction.word_filter = Callable()
	Board.shared().hold = ""
	main.interaction.word_cards = true
	main.interaction.card_seconds = 0.0
	main.sync_player_controls()

func _save(progress: Dictionary) -> void:
	var manager = ProfileManager.shared()
	if manager.active_id != "":
		manager.update(manager.active_id, {"tutorial": progress})
