extends Node
## The game's one sound service (first version 9 Nov 2026; record: docs/guides/TOWN_DESIGN_BRIEF.md
## "Bathroom fixtures", Sound). Cues live in data/sounds.json (file, bus, volume, loop,
## distance, source, licence); buses in res://default_bus_layout.tres (Master, SFX, Ambience,
## UI, Voice). Objects never play audio themselves: they emit signals, and the catalogue's
## "bindings" say which script's signal plays, starts or stops which cue. Sounds play from an
## AudioStreamPlayer3D placed at the object, so they come from where it is.
##
## Main adds it (Sound.new()) after the world is built, unless one is already there (App adds it
## before the loading screen, 25 Nov 2026, for the loading music); it binds every node already in
## the tree and any added later. Elsewhere: Sound.shared().play_at("cue.id", node).
## Sound effects (25 Nov 2026; guide docs/guides/VOICE.md "Sound effects"): a cue with no
## "distance" is flat (play_ui(): the stamp coin, right and wrong answers); a bound node that is
## not in 3D plays flat too. Doors play door.<kind>.open/close from door_animator.gd toggle().
##
## Spoken words (24 Nov 2026, guide docs/guides/VOICE.md): the catalogue's "voice" section names
## one clip per word and language, <folder>/<lang>/<voice_file(key)>.ogg, made by
## tools/voice_generate.py. say_word() plays it on the Voice bus, not positional, one word at a
## time. While "voice.enabled" is false (user, 24 Nov 2026) it plays nothing and has_voice() is
## false, so no speaker button or automatic word ever shows or sounds.
## Web packs (PERF-04, decision D7, 25 Nov 2026): the Web export leaves audio/voice/ out of
## index.pck. tools/voice_packs.gd writes one pack per language next to the page (voice/), and
## ensure_voice() downloads only the language being learned (Lexicon foreign, checked again
## whenever it changes), keeps it in user://voice/ for offline play and mounts it. Until it is
## mounted, or when there is no pack, has_voice() is false: the speaker simply does not show.
##
## Background music (25 Nov 2026, user: a lofi BGM for the demo, and a different soundtrack for
## the loading screen): the catalogue's "music" section names one looping cue per track ("town",
## "loading"). play_music(track) fades the playing track out and the new one in, on the Music bus
## (Settings' Music slider), not positional. App plays "loading" with the loading screen and
## "town" when it lifts; Main run on its own plays "town". Never plays when the tree runs a script
## (checks), so checks stay silent.
## Minigames (25 Nov 2026, user: "different songs for different activity"): while a game runs
## (activity_board.gd started / ended) its data/activities.json "music" track plays, then town
## again. Five moods: quiz, errands, mystery, focus, outdoors.
## The home's record player (25 Nov 2026, user; scripts/world/record_player.gd) lets the player
## pick any track: pick_record(track) plays it and makes it `town_track`, the track the town
## returns to after a game and after loading (play_town()); pick_record("") stops the music
## until the next pick. music_changed tells the turntable what is asked for.
## While a word is said (say_word) the music dips by DUCK_DB, through its own bus DUCK_BUS (sent
## to Music), so the Music slider is left alone.
##
## Web (24 Nov 2026, user: the tab always showed a speaker icon): Godot's AudioContext runs and
## sends silence the whole time. The Web preset's head script keeps window.bonAudioContexts; while
## none of this service's players plays, it is suspended (checked every WEB_IDLE_CHECK s), and
## _web_wake() resumes it before any play. Every game sound goes through this service.
const PATH := "res://data/sounds.json"
const WEB_IDLE_CHECK := 0.5
const Board := preload("res://scripts/learning/activity_board.gd")
## Music players play here; it sends to their cue's bus (Music). Added at run time.
const DUCK_BUS := "MusicDuck"
## How far the music dips while a word is said.
const DUCK_DB := -9.0
const Lexicon := preload("res://scripts/language/lexicon.gd")
## Web voice packs: the folder next to index.html (tools/voice_packs.gd) and the local copies.
const VOICE_PACK_URL := "voice/"
const VOICE_PACK_CACHE := "user://voice"
const VOICE_PACK_TIMEOUT := 20.0

static var _shared

## The track play_music() or stop_music() now asks for ("" = quiet); the record player follows it.
signal music_changed(track: String)
## A language's spoken-word pack is mounted (web) and its clips can be said.
signal voice_ready(lang: String)

