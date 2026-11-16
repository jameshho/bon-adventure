"""Makes res://assets/branding/bon_adventure_logo.webp from the user's logo (16 Nov 2026).
Input: source/bon_adventure_logo_source.webp converted to PNG (macOS: sips -s format png).
The white page around the logo becomes transparent (flood fill from the edges over near-white
pixels; the white cloud and cat stay because the brown outline encloses them), the outline's
anti-aliased edge is un-blended against white, and the result is trimmed to the logo plus 6 px.
Needs Pillow, NumPy and SciPy. Save the output as lossless WebP (Pillow: lossless=True, method=6).
Why a cleaned raster and not a VTracer SVG: docs/evidence/bon-adventure-logo-20261116/README.md.
"""
import sys, numpy as np
from PIL import Image
from scipy import ndimage
src, out = sys.argv[1], sys.argv[2]
im = np.asarray(Image.open(src).convert("RGB")).astype(np.float32)
h, w, _ = im.shape
mn = im.min(axis=2)
near_white = mn > 232
lab, n = ndimage.label(near_white)
edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
bg = np.isin(lab, list(edge))
# outline colour: dark pixels next to the background
ring = ndimage.binary_dilation(bg, iterations=3) & ~bg
dark = ring & (im.sum(axis=2) < 300)
f = np.median(im[dark], axis=0)
print("outline colour", f.round(), "bg fraction", bg.mean().round(3))
alpha = np.ones((h, w), np.float32)
alpha[bg] = 0
# soft edge: un-blend the band around the background against white, assuming the outline colour
band = ring & ~dark
a = np.max((255 - im) / np.maximum(255 - f, 1), axis=2).clip(0, 1)
alpha[band] = a[band]
# background pixels that are not pure white (anti-alias outside the threshold) keep a little coverage
bgsoft = bg & (mn < 250)
alpha[bgsoft] = a[bgsoft] * 0.9
rgb = im.copy()
blend = (alpha < 1) & (alpha > 0)
rgb[blend] = f
rgba = np.dstack([rgb, alpha * 255]).round().clip(0, 255).astype(np.uint8)
ys, xs = np.nonzero(alpha > 0.02)
pad = 6
y0, y1, x0, x1 = max(ys.min() - pad, 0), min(ys.max() + pad + 1, h), max(xs.min() - pad, 0), min(xs.max() + pad + 1, w)
print("trim", x0, y0, x1, y1, "->", x1 - x0, "x", y1 - y0)
Image.fromarray(rgba[y0:y1, x0:x1], "RGBA").save(out)
