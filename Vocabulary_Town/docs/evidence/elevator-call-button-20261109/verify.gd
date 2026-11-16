extends SceneTree
## Elevator call buttons and departure delay (9-10 Nov 2026; guide: docs/guides/HOSPITAL_THREE_FLOORS.md
## "Elevator call buttons"). In the real town, for the hospital and the control-tower elevators
## (both hospital_elevator.gd): an ElevatorCallButton on every landing and one per stop in the car
## (number on top, own glow colour), the old landing button and lamp gone, E/click reach them.
## Hospital behaviour: a press at the car's floor does not light; a press elsewhere lights and the
## doors stay open DEPART_DELAY s before closing; the button stays lit while the car travels,
## ignores a duplicate press and goes dark on arrival; landing and cabin buttons of one stop light
## together; a rider can choose a floor, step out and the car leaves without them; someone in the
## doorway holds the car until it is clear. Tower: a cabin-button trip.
## Floor picker (14 Nov 2026, scripts/ui/elevator_floor_picker.gd): E at the cabin panel (focus,
## or E on an aimed cabin button) opens the close-up with the player locked; a tap on a floor
## button calls the car and closes it; a tap outside, Esc and the X close it; the close-up follows
## a moving car; a plain click on a cabin button still presses it; cabin pick boxes are 1.5x wider,
## never overlap and never block the player (Area3D). Hospital and tower.
## Uses Main, which saves progress: run with an isolated HOME (README). Needs the hospital and
## airport units (full town or VT_FOCUS="hospital, airport"; report a focused run as focused).
## HOME=<scratch>/home VT_SPAWN=none godot --headless --path . --fixed-fps 60 --script res://docs/evidence/elevator-call-button-20261109/verify.gd
const Interactable := preload("res://scripts/core/interactable.gd")
const Interaction := preload("res://scripts/player/interaction_controller.gd")
const Elevator := preload("res://scripts/world/hospital_elevator.gd")
var failures := 0
var checks := 0
var game
var player: CharacterBody3D

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func finish() -> void:
	print("ELEVATOR CALL BUTTON: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func wait_for(done: Callable, frames := 1500) -> bool:
	for i in frames:
		if done.call():
			return true
		await physics_frame
	return done.call()

func seconds(s: float) -> void:
	for i in int(s * 60.0):
		await physics_frame

func frames(n: int) -> void:
	for i in n:
		await process_frame

func glow(button: Node3D) -> float:
	return button._face_mat.emission_energy_multiplier

func open_at(lift: Node3D, i: int) -> Callable:
	return func(): return lift.current_floor == i and lift.state == lift.State.OPEN

## Puts the player at an elevator-local spot on stop `i` (standing, at rest).
func put_player(lift: Node3D, i: int, local: Vector3) -> void:
	player.velocity = Vector3.ZERO
	player.global_position = lift.to_global(Vector3(local.x, lift.floor_ys[i] + .3, local.z))
	await seconds(.3)

## Every landing status line and the car's display show just the stop number `text`.
func shows(lift: Node3D, text: String) -> bool:
	return lift.car_label.text == text and lift.status_labels.all(func(l): return l.text == text)

func structure(lift: Node3D, label: String) -> void:
	var n: int = lift.floors()
	check(lift.landing_buttons.size() == n and lift.cabin_buttons.size() == n, "%s: a landing and a cabin button for each of %d stops" % [label, n])
	# Review fixes (10 Nov 2026): full-height doors, header text that fits, panel by the door.
	var leaves_ok := true
	for i in n:
		for leaf_body in lift.landing_doors[i].get_children():
			leaves_ok = leaves_ok and absf(lift.to_local(leaf_body.global_position).y - lift.floor_ys[i] - lift.door_h / 2.0) < .01
	for leaf_body in lift.car_doors.get_children():
		leaves_ok = leaves_ok and absf(lift.car.to_local(leaf_body.global_position).y - lift.door_h / 2.0) < .01
	check(leaves_ok, "%s: every door leaf stands on its floor (centre door_h/2 up, not half underground)" % label)
	# Open, every panel stays behind the jamb: outer edge 1.5 leaf + .05 within the door wall's
	# outer edge hw + .08 (flush with the side walls since the 10 Nov rebuild), and set_pair puts
	# the open panels there.
	var probe: Node3D = lift.landing_doors[lift.floors() - 1] if lift.current_floor != lift.floors() - 1 else lift.landing_doors[0]
	lift.set_pair(probe, 1.0)
	var tucked: bool = 1.5 * lift.leaf + .05 <= lift.hw() + .08 + .001 and 1.5 * lift.leaf + .05 <= lift.cw() / 2.0 + .06
	for k in 4:
		tucked = tucked and absf(absf(probe.get_child(k).position.x) - (1.25 * lift.leaf + .05)) < .001
	lift.set_pair(probe, 0.0)
	check(lift.landing_doors[0].get_child_count() == 4 and tucked, "%s: two-speed doors, open panels within the jambs" % label)
	var fits := true
	for i in n:
		var title: Label3D = lift.title_labels[i]
		var status: Label3D = lift.status_labels[i]
		var title_bottom: float = title.position.y - title.font_size * title.pixel_size / 2.0
		var status_top: float = status.position.y + status.font_size * status.pixel_size / 2.0
		fits = fits and title_bottom > status_top and title.position.y < lift.floor_ys[i] + lift.wall_h(i) and status.position.y > lift.floor_ys[i] + lift.door_h
	check(fits, "%s: floor title and number fit one above the other in every header" % label)
	check(lift.cabin_buttons.all(func(b): return lift.car.to_local(b.global_position).z < -lift.cd() / 2.0 + .2 and absf(lift.car.to_local(b.global_position).x) > lift.leaf), "%s: cabin panel on the front jamb beside the door" % label)
	check(lift.car.has_node("CabinFloorMat") and lift.car.has_node("CabinLightPanel") and lift.get("hint_card") == null, "%s: floor mat and light panel built; no hint card (E badge since 12 Nov 2026)" % label)
	# Rebuild (10 Nov 2026): the car clears the shaft walls and door wall (its side walls cut 4 cm
	# into the shaft's), has a front header, and its number display is centred above the door.
	check(lift.cw() / 2.0 + .06 < lift.hw() - .08 and lift.cd() / 2.0 + .06 < lift.hd() - .09 and lift.cd() / 2.0 + .06 < lift.hd() - .08, "%s: car 1 cm or more clear of the shaft and door wall" % label)
	var display: Vector3 = lift.car_label.position
	check(lift.car.has_node("CarHeader") and absf(display.x) < .01 and display.y > lift.door_h and display.y < Elevator.CAR_H and display.z < -lift.cd() / 2.0 + .2, "%s: car number display centred above the door (%s)" % [label, display])
	check(Elevator.FINISH > .04, "%s: car floor finish above the tower's lobby plinth (3.6 cm)" % label)
	check(lift.find_children("CallLamp*", "", false, false).is_empty() and lift.get_children().filter(func(c): return c.name.begins_with("Button") and not c is ElevatorCallButton).is_empty(), "%s: old landing button and call lamp removed" % label)
	for i in n:
		var landing: Node3D = lift.landing_buttons[i]
		var cabin: Node3D = lift.cabin_buttons[i]
		check(landing is ElevatorCallButton and cabin is ElevatorCallButton, "%s stop %d: both are ElevatorCallButtons" % [label, i])
		check(landing.target() == lift and cabin.target() == lift and landing.floor_index == i and cabin.floor_index == i, "%s stop %d: wired to the elevator and its stop" % [label, i])
		var p: Vector3 = lift.to_local(landing.global_position)
		check(absf(p.y - (lift.floor_ys[i] + 1.35)) < .01 and p.x < 0.0 and p.z < -lift.hd(), "%s stop %d: landing button on the right jamb of its door wall (%s)" % [label, i, p])
		check(cabin.get_parent() == lift.car and cabin.caption == lift.stop_name(i) and cabin.glow_color == Elevator.CABIN_GLOW and cabin.glow_color != landing.glow_color, "%s stop %d: cabin button in the car, number %s, its own glow colour" % [label, i, cabin.caption])
		var label3d: Array = cabin.find_children("*", "Label3D", true, false)
		check(label3d.size() == 1 and label3d[0].text == lift.stop_name(i), "%s stop %d: number shown on the cabin button" % [label, i])
		for b in [landing, cabin]:
			var picks: Array = b.find_children("Pick", "CollisionObject3D", true, false)
			var pick: Node = picks.front() if not picks.is_empty() else null
			check(pick != null and Interactable.find_for(pick, game.apartment) == Interactable.on(b) and b.has_method("use") and Interactable.on(b).needs_aim == (b == cabin), "%s %s: E and click reach it (its interactable; cabin buttons need aim)" % [label, b.name])
			check(not b.is_lit() and glow(b) == 0.0, "%s %s: dark while the elevator idles" % [label, b.name])
		# Landing picks are unchanged (a body over the plate); cabin picks 1.5x wider, an Area3D.
		var landing_pick: Node = landing.find_children("Pick", "CollisionObject3D", true, false).front()
		var cabin_pick: Node = cabin.find_children("Pick", "CollisionObject3D", true, false).front()
		check(landing_pick is StaticBody3D and not landing.picker_on_e, "%s stop %d: landing pick unchanged (StaticBody3D, E presses it)" % [label, i])
		var size: Vector3 = (cabin_pick.get_child(0).shape as BoxShape3D).size
		check(cabin_pick is Area3D and cabin.picker_on_e and is_equal_approx(size.x, cabin.button_radius * 2.8 * 1.5) and size.y > cabin.button_radius * 2.8 and size.y < Elevator.BUTTON_PITCH, "%s stop %d: cabin pick 1.5x wide (%.3f), taller than before, under the pitch (%.3f), an Area3D" % [label, i, size.x, size.y])
	var no_overlap := true
	for i in n - 1:
		var a: Node3D = lift.cabin_buttons[i]
		var b2: Node3D = lift.cabin_buttons[i + 1]
		no_overlap = no_overlap and absf(b2.position.y - a.position.y) - a.pick_extent().y > 0.0
	check(no_overlap, "%s: neighbouring cabin pick boxes do not overlap" % label)
	check(lift.cabin_panel != null and Interactable.on(lift.cabin_panel) != null and lift.cabin_panel.find_children("*", "StaticBody3D", true, false).is_empty(), "%s: the cabin panel is an interactable with no blocking body" % label)

func run():
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await physics_frame
	await physics_frame
	player = game.player
	var lifts: Array = game.apartment.find_children("*", "Node3D", true, false).filter(func(n): return n.get_script() == Elevator)
	var hospital: Node3D = null
	var tower: Node3D = null
	for lift in lifts:
		if lift.roof_stop:
			hospital = lift
		else:
			tower = lift
	check(hospital != null and tower != null, "hospital and control-tower elevators loaded (%d)" % lifts.size())
	if hospital == null or tower == null:
		finish()
		return
	structure(hospital, "hospital")
	structure(tower, "tower")
	var lift := hospital
	var landing: Array = lift.landing_buttons
	var cabin: Array = lift.cabin_buttons
	var arrivals: Array = []
	lift.arrived.connect(func(i: int): arrivals.append(i))
	# --- Press at the car's floor --------------------------------------------------------------
	check(lift.current_floor == 0 and lift.state == lift.State.OPEN, "hospital car starts open at floor 1")
	check(shows(lift, "1"), "displays inside and outside show just 1 (%s / %s)" % [lift.car_label.text, lift.status_labels[1].text])
	check(not landing[0].press() and not cabin[0].press(), "press at the car's floor is not accepted")
	await frames(20)
	check(not landing[0].is_lit() and glow(landing[0]) == 0.0 and lift.state == lift.State.OPEN and lift.pending.is_empty(), "press at the car's floor: not lit, no trip, nothing queued")
	# --- Press, the 2 s wait, duplicate, travel, arrival ---------------------------------------
	var pressed_floors: Array = []
	landing[1].pressed.connect(func(i: int): pressed_floors.append(i))
	check(landing[1].press(), "press on floor 2 accepted")
	check(landing[1].is_lit() and cabin[1].is_lit() and lift.state == lift.State.WAITING and lift.target_floor == 1, "press: lit (landing and cabin button of floor 2), car waiting")
	check(not landing[1].press() and not cabin[1].press() and lift.pending.is_empty() and pressed_floors == [1], "duplicate presses queue nothing")
	await frames(20)
	check(glow(landing[1]) > 0.0 and landing[1]._light.visible and glow(cabin[1]) > 0.0, "lit buttons glow")
	await seconds(lift.DEPART_DELAY - .5)
	check(lift.state == lift.State.WAITING and is_equal_approx(lift.door_fraction, 1.0) and is_equal_approx(lift.car.position.y, 0.0), "doors still open and car still %.1f s after the press" % (lift.DEPART_DELAY - .2))
	check(await wait_for(func(): return lift.state == lift.State.CLOSING, 60), "doors start closing after the %.0f s delay" % lift.DEPART_DELAY)
	check(await wait_for(func(): return lift.state == lift.State.MOVING), "car travels")
	check(landing[1].is_lit() and glow(landing[1]) > 0.0, "travel: still lit")
	check(cabin[2].press() and landing[2].is_lit() and lift.pending == [2], "floor 3 chosen in the car during the trip: queued, its landing button lit too")
	check(not landing[2].press() and lift.pending == [2], "duplicate floor 3 press queued nothing")
	check(await wait_for(func(): return lift.car.position.y > lift.floor_ys[1] * .6), "car past halfway to floor 2")
	check(shows(lift, "2"), "displays switch to 2 as the car nears floor 2 (%s)" % lift.car_label.text)
	check(await wait_for(func(): return arrivals.has(1)), "car arrives at floor 2")
	check(not landing[1].is_lit() and not cabin[1].is_lit(), "arrive: floor 2 buttons off at arrival")
	await frames(20)
	check(glow(landing[1]) == 0.0 and not landing[1]._light.visible, "arrive: floor 2 glow faded out")
	check(await wait_for(func(): return arrivals.has(2)), "queued trip continues to floor 3")
	check(not landing[2].is_lit() and not cabin[2].is_lit(), "floor 3 buttons off at arrival")
	check(shows(lift, "3"), "displays show 3 at floor 3")
	check(await wait_for(open_at(lift, 2)), "car open at floor 3")
	# --- A call at the floor where the car still stands holds it (no return trip) ---------------
	check(cabin[1].press() and lift.state == lift.State.WAITING, "floor 2 chosen; car waiting at floor 3")
	await seconds(1.5)
	landing[2].press()
	check(lift.state == lift.State.WAITING and is_equal_approx(lift.depart_wait, lift.DEPART_DELAY) and lift.pending.is_empty() and not landing[2].is_lit(), "call at floor 3 while waiting: the 2 s start again, nothing queued, not lit")
	await seconds(1.5)
	check(lift.state == lift.State.WAITING and is_equal_approx(lift.door_fraction, 1.0), "car still waiting 3 s after the first press")
	check(await wait_for(func(): return lift.state == lift.State.CLOSING and lift.door_fraction < .8, 120), "doors closing")
	landing[2].press()
	check(lift.state == lift.State.OPENING and lift.pending.is_empty(), "call at floor 3 while closing: the doors reopen, nothing queued")
	check(await wait_for(func(): return lift.state == lift.State.WAITING and is_equal_approx(lift.door_fraction, 1.0), 120) and lift.current_floor == 2 and lift.target_floor == 1, "doors open again, still bound for floor 2")
	check(await wait_for(open_at(lift, 1)), "then leaves for floor 2")
	check(not arrivals.has(2) or arrivals.count(2) == 1, "no extra trip back to floor 3")
	check(landing[2].press() and await wait_for(open_at(lift, 2)), "car called back to floor 3")
	# --- Choose a floor in the car, step out: the car leaves without the rider ------------------
	await put_player(lift, 2, Vector3(0, 0, .8))
	check(lift.inside_car(), "rider stands in the car at floor 3")
	check(cabin[0].press() and lift.state == lift.State.WAITING, "rider chooses floor 1 in the car")
	await put_player(lift, 2, Vector3(0, 0, -lift.hd() - 2.6))
	check(not lift.inside_car() and not lift.obstructed(), "rider stepped out onto the floor 3 landing within the delay")
	check(await wait_for(open_at(lift, 0)), "car goes to floor 1 without the rider")
	var p: Vector3 = lift.to_local(player.global_position)
	check(absf(p.y - lift.floor_ys[2]) < .5, "rider still on floor 3 (y %.2f)" % p.y)
	check(landing[2].press() and landing[2].is_lit(), "rider calls the car back to floor 3")
	check(await wait_for(open_at(lift, 2)), "car returns to floor 3")
	# --- Someone in the doorway holds the car -------------------------------------------------
	await put_player(lift, 2, Vector3(0, 0, -lift.hd() + .3))
	check(lift.obstructed(), "rider stands in the doorway")
	check(cabin[1].press(), "floor 2 chosen while the doorway is occupied")
	await seconds(lift.DEPART_DELAY + 1.5)
	check(lift.state == lift.State.WAITING and is_equal_approx(lift.door_fraction, 1.0) and cabin[1].is_lit(), "occupied doorway: doors stay open, the call is kept and lit")
	await put_player(lift, 2, Vector3(0, 0, -lift.hd() - 2.6))
	check(await wait_for(open_at(lift, 1)), "doorway cleared: the car leaves for floor 2")
	check(not cabin[1].is_lit(), "floor 2 button off at arrival")
	# --- A closed landing is closed full height ------------------------------------------------
	var space: PhysicsDirectSpaceState3D = lift.get_world_3d().direct_space_state
	var blocked := true
	for y in [.5, 1.5, 2.5, 3.0]:
		var from: Vector3 = lift.to_global(Vector3(.3, y, -lift.hd() - 3.0))
		var ray := PhysicsRayQueryParameters3D.create(from, lift.to_global(Vector3(.3, y, -lift.hd() + 2.0)))
		ray.exclude = [player.get_rid()]
		var hit := space.intersect_ray(ray)
		blocked = blocked and not hit.is_empty() and lift.landing_doors[0].is_ancestor_of(hit.collider)
	check(lift.current_floor != 0 and blocked, "closed floor 1 landing blocks the doorway up to 3 m")
	# --- Stop on the way, eased and faster ride, short stop, signals ----------------------------
	await put_player(lift, 2, Vector3(0, 0, -lift.hd() - 2.6))
	var events: Array = []
	lift.doors_closing.connect(func(i: int): events.append("close %d" % i))
	lift.departed.connect(func(a: int, b: int): events.append("depart %d>%d" % [a, b]))
	lift.doors_opening.connect(func(i: int): events.append("open %d" % i))
	arrivals.clear()
	check(lift.current_floor == 1 and cabin[3].press(), "floor 2: roof chosen")
	check(await wait_for(func(): return lift.state == lift.State.MOVING), "car leaves for the roof")
	check(cabin[2].press() and landing[2].is_lit(), "floor 3 chosen while passing below it")
	var top_speed := 0.0
	var start := Time.get_ticks_msec()
	while not arrivals.has(2) and Time.get_ticks_msec() - start < 20000:
		top_speed = maxf(top_speed, lift.speed)
		await physics_frame
	check(arrivals == [2] and lift.current_floor == 2 and lift.pending == [3], "car stops at floor 3 on the way, the roof still queued (%s, %s)" % [arrivals, lift.pending])
	check(top_speed > 2.05 and top_speed <= lift.MAX_SPEED + .001, "ride is faster than before and capped (top %.2f)" % top_speed)
	var frames_to_leave := 0
	while lift.state != lift.State.MOVING and frames_to_leave < 600:
		frames_to_leave += 1
		await physics_frame
	check(frames_to_leave < 4.0 * 60, "queued stop leaves without the old 1.5 s dwell (%.2f s)" % (frames_to_leave / 60.0))
	check(await wait_for(func(): return arrivals.has(3)), "then reaches the roof")
	check(events.has("close 1") and events.has("depart 1>3") and events.has("open 2") and events.has("depart 2>3") and events.has("open 3"), "sound signals fire for the trip: leaves for the roof, stops at 3 on the way (%s)" % [events])
	check(await wait_for(open_at(lift, 3)) and landing[1].press() and await wait_for(open_at(lift, 1)), "car back at floor 2")
	await picker_checks(lift, "hospital")
	# --- Tower: a cabin-button trip -----------------------------------------------------------
	# Tower shaft widened into its alcove (airport.gd widen_tower_elevator): a ray west from inside
	# the shaft, past its own walls, meets the stair wall right at the shaft's outer face.
	check(is_equal_approx(tower.shaft_w, 4.24) and is_equal_approx(tower.leaf, 1.1), "tower: shaft 4.24 wide, 2.2 door (%s, %s)" % [tower.shaft_w, tower.leaf])
	var west_from: Vector3 = tower.to_global(Vector3(0, 1.5, 0))
	var west_ray := PhysicsRayQueryParameters3D.create(west_from, tower.to_global(Vector3(-tower.hw() - 1.5, 1.5, 0)))
	west_ray.exclude = tower.find_children("*", "CollisionObject3D", true, false).map(func(b): return b.get_rid()) + [player.get_rid()]
	var west_hit := tower.get_world_3d().direct_space_state.intersect_ray(west_ray)
	var gap: float = INF if west_hit.is_empty() else -tower.to_local(west_hit.position).x - (tower.hw() + .08)
	check(gap < 0.0 and gap > -.05, "tower: no gap between the shaft and the stair wall (%.3f)" % gap)
	# Clicks reach the lobby button (user, 10 Nov 2026): the invisible guard that closed the old
	# alcove stood in front of it (airport.gd remove_tower_void_guard). Same ray as a click.
	for spot in [Vector3(0.3, 2.6, -tower.hd() - 2.2), Vector3(-1.5, 2.6, -tower.hd() - 1.5), Vector3(1.0, 2.6, -tower.hd() - 3.0)]:
		var eye: Vector3 = tower.to_global(spot)
		var aim_ray := PhysicsRayQueryParameters3D.create(eye, eye + (tower.landing_buttons[0].global_position - eye) * 1.2, 1)
		aim_ray.exclude = [player.get_rid()]
		var aim_hit := tower.get_world_3d().direct_space_state.intersect_ray(aim_ray)
		check(not aim_hit.is_empty() and Interactable.find_for(aim_hit.collider, game.apartment) == Interactable.on(tower.landing_buttons[0]), "tower: a click from the lobby %s reaches the call button (hit %s)" % [spot, aim_hit.get("collider")])
	var top: int = tower.floors() - 1
	check(tower.current_floor == 0 and tower.cabin_buttons[top].press(), "tower: top stop chosen in the car")
	check(tower.cabin_buttons[top].is_lit() and tower.landing_buttons[top].is_lit() and tower.state == tower.State.WAITING, "tower: both buttons of the top stop lit, car waiting")
	check(await wait_for(open_at(tower, top), 2400), "tower: car reaches the top stop")
	check(not tower.cabin_buttons[top].is_lit() and not tower.landing_buttons[top].is_lit(), "tower: buttons off at arrival")
	check(tower.landing_buttons[0].press() and await wait_for(open_at(tower, 0), 2400), "tower: landing call brings it back to the lobby")
	await tower_picker(tower)
	finish()

# --- Floor picker (14 Nov 2026) -------------------------------------------------------------

func picker_state(picker: Control, state: String) -> Callable:
	return func(): return picker.state == state

## Puts the player in the car at stop `i`, facing the cabin panel.
func face_panel(lift: Node3D, i: int) -> void:
	await put_player(lift, i, Vector3(minf(.8, lift.cw() / 4.0), 0, -lift.cd() / 2.0 + .9))
	var to_panel: Vector3 = lift.cabin_panel.global_position - player.global_position
	player.rotation.y = atan2(-to_panel.x, -to_panel.z)
	await seconds(.2)

func press_e(action: Callable) -> void:
	Input.action_press("use")
	action.call()
	Input.action_release("use")

func picker_checks(lift: Node3D, label: String) -> void:
	var picker: Control = game.elevator_floor_picker
	check(picker != null and picker.is_in_group("elevator_floor_picker"), "%s picker: built by Main" % label)
	if picker == null:
		return
	var stop: int = lift.current_floor
	await face_panel(lift, stop)
	check(lift.inside_car(), "%s picker: player in the car facing the panel" % label)
	# E through Main with the panel (or an aimed cabin button) focused.
	game.interaction.refresh_focus()
	var focus: Node = game.interaction.focus
	var panel_item: Node = Interactable.on(lift.cabin_panel)
	var focus_ok: bool = focus == panel_item or lift.cabin_buttons.any(func(b): return Interactable.on(b) == focus)
	check(focus_ok, "%s picker: the cabin panel (or a cabin button) is the E focus (%s)" % [label, focus.get_parent().name if focus != null else "none"])
	press_e(game.use_pressed)
	check(picker.state == "opening" and picker.visible and not player.controls_enabled and game.popups.top() == picker, "%s picker: E opens it, player locked, top of the Esc stack" % label)
	check(lift.pending.is_empty() and not lift.cabin_buttons.any(func(b): return b.is_lit()), "%s picker: opening calls nothing" % label)
	check(await wait_for(picker_state(picker, "open"), 120), "%s picker: camera arrives" % label)
	var cam: Camera3D = picker.camera
	var panel_at: Vector3 = lift.cabin_panel.global_position
	var centre: Vector2 = cam.unproject_position(panel_at) if cam != null else Vector2.INF
	var view: Vector2 = picker.size
	check(cam != null and cam.current and cam.global_position.distance_to(panel_at) < 3.0 and centre.distance_to(view * .5) < view.y * .1, "%s picker: close-up camera on the panel (%.2f m, panel at %s of %s)" % [label, cam.global_position.distance_to(panel_at) if cam != null else -1.0, centre, view])
	check(not player.visible, "%s picker: player model hidden in the close-up" % label)
	var rects_ok := true
	for i in lift.cabin_buttons.size():
		var r: Rect2 = picker.button_rect(i)
		rects_ok = rects_ok and r.size.y * 800.0 / view.y > 60.0 and picker.floor_at(r.get_center()) == i
		if i > 0:
			rects_ok = rects_ok and not r.intersects(picker.button_rect(i - 1))
	check(rects_ok, "%s picker: every floor button is a large separate target (%s)" % [label, picker.button_rect(0).size])
	# Tap outside the panel: closes, nothing called.
	var outside := Vector2(view.x * .05, view.y * .1)
	check(not picker.panel_rect().has_point(outside), "%s picker: test point is outside the panel" % label)
	picker.tap(outside)
	check(picker.state == "closing", "%s picker: a tap outside the panel closes it" % label)
	check(await wait_for(picker_state(picker, ""), 120) and not picker.visible and player.controls_enabled and player.visible and player.camera.current, "%s picker: camera back, player free and visible" % label)
	check(lift.pending.is_empty() and lift.state == lift.State.OPEN, "%s picker: closing called nothing" % label)
	# E on an aimed cabin button opens the picker too (it does not press the button).
	press_e(func(): lift.cabin_buttons[stop].use())
	check(picker.state == "opening", "%s picker: E on a cabin button opens the picker" % label)
	check(await wait_for(picker_state(picker, "open"), 120), "%s picker: open again" % label)
	# Esc (the popup stack) closes it.
	var esc := InputEventAction.new()
	esc.action = "back"
	esc.pressed = true
	Input.parse_input_event(esc)
	await frames(3)
	var esc_up := InputEventAction.new()
	esc_up.action = "back"
	Input.parse_input_event(esc_up)
	check(picker.state == "closing" or picker.state == "", "%s picker: Esc closes it" % label)
	check(await wait_for(picker_state(picker, ""), 120) and not game.settings_panel.visible, "%s picker: Esc closed only the picker (no Settings)" % label)
	# The X closes it.
	press_e(func(): Interactable.on(lift.cabin_panel).activate())
	check(await wait_for(picker_state(picker, "open"), 120), "%s picker: the panel's interactable opens it" % label)
	picker._close_button.pressed.emit()
	check(picker.state == "closing" and await wait_for(picker_state(picker, ""), 120), "%s picker: the X closes it" % label)
	# A plain click on a cabin button still presses it (no picker).
	var target: int = (stop + 1) % lift.floors()
	check(Interactable.on(lift.cabin_buttons[target]).activate() == "" and lift.cabin_buttons[target].is_lit() and picker.state == "", "%s picker: a click on cabin button %d presses it directly" % [label, target + 1])
	check(await wait_for(open_at(lift, target), 2400), "%s picker: car reached stop %d with the rider" % [label, target + 1])
	# Direct-click rays: 1.5x wider target, neighbours kept apart.
	var b0: Node3D = lift.cabin_buttons[0]
	var face: Vector3 = (b0.global_basis * Vector3(0, 0, 1)).normalized()
	var r0: float = b0.button_radius * b0.global_basis.get_scale().x
	var space: PhysicsDirectSpaceState3D = lift.get_world_3d().direct_space_state
	var hits := []
	for offset in [b0.global_basis.x.normalized() * r0 * 1.4 * 1.4, b0.global_basis.y.normalized() * (lift.BUTTON_PITCH * .5 - .006) * b0.global_basis.get_scale().y]:
		var aim: Vector3 = b0.global_position + offset
		var ray := PhysicsRayQueryParameters3D.create(aim + face * .8, aim - face * .2)
		ray.collide_with_areas = true
		ray.exclude = [player.get_rid()]
		var hit := space.intersect_ray(ray)
		hits.append(Interactable.find_for(hit.collider, game.apartment) == Interactable.on(b0) if not hit.is_empty() else false)
	check(hits == [true, true], "%s picker: a click 1.4x the old half-width off button 1, and just inside the pitch above it, reaches button 1 (%s)" % [label, hits])
	# Pick a floor in the picker: called, closed, the car takes the rider.
	stop = lift.current_floor
	await face_panel(lift, stop)
	press_e(game.use_pressed)
	check(await wait_for(picker_state(picker, "open"), 120), "%s picker: open at stop %d" % [label, stop + 1])
	var goal: int = (stop + 1) % lift.floors()
	var chosen: Array = []
	picker.floor_chosen.connect(func(i): chosen.append(i), CONNECT_ONE_SHOT)
	picker.tap(picker.button_rect(goal).get_center())
	check(chosen == [goal] and lift.cabin_buttons[goal].is_lit() and lift.target_floor == goal and picker.state == "closing", "%s picker: tapping floor %d calls the car there and closes" % [label, goal + 1])
	check(await wait_for(picker_state(picker, ""), 120) and player.controls_enabled, "%s picker: closed, player free" % label)
	check(await wait_for(open_at(lift, goal), 2400) and lift.inside_car(), "%s picker: the car takes the rider to stop %d" % [label, goal + 1])
	# The car moving while it is open: the close-up rides along.
	await face_panel(lift, goal)
	press_e(game.use_pressed)
	check(await wait_for(picker_state(picker, "open"), 120), "%s picker: open before the car moves" % label)
	var other: int = (goal + 1) % lift.floors()
	lift.call_elevator(other)
	check(await wait_for(func(): return lift.state == lift.State.MOVING, 600), "%s picker: car moves while the picker is open" % label)
	await seconds(.4)
	var gap: float = picker.camera.global_position.distance_to(lift.cabin_panel.global_position)
	var view_gap: float = lift.panel_view_transform(picker.camera.fov).origin.distance_to(lift.cabin_panel.global_position)
	check(picker.state == "open" and absf(gap - view_gap) < .05, "%s picker: the close-up follows the moving panel (%.2f / %.2f)" % [label, gap, view_gap])
	picker.close()
	check(await wait_for(picker_state(picker, ""), 120) and await wait_for(open_at(lift, other), 2400), "%s picker: closed during the ride; car arrives" % label)

func tower_picker(tower: Node3D) -> void:
	var picker: Control = game.elevator_floor_picker
	await face_panel(tower, 0)
	var top: int = tower.floors() - 1
	check(Interactable.on(tower.cabin_panel).activate() == "" and await wait_for(picker_state(picker, "open"), 120), "tower picker: opens on the tower's cabin panel")
	picker.tap(picker.button_rect(top).get_center())
	check(tower.cabin_buttons[top].is_lit() and tower.target_floor == top, "tower picker: tapping the top stop calls the car")
	check(await wait_for(picker_state(picker, ""), 120) and await wait_for(open_at(tower, top), 2400), "tower picker: closed; car reaches the top stop")
