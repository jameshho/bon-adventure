extends SceneTree
## Spoken-word backbone check (24 Nov 2026, docs/guides/VOICE.md). Headless, loads no town and
## plays no sound: sound.gd voice_file() / voice_path(), and that has_voice() and say_word()
## stay silent while "voice.enabled" is false and when a clip is missing. The manifest itself is
## checked by tools/voice_manifest.gd.
##   HOME=<scratch>/home godot --headless --path . --script res://docs/evidence/voice-backbone-20261124/verify.gd

const Sound := preload("res://scripts/core/sound.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")

var checks := 0
var failures := 0

func _initialize() -> void:
	_check(Sound.voice_file("apple") == "apple", "voice_file apple")
	_check(Sound.voice_file("apple pie") == "apple_pie", "voice_file apple pie")
	_check(Sound.voice_file("brown (hair)") == "brown_hair", "voice_file brown (hair)")
	_check(Sound.voice_file("T-Shirt") == "t_shirt", "voice_file T-Shirt")
	var sound = Sound.new()
	_check(not sound.voice.is_empty(), "sounds.json has a voice section")
	_check(sound.voice_enabled() == false, "spoken words are off (user, 24 Nov 2026)")
	_check(sound.voice_path("apple pie", "es") == "res://audio/voice/es/apple_pie.ogg", "voice_path")
	var langs: Dictionary = sound.voice.get("languages", {})
	_check(str(langs.get("es", {}).get("language_code", "")) == "es-MX", "Spanish is Latin American (es-MX)")
	_check(str(langs.get("es", {}).get("voice", "")) == "Mia", "Spanish voice Mia")
	for lang in langs:
		_check(Lexicon.shared().languages.has(lang), "voice language %s is a game language" % lang)
	_check(sound.has_voice("apple", "es") == false, "has_voice false while off")
	_check(sound.say_word("apple", "es") == false, "say_word silent while off")
	sound.voice["enabled"] = true
	_check(sound.has_voice("no such word", "es") == false, "has_voice false for a missing clip")
	_check(sound.say_word("no such word", "es") == false, "say_word silent for a missing clip")
	_check(sound.get_child_count() == 0, "no audio player was created")
	# The game's clips (made 24 Nov 2026): every word in every voice language loads as Ogg
	# Vorbis, not looping, and is found once switched on. say_word() is never called on a real
	# clip here, so nothing plays.
	var missing := 0
	var bad := 0
	for lang in langs:
		for key in Lexicon.shared().words():
			var path: String = sound.voice_path(str(key), lang)
			if not sound.has_voice(str(key), lang):
				missing += 1
				continue
			var clip = load(path)
			if not clip is AudioStreamOggVorbis or clip.loop:
				bad += 1
	_check(missing == 0, "every word has a clip in every voice language (%d missing)" % missing)
	_check(bad == 0, "every clip is non-looping Ogg Vorbis (%d bad)" % bad)
	sound.voice["enabled"] = false
	_check(sound.has_voice("apple", "es") == false, "has_voice false again once switched off")
	_check(sound.get_child_count() == 0, "still no audio player")
	var tokens: Array = Lexicon.shared().reading_tokens("蘋果", "zh")
	_check(tokens.size() == 1 and tokens[0]["reading"] == "píngguǒ", "reading_tokens 蘋果")
	sound.free()
	print("VOICE BACKBONE CHECK: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)
