extends SceneTree
## Logic check for the Alta Cocina restaurant game (6 Nov 2026). No town, no saves, no
## output files: godot --headless --path . --script res://docs/evidence/restaurant-20261106/verify.gd
##  1. The dish catalog agrees with the schema, the words and the icon library.
##  2. Thousands of random menus and orders, with the shipped difficulty and with intensity
##     and negation forced on: every order exists, exactly one dish of its course on the
##     menu meets it (the target), and a wrong dish always has a requirement it misses.
##  3. Every order, fragment and miss line renders in every language with no placeholder
##     left, and Spanish orders say "algo" with masculine adjectives only.
## 11 Nov 2026: textures and extras were removed (taste, temperature and ingredients only);
## the miss line is Twinkle's report ("X quería algo dulce, pero le serviste el pescado ...").
const Orders := preload("res://scripts/learning/restaurant_orders.gd")
const FoodIcons := preload("res://scripts/ui/food_icons.gd")
const Lexicon := preload("res://scripts/language/lexicon.gd")
const MENUS := 3000

var failures: PackedStringArray = []
var checks := 0

func _initialize() -> void:
	catalog()
	orders("shipped", {})
	orders("intensity+negation", {"intensity_chance": 1.0, "negation_chance": 1.0})
	orders("negation, three requirements", {"negation_chance": 1.0, "sizes": {"2": 1, "3": 1}})
	for failure in failures.slice(0, 40):
		print("FAIL: ", failure)
	print("%s: %d checks, %d failed" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)

func catalog() -> void:
	var lexicon = Lexicon.shared()
	var ids := {}
	var props: Dictionary = Orders.properties()
	check(not props.has("texture") and not props.has("extra"), "no texture or extra properties (11 Nov 2026)")
	check(Orders.TAG_GROUPS == ["ingredient"], "orders only ask for ingredients as tags")
	for group in ["taste", "ingredient"]:
		for id in props.get(group, {}):
			check(lexicon.has_word(str(props[group][id].word)), "property word %s" % props[group][id].word)
			check(FoodIcons.has_property_icon(id), "icon for property %s" % id)
	for word in Orders.temperature_words():
		check(lexicon.has_word(str(Orders.temperature_words()[word].word)), "temperature word " + word)
		check(FoodIcons.has_property_icon(word), "icon for temperature " + word)
	for entry in Orders.dishes():
		var id := str(entry.id)
		check(not ids.has(id), "duplicate dish " + id)
		ids[id] = true
		check(Orders.courses().has(str(entry.course)), "%s: course %s" % [id, entry.course])
		check(lexicon.has_word(str(entry.word)), "%s: word %s" % [id, entry.word])
		check(int(entry.get("price", 0)) > 0, id + ": price")
		check(int(entry.get("temperature", -1)) >= 0 and int(entry.get("temperature", -1)) <= 4, id + ": temperature")
		for taste in entry.get("taste", {}):
			check(Orders.taste_ids().has(taste), "%s: taste %s" % [id, taste])
			check(int(entry.taste[taste]) >= 1 and int(entry.taste[taste]) <= 3, "%s: %s level" % [id, taste])
		for tag in entry.get("has", []):
			check(not Orders.tag_def(str(tag)).is_empty(), "%s: tag %s" % [id, tag])
		check(FoodIcons.art_problems(entry.get("art", {})).is_empty(), "%s: art %s" % [id, FoodIcons.art_problems(entry.get("art", {}))])
	var size: Array = Orders.data().menu_size
	for course in Orders.courses():
		var count := Orders.dishes().filter(func(d): return str(d.course) == course).size()
		check(count >= int(size[1]), "course %s has %d dishes, menus need %d" % [course, count, size[1]])

