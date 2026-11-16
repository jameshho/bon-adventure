shader_type spatial;

// Hospital floor tiles (tools/build_hospital_remodel.py, 31 Oct 2026). Square tiles laid
// in world space so the grid runs on unbroken across rooms and floors, thin grout lines,
// a faint per-tile tone shift and a fine speckle. Grout and speckle fade with distance
// so far floors do not shimmer. base_color is each slab's own floor or room tint.
uniform vec4 base_color : source_color = vec4(0.902, 0.886, 0.855, 1.0);
// 60 cm town tiles at the Apartment's 1.3 world scale.
uniform float tile_size = 0.78;
uniform float grout_width = 0.018;
uniform float speckle_strength = 0.05;
varying vec2 floor_position;
varying float view_distance;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
    vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    floor_position = world.xz;
    view_distance = distance(world, CAMERA_POSITION_WORLD);
}

void fragment() {
    vec2 cell = floor_position / tile_size;
    vec2 tile = floor(cell);
    vec2 edge = abs(fract(cell) - 0.5) * tile_size;
    float near = 1.0 - smoothstep(4.0, 30.0, view_distance);
    float tone = (hash(tile) - 0.5) * 0.035;
    float speckle = (hash(floor(floor_position * 55.0)) - 0.5) * speckle_strength * near;
    vec3 colour = base_color.rgb * (1.0 + tone + speckle);
    float to_grout = tile_size * 0.5 - max(edge.x, edge.y);
    float grout = (1.0 - smoothstep(grout_width * 0.5, grout_width, to_grout)) * (0.35 + 0.65 * near);
    // Grout is a darker shade of the tile, so tinted room floors keep their colour.
    ALBEDO = colour * (1.0 - grout * 0.16);
    ROUGHNESS = 0.7;
    SPECULAR = 0.35;
}
