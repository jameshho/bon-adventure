extends Node
## The game's one sound service (first version 9 Nov 2026; record: docs/guides/TOWN_DESIGN_BRIEF.md
## "Bathroom fixtures", Sound). Cues live in data/sounds.json (file, bus, volume, loop,
## distance, source, licence); buses in res://default_bus_layout.tres (Master, SFX, Ambience,
## UI, Voice). Objects never play audio themselves: they emit signals, and the catalogue's
## "bindings" say which script's signal plays, starts or stops which cue. Sounds play from an
## AudioStreamPlayer3D placed at the object, so they come from where it is.
##
## Main adds it (Sound.new()) after the world is built; it binds every node already in the tree
## and any added later. Elsewhere: Sound.shared().play_at("cue.id", node).
##
## Spoken words (24 Nov 2026, guide docs/guides/VOICE.md): the catalogue's "voice" section names
## one clip per word and language, <folder>/<lang>/<voice_file(key)>.ogg, made by
## tools/voice_generate.py. say_word() plays it on the Voice bus, not positional, one word at a
## time. While "voice.enabled" is false (user, 24 Nov 2026) it plays nothing and has_voice() is
## false, so no speaker button or automatic word ever shows or sounds.
const PATH := "res://data/sounds.json"

static var _shared

var cues: Dictionary = {}
## script resource path -> binding dictionary (play / start / stop: signal -> cue id).
var bindings: Dictionary = {}
## The catalogue's "voice" section (enabled, folder, bus, volume_db, languages).
var voice: Dictionary = {}
var _streams: Dictionary = {}
var _voice_player: AudioStreamPlayer

static func shared():
	return _shared

func _init() -> void:
	name = "Sound"
	var file := FileAccess.open(PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(file.get_as_text()) if file else null
	if not data is Dictionary:
		push_error("sound.gd: cannot read " + PATH)
		return
	cues = data.get("cues", {})
	voice = data.get("voice", {})
	for binding in data.get("bindings", []):
		bindings[str(binding["script"])] = binding

func _enter_tree() -> void:
	_shared = self
	get_tree().node_added.connect(_bind)

func _ready() -> void:
	for node in get_tree().root.find_children("*", "", true, false):
		_bind(node)

func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_bind):
		get_tree().node_added.disconnect(_bind)
	if _shared == self:
		_shared = null

## Connects a node's signals when its script has a binding (once per node).
func _bind(node: Node) -> void:
	var script: Script = node.get_script()
	if script == null or not bindings.has(script.resource_path) or node.has_meta("sound_bound"):
		return
	node.set_meta("sound_bound", true)
	var binding: Dictionary = bindings[script.resource_path]
	for signal_name in binding.get("play", {}):
		node.connect(signal_name, play_at.bind(binding["play"][signal_name], node))
	for signal_name in binding.get("start", {}):
		node.connect(signal_name, start_loop.bind(binding["start"][signal_name], node))
	for signal_name in binding.get("stop", {}):
		node.connect(signal_name, stop_loop.bind(binding["stop"][signal_name], node))

func stream(cue_id: String) -> AudioStream:
	if not _streams.has(cue_id):
		var cue: Dictionary = cues.get(cue_id, {})
		_streams[cue_id] = load(str(cue["file"])) if cue.has("file") and ResourceLoader.exists(str(cue["file"])) else null
		if _streams[cue_id] == null:
			push_warning("sound.gd: no sound for cue " + cue_id)
	return _streams[cue_id]

## Plays a cue once from `at` (a positional player under it, freed when done). Returns the player.
func play_at(cue_id: String, at: Node3D) -> AudioStreamPlayer3D:
	var player := _player(cue_id, at)
	if player != null:
		player.finished.connect(player.queue_free)
		player.play()
	return player

## Starts a looping cue at `at` (one per cue and node; a second start keeps the first).
func start_loop(cue_id: String, at: Node3D) -> AudioStreamPlayer3D:
	var existing := looping(cue_id, at)
	if existing != null:
		return existing
	var player := _player(cue_id, at)
	if player != null:
		player.name = _loop_name(cue_id)
		player.play()
	return player

func stop_loop(cue_id: String, at: Node3D) -> void:
	var player := looping(cue_id, at)
	if player != null:
		player.stop()
		player.queue_free()

## The looping player of a cue at a node, else null.
func looping(cue_id: String, at: Node3D) -> AudioStreamPlayer3D:
	var player := at.get_node_or_null(NodePath(_loop_name(cue_id)))
	return player if player is AudioStreamPlayer3D and not player.is_queued_for_deletion() else null

## --- Spoken words -----------------------------------------------------------------------------

## The clip's file name for a word key: lower case, every run of other characters one "_"
## ("apple pie" -> "apple_pie"). tools/voice_manifest.gd refuses two keys with the same name.
static func voice_file(key: String) -> String:
	var out := ""
	var gap := false
	for c in key.to_lower():
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			if gap and out != "":
				out += "_"
			out += c
			gap = false
		else:
			gap = true
	return out

func voice_enabled() -> bool:
	return bool(voice.get("enabled", false))

## res://audio/voice/<lang>/<file>.ogg, whether or not it exists.
func voice_path(key: String, lang: String) -> String:
	return "%s/%s/%s.ogg" % [str(voice.get("folder", "res://audio/voice")), lang, voice_file(key)]

## True when spoken words are switched on and this word has a clip in `lang`.
func has_voice(key: String, lang: String) -> bool:
	return voice_enabled() and lang != "" and ResourceLoader.exists(voice_path(key, lang))

## Says a word in `lang` (stopping any word still being said). Returns false and plays nothing
## while spoken words are off or the clip is missing.
func say_word(key: String, lang: String) -> bool:
	if not has_voice(key, lang):
		return false
	var cue_id := "voice.%s.%s" % [lang, voice_file(key)]
	if not _streams.has(cue_id):
		_streams[cue_id] = load(voice_path(key, lang))
	var clip: AudioStream = _streams[cue_id]
	if clip == null:
		return false
	if _voice_player == null:
		_voice_player = AudioStreamPlayer.new()
		_voice_player.name = "Voice"
		add_child(_voice_player)
	_voice_player.stop()
	_voice_player.stream = clip
	_voice_player.bus = str(voice.get("bus", "Voice"))
	_voice_player.volume_db = float(voice.get("volume_db", 0.0))
	_voice_player.set_meta("sound_cue", cue_id)
	_voice_player.play()
	return true

func _loop_name(cue_id: String) -> String:
	return "Sound " + cue_id.replace(".", " ")

func _player(cue_id: String, at: Node3D) -> AudioStreamPlayer3D:
	var sound := stream(cue_id)
	if sound == null or not is_instance_valid(at) or not at.is_inside_tree():
		return null
	var cue: Dictionary = cues[cue_id]
	var player := AudioStreamPlayer3D.new()
	player.stream = sound
	player.bus = str(cue.get("bus", "SFX"))
	player.volume_db = float(cue.get("volume_db", 0.0))
	var distance: Dictionary = cue.get("distance", {})
	player.unit_size = float(distance.get("unit_size", 10.0))
	player.max_distance = float(distance.get("max_distance", 0.0))
	player.set_meta("sound_cue", cue_id)
	at.add_child(player)
	return player
