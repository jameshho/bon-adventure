"""Builds assets/stamps/coin_face.svg, the town stamp coin's face (user, 21 Nov 2026: the face of
their coin picture, coin_face_reference.webp, with the pig head traced by vtracer; the rest
designed to fit the game). Run from BonAdventure/ after trace_pig.py:
    python3 assets/stamps/source/build_coin_face.py
Layers (512 x 512): a gold disc with a light outer band, a groove and a warm inner face, and the
traced pig head in the centre. Plain SVG with gradients (Godot's importer draws it).
User, 21 Nov 2026 (later): no white accents (the gloss, sparkle marks, sprigs and star of the first
version were removed) and the head centred."""
import re

PIG = "assets/stamps/source/pig_head_traced.svg"
OUT = "assets/stamps/coin_face.svg"
SIZE = 512
C = SIZE / 2

pig = open(PIG).read()
width = float(re.search(r'width="([\d.]+)"', pig).group(1))
height = float(re.search(r'height="([\d.]+)"', pig).group(1))
paths = "\n".join(re.findall(r"<path[^>]*/>", pig))
scale = 300.0 / width
pig_x = C - width * scale / 2
pig_y = C - height * scale / 2

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" viewBox="0 0 {SIZE} {SIZE}">
<defs>
<radialGradient id="band" cx="40%" cy="35%" r="70%"><stop offset="0" stop-color="#ffe680"/><stop offset="0.7" stop-color="#fbcb3c"/><stop offset="1" stop-color="#e9a21c"/></radialGradient>
<radialGradient id="face" cx="42%" cy="38%" r="65%"><stop offset="0" stop-color="#ffd957"/><stop offset="0.75" stop-color="#f8bd2f"/><stop offset="1" stop-color="#eda522"/></radialGradient>
</defs>
<circle cx="{C}" cy="{C}" r="254" fill="#d88c14"/>
<circle cx="{C}" cy="{C}" r="246" fill="url(#band)"/>
<circle cx="{C}" cy="{C}" r="206" fill="#e09a1e"/>
<circle cx="{C}" cy="{C}" r="200" fill="url(#face)"/>
<circle cx="{C}" cy="{C}" r="190" fill="none" stroke="#ffe48a" stroke-width="3" stroke-opacity="0.7"/>
<g transform="translate({pig_x:.1f} {pig_y:.1f}) scale({scale:.4f})">
{paths}
</g>
</svg>
'''
open(OUT, "w").write(svg)
print("wrote", OUT, len(svg), "bytes; pig", round(width * scale), "x", round(height * scale))
