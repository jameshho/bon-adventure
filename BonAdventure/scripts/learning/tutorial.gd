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
## The tutorial script of 17 Nov 2026 (user; data/tutorial.json, phrases tutorial.*): BonBon's lines
## are separate bubbles that move on by themselves after a reading time with a 0.6 s pause between
## them (LINE_GAP; a click, a tap, E or Enter moves on at once) and hold the player meanwhile;
## what the player must DO shows in the instruction strip (scripts/ui/instruction_strip.gd), not in
## a bubble. Controls come one at a time ("controls" step: only E, then turning the view, then
## walking too). The two hiding friends are found in either order ("find" step; hints only when
## the player talks to BonBon, progressive and pointing at a friend not yet found); the shower
## curtain opens by dragging it. In the house only the hiding friend's door opens (review of
## 17 Nov 2026: the others are locked and BonBon says her friends would not hide there). The town reveal has a subtitle and can be skipped, and the park
## act ends with a picnic (a blanket and the bought food) before free exploration.
##
## Review of 17 Nov 2026 (user, evening): BonBon's lines are shown in a face close-up whenever she
## is near and standing still (consecutive lines keep the close-up); "Ready for an adventure?"
## waits for a "Yes!" and each friend's greeting for a reply; the shower curtain opens with E; the
## EN button (hold: every line and sign in the native language, the one language toggle) and the
## journal button stay hidden until the tutorial introduces them, and pulse then; the minigame
## picker is hidden and only doors and BonBon can be used (other doors say they are not the right
## place); it starts at noon; BonBon walks at the player's walking speed. The town reveal stays
## up until every building is in and the later acts' views are drawn behind it (the market and
## park acts lagged when it was skipped early), and only then can be skipped.
##
## Progress lives in the active profile ("tutorial": {"act", "done"}, profile_manager.gd), saved
## at the start of each act (the checkpoint). Skip ends it and puts the player outside the home;
## Settings' "Replay" starts it again (app.gd). Checks and tools that load main.tscn directly have
## no profile and never see it.
const DATA := "res://data/tutorial.json"
const NODE_NAME := "Tutorial"
const HOLD := "tutorial"
const NEXT := "tutorial_next"
## Metres per second the cast walks when there is no player to match (user, 17 Nov 2026: BonBon
## walks at the player's walking speed, _walk_speed()).
const WALK_SPEED := 1.8
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
const HouseCharacters := preload("res://scripts/characters/house_characters.gd")
const PlushCostume := preload("res://scripts/characters/plush_costume.gd")
const ModularTown := preload("res://scripts/world/modular_town.gd")
const DoorAnimator := preload("res://scripts/core/door_animator.gd")
const NpcPresence := preload("res://scripts/learning/npc_presence.gd")
const ShopDialogue := preload("res://scripts/learning/shop_dialogue.gd")
const MinigameZone := preload("res://scripts/learning/minigame_zone.gd")
const LoadingScreen := preload("res://scripts/ui/loading_screen.gd")
const TutorialShop := preload("res://scripts/learning/tutorial_shop.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const InteractIcons := preload("res://scripts/ui/interact_badge.gd")
const MinigameHost := preload("res://scripts/learning/minigame_host.gd")
const RenderCulling := preload("res://scripts/world/render_culling.gd")
const TutorialCue := preload("res://scripts/ui/tutorial_cue.gd")
const TapHint := preload("res://scripts/ui/tap_hint.gd")
const InstructionStrip := preload("res://scripts/ui/instruction_strip.gd")
const ShoppingBasket := preload("res://scripts/world/shopping_basket.gd")
const BonStyle := preload("res://scripts/ui/bon_style.gd")
## Dialogue pacing (user, 17 Nov 2026): a bubble stays READ_BASE + READ_PER_CHAR per character
## (clamped to READ_MIN..READ_MAX seconds), then LINE_GAP seconds before the next one.
const LINE_GAP := 0.6
## Seconds after a close-up's pan to the next speaker before that speaker's box shows (user, 21 Nov
## 2026: "a slight delay after the camera pan").
const PAN_BOX_DELAY := 0.25
const READ_BASE := 1.4
const READ_PER_CHAR := 0.055
const READ_MIN := 2.2
const READ_MAX := 8.0
## A remark (a door, a wrong item, an answer when asked) stays its reading time plus this.
const REMARK_EXTRA := 1.5
## BonBon's lines are in a close-up only when she is this near the player (metres) and not walking.
const GUIDE_FACE_RANGE := 8.0
## The tutorial's close-ups are closer and lower than a minigame's (user, 20 Nov 2026; npc_presence.gd
## FACE_DISTANCE 3.6 m and FACE_ELEVATION 18 degrees there).
const FACE_DISTANCE := 2.8
const FACE_ELEVATION := 8.0
## The choice id of a say step's "reply" button (the player's answer moves the line on).
const REPLY := "tutorial_reply"
## The time the tutorial starts at (minutes after midnight; user 17 Nov 2026: always noon).
const START_MINUTES := 720.0
## The cutscene can be skipped after this many seconds (a click still in flight does not skip it).
const CUTSCENE_SKIP_AFTER := 1.0
## The title cutscene's bar: the buildings coming in fill it to here, the later acts' views the rest.
const CUTSCENE_UNITS_SHARE := 0.8

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
## The window scale the Skip button was last styled for.
var _skip_scale := 0.0
var _cutscene: CanvasLayer
## "confine" step: the player stays inside these world XZ rects (none = free); `_confine_line`
## flashes when the player is held back (at most every CONFINE_FLASH_MS).
var _confine: Array[Rect2] = []
var _confine_line := ""
var _confine_flashed := -100000
## "lock" step: doors whose interactable says the step's line instead of opening ({"item", "use":
## its own on_use, given back by _unlock_all()}).
var _locked: Array = []
## Doors a "door" step opened (door_animator.gd); _stop() closes those still open.
var _opened: Array = []
## A wait step's "cue" (the control that pulses) and the hint step whose line it shows, kept to
## switch the wording when the device turns out to be a touch screen (the first touch).
var cue: Control
## "Click this" on a 3D object (tap_hint.gd; the shop's apple, 21 Nov 2026).
var tap_hint: Control
var _cue_layer: CanvasLayer
var _hint_spec: Dictionary = {}
var _hint_touch := false
## The instruction strip and what it shows ({"spec", "key", "note", "values", "touch"}; {} = none).
var strip
var _strip_spec: Dictionary = {}
## "controls" step: {"look", "move", "use"} (missing = allowed). _speaking holds all three while a
## line is read.
var _gate: Dictionary = {}
var _speaking := false
var _pausing := false
var _advance := false
var _said_end_ms := -100000
var _skip_cutscene := false
## "find" step: the spec, the roles found, how often BonBon was asked since the last find, and
## the curtain's state when the hunt started (it opens with E: _lock_curtain()).
var _find_spec: Dictionary = {}
var found: Dictionary = {}
var _hint_asks := 0
var _curtain_start := false
## A "say" lock step's line during the hunt (the guide's bubble at a locked door).
var _remark_line := ""
## The face close-up kept on from one line to the next (the next step is the same speaker's).
var _held_face: Node
var _keep_face := false
## A line waiting for the player's reply button, and whether it was pressed.
var _awaiting_reply := false
var _replied := false
## The EN button was introduced (the first friend found), so it shows from then on.
var _peek_introduced := false
## A line waiting for the player to hold EN before its reply button shows (the EN introduction).
var _need_peek := false
var _peek_watch: Callable = Callable()
## The strip of the EN introduction ("{badge}": the EN button's own label).
const PEEK_STRIP := {"line": "tutorial.ui_hold_en", "touch_line": "tutorial.ui_hold_en_touch"}
## The lock step in force (re-applied when buildings come in: _process()) and the doors seen then.
var _lock_spec: Dictionary = {}
var _lock_seen := 0
## The picnic (blanket and basket) of a place step's "picnic"; removed when the tutorial ends.
var _picnic: Node3D
## After the last step (tutorial.json "after"): the blanket with the guide and friends seated round
## it (_leave_party()), and how often each role was talked to (its next line).
var _party: Node3D
var _party_turns: Dictionary = {}
## Seated party members: their seat this far above the ground's collider (on the blanket's top,
## 0.13 m up plus its 3 cm) and their back this far behind the seat point.
const PARTY_SEAT_LIFT := 0.16
const PARTY_BACK := 0.25
## The picnic blanket (metres, across x by along z before turning): 2.5 times the first one's
## 2.4 x 1.9 m (user, 21 Nov 2026: room for everyone round it), and its checks per side, so each
## check stays the same size.
const PICNIC_SIZE := Vector2(6.0, 4.75)
const PICNIC_CHECKS := Vector2(67.5, 35.0)
## actor -> its walk's Tween (_walk(); put() stops it).
var _walks: Dictionary = {}
const CONFINE_FLASH_MS := 2500
## The Skip button's top edge (pixels at scale 1): where the HUD clock is, which the tutorial hides.
const SKIP_TOP := 10.0
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
			_next = true
		elif id == REPLY:
			_replied = true)
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
	tap_hint = TapHint.new()
	_cue_layer.add_child(tap_hint)
	strip = InstructionStrip.new()
	# Below the Skip button (74 + 56 px at scale 1).
	strip.top = 142.0
	strip.hidden_when = func() -> bool:
		return not running or zone.fading or is_instance_valid(_cutscene) or main.hud.is_journal_open() or main.hud.is_map_open() \
			or main.hud.is_help_open() or main.settings_panel.visible or main.money_panel.visible
	add_child(strip)

