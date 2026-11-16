extends Node
## Hard exit for windowed `--script` runs (captures, render checks) on macOS.
##
## Since 6 Nov 2026 a windowed Godot 4.7.2 run of the town aborts while quitting
## (`recursive_mutex::lock` throws during `-[NSApplication terminate:]`, after the
## script's work is done), leaving a "Godot quit unexpectedly" dialog and a crash
## report each time. This autoload leaves the tree last (autoloads exit after the
## main scene) and kills the process there, before the engine's macOS shutdown.
##
## Only for `--script` runs with a window: the game itself and `--headless` runs
## (tools/run_checks.py) exit normally and keep their exit codes. A killed run
## exits with 137 (SIGKILL) instead of its quit() code; read its log labels.
## Output printed before quit() is kept. A SceneTree script's `_finalize()` does
## NOT run (none in the project use it as of 13 Nov 2026).

var _active := false


func _ready() -> void:
	_active = OS.get_cmdline_args().has("--script") \
		and DisplayServer.get_name() != "headless" \
		and OS.get_environment("VT_SOFT_EXIT") != "1"
	if not _active:
		set_process(false)


func _exit_tree() -> void:
	if _active:
		OS.kill(OS.get_process_id())
