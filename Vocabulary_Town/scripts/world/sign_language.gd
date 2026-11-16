extends RefCounted
## World signs in every taught language (user decision, 9 Nov 2026; Spanish-only until then).
## data/sign_translations.json keys each sign by its English text with {code: text} for the
## other languages. A Label3D whose authored text is a key or any of its translations (the
## hospital's signs were authored in Spanish) joins GROUP and shows the language Main passes
## to set_language(): GameSettings.world_language(), the foreign language, or the native one
## in Native mode and while L is held. Poster meaning lines (_glosses) always show the native
## language; poster titles (_pairs) show "foreign  ·  native". Labels a script rewrites at
## runtime (the elevator) carry meta sign_dynamic and ask say() instead.
## docs/evidence/signs-20261109/verify.gd checks that every visible Label3D is covered.
const Lexicon := preload("res://scripts/language/lexicon.gd")
const GROUP := "translated_signs"
const PATH := "res://data/sign_translations.json"
## Longer text shrinks toward the authored footprint, but never below MIN_SHRINK.
## SLACK extra characters fit without shrinking (sign panels have side margins).
const MIN_SHRINK := 0.5
const SLACK := 2
## A CJK character is about this many Latin capitals wide.
const WIDE := 1.7
const PAIR := "  ·  "

static var _table: Dictionary
## Authored text -> [kind, key], built once from the table.
static var _index: Dictionary
## The language signs show now ("" until Main's first set_language: the foreign language).
static var language := ""

static func table() -> Dictionary:
    if _table.is_empty():
        _table = JSON.parse_string(FileAccess.get_file_as_string(PATH))
    return _table

static func shown_language() -> String:
    return language if language != "" else Lexicon.shared().foreign

## A sign in `lang` ("en" is the key itself; a missing translation falls back to English).
static func say(key: String, lang: String = "") -> String:
    if lang == "":
        lang = shown_language()
    return _in(table().get(key, {}), key, lang)

static func _in(entry: Variant, key: String, lang: String) -> String:
    if lang == "en" or not entry is Dictionary:
        return key
    return str(entry.get(lang, key))

static func index() -> Dictionary:
    if not _index.is_empty():
        return _index
    var t := table()
    var codes: Array = ["en"] + Lexicon.shared().playable_codes()
    for key in t:
        if not key.begins_with("_"):
            for lang in codes:
                var text := _in(t[key], key, lang)
                if not _index.has(text):
                    _index[text] = ["sign", key]
    for key in t.get("_glosses", {}):
        for lang in codes:
            var text := _in(t._glosses[key], key, lang)
            if not _index.has(text):
                _index[text] = ["gloss", key]
    for key in t.get("_pairs", {}):
        for a in codes:
            for b in codes:
                if a != b:
                    _index[_in(t._pairs[key], key, a) + PAIR + _in(t._pairs[key], key, b)] = ["pair", key]
    return _index

## [kind, key] for a label's authored text, or [] when it is not a sign.
static func find(label: Label3D) -> Array:
    var path := str(label.get_path())
    var nodes: Dictionary = table().get("_nodes", {})
    for suffix in nodes:
        if path.ends_with("/" + suffix):
            return ["sign", nodes[suffix]]
    if label.text.begins_with("_"):
        return []
    return index().get(label.text, [])

static func translate_all(town: Node3D) -> int:
    var count := 0
    for label in town.find_children("*", "Label3D", true, false):
        if label.is_in_group(GROUP) or label.has_meta("sign_dynamic") or label.is_in_group("lexicon_labels"):
            continue
        var found := find(label)
        if found.is_empty():
            continue
        label.set_meta("sign_source", label.text)
        label.set_meta("sign_kind", found[0])
        label.set_meta("sign_english", found[1])
        # Older checks read the Spanish text.
        label.set_meta("sign_spanish", _text(found[0], found[1], "es", "en"))
        label.set_meta("sign_font_size", label.font_size)
        label.add_to_group(GROUP)
        apply(label, shown_language())
        count += 1
    return count

static func set_language(tree: SceneTree, lang: String) -> void:
    language = lang
    for label in tree.get_nodes_in_group(GROUP):
        apply(label, lang)

## A sign's text when the world shows `lang` and the player's language is `native`.
static func _text(kind: String, key: String, lang: String, native: String) -> String:
    var t := table()
    match kind:
        "gloss":
            return _in(t._glosses.get(key), key, native)
        "pair":
            var main := _in(t._pairs.get(key), key, lang)
            return main if lang == native else main + PAIR + _in(t._pairs.get(key), key, native)
    return _in(t.get(key), key, lang)

static func apply(label: Label3D, lang: String) -> void:
    label.text = _text(str(label.get_meta("sign_kind", "sign")), str(label.get_meta("sign_english")), lang, Lexicon.shared().native)
    if label.has_meta("world_sign"):
        _fit_world_sign(label)
        return
    var ratio := 1.0
    # Wrapped labels reflow within their width; single-line signs scale instead.
    if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
        ratio = clampf((longest_line(str(label.get_meta("sign_source", label.get_meta("sign_english")))) + SLACK) / longest_line(label.text), MIN_SHRINK, 1.0)
    label.font_size = maxi(1, roundi(int(label.get_meta("sign_font_size")) * ratio))

## World signs (scripts/world/world_sign.gd, 16 Nov 2026) keep their font size (one glyph atlas)
## and shrink their pixel size only when the text is wider than the board's free width
## (sign_fit_width), never below their minimum letter height (sign_min_em). Wrapped signs reflow.
static func _fit_world_sign(label: Label3D) -> void:
    var base: float = label.get_meta("sign_pixel_size", label.pixel_size)
    label.font_size = int(label.get_meta("sign_font_size", label.font_size))
    label.pixel_size = base
    if label.autowrap_mode != TextServer.AUTOWRAP_OFF or not label.has_meta("sign_fit_width"):
        return
    var scale := label.global_transform.basis.get_scale().y if label.is_inside_tree() else 1.0
    var font: Font = label.font if label.font != null else ThemeDB.fallback_font
    var widest := 0.0
    for line in label.text.split("\n"):
        widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x)
    var width := widest * base * scale
    var fit: float = label.get_meta("sign_fit_width")
    if width <= fit or width <= 0.0:
        return
    var em := label.font_size * base * scale
    var floor_ratio := minf(1.0, float(label.get_meta("sign_min_em", 0.0)) / em) if em > 0.0 else 1.0
    label.pixel_size = base * maxf(fit / width, floor_ratio)

## The widest line, in Latin capitals (CJK characters count WIDE).
static func longest_line(text: String) -> float:
    var longest := 1.0
    for line in text.split("\n"):
        var width := 0.0
        for i in line.length():
            width += WIDE if line.unicode_at(i) >= 0x2E80 else 1.0
        longest = maxf(longest, width)
    return longest
