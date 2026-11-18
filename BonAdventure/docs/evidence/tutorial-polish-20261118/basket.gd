extends SceneTree
## Renders the carried shopping basket (scripts/world/shopping_basket.gd) with an apple and two
## bananas: from above as the Inspect view shows it, and from the side (tutorial polish,
## 18 Nov 2026). Graphics only. Output: basket_<tag>_<view>.png in this folder.
const Basket := preload("res://scripts/world/shopping_basket.gd")
func _init() -> void:
	var tag := "after"
	for a in OS.get_cmdline_user_args():
		tag = a
	root.size = Vector2i(900, 700)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.62, 0.66)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	world.add_child(sun)
	var basket: Node3D = load(Basket.SCENE).instantiate()
	world.add_child(basket)
	basket.show_items({"apple": 1, "banana": 2})
	var cam := Camera3D.new()
	cam.fov = 40
	world.add_child(cam)
	var views := {"top": [Vector3(0, 1.45, .25), Vector3(0, .1, 0)], "side": [Vector3(.75, .7, 1.0), Vector3(0, .18, 0)], "inspect": [Vector3(0, 1.2, .21), Vector3(0, .1, 0)]}
	for view in views:
		cam.look_at_from_position(views[view][0], views[view][1])
		if view == "inspect" and basket.has_method("on_inspect_begin"):
			basket.on_inspect_begin()
		for i in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/tutorial-polish-20261118/basket_%s_%s.png" % [tag, view])
	quit()
