extends SceneTree
## Mystery door reach (25 Nov 2026, bug: the doors could only be opened mid-jump). In the scaled
## house a leaf's middle is ~2.8 m above the floor, past interaction_controller.gd's MAX_RISE, so
## mystery_door.gd measures reach at hand height (REACH_Y). This stands BonBon on the floor in
## front of each mystery-room door and checks the focus pass picks it; for the hidden endless
## hall's doors it checks the reach point is within MAX_RISE of the floor below it.
## HOME=<scratch>/home VT_FOCUS=mystery VT_SPAWN=none \
##   godot --headless --path . --script res://docs/evidence/mystery-door-reach-20261125/verify.gd
## (works with the full town too; report a focused run as focused).
const Controller := preload("res://scripts/player/interaction_controller.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 6: await process_frame
	var player = game.player
	var ic = game.interaction
	var doors := []
	for n in get_nodes_in_group("interactables"):
		var o = n.get_parent()
		if o != null and o.has_meta("mystery_door"):
			doors.append(n)
	check(doors.size() == 12, "12 mystery doors (3 in the room, 9 in the hall): %d" % doors.size())
	var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	for item in doors:
		var leaf: Node3D = item.get_parent()
		var holder := leaf.get_parent().get_parent() as Node3D
		var label := "%s/%s" % [holder.get_parent().name, holder.name]
		# On the floor 1.4 m in front of the closed leaf, facing it.
		var front: Vector3 = holder.global_transform * Vector3(0, 0, 1.4)
		var q := PhysicsRayQueryParameters3D.create(front + Vector3.UP * 3.0, front + Vector3.DOWN * 5.0)
		q.exclude = [player.get_rid()]
		var hit: Dictionary = space.intersect_ray(q)
		var feet: Vector3 = hit.position if hit else Vector3(front.x, holder.global_position.y, front.z)
		var rise: float = item.point(feet).y - feet.y
		check(rise > 0.5 and rise < Controller.MAX_RISE, "%s: reach point %.2f m above the floor (under %.1f)" % [label, rise, Controller.MAX_RISE])
		if holder.get_parent().name != "DoorWall":
			continue  # the endless hall is hidden outside a game
		player.global_position = feet
		player.look_at(Vector3(leaf.global_position.x, feet.y, leaf.global_position.z), Vector3.UP, false)
		player.velocity = Vector3.ZERO
		for i in 3: await physics_frame
		ic.refresh_focus()
		check(ic.focus == item, "%s: focused from the floor without jumping" % label)
	print("MYSTERY DOOR REACH: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