## Plays from act `from_act` (a checkpoint) to the end.
func start(from_act: int) -> void:
	if running:
		_stop()
	# A replay starts without the picnic party of the last run (_leave_party()).
	_clear_party()
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
	# Only doors (and the shower curtain) and BonBon can be used meanwhile: no seats, faucets,
	# vehicles or stations (user, 17 Nov 2026).
	main.interaction.interact_filter = func(item: Node) -> bool:
		var owner_node: Node = item.get_parent()
		return main.doors.has(owner_node) or owner_node == actors.get("guide")
	# The EN button comes with the first friend's greeting (act 1), the journal button with the
	# journal step; the minigame picker and the Run button stay hidden, and running is off (user,
	# 17 Nov 2026: the player walks at the cast's pace).
	_peek_introduced = act > 0
	main.hud.tutorial_hidden = {"picker": true, "map": true, "run": true, "peek": not _peek_introduced, "journal": true}
	main.hud.tutorial_pulse = {}
	# No ✕ on the dialogue box (its lines move on by themselves) and no clock (user, 18 Nov 2026).
	panel.closable = false
	# Nor the box's tail (user, 20 Nov 2026).
	panel.tail = false
	_hide_clock(true)
	# The shower curtain stays shut until the hunt (_find()).
	_lock_curtain(act == 0)
	if main.get("day_night") != null:
		main.day_night.set_time(START_MINUTES)
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
		var steps: Array = data.acts[act].steps
		for i in steps.size():
			var spec: Dictionary = steps[i]
			step = spec
			if covered and not COVERED_STEPS.has(str(spec.do)):
				await _hold_until_released()
			# A close-up kept from the last line stays for the next line with a face: the same
			# speaker's, or the camera cuts to the next speaker (say(); user, 18 Nov 2026).
			var role := _say_face(spec)
			if is_instance_valid(_held_face) and role == "":
				_release_face()
			_keep_face = role != "" and i + 1 < steps.size() and _say_face(steps[i + 1]) != ""
			await _do(spec)
			if run != _run:
				return
		act += 1
	# Played to the end (not skipped): the guide and friends stay at the picnic (_leave_party()).
	await _leave_party(run)
	if run != _run:
		return
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
			var reply: Dictionary = narration(str(spec.reply)) if spec.has("reply") else {}
			# "face": "always": the close-up even when the speaker is far (user, 17 Nov 2026: BonBon
			# in the living room after the friends are found).
			await say(_speaker(str(spec.who)), _text(spec), _say_face(spec), null, reply, str(spec.get("face", "")) == "always", float(spec.get("seconds", 0.0)))
		"hint":
			_hint_spec = spec
			_hint_touch = is_touch()
			hint(_speaker(str(spec.who)), _text(spec))
		"wait":
			if spec.has("strip"):
				show_strip(spec, "strip")
			await _wait(spec)
			if _strip_spec.get("spec") == spec:
				clear_strip()
		"controls":
			# Which controls work (user, 17 Nov 2026): first only E, then turning the view, then
			# walking too; a step without keys gives everything back.
			_gate = spec.duplicate()
			_apply_gate()
		"strip":
			if spec.get("off", false):
				clear_strip()
			else:
				show_strip(spec)
		"pause":
			await _pause(float(spec.get("seconds", 1.0)), false)
		"find":
			await _find(spec)
		"door":
			var door := _door(spec)
			if door != null and not main.doors[door].get("open", false):
				DoorAnimator.toggle(main, door)
				_opened.append(door)
		"walk":
			_walk(actors.get(str(spec.who)), spec)
		"cutscene":
			await _play_cutscene(str(spec.line), str(spec.get("subtitle", "")))
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

