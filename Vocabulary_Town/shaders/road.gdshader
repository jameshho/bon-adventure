shader_type spatial;
render_mode cull_disabled;

// Asphalt for the loop road, driveways and parking pads (see world_refinements.gd::
// road_surfaces). World-space, so ribbons and pads match where they meet. Static and
// opaque: faint wear patches plus a fine aggregate grain that fades with distance.
uniform vec4 base_color : source_color = vec4(0.345, 0.420, 0.431, 1.0);
uniform float patch_strength = 0.06;
uniform float grain_strength = 0.09;
uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
varying vec2 ground_position;
varying float view_distance;

void vertex() {
    vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    ground_position = world.xz;
    view_distance = distance(world, CAMERA_POSITION_WORLD);
}

void fragment() {
    float patches = texture(noise_tex, ground_position * 0.018).r - 0.5;
    float grain = texture(noise_tex, ground_position * 1.9 + vec2(0.37, 0.11)).r * 0.6
        + texture(noise_tex, ground_position * 4.7 + vec2(0.71, 0.23)).r * 0.4 - 0.5;
    float near = 1.0 - smoothstep(8.0, 45.0, view_distance);
    vec3 colour = base_color.rgb * (1.0 + patches * patch_strength * 2.0);
    colour *= 1.0 + grain * grain_strength * 2.0 * (0.3 + 0.7 * near);
    ALBEDO = colour;
    ROUGHNESS = 0.93;
    SPECULAR = 0.2;
}
