shader_type spatial;
// The sun (by day) and moon (by night) in the sky: a soft round core with a halo, on a quad that
// scripts/world/day_night.gd turns toward the camera and places just inside its far limit, so all
// scenery draws over it (21 Nov 2026: the old solid ball sat in front of fogged buildings).
// Unshaded, no fog, no shadows; one draw call.
render_mode unshaded, fog_disabled, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Keyframe "disc" colour; the haze colour is the fog colour of the hour.
uniform vec4 disc_color : source_color = vec4(1.0, 0.886, 0.443, 1.0);
uniform vec4 haze_color : source_color = vec4(0.79, 0.89, 0.94, 1.0);
// Core radius as a share of the quad's half size; the rest is halo.
uniform float core = 0.28;
// Halo strength (sun brighter than moon).
uniform float glow = 0.8;
// 0 below the horizon to 1 above it, and how far the colour sinks into the haze near it.
uniform float fade = 1.0;
uniform float haze = 0.0;

void fragment() {
	float d = length(UV * 2.0 - 1.0);
	float body = 1.0 - smoothstep(core * 0.9, core, d);
	float halo = glow * pow(clamp(1.0 - d, 0.0, 1.0), 1.8);
	vec3 tint = mix(disc_color.rgb, haze_color.rgb, haze);
	// The halo is a lighter, hazier version of the core.
	ALBEDO = mix(mix(tint, haze_color.rgb, 0.35), tint, body);
	ALPHA = clamp(body + halo * (1.0 - body), 0.0, 1.0) * fade;
}
