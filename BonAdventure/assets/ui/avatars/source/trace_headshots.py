"""Traces the 8 picker headshots of the user's character-grid mockup (character_grid_reference.webp,
22 Nov 2026) with vtracer (user: "use vtracer and redraw the character selection screen to match
this, only change the character headshots") into source/<id>.svg and the portraits
assets/ui/avatars/<id>.webp (320 x 236, transparent) that app_screens.gd shows. Sunny is not in the
picker and keeps its plush portrait; tools/capture_app_art.gd skips ids that have an SVG here.
Run from BonAdventure/ with a Python that has vtracer, pillow and resvg-py (the vtracer wheel
segfaults on keyword arguments under Python 3.15; 3.9 works):
    python assets/ui/avatars/source/trace_headshots.py
Steps per tile: crop the head above the name pill, flood-fill the tile background from the top and
side edges (soft gradient: compare with the neighbour and the edge colour), grow it 2 px to drop the
blended fringe, paint it magenta, trace in colour/cutout mode, delete the magenta paths, render."""
import collections, os, re, tempfile
from PIL import Image, ImageDraw
import resvg_py, vtracer

DIR = "assets/ui/avatars/source/"
OUT = "assets/ui/avatars/"
SIZE = (320, 236)                  # output portrait (the art area is 272 x 202)
TOL = 30
COLS = [75, 397, 720, 1043]          # tile art left edge in the mockup (1374 x 1184)
ROWS = [332, 675]                    # art top; the art is 272 x 202 down to the name pill
IDS = [["bonbon", "leo", "bruno", "miso"], ["awoo", "poppy", "twinkle", "cocodrilo"]]
KEY = (255, 0, 255)

def dist(a, b):
    return sum((a[k] - b[k]) ** 2 for k in range(3)) ** 0.5

def keyed(im, x, y):
    cr = im.crop((x, y, x + 272, y + 202)).convert("RGB")
    w, h = cr.size
    px = cr.load()
    bg = [[False] * h for _ in range(w)]
    q = collections.deque([(i, 0) for i in range(w)] + [(e, j) for j in range(h) for e in (0, w - 1)])
    for i, j in q:
        bg[i][j] = True
    while q:
        i, j = q.popleft()
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            a, b = i + di, j + dj
            if 0 <= a < w and 0 <= b < h and not bg[a][b] and dist(px[a, b], px[i, j]) < TOL / 6 and dist(px[a, b], px[0, j]) < TOL:
                bg[a][b] = True
                q.append((a, b))
    for _ in range(2):
        grow = [(i, j) for i in range(w) for j in range(h) if not bg[i][j] and any(
            0 <= i + a < w and 0 <= j + b < h and bg[i + a][j + b] for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
        for i, j in grow:
            bg[i][j] = True
    for i in range(w):
        for j in range(h):
            if bg[i][j]:
                px[i, j] = KEY
    # A 1 px key border so every outline closes (the picture keeps the mockup's art area shape,
    # so the tile's picture box shows it as large as the mockup does).
    framed = Image.new("RGB", (w, h + 1), KEY)
    framed.paste(cr, (0, 1))
    return framed

def not_key(match):
    col = re.search(r'fill="#([0-9A-Fa-f]{6})"', match.group(0))
    if not col:
        return match.group(0)
    r, g, b = (int(col.group(1)[k:k + 2], 16) for k in (0, 2, 4))
    return "" if r > 200 and g < 90 and b > 200 else match.group(0)

def main():
    im = Image.open(DIR + "character_grid_reference.webp").convert("RGB")
    # The check badge overlaps BonBon's tile: paint it over with the tile green first.
    ImageDraw.Draw(im).ellipse((293, 291, 377, 375), fill=im.getpixel((120, 345)))
    tmp = tempfile.mkdtemp()
    for r, y in enumerate(ROWS):
        for c, x in enumerate(COLS):
            name = IDS[r][c]
            src = os.path.join(tmp, name + ".png")
            keyed(im, x, y).save(src)
            svg_path = DIR + name + ".svg"
            vtracer.convert_image_to_svg_py(src, svg_path, colormode="color", hierarchical="cutout",
                mode="spline", filter_speckle=4, color_precision=8, layer_difference=6,
                corner_threshold=60, length_threshold=4.0, splice_threshold=45, path_precision=3)
            svg = re.sub(r"<path[^>]*/>", not_key, open(svg_path).read())
            open(svg_path, "w").write(svg)
            png = os.path.join(tmp, name + "_out.png")
            open(png, "wb").write(bytes(resvg_py.svg_to_bytes(svg_string=svg, width=SIZE[0], height=SIZE[1])))
            Image.open(png).convert("RGBA").save(OUT + name + ".webp", "WEBP", quality=90, method=6)
            print("traced", name)

main()
