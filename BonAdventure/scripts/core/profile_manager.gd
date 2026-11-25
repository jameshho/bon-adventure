extends RefCounted
## Local player profiles (PWA restructure, user decisions 12 Nov 2026): at most MAX_PROFILES on
## a device, each with the player's name, a profile name (how the game addresses them) and an
## avatar (a cast id in data/npcs.json). The list is user://profiles/index.json:
##   {"schema": 1, "next": 3, "last": "p1",
##    "profiles": [{"id": "p1", "name": "Ana", "profile_name": "Ana's town", "avatar": "bonbon"}]}
## Ids are never reused. Each profile's saves are in user://profiles/<id>/ (save_store.gd).
##
## select(id) points every save at that profile and drops the shared() singletons that hold
## profile data, so they reload from the new folder; the app scene restarts the town after it.
## Main calls use_default() at startup: with nothing selected it takes the last used profile,
## and with no profiles at all the saves stay in user:// (checks, tools, a first launch).
## The first profile created adopts those older user:// saves as copies; the originals stay
## as a backup.
const SaveStore := preload("res://scripts/core/save_store.gd")
const INDEX_PATH := "user://profiles/index.json"
const MAX_PROFILES := 3
const MAX_NAME_LENGTH := 24
const DEFAULT_AVATAR := "bonbon"

static var _shared

var index: Dictionary = {}
## The selected profile's id, or "" (old flat layout).
var active_id := ""

static func shared():
	if _shared == null:
		_shared = new()
		_shared.load_index()
	return _shared

func load_index() -> void:
	var parsed: Variant = SaveStore.read_json(INDEX_PATH)
	index = parsed if parsed is Dictionary else {}
	index["schema"] = SaveStore.SCHEMA
	index["next"] = int(index.get("next", 1))
	if not index.get("profiles") is Array:
		index["profiles"] = []
	index["last"] = str(index.get("last", ""))
	# A saved avatar that is no longer a house character (e.g. the pig's id before the BonBon
	# rename, 16 Nov 2026) loads as DEFAULT_AVATAR, and the list is saved that way.
	var known := avatar_ids()
	var changed := false
	if known.is_empty():
		return  # the character data could not be read: change nothing
	for entry in index.profiles:
		if entry is Dictionary and not known.has(str(entry.get("avatar", ""))):
			entry["avatar"] = DEFAULT_AVATAR
			changed = true
	if changed:
		save_index()

func save_index() -> bool:
	return SaveStore.write_json(INDEX_PATH, index, "  ")

## Copies of every profile entry, in creation order.
func profiles() -> Array:
	return index.profiles.duplicate(true)

func get_profile(id: String) -> Dictionary:
	for entry in index.profiles:
		if str(entry.get("id", "")) == id:
			return entry.duplicate()
	return {}

func active_profile() -> Dictionary:
	return get_profile(active_id)

func can_create() -> bool:
	return index.profiles.size() < MAX_PROFILES

## Avatar ids the player may pick: the house characters, in data order.
static func avatar_ids() -> Array:
	return preload("res://scripts/characters/house_characters.gd").ids()

## A trimmed, length-limited name ("" when blank).
static func clean_name(text: String) -> String:
	return text.strip_edges().left(MAX_NAME_LENGTH)

## True when user:// still has saves from before profiles (they move into the first profile).
func has_legacy_saves() -> bool:
	if not index.profiles.is_empty():
		return false
	for file in SaveStore.PROFILE_FILES:
		if FileAccess.file_exists("user://".path_join(file)):
			return true
	return false

## A new profile; returns its id, or "" when the names are blank, the avatar is unknown or
## MAX_PROFILES already exist. The first profile receives copies of the older user:// saves.
func create(player_name: String, profile_name: String, avatar: String = DEFAULT_AVATAR) -> String:
	player_name = clean_name(player_name)
	profile_name = clean_name(profile_name)
	if player_name == "" or profile_name == "" or not can_create() or not avatar_ids().has(avatar):
		return ""
	var adopt := has_legacy_saves()
	var id := "p%d" % index.next
	var dir := SaveStore.PROFILES_DIR.path_join(id)
	if not SaveStore.read_only:
		DirAccess.make_dir_recursive_absolute(dir)
	if adopt and not SaveStore.read_only:
		for file in SaveStore.PROFILE_FILES:
			var source := "user://".path_join(file)
			if FileAccess.file_exists(source):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(dir.path_join(file)))
	index.next = int(index.next) + 1
	index.profiles.append({"id": id, "name": player_name, "profile_name": profile_name, "avatar": avatar})
	save_index()
	return id

## Changes name, profile_name or avatar of a profile (other keys are kept). False when unknown
## or a value is invalid.
func update(id: String, fields: Dictionary) -> bool:
	for entry in index.profiles:
		if str(entry.get("id", "")) != id:
			continue
		var changed := {}
		for key in fields:
			var value: Variant = fields[key]
			if key in ["name", "profile_name"]:
				value = clean_name(str(value))
				if value == "":
					return false
			elif key == "avatar" and not avatar_ids().has(str(value)):
				return false
			changed[key] = value
		entry.merge(changed, true)
		save_index()
		return true
	return false

func rename(id: String, profile_name: String) -> bool:
	return update(id, {"profile_name": profile_name})

## Deletes a profile and its saves. The active profile cannot be deleted.
func delete(id: String) -> bool:
	if id == active_id or get_profile(id).is_empty():
		return false
	index.profiles = index.profiles.filter(func(entry) -> bool: return str(entry.get("id", "")) != id)
	if index.last == id:
		index.last = ""
	if not SaveStore.read_only:
		SaveStore.remove_tree(SaveStore.PROFILES_DIR.path_join(id))
	save_index()
	return true

## Points every save at this profile ("" = the flat user:// layout) and resets the shared
## singletons that hold profile data. The caller restarts the town (the app scene does).
func select(id: String) -> bool:
	if id != "" and get_profile(id).is_empty():
		return false
	active_id = id
	SaveStore.profile_dir = SaveStore.PROFILES_DIR.path_join(id) if id != "" else ""
	if id != "" and index.last != id:
		index.last = id
		save_index()
	reset_singletons()
	return true

## Main at startup: keep the selection, else the last used profile, else the flat layout.
func use_default() -> void:
	if active_id != "":
		return
	var last := str(index.get("last", ""))
	if last != "" and not get_profile(last).is_empty():
		select(last)

## Drops the shared() objects that read profile saves or hold session state, so the next
## shared() call builds them again (the Lexicon keeps its data; GameSettings.apply() resets
## its languages).
static func reset_singletons() -> void:
	preload("res://scripts/core/game_settings.gd")._shared = null
	preload("res://scripts/learning/practice_log.gd")._shared = null
	preload("res://scripts/learning/word_memory.gd")._shared = null
	preload("res://scripts/learning/activity_board.gd")._shared = null
	preload("res://scripts/learning/game_clock.gd")._shared = null
	preload("res://scripts/learning/game_progress.gd")._shared = null
	preload("res://scripts/learning/achievements.gd")._shared = null
	preload("res://scripts/learning/missions.gd")._shared = null
