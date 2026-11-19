extends SceneTree
## World signs (16 Nov 2026, scripts/world/world_sign.gd; rule:
## docs/guides/BUILDING_DESIGN_BLUEPRINT.md#sign-readability). In every playable language:
## every world sign keeps its letter height at or above its minimum (reading distance / 30), uses
## the shared font size, fits its board's free width (one line) or its lines (wrapped), and its
## lettering has WCAG 4.5 contrast against its outline or, without one, its board. Every sign
## label of the supermarket (the first building migrated) is a world sign. Also prints, for
## information, how many other town labels are still under 0.15 m (the migration follow-up).
## Isolated HOME (Main saves progress and settings):
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/world-signs-20261116/verify.gd
## Prints "WORLD SIGNS: N checks, M failures".
const WorldSign := preload("res://scripts/world/world_sign.gd")
const SignLanguage := preload("res://scripts/world/sign_language.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const SUPERMARKET := ["RelocatedSites/Supermarket", "Buildings/MarketDisplays", "Map facades/SUPERMARKET"]
## The supermarket's sign labels on 16 Nov 2026 (each interior sign has a back-side twin).
const SUPERMARKET_SIGNS := 37  # 35 on 16 Nov 2026; +HOME sign (front and back) on 18 Nov 2026
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func run():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 3: await physics_frame
	var town: Node3D = game.apartment
	var signs: Array = root.find_children("*", "Label3D", true, false).filter(func(l): return l.has_meta("world_sign"))
	print("world signs: %d" % signs.size())
	# 1. The supermarket is migrated.
	var market := 0
	for part in SUPERMARKET:
		if not town.has_node(part):
			check(false, "supermarket part %s is loaded (VT_FOCUS must include the supermarket)" % part)
			continue
		for label: Label3D in town.get_node(part).find_children("*", "Label3D", true, false):
			market += 1
			check(label.has_meta("world_sign"), "supermarket label %s is a world sign" % town.get_path_to(label))
	check(market == SUPERMARKET_SIGNS, "supermarket sign labels: %d (%d since 18 Nov 2026)" % [market, SUPERMARKET_SIGNS])
	# 2. The rule in every language.
	var shown := SignLanguage.shown_language()
	var seen := {}
	for code in Lexicon.shared().playable_codes():
		SignLanguage.set_language(self, code)
		for label: Label3D in signs:
			var key := "%s|%s" % [code, label.text]
			if seen.has(key):
				continue
			seen[key] = true
			var name := "%s %s (%s)" % [code, label.text.c_escape(), town.get_path_to(label)]
			var em := WorldSign.em_of(label)
			check(em >= float(label.get_meta("sign_min_em")) - 0.001, "%s letters %.3f m >= %.3f m" % [name, em, float(label.get_meta("sign_min_em"))])
			check(label.font_size == WorldSign.FONT_SIZE, "%s font size %d" % [name, label.font_size])
			if label.has_meta("sign_fit_width"):
				var fit: float = label.get_meta("sign_fit_width")
				if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
					var width := WorldSign.text_width(label)
					check(width <= fit + 0.01, "%s width %.2f m fits %.2f m" % [name, width, fit])
				else:
					var lines := _lines(label, fit)
					check(lines <= int(label.get_meta("sign_max_lines")), "%s wraps to %d lines" % [name, lines])
			var behind: Color = label.outline_modulate if label.outline_size > 0 else label.get_meta("sign_board", Color.BLACK)
			var ratio := WorldSign.contrast(label.modulate, behind)
			check(ratio >= WorldSign.MIN_CONTRAST - 0.01, "%s contrast %.1f" % [name, ratio])
	SignLanguage.set_language(self, shown)
	# 3. Information: other labels still under 0.15 m letters (the migration follow-up).
	var small := {}
	for label: Label3D in root.find_children("*", "Label3D", true, false):
		if label.has_meta("world_sign") or not label.is_visible_in_tree() or label.text.strip_edges() == "":
			continue
		if WorldSign.em_of(label) < 0.15:
			var owner_name := str(town.get_path_to(label)).get_slice("/", 0)
			small[owner_name] = int(small.get(owner_name, 0)) + 1
	print("not yet world signs, under 0.15 m: %s" % JSON.stringify(small))
	print("WORLD SIGNS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## Lines `label`'s text takes when wrapped at `fit` metres (greedy word wrap, as Label3D does).
func _lines(label: Label3D, fit: float) -> int:
	var lines := 0
	for paragraph in label.text.split("\n"):
		lines += 1
		var line := ""
		for word in paragraph.split(" ", false):
			var trial := word if line == "" else line + " " + word
			if line != "" and WorldSign.text_width(label, trial) > fit + 0.01:
				lines += 1
				line = word
			else:
				line = trial
	return lines
