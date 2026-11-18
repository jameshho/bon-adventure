"""Nearby loading proposal (17 Nov 2026): from measure_units.gd's results, which building units a
player at a given spot would hold for each loading radius, and their GPU buffer cost.
Cost of a unit = its buffer_mb delta when added (meshes, batches, plush sculpts) plus the
textures that came back when it was freed (restaurants: 7.4 MB of poster viewports). The texture
deltas of the staged run are not used: they are almost all font glyph atlases (README).
A unit counts as near when any of its parts' XZ boxes is within the radius of the spot.
Spots: every Main.ENTRANCES standing point, and a 5 m grid over the units' area (x -230..220,
z 0..350), which includes sea and park, so it is only a spread.
python3 -I radius_table.py   (run in this folder)"""
import json, math, os
here = os.path.dirname(os.path.abspath(__file__))
d = json.load(open(os.path.join(here, "results.json")))
d["units"].update(json.load(open(os.path.join(here, "results_barn.json")))["units"])
cost, boxes = {}, {}
for k, u in d["units"].items():
    cost[k] = u["delta"]["buffer_mb"] - d["freed"].get(k, {}).get("texture_mb", 0.0)
    boxes[k] = [p["box"] for p in u["parts"] if p["box"] != [0, 0, 0, 0]]
def dist(p, b):
    dx = max(b[0] - p[0], 0, p[0] - b[2]); dz = max(b[1] - p[1], 0, p[1] - b[3])
    return math.hypot(dx, dz)
def near(p, r):
    return [k for k in boxes if any(dist(p, b) <= r for b in boxes[k])]
total = sum(cost.values())
print("units' own cost, all loaded: %.1f MB (buffers + freed textures)" % total)
print("per unit:", ", ".join("%s %.1f" % (k, v) for k, v in sorted(cost.items(), key=lambda x: -x[1])))
grid = [(x, z) for x in range(-230, 221, 5) for z in range(0, 351, 5)]
for r in (60, 90, 130, 160, 200):
    g = [sum(cost[k] for k in near(p, r)) for p in grid]
    gn = [len(near(p, r)) for p in grid]
    g.sort()
    print("\nradius %d m: grid mean %.0f MB (%.1f units), median %.0f, 90th pct %.0f, max %.0f" % (
        r, sum(g) / len(g), sum(gn) / len(gn), g[len(g) // 2], g[int(len(g) * 0.9)], g[-1]))
    for name, p in sorted(d["entrances"].items()):
        ks = near(p, r)
        print("  %-11s %5.1f MB %2d units  %s" % (name, sum(cost[k] for k in ks), len(ks), " ".join(sorted(ks))))
