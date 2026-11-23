extends SceneTree
## 23 Nov 2026 (user): one registry for every NPC (data/npcs.json), idle chatter with brush-offs,
## the barn farmer, natural standing spots. Validator and demonstration:
##   1. the registry itself: unique permanent ids, scenes, costumes, units, activities, words, name
##      phrases, chatter groups (at least 3 lines each, brush-off sets) in every language;
##   2. the loaded town (every unit): every character node is in the registry, and every placed
##      registry NPC is in the town at its registry spot and facing, in its costume;
##   3. chatter: every NPC without an activity talks (TALK interactable, its word kept in the area
##      list); the demonstration prints the lines a player gets talking to the sports clerk again
##      and again (random, no repeat; brush-offs after 3; normal again after the reset), and a host
##      whose game is not on offer (Lana) answering with an idle line instead of "not now".
## With graphics it writes PNGs here (moved NPCs, the farmer, the chatter in the dialogue box).
## Headless (runner id npc_registry):
##   HOME=<scratch> VT_FOCUS=all VT_SPAWN=none godot --headless --path . --script res://docs/evidence/npc-registry-20261123/verify.gd
## Renders:
##   HOME=<scratch> VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1280x800 --script res://docs/evidence/npc-registry-20261123/verify.gd
const OUT := "res://docs/evidence/npc-registry-20261123"
const Registry := preload("res://scripts/characters/npc_registry.gd")
const Chatter := preload("res://scripts/characters/npc_chatter.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
const GameSettings := preload("res://scripts/core/game_settings.gd")
const PLACEMENTS := ["house", "scene", "registry", "runtime", "cast"]
var checks := 0
var failures := 0
var game
var town: Node3D
var graphics := false

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ", label)

func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	_check_data()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 6: await process_frame
	await physics_frame
	await physics_frame
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	town = game.apartment
	_check_town()
	if graphics:
		# Real clicks on the window would talk to the focused NPC (click = activate) and upset
		# the chatter count; the moved NPCs render first.
		for node in [game, game.interaction, game.player]:
			if node != null:
				node.set_process_input(false)
				node.set_process_unhandled_input(false)
		await _renders()
	await _check_chatter()
	# Let the last tweens and close-ups settle before quitting.
	for i in 30: await process_frame
	finish()

func finish() -> void:
	print("NPC REGISTRY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

# --- 1. The data ---------------------------------------------------------------------------

func _check_data() -> void:
	var lexicon = preload("res://scripts/learning/shop_dialogue.gd").new().lexicon
	var words: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/words.json"))["words"]
	var outfits: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/plush_costumes.json"))["outfits"]
	var units: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json"))["units"]
	var activities: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/activities.json")).get("activities", {})
	var groups: Dictionary = Registry.data().get("chatter_groups", {})
	var languages: Array = lexicon.codes()
	check(not FileAccess.file_exists("res://data/house_characters.json"), "data/house_characters.json is folded into the registry (one source)")
	var ids := {}
	var bad: Array = []
	for entry in Registry.all():
		var id := str(entry.get("id", ""))
		var problems: Array = []
		if not id.is_valid_identifier() or id != id.to_lower() or ids.has(id):
			problems.append("id")
		ids[id] = true
		if not ResourceLoader.exists(str(entry.get("scene", ""))):
			problems.append("scene")
		for field in ["costume", "work_costume"]:
			if str(entry.get(field, "")) != "" and not outfits.has(str(entry[field])):
				problems.append(field)
		var placement := str(entry.get("placement", ""))
		if not placement in PLACEMENTS:
			problems.append("placement")
		if placement != "cast" and not units.has(str(entry.get("unit", ""))):
			problems.append("unit")
		if placement in ["house", "scene", "registry"] and (not entry.get("at") is Array or not entry.has("facing")):
			problems.append("at/facing")
		if placement in ["scene", "registry"] and str(entry.get("node", "")) == "":
			problems.append("node")
		if placement == "runtime" and not FileAccess.file_exists("res://" + str(entry.get("owner", ""))):
			problems.append("owner")
		if str(entry.get("role", "")) == "host":
			var activity := str(entry.get("activity", ""))
			if not activities.has(activity) and not activity.begins_with("checkout_"):
				problems.append("activity")
		if str(entry.get("word", "")) != "" and not words.has(str(entry.word)):
			problems.append("word")
		if str(entry.get("name_phrase", "")) != "" and not lexicon.phrases.has(str(entry.name_phrase)):
			problems.append("name_phrase")
		if str(entry.get("chatter", "")) != "" and not groups.has(str(entry.chatter)):
			problems.append("chatter group")
		if not problems.is_empty():
			bad.append("%s (%s)" % [id, ", ".join(problems)])
	check(bad.is_empty(), "every registry entry is complete and valid (%d NPCs) %s" % [Registry.all().size(), bad])
	check(Registry.cast().size() == 9 and str(Registry.cast()[0].id) == "bonbon", "the cast keeps its 9 ids in their old order (avatars, tutorial stand-ins)")
	var thin: Array = []
	var chatter := Chatter.new()
	chatter.lexicon = lexicon
	for group in groups:
		var group_lines: Array = chatter.lines(group)
		if group_lines.size() < 3:
			thin.append(group)
		for set_name in ["brush_" + str(groups[group])]:
			if chatter.lines(set_name).size() < 2:
				thin.append(set_name)
		for id in group_lines:
			for code in languages:
				if str(lexicon.phrases[id].get(code, "")) == "":
					thin.append("%s/%s" % [id, code])
	chatter.free()
	check(thin.is_empty(), "every chatter group has 3+ lines and a brush-off set, in every language %s" % [thin])

# --- 2. The town ---------------------------------------------------------------------------

func _characters() -> Array:
	var found: Array = []
	var pending: Array[Node] = [game]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node == game.player or node is DriveableVehicle:
			continue
		if node is Node3D and node != game and (str(node.scene_file_path).begins_with("res://scenes/characters/") or node.has_meta("character_id") or node.has_meta("npc_id")):
			found.append(node)
			continue
		pending.append_array(node.get_children())
	return found

func _check_town() -> void:
	var by_id := {}
	var strays: Array = []
	var nodes := _characters()
	for node in nodes:
		var entry := Registry.of_node(node)
		if entry.is_empty():
			strays.append(str(game.get_path_to(node)))
			continue
		by_id[str(entry.id)] = node
	check(strays.is_empty(), "every character in the town is in the registry (%d found) %s" % [nodes.size(), strays])
	var missing: Array = []
	var off: Array = []
	var dressed: Array = []
	var turn: Basis = town.global_basis.orthonormalized()
	for entry in Registry.all():
		var placement := str(entry.get("placement", ""))
		var id := str(entry.id)
		if placement == "cast" or (placement == "house" and not bool(entry.get("in_house", true))):
			continue
		var node: Node3D = by_id.get(id)
		if node == null:
			missing.append(id)
			continue
		if placement in ["scene", "registry"]:
			var at := town.to_local(node.global_position)
			var goal := Registry.point(entry.at)
			var flat := Vector2(at.x - goal.x, at.z - goal.z).length()
			var forward := -node.global_basis.z
			forward.y = 0
			var want: Vector3 = turn * Registry.direction(entry.facing)
			var angle := rad_to_deg(forward.normalized().angle_to(want.normalized()))
			# Height: a host calling with its "!" hops up to 0.14 (npc_presence.gd).
			if flat > 0.02 or (placement == "scene" and absf(at.y - goal.y) > 0.2) or angle > 2.0:
				off.append("%s (%.2f m, %.1f°)" % [id, flat, angle])
		var outfit := str(entry.get("work_costume", entry.get("costume", "")))
		if placement != "house" and outfit != "":
			var costume := node.get_node_or_null("Costume")
			if costume == null or str(costume.get("outfit")) != outfit:
				dressed.append(id)
	# Standing NPCs: the body at belly height is free of walls and fixtures (the probe of
	# shop-staff-20261101/verify.gd), figure blockers and the player excluded.
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	var buried: Array = []
	var walled: Array = []
	for entry in Registry.all():
		var node: Node3D = by_id.get(str(entry.id))
		if node == null or str(entry.get("pose", "")) != "stand" or not str(entry.get("placement", "")) in ["scene", "registry", "runtime"]:
			continue
		var box := BoxShape3D.new()
		box.size = Vector3(1.0, 0.8, 0.7)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = box
		query.collision_mask = 0xFFFFFFFF & ~256
		query.exclude = [game.player.get_rid()]
		query.transform = Transform3D(node.global_basis.orthonormalized(), node.global_position + Vector3(0, 0.8, 0))
		var hits := space.intersect_shape(query, 4)
		if not hits.is_empty():
			buried.append("%s in %s" % [entry.id, hits.map(func(h) -> String: return str(h.collider.get_parent().name) + "/" + str(h.collider.name))])
		# Facing a wall: something solid right in front of the face (above any counter).
		var forward := -node.global_basis.z
		forward.y = 0
		var face := node.global_position + Vector3(0, 1.6, 0)
		var ray := PhysicsRayQueryParameters3D.create(face, face + forward.normalized() * 1.0, 0xFFFFFFFF & ~256)
		ray.exclude = [game.player.get_rid()]
		var hit := space.intersect_ray(ray)
		if not hit.is_empty():
			walled.append("%s (%s at %.2f)" % [entry.id, hit.collider.get_parent().name, face.distance_to(hit.position)])
	check(buried.is_empty(), "no standing NPC is inside a wall or fixture %s" % [buried])
	check(walled.is_empty(), "no standing NPC faces a wall within 1 m %s" % [walled])
	check(missing.is_empty(), "every placed registry NPC is in the town %s" % [missing])
	check(off.is_empty(), "every scene / registry NPC stands at its registry spot and facing %s" % [off])
	check(dressed.is_empty(), "every placed NPC wears its registry costume %s" % [dressed])
	# The moves of 23 Nov 2026.
	var clerk: Node3D = by_id.get("sports_clerk")
	check(clerk != null and town.to_local(clerk.global_position).distance_to(Vector3(91.15, 0.038, 248.55)) < 0.05, "the sports clerk stands at the front end of the checkout counter")
	var li: Node3D = by_id.get("dr_li")
	var hedge := town.get_node_or_null("Buildings/Hospital/Trimmed hedge9/Model/Hedge body") as MeshInstance3D
	if li != null and hedge != null:
		var box: AABB = (town.global_transform.affine_inverse() * hedge.global_transform) * hedge.get_aabb()
		var feet := town.to_local(li.global_position)
		check(feet.x - box.end.x > 0.5, "Dr. Li stands clear of the hedge (%.2f from it)" % (feet.x - box.end.x))
	var farmer: Node3D = by_id.get("tomas")
	check(farmer != null and town.get_node_or_null("Barn").is_ancestor_of(farmer), "the farmer Tomás is in the barn")
	if farmer != null:
		check(farmer.is_in_group("figures") and farmer.get_node_or_null("FigureBlocker") != null, "the farmer is solid and blinks like every plush")
		check(Interactable.on(farmer) != null and Interactable.on(farmer).kind == Interactable.Kind.TALK, "the farmer talks (E, click, tap)")
	# Who talks: hosts through their game's host, everyone else through the chatter.
	var silent: Array = []
	for id in by_id:
		var entry := Registry.spec(id)
		if str(entry.get("chatter", "")) != "" and Interactable.on(by_id[id]) == null:
			silent.append(id)
	check(silent.is_empty(), "every NPC with a chatter group can be talked to %s" % [silent])
	var kept := 0
	var dropped: Array = []
	for id in by_id:
		var node: Node3D = by_id[id]
		# Only the town's NPCs have word areas (the Home cast lives under Main and shows a name card).
		if town.is_ancestor_of(node) and node.get_meta("talk_keeps_word", false) and str(node.get_meta("word_key", "")) != "":
			if game.area_vocabulary.assignments.has(node):
				kept += 1
			else:
				dropped.append(id)
	check(kept > 10 and dropped.is_empty(), "chatting NPCs keep their role word in the area word lists (%d) %s" % [kept, dropped])
	var count := {}
	for id in by_id:
		var unit := str(Registry.spec(id).get("unit", "-"))
		count[unit] = int(count.get(unit, 0)) + 1
	print("NPCS BY UNIT ", count, " total ", by_id.size())

# --- 3. Chatter ----------------------------------------------------------------------------

func _check_chatter() -> void:
	var chatter = game.npc_chatter
	var panel = game.shop_panel
	check(chatter != null and Chatter.current == chatter, "Main has the chatter")
	var clerk := town.get_node_or_null("Buildings/SportsStore/Interior/GoldenSalesperson") as Node3D
	if clerk == null:
		return
	_stand_before(clerk, 2.0)
	var shop: Array = chatter.lines("shop")
	var brush: Array = chatter.lines("brush_staff")
	var said: Array = []
	for i in 6:
		chatter.talk(clerk)
		await process_frame
		said.append(panel.current_line())
		var line: Dictionary = panel.current_line()
		print("DEMO talk %d: %s  |  EN: %s" % [i + 1, line.get("foreign", ""), line.get("native", "")])
		if graphics and i in [0, 4]:
			await _screen("chatter-%s" % ("line" if i == 0 else "brush-off"))
		chatter.clock += 3.0
	var ids: Array = []
	for line in said:
		for id in shop + brush:
			if game.npc_chatter.lexicon.line(id) == line:
				ids.append(id)
				break
	check(ids.size() == 6, "every line came from the chatter phrases %s" % [ids])
	check(ids.slice(0, 3).all(func(id) -> bool: return id in shop), "the first 3 talks are shop lines")
	check(ids.slice(3).all(func(id) -> bool: return id in brush), "talks 4-6 in quick succession are brush-offs")
	var repeats := false
	for i in range(1, ids.size()):
		repeats = repeats or ids[i] == ids[i - 1]
	check(not repeats, "never the same line twice in a row")
	check(panel.is_dialogue_visible() and not panel.has_choices(), "the line shows in the shared dialogue box without choices (the player stays free)")
	var speaker: Dictionary = chatter.speaker(clerk)
	check(str(speaker.get("native", "")).to_lower().contains("salesperson"), "an unnamed clerk is introduced by its role word (%s / %s)" % [speaker.get("foreign"), speaker.get("native")])
	if graphics:
		# As if the HUD's EN were held: the HUD would end a peek with no key or button held.
		game.hud.set_process(false)
		GameSettings.shared().set_peek(true)
		for i in 3: await process_frame
		await _screen("chatter-brush-off-EN")
		GameSettings.shared().set_peek(false)
		game.hud.set_process(true)
	chatter.clock += Chatter.RESET_SECONDS + 1.0
	chatter.talk(clerk)
	await process_frame
	var after: Dictionary = panel.current_line()
	check(shop.any(func(id) -> bool: return chatter.lexicon.line(id) == after), "after a pause it chats normally again: %s" % after.get("foreign", ""))
	check(game.studied_words.has("salesperson"), "talking to the clerk counts its role word as studied")
	panel.hide_dialogue()
	# A host whose game is not on offer: an idle line of its group instead of "not now".
	var lana := town.get_node_or_null("Buildings/School/TeacherLana") as Node3D
	var host: Node = null
	for node in game.find_children("MinigameHost", "", true, false):
		if node.get("npc") == lana:
			host = node
	check(host != null, "Lana has her game's host")
	if host != null:
		_stand_before(lana, 2.0)
		host.offered = false
		host._on_talk(lana)
		for i in 3: await process_frame
		var line: Dictionary = panel.current_line()
		print("DEMO Lana (class not on offer): %s  |  EN: %s" % [line.get("foreign", ""), line.get("native", "")])
		check(chatter.lines("school").any(func(id) -> bool: return chatter.lexicon.line(id) == line), "Lana, with no class on offer, says an idle school line")
		if graphics:
			await _screen("host-not-on-offer")
		host.close_dialogue()
		host.offered = true
		host._on_talk(lana)
		for i in 3: await process_frame
		check(panel.has_choices(), "with the class on offer she still offers it (Yes / Not now)")
		host.close_dialogue()
		for i in 20: await process_frame
	# The farmer.
	var farmer := town.get_node_or_null("Barn/Farmer") as Node3D
	if farmer != null:
		_stand_before(farmer, 2.2)
		chatter.talk(farmer)
		await process_frame
		var line: Dictionary = panel.current_line()
		print("DEMO Tomás: %s  |  EN: %s" % [line.get("foreign", ""), line.get("native", "")])
		check(chatter.lines("farm").any(func(id) -> bool: return chatter.lexicon.line(id) == line), "the farmer chats about the farm")
		if graphics:
			await _screen("farmer-chatter")
		panel.hide_dialogue()

func _stand_before(npc: Node3D, distance: float) -> void:
	var forward := -npc.global_basis.z
	forward.y = 0
	forward = forward.normalized()
	var spot := npc.global_position + forward * distance
	game.player.global_position = spot + Vector3(0, 0.1, 0)
	game.player.velocity = Vector3.ZERO
	var yaw := atan2(forward.x, forward.z)
	game.player.rotation.y = yaw
	game.player.camera_yaw = yaw
	game.player.reset_camera()

# --- Renders -------------------------------------------------------------------------------

func _renders() -> void:
	for id in ["sports_clerk", "dr_li", "tomas"]:
		var entry := Registry.spec(id)
		var node := town.get_node_or_null(NodePath(str(entry.node))) as Node3D
		if node == null:
			continue
		var at := node.global_position
		var forward := -node.global_basis.z
		forward.y = 0
		forward = forward.normalized()
		await _view("%s-front" % id, at + forward * 4.0 + Vector3.UP * 2.4, at + Vector3.UP * 1.1, 0.05)
		await _view("%s-plan" % id, at + Vector3.UP * 14.0 + forward * 0.01, at, 11.4)

func _view(title: String, eye: Vector3, at: Vector3, near: float) -> void:
	var cam := Camera3D.new()
	cam.fov = 60.0 if near < 1.0 else 50.0
	cam.near = near
	cam.far = 400.0
	root.add_child(cam)
	cam.global_position = eye
	cam.look_at(at, Vector3.UP if absf((at - eye).normalized().y) < 0.99 else Vector3.FORWARD)
	var previous := root.get_viewport().get_camera_3d()
	cam.current = true
	game.hud.visible = false
	game.player.visible = false
	for i in 8: await process_frame
	await _drawn()
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)
	game.hud.visible = true
	game.player.visible = true
	cam.queue_free()
	if previous != null and is_instance_valid(previous):
		previous.current = true

## The game as the player sees it (HUD and dialogue box).
func _screen(title: String) -> void:
	for i in 10: await process_frame
	await _drawn()
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)

# Waits for a drawn frame, at most 120 process frames (a hidden window draws nothing, and the
# first render run, 23 Nov, waited forever on frame_post_draw).
func _drawn() -> void:
	var drawn := [false]
	var mark := func() -> void: drawn[0] = true
	RenderingServer.frame_post_draw.connect(mark, CONNECT_ONE_SHOT)
	for i in 120:
		if drawn[0]:
			return
		await process_frame
	if RenderingServer.frame_post_draw.is_connected(mark):
		RenderingServer.frame_post_draw.disconnect(mark)
	print("NOTE: no frame drawn (window hidden?); the capture may be stale")
