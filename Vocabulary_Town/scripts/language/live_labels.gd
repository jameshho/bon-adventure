extends RefCounted
## World labels whose text follows the Display Mode (the Settings Native mode checkbox). A
## bound label keeps a text reference (Lexicon.text(): a word, a word form or a phrase) instead
## of fixed text, so set_language() can re-render it in either taught language from data. Main
## calls set_language() whenever the Display Mode changes: Native mode shows the native
## language, Foreign the foreign one, the same rule as world signs
## (scripts/world/sign_language.gd).
##
## `fit_width` (world-label units, 0 = never shrink) keeps longer translations inside
## their card: the label shrinks below its built pixel size until its longest line fits.
const Lexicon := preload("res://scripts/language/lexicon.gd")
const GROUP := "lexicon_labels"
## Average glyph width as a fraction of the font size (the default font, mixed case).
const GLYPH_WIDTH := .58

static func bind(label: Label3D, ref: Dictionary, fit_width: float = 0.0) -> void:
	label.set_meta("lexicon_text", ref)
	label.set_meta("lexicon_fit", fit_width)
	label.set_meta("lexicon_pixel", label.pixel_size)
	label.add_to_group(GROUP, true)
	# A bound label is never also a table sign (scripts/world/sign_language.gd).
	label.remove_from_group("translated_signs")
	apply(label, Lexicon.shared().foreign)

## The language world labels show in Display Mode `mode` (0 native, 1 foreign).
static func language_for_mode(mode: int) -> String:
	var lexicon = Lexicon.shared()
	return lexicon.native if mode == 0 else lexicon.foreign

static func set_language(tree: SceneTree, lang: String) -> void:
	for label in tree.get_nodes_in_group(GROUP):
		apply(label, lang)

static func apply(label: Label3D, lang: String) -> void:
	label.text = Lexicon.shared().text(label.get_meta("lexicon_text"), lang)
	var base := float(label.get_meta("lexicon_pixel"))
	var fit := float(label.get_meta("lexicon_fit"))
	if fit <= 0.0:
		label.pixel_size = base
		return
	var longest := 1
	for line in label.text.split("\n"):
		longest = maxi(longest, line.length())
	label.pixel_size = minf(base, fit / (longest * label.font_size * GLYPH_WIDTH))
