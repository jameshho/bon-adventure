extends RefCounted
## Where learner saves live, and how they are written (PWA restructure phase 1, 12 Nov 2026).
##
## Every profile keeps its own copy of the save files in user://profiles/<id>/
## (profile_manager.gd owns the list and picks the active one). With no active profile, the
## files stay in user:// itself: the layout from before profiles. That is what checks and
## tools see (they run with an isolated, empty HOME and keep using the old constants such as
## GameSettings.PATH), and what an old install has until its saves move into the first profile.
## Settings for the device, not the player, go in user://device.json (DEVICE_FILE).
##
## Writes go to "<file>.tmp" first and are then renamed over the file, so a crash or a closed
## tab never leaves half a save. read_only (set by Main while tools/bake_unit.gd bakes) makes
## every write a no-op.

## The profile folder layout; profile_manager.gd stores it in user://profiles/index.json.
const SCHEMA := 1
const PROFILES_DIR := "user://profiles"
const DEVICE_FILE := "user://device.json"
## The per-profile save files (names inside a profile folder, or user:// without a profile).
const PROFILE_FILES: Array[String] = [
	"settings.json",
	"vocabulary_progress_by_language.json",
	"vocabulary_apartment_progress.json",
	"vocabulary_town_bookmarks.json",
	"practice_log.json",
	"radar_patrol.json",
	# The player's last place (player_place.gd, 14 Nov 2026).
	"player_place.json",
]

## The active profile's folder ("user://profiles/p1"), or "" for the old flat layout.
static var profile_dir := ""
## True while baking: nothing is written.
static var read_only := false

## The full path of a per-profile save file, e.g. path("settings.json").
static func path(file: String) -> String:
	return (profile_dir if profile_dir != "" else "user://").path_join(file)

static func read_json(full_path: String) -> Variant:
	if not FileAccess.file_exists(full_path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(full_path))

static func write_json(full_path: String, data: Variant, indent: String = "") -> bool:
	return write_text(full_path, JSON.stringify(data, indent))

## Writes the whole file through a temporary file and a rename. False when nothing was written.
static func write_text(full_path: String, text: String) -> bool:
	if read_only:
		return false
	var dir := full_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var temp := full_path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_warning("save_store: cannot write " + temp)
		return false
	file.store_string(text)
	file.close()
	if DirAccess.rename_absolute(temp, full_path) == OK:
		return true
	# Platforms whose rename does not replace an existing file.
	DirAccess.remove_absolute(full_path)
	if DirAccess.rename_absolute(temp, full_path) == OK:
		return true
	push_warning("save_store: cannot replace " + full_path)
	return false

## Removes a folder and everything in it (a deleted profile).
static func remove_tree(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		remove_tree(dir_path.path_join(sub))
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(dir_path)
