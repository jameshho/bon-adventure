shader_type spatial;
// Garden lagoon: translucent like the home pool so the bank and bed tint show
// through, with a fresnel sky reflection, sun glints and slow ripples in pond greens.
render_mode blend_mix, cull_disabled, depth_draw_opaque;
uniform vec3 shallow_color : source_color = vec3(0.24, 0.48, 0.45);
uniform vec3 deep_color : source_color = vec3(0.06, 0.22, 0.23);
uniform vec3 sky_color : source_color = vec3(0.52, 0.70, 0.78);
uniform float clarity : hint_range(0.0, 1.0) = 0.45;
varying vec3 water_position;
void vertex() {
    water_position = VERTEX;
}
void fragment() {
    vec2 p = water_position.xz;
    // Two drifting wave trains; their slopes tilt the normal for moving glints.
    float a = sin(p.x * 1.2 + p.y * 5.1 + sin(p.x * 0.47 + TIME * 0.13) * 1.8 + TIME * 0.65);
    float b = sin(p.x * 0.8 + p.y * 8.3 + sin(p.x * 0.31) * 2.1 - TIME * 0.42);
    float c = cos(p.x * 3.7 - p.y * 1.9 + TIME * 0.9);
    float broad = sin(p.x * 0.19 + sin(p.y * 0.16) * 1.8) * 0.5 + 0.5;
    vec3 tilt = vec3(a * 0.05 + c * 0.025, b * 0.05 - c * 0.02, 0.0);
    vec3 n = normalize(NORMAL + tilt);
    float fresnel = pow(1.0 - clamp(dot(n, normalize(VIEW)), 0.0, 1.0), 3.0);
    vec3 body = mix(shallow_color, deep_color, 0.35 + broad * 0.3);
    ALBEDO = mix(body, sky_color, fresnel * 0.45);
    // Clear when looking down, mirror-like toward the horizon.
    ALPHA = mix(1.0 - clarity, 0.94, fresnel);
    NORMAL = n;
    ROUGHNESS = 0.07;
    SPECULAR = 0.85;
    METALLIC = 0.0;
}
