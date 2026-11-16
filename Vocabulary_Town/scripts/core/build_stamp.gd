extends RefCounted
## When this build was made (15 Nov 2026, user): the title and loading screens show
## "Last update on 11-15 at 19:25" (data/phrases.json "app.last_update"). The export writes FILE
## (addons/web_export/build_stamp.gd, every export, in the exporting Mac's local time); a run
## from the project has no such file and shows nothing.
const FILE := "res://build_stamp.txt"
const Lexicon := preload("res://scripts/language/lexicon.gd")

## "Last update on 11-15 at 19:25" in `lang`, or "" when this run is not an exported build.
static func line(lang: String) -> String:
	if not FileAccess.file_exists(FILE):
		return ""
	var parts := FileAccess.get_file_as_string(FILE).strip_edges().split(" ")
	if parts.size() != 2:
		return ""
	return Lexicon.shared().phrase("app.last_update", lang, {"date": parts[0], "time": parts[1]})