## Shows `line` as one bubble and waits while it is read (reading_seconds()), or until a click,
## tap, E or Enter moves on (_input()), the box's ✕ or another line takes the box. A line right
## after another first waits LINE_GAP seconds with the box empty (user, 17 Nov 2026). The player
## is held meanwhile (no walking, turning or using). `face`: the role whose face the camera shows
## ("guide" only while she is near and standing: _guide_face_ok()). `reply` (a line): a button
## with it, and the line waits for that button instead of moving on (user, 17 Nov 2026).
## `always`: the guide's close-up even when she is far from the player. `seconds` > 0: the line
## stays exactly that long instead of its reading time (a say step's "seconds", user 18 Nov 2026).
## A close-up kept from the line before (_held_face) cuts straight to this speaker's face, never
## through the player's view (user, 18 Nov 2026).
func say(speaker: Variant, line: Dictionary, face := "", node: Node3D = null, reply: Dictionary = {}, always := false, seconds := 0.0) -> void:
	var run := _run
	var keep := _keep_face
	_keep_face = false
	if face == "guide" and node == null and not always and not _guide_face_ok():
		face = ""
	if Time.get_ticks_msec() - _said_end_ms < 250:
		await _pause(LINE_GAP)
		if run != _run:
			return
	_speaking = true
	_apply_gate()
	_replied = false
	_awaiting_reply = not reply.is_empty()
	var choices: Array = [{"id": REPLY, "label": reply, "icon": "next"}] if _awaiting_reply else []
	# The reply waits for the EN introduction (_introduce_peek()); EN may be held while the camera
	# still eases to the face, so the button comes back below whenever it was held back here.
	var withheld := _need_peek and not choices.is_empty()
	var presence := _face(face, node)
	if presence != null and presence != _held_face and is_instance_valid(_held_face) and _held_face.is_zoomed():
		presence.cut_from(_held_face)
		_held_face = null
		# The box comes once the pan has ended and a short beat after (user, 21 Nov 2026).
		await _pause(NpcPresence.PAN_SECONDS + PAN_BOX_DELAY, false)
		if run != _run:
			return
	_show(speaker, line, [] if _need_peek else choices)
	_advance = false
	if presence != _held_face:
		_release_face()
	if presence != null and not presence.is_zoomed():
		# The last close-up eases back first: a new one would take its camera as the one to
		# return to (npc_presence.gd keeps the camera that was current).
		var ends := Time.get_ticks_msec() + 800
		await until(func() -> bool: return get_viewport().get_camera_3d() == main.camera or Time.get_ticks_msec() > ends)
		if get_viewport().get_camera_3d() == main.camera:
			presence.zoom_to_face(true)
	if withheld:
		# The EN introduction: the reply comes once EN was held (_introduce_peek()).
		await until(func() -> bool: return not _need_peek or _closed or not panel.is_dialogue_visible() or panel.current_line() != _line)
		if run == _run and not _closed and panel.is_dialogue_visible() and panel.current_line() == _line:
			_show(speaker, line, choices)
		_replied = false
	if _awaiting_reply:
		await until(func() -> bool: return _replied or _closed or not panel.is_dialogue_visible() or panel.current_line() != _line)
	else:
		var read_until := Time.get_ticks_msec() + int((seconds if seconds > 0.0 else reading_seconds(line)) * 1000.0)
		await until(func() -> bool: return _advance or _closed or Time.get_ticks_msec() >= read_until or not panel.is_dialogue_visible() or panel.current_line() != _line)
	_awaiting_reply = false
	if presence != null:
		if keep and run == _run:
			_held_face = presence
		else:
			presence.zoom_to_face(false)
	if panel.is_dialogue_visible() and panel.current_line() == _line:
		panel.hide_dialogue()
	_speaking = false
	_advance = false
	_said_end_ms = Time.get_ticks_msec()
	if run == _run:
		_apply_gate()

## The role whose close-up a say step shows: its "face", or BonBon's own lines whenever she can be
## shown (user, 17 Nov 2026: zoom in on her so the player reads her lines); "" = none.
func _say_face(spec: Dictionary) -> String:
	if str(spec.get("do", "")) != "say":
		return ""
	var who := str(spec.get("who", ""))
	if spec.get("face", false) or (who == "guide" and _guide_face_ok()):
		return who
	return ""

## BonBon can be shown in a close-up: she is within GUIDE_FACE_RANGE of the player and not walking.
func _guide_face_ok() -> bool:
	var actor: Node3D = actors.get("guide")
	if actor == null or not running:
		return false
	var walk: Tween = _walks.get(actor)
	if walk != null and walk.is_valid() and walk.is_running():
		return false
	return _flat(actor.global_position, main.player.global_position) <= GUIDE_FACE_RANGE

## Ends a close-up kept on from the last line.
func _release_face() -> void:
	if is_instance_valid(_held_face):
		_held_face.zoom_to_face(false)
	_held_face = null

## Seconds a bubble stays: its length (a line in the language being learned also counts half its
## translation), clamped.
static func reading_seconds(line: Dictionary) -> float:
	var chars := str(line.get("foreign", "")).length()
	if not line.get("narration", false):
		chars += int(str(line.get("native", "")).length() * 0.5)
	return clampf(READ_BASE + chars * READ_PER_CHAR, READ_MIN, READ_MAX)

## Waits `seconds`; `skippable`: a click, tap or key ends it at once (the gap between bubbles).
func _pause(seconds: float, skippable := true) -> void:
	_advance = false
	_pausing = skippable
	var ends := Time.get_ticks_msec() + int(seconds * 1000.0)
	await until(func() -> bool: return (skippable and _advance) or Time.get_ticks_msec() >= ends)
	_pausing = false
	_advance = false

## A short bubble that does not hold the player or the steps (a door BonBon has no use for, a
## wrong item, her answer when asked): it closes by itself. Not over a line being read or a
## question with buttons.
## tutorial.json "remark_seconds" (phrase id -> seconds) shortens one (user, 18 Nov 2026: "That's
## not where we are going right now!" 2 s, "Oops! That's not on our shopping list!" 1.5 s).
func remark(role: String, id: String, values: Dictionary = {}) -> void:
	if not running or _speaking or panel.has_choices():
		return
	var line: Dictionary = narration(id, values)
	var seconds := float(data.get("remark_seconds", {}).get(id, reading_seconds(line) + REMARK_EXTRA))
	panel.show_dialogue(_speaker(role), line, [], seconds)

## A click or tap (not on a button: the box's ✕, Skip), E or Enter moves the line on. A line
## waiting for a reply moves on only by its button, or E / Enter.
func _input(event: InputEvent) -> void:
	if not running:
		return
	var at: Variant = _press_position(event)
	if _speaking or _pausing:
		if at != null and not _on_button(at):
			if not _awaiting_reply:
				_advance = true
		elif (event is InputEventKey or event is InputEventAction) and event.is_pressed() and not event.is_echo() \
				and (event.is_action("ui_accept") or event.is_action("use")):
			if _awaiting_reply:
				_replied = not _need_peek
			else:
				_advance = true
			# E only moves the line on (it would also get the player out of bed).
			get_viewport().set_input_as_handled()

## The screen position of a left mouse press or a touch (a touch's emulated mouse press is left
## out: the touch itself counts), else null.
func _press_position(event: InputEvent) -> Variant:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		return event.position
	if event is InputEventScreenTouch and event.pressed:
		return event.position
	return null

