extends SceneTree
## 4 Nov 2026: family-game words, school posters and Dr. Li in the real town (Main).
## Main saves progress, so run with an isolated HOME (README). A VT_FOCUS run that skips
## interiors must be reported as focused:
## HOME=<scratch>/home VT_FOCUS="school, hospital" godot --headless --path . --script res://docs/evidence/family-posters-20261104/verify_town.gd
const Lexicon := preload("res://scripts/language/lexicon.gd")
const Interaction := preload("res://scripts/player/interaction_controller.gd")
const POSTERS := ["Classroom poster family", "Classroom poster months", "Classroom poster before after", "Classroom poster older younger"]
var failures := 0
var checks := 0
func _initialize(): run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

## Bounds of every visible mesh under `node`, in `frame`'s local coordinates.
func bounds_in(frame: Node3D, node: Node3D) -> AABB:
	var to_frame := frame.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.is_visible_in_tree(): continue
		var local: AABB = mesh.get_aabb()
		for i in range(8):
			var p: Vector3 = to_frame * (mesh.global_transform * local.get_endpoint(i))
			box = AABB(p, Vector3.ZERO) if first else box.expand(p)
			first = false
	return box

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	await physics_frame
	await physics_frame
	var lex = Lexicon.shared()
	var town: Node3D = game.apartment
	var school: Node3D = town.get_node("Buildings/School")
	# --- Posters ------------------------------------------------------------------------
	var found := {}
	for title in POSTERS:
		var poster: Node3D = school.get_node_or_null(title)
		check(poster != null, title + " exists in the school")
		if poster == null: continue
		var box := bounds_in(school, poster)
		check(box.position.x > -11.75 and box.end.x < 11.75 and box.position.z > -12.0 and box.end.z < 5.56 and box.position.y > .3 and box.end.y < 4.6, title + " is inside the school shell: " + str(box))
		if title == "Classroom poster family":
			check(box.position.x > .1 and box.end.x < .3 and box.position.z > -3.2 and box.end.z < 5.55, "family tree lies flat on the divider's Science face: " + str(box))
		else:
			check(box.position.z > 5.4 and box.end.z < 5.56 and box.position.x < -.1 and box.end.y < 3.6, title + " lies on the General rear wall below its label: " + str(box))
		for node in poster.find_children("*", "Node3D", true, false):
			var key := str(node.get_meta("word_key", ""))
			if key == "": continue
			found[key] = found.get(key, 0) + 1
			# The word root's own pick area resolves to that root.
			var areas: Array = node.find_children("*", "Area3D", false, false)
			check(areas.size() == 1 and Interaction.vocabulary_target(areas[0], town) == node, "%s on %s is pickable through its own area" % [key, title])
			check(game.vocabulary.has(key), key + " is a words.json word")
			check(game.zones.resolve_global(node.global_position) == "school", key + " stands in the school zone (journal By Area): " + game.zones.resolve_global(node.global_position))
	# Rear-wall posters do not overlap one another.
	var rear: Array = []
	for title in POSTERS.slice(1):
		var poster: Node3D = school.get_node_or_null(title)
		if poster: rear.append(bounds_in(school, poster))
	for i in rear.size():
		for j in range(i + 1, rear.size()):
			check(rear[i].end.x < rear[j].position.x or rear[j].end.x < rear[i].position.x, "rear posters %d and %d do not overlap" % [i, j])
	# Every new word has an object; cousin twice (el primo, la prima).
	var family := ["mother", "father", "brother", "sister", "son", "daughter", "husband", "wife", "grandmother", "grandfather", "grandson", "granddaughter", "aunt", "uncle", "niece", "nephew", "boyfriend", "girlfriend", "older", "younger"]
	var time := ["before", "after", "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"]
	for key in family + time + ["cousin"]:
		check(found.has(key), key + " has a poster object")
	check(found.get("cousin", 0) == 2, "cousin appears twice")
	# Labels come from the Lexicon.
	var tree: Node3D = school.get_node_or_null("Classroom poster family")
	if tree:
		var expect := {"Family cousin m": "el primo", "Family cousin f": "la prima", "Family grandmother": "la abuela", "Family uncle": "el tío"}
		for title in expect:
			var node: Node3D = tree.get_node_or_null(title)
			var texts: Array = []
			if node:
				for l in node.find_children("*", "Label3D", false, false): texts.append(l.text)
			check(expect[title] in texts, "%s is labelled %s: %s" % [title, expect[title], texts])
		var me: Node3D = tree.get_node_or_null("Family me")
		check(me != null and not me.has_meta("word_key") and me.find_children("*", "Area3D", true, false).is_empty(), "'yo' is a plain, unclickable card")
	var months: Node3D = school.get_node_or_null("Classroom poster months")
	if months:
		var may: Node3D = months.get_node_or_null("Month may")
		var texts: Array = []
		if may:
			for l in may.find_children("*", "Label3D", false, false): texts.append(l.text)
		check(lex.phrase("posters.month_row", lex.foreign, {"number": 5, "month": "mayo"}) in texts, "May row reads '5  mayo': " + str(texts))
	# The L toggle: English mode re-renders every bound poster label in the native language.
	var LiveLabels = load("res://scripts/language/live_labels.gd")
	var bound: Array = game.get_tree().get_nodes_in_group(LiveLabels.GROUP)
	check(bound.size() >= 40, "poster labels are bound to the Lexicon: %d" % bound.size())
	game.hud.language_changed.emit(0)
	var english := {"Classroom poster family/Family uncle": "uncle", "Classroom poster family/Family cousin f": "cousin",
		"Classroom poster months/Month may": "5  May", "Classroom poster older younger/Age older": "older",
		"Classroom poster before after/Time after": "after", "Classroom poster family/Family me": "me"}
	for path in english:
		var node: Node3D = school.get_node_or_null(path)
		var texts: Array = []
		if node:
			for l in node.find_children("*", "Label3D", false, false): texts.append(l.text)
		check(english[path] in texts, "English mode: %s reads %s: %s" % [path, english[path], texts])
	var headers: Array = []
	if tree:
		for l in tree.find_children("*", "Label3D", false, false): headers.append(l.text)
	check("FAMILY  ·  LA FAMILIA" in headers and "COUPLES" in headers, "English mode family title and couples: " + str(headers))
	var too_wide := []
	for l in bound:
		var fit := float(l.get_meta("lexicon_fit"))
		var longest := 0
		for line in l.text.split("\n"): longest = maxi(longest, line.length())
		if fit > 0.0 and longest * l.font_size * LiveLabels.GLYPH_WIDTH * l.pixel_size > fit + .001: too_wide.append(l.text)
	check(too_wide.is_empty(), "English labels fit their cards: " + str(too_wide))
	game.hud.language_changed.emit(2)
	var back: Node3D = school.get_node_or_null("Classroom poster family/Family uncle")
	var back_texts: Array = []
	if back:
		for l in back.find_children("*", "Label3D", false, false): back_texts.append(l.text)
	check("el tío" in back_texts, "Both mode switches back to Spanish: " + str(back_texts))
	# The 31 Oct TIME and DIRECTIONS posters are unchanged on the General face.
	check(school.get_node_or_null("Classroom poster el") != null and school.get_node_or_null("Classroom poster las") != null, "existing TIME and DIRECTIONS posters remain")
	# --- Dr. Li -------------------------------------------------------------------------
	var hospital: Node3D = town.get_node("Buildings/Hospital")
	var dr_li: Node3D = hospital.get_node_or_null("DrLi")
	check(dr_li != null, "Dr. Li stands at the hospital")
	if dr_li:
		check(dr_li.scene_file_path.ends_with("pig_plush.tscn"), "Dr. Li is a pig plush")
		var costume: Node = dr_li.get_node_or_null("Costume")
		check(costume != null and str(costume.get("outfit")) == "doctor", "Dr. Li wears the doctor outfit")
		check(str(dr_li.get_meta("character_name", "")) == lex.phrase("hospital.dr_li", lex.foreign) and str(dr_li.get_meta("character_id", "")) == "dr_li", "Dr. Li's name and id: " + str(dr_li.get_meta("character_name", "")))
		check(dr_li.global_basis.get_scale().is_equal_approx(Vector3.ONE), "Dr. Li keeps world scale 1 (BonBon-sized)")
		var local := hospital.to_local(dr_li.global_position)
		check(local.x < -2.6 and local.x > -6.0 and local.z < -12.4 and local.z > -16.0, "Dr. Li is right of the entrance, outside, clear of the canopy posts: " + str(local))
		var facing := hospital.global_basis.inverse() * -dr_li.global_basis.z
		check(facing.z < -.5, "Dr. Li faces the street: " + str(facing))
		# Feet on the ground: the first surface under her (excluding herself) is at her lowest point.
		var bottom := bounds_in(town, dr_li).position.y
		var space := dr_li.get_world_3d().direct_space_state
		var from := dr_li.global_position + Vector3(0, 3, 0)
		var query := PhysicsRayQueryParameters3D.create(from, from - Vector3(0, 12, 0))
		var exclude: Array[RID] = []
		for body in dr_li.find_children("*", "CollisionObject3D", true, false): exclude.append(body.get_rid())
		query.exclude = exclude
		var hit := space.intersect_ray(query)
		var ground_y: float = town.to_local(hit.position).y if not hit.is_empty() else -INF
		check(not hit.is_empty() and absf(ground_y - bottom) < .12, "Dr. Li's lowest point %.3f is on the ground %.3f" % [bottom, ground_y])
		# Not in the doorway: the entrance (0, 0, -12.2) stays clear by more than 2 units.
		check(Vector2(local.x, local.z + 12.2).length() > 2.0, "Dr. Li leaves the entrance clear")
		var targetable: Node3D = Interaction.vocabulary_target(dr_li.find_children("*", "CollisionObject3D", true, false)[0], town) if not dr_li.find_children("*", "CollisionObject3D", true, false).is_empty() else null
		check(targetable == dr_li, "a click on Dr. Li reaches her (name card)")
	print("family posters town: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
