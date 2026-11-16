extends RefCounted
## One-time save move after a project rename. Godot scopes user:// by the project's
## config/name on desktop, so renaming the project points the game at an empty folder.
## On start-up (before anything reads user://), if the current folder has no saves at all
## (no profiles, no device settings, none of the flat save files), copy everything from the
## most recent earlier folder that has saves: the whole tree, so profiles/ (index.json and
## every profile folder) and device.json come along as well as the old flat layout.
## Nothing is overwritten and the old folder is left as a backup. In a browser user:// is
## always /userfs (the site's IndexedDB) whatever the name, so there is nothing to move; runs
## with an isolated HOME or a custom user dir (checks, test copies) find no sibling folder.

## Earlier project names, newest first. Godot names the folder after config/name with the
## characters a folder name cannot hold replaced (OS.get_safe_dir_name), as below.
## "Vocabulary Town" -> "Bon Adventure": user decision, 16 Nov 2026 (the game is "Bon Adventure:
## Little Town of Words"; the short name keeps the folder name plain).
const PREVIOUS_NAMES: Array[String] = ["Vocabulary Town", "Vocabulary Town v0.21 - Discovery Missions"]
const SaveStore := preload("res://scripts/core/save_store.gd")
## The save files of the flat layout (before profiles); save_store.gd owns the list.
const SAVE_FILES := SaveStore.PROFILE_FILES
const PROFILE_INDEX := "user://profiles/index.json"

static func run() -> int:
    if SaveStore.read_only or FileAccess.file_exists(PROFILE_INDEX) or FileAccess.file_exists(SaveStore.DEVICE_FILE):
        return 0
    var here := OS.get_user_data_dir()
    for file in SAVE_FILES:
        if FileAccess.file_exists(here.path_join(file)): return 0
    for name in PREVIOUS_NAMES:
        var old := here.get_base_dir().path_join(name.validate_filename())
        if old == here or not DirAccess.dir_exists_absolute(old) or not _has_saves(old): continue
        var copied := _copy_tree(old, here)
        if copied > 0:
            print("Save migration: copied ", copied, " save files from ", old)
            return copied
    return 0

static func _has_saves(folder: String) -> bool:
    if FileAccess.file_exists(folder.path_join("profiles/index.json")): return true
    for file in SAVE_FILES:
        if FileAccess.file_exists(folder.path_join(file)): return true
    return false

## Copies every file under `from` into `to` (folders made as needed), never overwriting.
## Godot's own folders in user:// (logs, shader_cache, vulkan) are left behind.
static func _copy_tree(from: String, to: String) -> int:
    var copied := 0
    DirAccess.make_dir_recursive_absolute(to)
    for file in DirAccess.get_files_at(from):
        var target := to.path_join(file)
        if not FileAccess.file_exists(target) and DirAccess.copy_absolute(from.path_join(file), target) == OK:
            copied += 1
    for folder in DirAccess.get_directories_at(from):
        if folder in ["logs", "shader_cache", "vulkan"]: continue
        copied += _copy_tree(from.path_join(folder), to.path_join(folder))
    return copied
