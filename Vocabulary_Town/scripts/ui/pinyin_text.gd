extends RefCounted
## The pronunciation line under foreign text (pinyin when Chinese is the foreign language,
## Stage 4c): one place for its font and how it is filled, so every panel shows it the same.
##
## Godot's built-in font (Open Sans SemiBold) has no ǎ ǐ ǒ ǔ ǖ ǘ ǚ ǜ Ǎ Ǒ: they fell back to a
## system font and its caron drew like a breve. The line uses Noto Sans SemiBold
## (fonts/NotoSans-SemiBold.ttf, SIL Open Font License), which has every pinyin letter
## (user decision, 4 Nov 2026: this line only; the rest of the interface keeps the built-in
## font). docs/evidence/chinese-pinyin-20261104/verify.gd checks the coverage.
##
## Use: style(label) once when the label is built, then show(label, line) whenever its
## {"foreign", "native"} line is drawn.
const GameSettings := preload("res://scripts/core/game_settings.gd")
const FONT := preload("res://fonts/NotoSans-SemiBold.ttf")

static func style(label: Label) -> Label:
	label.add_theme_font_override("font", FONT)
	label.visible = false
	return label

## Fills the label with the reading of `line`'s foreign text; hidden when there is none
## (Native only, or a foreign language without reading data).
static func show(label: Label, line: Variant) -> void:
	label.text = GameSettings.shared().reading(line)
	label.visible = label.text != ""
