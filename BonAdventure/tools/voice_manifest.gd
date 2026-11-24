extends SceneTree
## Spoken-word manifest (developer tool, 24 Nov 2026; guide docs/guides/VOICE.md). Lists what
## tools/voice_generate.py asks Amazon Polly to say: one entry per word of data/words.json and
## language of data/sounds.json "voice.languages", with the clip's file name
## (sound.gd voice_file()) and the SSML to speak. Loads only the language data, not the town,
## and writes no saves.
##
##   HOME=<scratch>/home godot --headless --path . --script res://tools/voice_manifest.gd
##       checks only: prints FAIL: lines and "VOICE MANIFEST: ..." with the counts; writes nothing.
##   ... --script res://tools/voice_manifest.gd -- --out <file.json>
##       also writes the manifest there (voice_generate.py does this into a temporary file).
##
## Spanish: the text with its article; "el médico / la médica" is said as both forms with a short
## pause (every "/" in any language is that pause: 姑媽/姑姐). English: the text. A note in
## brackets ("el banco (dinero)") is left out. Chinese: every character inside an SSML <phoneme> with its pinyin
## from the game's own readings (Lexicon.reading_tokens(), data/pinyin_zh.json) as tone numbers
## (x-amazon-pinyin: píngguǒ -> ping2 guo3, ü -> v, neutral tone 5), so Polly says what the
## game shows under the word and the Traditional characters cannot be misread.
## FAIL: two keys with the same file name, a word with no text, a character without a reading,
## or a reading that does not split into one syllable per character.

const Lexicon := preload("res://scripts/language/lexicon.gd")
const Sound := preload("res://scripts/core/sound.gd")
const SOUNDS_PATH := "res://data/sounds.json"
const PAUSE := "<break time=\"400ms\"/>"
const TONES := {
	"ā": ["a", 1], "á": ["a", 2], "ǎ": ["a", 3], "à": ["a", 4],
	"ē": ["e", 1], "é": ["e", 2], "ě": ["e", 3], "è": ["e", 4],
	"ī": ["i", 1], "í": ["i", 2], "ǐ": ["i", 3], "ì": ["i", 4],
	"ō": ["o", 1], "ó": ["o", 2], "ǒ": ["o", 3], "ò": ["o", 4],
	"ū": ["u", 1], "ú": ["u", 2], "ǔ": ["u", 3], "ù": ["u", 4],
	"ǖ": ["v", 1], "ǘ": ["v", 2], "ǚ": ["v", 3], "ǜ": ["v", 4], "ü": ["v", 0],
}

var problems: PackedStringArray = []
## Toneless syllables the game's pinyin uses (from data/pinyin_zh.json "chars"), for splitting.
var syllables: Dictionary = {}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path := ""
	var at := args.find("--out")
	if at >= 0 and at + 1 < args.size():
		out_path = args[at + 1]
	var sounds: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOUNDS_PATH))
	var voice: Dictionary = sounds.get("voice", {}) if sounds is Dictionary else {}
	var languages: Dictionary = voice.get("languages", {})
	var lexicon = Lexicon.shared()
	for problem in lexicon.load_problems:
		problems.append(problem)
	for c in lexicon.reading_data.get("zh", {}).get("chars", {}):
		var plain := _toneless(str(lexicon.reading_data["zh"]["chars"][c]))
		if plain != "":
			syllables[plain] = true
	var files := {}
	var manifest := {"languages": {}}
	var count := 0
	for lang in languages:
		if not lexicon.languages.has(lang):
			problems.append("sounds.json voice language '%s' is not in languages.json" % lang)
			continue
		var entries := {}
		for key in lexicon.words():
			var file := Sound.voice_file(str(key))
			if files.has(file) and files[file] != key:
				problems.append("'%s' and '%s' share the clip name %s" % [files[file], key, file])
			files[file] = key
			var text := str(lexicon.words()[key].get("text", {}).get(lang, ""))
			if text == "":
				problems.append("%s: no %s text" % [key, lang])
				continue
			entries[key] = {"file": file, "text": text, "ssml": _ssml(str(key), text, lang, lexicon)}
			count += 1
		manifest["languages"][lang] = {"settings": languages[lang], "words": entries}
	for problem in problems:
		print("FAIL: " + problem)
	print("VOICE MANIFEST: %d clips in %d languages; %d problems" % [count, manifest["languages"].size(), problems.size()])
	if out_path != "" and problems.is_empty():
		var file := FileAccess.open(out_path, FileAccess.WRITE)
		if file == null:
			print("FAIL: cannot write " + out_path)
			quit(1)
			return
		file.store_string(JSON.stringify(manifest, "  ", true))
		file.close()
		print("VOICE MANIFEST WRITTEN: " + out_path)
	quit(0 if problems.is_empty() else 1)

