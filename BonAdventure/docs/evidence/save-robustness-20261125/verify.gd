extends SceneTree
## Save robustness (improvement plan C1: ARCH-01…05, 25 Nov 2026). Headless, without the town:
## - a failed write leaves the old file byte-identical and no temp file behind,
## - a file that does not parse (word_memory.json, settings.json) is backed up once as
##   "<file>.corrupt-<unix>" and the game's singletons still load,
## - studied words: unknown keys are left out in memory but saved back unchanged (bookmarks too),
##   and saving one language keeps the others,
## - a corrupt or lost profiles/index.json is rebuilt from the p* folders, their files unchanged,
##   "next" above every folder, and older flat saves never copied into an existing folder,
## - SessionWords lists a new player's words after a profile reset.
## Writes save files, so it needs an isolated HOME and refuses to run when saves exist:
##   HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/save-robustness-20261125/verify.gd
## Prints "SAVE ROBUSTNESS: N checks, M failures".
const SaveStore := preload("res://scripts/core/save_store.gd")
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PracticeLog := preload("res://scripts/learning/practice_log.gd")
const Progress := preload("res://scripts/learning/vocabulary_progress.gd")
const WordMemory := preload("res://scripts/learning/word_memory.gd")
const SessionWords := preload("res://scripts/learning/session_words.gd")
var failures := 0
var checks := 0

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func write_raw(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

## Files in `dir` whose names start with `prefix`.
func files_like(dir: String, prefix: String) -> Array:
	return Array(DirAccess.get_files_at(dir)).filter(func(f: String) -> bool: return f.begins_with(prefix))

## Every file under user://profiles/p* with its text.
func profile_files() -> Dictionary:
	var result := {}
	for number in ProfileManager.profile_folders():
		var dir := SaveStore.PROFILES_DIR.path_join("p%d" % number)
		for file in DirAccess.get_files_at(dir):
			result[dir.path_join(file)] = FileAccess.get_file_as_string(dir.path_join(file))
	return result

func run():
	for file in SaveStore.PROFILE_FILES + ["profiles/index.json"]:
		if FileAccess.file_exists("user://" + file):
			print("SAVE ROBUSTNESS: refusing to run, user://%s exists (use an isolated HOME)" % file)
			quit(1)
			return
	failed_write()
	corrupt_files()
	studied_words()
	session_words()
	corrupt_index()
	print("SAVE ROBUSTNESS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

# ARCH-01 -------------------------------------------------------------------------------------
func failed_write() -> void:
	var path := "user://robust_write.json"
	check(SaveStore.write_json(path, {"good": true}), "a normal write succeeds")
	var before := FileAccess.get_file_as_bytes(path)
	SaveStore.fail_writes_for_test = true
	var ok := SaveStore.write_json(path, {"good": false, "longer": "text"})
	SaveStore.fail_writes_for_test = false
	check(not ok, "a failed write returns false")
	check(FileAccess.get_file_as_bytes(path) == before, "a failed write leaves the old file byte-identical")
	check(not FileAccess.file_exists(path + ".tmp"), "a failed write removes its temp file")
	check(SaveStore.write_json(path, {"good": 2}) and SaveStore.read_json(path).good == 2, "writes work again afterwards")

# ARCH-02 -------------------------------------------------------------------------------------
func corrupt_files() -> void:
	write_raw(SaveStore.path(WordMemory.FILE), "{\"es\": {\"step\": 4, ")
	write_raw(GameSettings.PATH, "not json at all")
	check(SaveStore.read_json(SaveStore.path(WordMemory.FILE)) == null, "a corrupt file reads as null")
	SaveStore.read_json(SaveStore.path(WordMemory.FILE))
	var backups := files_like("user://", WordMemory.FILE + ".corrupt-")
	check(backups.size() == 1, "a corrupt word_memory.json is backed up once (%s)" % [backups])
	if backups.size() == 1:
		check(FileAccess.get_file_as_string("user://" + backups[0]) == "{\"es\": {\"step\": 4, ", "the backup holds the corrupt text")
	# The game still starts: the settings and the word memory load (and may save) after a backup.
	GameSettings._shared = null
	var settings = GameSettings.shared()
	check(settings != null, "the settings load from a corrupt file")
	check(files_like("user://", "settings.json.corrupt-").size() == 1, "a corrupt settings.json is backed up")
	settings.save()
	check(SaveStore.read_json(GameSettings.PATH) is Dictionary, "settings save again over the corrupt file")
	WordMemory._shared = null
	check(WordMemory.shared().step() == 0, "the word memory starts fresh from a corrupt file")
	check(SaveStore.read_json("user://robust_missing.json") == null and files_like("user://", "robust_missing").is_empty(), "a missing file is not backed up")

# ARCH-04 + ARCH-02 (languages kept) ----------------------------------------------------------
func studied_words() -> void:
	var valid := {"sofa": true, "tap": true, "lamp": true}
	var aliases := {"couch": "sofa"}
	SaveStore.write_json(Progress.LANGUAGE_FILE, {"es": ["sofa", "gone_word"], "fr": ["lamp"]})
	var before := FileAccess.get_file_as_string(Progress.LANGUAGE_FILE)
	var studied: Dictionary = Progress.load_studied_words(valid, aliases, "es")
	check(studied.keys() == ["sofa"], "an unknown studied key is left out in memory (%s)" % [studied.keys()])
	check(FileAccess.get_file_as_string(Progress.LANGUAGE_FILE) == before, "loading does not rewrite the save")
	studied["tap"] = true
	Progress.save_studied_words(studied, valid, aliases, "es")
	var saved: Dictionary = SaveStore.read_json(Progress.LANGUAGE_FILE)
	check(saved.es.has("gone_word") and saved.es.has("sofa") and saved.es.has("tap"), "an unknown key is saved back unchanged (%s)" % [saved.es])
	check(saved.get("fr") == ["lamp"], "saving Spanish keeps the French words")
	SaveStore.write_json(Progress.LANGUAGE_FILE, {"es": ["couch", "gone_word"]})
	studied = Progress.load_studied_words(valid, aliases, "es")
	saved = SaveStore.read_json(Progress.LANGUAGE_FILE)
	check(studied.keys() == ["sofa"] and saved.es.has("sofa") and not saved.es.has("couch") and saved.es.has("gone_word"), "an alias is still saved as its canonical key, the unknown key kept (%s)" % [saved.es])
	SaveStore.write_json(Progress.BOOKMARKS_FILE, ["lamp", "gone_word"])
	var marks: Dictionary = Progress.load_bookmarked_words(valid, aliases)
	check(marks.keys() == ["lamp"], "an unknown bookmark is left out in memory")
	marks.erase("lamp")
	marks["tap"] = true
	Progress.save_bookmarked_words(marks, valid, aliases)
	var saved_marks: Array = SaveStore.read_json(Progress.BOOKMARKS_FILE)
	check(saved_marks.has("tap") and saved_marks.has("gone_word") and not saved_marks.has("lamp"), "bookmarks keep unknown keys; a removed one goes (%s)" % [saved_marks])

# ARCH-05 -------------------------------------------------------------------------------------
func record(game: String, key: String) -> void:
	PracticeLog.shared().begin(game, [key])
	PracticeLog.shared().first_answer(true)
	PracticeLog.shared().complete()

func session_words() -> void:
	GameSettings.shared().set_languages("en", "es")
	SessionWords.shared().start("robust_game")
	record("robust_game", "sofa")
	check(not SessionWords.shared().summary().all.is_empty(), "SessionWords lists the first player's word")
	ProfileManager.reset_singletons()
	check(SessionWords._shared == null, "the profile reset drops SessionWords")
	GameSettings.shared().set_languages("en", "es")
	SessionWords.shared().start("robust_game")
	record("robust_game", "tap")
	check(SessionWords.shared().summary().all == ["tap"], "after a reset SessionWords lists the next player's word (%s)" % [SessionWords.shared().summary()])

# ARCH-03 -------------------------------------------------------------------------------------
func corrupt_index() -> void:
	ProfileManager._shared = null
	var manager = ProfileManager.shared()
	var ids := [manager.create("Ana", "Ana", "bonbon"), manager.create("Ben", "Ben", "bonbon"), manager.create("Cy", "Cy", "bonbon")]
	check(ids == ["p1", "p2", "p3"], "three profiles made (%s)" % [ids])
	write_raw("user://profiles/p2/marker.json", "{\"player\": \"Ben\"}")
	var files := profile_files()
	write_raw(ProfileManager.INDEX_PATH, "{\"schema\": 1, \"next\": ")
	ProfileManager._shared = null
	manager = ProfileManager.shared()
	var listed: Array = manager.profiles().map(func(p): return str(p.id))
	check(listed == ["p1", "p2", "p3"], "a corrupt index lists p1-p3 again (%s)" % [listed])
	check(int(manager.index.next) == 4, "next goes above every folder (%d)" % int(manager.index.next))
	check(profile_files() == files, "the profiles' files are unchanged")
	check(files_like("user://profiles", "index.json.corrupt-").size() == 1, "the corrupt index is backed up")
	check(SaveStore.read_json(ProfileManager.INDEX_PATH) is Dictionary, "the rebuilt index is saved")
	# A lost index with a gap in the folders: next still goes above the highest.
	SaveStore.remove_tree("user://profiles/p2")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ProfileManager.INDEX_PATH))
	ProfileManager._shared = null
	manager = ProfileManager.shared()
	listed = manager.profiles().map(func(p): return str(p.id))
	check(listed == ["p1", "p3"] and int(manager.index.next) == 4, "a lost index rebuilds p1, p3 with next 4 (%s, %d)" % [listed, int(manager.index.next)])
	# A readable index that lists nothing while a folder exists: flat saves are not copied into it.
	SaveStore.remove_tree("user://profiles/p3")
	SaveStore.write_json(ProfileManager.INDEX_PATH, {"schema": 1, "next": 1, "last": "", "profiles": []})
	ProfileManager._shared = null
	manager = ProfileManager.shared()
	var p1_before := profile_files()
	check(manager.has_legacy_saves(), "flat saves are there to adopt")
	var made: String = manager.create("Dee", "Dee", "bonbon")
	check(made == "p2", "a new profile does not reuse p1 (%s)" % made)
	var p1_after := profile_files()
	var p1_same := true
	for path in p1_before:
		p1_same = p1_same and p1_after.get(path) == p1_before[path]
	check(p1_same, "the existing p1 folder is not overwritten by flat saves")
	check(FileAccess.file_exists("user://profiles/p2/settings.json"), "the new folder adopts the flat saves")