var cues: Dictionary = {}
## script resource path -> binding dictionary (play / start / stop: signal -> cue id).
var bindings: Dictionary = {}
## The catalogue's "voice" section (enabled, folder, bus, volume_db, languages).
var voice: Dictionary = {}
## The catalogue's "music" section (enabled, tracks: name -> cue id, fade_in, fade_out).
var music: Dictionary = {}
## Track name -> its AudioStreamPlayer (reused, not freed; a track starts from the top each time).
var _music_players: Dictionary = {}
## The track play_music() last asked for ("" after stop_music()).
var _music_now := ""
## What the town plays when no game runs: "town", or the record player's pick ("" = stopped).
var town_track := "town"
var _duck_tween: Tween
var _streams: Dictionary = {}
var _voice_player: AudioStreamPlayer
## Every player this service made (looping and one-shot), to know whether anything plays.
var _players: Array = []
var _web := OS.has_feature("web")
## The page starts with its audio suspended (the Web preset's head script).
var _web_awake := false
var _web_check := 0.0
## Web voice packs: language -> "loading", "ready" or "none" (no pack); the language last asked for.
var _voice_packs: Dictionary = {}
var _voice_lang := ""

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
	music = data.get("music", {})
	for binding in data.get("bindings", []):
		bindings[str(binding["script"])] = binding

func _enter_tree() -> void:
	_shared = self
	get_tree().node_added.connect(_bind)

func _ready() -> void:
	for node in get_tree().root.find_children("*", "", true, false):
		_bind(node)
	var board = Board.shared()
	board.started.connect(_on_activity_started)
	board.ended.connect(_on_activity_ended)
	if _web:
		ensure_voice(Lexicon.shared().foreign)

func _process(delta: float) -> void:
	if not _web:
		return
	_web_check -= delta
	if _web_check > 0.0:
		return
	_web_check = WEB_IDLE_CHECK
	# The learned language changed (Settings, another profile): fetch that language's pack.
	if Lexicon.shared().foreign != _voice_lang:
		ensure_voice(Lexicon.shared().foreign)
	if _web_awake and not is_playing():
		_web_suspend()

## Whether any sound of this service is playing now.
func is_playing() -> bool:
	var live: Array = []
	var playing := false
	for player in _players:
		if is_instance_valid(player) and not player.is_queued_for_deletion():
			live.append(player)
			playing = playing or player.playing
	_players = live
	return playing

## Suspends the page's audio while nothing plays (no speaker icon); the page then ignores
## Godot's own resume() until _web_wake().
func _web_suspend() -> void:
	JavaScriptBridge.eval("window.bonAudioWanted = false; (window.bonAudioContexts || []).forEach(function (c) { if (c.state === 'running') { c.suspend(); } })", true)
	_web_awake = false

## Resumes the page's audio just before a sound starts.
func _web_wake() -> void:
	_web_check = WEB_IDLE_CHECK * 2.0
	if _web and not _web_awake:
		JavaScriptBridge.eval("window.bonAudioWanted = true; (window.bonAudioContexts || []).forEach(function (c) { if (c.state !== 'closed') { c.resume(); } })", true)
		_web_awake = true

func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_bind):
		get_tree().node_added.disconnect(_bind)
	# The board outlives the town: never leave it holding this service.
	var board = Board.shared()
	if board.started.is_connected(_on_activity_started):
		board.started.disconnect(_on_activity_started)
	if board.ended.is_connected(_on_activity_ended):
		board.ended.disconnect(_on_activity_ended)
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
		node.connect(signal_name, _play_bound.bind(binding["play"][signal_name], node))
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

## A bound signal's cue: positional at the node when the cue has a "distance" and the node is in
## 3D, else flat (play_ui). Bound signals carry no arguments (the cue and node are bound after).
func _play_bound(cue_id: String, node: Node) -> void:
	if node is Node3D and cues.get(cue_id, {}).has("distance"):
		play_at(cue_id, node)
	else:
		play_ui(cue_id)

