extends SceneTree
## Makes the web app's icons from assets/branding/source/app_icon_source.webp, the user's own icon
## picture (16 Nov 2026: the pig's head on mint, 988 square, used as it is). It replaced the
## vector pig of tools/app_icon.svg (13 Nov 2026) and a head cut out of the logo (16 Nov), both in
## git history. Each size is scaled down from the picture (Lanczos, no upscaling).
## Writes assets/ui/app/icon_<size>.png (512, 192, 180, 144); export_presets.cfg
## (progressive_web_app icons) and project.godot (config/icon: the page's favicon and
## apple-touch-icon in a web export) point at them. Works headless:
## godot --headless --path . --script res://tools/make_app_icons.gd
## Optional: -- <folder> writes extra preview sizes (512, 180, 120, 76, 60, 40, 29) there.
## The picture sits in a .gdignore folder (not imported), so it is read from disk.
const SOURCE := "res://assets/branding/source/app_icon_source.webp"
const APP := "res://assets/ui/app/"
const SIZES := [512, 192, 180, 144]
const PREVIEW := [512, 180, 120, 76, 60, 40, 29]

func _initialize() -> void:
	var master := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if master == null or master.is_empty():
		print("make_app_icons: cannot read ", SOURCE)
		quit(1)
		return
	master.convert(Image.FORMAT_RGB8)
	var args := OS.get_cmdline_user_args()
	for side in SIZES:
		_render(master, side).save_png(ProjectSettings.globalize_path(APP + "icon_%d.png" % side))
		print("icon ", side)
	if not args.is_empty():
		for side in PREVIEW:
			_render(master, side).save_png(args[0].path_join("preview_%d.png" % side))
	quit(0)

## The master scaled to side x side pixels.
func _render(master: Image, side: int) -> Image:
	var image := master.duplicate() as Image
	if image.get_width() != side:
		image.resize(side, side, Image.INTERPOLATE_LANCZOS)
	return image
