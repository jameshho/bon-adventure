extends "res://docs/evidence/interiors-polish-20261109/audit.gd"
## 9 Nov 2026 interiors polish verify: in the sports store, furniture store, Pizza and Burger and
## police station every word root is learnable, has a collision shape, is visible and a pointer
## ray reaches it (except the documented exceptions below), and every word key present before
## the polish (keys-before.txt) is still present.
## HOME=<scratch> VT_FOCUS="sports, furniture, restaurants, police" VT_SPAWN=none \
##   godot --headless --path . --script res://docs/evidence/interiors-polish-20261109/verify.gd
## Read-only: writes nothing.
## Unreachable on purpose (docs/guides/TOWN_DESIGN_BRIEF.md "Interiors polish"): the police entrance
## mat lies under the door threshold, the locker apples sit behind the closed locker door and the
## lineup door belongs to the lineup game (not part of the polish).
const EXPECTED_UNREACHABLE := ["Police Station entrance mat", "Locker apple", "Lineup door leaf"]
const LOCKER_APPLE_COPIES := 2
var passed := 0
var failed := 0

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 4: await physics_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	var before := {}
	for line in FileAccess.get_file_as_string("res://docs/evidence/interiors-polish-20261109/keys-before.txt").split("\n"):
		if ":" in line:
			before[line.get_slice(":", 0).strip_edges()] = Array(line.get_slice(":", 1).strip_edges().split(",", false))
	for unit in ["sports", "furniture", "restaurants", "police"]:
		var keys := {}
		var bad: Array = []
		var allowed_apples := LOCKER_APPLE_COPIES + 1
		for path in PARTS[unit]:
			var top: Node3D = game.apartment.get_node_or_null(path)
			if top == null:
				check("%s: %s present" % [unit, path], false); continue
			for r in [top] + top.find_children("*", "Node3D", true, false):
				if str(r.get_meta("word_key", "")) == "": continue
				var key := key_of(r)
				keys[key] = true
				var shapes := 0
				for s in r.find_children("*", "CollisionShape3D", true, false):
					if not s.disabled and s.get_parent() is CollisionObject3D: shapes += 1
				var ok: bool = game.vocabulary.has(key) and shapes > 0 and r.is_visible_in_tree()
				if ok and not reachable(r):
					var excused := false
					for title in EXPECTED_UNREACHABLE:
						if String(r.name) == title: excused = true
					if not excused and key == "apple" and String(r.get_parent().name) == "Interior" and allowed_apples > 0 \
							and absf(r.global_position.x - top.get_node("Interior/Locker apple").global_position.x) < .2:
						excused = true
					if key == "apple" and excused: allowed_apples -= 1
					ok = excused
				if not ok: bad.append("%s (%s)" % [top.get_path_to(r), key])
		check("%s: every word root learnable, solid, visible and clickable%s" % [unit, "" if bad.is_empty() else ": " + ", ".join(bad)], bad.is_empty())
		var missing: Array = before.get(unit, []).filter(func(k): return not keys.has(k))
		check("%s: every word key from before the polish still present%s" % [unit, "" if missing.is_empty() else ": " + ", ".join(missing)], missing.is_empty())
	print("VERIFY interiors polish: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func check(label: String, ok: bool) -> void:
	if ok: passed += 1
	else: failed += 1
	print("%s %s" % ["PASS" if ok else "FAIL", label])