## Plays a cue once, not positional (UI and reward sounds: the coin, right and wrong answers;
## 25 Nov 2026). Freed when done. Returns the player, or null when the cue has no sound.
func play_ui(cue_id: String) -> AudioStreamPlayer:
	var sound := stream(cue_id)
	if sound == null or not is_inside_tree():
		return null
	var cue: Dictionary = cues[cue_id]
	var player := AudioStreamPlayer.new()
	player.stream = sound
	player.bus = str(cue.get("bus", "UI"))
	player.volume_db = float(cue.get("volume_db", 0.0))
	player.set_meta("sound_cue", cue_id)
	add_child(player)
	_players.append(player)
	player.finished.connect(player.queue_free)
	_web_wake()
	player.play()
	return player

## Plays a cue once from `at` (a positional player under it, freed when done). Returns the player.
## A cue with "restart": true first stops the same cue still sounding at `at` (a door or bell
## used again quickly does not pile its sounds up).
func play_at(cue_id: String, at: Node3D) -> AudioStreamPlayer3D:
	if bool(cues.get(cue_id, {}).get("restart", false)) and is_instance_valid(at):
		for child in at.get_children():
			if child is AudioStreamPlayer3D and str(child.get_meta("sound_cue", "")) == cue_id and not child.has_meta("sound_loop"):
				child.stop()
				child.queue_free()
	var player := _player(cue_id, at)
	if player != null:
		player.finished.connect(player.queue_free)
		_web_wake()
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
		player.set_meta("sound_loop", true)
		_web_wake()
		player.play()
	return player

func stop_loop(cue_id: String, at: Node3D) -> void:
	var player := looping(cue_id, at)
	if player != null:
		player.stop()
		player.queue_free()

## --- Vehicle engines ----------------------------------------------------------------------------

## Engines (25 Nov 2026, user: a sound for driving): a looping cue with an "engine" section names
## the vehicle word keys it sounds for ("vehicles"; the cue with "default": true for any other).
## engine() keeps it looping at the vehicle while `running`, its pitch from pitch_idle to pitch_top
## and its volume from idle_db to 0 dB (on top of volume_db) as `speed` goes 0 -> 1, times the
## key's factor in "types". Stopping fades out over ENGINE_FADE s (no click).
const ENGINE_FADE := 0.25

## The engine cue for a vehicle word key ("" when none).
func engine_cue(kind: String) -> String:
	var fallback := ""
	for cue_id in cues:
		var tune: Dictionary = cues[cue_id].get("engine", {})
		if tune.is_empty():
			continue
		if kind in tune.get("vehicles", []):
			return cue_id
		if bool(tune.get("default", false)):
			fallback = cue_id
	return fallback

func engine(vehicle: Node3D, running: bool, speed: float, kind := "car") -> void:
	var cue_id := engine_cue(kind)
	if cue_id == "" or not is_instance_valid(vehicle):
		return
	var player := looping(cue_id, vehicle)
	if not running:
		if player != null:
			# Renamed first, so looping() no longer finds it and a restart makes a new one.
			player.name = _loop_name(cue_id) + " stopping"
			var fade := player.create_tween()
			fade.tween_property(player, "volume_db", -60.0, ENGINE_FADE)
			fade.tween_callback(player.queue_free)
		return
	if player == null:
		player = start_loop(cue_id, vehicle)
		if player == null:
			return
	var cue: Dictionary = cues[cue_id]
	var tune: Dictionary = cue.get("engine", {})
	var s := clampf(speed, 0.0, 1.0)
	var factor := float(tune.get("types", {}).get(kind, 1.0))
	player.pitch_scale = maxf(0.05, factor * lerpf(float(tune.get("pitch_idle", 1.0)), float(tune.get("pitch_top", 1.0)), s))
	player.volume_db = float(cue.get("volume_db", 0.0)) + lerpf(float(tune.get("idle_db", 0.0)), 0.0, s)

## The looping player of a cue at a node, else null.
func looping(cue_id: String, at: Node3D) -> AudioStreamPlayer3D:
	var player := at.get_node_or_null(NodePath(_loop_name(cue_id)))
	return player if player is AudioStreamPlayer3D and not player.is_queued_for_deletion() else null

## --- Background music --------------------------------------------------------------------------

