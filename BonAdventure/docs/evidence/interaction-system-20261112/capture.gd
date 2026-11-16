extends SceneTree
## Interaction system views (12 Nov 2026; docs/guides/ARCHITECTURE_REVIEW_PART1.md#interaction-system).
## Graphics required, isolated HOME, home unit loaded:
## (The avatar is hidden; the view is the player's.)
##   HOME=<scratch>/home VT_FOCUS=home VT_SPAWN=none godot --path . --resolution 1280x800 \
##     --script res://docs/evidence/interaction-system-20261112/capture.gd
## Writes next to this script: npc-bang.png (Mei's gold "!" from 8 m), npc-e.png (the "E" over
## her head in range), faucet.png (the badge on the lever), car-door.png (beside Subi's driver
## door), station-dot.png (the electrical box's dot from the path). Prints each view's focus.
const OUT := "res://docs/evidence/interaction-system-20261112/"
const ModularTown := preload("res://scripts/world/modular_town.gd")
var game
var probe: Camera3D

func _initialize(): run.call_deferred()

func frames(n: int) -> void:
	for i in n: await process_frame

## The player stands at `stand` facing `target`; the view is a camera a little behind and above
## her (aiming uses the same camera, so "aimed" means the screen centre).
func view(name: String, stand: Vector3, target: Vector3, back := 1.6, up := 1.7) -> void:
	var p = game.player
	p.global_position = stand
	var flat := target - stand
	flat.y = 0
	flat = flat.normalized()
	p.rotation.y = atan2(-flat.x, -flat.z)
	probe.global_position = stand - flat * back + Vector3.UP * up
	probe.look_at(target)
	probe.make_current()
	game.interaction.camera = probe
	game.interaction.pointer_position = root.get_visible_rect().size * 0.5
	await frames(20)
	game.interaction.refresh_focus()
	await frames(10)
	root.get_texture().get_image().save_png(OUT + name + ".png")
	var focus: Node = game.interaction.focus
	print("VIEW %s: focus %s, badge %s, bangs %d" % [name, focus.get_parent().name if focus != null else "none",
		game.interaction.icons.badge.visible, game.interaction.icons.bang_count()])

func run():
	if DisplayServer.get_name() == "headless":
		print("needs graphics")
		quit(1)
		return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(20)
	game.player.set_physics_process(false)
	# The avatar would fill the view from just behind it: hidden (it is no interaction target).
	for child in game.player.get_children():
		if child is VisualInstance3D or (child is Node3D and child.find_children("*", "MeshInstance3D", true, false).size() > 0):
			child.visible = false
	probe = Camera3D.new()
	probe.top_level = true
	probe.fov = 70
	root.add_child(probe)
	var home: Node3D = ModularTown.building(game.apartment, "home")
	if home == null:
		print("home not loaded (VT_FOCUS=home)")
		quit(1)
		return
	# Mei (mahjong host): offered, so she calls the player from a distance.
	var mahjong = null
	for child in game.get_children():
		if child.get_script() != null and child.get_script().resource_path.ends_with("mahjong_session.gd"):
			mahjong = child
	if mahjong != null and mahjong.host != null:
		var mei: Node3D = mahjong.host.npc
		mahjong.host.offered = true
		var front: Vector3 = mei.global_position + (game.player.global_position - mei.global_position).normalized() * 8.0
		front.y = mei.global_position.y
		await view("npc-bang", front, mei.global_position + Vector3.UP * 1.0)
		var near: Vector3 = mei.global_position + (front - mei.global_position).normalized() * 2.4
		await view("npc-e", near, mei.global_position + Vector3.UP * 1.0)
	var faucet: Node3D = home.find_child("Guest bathroom faucet", true, false)
	if faucet != null:
		var out: Vector3 = faucet.global_basis.z.normalized()
		await view("faucet", faucet.global_position + out * 0.8 - Vector3.UP * 0.9, faucet.global_position, 0.7, 1.9)
	var subi: Node3D = null
	for v in game.driveable_vehicles:
		if v.get_meta("character_name", "") == "Subi":
			subi = v
	if subi != null:
		await view("car-door", subi.to_global(Vector3(0, .1, 2.2)), subi.to_global(Vector3(0, 1.0, 0)), 2.2, 1.9)
	var box: Node3D = home.find_child("Electrical box", true, false)
	if box != null:
		var spot: Vector3 = box.front_center() + box.facing() * 7.0
		spot.y = box.front_center().y - 1.2
		await view("station-dot", spot, box.front_center(), 1.6, 1.8)
	quit(0)
