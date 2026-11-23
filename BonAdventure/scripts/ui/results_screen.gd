extends Control
## The results screen after a minigame (user design, 21 Nov 2026; docs/guides/MINIGAMES.md#results-screen).
## Not a score screen: no percentages or grades. One card in the UI art style (bon_style.gd) with
##   1. the accomplishment: a title specific to the game ("Books Sorted!") and one line of what
##      the player did;
##   2. vocabulary progress: stat bubbles (words practiced, new words, quests) and the 3-5 most
##      interesting words (new first, then ones the player struggled with; session_words.gd),
##      with "See all" for the rest;
##   3. a small reward (optional): a town mission done ("Quest updated!" and its XP, results_flow.gd),
##      coins, stars. Coins and stars are not designed yet (user: "finalize later").
## With no new words the screen becomes "Great Practice!" with the familiar words practiced.
## Buttons: Continue exploring (green, closes) and Play again (blue, only with `replay`).
##
##   main.results_screen.show_results({
##       "title": UiText.t("results.title_library_rosa"),        # else results.title_done
##       "line": UiText.t("results.line_library_rosa"),
##       "words": SessionWords.shared(),                          # or a summary() dictionary
##       "rewards": [{"kind": "quest", "text": "..."}, {"kind": "xp", "amount": 30}, {"kind": "coins", "amount": 5},
##                   {"kind": "stars", "amount": 2}],
##       "replay": true,
##       "picture": func(key) -> Texture2D: ...,                  # optional; else word_pictures.gd
##   })
## Signals: continued (Continue, Esc) and replay_requested (Play again); either closes the card.
## Interface text in the native language (data/phrases.json group "results"); words through the
## Lexicon (foreign word, native meaning). Scales with min(height / 800, width / 1100) and fits a
## landscape phone (two columns, no scrolling). Main locks the player while it shows
## (minigame_wiring.gd PANELS).
signal continued
signal replay_requested
## Esc (popup stack, minigame_wiring.gd PANELS).
signal close_requested

