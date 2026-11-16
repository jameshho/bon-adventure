extends SceneTree
## Renders the two control-tower radars from the baked airport unit (no town) and checks their
## Radar Patrol hookup. godot --path . --resolution 900x700 --script res://docs/evidence/radar-patrol-20261109/capture_radars.gd
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	var town := Node3D.new()
	root.add_child(town)
	var airport: Node = load("res://scenes/town/airport.scn").instantiate()
	town.add_child(airport)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.8)
	env.environment.ambient_light_energy = 1.0
	root.add_child(env)
	var cam := Camera3D.new()
	cam.fov = 50
	root.add_child(cam)
	cam.current = true
	for radar in airport.find_children("Radar *", "Node3D", true, false):
		if str(radar.get_meta("word_key", "")) != "radar":
			continue
		print("%s: script=%s word=%s click_play=%s hint=%s use=%s" % [radar.name, radar.get_script().resource_path if radar.get_script() else "none", radar.get_meta("word_key"), radar.get_meta("click_play", false), radar.get_meta("action_hint", ""), radar.has_method("use")])
		var screen: Node3D = radar.get_node("RadarScreen")
		var normal: Vector3 = screen.global_basis.z.normalized()
		var target := screen.global_position
		cam.global_position = target + normal * 1.6 + Vector3(0, 0.5, 0) + screen.global_basis.x * 0.4
		cam.look_at(target)
		for i in 8:
			await process_frame
		root.get_texture().get_image().save_png("res://docs/evidence/radar-patrol-20261109/%s.png" % str(radar.name).replace(" ", "-").to_lower())
		print("saved ", radar.name)
	quit()
