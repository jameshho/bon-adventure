extends SceneTree
## Spoken-word packs for the web (PERF-04, decision D7, 25 Nov 2026; guide docs/guides/VOICE.md
## "Web packs"). The Web preset leaves audio/voice/ out of index.pck; this tool writes one Godot
## resource pack per language instead, so a player downloads only the language being learned
## (sound.gd ensure_voice()).
##
##   godot --headless --path . --script res://tools/voice_packs.gd -- --out <folder>
##
## For every language in data/languages.json that has a folder under the catalogue's voice
## "folder" (data/sounds.json), it packs each clip's .import file and its imported stream
## (.godot/imported/..., so run it after an import or export) into <out>/<lang>-<md5 8>.pck, and
## writes <out>/index.json: {"format": 1, "packs": {lang: {"file", "bytes", "clips"}}}. The file
## name changes whenever a clip does, so browsers never keep a stale pack. A clip whose imported
## file is missing is skipped with a warning (the game then hides its speaker, as for a word with
## no clip). tools/deploy_web.py runs this into <build>/voice/. Writes nothing inside the project.
const LANGUAGES := "res://data/languages.json"
const SOUNDS := "res://data/sounds.json"

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--out")
	if at < 0 or at + 1 >= args.size():
		printerr("voice_packs: usage: -- --out <folder outside the project>")
		quit(1)
		return
	var out := ProjectSettings.globalize_path(args[at + 1]).simplify_path()
	if out.begins_with(ProjectSettings.globalize_path("res://").simplify_path()):
		printerr("voice_packs: --out must be outside the project")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out)
	var languages: Dictionary = _json(LANGUAGES).get("languages", {})
	var folder := str(_json(SOUNDS).get("voice", {}).get("folder", "res://audio/voice"))
	var index := {"format": 1, "packs": {}}
	var problems := 0
	for lang in languages:
		var dir := "%s/%s" % [folder, lang]
		if not DirAccess.dir_exists_absolute(dir):
			continue
		var clips := []
		for name in DirAccess.get_files_at(dir):
			if name.ends_with(".ogg.import"):
				clips.append(name)
		clips.sort()
		var temp := "%s/%s.pck.part" % [out, lang]
		var packer := PCKPacker.new()
		if packer.pck_start(temp) != OK:
			printerr("voice_packs: cannot write " + temp)
			quit(1)
			return
		var packed := 0
		for name in clips:
			var import_path := "%s/%s" % [dir, name]
			var config := ConfigFile.new()
			var imported := ""
			if config.load(import_path) == OK:
				imported = str(config.get_value("remap", "path", ""))
			if imported == "" or not FileAccess.file_exists(imported):
				push_warning("voice_packs: %s has no imported clip; left out" % import_path)
				problems += 1
				continue
			packer.add_file(import_path, import_path)
			packer.add_file(imported, imported)
			packed += 1
		packer.flush()
		var file := "%s-%s.pck" % [lang, FileAccess.get_md5(temp).substr(0, 8)]
		var final_path := "%s/%s" % [out, file]
		if FileAccess.file_exists(final_path):
			DirAccess.remove_absolute(final_path)
		DirAccess.rename_absolute(temp, final_path)
		var bytes := FileAccess.get_file_as_bytes(final_path).size()
		index.packs[lang] = {"file": file, "bytes": bytes, "clips": packed}
		print("voice_packs: %s  %d clips  %.2f MB" % [file, packed, bytes / 1e6])
	var index_file := FileAccess.open(out + "/index.json", FileAccess.WRITE)
	index_file.store_string(JSON.stringify(index, "  "))
	index_file.close()
	print("VOICE PACKS: %d languages in %s; %d clips left out" % [index.packs.size(), out, problems])
	quit(0)

func _json(path: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}
