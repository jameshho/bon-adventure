extends RefCounted
## Development focus switch (README "Development focus"): dev_focus.txt, or the environment
## variables VT_FOCUS / VT_SPAWN. Committed form: `all` (every building, normal spawn).

## Building names (unit keys or aliases from data/buildings.json) to load; empty for all.
static func dev_focus() -> Array:
	var text := OS.get_environment("VT_FOCUS")
	if text.strip_edges() == "" and FileAccess.file_exists("res://dev_focus.txt"):
		text = FileAccess.get_file_as_string("res://dev_focus.txt")
	var names: Array = []
	for line in text.split("\n"):
		line = line.split("#")[0]
		for word in line.replace(",", " ").split(" ", false):
			var name := word.strip_edges().to_lower()
			if name.contains("="):
				continue
			if name != "" and name != "all" and not names.has(name):
				names.append(name)
	return names

## Development spawn, `spawn=<building>` (any building name, plus `restaurant`/`burger`/`pizza`/`taqueria`) anywhere in dev_focus.txt, or the
## environment variable VT_SPAWN: the player starts and respawns outside that door instead of
## the supermarket. Places are in Main.ENTRANCES (shared with the saved-place respawn). Empty when unset (the committed default).
static func dev_spawn() -> String:
	var env := OS.get_environment("VT_SPAWN").strip_edges().to_lower()
	if env != "":
		return env
	if not FileAccess.file_exists("res://dev_focus.txt"):
		return ""
	for line in FileAccess.get_file_as_string("res://dev_focus.txt").split("\n"):
		line = line.split("#")[0]
		for word in line.replace(",", " ").split(" ", false):
			var token := word.strip_edges().to_lower()
			if token.begins_with("spawn="):
				return token.substr(6)
	return ""
