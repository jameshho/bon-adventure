extends SceneTree
## The lagoon fish under the water (23 Nov 2026, base step `fish_under_water`): a rendered view of
## the fish below the surface, then the swan boat driven (boat.drive, full pedal) from 14 units
## north straight over the fish's home, printing where it stops and a view of it passing over.
## Overwrites the PNGs here. Graphics and an isolated HOME:
## HOME=<scratch>/home VT_FOCUS=all VT_SPAWN=none godot --path . --resolution 1560x720 --script res://docs/evidence/fish-under-water-20261123/capture.gd
const DIR := "res://docs/evidence/fish-under-water-20261123/"
func _initialize(): run.call_deferred()
func shot(name: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(DIR+name))
func run():
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 40: await process_frame
	game.day_night.set_time(11.5 * 60.0)
	var town: Node3D = game.apartment
	var fish: Node3D = town.get_node("ParkZoo/Fish")
	var boat: Node3D = town.get_node("Swan boat")
	var water: MeshInstance3D = town.get_node("PublicGarden/Public Garden lagoon")
	var surface: float = (water.global_transform * water.get_aabb()).end.y
	var top := -INF
	for mesh: MeshInstance3D in fish.find_children("*", "MeshInstance3D", true, false):
		top = maxf(top, (mesh.global_transform * mesh.get_aabb()).end.y)
	print("FISH: top %.3f, water surface %.3f -> under water: %s" % [top, surface, top < surface])
	game.player.global_position = fish.global_position + Vector3(0, 0, 30)
	for i in 20: await physics_frame
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.global_position = fish.global_position + Vector3(4.5, 4.0, 5.5)
	camera.look_at(fish.global_position)
	camera.current = true
	game.hud.hide()
	await shot("fish.png")
	# The boat from 14 units north, bow pointing at the fish, full pedal.
	var home: Vector3 = town.to_local(fish.global_position)
	var start := home + Vector3(0, 0, 14)
	boat.transform = Transform3D(Basis.IDENTITY, Vector3(start.x, boat.position.y, start.z))
	boat.speed = 0
	var passed_z := 0.0
	for i in 600:
		boat.drive(1.0 / 60, 1.0, 0.0)
		await physics_frame
		if i == 240:
			camera.global_position = fish.global_position + Vector3(9, 5, 2)
			camera.look_at(fish.global_position)
			await shot("boat_over_fish.png")
		if boat.speed == 0 and i > 30: break
	print("BOAT: from z %.2f, stopped at z %.2f; fish home z %.2f -> passed the fish: %s" % [start.z, boat.position.z, home.z, boat.position.z < home.z - 4.0])
	quit()
