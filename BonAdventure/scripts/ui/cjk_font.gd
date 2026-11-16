extends RefCounted
## Chinese fallback for the game's fonts (13 Nov 2026).
##
## Godot's built-in font (Open Sans SemiBold, the interface font: user decision 4 Nov 2026) and
## fonts/NotoSans-SemiBold.ttf (the pinyin line) have no Chinese. Desktop Godot quietly used a
## system font, but a browser gives the web build none, so Chinese showed as empty boxes.
## fonts/NotoSansTC-SemiBold-subset.ttf (Noto Sans TC, SIL OFL 1.1, only the characters the
## game's data and scripts contain) is the fallback: install() adds it to the built-in font,
## which every Control, Label3D and ThemeDB.fallback_font user shares, and
## NotoSans-SemiBold.ttf.import lists it as that font's fallback.
##
## Regenerate the subset with tools/build_cjk_font.py whenever Chinese text is added.
const FONT := preload("res://fonts/NotoSansTC-SemiBold-subset.ttf")

## Called first thing by app.gd and main.gd (_init), before any text is shaped. Idempotent.
static func install() -> void:
	var font := ThemeDB.fallback_font
	if font == null or font.fallbacks.has(FONT):
		return
	var list := font.fallbacks
	list.append(FONT)
	font.fallbacks = list
