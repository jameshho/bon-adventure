import re, sys
src, out, min_area = sys.argv[1], sys.argv[2], float(sys.argv[3])
s = open(src).read()
w, h = re.search(r'width="(\d+)" height="(\d+)"', s).groups()
paths = re.findall(r'<path d="([^"]+)" fill="([^"]+)" transform="translate\(([-\d.]+),([-\d.]+)\)"/>', s)
kept, dropped = [], 0
def r(m): 
    v = round(float(m.group()), 1)
    return ("%g" % v)
for d, fill, tx, ty in paths:
    nums = [float(x) for x in re.findall(r'-?\d+(?:\.\d+)?', d)]
    xs, ys = nums[0::2], nums[1::2]
    area = (max(xs) - min(xs)) * (max(ys) - min(ys))
    if area < min_area:
        dropped += 1; continue
    d2 = re.sub(r'-?\d+\.\d+', r, d)
    kept.append(f'<path d="{d2}" fill="{fill}" transform="translate({tx},{ty})"/>')
open(out, "w").write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n' + "\n".join(kept) + "\n</svg>\n")
print(src, "paths", len(paths), "kept", len(kept), "dropped", dropped, "bytes", len(open(out).read()))