## Plays a music track ("town", "loading"; the catalogue's music.tracks), fading out the one
## playing. Asking for the track already playing keeps it going. Returns false and plays nothing
## while music is off, in a check (the tree runs a script) or when the track has no sound.
func play_music(track: String) -> bool:
	if not bool(music.get("enabled", false)) or get_tree() == null or get_tree().get_script() != null:
		return false
	var current: AudioStreamPlayer = _music_players.get(track)
	if track == _music_now and current != null and current.playing:
		return true
	var cue_id := str(music.get("tracks", {}).get(track, ""))
	var clip := stream(cue_id) if cue_id != "" else null
	if clip == null:
		return false
	_fade_out_music(track)
	if current == null:
		current = AudioStreamPlayer.new()
		current.name = "Music " + track
		# Keeps playing (and fading) whatever pauses the game.
		current.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(current)
		_players.append(current)
		_music_players[track] = current
	var cue: Dictionary = cues[cue_id]
	current.stream = clip
	current.bus = _duck_bus(str(cue.get("bus", "Music")))
	current.set_meta("sound_cue", cue_id)
	var target := float(cue.get("volume_db", 0.0))
	var fade := float(music.get("fade_in", 0.0))
	_kill_fade(current)
	current.volume_db = -40.0 if fade > 0.0 else target
	_music_now = track
	music_changed.emit(track)
	_web_wake()
	current.play()
	if fade > 0.0:
		var tween := current.create_tween()
		tween.tween_property(current, "volume_db", target, fade)
		current.set_meta("music_fade", tween)
	return true

## A game's track while it runs (its activities.json "music"; none: town).
func activity_track(id: String) -> String:
	return str(Board.shared().activities.get(id, {}).get("music", "town"))

func _on_activity_started(id: String) -> void:
	if _music_now != "loading":
		play_music(activity_track(id))

func _on_activity_ended(_id: String, _summary: Dictionary) -> void:
	if _music_now != "loading":
		play_town()

## The town's own music: `town_track` (the record player's pick), or quiet after its Stop.
func play_town() -> bool:
	if town_track == "":
		stop_music()
		return false
	return play_music(town_track)

## The record player's choice (record_player_panel.gd): plays `track` now and keeps it as the
## town's music; "" stops the music until the next pick.
func pick_record(track: String) -> void:
	town_track = track
	play_town()

## The track asked for last, playing or still fading in ("" = none or stopped).
func music_wanted() -> String:
	return _music_now

## The music tracks in catalogue order (the record player's songs).
func track_names() -> Array:
	return (music.get("tracks", {}) as Dictionary).keys()

## DUCK_BUS, made once and sent to `to`, else `to` itself when it cannot be made.
func _duck_bus(to: String) -> String:
	if AudioServer.get_bus_index(DUCK_BUS) < 0:
		if AudioServer.get_bus_index(to) < 0:
			return to
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, DUCK_BUS)
		AudioServer.set_bus_send(index, to)
	return DUCK_BUS

## Dips the music for `seconds` (a spoken word), then brings it back.
func duck_music(seconds: float) -> void:
	var index := AudioServer.get_bus_index(DUCK_BUS)
	if index < 0:
		return
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	var set_db := func(db: float) -> void: AudioServer.set_bus_volume_db(index, db)
	_duck_tween = create_tween()
	_duck_tween.tween_method(set_db, AudioServer.get_bus_volume_db(index), DUCK_DB, 0.12)
	_duck_tween.tween_interval(seconds)
	_duck_tween.tween_method(set_db, DUCK_DB, 0.0, 0.6)

## Fades every music track out.
func stop_music() -> void:
	var was := _music_now
	_music_now = ""
	_fade_out_music("")
	if was != "":
		music_changed.emit("")

## The track asked for last, while it plays; else "".
func music_track() -> String:
	var player: AudioStreamPlayer = _music_players.get(_music_now)
	return _music_now if player != null and player.playing else ""

func music_playing() -> bool:
	return music_track() != ""

func _fade_out_music(keep: String) -> void:
	for track in _music_players:
		var player: AudioStreamPlayer = _music_players[track]
		if track == keep or not player.playing:
			continue
		_kill_fade(player)
		var tween := player.create_tween()
		tween.tween_property(player, "volume_db", -40.0, float(music.get("fade_out", 1.0)))
		tween.tween_callback(player.stop)
		player.set_meta("music_fade", tween)

func _kill_fade(player: AudioStreamPlayer) -> void:
	# has_meta first: get_meta() with a null default still logs an error when the key is missing.
	var tween: Tween = player.get_meta("music_fade") if player.has_meta("music_fade") else null
	if tween != null and tween.is_valid():
		tween.kill()

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

