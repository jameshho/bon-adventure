shader_type spatial;
render_mode cull_disabled;

// Concrete paving for sidewalks, curbs and walks (world_refinements.gd). A light grain
// in world space; on swept sidewalks (UV.x = distance along the loop) thin control
// joints every `joint_spacing`. joint_strength 0 turns joints off for plain ribbons.
uniform vec4 base_color : source_color = vec4(0.824, 0.796, 0.718, 1.0);
uniform float grain_strength = 0.06;
uniform float joint_spacing = 1.8;
uniform float joint_strength = 0.0;
uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
varying vec2 ground_position;
varying float view_distance;

void vertex() {
    vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    ground_position = world.xz;
    view_distance = distance(world, CAMERA_POSITION_WORLD);
}

void fragment() {
    float grain = texture(noise_tex, ground_position * 1.4 + vec2(0.19, 0.53)).r - 0.5;
    float stain = texture(noise_tex, ground_position * 0.05).r - 0.5;
    float near = 1.0 - smoothstep(6.0, 40.0, view_distance);
    vec3 colour = base_color.rgb * (1.0 + stain * 0.05) * (1.0 + grain * grain_strength * 2.0 * (0.4 + 0.6 * near));
    float joint_distance = abs(fract(UV.x / joint_spacing + 0.5) - 0.5) * joint_spacing;
    float joint = 1.0 - smoothstep(0.018, 0.045, joint_distance);
    colour *= 1.0 - joint * joint_strength * (0.35 + 0.65 * near);
    ALBEDO = colour;
    ROUGHNESS = 0.9;
    SPECULAR = 0.25;
}
