extends SceneTree
## GAME-05 (25 Nov 2026): the last-resort unstuck. Blocks every exit the seat and vehicle code try
## with boxes and shows the player still gets out:
##   1. an airport seat whose stand-up spots are all blocked: standing up finds a clear spot nearby
##      (PlayerPlace.safe_spot, level mode, indoors);
##   2. the same seat inside a closed cage: no spot in sight, so the player is respawned outside the
##      building's entrance (PlayerPlace.rescue_spot) and a running game ends (end_activity());
##   3. a fall below Main.FALL_RESPAWN_Y also ends a running game;
##   4. the parked scooter with every exit blocked: E gets off at a clear spot nearby.
## Uses only the game's own calls (stand(), toggle_vehicle(), the fall), so the same script was the
## probe on the code before the change. Run with VT_FOCUS=all, VT_SPAWN=none and an isolated HOME
## (README Verification); writes no files:
## godot --headless --path . --fixed-fps 60 --script res://docs/evidence/unstuck-20261125/verify.gd
const Board := preload("res://scripts/learning/activity_board.gd")
const PROBE_ID := "unstuck_probe"

## A stand-in for a running minigame: Board finds it through activity_running(), and a respawn
## must end it through end_activity() (the language-change stop path every in-world game has).
class FakeGame:
	extends RefCounted
	var running := true
	var ended := 0
	func activity_running() -> bool:
		return running
	func end_activity() -> void:
		ended += 1
		running = false

var game
var checks := 0
var failures := 0
var blockers: Array[Node3D] = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func frames(n: int) -> void:
	for i in n:
		await physics_frame

## A solid post standing on world point `foot` (box sizes are in the Apartment's 1.3 frame).
func post(foot: Vector3, size := Vector3(0.45, 1.4, 0.45)) -> void:
	var root: Node3D = game.box("Unstuck blocker", Vector3.ZERO, size, Color.RED, "", true)
	root.global_position = foot + Vector3.UP * size.y * 1.3 * 0.5
	blockers.append(root)

func clear_blockers() -> void:
	for node in blockers:
		node.free()
	blockers.clear()

