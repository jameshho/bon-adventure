extends SceneTree
## Profiles and the save store (PWA restructure phase 1, 12 Nov 2026): the flat user:// layout
## without profiles, the first profile adopting older saves as copies, at most 3 profiles,
## per-profile settings / progress / practice counts, rename / avatar / delete, ids never
## reused, the last used profile at startup, atomic writes and read-only baking.
## Writes save files, so it needs an isolated HOME and refuses to run when saves exist:
## HOME=<scratch>/home godot --headless --path . --script res://docs/evidence/profiles-20261112/verify.gd
## Prints "PROFILES: N checks, M failures".
const SaveStore := preload("res://scripts/core/save_store.gd")
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Progress := preload("res://scripts/learning/vocabulary_progress.gd")
const SaveMigration := preload("res://scripts/core/save_migration.gd")
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func run():
	for file in SaveStore.PROFILE_FILES + ["profiles/index.json"]:
		if FileAccess.file_exists("user://" + file):
			print("PROFILES: refusing to run, user://%s exists (use an isolated HOME)" % file)
			quit(1)
			return
	# 1. No profiles: the flat layout.
	var manager = ProfileManager.shared()
	manager.use_default()
	check(manager.active_id == "" and SaveStore.path("settings.json") == GameSettings.PATH, "without profiles the saves stay in user://")
	check(not manager.has_legacy_saves(), "an empty user:// has no older saves")
	# 2. Older saves move into the first profile as copies.
	SaveStore.write_json(GameSettings.PATH, {"display": GameSettings.NATIVE, "native": "en", "foreign": "es", "outfit": ""})
	SaveStore.write_json(Progress.LANGUAGE_FILE, {"es": ["sofa", "tap"]})
	SaveStore.write_json(PracticeLog.PATH, {"es": {"sofa": {"shop_supermarket": {"positive": 2, "negative": 0, "translated": 0}}}})
	check(manager.has_legacy_saves(), "older saves are found")
	check(manager.create("", "Town", "bonbon") == "" and manager.create("Ana", "  ", "bonbon") == "", "blank names are refused")
	check(manager.create("Ana", "Town", "dragon") == "", "an unknown avatar is refused")
	var first: String = manager.create("  Ana  ", "Ana's town", "leo")
	check(first == "p1", "the first profile is p1 (got %s)" % first)
	check(manager.get_profile(first).get("name") == "Ana" and manager.get_profile(first).get("avatar") == "leo", "names are trimmed and the avatar kept")
	for file in ["settings.json", "vocabulary_progress_by_language.json", "practice_log.json"]:
		check(FileAccess.file_exists("user://profiles/p1/" + file), "the first profile has a copy of " + file)
		check(FileAccess.file_exists("user://" + file), "the original " + file + " stays as a backup")
	var second: String = manager.create("Ben", "Ben", "bruno")
	var third: String = manager.create("Cy", "Cy", "miso")
	check(second == "p2" and third == "p3", "later profiles are p2 and p3")
	check(not FileAccess.file_exists("user://profiles/p2/settings.json"), "only the first profile adopts older saves")
	check(manager.create("Dee", "Dee", "bonbon") == "" and not manager.can_create(), "at most 3 profiles")
	# 3. Each profile reads and writes its own saves.
	check(manager.select(first), "select p1")
	var settings = GameSettings.shared()
	check(settings.display == GameSettings.NATIVE, "p1 loads the adopted settings")
	settings.set_display(GameSettings.FOREIGN)
	check(int(SaveStore.read_json("user://profiles/p1/settings.json").display) == GameSettings.FOREIGN, "p1 saves into its own folder")
	check(int(SaveStore.read_json(GameSettings.PATH).display) == GameSettings.NATIVE, "the backup in user:// is not written")
	check(Progress.load_studied_words({}, {}, "es").has("sofa"), "p1 has the adopted progress")
	check(PracticeLog.shared().counts.get("es", {}).has("sofa"), "p1 has the adopted practice counts")
	check(manager.select(second), "select p2")
	check(GameSettings.shared() != settings and GameSettings.shared().display == GameSettings.DEFAULT_DISPLAY, "switching resets the settings singleton to p2's defaults")
	check(Progress.load_studied_words({}, {}, "es").is_empty(), "p2 starts with no progress")
	check(PracticeLog.shared().counts.is_empty(), "p2 starts with no practice counts")
	Progress.save_bookmarked_words({"tap": true})
	check(FileAccess.file_exists("user://profiles/p2/vocabulary_town_bookmarks.json") and not FileAccess.file_exists(Progress.BOOKMARKS_FILE), "bookmarks are saved per profile")
	check(DirAccess.get_files_at("user://profiles/p2").size() > 0 and Array(DirAccess.get_files_at("user://profiles/p2")).all(func(f): return not f.ends_with(".tmp")), "atomic writes leave no temporary files")
	# 4. Rename, avatar, delete.
	check(manager.rename(second, "Ben's place") and manager.get_profile(second).profile_name == "Ben's place", "rename")
	check(not manager.update(second, {"avatar": "dragon"}) and manager.update(second, {"avatar": "poppy", "tutorial_done": true}), "avatar is validated; other fields are kept")
	check(not manager.delete(second), "the active profile cannot be deleted")
	check(manager.delete(third) and not DirAccess.dir_exists_absolute("user://profiles/p3"), "delete removes the profile and its folder")
	check(manager.create("Eve", "Eve", "sunny") == "p4", "ids are never reused")
	# 5. The index on disk, and the last used profile at startup.
	var reloaded = ProfileManager.new()
	reloaded.load_index()
	check(reloaded.profiles().size() == 3 and int(reloaded.index.schema) == SaveStore.SCHEMA, "the index reloads with 3 profiles and the schema version")
	check(reloaded.get_profile(second).get("tutorial_done") == true, "extra profile fields are saved")
	reloaded.use_default()
	check(reloaded.active_id == second, "startup takes the last used profile")
	check(SaveMigration.run() == 0, "the project-rename move does nothing once profiles exist")
	# 6. Baking writes nothing.
	SaveStore.read_only = true
	check(not SaveStore.write_json("user://profiles/p2/read_only.json", {}) and not FileAccess.file_exists("user://profiles/p2/read_only.json"), "read_only blocks writes")
	SaveStore.read_only = false
	# Clean up.
	SaveStore.remove_tree("user://profiles")
	for file in SaveStore.PROFILE_FILES:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + file))
	print("PROFILES: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