## --- Web voice packs (PERF-04) -------------------------------------------------------------

## Whether `lang`'s clips are in res:// now: always in the editor and desktop runs; on the web
## once its pack is mounted.
func voice_present(lang: String) -> bool:
	return lang != "" and DirAccess.dir_exists_absolute("%s/%s" % [str(voice.get("folder", "res://audio/voice")), lang])

## Makes sure the learned language's clips can be said. Nothing to do when they are already in
## res:// (or spoken words are off). On the web: reads voice/index.json next to the page; uses the
## pack kept in user://voice/ when it is the current one, else downloads it there; then mounts
## it. Offline, or when the index cannot be read, the kept pack is mounted as it is. A language
## with no pack, or a failed download, leaves its words silent (no speaker), with no error.
func ensure_voice(lang: String) -> void:
	_voice_lang = lang
	if lang == "" or not voice_enabled() or _voice_packs.has(lang):
		return
	if voice_present(lang):
		_voice_packs[lang] = "ready"
		return
	if not _web:
		_voice_packs[lang] = "none"
		return
	_voice_packs[lang] = "loading"
	var text := (await _fetch(VOICE_PACK_URL + "index.json?t=%d" % int(Time.get_unix_time_from_system()))).get_string_from_utf8()
	var index: Variant = JSON.parse_string(text) if text.begins_with("{") else null
	var packs: Variant = index.get("packs") if index is Dictionary else null
	var entry: Variant = packs.get(lang) if packs is Dictionary else null
	DirAccess.make_dir_recursive_absolute(VOICE_PACK_CACHE)
	var kept := _kept_packs(lang)
	# Offline, or the download fails: the pack kept last time, as it is.
	var file: String = kept[-1] if not kept.is_empty() else ""
	if entry is Dictionary and str(entry.get("file", "")).is_valid_filename():
		var wanted := str(entry.file)
		if kept.has(wanted):
			file = wanted
		else:
			var body := await _fetch(VOICE_PACK_URL + wanted)
			if not body.is_empty() and (not entry.has("bytes") or body.size() == int(entry.bytes)):
				var out := FileAccess.open("%s/%s" % [VOICE_PACK_CACHE, wanted], FileAccess.WRITE)
				if out != null:
					out.store_buffer(body)
					out.close()
					file = wanted
		if file == wanted:
			# Older packs of this language are never needed again.
			for old in kept:
				if old != wanted:
					DirAccess.remove_absolute("%s/%s" % [VOICE_PACK_CACHE, old])
	elif packs is Dictionary:
		file = ""  # the build has no pack for this language
	if file != "" and ProjectSettings.load_resource_pack("%s/%s" % [VOICE_PACK_CACHE, file]) and voice_present(lang):
		_voice_packs[lang] = "ready"
		voice_ready.emit(lang)
	else:
		_voice_packs[lang] = "none"

## The packs of `lang` kept in user://voice/ (<lang>-<hash>.pck).
func _kept_packs(lang: String) -> Array:
	var kept := []
	for name in DirAccess.get_files_at(VOICE_PACK_CACHE):
		if name.begins_with(lang + "-") and name.ends_with(".pck") and name.length() == lang.length() + 13:
			kept.append(name)
	return kept

## GETs a file next to the page; empty on any failure (offline, missing, not the web).
func _fetch(relative: String) -> PackedByteArray:
	var url = JavaScriptBridge.eval("new URL('%s', window.location.href).href" % relative.c_escape())
	if not url is String or url == "":
		return PackedByteArray()
	var request := HTTPRequest.new()
	request.timeout = VOICE_PACK_TIMEOUT
	add_child(request)
	var body := PackedByteArray()
	if request.request(url) == OK:
		var result: Array = await request.request_completed
		if result[0] == HTTPRequest.RESULT_SUCCESS and int(result[1]) == 200:
			body = result[3]
	request.queue_free()
	return body

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
		_players.append(_voice_player)
	_voice_player.stop()
	_voice_player.stream = clip
	_voice_player.bus = str(voice.get("bus", "Voice"))
	_voice_player.volume_db = float(voice.get("volume_db", 0.0))
	_voice_player.set_meta("sound_cue", cue_id)
	_web_wake()
	_voice_player.play()
	duck_music(clip.get_length())
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
	_players.append(player)
	return player
