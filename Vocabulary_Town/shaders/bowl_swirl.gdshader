shader_type spatial;
// Toilet bowl water (scripts/world/toilet.gd, 8 Nov 2026): the fountain water's pale blue with a
// still ripple at rest; while flushing, `swirl` (0..1) brings in three bright spiral arms turning
// with `phase` and a darker vortex in the middle. The disc mesh has radius 1 (node scale sets size).
render_mode blend_mix, cull_disabled, depth_draw_opaque;
uniform vec3 water_color : source_color = vec3(0.48, 0.74, 0.88);
uniform float opacity : hint_range(0.0, 1.0) = 0.7;
uniform float swirl : hint_range(0.0, 1.0) = 0.0;
uniform float phase = 0.0;
varying vec3 local_position;
void vertex() {
    local_position = VERTEX;
}
void fragment() {
    float r = clamp(length(local_position.xz), 0.0, 1.0);
    float around = atan(local_position.z, local_position.x);
    float arms = 0.5 + 0.5 * sin(around * 3.0 + r * 7.0 - phase);
    float ripple = 0.5 + 0.5 * sin(r * 14.0 - TIME * 1.2);
    float bright = mix(ripple * 0.12, arms * 0.6, swirl) + smoothstep(0.78, 1.0, r) * 0.25;
    float vortex = (1.0 - smoothstep(0.0, 0.4, r)) * swirl;
    ALBEDO = mix(water_color, vec3(1.0), bright) * (1.0 - vortex * 0.3);
    ALPHA = clamp(opacity + bright * 0.25, 0.0, 0.95);
    EMISSION = water_color * 0.08;
    ROUGHNESS = 0.08;
    SPECULAR = 0.8;
}
