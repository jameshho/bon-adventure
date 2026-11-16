shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never;
uniform vec4 glow_color : source_color = vec4(0.0, 0.749, 1.0, 1.0);
uniform float strength = 0.3;
void vertex() { VERTEX += NORMAL * 0.018; }
void fragment() {
    float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.2);
    ALBEDO = glow_color.rgb * (0.7 + rim * 0.3);
    EMISSION = glow_color.rgb * rim * 0.4;
    ALPHA = (0.08 + rim * 0.92) * strength;
}