func _on_button(at: Vector2) -> bool:
	var buttons: Array = [_skip_button]
	if panel.get("dialogue_card") != null:
		buttons.append_array(panel.dialogue_card.find_children("*", "BaseButton", true, false))
	for button in buttons:
		if is_instance_valid(button) and button.is_visible_in_tree() and button.get_global_rect().has_point(at):
			return true
	return false

## Gives the player the controls the "controls" step allows, minus what a line being read holds
## back (player_controller.gd look_allowed / move_allowed, interaction_controller.gd
## interact_allowed).
func _apply_gate() -> void:
	var held := running and _speaking
	main.player.look_allowed = bool(_gate.get("look", true)) and not held
	main.player.move_allowed = bool(_gate.get("move", true)) and not held
	main.interaction.interact_allowed = bool(_gate.get("use", true)) and not held

# --- The instruction strip ----------------------------------------------------------------------

## Shows a step's `key` phrase ("line", "strip"; its touch_ twin on a touch screen) in the
## instruction strip, with an optional progress `note` and phrase `values`.
func show_strip(spec: Dictionary, key := "line", note := "", values: Dictionary = {}) -> void:
	_strip_spec = {"spec": spec, "key": key, "note": note, "values": values, "touch": is_touch()}
	strip.show_text(lexicon.phrase(phrase_id(spec, key), lexicon.native, values), note)

func clear_strip() -> void:
	_strip_spec = {}
	if strip != null:
		strip.clear()

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
		presence.face_distance = FACE_DISTANCE
		presence.face_elevation = FACE_ELEVATION
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
		"card":
			# Until the word card is closed (by itself after card_seconds, or a click), then "after"
			# seconds (user, 21 Nov 2026: the statue's name comes 0.2 s after its card closes).
			await until(func() -> bool: return not main.hud.is_card_visible())
			await _pause(float(spec.get("after", 0.0)), false)
		"view", "move":
			await _try_control(spec)
		"journal":
			var open := bool(spec.open)
			# The journal button appears with this step and pulses until it is opened (user,
			# 17 Nov 2026).
			main.hud.tutorial_hidden["journal"] = false
			if open:
				main.hud.tutorial_pulse["journal"] = true
			await until(func() -> bool: return main.hud.is_journal_open() == open)
			main.hud.tutorial_pulse.erase("journal")
			# Done asking: the hint leaves the open journal clear.
			if panel.is_dialogue_visible() and panel.current_line() == _line:
				panel.hide_dialogue()

## "view": waits until the player has turned the view by hand ("turn" radians, player
## look_turned: a mouse or finger drag) or, if the step has "zoom", zoomed that many metres; "move":
## until they walked "distance" metres. The control pulses meanwhile (the step's "cue", default
## its "for"); a first touch switches BonBon's line to the touch wording. Done: the cue goes and
## the hint leaves the screen clear.
func _try_control(spec: Dictionary) -> void:
	var player: Node3D = main.player
	var kind := str(spec.for)
	var turned: float = player.look_turned
	var distance: float = player.camera_distance
	# "move" counts the way walked, not the straight line (a small bedroom; user 17 Nov 2026:
	# walk more before the next line).
	var walked := [0.0, player.global_position]
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
			# Zooming counts only where the step says so (user, 17 Nov 2026: wait for the drag).
			return player.look_turned - turned >= float(spec.get("turn", 0.6)) or (spec.has("zoom") and absf(player.camera_distance - distance) >= float(spec.zoom))
		if not player.seated:
			walked[0] += _flat(player.global_position, walked[1])
		walked[1] = player.global_position
		return not player.seated and walked[0] >= float(spec.get("distance", 1.5)))
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

## The door of a space named "name", else the nearest to "at" [x, z] (doors are registered in
## Main.doors).
func _door(spec: Dictionary) -> Node3D:
	var space := _space(str(spec.space))
	var at := Vector3(float(spec.get("at", [0, 0])[0]), 0.0, float(spec.get("at", [0, 0])[1]))
	var best: Node3D = null
	for door in main.doors:
		if not is_instance_valid(door) or not space.is_ancestor_of(door):
			continue
		if spec.has("name"):
			if str(door.name) == str(spec.name):
				return door
			continue
		var local: Vector3 = space.to_local(door.global_position)
		if best == null or _flat(local, at) < _flat(space.to_local(best.global_position), at):
			best = door
	return best

func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

# --- Finding the friends ---------------------------------------------------------------------

## "find" (user, 17 Nov 2026): the hiding friends of "friends" are found in either order. Each
## entry: "role", "hello" (its greeting, in the language being learned), "hints" (BonBon's
## answers when asked, general to exact) and how it is found: "curtain" (the shower curtain of
## tutorial.json "curtain": near "at" ("space", "radius") BonBon says the "approach" lines and the
## strip asks to open it with E; opening it reveals the friend, and the word "study" is studied) or
## "radius" (walking that close to the friend). The strip shows "objective" with the count; BonBon
## says "first" after the first and "all" after the last.
func _find(spec: Dictionary) -> void:
	_find_spec = spec
	found.clear()
	_hint_asks = 0
	var curtain := _curtain_node()
	_curtain_start = bool(main.doors[curtain].get("open", false)) if curtain != null else false
	# The curtain opens with E or a click (user, 17 Nov 2026: no drag); until now it was shut.
	_lock_curtain(false)
	var friends: Array = spec.friends
	while found.size() < friends.size():
		_show_objective()
		var next: Array = [{}]
		var ok: bool = await until(func() -> bool:
			next[0] = _find_trigger(friends)
			return not next[0].is_empty())
		if not ok:
			return
		var friend: Dictionary = next[0]
		var revealed: bool = await _reveal(friend)
		if not revealed:
			return
		found[str(friend.role)] = true
		_hint_asks = 0
		_show_objective()
		# BonBon's answer in her close-up wherever she is (user, 17 Nov 2026); after the last friend
		# it stays on for her next line ("more to show").
		var last := found.size() >= friends.size()
		_keep_face = last
		await say(_speaker("guide"), narration(str(spec.get("all" if last else "first", ""))), "guide", null, {}, true)
	clear_strip()
	_find_spec = {}

func _show_objective() -> void:
	show_strip(_find_spec, "objective", "%d/%d" % [found.size(), _find_spec.friends.size()], {"name": _speaker("guide")})

## The friend the player has just come to (or whose curtain is open), or {}.
func _find_trigger(friends: Array) -> Dictionary:
	for friend in friends:
		if found.has(str(friend.role)):
			continue
		if friend.has("curtain"):
			if _curtain_opened():
				return friend
			var point: Vector3 = _space(str(friend.space)).to_global(_vec(friend.at))
			if _flat(main.player.global_position, point) <= float(friend.radius):
				return friend
		else:
			var actor: Node3D = actors.get(str(friend.role))
			if actor != null and _flat(main.player.global_position, actor.global_position) <= float(friend.radius):
				return friend
	return {}

