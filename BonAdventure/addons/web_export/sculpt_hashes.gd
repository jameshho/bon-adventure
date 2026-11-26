@tool
extends EditorExportPlugin
## Every export (PERF-03, 25 Nov 2026): the pack keeps scripts as tokens without their source,
## and the plush sculpt cache keys on the source (scripts/characters/sculpt_cache.gd), so it was
## off in every exported build and the web sculpted every plush again on each launch and each
## late building. This writes SculptCache.source_hash_of() of every script in the characters
## folder, from the sources being packed, as res://sculpt_hashes.json; the game reads it there.
const SculptCache := preload("res://scripts/characters/sculpt_cache.gd")

func _get_name() -> String:
	return "SculptHashes"

func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	var hashes := {}
	_collect(SculptCache.CHARACTER_SCRIPTS, hashes)
	add_file(SculptCache.HASHES, JSON.stringify(hashes, "\t", true).to_utf8_buffer(), false)

func _collect(folder: String, hashes: Dictionary) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() != "gd":
			continue
		var script := load(folder + file) as Script
		var hash := SculptCache.source_hash_of(script) if script != null else ""
		if hash != "":
			hashes[folder + file] = hash
	for sub in DirAccess.get_directories_at(folder):
		_collect(folder + sub + "/", hashes)
