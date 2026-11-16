@tool
extends EditorPlugin
## Registers compress_scenes.gd (web exports) and build_stamp.gd (every export) with the
## exporter (README "Web app (PWA)").
var _export: EditorExportPlugin
var _stamp: EditorExportPlugin

func _enter_tree() -> void:
	_export = preload("res://addons/web_export/compress_scenes.gd").new()
	add_export_plugin(_export)
	_stamp = preload("res://addons/web_export/build_stamp.gd").new()
	add_export_plugin(_stamp)

func _exit_tree() -> void:
	remove_export_plugin(_export)
	remove_export_plugin(_stamp)
