extends SceneTree
## Demo background music (25 Nov 2026): the town and loading tracks in the catalogue, their
## imported loops, the Music bus, and that checks (a SceneTree script, like this one) never play
## music. Silent: never plays anything and loads no town. Writes no files.
##   godot --headless --path . --script res://docs/evidence/lofi-music-20261125/verify.gd
const Sound := preload("res://scripts/core/sound.gd")
## Track -> expected length in seconds (tools/make_lofi_demo.py).
const LENGTHS := {"town": 53.3, "loading": 34.3}

var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", label)

func _initialize() -> void:
	var sound = Sound.new()
	root.add_child(sound)
	await process_frame
	var music: Dictionary = sound.music
	check(bool(music.get("enabled", false)), "music enabled")
	check(AudioServer.get_bus_index("Music") >= 0, "Music bus exists")
	var tracks: Dictionary = music.get("tracks", {})
	check(tracks.size() == LENGTHS.size(), "two tracks (town, loading)")
	check(str(tracks.get("town", "")) != str(tracks.get("loading", "")), "loading has its own track")
	for track in LENGTHS:
		var cue_id := str(tracks.get(track, ""))
		check(sound.cues.has(cue_id), track + ": cue in catalogue")
		var cue: Dictionary = sound.cues.get(cue_id, {})
		check(str(cue.get("bus", "")) == "Music", track + ": on Music bus")
		check(bool(cue.get("loop", false)), track + ": cue says loop")
		var clip = sound.stream(cue_id)
		check(clip is AudioStreamWAV, track + ": loads as AudioStreamWAV")
		if clip is AudioStreamWAV:
			check(clip.loop_mode == AudioStreamWAV.LOOP_FORWARD, track + ": imported as forward loop")
			var length: float = clip.get_length()
			check(absf(length - LENGTHS[track]) < 0.5, track + ": length %.1f s" % length)
			print("%s: %.1f s, format %d, mix rate %d" % [track, length, clip.format, clip.mix_rate])
	check(not sound.play_music("loading") and not sound.play_music("town"), "play_music refuses in a check")
	check(not sound.music_playing() and not sound.is_playing(), "nothing plays in a check")
	check(sound.get_child_count() == 0, "no music player in a check")
	print("LOFI MUSIC: %d failures" % failures)
	sound.queue_free()
	quit(1 if failures > 0 else 0)
