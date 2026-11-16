extends SceneTree
## Supermarket visual-quality views (8 Nov 2026); graphics required.
## VT_FOCUS=supermarket godot --path . --resolution 1200x800 --script res://docs/evidence/supermarket-visual-20261108/capture.gd -- <prefix>
## Writes <prefix>-<view>.png into this folder only (use an isolated HOME: Main may save progress).
## Optional view names after the prefix limit the run to those views.
func _initialize(): run.call_deferred()
func run():
	if DisplayServer.get_name()=="headless": quit(1); return
	var folder:="res://docs/evidence/supermarket-visual-20261108"
	var args:=OS.get_cmdline_user_args()
	var prefix:=(args[0]+"-") if args.size()>0 else ""
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.interaction.set_physics_process(false)
	game.hud.hide()
	var market: Node3D=game.apartment.get_node("RelocatedSites/Supermarket")
	var camera:=Camera3D.new()
	game.add_child(camera)
	camera.current=true
	camera.far=900.0
	# [name, eye, target, fov]: market-local (door x -35.8..-30.2 on the z=34.25 front wall,
	# +X is the left-hand side on entering, rear wall z=59.75).
	var views:=[
		["entrance",Vector3(-33,2.3,34.8),Vector3(-33,1.0,50),65.0],
		["checkout",Vector3(-33.5,2.2,42.5),Vector3(-39.5,1.0,36.5),65.0],
		["fruit",Vector3(-31.5,2.2,40.5),Vector3(-22,1.0,48),65.0],
		["pantry",Vector3(-41.3,2.0,41.8),Vector3(-41.3,1.0,52),65.0],
		["rear",Vector3(-33,2.3,51.5),Vector3(-33,1.2,59),65.0],
		["drinks",Vector3(-29.5,2.1,41.5),Vector3(-22,1.0,36),65.0],
		["close-fruit",Vector3(-23.6,1.7,45.2),Vector3(-21.0,.95,46.4),50.0],
		["close-veg",Vector3(-34.2,1.65,42.5),Vector3(-34.2,.8,44.0),50.0],
		["close-pantry",Vector3(-41.3,1.45,46.0),Vector3(-42.9,.85,47.6),50.0],
		["close-dairy",Vector3(-33,1.5,47.9),Vector3(-33,1.15,50.0),55.0],
		["close-bakery",Vector3(-26.5,1.85,54.7),Vector3(-25.0,1.1,56.8),50.0],
		["close-meat",Vector3(-36.5,1.85,54.7),Vector3(-34.5,1.1,56.8),50.0],
		["close-home",Vector3(-27.6,1.45,38.0),Vector3(-25.6,.7,38.6),50.0],
		["close-checkout",Vector3(-35.6,1.9,39.0),Vector3(-37.4,1.1,37.2),50.0],
		["close-lane2",Vector3(-41.0,1.85,38.9),Vector3(-39.5,1.1,36.6),50.0],
		["close-seafood",Vector3(-42.4,1.85,55.35),Vector3(-42.4,1.15,56.75),55.0],
		["close-baskets",Vector3(-28.95,1.3,36.7),Vector3(-28.95,.35,35.25),50.0],
		["close-cashier",Vector3(-43.4,1.75,38.0),Vector3(-44.85,1.1,36.9),45.0],
		["carts",Vector3(-37.3,1.9,29.6),Vector3(-39.6,.6,32.0),55.0],
	]
	var only:=args.slice(1)
	if not only.is_empty(): views=views.filter(func(v): return v[0] in only)
	for spec in views:
		camera.fov=spec[3]
		camera.global_position=market.to_global(spec[1])
		camera.look_at(market.to_global(spec[2]))
		for i in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder+"/"+prefix+spec[0]+".png")
	print("SUPERMARKET VISUAL CAPTURE done")
	quit()