func capsule_clear(p: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = game.player.get_node("PlayerCollision").shape
	q.transform = Transform3D(Basis.IDENTITY, p + Vector3.UP * 1.1)
	q.exclude = [game.player.get_rid()]
	return game.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()

func run() -> void:
	create_timer(420).timeout.connect(func(): print("TIMEOUT"); quit(1))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	await _blocked_seat()
	await _caged_seat()
	await _fall()
	await _blocked_vehicle()
	print("UNSTUCK: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## Sits on the first airport row seat (sat from the front, as check_seats_and_swan_boats.gd).
func _sit() -> Dictionary:
	var terminal: Node3D = game.apartment.get_node("Airport/Terminal")
	for s in game.seating.seats:
		if not terminal.is_ancestor_of(s.node) or terminal.to_local(s.point).x < -8:
			continue
		game.player.global_position = Vector3(s.point.x, terminal.global_position.y + 0.12, s.point.z) + s.forward * 1.1
		await frames(4)
		if game.seating.sit_on(s.node):
			await frames(40)
			if game.player.seated:
				return game.seating.current
	return {}

## Posts on every point seating_controller.safe_stand_position() tries.
func _block_stand_points(seat: Dictionary) -> void:
	var floor_y: float = game.seating.return_position.y
	var points: Array[Vector3] = [game.seating.return_position]
	if seat.node.has_meta("stand_position"):
		points.append(seat.node.to_global(seat.node.get_meta("stand_position")))
	var forward: Vector3 = seat.forward
	var side := forward.cross(Vector3.UP)
	for distance in [1.5, 2.2, 2.9]:
		for direction in [forward, side, -side, -forward]:
			points.append(seat.point + direction * distance)
	for p in points:
		post(Vector3(p.x, floor_y, p.z))

func _blocked_seat() -> void:
	var seat := await _sit()
	check(not seat.is_empty(), "sat on an airport row seat")
	if seat.is_empty():
		return
	var at: Vector3 = seat.point
	_block_stand_points(seat)
	await frames(2)
	check(game.seating.safe_stand_position().is_empty(), "every stand-up spot of the seat is blocked")
	game.seating.stand()
	await frames(40)
	var p: Vector3 = game.player.global_position
	var flat := Vector2(p.x - at.x, p.z - at.z).length()
	check(not game.player.seated, "blocked seat: the player stands up anyway")
	check(flat < 7.0, "blocked seat: stands nearby (%.2f m from the seat)" % flat)
	check(capsule_clear(p), "blocked seat: the standing spot is clear")
	check(game.player.collision_layer != 0, "blocked seat: walking collision is back")
	clear_blockers()

func _caged_seat() -> void:
	var fake := FakeGame.new()
	Board.shared().register(PROBE_ID, fake, true)
	var seat := await _sit()
	check(not seat.is_empty(), "sat on the seat again")
	if seat.is_empty():
		return
	var at: Vector3 = seat.point
	var floor_y: float = game.seating.return_position.y
	_block_stand_points(seat)
	post(Vector3(at.x, floor_y, at.z))
	# A closed cage 2 m wide around the seat, 3 m high, with a lid: nothing outside is in sight.
	var half := 1.0
	for side in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var size := Vector3(0.1, 3.0, 2.2) if side.x != 0.0 else Vector3(2.2, 3.0, 0.1)
		post(Vector3(at.x, floor_y, at.z) + side * half, size / 1.3)
	post(Vector3(at.x, floor_y + 3.0, at.z), Vector3(2.4, 0.1, 2.4) / 1.3)
	await frames(2)
	check(Board.shared().blocker("") == PROBE_ID, "a game is running")
	game.seating.stand()
	await frames(40)
	var p: Vector3 = game.player.global_position
	var flat := Vector2(p.x - at.x, p.z - at.z).length()
	check(not game.player.seated, "caged seat: the player gets out")
	check(flat > 3.0, "caged seat: respawned away from the cage (%.1f m)" % flat)
	check(capsule_clear(p), "caged seat: the respawn spot is clear")
	check(fake.ended == 1 and Board.shared().blocker("") == "", "caged seat: the respawn ended the running game (end_activity x%d)" % fake.ended)
	clear_blockers()

func _fall() -> void:
	var fake := FakeGame.new()
	Board.shared().register(PROBE_ID, fake, true)
	await frames(2)
	game.player.global_position = Vector3(game.player.global_position.x, game.FALL_RESPAWN_Y - 10.0, game.player.global_position.z)
	await process_frame
	await process_frame
	check(game.player.global_position.distance_to(game.spawn_position()) < 0.5, "fall: back at the spawn")
	check(fake.ended == 1, "fall: the respawn ended the running game (end_activity x%d)" % fake.ended)

func _blocked_vehicle() -> void:
	var bike: DriveableVehicle = game.apartment.get_node("Vehicles/Motorcycle")
	game.player.global_position = bike.boarding_step_point() + Vector3(0, 0.1, 0)
	await frames(2)
	check(game.board_vehicle(bike) and game.active_vehicle == bike, "gets on the scooter")
	for i in roundi(bike.boarding_duration * 60) + 40:
		await physics_frame
	check(not bike.boarding_busy() and game.active_vehicle == bike, "on the scooter")
	var points: Array[Vector3] = bike.preferred_exit_points()
	for direction in [bike.global_basis.x.normalized(), -bike.global_basis.x.normalized(), bike.global_basis.z.normalized(), -bike.global_basis.z.normalized()]:
		points.append(bike.global_position + direction * 3.3)
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	for p in points:
		var ray := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.5, p - Vector3.UP * 3.0)
		ray.exclude = bike.collision_exceptions + [game.player.get_rid()]
		var hit := space.intersect_ray(ray)
		post(hit.position if not hit.is_empty() else p)
	await frames(2)
	check(not bike.safe_exit(game.player).ok, "every exit of the scooter is blocked")
	var at := bike.global_position
	game.toggle_vehicle()
	for i in roundi(bike.boarding_duration * 60) + 40:
		if game.active_vehicle == null:
			break
		await physics_frame
	var p: Vector3 = game.player.global_position
	var flat := Vector2(p.x - at.x, p.z - at.z).length()
	check(game.active_vehicle == null and game.player.riding_vehicle == null, "blocked scooter: E gets off anyway")
	check(flat < 7.0, "blocked scooter: stands nearby (%.2f m)" % flat)
	check(capsule_clear(p), "blocked scooter: the standing spot is clear")
	clear_blockers()
