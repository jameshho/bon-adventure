extends Node3D
## The chapel's bell (user, 21 Nov 2026: "make the bell ringable, I will add the audio later";
## built by scripts/buildings/chapel.gd grand_chapel in the bell tower; record:
## docs/guides/TOWN_DESIGN_BRIEF.md chapel row). This node is the pivot under the headstock;
## the bell, its clapper (child "Bell clapper") and rope hang from it.
##
## E, a click or a tap (its interactable, badge on the rope's grip) rings it: it swings to and fro
## about its local X (north-south), dying away, the clapper lagging behind. A ring while it
## swings starts a fresh swing. Silent itself: `rung` plays bell.chapel (data/sounds.json
## "bindings", 25 Nov 2026: a ding-dong heard across the chapel square; a new ring restarts it).
## Reports "ring_bell" to the achievement log.
const Interactable := preload("res://scripts/core/interactable.gd")
const Achievements := preload("res://scripts/learning/achievements.gd")
## Emitted on every ring (the bell.chapel sound).
signal rung

## Swing amplitudes (radians), each reached in SWING_TIME seconds; the last returns to rest.
const SWING := [0.55, -0.45, 0.34, -0.22, 0.12, -0.05, 0.0]
const SWING_TIME := 0.34

## Where the E badge sits (this node's units): the rope's grip, set by the builder.
@export var badge_offset := Vector3(0, -1.0, 0)

var _tween: Tween

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	Interactable.attach(self, {
		"kind": Interactable.Kind.USE,
		"prompt_distance": 2.4,
		"badge_offset": badge_offset,
	})

func use() -> void:
	ring()

func ring() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	rung.emit()
	Achievements.shared().note("ring_bell")
	var clapper := get_node_or_null("Bell clapper") as Node3D
	_tween = create_tween()
	for k in SWING.size():
		var angle: float = SWING[k]
		_tween.tween_property(self, "rotation:x", angle, SWING_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if clapper != null:
			# The clapper lags: it leans the other way, then strikes as the bell turns.
			_tween.parallel().tween_property(clapper, "rotation:x", -angle * 0.6, SWING_TIME * 0.8).set_delay(SWING_TIME * 0.2)
