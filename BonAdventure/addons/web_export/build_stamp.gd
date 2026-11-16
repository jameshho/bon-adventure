@tool
extends EditorExportPlugin
## Every export (15 Nov 2026, user: "last update on 11-15 at 19:25" on the title and loading
## screens): writes the export's local date and time into the pack as res://build_stamp.txt
## ("MM-DD HH:MM"). scripts/core/build_stamp.gd reads it; runs from the project have none.

func _get_name() -> String:
	return "BuildStamp"

func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	var now := Time.get_datetime_dict_from_system()
	var text := "%02d-%02d %02d:%02d" % [now.month, now.day, now.hour, now.minute]
	add_file(preload("res://scripts/core/build_stamp.gd").FILE, text.to_utf8_buffer(), false)
