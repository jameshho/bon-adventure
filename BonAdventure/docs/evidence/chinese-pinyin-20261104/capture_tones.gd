extends SceneTree
## Font fix (4 Nov 2026): every pinyin tone letter, ǖ ǘ ǚ ǜ included, in a PinyinText label
## (Noto Sans SemiBold) above the same rows in the built-in font, at the sizes the panels use.
## No town is loaded and nothing is saved. Graphics required:
## godot --path . --resolution 1400x760 --script res://docs/evidence/chinese-pinyin-20261104/capture_tones.gd
const PinyinText := preload("res://scripts/ui/pinyin_text.gd")
const ROWS := [
	"a  ā á ǎ à    e  ē é ě è    i  ī í ǐ ì",
	"o  ō ó ǒ ò    u  ū ú ǔ ù    ü  ǖ ǘ ǚ ǜ",
	"Ā Á Ǎ À   Ē É Ě È   Ō Ó Ǒ Ò",
	"nǚ lǚ lǜ zōnglǘ   nǐ hǎo   wǒ   shuǐ   Xièxie nǐ!",
]

func _initialize(): run.call_deferred()

func add(box: VBoxContainer, text: String, size: int, pinyin: bool) -> void:
	var label := Label.new()
	if pinyin:
		PinyinText.style(label)
		label.visible = true
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("f2d9a0") if pinyin else Color("bed9e4"))
	box.add_child(label)

func run():
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	var back := ColorRect.new()
	back.color = Color("13283a")
	back.size = Vector2(1400, 760)
	root.add_child(back)
	var box := VBoxContainer.new()
	box.position = Vector2(30, 20)
	root.add_child(box)
	for pinyin in [true, false]:
		var title := Label.new()
		title.text = "PinyinText (Noto Sans SemiBold)" if pinyin else "Built-in font (Open Sans SemiBold), before the fix"
		box.add_child(title)
		for row in ROWS:
			add(box, row, 34 if row == ROWS[0] or row == ROWS[1] else 24, pinyin)
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/chinese-pinyin-20261104/tones.png")
	print("PINYIN TONES CAPTURE done")
	quit()
