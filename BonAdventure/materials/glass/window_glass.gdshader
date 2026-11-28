// Shared window glass (docs/guides/WINDOWS.md; user, 13 Nov 2026): ONE sheet with two looks. The
// face toward the outdoors is dark and reflective, the face toward the room light and clear, so a
// window reads like real glass (dark from the street by day, easy to see out of from inside).
// The sheet is drawn from both sides (cull_disabled); FRONT_FACING says which side the camera is
// on. The reflection is a cheap sky/ground gradient picked by the reflected direction: no screen
// texture, reflection probe or extra pass, so it runs on the Compatibility renderer and the web.
// It is lit like any surface, so the reflection dims at night, and the reflected sky colour
// follows the time of day (glass_sky_colour below). outside_face: 0 = no outdoors side
// (both faces use the inside look), 1 = the +Z face looks outdoors, 2 = the -Z face does.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, specular_schlick_ggx;

uniform int outside_face = 0;
// rgb = tint, a = opacity.
uniform vec4 inside_tint : source_color = vec4(0.66, 0.78, 0.86, 0.30);
uniform vec4 outside_tint : source_color = vec4(0.17, 0.20, 0.22, 0.80);
// How much of the faked sky shows in the glass, facing it straight on.
uniform float inside_reflection : hint_range(0.0, 1.0) = 0.08;
uniform float outside_reflection : hint_range(0.0, 1.0) = 0.38;
// The sky the glass reflects: a global (project.godot [shader_globals]) that day_night.gd sets
// with one write as the hours pass (P3-20, 25 Nov 2026), so every glass material, the shared
// file and its per-tint copies alike, takes the dawn, dusk and night sky. Default: the noon sky.
global uniform vec4 glass_sky_colour;
uniform vec3 ground_colour : source_color = vec3(0.36, 0.40, 0.38);

void fragment() {
	bool outdoors = (outside_face == 1 && FRONT_FACING) || (outside_face == 2 && !FRONT_FACING);
	vec4 tint = outdoors ? outside_tint : inside_tint;
	float strength = outdoors ? outside_reflection : inside_reflection;
	// Toward the viewer whichever side it is seen from.
	vec3 n = dot(NORMAL, VIEW) < 0.0 ? -NORMAL : NORMAL;
	float fresnel = pow(1.0 - clamp(dot(n, VIEW), 0.0, 1.0), 4.0);
	vec3 bounce = (INV_VIEW_MATRIX * vec4(reflect(-VIEW, n), 0.0)).xyz;
	vec3 env = mix(ground_colour, glass_sky_colour.rgb, smoothstep(-0.2, 0.35, bounce.y));
	float k = strength * (0.6 + 0.4 * fresnel);
	ALBEDO = mix(tint.rgb, env, k);
	// Glass grows more mirror-like at grazing angles.
	ALPHA = clamp(tint.a + (1.0 - tint.a) * max(fresnel * 0.6, k * 0.5), 0.0, 1.0);
	ROUGHNESS = 0.12;
	SPECULAR = 0.6;
	METALLIC = 0.0;
}