## Plays one friend's discovery; false when the tutorial stopped meanwhile.
func _reveal(friend: Dictionary) -> bool:
	var run := _run
	if friend.has("curtain") and not _curtain_opened():
		for id in friend.get("approach", []):
			await say(_speaker("guide"), narration(str(id)))
			if run != _run:
				return false
		if friend.has("strip"):
			show_strip(friend, "strip")
		if not await until(_curtain_opened):
			return false
		_show_objective()
	if friend.has("study"):
		main.interaction.word_studied.emit(str(friend.study))
	if friend.has("curtain"):
		# The curtain slides back before the close-up.
		await _pause(0.5, false)
	var line: Dictionary = lexicon.line(str(friend.hello), {"name": _speaker(str(friend.role))})
	# The first greeting introduces the EN button (user, 17 Nov 2026); each is answered with the
	# step's "reply" (in the language being learned).
	_introduce_peek()
	var reply: Dictionary = lexicon.line(str(_find_spec.get("reply", "tutorial.reply_nice")), {})
	# BonBon answers next: the camera cuts from the friend's face to hers.
	_keep_face = true
	await say(_speaker(str(friend.role)), line, str(friend.role), null, reply)
	_end_peek_intro()
	return run == _run

## The EN introduction (user, 17 Nov 2026): at the first friend's greeting, in the language being
## learned, the EN button appears and pulses and the strip says to hold it; the reply button shows
## once it was held (say()). Not in the Native display mode (no EN button there).
func _introduce_peek() -> void:
	if _peek_introduced:
		return
	_peek_introduced = true
	main.hud.tutorial_hidden["peek"] = false
	if int(main.hud.mode) == GameSettings.NATIVE:
		return
	main.hud.tutorial_pulse["peek"] = true
	_need_peek = true
	show_strip(PEEK_STRIP, "line", "", {"badge": GameSettings.shared().native_badge()})
	var settings = GameSettings.shared()
	var watch := func() -> void:
		if settings.peeking and _need_peek:
			_need_peek = false
			main.hud.tutorial_pulse.erase("peek")
	if not settings.peek_changed.is_connected(watch):
		settings.peek_changed.connect(watch)
	_peek_watch = watch

## The cashier's request (user, 18 Nov 2026): the strip reminds the player to hold EN when unsure
## and the EN button pulses. Not in the Native display mode (no EN button there).
func show_peek_strip() -> void:
	if int(main.hud.mode) == GameSettings.NATIVE:
		return
	main.hud.tutorial_hidden["peek"] = false
	main.hud.tutorial_pulse["peek"] = true
	show_strip(PEEK_STRIP, "line", "", {"badge": GameSettings.shared().native_badge()})

func clear_peek_strip() -> void:
	main.hud.tutorial_pulse.erase("peek")
	if _strip_spec.get("spec") == PEEK_STRIP:
		clear_strip()

func _end_peek_intro() -> void:
	_need_peek = false
	main.hud.tutorial_pulse.erase("peek")
	if _peek_watch.is_valid() and GameSettings.shared().peek_changed.is_connected(_peek_watch):
		GameSettings.shared().peek_changed.disconnect(_peek_watch)
	_peek_watch = Callable()
	if _strip_spec.get("spec") == PEEK_STRIP:
		clear_strip()

## BonBon's hint while the friends are hunted: the first friend not found yet (data order), the
## more exact the more often she was asked since the last find.
func _find_hint() -> String:
	if _find_spec.is_empty():
		return ""
	for friend in _find_spec.friends:
		if not found.has(str(friend.role)):
			var hints: Array = friend.get("hints", [])
			return str(hints[mini(_hint_asks, hints.size() - 1)]) if not hints.is_empty() else ""
	return ""

func _curtain_node() -> Node3D:
	var curtain := main.apartment.get_node_or_null(NodePath(str(data.get("curtain", "")))) as Node3D
	return curtain if curtain != null and main.doors.has(curtain) else null

## Keeps the shower curtain shut (`on`: until the hunt starts, so the friend is not found early)
## or lets it open with E again.
func _lock_curtain(on: bool) -> void:
	var curtain := _curtain_node()
	var item: Node = Interactable.on(curtain) if curtain != null else null
	if item != null:
		item.on_check = (func() -> Variant: return false) if on else Callable()

## The shower curtain was pulled back since the hunt started.
func _curtain_opened() -> bool:
	var curtain := _curtain_node()
	return curtain != null and bool(main.doors[curtain].get("open", false)) != _curtain_start

# --- Locked doors and confining ---------------------------------------------------------------

## "lock": every door of the space (main.doors; not the shower curtains) except the ones named
## in "open" answers with the step's "line" instead of opening (user, 13 Nov 2026: the house tour
## only opens the rooms it uses). A later lock step replaces the list; _stop() unlocks all.
## "open_in" units keep all their doors (user, 17 Nov 2026: in the town acts only the
## supermarket's open; the others say they are not the right place); buildings that come in later
## are locked too (_process()). "say": true (the house act, user 17 Nov 2026: only the hiding
## friend's door opens) has the guide say the line in a bubble instead, "remark_line" while the
## friends are hunted ("my friends wouldn't hide there"); a locked door that stands open (the ones
## the tutorial opened) cannot be used at all, so it never shuts the player in.
func _lock(spec: Dictionary) -> void:
	_unlock_all()
	if spec.get("off", false):
		return
	_lock_spec = spec
	_lock_seen = main.doors.size()
	# "world": every door of the town (the cast's own space holds none).
	var space: Node = main.apartment if str(spec.get("space", "home")) == "world" else _space(str(spec.get("space", "home")))
	var open: Array = spec.get("open", [])
	# "open_in": units (data/buildings.json keys) whose doors all stay usable (the supermarket).
	var open_sites: Array = []
	for unit in spec.get("open_in", []):
		var site: Node3D = ModularTown.building(main.apartment, str(unit))
		if site != null:
			open_sites.append(site)
	_remark_line = str(spec.get("remark_line", ""))
	var line := str(spec.get("line", ""))
	var says := bool(spec.get("say", false))
	for door in main.doors:
		if not is_instance_valid(door) or not space.is_ancestor_of(door):
			continue
		if str(main.doors[door].get("type", "")) == "curtain" or open.has(str(door.name)) \
				or open_sites.any(func(site: Node3D) -> bool: return site.is_ancestor_of(door)):
			continue
		var item: Node = Interactable.on(door)
		if item == null:
			continue
		_locked.append({"item": item, "use": item.on_use})
		if says:
			var shut := func() -> bool: return main.doors.has(door) and not bool(main.doors[door].get("open", false))
			item.on_check = func() -> Variant: return shut.call()
			item.on_use = func() -> void: _say_locked(line)
		else:
			item.on_check = func() -> Variant: return lexicon.phrase(line, lexicon.native) if line != "" else false

## A "say" lock step's door was tried: the guide's bubble (remark_line during the hunt).
func _say_locked(line: String) -> void:
	var id := _remark_line if str(step.get("do", "")) == "find" and _remark_line != "" else line
	if id != "":
		remark("guide", id)

