extends SceneTree
## 25 Nov 2026 character motion (ANIM-07, ANIM-04/01, ANIM-05; docs/guides/COMPONENTS.md
## #plush-characters, docs/guides/NPCS.md#facing-the-player):
##   - an ambient NPC (the farmer) talked to from the side turns by yaw toward the player, never
##     moving its Head, and eases back when the line closes; it waits while `calling`;
##   - a turn that would swing it into a wall is shortened or skipped; a seated figure never turns;
##   - a minigame host (Lana) faces the player while its greeting shows, and turns back;
##   - the calling hop eases down instead of snapping, with physics interpolation off only meanwhile;
##   - gesture tweens and the carried-item pendulum run on physics ticks.
## HOME=<scratch> VT_FOCUS="barn, school" VT_SPAWN=none \
##   godot [--headless] --path . --resolution 1280x800 --script res://docs/evidence/characters-20261125/verify.gd
## With graphics it writes facing-*.png here; reads no saves (isolated HOME).
const OUT := "res://docs/evidence/characters-20261125"
const PlushLife := preload("res://scripts/characters/plush_life.gd")
const Interactable := preload("res://scripts/core/interactable.gd")
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
		print("FAIL: ", label)

func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 6: await process_frame
	await physics_frame
	town = game.apartment
	game.player.set_physics_process(false)
	if game.day_night:
		game.day_night.pause()
		game.day_night.set_time(12 * 60.0)
	await _check_farmer()
	await _check_host()
	_check_ticks()
	print("CHARACTERS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func ticks(n: int) -> void:
	for i in n: await physics_frame

## Puts the player `distance` m from `npc`, `angle` radians round from its facing.
func stand_beside(npc: Node3D, distance: float, angle: float) -> void:
	var forward := -npc.global_basis.z
	forward.y = 0
	forward = forward.normalized().rotated(Vector3.UP, angle)
	game.player.global_position = npc.global_position + forward * distance + Vector3(0, 0.1, 0)
	game.player.velocity = Vector3.ZERO
	game.player.rotation.y = atan2(forward.x, forward.z)
	game.player.camera_yaw = game.player.rotation.y + PI * 0.25
	game.player.reset_camera()

## Radians between `npc`'s facing and the direction to the player.
func off_player(npc: Node3D) -> float:
	var forward := -npc.global_basis.z
	var to: Vector3 = game.player.global_position - npc.global_position
	return absf(Vector2(forward.x, forward.z).angle_to(Vector2(to.x, to.z)))

func _check_farmer() -> void:
	var chatter = game.npc_chatter
	var panel = game.shop_panel
	var farmer := town.get_node_or_null("Barn/Farmer") as Node3D
	check(farmer != null, "the farmer is loaded")
	if farmer == null:
		return
	var head := farmer.get_node("Head") as Node3D
	var head_rest := head.transform
	var rest_yaw := farmer.rotation.y
	var rest_position := farmer.position
	stand_beside(farmer, 2.4, 1.0)
	var before := off_player(farmer)
	if graphics:
		await _screen("facing-farmer-before")
	# Calling: it waits.
	var item := Interactable.on(farmer)
	item.calling = true
	chatter.talk(farmer)
	check(PlushLife.facing(farmer), "talking starts the farmer's turn")
	await ticks(20)
	check(is_equal_approx(farmer.rotation.y, rest_yaw), "a calling NPC does not turn yet")
	item.calling = false
	await ticks(45)
	var after := off_player(farmer)
	check(after < before - 0.5, "the farmer turns toward the player (%.2f -> %.2f rad)" % [before, after])
	check(head.transform.is_equal_approx(head_rest), "the farmer's Head is never moved")
	check(farmer.position.is_equal_approx(rest_position), "only the yaw changes, not the spot")
	if graphics:
		await _screen("facing-farmer-turned")
	panel.hide_dialogue()
	await ticks(70)
	check(is_equal_approx(farmer.rotation.y, rest_yaw) and not PlushLife.facing(farmer), "the farmer eases back to his own facing (%.3f vs %.3f)" % [farmer.rotation.y, rest_yaw])
	# Straight in front: nothing to turn.
	stand_beside(farmer, 2.4, 0.0)
	check(is_nan(PlushLife.facing_yaw(farmer, game.player.global_position, [game.player])), "a player straight ahead needs no turn")
	# Wall clearance: a wall where the turn would swing his back.
	stand_beside(farmer, 2.4, 1.0)
	var open_yaw := PlushLife.facing_yaw(farmer, game.player.global_position, [game.player])
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(0.1, 2.0, 1.2)
	wall.add_child(shape)
	farmer.get_parent().add_child(wall)
	var back := farmer.global_basis.z
	back.y = 0
	back = back.normalized().rotated(Vector3.UP, 0.9)
	wall.global_position = farmer.global_position + back * 0.4 + Vector3(0, 1.0, 0)
	wall.look_at(farmer.global_position + Vector3(0, 1.0, 0), Vector3.UP)
	wall.rotate_object_local(Vector3.UP, PI * 0.5)
	await ticks(2)
	var walled_yaw := PlushLife.facing_yaw(farmer, game.player.global_position, [game.player])
	var open_turn := absf(angle_difference(rest_yaw, open_yaw))
	var walled_turn := 0.0 if is_nan(walled_yaw) else absf(angle_difference(rest_yaw, walled_yaw))
	check(not is_nan(open_yaw) and walled_turn < open_turn - 0.1, "a wall behind shortens or stops the turn (%.2f -> %.2f rad)" % [open_turn, walled_turn])
	wall.free()
	# A seated figure never turns.
	farmer.set_meta("seat_point", farmer.global_position)
	check(not PlushLife.face_while(game, farmer, game.player, func() -> bool: return true), "a seated NPC is skipped")
	farmer.remove_meta("seat_point")
	farmer.set_meta("napping", true)
	check(not PlushLife.face_while(game, farmer, game.player, func() -> bool: return true), "a napping NPC is skipped")
	farmer.remove_meta("napping")

func _check_host() -> void:
	var lana := town.get_node_or_null("Buildings/School/TeacherLana") as Node3D
	var host: Node = null
	for node in game.find_children("MinigameHost", "", true, false):
		if node.get("npc") == lana:
			host = node
	check(host != null, "Lana has her game's host")
	if host == null:
		return
	var rest_yaw := lana.rotation.y
	var presence = host.presence
	stand_beside(lana, 2.2, 0.9)
	var before := off_player(lana)
	# The hop eases down instead of snapping (ANIM-04) with interpolation off only meanwhile.
	var mode := lana.physics_interpolation_mode
	presence.animate(0.2, true)
	presence.animate(0.2, true)
	var lifted: float = lana.position.y - presence.rest_position.y
	check(lifted > 0.03, "the calling hop lifts Lana (%.3f)" % lifted)
	check(lana.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF, "interpolation is off while the hop moves her each frame")
	presence.animate(1.0 / 60.0, false)
	var one: float = lana.position.y - presence.rest_position.y
	check(one > 0.0 and one < lifted, "one frame after calling stops she is on her way down, not snapped (%.3f -> %.3f)" % [lifted, one])
	for i in 40:
		presence.animate(1.0 / 60.0, false)
	check(lana.position.is_equal_approx(presence.rest_position), "she settles at rest")
	check(lana.physics_interpolation_mode == mode, "interpolation is back as it was at rest")
	# Talking: the host faces the player while its line shows.
	host.offered = true
	host._on_talk(lana)
	await ticks(50)
	var after := off_player(lana)
	check(game.shop_panel.is_dialogue_visible(), "Lana's line shows")
	check(after < before - 0.4, "Lana turns toward the player while talking (%.2f -> %.2f rad)" % [before, after])
	if graphics:
		await _screen("facing-lana-talking")
	host.close_dialogue()
	await ticks(80)
	check(is_equal_approx(lana.rotation.y, rest_yaw), "Lana turns back after the talk")

func _check_ticks() -> void:
	# Gestures run on physics ticks (ANIM-01).
	var figure := town.get_node_or_null("Barn/Farmer") as Node3D
	if figure != null:
		var tween: Tween = PlushLife.play(game, figure, "hop")
		check(tween != null and figure.get_meta(PlushLife.GESTURE_META) == tween, "a gesture is recorded on the figure")
		tween.custom_step(10.0)
	# The pendulum (ANIM-05): physics ticks, not frames.
	var hand = game.player.hand
	var bag := Node3D.new()
	bag.set_meta("hold_kind", "bag")
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	bag.add_child(mesh)
	town.add_child(bag)
	hand.hold(bag)
	check(hand.is_physics_processing() and not hand.is_processing(), "a swinging item sways on physics ticks")
	hand.release(null, null, false)
	check(not hand.is_physics_processing(), "an empty hand stops ticking")
	bag.queue_free()

func _screen(title: String) -> void:
	game.hud.visible = false
	for i in 10: await process_frame
	var drawn := [false]
	RenderingServer.frame_post_draw.connect(func() -> void: drawn[0] = true, CONNECT_ONE_SHOT)
	for i in 120:
		await process_frame
		if drawn[0]:
			break
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, title])
	print("CAPTURE ", title)
	game.hud.visible = true