const BonStyle := preload("res://scripts/ui/bon_style.gd")
const UiText := preload("res://scripts/language/ui_text.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const SessionWords := preload("res://scripts/learning/session_words.gd")
const WordPictures := preload("res://scripts/ui/word_pictures.gd")

## Words shown before "See all" (user: 3-5).
const HIGHLIGHTS := 4
## The card's design size at scale 1 (a 1100 x 800 window).
const CARD := Vector2(1000, 0)

var card: PanelContainer
## What the card shows now (checks read it): the spec plus "practice" (the no-new-words variant),
## "shown_words" and "stats" ({id: number}).
var shown: Dictionary = {}
var _spec: Dictionary = {}
var _all := false

func setup() -> void:
	name = "ResultsScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Catches presses around the card so they do not reach the world (no dark shade: UI_STYLE.md).
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	close_requested.connect(_continue)
	get_viewport().size_changed.connect(func() -> void:
		if visible:
			_build())

func show_results(spec: Dictionary) -> void:
	_spec = spec.duplicate()
	_all = false
	_build()
	get_parent().move_child(self, -1)
	visible = true
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2.ONE * 0.92
	card.modulate.a = 0.0
	var pop := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(card, "scale", Vector2.ONE, 0.35)
	pop.tween_property(card, "modulate:a", 1.0, 0.2)

## Minigame panels re-render on a language or Display Mode change (minigame_wiring.gd).
func refresh_display() -> void:
	if visible:
		_build()

func _words() -> Dictionary:
	var source: Variant = _spec.get("words", null)
	if source is Dictionary:
		return source
	if source != null and source.has_method("summary"):
		var summary: Dictionary = source.summary()
		summary["highlights"] = source.highlights(HIGHLIGHTS)
		return summary
	return {"new": [], "practiced": [], "struggled": [], "all": []}

func _factor() -> float:
	var view: Vector2 = get_viewport().get_visible_rect().size
	return clampf(minf(view.y / 800.0, view.x / 1100.0), 0.5, 3.0)

func _build() -> void:
	if card != null:
		card.queue_free()
	var f := _factor()
	var words := _words()
	var fresh: Array = words.get("new", [])
	var familiar: Array = words.get("practiced", [])
	var every: Array = words.get("all", fresh + familiar)
	var practice := fresh.is_empty() and not familiar.is_empty()
	var quests: Array = _spec.get("rewards", []).filter(func(r): return str(r.get("kind", "")) == "quest")
	shown = _spec.duplicate()
	shown["practice"] = practice
	shown["stats"] = {}

	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", roundi(10 * f))
	var heading: String = UiText.t("results.practice_title") if practice else str(_spec.get("title", UiText.t("results.title_done")))
	var banner := BonStyle.title(heading, f, 42.0)
	# A shorter cloud than a page title's (the card must fit a landscape phone).
	banner.add_theme_constant_override("margin_top", roundi(60 * f))
	banner.add_theme_constant_override("margin_bottom", roundi(12 * f))
	stack.add_child(banner)
	var line: String = UiText.t("results.practice_line", {"count": familiar.size()}) if practice else str(_spec.get("line", ""))
	if line != "":
		var said := BonStyle.label(line, 24, BonStyle.INK_SOFT, f, 600)
		said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(said)

	var body := HBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation", roundi(26 * f))
	stack.add_child(body)
	# Left: the stat bubbles, then the rewards.
	var left := VBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_theme_constant_override("separation", roundi(10 * f))
	left.custom_minimum_size.x = 330 * f
	body.add_child(left)
	if every.is_empty():
		pass   # no tested words (e.g. a game launched from the picker): no word stats at all
	elif practice:
		_stat(left, "practice", familiar.size(), UiText.t("results.stat_practice"), f)
	else:
		# A zero reads as a failure: a first play shows no "0 words practiced" (user, 21 Nov 2026).
		if not familiar.is_empty():
			_stat(left, "practiced", familiar.size(), UiText.t("results.stat_practiced"), f)
		_stat(left, "new", fresh.size(), UiText.t("results.stat_new"), f)
	if not quests.is_empty():
		_stat(left, "quests", quests.size(), UiText.t("results.stat_quests"), f)
	_rewards(left, f)
	# Right: the words.
	if not every.is_empty():
		body.add_child(_word_band(words, practice, f))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", roundi(20 * f))
	if bool(_spec.get("replay", false)):
		var again := BonStyle.button(UiText.t("results.again"), "back", "retry", f, 26.0, Vector2(220, 66))
		again.name = "Play again"
		again.pressed.connect(_replay)
		buttons.add_child(again)
	var go := BonStyle.button(UiText.t("results.continue"), "primary", "arrow_right", f, 26.0, Vector2(300, 66))
	go.name = "Continue"
	go.pressed.connect(_continue)
	buttons.add_child(go)
	stack.add_child(buttons)

	card = BonStyle.card(stack, f, false)
	BonStyle.rescale_card(card, f, 24.0, 24.0)
	card.name = "Results card"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.custom_minimum_size.x = minf(CARD.x * f, get_viewport().get_visible_rect().size.x - 24.0)
	add_child(card)
	card.reset_size()
	_place.call_deferred()

func _place() -> void:
	if card == null or not is_instance_valid(card):
		return
	var view: Vector2 = get_viewport().get_visible_rect().size
	card.size = card.get_combined_minimum_size()
	card.position = ((view - card.size) * 0.5).max(Vector2.ZERO)
	card.pivot_offset = card.size * 0.5

## One stat bubble: a big number beside its label.
func _stat(parent: Control, id: String, value: int, text: String, f: float) -> void:
	shown.stats[id] = value
	var bubble := PanelContainer.new()
	bubble.name = "Stat " + id
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var look: StyleBox = BonStyle.box("soft", f)
	look.content_margin_left = 22.0 * f
	look.content_margin_right = 22.0 * f
	look.content_margin_top = 2.0 * f
	look.content_margin_bottom = 4.0 * f
	bubble.add_theme_stylebox_override("panel", look)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", roundi(16 * f))
	var number := BonStyle.label(str(value), 42, BonStyle.GREEN_TEXT if id == "new" else BonStyle.INK, f, 700)
	number.custom_minimum_size.x = 70 * f
	row.add_child(number)
	var words := BonStyle.label(text, 22, BonStyle.INK, f, 600, HORIZONTAL_ALIGNMENT_LEFT)
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(words)
	bubble.add_child(row)
	parent.add_child(bubble)

## Quests updated, coins and stars (each only when the game passed one).
func _rewards(parent: Control, f: float) -> void:
	var quests: Array = []
	var prizes := HBoxContainer.new()
	prizes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prizes.add_theme_constant_override("separation", roundi(24 * f))
	for reward in _spec.get("rewards", []):
		match str(reward.get("kind", "")):
			"quest":
				quests.append(str(reward.get("text", "")))
			"coins":
				var coins := _reward_line("money", UiText.t("results.coins", {"n": int(reward.get("amount", 0))}), f, false)
				coins.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				prizes.add_child(coins)
			"xp":
				if int(reward.get("amount", 0)) > 0:
					var xp := _reward_line("star", UiText.t("results.xp", {"n": int(reward.get("amount", 0))}), f, false)
					xp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
					prizes.add_child(xp)
			"stars":
				prizes.add_child(BonStyle.stars(clampi(int(reward.get("amount", 0)), 0, 3), 38.0 * f))
	if prizes.get_child_count() > 0:
		parent.add_child(prizes)
	else:
		prizes.free()
	if quests.is_empty():
		return
	parent.add_child(BonStyle.label(UiText.t("results.quest_updated"), 22, BonStyle.INK, f, 700, HORIZONTAL_ALIGNMENT_LEFT))
	for text in quests:
		parent.add_child(_reward_line("check", text, f))

func _reward_line(icon: String, text: String, f: float, wrap := true) -> Control:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", roundi(10 * f))
	var mark := TextureRect.new()
	mark.texture = BonStyle.icon_texture(icon, 64)
	mark.modulate = BonStyle.GREEN_TEXT
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size = Vector2(30, 30) * f
	row.add_child(mark)
	var words := BonStyle.label(text, 20, BonStyle.INK, f, 600, HORIZONTAL_ALIGNMENT_LEFT)
	if wrap:
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(words)
	return row

## "Words you discovered" (or "Words you practiced"): the highlights as rows, or every word as
## small chips after "See all".
func _word_band(words: Dictionary, practice: bool, f: float) -> Control:
	var every: Array = words.get("all", [])
	var fresh: Array = words.get("new", [])
	var picks: Array = words.get("highlights", every.slice(0, HIGHLIGHTS))
	var lexicon = Lexicon.shared()
	var list := VBoxContainer.new()
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_theme_constant_override("separation", roundi(4 * f))
	if _all:
		var grid := GridContainer.new()
		grid.columns = 3
		grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_theme_constant_override("h_separation", roundi(18 * f))
		grid.add_theme_constant_override("v_separation", roundi(4 * f))
		for key in every:
			var chip := BonStyle.label(lexicon.word(key, lexicon.foreign), 20, BonStyle.GREEN_TEXT if fresh.has(key) else BonStyle.INK, f, 700, HORIZONTAL_ALIGNMENT_LEFT)
			chip.tooltip_text = lexicon.word(key, lexicon.native)
			grid.add_child(chip)
		list.add_child(grid)
		shown["shown_words"] = every.duplicate()
	else:
		for key in picks:
			list.add_child(_word_row(key, fresh.has(key), f))
		shown["shown_words"] = picks.duplicate()
	if every.size() > picks.size():
		var more := BonStyle.button(UiText.t("results.see_less") if _all else UiText.t("results.see_all", {"count": every.size()}), "quiet", "", f, 20.0, Vector2(150, 44))
		more.name = "See all"
		more.size_flags_horizontal = Control.SIZE_SHRINK_END
		more.pressed.connect(func() -> void:
			_all = not _all
			_build()
			card.modulate.a = 1.0)
		list.add_child(more)
	var title: String = UiText.t("results.words_practiced") if practice else UiText.t("results.words_new")
	var hint: String = "" if practice else UiText.t("results.new_count", {"count": fresh.size()})
	var band := BonStyle.band(title, hint, list, f)
	band.name = "Words"
	band.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return band

## One highlighted word: an optional picture, the foreign word, its native meaning and a "New" tag.
func _word_row(key: String, fresh: bool, f: float) -> Control:
	var lexicon = Lexicon.shared()
	var row := HBoxContainer.new()
	row.name = "Word " + key
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", roundi(14 * f))
	var picture: Variant = null
	var maker: Variant = _spec.get("picture", null)
	if maker is Callable and (maker as Callable).is_valid():
		picture = (maker as Callable).call(key)
	var art := TextureRect.new()
	art.name = "Picture"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(52, 52) * f
	# Without a game's own picture, the word's town object (word_pictures.gd, 23 Nov 2026).
	var pictures = WordPictures.shared()
	if picture is Texture2D:
		art.texture = picture
		row.add_child(art)
	elif pictures != null and pictures.fill(art, key):
		row.add_child(art)
	else:
		art.free()
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_theme_constant_override("separation", 0)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_child(BonStyle.label(lexicon.word(key, lexicon.foreign), 26, BonStyle.INK, f, 700, HORIZONTAL_ALIGNMENT_LEFT))
	texts.add_child(BonStyle.label(lexicon.word(key, lexicon.native), 18, BonStyle.INK_SOFT, f, 600, HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(texts)
	if fresh:
		var tag := PanelContainer.new()
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var look: StyleBox = BonStyle.box("choice_on", f)
		look.content_margin_left = 14.0 * f
		look.content_margin_right = 14.0 * f
		look.content_margin_top = 2.0 * f
		look.content_margin_bottom = 4.0 * f
		tag.add_theme_stylebox_override("panel", look)
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tag.add_child(BonStyle.label(UiText.t("results.new_tag"), 18, Color.WHITE, f, 700))
		row.add_child(tag)
	return row

func _continue() -> void:
	if not visible:
		return
	visible = false
	continued.emit()

func _replay() -> void:
	if not visible:
		return
	visible = false
	replay_requested.emit()
