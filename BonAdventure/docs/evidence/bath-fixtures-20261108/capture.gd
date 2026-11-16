extends SceneTree
## Views of the working toilets and faucets (8 Nov 2026): each bathroom at rest, then with the
## toilet mid-flush and the faucet running. Overwrites the PNGs in this folder.
## Uses Main, which saves progress and settings: run with an isolated HOME (README).
## HOME=<scratch>/home VT_FOCUS=home,airport VT_SPAWN=none godot --path . --resolution 1200x800 --script res://docs/evidence/bath-fixtures-20261108/capture.gd
const FOLDER := "res://docs/evidence/bath-fixtures-20261108/"
const ModularTown := preload("res://scripts/world/modular_town.gd")
var camera: Camera3D

func _initialize(): run.call_deferred()

func frame(file: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(FOLDER + file + ".png")
	print("saved ", file)

func shot(space: Node3D, from: Vector3, at: Vector3, file: String, fov := 62.0) -> void:
	camera.fov = fov
	camera.global_position = space.to_global(from)
	camera.look_at(space.to_global(at))
	await frame(file)

## Starts a flush and/or turns a faucet on, then waits until the swirl is strong.
func act(toilet: Node, faucet: Node) -> void:
	if toilet != null: toilet.get_node("Model/Flush").use()
	if faucet != null and not faucet.is_on: faucet.use()
	await create_timer(.75).timeout

func run():
	if DisplayServer.get_name() == "headless": quit(1); return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(30): await process_frame
	game.player.set_physics_process(false); game.interaction.set_physics_process(false)
	game.hud.hide()
	var home: Node3D = ModularTown.building(game.apartment, "home")
	var terminal: Node3D = game.apartment.get_node("Airport/Terminal")
	var interior := terminal.get_node("Interior")
	game.player.global_position = terminal.to_global(Vector3(0, .3, -12))
	camera = Camera3D.new()
	game.add_child(camera)
	camera.far = 900.0
	camera.current = true
	# Home guest bathroom.
	var guest_toilet := home.get_node("Guest bathroom toilet")
	var guest_faucet := home.get_node("Guest bathroom faucet")
	await shot(home, Vector3(-6.2, 2.3, -3.4), Vector3(-7.7, .7, -6.3), "home-guest-rest", 70.0)
	await shot(home, Vector3(-7.3, 1.45, -4.9), Vector3(-8.0, .5, -6.5), "home-toilet-rest", 55.0)
	await act(guest_toilet, null)
	await shot(home, Vector3(-7.3, 1.45, -4.9), Vector3(-8.0, .5, -6.5), "home-toilet-flush", 55.0)
	await act(null, guest_faucet)
	await shot(home, Vector3(-6.5, 1.6, -5.0), Vector3(-6.5, 1.05, -6.1), "home-faucet-on", 55.0)
	await create_timer(2.0).timeout
	await act(guest_toilet, null)
	await shot(home, Vector3(-6.2, 2.3, -3.4), Vector3(-7.7, .7, -6.3), "home-guest-action", 70.0)
	# BonBon seated on the guest toilet (9 Nov 2026: E near a toilet sits).
	game.player.global_position = guest_toilet.to_global(Vector3(0, .05, 1.4))
	game.player.show()
	if game.seating.try_sit():
		await create_timer(1.0).timeout
		await shot(home, Vector3(-6.0, 2.0, -3.6), Vector3(-7.7, .9, -6.3), "home-toilet-seated", 62.0)
		game.seating.stand()
		await create_timer(1.0).timeout
	else:
		print("could not sit on the guest toilet")
	# Family bathroom, from its doorway.
	await shot(home, Vector3(-5.3, 2.2, 10.7), Vector3(-8.2, .6, 8.4), "home-family", 72.0)
	# Kitchen faucet.
	var kitchen := home.get_node("Sink tap")
	await shot(home, Vector3(10.0, 2.2, 8.4), Vector3(11.8, 1.4, 7.2), "kitchen-rest", 58.0)
	await act(null, kitchen)
	await shot(home, Vector3(10.0, 2.2, 8.4), Vector3(11.8, 1.4, 7.2), "kitchen-on", 58.0)
	# Airport: the claim with the restroom block, then inside both rooms with the doors open.
	await shot(terminal, Vector3(4.5, 3.8, -7.8), Vector3(13.5, 1.4, -1.2), "airport-claim", 70.0)
	await shot(terminal, Vector3(13.9, 6.5, -3.6), Vector3(13.9, 0, -.2), "airport-above", 75.0)
	for title in ["Women's restroom door", "Men's restroom door"]:
		game.doors[interior.get_node(title)]["open"] = true
	await create_timer(1.0).timeout
	await shot(terminal, Vector3(12.0, 2.6, -3.4), Vector3(12.7, .9, .5), "airport-women-rest", 66.0)
	await act(interior.get_node("Women's restroom toilet"), interior.get_node("Women's restroom faucet"))
	await shot(terminal, Vector3(12.0, 2.6, -3.4), Vector3(12.7, .9, .5), "airport-women-action", 66.0)
	await act(interior.get_node("Men's restroom toilet"), interior.get_node("Men's restroom faucet"))
	await shot(terminal, Vector3(15.6, 2.7, -1.5), Vector3(15.1, .8, .6), "airport-men-action", 70.0)
	quit(0)
