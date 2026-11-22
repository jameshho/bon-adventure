"""Traces the pig head of the user's coin picture (coin_face_reference.webp, 21 Nov 2026) into
assets/stamps/source/pig_head_traced.svg with vtracer (user: "use v tracer on the pig head").
Run from BonAdventure/ with a Python that has vtracer and pillow:
    python assets/stamps/source/trace_pig.py
Steps: crop the head, clear the gold background (flood fill from the edges over gold pixels),
keep the biggest piece (the head), upscale 2x for smoother curves, flatten to the PALETTE colours, trace in colour mode."""
import collections, sys
from PIL import Image, ImageFilter
import vtracer

SRC = "assets/stamps/source/coin_face_reference.webp"
CROP = (420, 255, 1095, 750)
OUT = "assets/stamps/source/pig_head_traced.svg"
## Output colour <- the picture's colours that become it (sampled; shading folds into the base).
PALETTE = {
    "#fddcd0": ["#fddcd0", "#ffe9d5", "#ffd1c3", "#fde3da", "#ffd6d0", "#fff1e6", "#fecab7", "#fccbb7", "#fdccb8", "#fecdbb", "#e9b29c"],   # face
    "#fbb2ab": ["#fdbdb6", "#fca69f", "#febdb5", "#f4a09a", "#f29790", "#f7aea6"],   # cheeks, ears, snout
    "#b9652a": ["#b9652a", "#c8783a", "#a8551f", "#d08a4c", "#9f4d24", "#a04e25", "#ae572c", "#9a4724", "#d89671"],   # outline, snout ring
    "#873d19": ["#873d19", "#93431c", "#6f3014", "#7a3516"],                          # eyes, nostrils
}
TMP = sys.argv[1] if len(sys.argv) > 1 else "/tmp/pig_head_clean.png"

def gold(p):
    r, g, b, a = p
    return a < 20 or (r > 200 and g > 140 and b < 140 and r - b > 110)

im = Image.open(SRC).convert("RGBA").crop(CROP)
w, h = im.size
px = im.load()
seen = [[False] * h for _ in range(w)]
queue = collections.deque((x, y) for x in range(w) for y in (0, h - 1))
queue.extend((x, y) for y in range(h) for x in (0, w - 1))
while queue:
    x, y = queue.popleft()
    if not (0 <= x < w and 0 <= y < h) or seen[x][y] or not gold(px[x, y]):
        continue
    seen[x][y] = True
    px[x, y] = (0, 0, 0, 0)
    queue.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
# Keep the biggest opaque piece (drops the sparkles and ring bits at the crop's edges).
label = {}
best = []
for sx in range(w):
    for sy in range(h):
        if px[sx, sy][3] == 0 or (sx, sy) in label:
            continue
        piece = []
        queue = collections.deque([(sx, sy)])
        label[(sx, sy)] = True
        while queue:
            x, y = queue.popleft()
            piece.append((x, y))
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= n[0] < w and 0 <= n[1] < h and n not in label and px[n][3] > 0:
                    label[n] = True
                    queue.append(n)
        if len(piece) > len(best):
            best = piece
keep = set(best)
for x in range(w):
    for y in range(h):
        if (x, y) not in keep:
            px[x, y] = (0, 0, 0, 0)
box = im.getbbox()
im = im.crop(box)
im = im.resize((im.width * 2, im.height * 2), Image.LANCZOS)
# Flat colours (the picture's soft shading would trace as hundreds of bands): every pixel takes
# the nearest of PALETTE (sampled from the picture), opaque or clear, then a mode filter smooths
# the borders, so the trace is a handful of clean cartoon shapes.
alpha = im.getchannel("A").point(lambda a: 255 if a > 128 else 0)
rgb = im.convert("RGB")
hexrgb = lambda c: tuple(int(c[i:i + 2], 16) for i in (1, 3, 5))
pairs = [(hexrgb(sample), hexrgb(out)) for out, samples in PALETTE.items() for sample in samples]
lut = {}
data = []
for p in rgb.getdata():
    if p not in lut:
        lut[p] = min(pairs, key=lambda pair: sum((pair[0][i] - p[i]) ** 2 for i in range(3)))[1]
    data.append(lut[p])
rgb.putdata(data)
# The snout ring is darker at the bottom and reads as the eyes' colour: a dark piece wider than
# an eye (EYE_MAX px across), small or not a solid oval is part of the ring and takes the outline colour.
OUTLINE, DARK = hexrgb("#b9652a"), hexrgb("#873d19")
EYE_MAX = 110
rp = rgb.load()
done = set()
for sx in range(rgb.width):
    for sy in range(rgb.height):
        if rp[sx, sy] != DARK or (sx, sy) in done:
            continue
        piece = [(sx, sy)]
        done.add((sx, sy))
        queue = collections.deque(piece)
        while queue:
            x, y = queue.popleft()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= n[0] < rgb.width and 0 <= n[1] < rgb.height and n not in done and rp[n] == DARK:
                    done.add(n)
                    piece.append(n)
                    queue.append(n)
        xs = [p[0] for p in piece]
        ys = [p[1] for p in piece]
        box = (max(xs) - min(xs) + 1) * (max(ys) - min(ys) + 1)
        # Eyes and nostrils are solid ovals (about 3/4 of their box, over 1500 px); ring streaks are
        # thin, ragged or wide.
        if max(xs) - min(xs) > EYE_MAX or len(piece) < 1500 or len(piece) < 0.6 * box:
            for p in piece:
                rp[p] = OUTLINE
rgb = rgb.filter(ImageFilter.ModeFilter(9))
im = rgb.convert("RGBA")
im.putalpha(alpha.filter(ImageFilter.MedianFilter(7)))
im.save(TMP)
vtracer.convert_image_to_svg_py(TMP, OUT, colormode="color", hierarchical="stacked", mode="spline",
		filter_speckle=20, color_precision=8, layer_difference=4, corner_threshold=60,
		length_threshold=4.0, max_iterations=10, splice_threshold=45, path_precision=1)
print("wrote", OUT, im.size)
