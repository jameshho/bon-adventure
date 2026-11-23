extends Node
## Idle chatter (23 Nov 2026, user): talking to an NPC that has no activity, or whose activity is
## not on offer, gives a random line of its group in the shared dialogue box, in the language being
## learned (the HUD's EN shows the native line). Never the same line twice in a row. When the
## player keeps prompting the same NPC (more than CHATTY lines with less than RESET_SECONDS between
## them) it answers with a brush-off line instead ("feel free to look around", "I'm a bit busy"),
## until RESET_SECONDS pass without talking to it.
## Guide: docs/guides/NPCS.md#idle-chatter. Lines: data/phrases.json "chatter.<group>_<n>"
## (n = 1, 2, ...) and the brush-offs "chatter.brush_<set>_<n>", the set ("staff" / "friend")
## named per group by data/npcs.json "chatter_groups".
##
## Two ways in:
##   - attach(npc): an NPC without an activity (registry role not "host") gets the shared TALK
##     Interactable (E, a click or a tap; never hover-only). Its role word stays in the area's word
##     list (meta talk_keeps_word, area_vocabulary.gd) and an unnamed NPC's word counts as studied
##     when the player talks to it, as a click on it used to.
##   - next_line(npc): a minigame host whose game is not on offer (minigame_host.gd gate()) shows the
##     line itself, with its own speaker and face close-up.
## Main makes one (main.npc_chatter); `current` reaches it from the sessions.

const Registry := preload("res://scripts/characters/npc_registry.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const InteractIcons := preload("res://scripts/ui/interact_badge.gd")
const Board := preload("res://scripts/learning/activity_board.gd")
## Metres within which E (or a click / tap) talks: the minigame host's talk distance.
const TALK_DISTANCE := 3.5
## Ordinary lines a player gets in a row before the brush-offs start.
const CHATTY := 3
## Seconds without talking to an NPC after which it chats normally again.
const RESET_SECONDS := 40.0
## Seconds a line stays in the box (it also closes when the player walks off).
const MESSAGE_SECONDS := 6.0

static var current

var lexicon
var panel
var interaction
var dialogue
## Seconds since start; checks may move it forward to test the reset.
var clock := 0.0
## npc instance id -> {"count", "last", "line"}.
var _talks := {}
## The ambient line on screen ({} when none).
var _line := {}
var _rng := RandomNumberGenerator.new()

func setup(main) -> void:
	name = "NpcChatter"
	current = self
	panel = main.shop_panel
	interaction = main.interaction
	dialogue = preload("res://scripts/learning/shop_dialogue.gd").new()
	lexicon = dialogue.lexicon
	_rng.randomize()
	panel.dialogue_closed.connect(_on_dialogue_closed)

func _process(delta: float) -> void:
	clock += delta

func _exit_tree() -> void:
	if current == self:
		current = null

## Gives every registry NPC under `root` that has a chatter group and no activity its TALK
## interactable; returns how many.
func attach_all(root: Node) -> int:
	var count := 0
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node.has_meta("npc_id") and node is Node3D:
			if attach(node):
				count += 1
			continue
		pending.append_array(node.get_children())
	return count

## Makes `npc` talk with idle lines (false: no registry entry, a host, or no chatter group).
func attach(npc: Node3D) -> bool:
	var entry := Registry.of_node(npc)
	if entry.is_empty() or str(entry.get("role", "")) == "host" or str(entry.get("chatter", "")) == "":
		return false
	npc.set_meta("talk_keeps_word", true)
	Interactable.attach(npc, {
		"kind": Interactable.Kind.TALK,
		"prompt_distance": TALK_DISTANCE,
		"priority": 1.0,
		"badge_offset": Vector3(0, InteractIcons.head_height(npc), 0),
		"on_point": func(_from: Vector3) -> Vector3: return npc.global_position,
		"on_check": func() -> Variant: return available(npc),
		"on_use": func() -> void: talk(npc),
	}).enabled = true
	return true

## Whether an ambient NPC can chat now: no minigame running, no question in the box, not napping.
func available(npc: Node3D) -> bool:
	return Board.shared().blocker("") == "" and not panel.has_choices() and not bool(npc.get_meta("napping", false))

## Shows `npc`'s next line in the shared box (an ambient NPC; a host uses next_line()).
func talk(npc: Node3D) -> void:
	if not available(npc):
		return
	var said := next_line(npc)
	if said.is_empty():
		return
	interaction.clear_card()
	_line = said.line
	panel.translate_text = lexicon.line("common.show_translation")
	panel.show_dialogue(speaker(npc), _line, [], MESSAGE_SECONDS)
	var entry := Registry.of_node(npc)
	var word := str(npc.get_meta("word_key", entry.get("word", "")))
	if word != "" and not npc.has_meta("character_name") and interaction.has_signal("word_studied"):
		interaction.word_studied.emit(word)

## The next idle line of `npc`: {"id": phrase id, "line": {"foreign", "native"}, "brush": bool},
## {} when it has no chatter group. Counts the talk (see the header).
func next_line(npc: Node) -> Dictionary:
	var group := str(Registry.of_node(npc).get("chatter", ""))
	var ids := lines(group)
	if ids.is_empty():
		return {}
	var key := npc.get_instance_id()
	var state: Dictionary = _talks.get(key, {"count": 0, "last": -INF, "line": ""})
	if clock - float(state.last) > RESET_SECONDS:
		state.count = 0
	state.count += 1
	state.last = clock
	var brush := int(state.count) > CHATTY
	if brush:
		var set_ids := lines("brush_" + Registry.brush_set(group))
		if not set_ids.is_empty():
			ids = set_ids
	var pool := ids.filter(func(id) -> bool: return id != state.line)
	var id: String = pool[_rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else ids[0]
	state.line = id
	_talks[key] = state
	return {"id": id, "line": lexicon.line(id), "brush": brush}

## The phrase ids of chatter group `group` (chatter.<group>_1, _2, ... while they exist).
func lines(group: String) -> Array:
	var ids: Array = []
	if group == "":
		return ids
	var n := 1
	while lexicon.phrases.has("chatter.%s_%d" % [group, n]):
		ids.append("chatter.%s_%d" % [group, n])
		n += 1
	return ids

## The speaker line: the NPC's name phrase, its plain name (the cast), else its role word
## ("La vendedora" / "The salesperson").
func speaker(npc: Node3D) -> Dictionary:
	var entry := Registry.of_node(npc)
	if str(entry.get("name_phrase", "")) != "":
		return lexicon.line(str(entry.name_phrase))
	var shown := str(npc.get_meta("character_name", entry.get("name", "")))
	if shown != "":
		return {"foreign": shown, "native": shown}
	return dialogue.speaker_line(str(npc.get_meta("word_key", entry.get("word", ""))), str(entry.get("gender", "")))

func _on_dialogue_closed() -> void:
	# ✕ only asks; the owner of the line on screen hides it.
	if not _line.is_empty() and panel.is_dialogue_visible() and panel.current_line() == _line:
		panel.hide_dialogue()
	_line = {}
