"""Cuts the 8 picker headshots out of the user's character-grid mockup (character_grid_reference.webp,
22 Nov 2026) into the portraits assets/ui/avatars/<id>.webp (544 x 404, transparent) that
app_screens.gd shows. Since 23 Nov 2026 (user: the vtracer traces of 22 Nov looked pixelated and
broke BonBon's nose) the mockup's own pixels are used, not a trace. Sunny is not in the picker and
keeps its plush portrait; tools/capture_app_art.gd skips the ids in IDS (its MOCKUP_IDS).
Run from BonAdventure/ with a Python that has pillow:
    python assets/ui/avatars/source/cut_headshots.py
Steps per tile: crop the head above the name pill (the art area, 272 x 202), flood-fill the tile
background from the top and side edges (soft gradient: compare with the neighbour and the edge
colour), shrink the head mask 1 px to drop the blended fringe, scale the crop UP times with
Lanczos and use the scaled, slightly blurred mask as a soft alpha edge."""
import collections
from PIL import Image, ImageDraw, ImageFilter

DIR = "assets/ui/avatars/source/"
OUT = "assets/ui/avatars/"
UP = 2                               # output scale: 544 x 404, sharp on large windows
TOL = 30
COLS = [75, 397, 720, 1043]          # tile art left edge in the mockup (1374 x 1184)
ROWS = [332, 675]                    # art top; the art is 272 x 202 down to the name pill
IDS = [["bonbon", "leo", "bruno", "miso"], ["awoo", "poppy", "twinkle", "cocodrilo"]]

def dist(a, b):
    return sum((a[k] - b[k]) ** 2 for k in range(3)) ** 0.5

def head_mask(cr):
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
    mask = Image.new("L", (w, h), 0)
    mp = mask.load()
    for i in range(w):
        for j in range(h):
            mp[i, j] = 0 if bg[i][j] else 255
    return mask.filter(ImageFilter.MinFilter(3))

def main():
    im = Image.open(DIR + "character_grid_reference.webp").convert("RGB")
    # The check badge overlaps BonBon's tile: paint it over with the tile green first.
    ImageDraw.Draw(im).ellipse((293, 291, 377, 375), fill=im.getpixel((120, 345)))
    for r, y in enumerate(ROWS):
        for c, x in enumerate(COLS):
            name = IDS[r][c]
            cr = im.crop((x, y, x + 272, y + 202))
            size = (cr.width * UP, cr.height * UP)
            out = cr.resize(size, Image.LANCZOS).convert("RGBA")
            out.putalpha(head_mask(cr).resize(size, Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.2)))
            out.save(OUT + name + ".webp", "WEBP", quality=92, method=6)
            print("cut", name)

main()
