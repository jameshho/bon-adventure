shader_type spatial;
// Monument fountain streams and spill sheets (scripts/buildings/monument_plaza.gd, 8 Nov 2026):
// pale translucent water with bright bands sliding down the local height, so the static
// strands read as falling water. No UVs needed: the bands follow the mesh's own Y.
// Also the faucet streams (scripts/world/faucet.gd, 8 Nov 2026), which set `bands` and `speed`.
render_mode blend_mix, cull_disabled, depth_draw_opaque;
uniform vec3 water_color : source_color = vec3(0.74, 0.88, 0.94);
uniform float opacity : hint_range(0.0, 1.0) = 0.55;
uniform float speed = 1.4;
// Bright bands per local unit of height (5 for the fountains).
uniform float bands = 5.0;
varying vec3 local_position;
void vertex() {
    local_position = VERTEX;
}
void fragment() {
    float around = atan(local_position.z, local_position.x);
    float flow = local_position.y * bands + TIME * speed + sin(around * 23.0) * 0.4;
    float streak = 0.5 + 0.5 * sin(flow * 6.2832);
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
    ALBEDO = mix(water_color, vec3(1.0), streak * 0.4 + fresnel * 0.3);
    ALPHA = clamp(opacity * (0.6 + 0.4 * streak) + fresnel * 0.25, 0.0, 0.95);
    EMISSION = water_color * 0.1;
    ROUGHNESS = 0.08;
    SPECULAR = 0.8;
}
