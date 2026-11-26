extends SceneTree
## Swing on a touch screen (25 Nov 2026, user: "on mobile, the swing does not work"). The touch
## joystick presses only move_forward / move_back with strength (touch_controls.gd
## _move_stick()), never climb_up / climb_down, so the swing never got a kick. Sits on a swing in
## touch mode and pushes the stick exactly as the touch layer does (Input.action_press).
## Isolated HOME (README): VT_FOCUS=playground HOME=<scratch> godot --headless --path . --fixed-fps 60 --script res://docs/evidence/swing-touch-20261125/verify.gd
var failures := 0
var game
func _initialize(): run.call_deferred()
func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1
func stick(action: String, strength: float, frames: int) -> void:
	Input.action_press(action, strength)
	for i in range(frames): await physics_frame
	Input.action_release(action)
	for i in range(4): await physics_frame
func peak(seconds: float, swing) -> float:
	var best := 0.0
	for i in range(int(seconds * 60)):
		await physics_frame
		best = maxf(best, absf(swing.angle))
	return best
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(10): await physics_frame
	game.hud.set_touch_mode(true)
	var kit: Node3D = game.apartment.get_node("RelocatedSites/Playground/Playground equipment")
	var seats: Array = game.seating.seats.filter(func(s): return kit.is_ancestor_of(s.node) and s.label == "swing")
	var seat: Node3D = seats[0].node
	var swing = seat.get_meta("playground_swing")
	var player = game.player
	player.global_position = seat.global_position + Vector3(0, -.6, -1.7)
	player.velocity = Vector3.ZERO
	for i in range(20): await physics_frame
	game.seating.sit_on(seat)
	var hint: String = game.hud.quest_toast.text  # before the first-ride achievement toast replaces it
	for i in range(60): await physics_frame
	check(player.seated and game.seating.current.get("node") == seat, "sits on the swing")
	check(hint.contains("joystick"), "touch hint names the joystick: " + hint)
	var rest := await peak(0.5, swing)
	await stick("move_forward", 0.3, 20)
	var light := await peak(2.0, swing)
	check(light < .05, "a light touch (30%%) does not kick (%.3f rad)" % light)
	await stick("move_forward", 0.9, 20)
	var kicked := await peak(3.0, swing)
	check(kicked > .05, "joystick pushed up kicks the swing (%.3f → %.3f rad)" % [rest, kicked])
	# Pump in time with the stick: forward as the seat starts forward, back as it starts back.
	var previous: float = swing.speed
	for i in range(int(10 * 60)):
		await physics_frame
		if previous <= 0.0 and swing.speed > 0.0: await stick("move_forward", 1.0, 3)
		elif previous >= 0.0 and swing.speed < 0.0: await stick("move_back", 1.0, 3)
		previous = swing.speed
	var built := await peak(2.7, swing)
	check(built > kicked + .2, "timed joystick pushes build momentum (%.2f → %.2f rad)" % [kicked, built])
	print("DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
