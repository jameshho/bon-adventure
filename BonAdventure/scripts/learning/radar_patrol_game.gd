extends RefCounted
## Radar Patrol rules (pastime, 9 Nov 2026; docs/guides/RADAR_PATROL.md). Drawn and played by
## scripts/ui/radar_patrol_panel.gd; this script knows nothing about the screen.
##
## The radar is a unit circle (radius 1, +y down like the screen). Friendly planes and alien
## UFOs enter from a random edge point and fly in a straight line across. A tap on a UFO
## destroys it (points, combo +1); a tap on a plane or on empty sky breaks the combo, and a
## tap on a plane also costs points. A UFO that leaves the radar escapes: the combo breaks but
## the game goes on. A UFO touching a plane ends the game at once. Endless: speed and spawn
## rate rise with time, with no waves or levels.

## Hit circles, grown with the sprites: 20% (user, 9 Nov 2026; were 0.055 and 0.05), then 40%
## more (user, 15 Nov 2026; were 0.066 and 0.06).
const UFO_RADIUS := 0.092
const PLANE_RADIUS := 0.084
## A tap also hits a UFO where it was this many seconds ago (reaction and touch lag).
const TAP_LAG := 0.18
## Centre distance at which a UFO and a plane collide (a little forgiving).
const CRASH_DISTANCE := 0.085
const EDGE := 1.1
const POINTS := 100
const COMBO_BONUS := 50
const MAX_COMBO_BONUS := 9
const FRIENDLY_PENALTY := 200
## A UFO is a threat (amber brackets) when its closest approach to a plane within this many
## seconds is under THREAT_DISTANCE.
const THREAT_SECONDS := 1.6
const THREAT_DISTANCE := 0.13
## Planes never cross paths (user, 9 Nov 2026): a new plane's straight path, edge to edge, keeps
## at least this far from what is left of every other plane's path.
const PLANE_PATH_CLEARANCE := 0.14
## No instant game over at a spawn (user, 9 Nov 2026): a plane does not appear while a UFO is
## within this distance of the start of its path (its entry and first 0.35 radii on the radar),
## counting where the UFO will move meanwhile; a UFO likewise keeps clear of planes as it enters.
const PLANE_SPAWN_SAFE := 0.4
const PLANE_SAFE_REACH := 0.35
## ... and for at least this long after entering (at top speed 0.35 radii take under a second).
const SAFE_SECONDS := 1.2
## Tries for a spawn that keeps both rules; when none does, wait this long and try again.
const SPAWN_TRIES := 16
const SPAWN_RETRY := 0.3

var rng := RandomNumberGenerator.new()
var time := 0.0
var score := 0
var combo := 0
var best_combo := 0
var kills := 0
var escaped := 0
var over := false
var crash_point := Vector2.ZERO
## {kind: "ufo"/"plane", pos, vel, entered, id, flash}
var entities: Array = []
## Short-lived events for the panel to animate: {kind: "pop"/"miss"/"friendly"/"escape"/"crash", pos, text}
var events: Array = []
var _next_ufo := 0.6
var _next_plane := 0.0
var _ids := 0

