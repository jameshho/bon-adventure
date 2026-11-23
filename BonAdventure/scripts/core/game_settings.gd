extends RefCounted
## The player's settings: the Display Mode, the two taught languages, BonBon's outfit and the
## follow camera. Saved to
## the active profile's settings.json (save_store.gd; user://settings.json without a profile; learner data: tests run with an isolated HOME, see the README);
## defaults come from data/languages.json and DEFAULT_DISPLAY. Main loads them first thing
## and apply() hands the languages to the shared Lexicon before anything builds text.
##
## Display Mode — the same numbers as the HUD's `mode`:
##   NATIVE  (0) only the native text; no translate button. The Settings checkbox
##           "Show everything in my language" (no practice is recorded while it is on).
##   FOREIGN (1) the foreign text; the translate button reveals the native line. Default.
## World signs and posters show the foreign language except in NATIVE.
## User decision 7 Nov 2026: the old BOTH mode (2), the L key and the HUD mode button were
## removed (the translate bubble is the quick peek); a saved 2 loads as FOREIGN.
## User decision 9 Nov 2026: L is back as hold-to-peek (`peeking`, not a mode): while L or
## the HUD peek button is held, world signs and labels show the native language.
## Graphics quality: none since 23 Nov 2026 (user: one consistent setting that works on a phone,
## render_culling.gd). The Low / High choice of 14 Nov 2026 was removed; a saved "graphics" key is
## ignored and dropped at the next save.
## Follow camera (user decision, 14 Nov 2026): on by default; the Settings checkbox "Camera
## follows me" turns it off (player_controller.gd follow_view(); Main hands it to the player).
const Lexicon := preload("res://scripts/language/lexicon.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")

signal changed
## The hold-to-peek (hold L or the HUD peek button) started or ended.
signal peek_changed

enum {NATIVE, FOREIGN}
const DEFAULT_DISPLAY := FOREIGN
const FILE := "settings.json"
## The file without an active profile (what checks read and write); the game uses SaveStore.path(FILE).
const PATH := "user://" + FILE

var display := DEFAULT_DISPLAY
var native := ""
var foreign := ""
## The outfit BonBon wears (data/plush_costumes.json id; "" = her own look), kept in a fitting
## room (outfit picker, 9 Nov 2026) and put back on at startup by Main.make_player().
var outfit := ""
## True while the player holds L or the HUD peek button (user decision, 9 Nov 2026): world
## signs and labels show the native language until it is released. Never saved; the
## Display Mode, the dialogue and practice recording are unchanged.
var peeking := false
## Whether walking sideways turns the view (saved with the other settings).
var follow_camera := true

static var _shared

static func shared():
	if _shared == null:
		_shared = new()
		_shared.load_saved()
	return _shared

func load_saved() -> void:
	var lexicon = Lexicon.shared()
	native = lexicon.native
	foreign = lexicon.foreign
	display = DEFAULT_DISPLAY
	outfit = ""
	follow_camera = true
	var parsed: Variant = SaveStore.read_json(SaveStore.path(FILE))
	if not parsed is Dictionary:
		return
	# Anything but NATIVE (including the removed BOTH, 2) loads as the default FOREIGN.
	if int(parsed.get("display", -1)) == NATIVE:
		display = NATIVE
	# A language that is no longer in languages.json, or only a draft, falls back to the default.
	if lexicon.playable_codes().has(str(parsed.get("native", ""))):
		native = str(parsed.native)
	if lexicon.playable_codes().has(str(parsed.get("foreign", ""))):
		foreign = str(parsed.foreign)
	# An outfit that is no longer in the data loads as BonBon's own look.
	var worn := str(parsed.get("outfit", ""))
	if preload("res://scripts/characters/plush_costume.gd").outfit_ids().has(worn):
		outfit = worn
	follow_camera = bool(parsed.get("follow_camera", true))

func save() -> void:
	SaveStore.write_json(SaveStore.path(FILE), {"display": display, "native": native, "foreign": foreign, "outfit": outfit, "follow_camera": follow_camera}, "  ")

## Hands the chosen languages to the shared Lexicon (every phrase and word reads them).
func apply() -> void:
	var lexicon = Lexicon.shared()
	lexicon.native = native
	lexicon.foreign = foreign

func set_display(value: int) -> void:
	if value == display or not value in [NATIVE, FOREIGN]:
		return
	display = value
	save()
	changed.emit()

## A fitting room kept this outfit ("" = BonBon's own look).
func set_outfit(id: String) -> void:
	if id == outfit:
		return
	outfit = id
	save()

## The Settings checkbox "Camera follows me".
func set_follow_camera(on: bool) -> void:
	if on == follow_camera:
		return
	follow_camera = on
	save()
	changed.emit()

## The Settings checkbox "Show everything in my language".
func set_native(on: bool) -> void:
	set_display(NATIVE if on else FOREIGN)

func is_native() -> bool:
	return display == NATIVE

## Same language for both is allowed (the user tests with it).
func set_languages(native_code: String, foreign_code: String) -> void:
	if native_code == native and foreign_code == foreign:
		return
	native = native_code
	foreign = foreign_code
	apply()
	save()
	changed.emit()

## Hold-to-peek on (key or button down) or off (released, window lost focus).
func set_peek(on: bool) -> void:
	if on == peeking:
		return
	peeking = on
	peek_changed.emit()

## The language world signs and posters show in the current mode (native while peeking).
func world_language() -> String:
	return native if display == NATIVE or peeking else foreign

## The short label on the translate button (languages.json "badge"): EN, ES, 中.
func native_badge() -> String:
	return str(Lexicon.shared().languages.get(native, {}).get("badge", native.to_upper()))

## How a {"foreign", "native"} line is shown: [main text, second line or ""]. The second
## line appears in FOREIGN while the translate button is on.
func view(line: Variant, revealed: bool) -> Array:
	if not line is Dictionary:
		return ["", ""]
	var main := str(line.get("foreign", ""))
	var other := str(line.get("native", ""))
	if display == NATIVE:
		return [other, ""]
	return [main, other if revealed else ""]

## The pronunciation shown under the main text of view() (pinyin when Chinese is the foreign
## language, Stage 4c): "" in NATIVE or when the foreign language has no reading data.
func reading(line: Variant) -> String:
	if display == NATIVE or not line is Dictionary:
		return ""
	var lexicon = Lexicon.shared()
	return lexicon.reading(str(line.get("foreign", "")), lexicon.foreign)

## A line on one row: "Clear all" / "Borrar todo / Clear all".
func inline(line: Variant, revealed: bool, separator: String = " / ") -> String:
	var parts := view(line, revealed)
	return parts[0] + (separator + parts[1] if parts[1] != "" and parts[1] != parts[0] else "")

## A line on two rows (buttons): "Borrar todo\nClear all".
func stacked(line: Variant, revealed: bool) -> String:
	return inline(line, revealed, "\n")

func shows_translate_button() -> bool:
	return display == FOREIGN
