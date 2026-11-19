extends "res://scripts/characters/plush_costume.gd"
## EXPERIMENT (18 Nov 2026): plush_costume.gd with the arm anchors taken from the shared rig's
## measurement (rig.gd) instead of the typed shoulder / hand of data/plush_costumes.json.
## Everything else (collar, hide, tuck, press, hat_sink) still comes from the data.

var anchors := {}


func _anchor(key: String, side: float) -> Vector3:
	if anchors.has(key):
		var v: Array = anchors[key]
		return Vector3(side * float(v[0]), float(v[1]), float(v[2]))
	return super._anchor(key, side)