func orders(label: String, overrides: Dictionary) -> void:
	var lexicon = Lexicon.shared()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261106
	var engine := Orders.new(rng, overrides)
	var made := 0
	var sizes := {}
	var negations := 0
	var intensities := 0
	for m in MENUS:
		engine.new_menu()
		var served: Array = []
		var recent: Array = []
		for course in Orders.courses():
			var section: Array = engine.menu[course]
			check(section.size() >= 1, "%s: empty %s section" % [label, course])
			var order := engine.make_order(course, served, recent)
			check(not order.is_empty(), "%s: no order for %s on menu %s" % [label, course, section.map(func(d): return d.id)])
			if order.is_empty():
				continue
			made += 1
			var reqs: Array = order.reqs
			sizes[reqs.size()] = int(sizes.get(reqs.size(), 0)) + 1
			check(reqs.size() <= int(engine.difficulty.max_size), "%s: too many requirements" % label)
			check(Orders.count_matches(section, reqs) == 1, "%s: %d dishes match %s" % [label, Orders.count_matches(section, reqs), reqs])
			check(Orders.matches(Orders.dish(order.target), reqs), "%s: target %s does not match" % [label, order.target])
			check(section.any(func(d): return str(d.id) == order.target), "%s: target not on the menu" % label)
			var neg := reqs.filter(func(r): return Orders.is_negative(r)).size()
			check(neg <= 1, label + ": more than one negative")
			if neg > 0:
				negations += 1
				check(not Orders.is_negative(reqs[0]), label + ": negative requirement first")
			if reqs.any(func(r): return str(r.op) in ["little", "very"]):
				intensities += 1
			if float(engine.difficulty.get("negation_chance", 0.0)) == 0.0:
				check(neg == 0, label + ": negation while switched off")
			for entry in section:
				if str(entry.id) != order.target:
					check(not Orders.first_miss(entry, reqs).is_empty(), "%s: %s has no missed requirement" % [label, entry.id])
			# Text, every 7th menu (rendering is the slow part).
			if m % 7 == 0:
				for lang in lexicon.codes():
					var text: String = lexicon.text(Orders.order_ref(order), lang)
					check(not "{" in text and not "restaurant." in text, "%s: %s order text '%s'" % [label, lang, text])
					for req in reqs:
						var miss: String = lexicon.text(Orders.miss_ref(req, str(Orders.dish(order.target).word), "Leo"), lang)
						check(not "{" in miss and not "restaurant." in miss, "%s: %s miss text '%s'" % [label, lang, miss])
				var spanish: String = lexicon.text(Orders.order_ref(order), "es")
				check("quiero algo" in spanish, "Spanish order says algo: " + spanish)
				for feminine in ["fría", "salada", "ácida", "amarga", "tibia"]:
					check(not (" " + feminine) in spanish, "Spanish adjective agrees with algo: " + spanish)
				# Twinkle's report of a wrong order (two wrong dishes) and the customer's first line
				# (11 Nov 2026: 2-3 courses per visit).
				var report: String = lexicon.text(Orders.report_ref([[reqs[0], str(section[0].word)], [reqs[0], str(section[1].word)]], "Leo"), "es")
				check(report.begins_with("¡Uy! Leo quería algo ") and "pero le serviste " in report and " También quería algo " in report and report.ends_with("¡Inténtalo de nuevo la próxima vez!"), "Spanish report: " + report)
				for lang in lexicon.codes():
					for courses in [["starter", "drink"], ["starter", "main", "dessert"]]:
						var intro: String = lexicon.text(Orders.intro_ref(courses), lang)
						check(not "{" in intro and not "restaurant." in intro, "%s intro text '%s'" % [lang, intro])
						var wrong: String = lexicon.text(Orders.report_ref([[reqs[0], str(section[0].word)], [reqs[0], str(section[1].word)]], "Leo"), lang)
						check(not "{" in wrong and not "restaurant." in wrong, "%s report text '%s'" % [lang, wrong])
				check(lexicon.text(Orders.intro_ref(["starter", "drink"]), "es") == "Quisiera pedir una entrada y una bebida.", "Spanish intro: " + lexicon.text(Orders.intro_ref(["starter", "drink"]), "es"))
			if m < 3:
				print("  %s | %s | %s | %s" % [order.target, lexicon.text(Orders.order_ref(order), "es"), lexicon.text(Orders.order_ref(order), "en"), lexicon.text(Orders.order_ref(order), "zh")])
			served.append(order.target)
			for req in reqs:
				recent.append(Orders.prop_of(req))
	print("%s: %d orders; requirement counts %s; %d with intensity, %d with negation" % [label, made, sizes, intensities, negations])
	if float(engine.difficulty.get("negation_chance", 0.0)) >= 1.0:
		check(negations > made / 4, label + ": negation hardly ever possible")
	if float(engine.difficulty.get("intensity_chance", 0.0)) >= 1.0:
		check(intensities > made / 10, label + ": intensity hardly ever used")
