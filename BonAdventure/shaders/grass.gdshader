shader_type spatial;
render_mode cull_disabled;

// Shared lawn surface for every grass mesh (see world_refinements.gd::grass_surfaces).
// Static and opaque: broad lush/dry colour patches, mid-scale clumping, and a fine
// blade grain that fades with distance so it never shimmers. One noise texture.
uniform vec4 base_color : source_color = vec4(0.470588, 0.588235, 0.372549, 1.0);
uniform vec4 lush_color : source_color = vec4(0.36, 0.52, 0.28, 1.0);
uniform vec4 dry_color : source_color = vec4(0.60, 0.64, 0.38, 1.0);
uniform float grain_strength = 0.2;
uniform float grain_fade_start = 6.0;
uniform float grain_fade_end = 38.0;
uniform sampler2D grass_noise : repeat_enable, filter_linear_mipmap;
varying vec2 ground_position;
varying float view_distance;

void vertex() {
    vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    ground_position = world.xz;
    view_distance = distance(world, CAMERA_POSITION_WORLD);
}

void fragment() {
    // World-space scales stay continuous across differently sized lawn meshes.
    float broad = texture(grass_noise, ground_position * 0.012).r;
    float clumps = texture(grass_noise, ground_position * 0.09 + vec2(0.31, 0.67)).r - 0.5;
    vec3 colour = mix(lush_color.rgb, dry_color.rgb, smoothstep(0.38, 0.72, broad) * 0.55);
    colour = mix(colour, base_color.rgb, 0.35);
    colour *= 1.0 + clumps * 0.14;
    // Blade grain: two finely scaled, rotated samples stretched slightly along one axis
    // read as short blades; contrast is pushed so they form flecks, not soft blur.
    vec2 g = ground_position;
    float a = texture(grass_noise, vec2(g.x * 2.3, g.y * 1.2) + vec2(0.13, 0.71)).r;
    float b = texture(grass_noise, vec2(g.x * 0.9 - g.y * 1.9, g.x * 1.9 + g.y * 0.9) * 1.1).r;
    float grain = smoothstep(0.30, 0.70, a * 0.55 + b * 0.45) - 0.5;
    float near = 1.0 - smoothstep(grain_fade_start, grain_fade_end, view_distance);
    colour *= 1.0 + grain * grain_strength * (0.35 + 0.65 * near);
    ALBEDO = colour;
    ROUGHNESS = 1.0;
    SPECULAR = 0.15;
}