func _unlock_all() -> void:
	_lock_spec = {}
	for entry in _locked:
		var item: Node = entry.item
		if is_instance_valid(item):
			item.on_check = Callable()
			item.on_use = entry.use
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
		# BonBon says it (17 Nov 2026: "Hey! The supermarket is this way!").
		remark("guide", _confine_line)

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
	if spec.has("picnic"):
		_make_picnic(space, spec.picnic)
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

## The picnic (user, 17 Nov 2026): a gingham blanket on the ground at "at" ([x, y, z] in the
## space), turned along "look", with the shopping basket (shopping_basket.gd) holding the food
## bought in the market act (tutorial.json shop items). Gone when the tutorial ends.
func _make_picnic(space: Node3D, spec: Dictionary) -> void:
	_clear_picnic()
	_picnic = Node3D.new()
	_picnic.name = "TutorialPicnic"
	_world.add_child(_picnic)
	_picnic.global_position = _ground(space.to_global(_vec(spec.at)))
	var facing: Vector3 = space.global_basis * _look(spec.look)
	_picnic.global_basis = Basis.looking_at(Vector3(facing.x, 0, facing.z).normalized(), Vector3.UP)
	var cloth := MeshInstance3D.new()
	cloth.name = "Picnic blanket"
	# A thin slab above the ground's collider: the park lawn is drawn 5 to 10 cm higher.
	var slab := BoxMesh.new()
	slab.size = Vector3(PICNIC_SIZE.x, 0.03, PICNIC_SIZE.y)
	cloth.mesh = slab
	cloth.position.y = 0.13
	cloth.material_override = _gingham()
	cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_picnic.add_child(cloth)
	var basket: Node3D = load(ShoppingBasket.SCENE).instantiate()
	basket.name = "Picnic basket"
	_picnic.add_child(basket)
	basket.position = Vector3(0.35, 0.145, -0.15)
	basket.rotation.y = 0.4
	basket.show_items(data.shop.items)

## Red and white gingham: a 2 x 2 pixel pattern repeated over the blanket.
func _gingham() -> StandardMaterial3D:
	var image := Image.create(2, 2, false, Image.FORMAT_RGB8)
	image.set_pixel(0, 0, Color("d9483f"))
	image.set_pixel(1, 0, Color("f2a39b"))
	image.set_pixel(0, 1, Color("f2a39b"))
	image.set_pixel(1, 1, Color("fbf4ec"))
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	# BoxMesh UVs put each face in a third of the texture across: 3 x 9 checks along the top.
	material.uv1_scale = Vector3(PICNIC_CHECKS.x, PICNIC_CHECKS.y, 1)
	material.roughness = 0.95
	return material

func _clear_picnic() -> void:
	if is_instance_valid(_picnic):
		_picnic.queue_free()
	_picnic = null

## The tutorial played to its end (user, 21 Nov 2026): behind a fade, the guide and the friends sit
## down round the picnic blanket (tutorial.json "after" "seats"; house_characters.gd seated(), the
## house characters' seated pose) and stay there after the tutorial, each a TALK interactable
## (interactable.gd: E, a click or a tap) saying its next "lines" phrase in turn. Not saved: a
## reload does not bring them back, and a replay (start()) clears them first. Nothing when the
## act had no picnic or "after" is missing.
func _leave_party(run: int) -> void:
	var spec: Dictionary = data.get("after", {})
	if spec.is_empty() or not is_instance_valid(_picnic):
		return
	await zone.fade_through(func() -> void:
		if run == _run:
			_make_party(spec))

func _make_party(spec: Dictionary) -> void:
	_clear_party()
	_party = Node3D.new()
	_party.name = "TutorialPicnicParty"
	_world.add_child(_party)
	# The blanket stays: it moves to the party, out of _clear_picnic()'s reach.
	_picnic.reparent(_party)
	_picnic = null
	if is_instance_valid(_cast_root):
		_cast_root.visible = false
	var space := _space(str(spec.get("space", "world")))
	var maker := HouseCharacters.new()
	var seats: Dictionary = spec.get("seats", {})
	for role in seats:
		var id := str(cast.get(role, ""))
		if id == "":
			continue
		var info: Dictionary = HouseCharacters.spec_of(id)
		var where: Dictionary = seats[role]
		var seat: Vector3 = _ground(space.to_global(_vec(where.at))) + Vector3.UP * PARTY_SEAT_LIFT
		var facing: Vector3 = space.global_basis * _look(where.look)
		facing.y = 0.0
		var back := seat - facing.normalized() * PARTY_BACK
		var npc: Node3D = maker.seated(str(info.scene), _party, str(role), seat, facing, back)
		# Dressed after seating, as the house characters are (house_characters.gd build()).
		if str(info.get("costume", "")) != "":
			PlushCostume.dress(npc, str(info.costume))
		npc.set_meta("character_name", str(info.name))
		npc.set_meta("character_species", str(info.get("species", "")))
		HouseCharacters.fit_blocker(npc)
		var talker := str(role)
		Interactable.attach(npc, {
			"kind": Interactable.Kind.TALK,
			"prompt_distance": MinigameHost.TALK_DISTANCE,
			"priority": 1.0,
			"badge_offset": Vector3(0, InteractIcons.head_height(npc), 0),
			"on_point": func(_from: Vector3) -> Vector3: return npc.global_position,
			"on_check": func() -> Variant: return not running,
			"on_use": func() -> void: _party_talk(talker),
		})

## A party member's next friendly line (tutorial.json "after" "lines", in turn), a bubble that
## closes by itself.
func _party_talk(role: String) -> void:
	var lines: Array = data.get("after", {}).get("lines", {}).get(role, [])
	if lines.is_empty() or running or panel.has_choices():
		return
	var turn := int(_party_turns.get(role, 0))
	_party_turns[role] = turn + 1
	var line: Dictionary = narration(str(lines[turn % lines.size()]))
	panel.show_dialogue(_speaker(role), line, [], reading_seconds(line) + REMARK_EXTRA)

