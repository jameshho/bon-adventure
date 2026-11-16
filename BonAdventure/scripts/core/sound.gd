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
const PATH := "res://data/sounds.json"

static var _shared

var cues: Dictionary = {}
## script resource path -> binding dictionary (play / start / stop: signal -> cue id).
var bindings: Dictionary = {}
var _streams: Dictionary = {}

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