func reset(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	time = 0.0
	score = 0
	combo = 0
	best_combo = 0
	kills = 0
	escaped = 0
	over = false
	entities.clear()
	events.clear()
	_next_ufo = 0.8
	_next_plane = 0.0
	_ids = 0

## Speed multiplier: 1 at the start, rising to 2.6 after about two and a half minutes.
func pace() -> float:
	return 1.0 + minf(time / 95.0, 1.6)

func ufo_interval() -> float:
	return maxf(0.45, 1.7 * exp(-time / 100.0))

func plane_interval() -> float:
	return maxf(1.3, 3.4 * exp(-time / 140.0))

func step(delta: float) -> void:
	if over:
		return
	time += delta
	_next_ufo -= delta
	_next_plane -= delta
	if _next_plane <= 0.0:
		_next_plane = plane_interval() * rng.randf_range(0.8, 1.2)
		if count("plane") < 6 and not _spawn("plane"):
			_next_plane = SPAWN_RETRY
	if _next_ufo <= 0.0:
		_next_ufo = ufo_interval() * rng.randf_range(0.75, 1.25)
		if count("ufo") < 10:
			_spawn("ufo")
	for entity in entities:
		entity["pos"] += entity["vel"] * delta
		entity["flash"] = maxf(0.0, entity["flash"] - delta)
		if not entity["entered"] and entity["pos"].length() < 0.96:
			entity["entered"] = true
	var kept: Array = []
	for entity in entities:
		if entity["entered"] and entity["pos"].length() > EDGE + 0.02:
			if entity["kind"] == "ufo":
				escaped += 1
				combo = 0
				events.append({"kind": "escape", "pos": entity["pos"].normalized() * 0.97, "text": "ESCAPED"})
			continue
		kept.append(entity)
	entities = kept
	for ufo in entities:
		# Only on the radar: nothing collides out of sight.
		if ufo["kind"] != "ufo" or ufo["pos"].length() > 1.0:
			continue
		for plane in entities:
			if plane["kind"] == "plane" and plane["pos"].length() <= 1.0 and ufo["pos"].distance_to(plane["pos"]) < CRASH_DISTANCE:
				over = true
				crash_point = (ufo["pos"] + plane["pos"]) * 0.5
				events.append({"kind": "crash", "pos": crash_point, "text": "COLLISION"})
				return

func count(kind: String) -> int:
	var n := 0
	for entity in entities:
		if entity["kind"] == kind:
			n += 1
	return n

## Points for the next hit at the current combo.
func points_for(combo_count: int) -> int:
	return POINTS + COMBO_BONUS * mini(maxi(combo_count - 1, 0), MAX_COMBO_BONUS)

## A tap at radar point `at`; `slop` widens the hit circle (a finger). Returns "ufo",
## "plane" or "miss".
## Forgiving touch (user, 15 Nov 2026: "still hard to tap while the logo is already big
## enough"): any UFO within its reach wins over a plane, the reach also covers where the UFO
## was TAP_LAG seconds ago (the finger lands on what the eye saw), and a plane only takes a
## tap with half the slop, so friendly fire stays a clear miss-aim.
func tap(at: Vector2, slop: float = 0.03) -> String:
	if over:
		return ""
	var target: Dictionary = {}
	var nearest := INF
	for entity in entities:
		if entity["kind"] != "ufo":
			continue
		var trail: Vector2 = entity["pos"] - entity["vel"] * TAP_LAG
		var distance := segment_point_distance(trail, entity["pos"], at)
		if distance < UFO_RADIUS + slop and distance < nearest:
			nearest = distance
			target = entity
	if target.is_empty():
		for entity in entities:
			if entity["kind"] != "plane":
				continue
			var distance: float = entity["pos"].distance_to(at)
			if distance < PLANE_RADIUS + slop * 0.5 and distance < nearest:
				nearest = distance
				target = entity
	if target.is_empty():
		combo = 0
		events.append({"kind": "miss", "pos": at, "text": ""})
		return "miss"
	if target["kind"] == "plane":
		combo = 0
		score = maxi(0, score - FRIENDLY_PENALTY)
		target["flash"] = 0.6
		events.append({"kind": "friendly", "pos": target["pos"], "text": "-%d" % FRIENDLY_PENALTY})
		return "plane"
	combo += 1
	best_combo = maxi(best_combo, combo)
	kills += 1
	var gained := points_for(combo)
	score += gained
	entities.erase(target)
	events.append({"kind": "pop", "pos": target["pos"], "text": "+%d" % gained + (" x%d" % combo if combo > 1 else "")})
	return "ufo"

## Whether `ufo` will pass close to a plane soon (the panel marks it).
func threat(ufo: Dictionary) -> bool:
	for plane in entities:
		if plane["kind"] != "plane":
			continue
		var rel_pos: Vector2 = ufo["pos"] - plane["pos"]
		var rel_vel: Vector2 = ufo["vel"] - plane["vel"]
		var speed2 := rel_vel.length_squared()
		var when := 0.0 if speed2 < 0.000001 else clampf(-rel_pos.dot(rel_vel) / speed2, 0.0, THREAT_SECONDS)
		if (rel_pos + rel_vel * when).length() < THREAT_DISTANCE:
			return true
	return false

## Adds a plane or UFO entering from a random edge point. Neither appears where it could hit
## the other kind during its entry (spawn_safe()), and a plane's path crosses no other plane's
## path; returns false when no such spot was found (the caller tries again shortly).
func _spawn(kind: String) -> bool:
	for attempt in SPAWN_TRIES:
		var angle := rng.randf() * TAU
		var start := Vector2.from_angle(angle) * EDGE
		# Planes may fly off-centre routes too, so they can keep clear of each other.
		var aim := Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * (0.8 if kind == "plane" else 0.55)
		# Later on, some UFOs head for a plane's path, so collisions become a real danger.
		if kind == "ufo" and rng.randf() < minf(0.55, 0.15 + time / 150.0):
			var planes := entities.filter(func(e): return e["kind"] == "plane" and e["entered"])
			if not planes.is_empty():
				var plane: Dictionary = planes[rng.randi() % planes.size()]
				aim = plane["pos"] + plane["vel"] * rng.randf_range(2.0, 4.0)
				if aim.length() > 0.8:
					aim = aim.normalized() * 0.8
		var base := 0.17 if kind == "plane" else 0.21
		var velocity := (aim - start).normalized() * base * pace() * rng.randf_range(0.85, 1.15)
		if not spawn_safe(kind, start, velocity):
			continue
		_ids += 1
		entities.append({"kind": kind, "pos": start, "vel": velocity, "entered": false, "id": _ids, "flash": 0.0})
		return true
	return false

## Whether a `kind` may start at `start` with `velocity`:
## - its entry (from the edge to PLANE_SAFE_REACH inside the radar) keeps PLANE_SPAWN_SAFE from
##   where every craft of the other kind will be meanwhile (their tracks over that time), so a
##   spawn never causes an instant game over;
## - a plane's path, edge to edge, keeps PLANE_PATH_CLEARANCE from every other plane's remaining
##   path (planes never cross paths).
func spawn_safe(kind: String, start: Vector2, velocity: Vector2) -> bool:
	var direction := velocity.normalized()
	var speed := velocity.length()
	var entry_seconds := maxf(0.0, entry_distance(start, direction)) / speed + maxf(PLANE_SAFE_REACH / speed, SAFE_SECONDS)
	var entry_end := start + velocity * entry_seconds
	var path_end := exit_point(start, direction)
	for other in entities:
		if other["kind"] != kind:
			var track_end: Vector2 = other["pos"] + other["vel"] * entry_seconds
			if segment_distance(start, entry_end, other["pos"], track_end) < PLANE_SPAWN_SAFE:
				return false
		elif kind == "plane":
			var other_dir: Vector2 = other["vel"].normalized()
			if segment_distance(start, path_end, other["pos"], exit_point(other["pos"], other_dir)) < PLANE_PATH_CLEARANCE:
				return false
	return true

## Where a straight line from `from` along unit `direction` leaves the spawn circle.
static func exit_point(from: Vector2, direction: Vector2) -> Vector2:
	var b := from.dot(direction)
	var c := from.length_squared() - EDGE * EDGE
	return from + direction * (-b + sqrt(maxf(b * b - c, 0.0)))

## How far along `direction` from `from` the line enters the radar (radius 1).
static func entry_distance(from: Vector2, direction: Vector2) -> float:
	var b := from.dot(direction)
	var c := from.length_squared() - 1.0
	return -b - sqrt(maxf(b * b - c, 0.0))

static func segment_point_distance(a: Vector2, b: Vector2, p: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))

static func segment_distance(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> float:
	if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
		return 0.0
	return minf(minf(segment_point_distance(c, d, a), segment_point_distance(c, d, b)),
		minf(segment_point_distance(a, b, c), segment_point_distance(a, b, d)))
