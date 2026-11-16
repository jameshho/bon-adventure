shader_type spatial;
render_mode cull_disabled;

// Beach and island sand (scripts/world/coast.gd). Static and opaque, like grass/paving:
// broad dune tint, slow wind ripples, fine grain that fades with distance, sparse
// pebble flecks, and wet sand toward the waterline. Mesh vertex colour red = wetness
// (0 dry back beach, 1 at the water), so no texture is tied to one mesh.
uniform vec4 base_color : source_color = vec4(0.76, 0.63, 0.42, 1.0);
uniform vec4 light_color : source_color = vec4(0.84, 0.72, 0.5, 1.0);
uniform vec4 shade_color : source_color = vec4(0.7, 0.58, 0.39, 1.0);
uniform vec4 wet_color : source_color = vec4(0.6, 0.49, 0.34, 1.0);
uniform vec4 pebble_color : source_color = vec4(0.58, 0.53, 0.45, 1.0);
uniform float grain_strength = 0.34;
uniform float ripple_strength = 0.1;
uniform float grain_fade_start = 6.0;
uniform float grain_fade_end = 38.0;
uniform sampler2D sand_noise : repeat_enable, filter_linear_mipmap;
varying vec2 ground_position;
varying float view_distance;
varying float wetness;

void vertex() {
    vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    ground_position = world.xz;
    view_distance = distance(world, CAMERA_POSITION_WORLD);
    wetness = COLOR.r;
}

void fragment() {
    float near = 1.0 - smoothstep(grain_fade_start, grain_fade_end, view_distance);
    float broad = texture(sand_noise, ground_position * 0.011).r;
    float warp = texture(sand_noise, ground_position * 0.035 + vec2(0.4, 0.2)).r;
    vec3 colour = mix(shade_color.rgb, base_color.rgb, smoothstep(0.2, 0.45, broad));
    colour = mix(colour, light_color.rgb, smoothstep(0.45, 0.72, broad));
    // Wind ripples: a sine warped by low-frequency noise gives wavy, uneven crests.
    float ripple = sin((ground_position.x * 0.8 + ground_position.y * 0.5) * 2.2 + warp * 11.0);
    colour *= 1.0 + ripple * ripple_strength * (1.0 - smoothstep(10.0, 60.0, view_distance));
    // Grain: two rotated samples thresholded into light and dark flecks.
    vec2 g = ground_position;
    float a = texture(sand_noise, g * 1.9 + vec2(0.13, 0.71)).r;
    float b = texture(sand_noise, vec2(g.x * 0.8 - g.y * 1.7, g.x * 1.7 + g.y * 0.8) * 1.3).r;
    float grain = smoothstep(0.30, 0.70, a * 0.5 + b * 0.5) - 0.5;
    colour *= 1.0 + grain * grain_strength * (0.3 + 0.7 * near);
    // Pebble flecks: rare, small, only near the camera.
    float peb = smoothstep(0.80, 0.84, texture(sand_noise, g * 0.55 + vec2(0.52, 0.18)).r);
    colour = mix(colour, pebble_color.rgb, peb * 0.55 * near);
    // Wet sand: darker and glossier toward the water, with a ragged noisy edge.
    float wet = smoothstep(0.4, 1.0, wetness + (texture(sand_noise, g * 0.09).r - 0.5) * 0.5);
    colour = mix(colour, wet_color.rgb, wet * 0.5);
    ALBEDO = colour;
    ROUGHNESS = mix(1.0, 0.55, wet);
    SPECULAR = mix(0.12, 0.4, wet);
}
