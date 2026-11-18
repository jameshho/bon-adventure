extends SceneTree
## Clears the brown pockets between the logo's animals (user, 18 Nov 2026: "a few spots that are
## not transparent" on the title screen): the source art fills the gaps between the lion and the
## cat, the pig and the beagle, and the beagle and the bear with a mid brown (about 148, 95, 50),
## which clean_logo.py keeps because the outline encloses them. This pass makes every large
## connected patch of that brown transparent and turns its anti-aliased edge into the outline
## colour with partial alpha, so the dark outline stays crisp.
##   godot --headless --path . --script res://assets/branding/source/clear_logo_pockets.gd [-- --dry]
## Reads and rewrites res://assets/branding/bon_adventure_logo.webp (lossless WebP). Run once.
const LOGO := "res://assets/branding/bon_adventure_logo.webp"
const POCKET := Color8(148, 95, 50)
const OUTLINE := Color8(90, 20, 3)
## Colour distance (0..1 per channel, RGB) still counted as pocket brown.
const NEAR := 0.16
## Patches smaller than this many pixels, or thinner than MIN_SIDE pixels either way (the
## anti-aliased edges along outlines are one pixel thin), are left alone.
const MIN_AREA := 40
const MIN_SIDE := 6

func _init() -> void:
	var dry := OS.get_cmdline_user_args().has("--dry")
	var im: Image = load(LOGO).get_image()
	im.decompress()
	im.convert(Image.FORMAT_RGBA8)
	var w := im.get_width()
	var h := im.get_height()
	var near := PackedByteArray()
	near.resize(w * h)
	for y in h:
		for x in w:
			var c := im.get_pixel(x, y)
			near[y * w + x] = 1 if c.a > 0.5 and _dist(c, POCKET) < NEAR else 0
	var seen := PackedByteArray()
	seen.resize(w * h)
	var cleared := 0
	for start in w * h:
		if near[start] == 0 or seen[start] == 1:
			continue
		var patch := PackedInt32Array([start])
		seen[start] = 1
		var i := 0
		while i < patch.size():
			var p := patch[i]
			i += 1
			var px := p % w
			var py := p / w
			for q in [p - 1 if px > 0 else -1, p + 1 if px < w - 1 else -1, p - w if py > 0 else -1, p + w if py < h - 1 else -1]:
				if q >= 0 and near[q] == 1 and seen[q] == 0:
					seen[q] = 1
					patch.append(q)
		if patch.size() < MIN_AREA:
			continue
		var lo := Vector2i(w, h)
		var hi := Vector2i.ZERO
		for p in patch:
			lo = Vector2i(mini(lo.x, p % w), mini(lo.y, p / w))
			hi = Vector2i(maxi(hi.x, p % w), maxi(hi.y, p / w))
		if mini(hi.x - lo.x, hi.y - lo.y) + 1 < MIN_SIDE:
			continue
		print("pocket area %d box %s..%s" % [patch.size(), lo, hi])
		cleared += 1
		if dry:
			continue
		for p in patch:
			im.set_pixel(p % w, p / w, Color(OUTLINE, 0.0))
		# The edge: pixels next to the patch that mix pocket brown and the outline become the
		# outline colour, as opaque as they are outline-like.
		for p in patch:
			for q in [p - 1, p + 1, p - w, p + w, p - w - 1, p - w + 1, p + w - 1, p + w + 1]:
				if q < 0 or q >= w * h or near[q] == 1:
					continue
				var c := im.get_pixel(q % w, q / w)
				if c.a < 1.0:
					continue
				var a := clampf(_dist(c, POCKET) / maxf(_dist(OUTLINE, POCKET), 0.001), 0.0, 1.0)
				if a < 0.95 and _dist(c, OUTLINE) < _dist(OUTLINE, POCKET):
					im.set_pixel(q % w, q / w, Color(OUTLINE, a))
	print("pockets cleared: %d%s" % [cleared, " (dry run)" if dry else ""])
	if not dry and cleared > 0:
		im.save_webp(ProjectSettings.globalize_path(LOGO), false)
	quit()

func _dist(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()
