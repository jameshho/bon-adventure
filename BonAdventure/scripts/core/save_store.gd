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
## tab never leaves half a save. A write that fails or comes up short (a full disk) leaves the
## old file as it was (25 Nov 2026). read_only (set by Main while tools/bake_unit.gd bakes) makes
## every write a no-op. A file that exists but does not parse is copied to
## "<file>.corrupt-<unix time>" once before anything can replace it (read_json, 25 Nov 2026).

## The profile folder layout; profile_manager.gd stores it in user://profiles/index.json.
const SCHEMA := 1
const PROFILES_DIR := "user://profiles"
const DEVICE_FILE := "user://device.json"
## The per-profile save files (names inside a profile folder, or user:// without a profile).
## A new save file goes here; a new shared() singleton that reads a profile save or holds session
## state must also be dropped in profile_manager.gd reset_singletons(), or it keeps the previous
## profile's data after a profile switch.
const PROFILE_FILES: Array[String] = [
	"settings.json",
	"vocabulary_progress_by_language.json",
	"vocabulary_apartment_progress.json",
	"vocabulary_town_bookmarks.json",
	"practice_log.json",
	"radar_patrol.json",
	# The player's last place (player_place.gd, 14 Nov 2026).
	"player_place.json",
	# Minigame levels and stars (game_progress.gd, 18 Nov 2026).
	"game_progress.json",
	# Achievements, town stamps and XP (achievements.gd, 21 Nov 2026).
	"achievements.json",
	# Town missions (missions.gd, 21 Nov 2026).
	"missions.json",
	# Mei's unfinished mahjong game and its scores (mahjong_session.gd, 23 Nov 2026).
	"mahjong.json",
	# Which words come up in the games (word_memory.gd, FSRS by steps, 24 Nov 2026).
	"word_memory.json",
]

## The active profile's folder ("user://profiles/p1"), or "" for the old flat layout.
static var profile_dir := ""
## True while baking: nothing is written.
static var read_only := false
## Checks only: makes the next writes fail after the temp file is opened (a full disk).
static var fail_writes_for_test := false
## Corrupt files already backed up in this run (a path is backed up once).
static var _backed_up := {}

## The full path of a per-profile save file, e.g. path("settings.json").
static func path(file: String) -> String:
	return (profile_dir if profile_dir != "" else "user://").path_join(file)

## The parsed file (a Dictionary or Array), or null when it is missing or does not parse; a file
## that does not parse is kept as a backup first (backup_corrupt()).
static func read_json(full_path: String) -> Variant:
	if not FileAccess.file_exists(full_path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(full_path))
	if parsed is Dictionary or parsed is Array:
		return parsed
	backup_corrupt(full_path)
	return null

## Copies an unreadable save to "<file>.corrupt-<unix time>" (once per run) with a warning, so the
## next save cannot destroy what a recovery might still read. Returns the backup's path.
static func backup_corrupt(full_path: String) -> String:
	if _backed_up.has(full_path):
		return str(_backed_up[full_path])
	var backup := "%s.corrupt-%d" % [full_path, int(Time.get_unix_time_from_system())]
	if read_only or DirAccess.copy_absolute(ProjectSettings.globalize_path(full_path), ProjectSettings.globalize_path(backup)) != OK:
		push_warning("save_store: %s does not parse and could not be backed up" % full_path)
		backup = ""
	else:
		push_warning("save_store: %s does not parse; kept a copy as %s" % [full_path, backup.get_file()])
	_backed_up[full_path] = backup
	return backup

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
	var stored := file.store_string(text) and not fail_writes_for_test
	stored = stored and file.get_error() == OK
	file.close()
	# A short write (a full disk) is caught by the size as well.
	var check := FileAccess.open(temp, FileAccess.READ)
	var length := check.get_length() if check != null else -1
	check = null  # closes it before the rename
	if not stored or length != text.to_utf8_buffer().size():
		DirAccess.remove_absolute(temp)
		push_warning("save_store: writing %s failed; the old file is kept" % full_path)
		return false
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
