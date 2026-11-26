# Contact shadows (GFX-01) — rejected 25 November 2026

Soft round "blob" shadows (one flat quad, one shared unshaded alpha-blended material) were built
under the player, plush characters, animals and vehicles, and batched under trees, shrubs and
floor-standing word props through `render_culling.gd`. Measured on the Mac (full town, 1560×720),
they cost 1.4–4.0 % more draw calls on foot and 2.9 % flying at 40 m, with no frame-time change.

**The user rejected them (25 Nov 2026) after playing the zoo:** a dark wedge ran sideways from the
plant in the tiger enclosure, a fainter one from the plant behind it, and the bench had a darker
edge. Offered "fix it" or "remove shadows", they chose to remove them. All of the code, the material
and the docs were taken out and nothing was committed. The improvement plan's decision log records
D6 as reversed.

The wedges most likely came from the batched static quads (`ground_pose()`), which flattened a
tilted or non-uniformly scaled prop's axes into a skewed quad, and from the view-ray depth bias
on sloped ground. Look at those first if contact shadows are tried again.
