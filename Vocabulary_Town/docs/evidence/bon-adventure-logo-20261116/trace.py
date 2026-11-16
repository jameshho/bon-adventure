"""The VTracer runs of the logo trial (16 Nov 2026), on the cleaned, trimmed, transparent logo
(assets/branding/source/clean_logo.py output, clean.png). Run from a scratch folder, then
svg_cleanup.py <in.svg> <out.svg> 30 (drops empty and speckle paths under 30 px² of bounding
box and rounds coordinates to 0.1 px). VTracer 0.6.15 (Python), Pillow, NumPy, SciPy.
"""
import vtracer
RUNS = {
    "t_lean": dict(filter_speckle=16, color_precision=5, layer_difference=28, length_threshold=6.0, corner_threshold=60, path_precision=1),
    "t_balanced": dict(filter_speckle=8, color_precision=6, layer_difference=16, length_threshold=4.0, corner_threshold=60, path_precision=2),
    "t_fine": dict(filter_speckle=4, color_precision=7, layer_difference=10, length_threshold=3.5, corner_threshold=50, path_precision=2),
}
for name, kw in RUNS.items():
    vtracer.convert_image_to_svg_py("clean.png", name + ".svg", colormode="color", hierarchical="stacked",
                                    mode="spline", max_iterations=10, splice_threshold=45, **kw)