func _ssml(key: String, text: String, lang: String, lexicon) -> String:
	# A note in brackets tells two senses apart on screen ("el banco (dinero)", 啡色（頭髮）);
	# it is not said.
	var notes := RegEx.create_from_string("\\s*[(（][^)）]*[)）]")
	text = notes.sub(text, "", true).strip_edges()
	if lang == "zh":
		return "<speak>%s</speak>" % _pinyin_ssml(key, text, lexicon)
	var parts := PackedStringArray()
	for part in text.split("/"):
		parts.append(_escape(part.strip_edges()))
	return "<speak>%s</speak>" % PAUSE.join(parts)

## Each character in a <phoneme> with its numbered pinyin; other text as it is.
func _pinyin_ssml(key: String, text: String, lexicon) -> String:
	var out := ""
	for token in lexicon.reading_tokens(text, "zh"):
		var source := str(token["source"])
		match str(token["kind"]):
			"word":
				var split := _split(str(token["reading"]), source.length())
				if split.is_empty():
					problems.append("%s: reading '%s' of %s does not split into %d syllables" % [key, token["reading"], source, source.length()])
					out += _escape(source)
					continue
				for i in source.length():
					out += "<phoneme alphabet=\"x-amazon-pinyin\" ph=\"%s\">%s</phoneme>" % [split[i], _escape(source[i])]
			"gap":
				problems.append("%s: no pinyin for %s" % [key, source])
				out += _escape(source)
			_:
				out += _escape(source).replace("/", PAUSE)
	return out

## Splits a reading ("píngguǒ", "sūn'ér") into exactly `count` numbered syllables
## (["ping2", "guo3"]); [] when it cannot.
func _split(reading: String, count: int) -> PackedStringArray:
	var letters := reading.to_lower().replace("'", "").replace(" ", "").replace("-", "")
	var plain := _toneless(letters)
	if plain.length() != letters.length():
		return []
	var memo := {}
	var lengths: Array = _split_from(plain, 0, count, memo)
	if lengths.is_empty():
		return []
	var out := PackedStringArray()
	var at := 0
	for size in lengths:
		out.append(_numbered(letters.substr(at, size)))
		at += size
	return out

## Syllable lengths covering plain[at:] with `left` syllables, longest syllable first; [] if none.
func _split_from(plain: String, at: int, left: int, memo: Dictionary) -> Array:
	if at == plain.length():
		return [] if left > 0 else [0]
	if left == 0:
		return []
	var id := "%d:%d" % [at, left]
	if memo.has(id):
		return memo[id]
	var found: Array = []
	for size in range(mini(6, plain.length() - at), 0, -1):
		if not syllables.has(plain.substr(at, size)):
			continue
		var rest := _split_from(plain, at + size, left - 1, memo)
		if not rest.is_empty():
			found = [size] + (rest if rest != [0] else [])
			break
	memo[id] = found
	return found

## "guǒ" -> "guo3", "lǜ" -> "lv4", "de" -> "de5".
func _numbered(syllable: String) -> String:
	var tone := 5
	var out := ""
	for c in syllable:
		if TONES.has(c):
			out += TONES[c][0]
			if int(TONES[c][1]) > 0:
				tone = int(TONES[c][1])
		else:
			out += c
	return out + str(tone)

func _toneless(text: String) -> String:
	var out := ""
	for c in text.to_lower():
		out += str(TONES[c][0]) if TONES.has(c) else c
	return out

func _escape(text: String) -> String:
	return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")
