extends SceneTree
## Minigame lifecycle signals (PWA phase 4, 12 Nov 2026): activity_board.gd watch() emits
## started(id) when an activity begins running and ended(id, summary) when it stops, with the
## rounds, the target and whether it was completed; running_id follows. Uses stand-in sessions
## (no town, no saves): godot --headless --path . --script res://docs/evidence/activity-lifecycle-20261112/verify.gd
## Prints "ACTIVITY LIFECYCLE: N checks, M failures".
const Board := preload("res://scripts/learning/activity_board.gd")
var failures := 0
var checks := 0
var log: Array = []

class Stub:
	var running := false
	func activity_running() -> bool:
		return running

func _initialize(): run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)

func run():
	var board = Board.new()
	board.load_data()
	board.started.connect(func(id: String) -> void: log.append(["started", id]))
	board.ended.connect(func(id: String, summary: Dictionary) -> void: log.append(["ended", id, summary]))
	var ids: Array = board.activities.keys()
	var game: String = ids[0]
	var other: String = ids[1]
	var a := Stub.new()
	var b := Stub.new()
	board.register(game, a)
	board.register(other, b)
	board.set_rounds(game, 2)
	board.watch()
	check(log.is_empty() and board.running_id == "", "nothing running: no signal")
	board.begin(game)
	a.running = true
	board.watch()
	board.watch()
	check(log == [["started", game]] and board.running_id == game, "started once when the game runs")
	board.add_success(game)
	board.add_success(game)
	a.running = false
	board.watch()
	# Progression (18 Nov 2026) added "misses", "needed" and "custom" to the summary.
	var ended: Dictionary = log[1][2] if log.size() == 2 else {}
	check(log.size() == 2 and log[1][1] == game and ended.get("rounds") == 2 and ended.get("target") == 2 and ended.get("completed") == true and ended.get("misses") == 0 and ended.has("needed") and ended.has("custom"), "ended with a completed summary: %s" % str(log.back()))
	check(board.running_id == "", "running_id clears")
	board.begin(game)
	a.running = true
	board.watch()
	a.running = false
	board.watch()
	check(log[-1][2].completed == false and log[-1][2].rounds == 0, "a game left early ends not completed")
	b.running = true
	board.watch()
	check(log[-1] == ["started", other], "an activity without begin() is seen too")
	print("ACTIVITY LIFECYCLE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