func _clear_party() -> void:
	if is_instance_valid(_party):
		_party.queue_free()
	_party = null
	_party_turns.clear()

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
## `act_index` (default the current act): the later acts' views, drawn behind the title cutscene
## (_play_cutscene(): the market and park acts lagged on first draws, 17 Nov 2026); a "shop" step
## adds the shop staff's close-ups and the store's outside spot, a "picnic" its spot.
func warm_views(act_index := -1) -> Array:
	var views: Array = []
	var faces: Array = actors.keys().map(func(role) -> Node: return _face(role, null))
	var spots: Array[Vector3] = []
	for spec in data.acts[act if act_index < 0 else act_index].steps:
		if str(spec.do) == "cutscene":
			break
		var space := _space(str(spec.get("space", "world")))
		match str(spec.do):
			"shop":
				var rules_of = ShopDialogue.new()
				var shop_rules: Dictionary = rules_of.store_rules(str(data.shop.store))
				for staff in [str(shop_rules.get("clerk", "")), str(rules_of.cashiers.get(str(data.shop.store), {}).get("npc", ""))]:
					var npc := main.apartment.find_child(staff, true, false) as Node3D if staff != "" else null
					if npc != null:
						faces.append(_face("", npc))
				var outside: Dictionary = data.shop.get("outside", {})
				if not outside.is_empty():
					spots.append(_space(str(outside.space)).to_global(_vec(outside.at)))
			"place":
				if spec.has("player"):
					spots.append(space.to_global(_vec(spec.player.at)))
				for role in spec.get("cast", {}):
					spots.append(space.to_global(_vec(spec.cast[role].at)))
				if spec.has("picnic"):
					spots.append(space.to_global(_vec(spec.picnic.at)))
			"walk":
				for point in spec.path:
					spots.append(space.to_global(Vector3(float(point[0]), 0.0, float(point[1]))))
			"wait":
				if spec.has("at") and spec.has("space"):
					var at: Array = spec.at
					spots.append(space.to_global(_vec(at) if at.size() == 3 else Vector3(float(at[0]), 0.0, float(at[1]))))
	for presence in faces:
		if presence != null:
			views.append({"transform": presence.face_transform(), "fov": NpcPresence.FACE_FOV})
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

## Draws `views` (warm_views()) one after another through a camera of its own, two frames each
## (the second is drawn with the view for sure), then gives the camera back. `on_drawn(count)`
## after each (app.gd's and the cutscene's progress bar).
func draw_views(views: Array, on_drawn: Callable = Callable()) -> void:
	var before := get_viewport().get_camera_3d()
	var look := Camera3D.new()
	look.name = "WarmUpCamera"
	look.near = 0.05
	look.far = main.camera.far
	main.add_child(look)
	look.make_current()
	var drawn := 0
	for view in views:
		look.global_transform = view.transform
		look.fov = float(view.fov)
		await get_tree().process_frame
		await get_tree().process_frame
		drawn += 1
		if on_drawn.is_valid():
			on_drawn.call(drawn)
	if is_instance_valid(before):
		before.make_current()
	look.queue_free()

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
	# A walk still under way would carry the actor back (17 Nov 2026: the cast walking off at the
	# end of the market act reappeared at the supermarket in the park).
	_stop_walk(actor)
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
	_stop_walk(actor)
	var tween := actor.create_tween()
	_walks[actor] = tween
	var from := actor.global_position
	# "speed": a factor of the walking speed (user, 20 Nov 2026: BonBon walks to the living room
	# at 0.8).
	var speed := _walk_speed() * float(spec.get("speed", 1.0))
	for point in spec.path:
		var to := _ground(space.to_global(Vector3(float(point[0]), 0.0, float(point[1])))) + Vector3.UP * lift
		var a := from
		tween.tween_callback(func() -> void:
			var way := Vector3(to.x - a.x, 0, to.z - a.z)
			if way.length() > 0.01:
				actor.global_basis = Basis.looking_at(way.normalized(), Vector3.UP))
		tween.tween_property(actor, "global_position", to, maxf(_flat(a, to) / speed, 0.05))
		from = to
	# "look": the way the walker turns once there (the whole body; a plush's Head is never turned).
	if spec.has("look"):
		var facing: Vector3 = space.global_basis * _look(spec.look)
		tween.tween_callback(func() -> void:
			actor.global_basis = Basis.looking_at(Vector3(facing.x, 0, facing.z).normalized(), Vector3.UP))

## The cast's walking speed: the player's own (player_controller.gd walk_speed).
func _walk_speed() -> float:
	var speed = main.player.get("walk_speed") if main != null and is_instance_valid(main.player) else null
	return float(speed) if speed != null and float(speed) > 0.0 else WALK_SPEED

func _stop_walk(actor: Node3D) -> void:
	var walk: Tween = _walks.get(actor)
	if walk != null and walk.is_valid():
		walk.kill()
	_walks.erase(actor)

## Who plays each role: the guide and the friends of tutorial.json; one who is the player's
## avatar is replaced by the next house character (data order) not already in the cast (user,
## 17 Nov 2026: a player who picked BonBon is greeted by someone else).
func _cast_actors() -> void:
	var avatar := str(ProfileManager.shared().active_profile().get("avatar", ""))
	var everyone: Array = HouseCharacters.ids()
	var taken: Array = [str(data.guide), avatar] + Array(data.friends)
	var stand_in := func(id: String) -> String:
		if id != avatar:
			return id
		for other in everyone:
			if not taken.has(other):
				taken.append(other)
				return other
		return id
	cast = {"guide": stand_in.call(str(data.guide))}
	for i in data.friends.size():
		cast["friend_%d" % (i + 1)] = stand_in.call(str(data.friends[i]))
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
		if role == "guide":
			_make_guide_talker(actor)
		cast_built += 1
	# Every seated house character is hidden while it runs, not only the cast's own twins (user,
	# 17 Nov 2026: the player's own character sat on the couch and napped on the guest bed), and
	# none naps meanwhile (sleepers go back to their seats first).
	_set_naps(false)
	var twins: Node = main.get_node_or_null("HouseCharacters")
	if twins != null:
		for twin in twins.get_children():
			if twin is Node3D:
				_hide(twin)
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
		"find":
			return _find_hint()
	return ""

## BonBon turns to the player and says where to go next (a bubble that closes by itself). Hints
## only come when asked (user, 17 Nov 2026); during the hunt and the shopping each ask gives the
## next, more exact hint.
func _talk_to_guide() -> void:
	var id := where_line()
	var actor: Node3D = actors.get("guide")
	if id == "" or actor == null:
		return
	var way: Vector3 = main.player.global_position - actor.global_position
	way.y = 0.0
	if way.length() > 0.05:
		actor.global_basis = Basis.looking_at(way.normalized(), Vector3.UP)
	match str(step.get("do", "")):
		"find":
			_hint_asks += 1
		"shop":
			if is_instance_valid(shop):
				shop.asked()
	remark("guide", id)

## House characters' naps (house_characters.gd Bedtime) on or off; off also wakes every sleeper
## (back to its seat), so no bed is taken.
func _set_naps(on: bool) -> void:
	var bedtime: Node = main.get_node_or_null("HouseCharacters/Bedtime")
	if bedtime == null:
		return
	bedtime.set_process(on)
	if not on and bedtime.has_method("wake_all"):
		bedtime.wake_all(main.get("seating"))

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
	_walks.clear()
	_set_naps(true)

## Act 1 needs the family bathtub's curtain drawn along its rail, hiding the tub (the home's own
## curtain, home_furnishing.gd; in door_animator.gd terms "open" = drawn, and it starts bunched
## at the wall), and every other door of the home shut as in a new town (user, 17 Nov 2026: a
## replay found the front door open); the act's "door" steps open what it needs.
func _reset_props() -> void:
	var home := _space("home")
	for door in main.doors.keys():
		if is_instance_valid(door) and home.is_ancestor_of(door) and str(main.doors[door].get("type", "")) != "curtain" \
				and bool(main.doors[door].get("open", false)):
			DoorAnimator.toggle(main, door)
	var curtain: Node = main.apartment.get_node_or_null(NodePath(str(data.get("curtain", ""))))
	if curtain != null and main.doors.has(curtain) and not main.doors[curtain].get("open", false):
		DoorAnimator.toggle(main, curtain)

