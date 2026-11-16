extends SceneTree
## Every world sign in every taught language (user decision, 9 Nov 2026). Checks
## data/sign_translations.json has every playable language, that every visible Label3D in the
## town is covered (a table sign, a Lexicon-bound label, an elevator label, text without
## letters or a _same name/code), that signs, posters and the elevator switch for every
## native/foreign pair, and that holding L with Chinese as the native language shows Chinese.
## Isolated HOME (Main saves progress and settings; the script removes user://settings.json):
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/signs-20261109/verify.gd
## Prints "SIGNS: N checks, M failures".
const GameSettings := preload("res://scripts/core/game_settings.gd")
const SignLanguage := preload("res://scripts/world/sign_language.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func run():
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	var table: Dictionary = SignLanguage.table()
	var codes: Array = Lexicon.shared().playable_codes()
	var others: Array = codes.filter(func(c): return c != "en")
	# 1. Data: every entry in every language.
	for section in ["", "_glosses", "_pairs"]:
		var entries: Dictionary = table if section == "" else table[section]
		for key in entries:
			if key.begins_with("_"):
				continue
			for code in others:
				check(entries[key] is Dictionary and str(entries[key].get(code, "")).strip_edges() != "", "%s %s has %s" % [section, key.c_escape(), code])
	for suffix in table._nodes:
		check(table.has(table._nodes[suffix]), "_nodes %s names a sign" % suffix)
	# 2. Every visible label in the town is covered.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 3: await physics_frame
	var letters := RegEx.create_from_string("\\p{L}")
	var same: Array = table._same
	var signs := 0
	var seen := {}
	for label in root.find_children("*", "Label3D", true, false):
		if not label.is_visible_in_tree() or label.text.strip_edges() == "":
			continue
		if label.is_in_group(SignLanguage.GROUP):
			signs += 1
			continue
		if label.is_in_group("lexicon_labels") or label.has_meta("sign_dynamic") or letters.search(label.text) == null or same.has(label.text):
			continue
		if not seen.has(label.text):
			seen[label.text] = true
			check(false, "untranslated sign %s @ %s" % [label.text.c_escape(), root.get_path_to(label)])
	print("signs in the table: %d labels" % signs)
	# 286 on 9 Nov 2026; 276 after the interiors polish the same day (the sports store's 28 Oct
	# department signs were replaced by seven wall signs; Pizza and Burger gained two).
	check(signs >= 270, "table signs found (276 on 9 Nov 2026)")
	# 3. Every native/foreign pair: signs, posters and the elevator switch.
	var lexicon = Lexicon.shared()
	var keep := [lexicon.native, lexicon.foreign]
	var labels: Array = get_nodes_in_group(SignLanguage.GROUP)
	var elevator: Node = root.find_child("Elevator", true, false)
	for native in codes:
		for foreign in codes:
			if native == foreign:
				continue
			lexicon.native = native
			lexicon.foreign = foreign
			for lang in [foreign, native]:
				SignLanguage.set_language(self, lang)
				var wrong := 0
				for label in labels:
					var key: String = label.get_meta("sign_english")
					var expected: String
					match str(label.get_meta("sign_kind")):
						"gloss": expected = SignLanguage._in(table._glosses[key], key, native)
						"pair": expected = SignLanguage._in(table._pairs[key], key, lang) + ("" if lang == native else SignLanguage.PAIR + SignLanguage._in(table._pairs[key], key, native))
						_: expected = SignLanguage.say(key, lang)
					if label.text != expected or label.text == "":
						wrong += 1
						if wrong <= 3:
							print("  %s/%s shows %s: %s, expected %s" % [native, foreign, lang, label.text.c_escape(), expected.c_escape()])
				check(wrong == 0, "native %s, foreign %s: every sign shows %s" % [native, foreign, lang])
				if elevator != null:
					await physics_frame
					check(elevator.status_labels[0].text == elevator.stop_name(elevator.car_stop()) and elevator.title_labels[0].text.begins_with(SignLanguage.say("FLOOR", lang)), "elevator in %s (status shows only the car's stop number)" % lang)
	# 4. Holding L with Chinese as the native language.
	lexicon.native = keep[0]
	lexicon.foreign = keep[1]
	var settings = GameSettings.shared()
	settings.set_languages("zh", "es")
	var reception: Label3D = null
	for label in labels:
		if label.get_meta("sign_source") == "RECEPCIÓN":
			reception = label
	check(reception != null, "the hospital's Spanish RECEPCIÓN sign is a table sign")
	if reception != null:
		check(reception.text == "RECEPCIÓN", "foreign Spanish: RECEPCIÓN")
		settings.set_peek(true)
		check(reception.text == "接待處", "holding L with native Chinese: 接待處 (got %s)" % reception.text)
		settings.set_peek(false)
		check(reception.text == "RECEPCIÓN", "released: RECEPCIÓN")
	settings.set_languages(keep[0], keep[1])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	print("SIGNS: %d checks, %d failures" % [checks, failures])
	quit()
