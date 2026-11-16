extends SceneTree
## BonBon rename (16 Nov 2026): saves made before the rename still load.
## 1. Desktop: config/name "Vocabulary Town" -> "Bon Adventure" moves user://. An old-format
##    folder ("Vocabulary Town", beside the new one) with a profile whose avatar is an old id, its
##    settings, device.json and a log is copied over by save_migration.gd (profiles included,
##    logs left behind, nothing overwritten, a second run copies nothing).
## 2. Profiles: a saved avatar that is no longer a house character (the pig's id before the
##    rename; "old_pig" here) is rewritten to "bonbon" on load; create()/update() refuse it.
## 3. Web: web_resume.gd's page code moves the old localStorage note "vt-resume" to
##    "bon-resume" once and removes the old key (run in macOS JavaScript with a localStorage
##    stand-in, as no browser runs here).
## Writes into the user data folder and its parent, so it needs an isolated HOME and refuses to
## run outside one:
## HOME=<scratch>/home godot --headless --path . --script res://docs/evidence/bonbon-rename-20261116/verify_saves.gd
## Prints "BONBON SAVES: N checks, M failures".
const SaveStore := preload("res://scripts/core/save_store.gd")
const ProfileManager := preload("res://scripts/core/profile_manager.gd")
const SaveMigration := preload("res://scripts/core/save_migration.gd")
const WebResume := preload("res://scripts/core/web_resume.gd")
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("ok:   " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func run():
	var here := OS.get_user_data_dir()
	var home := OS.get_environment("HOME")
	# A scratch HOME (the check runner's and the README's) lives under a temporary folder.
	if not here.begins_with(home) or not ("tmp" in home or "scratch" in home or "/var/folders/" in home):
		print("BONBON SAVES: refusing to run without an isolated HOME (%s)" % here)
		quit(1)
		return
	check(here.get_file() == "Bon Adventure", "the user folder is named after config/name 'Bon Adventure' (%s)" % here.get_file())
	if FileAccess.file_exists("user://profiles/index.json") or FileAccess.file_exists(SaveStore.DEVICE_FILE):
		print("BONBON SAVES: refusing to run, the new folder already has saves")
		quit(1)
		return
	# 1. An old folder in the format before the rename.
	var old := here.get_base_dir().path_join("Vocabulary Town")
	var index := {"schema": 1, "next": 3, "last": "p1", "profiles": [
		{"id": "p1", "name": "Ana", "profile_name": "Ana", "avatar": "old_pig"},
		{"id": "p2", "name": "Leo", "profile_name": "Leo", "avatar": "leo"}]}
	write(old.path_join("profiles/index.json"), JSON.stringify(index, "  "))
	write(old.path_join("profiles/p1/settings.json"), JSON.stringify({"native": "en", "foreign": "es", "outfit": ""}))
	write(old.path_join("profiles/p1/practice_log.json"), JSON.stringify({"es": {"sofa": {}}}))
	write(old.path_join("device.json"), JSON.stringify({"quality": "low"}))
	write(old.path_join("logs/godot.log"), "old log")
	var copied := SaveMigration.run()
	check(copied == 4, "the migration copies the 4 save files of the old folder (%d)" % copied)
	check(FileAccess.file_exists("user://profiles/p1/settings.json") and FileAccess.file_exists("user://profiles/p1/practice_log.json"), "profile p1's saves are in the new folder")
	check(FileAccess.file_exists(SaveStore.DEVICE_FILE), "device.json is in the new folder")
	check(FileAccess.get_file_as_string("user://logs/godot.log") != "old log", "Godot's logs stay behind")
	check(FileAccess.file_exists(old.path_join("profiles/index.json")), "the old folder stays as a backup")
	check(SaveMigration.run() == 0, "a second start copies nothing")
	# 2. The avatar alias.
	var manager = ProfileManager.shared()
	check(manager.get_profile("p1").get("avatar") == "bonbon", "an unknown saved avatar ('old_pig') loads as 'bonbon'")
	check(manager.get_profile("p2").get("avatar") == "leo", "other avatars are unchanged")
	var saved: Variant = SaveStore.read_json("user://profiles/index.json")
	check(saved is Dictionary and saved.profiles[0].avatar == "bonbon", "the profile list is saved with 'bonbon'")
	check(not "old_pig" in FileAccess.get_file_as_string("user://profiles/index.json"), "the unknown id is not left in the saved profile list")
	check(ProfileManager.avatar_ids().has("bonbon"), "the avatar list has 'bonbon'")
	check(not manager.update("p2", {"avatar": "old_pig"}) and manager.get_profile("p2").avatar == "leo", "update() refuses an unknown avatar")
	check(manager.create("Mia", "Mia", "old_pig") == "", "create() refuses an unknown avatar")
	var id: String = manager.create("Mia", "Mia")
	check(id != "" and manager.get_profile(id).avatar == "bonbon", "a new profile is BonBon by default")
	check(ProfileManager.DEFAULT_AVATAR == "bonbon", "the default avatar is BonBon")
	# 3. The web resume note.
	var note := "{\"profile\":\"p1\",\"x\":1}"
	var cases := [
		[{"vt-resume": note}, {"bon-resume": note}, "an old note moves to bon-resume and vt-resume is removed"],
		[{"vt-resume": "{}", "bon-resume": note}, {"bon-resume": note}, "a newer bon-resume note is kept and the old key removed"],
		[{"bon-resume": note}, {"bon-resume": note}, "a bon-resume note alone is left as it is"],
		[{}, {}, "no note: nothing is written"],
	]
	for case in cases:
		var result: Variant = _run_js(case[0])
		check(result is Dictionary and result == case[1], "%s (%s)" % [case[2], str(result)])
	print("BONBON SAVES: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## Runs MOVE_OLD_NOTE_JS against a localStorage stand-in holding `store`; returns what is left.
func _run_js(store: Dictionary) -> Variant:
	var code := "var data = %s; var localStorage = {getItem: function (k) { return k in data ? data[k] : null; }, setItem: function (k, v) { data[k] = String(v); }, removeItem: function (k) { delete data[k]; }}; %s; JSON.stringify(data);" % [JSON.stringify(store), WebResume.move_old_note_js()]
	var output := []
	# Through a file: Godot's OS.execute drops the double quotes inside an argument.
	var script := OS.get_user_data_dir().path_join("resume_check.js")
	write(script, code)
	if OS.execute("osascript", ["-l", "JavaScript", script], output, true) != 0:
		return "osascript failed: " + str(output)
	return JSON.parse_string(str(output[0]).strip_edges())
