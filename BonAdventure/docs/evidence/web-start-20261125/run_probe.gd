extends SceneTree
## Native runner for probe.gd (see its header).
func _initialize() -> void:
	root.add_child.call_deferred(load("res://docs/evidence/web-start-20261125/probe.gd").new())
