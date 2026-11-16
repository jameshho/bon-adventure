@tool
extends EditorExportPlugin
## Web exports only (12 Nov 2026, PWA phase 7): every scene file over MIN_BYTES goes into the
## pck as a compressed binary scene, remapped from its own path, so the pck stays under GitHub
## Pages' 100 MB file limit (the baked town alone, scenes/town/base.scn, is 72 MB raw). The
## files in the project are untouched. The scene is loaded and saved again (not converted file
## to file), so instance overrides equal to a default value survive; see the README's
## "Web app (PWA)" for why exports otherwise keep scenes as text.
const MIN_BYTES := 256 * 1024
const OUT := "user://web_export/"

var _web := false

func _get_name() -> String:
	return "CompressScenes"

func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	_web = features.has("web")
	if _web:
		DirAccess.make_dir_recursive_absolute(OUT)

func _export_file(path: String, type: String, _features: PackedStringArray) -> void:
	if not _web or type != "PackedScene" or not path.get_extension() in ["tscn", "scn"]:
		return
	if FileAccess.get_size(path) < MIN_BYTES:
		return
	var scene := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if scene == null:
		push_warning("web_export: could not load " + path)
		return
	var temp := OUT + path.md5_text() + ".scn"
	if ResourceSaver.save(scene, temp, ResourceSaver.FLAG_COMPRESS) != OK:
		push_warning("web_export: could not save " + path)
		return
	var bytes := FileAccess.get_file_as_bytes(temp)
	DirAccess.remove_absolute(temp)
	# Remapped: loading `path` in the game opens the compressed copy.
	add_file(path.get_basename() + ".compressed.scn", bytes, true)
