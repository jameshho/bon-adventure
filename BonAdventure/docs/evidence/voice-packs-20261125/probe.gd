extends SceneTree
## Web voice pack probe (PERF-04, 25 Nov 2026, docs/guides/VOICE.md "Web packs"). Mounts one pack
## made by tools/voice_packs.gd in an EMPTY Godot project (not this one, whose res:// already has
## every clip) and loads clips from it. Copy this file into a folder with a minimal
## project.godot, then:
##   godot --headless --path <that folder> --script res://probe.gd -- <build>/voice/es-<hash>.pck es
## 25 Nov 2026: before mount the folder is absent; mounted true; apple 0.85 s, apple_pie 1.19 s,
## doctor 1.90 s load as AudioStreamOggVorbis; bamboo does not exist (no clip yet).
## index.json beside this file is the build's pack index from the same day.
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var pack: String = args[0]
	var lang: String = args[1]
	print("before mount, dir exists: ", DirAccess.dir_exists_absolute("res://audio/voice/" + lang))
	print("mounted: ", ProjectSettings.load_resource_pack(pack))
	print("after mount, dir exists: ", DirAccess.dir_exists_absolute("res://audio/voice/" + lang))
	var ok := 0
	var names := ["apple", "apple_pie", "doctor", "bamboo"]
	for n in names:
		var path := "res://audio/voice/%s/%s.ogg" % [lang, n]
		var exists := ResourceLoader.exists(path)
		var clip = load(path) if exists else null
		print("%s exists=%s clip=%s len=%s" % [n, exists, clip, clip.get_length() if clip else 0.0])
	quit(0)