# --- Cutscene, skip button, end ------------------------------------------------------------

## A few seconds of Bon Adventure: the loading screen's town pictures with the title over them.
## It is also the loading screen for the rest of the tutorial (16 Nov 2026, user: app.gd
## _load_rest() adds Main's pending_units while it is up; 17 Nov 2026, user: the market and park
## acts still lagged): the bar fills to CUTSCENE_UNITS_SHARE as the buildings come in, then the
## later acts' views are drawn behind it (warm_views(), draw_views()) to the end. Only then does
## it say "Click or tap to skip" and can be skipped (after CUTSCENE_SKIP_AFTER s); it stays at least
## cutscene_seconds, and ends at cutscene_max_seconds even if the buildings are not all in.
## `subtitle_id`: the line under the title (17 Nov 2026, user: "Little Town of Words").
func _play_cutscene(title_id: String, subtitle_id := "") -> void:
	var run := _run
	_cutscene = LoadingScreen.new()
	add_child(_cutscene)
	var total := float(main.pending_units.size())
	_cutscene.show_title(lexicon.phrase(title_id, lexicon.native), true,
		lexicon.phrase(subtitle_id, lexicon.native) if subtitle_id != "" else "", "")
	_skip_cutscene = false
	var started := Time.get_ticks_msec()
	_cutscene.skip_requested.connect(func() -> void:
		if Time.get_ticks_msec() - started >= CUTSCENE_SKIP_AFTER * 1000.0:
			_skip_cutscene = true)
	var least: float = started + float(data.get("cutscene_seconds", 7.0)) * 1000.0
	var most: float = started + float(data.get("cutscene_max_seconds", 60.0)) * 1000.0
	await until(func() -> bool:
		if total > 0.0 and is_instance_valid(_cutscene):
			_cutscene.set_progress(CUTSCENE_UNITS_SHARE * (1.0 - main.pending_units.size() / total))
		# A replay with nearby loading (nearby_units.gd) never waits for far buildings.
		return main.pending_units.is_empty() or main.has_node("NearbyUnits") or Time.get_ticks_msec() >= most)
	if run != _run:
		return
	var views: Array = []
	for later in range(act + 1, data.acts.size()):
		views.append_array(warm_views(later))
	if not views.is_empty() and is_instance_valid(_cutscene):
		var count := float(views.size())
		await draw_views(views, func(drawn: int) -> void:
			if is_instance_valid(_cutscene):
				_cutscene.set_progress(lerpf(CUTSCENE_UNITS_SHARE, 1.0, drawn / count)))
		if run != _run:
			return
	if is_instance_valid(_cutscene):
		_cutscene.set_progress(1.0)
		_cutscene.set_skip_note(lexicon.phrase("tutorial.tap_skip", lexicon.native))
	await until(func() -> bool:
		var now := Time.get_ticks_msec()
		return _skip_cutscene or now >= most or now >= least)
	if is_instance_valid(_cutscene):
		_cutscene.finish()
	_cutscene = null

func _make_skip_button() -> void:
	_skip_layer = CanvasLayer.new()
	_skip_layer.name = "TutorialSkip"
	_skip_layer.layer = 60
	_skip_layer.visible = false
	add_child(_skip_layer)
	# The in-game soft blue pill (docs/guides/UI_STYLE.md, kind "soft"); restyled in _process
	# only when the window scale changes.
	_skip_button = BonStyle.button("", "soft", "", 1.0, 24.0, Vector2(150, 56))
	_skip_button.pressed.connect(skip)
	_skip_layer.add_child(_skip_button)

func _process(_delta: float) -> void:
	if running:
		# No running (Shift or the Run button) during the tutorial.
		if main.player.get("sprint_enabled"):
			main.player.sprint_enabled = false
		# Buildings that came in since the lock step get their doors locked too.
		if not _lock_spec.is_empty() and main.doors.size() != _lock_seen:
			_lock(_lock_spec)
		# The strip's wording follows the device (the first touch switches it).
		if not _strip_spec.is_empty() and bool(_strip_spec.touch) != is_touch():
			show_strip(_strip_spec.spec, _strip_spec.key, _strip_spec.note, _strip_spec.values)
	if not _skip_layer.visible:
		return
	# Finger sized and scaled with the window (money_panel.gd's rule), top centre.
	var screen := get_viewport().get_visible_rect().size
	var f := clampf(minf(screen.y / 800.0, screen.x / 1100.0), 0.6, 3.0)
	var text: String = lexicon.phrase("tutorial.skip", lexicon.native)
	if _skip_button.text != text or not is_equal_approx(_skip_scale, f):
		_skip_button.text = text
		_skip_scale = f
		BonStyle.style_button(_skip_button, "soft", f, 24.0)
		_skip_button.custom_minimum_size = Vector2(150, 56) * f
	_skip_button.size = _skip_button.get_minimum_size()
	# Top centre where the HUD clock is (hidden meanwhile); out of the way of the journal, map, help
	# and Settings, and of an instruction strip (user, 18 Nov 2026: hidden while one shows).
	_skip_button.position = Vector2((screen.x - _skip_button.size.x) * 0.5, SKIP_TOP * f)
	_skip_button.visible = _strip_spec.is_empty() and not (main.hud.is_journal_open() or main.hud.is_map_open() or main.hud.is_help_open() or main.settings_panel.visible)

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
	if is_instance_valid(tap_hint):
		tap_hint.clear()
	clear_strip()
	_gate = {}
	_speaking = false
	_pausing = false
	_find_spec = {}
	_awaiting_reply = false
	_end_peek_intro()
	_release_face()
	_lock_curtain(false)
	main.interaction.interact_filter = Callable()
	main.hud.tutorial_hidden = {}
	main.hud.tutorial_pulse = {}
	panel.closable = true
	panel.tail = true
	_hide_clock(false)
	_apply_gate()
	_clear_picnic()
	_clear_cast()
	_skip_layer.visible = false
	_unlock_all()
	_confine.clear()
	main.interaction.word_filter = Callable()
	Board.shared().hold = ""
	main.interaction.word_cards = true
	main.interaction.card_seconds = 0.0
	main.sync_player_controls()

## The HUD clock is hidden while the tutorial runs (user, 18 Nov 2026).
func _hide_clock(on: bool) -> void:
	var clock = main.get("day_clock")
	if clock != null and clock.has_method("set_hidden"):
		clock.set_hidden(on)

func _save(progress: Dictionary) -> void:
	var manager = ProfileManager.shared()
	if manager.active_id != "":
		manager.update(manager.active_id, {"tutorial": progress})
