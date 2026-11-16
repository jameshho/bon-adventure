extends Node
## Which popups and minigame screens are open, in the order they opened, so Esc acts on the
## TOPMOST one only (user decision, 4 Nov 2026). Main owns it and is the only Esc handler:
## Esc runs the top popup's close action (its ✕ behaviour); with nothing open Main opens
## Settings; in Settings Esc closes Settings.
##
## Register a popup once with watch(control, close): the stack follows the control's
## visibility, so a popup that opens later goes on top. `close` must do exactly what the
## popup's ✕ does (a minigame may ask "are you sure?" instead of closing; that question is
## then the new top). Panels that swallow keys while open must let Esc through.
signal changed

## [{"control": Control, "close": Callable}], oldest first.
var _open: Array = []

func watch(control: Control, close: Callable) -> void:
	control.visibility_changed.connect(_on_visibility.bind(control, close))
	if control.is_visible_in_tree():
		_open.append({"control": control, "close": close})

func _on_visibility(control: Control, close: Callable) -> void:
	_forget(control)
	if control.is_visible_in_tree():
		_open.append({"control": control, "close": close})
	changed.emit()

func _forget(control: Control) -> void:
	for i in range(_open.size() - 1, -1, -1):
		if _open[i].control == control:
			_open.remove_at(i)

func _prune() -> void:
	for i in range(_open.size() - 1, -1, -1):
		var control = _open[i].control
		if not is_instance_valid(control) or not control.is_visible_in_tree():
			_open.remove_at(i)

func top() -> Control:
	_prune()
	return _open[-1].control if not _open.is_empty() else null

func is_open(control: Control) -> bool:
	_prune()
	return _open.any(func(entry): return entry.control == control)

func is_empty() -> bool:
	return top() == null

## Runs the topmost popup's close action. False when nothing is open.
func close_top() -> bool:
	_prune()
	if _open.is_empty():
		return false
	var entry: Dictionary = _open[-1]
	entry.close.call()
	return true
