// Control-tower radar screen (9 Nov 2026; docs/guides/RADAR_PATROL.md): the Radar Patrol look in 3D —
// dark green disc, square grid, range rings, crosshair, bearing ticks, a rotating sweep and a
// few blips that light up as the sweep passes. Drawn on a quad (UV 0..1); outside the circle
// is discarded. Used by both radars (airport.gd step radar_patrol_screens).
shader_type spatial;
render_mode unshaded, cull_back;

uniform float sweep_speed = 1.7;
uniform vec3 glow : source_color = vec3(0.49, 1.0, 0.43);
uniform vec3 line_color : source_color = vec3(0.25, 0.75, 0.35);
uniform vec3 deep : source_color = vec3(0.025, 0.12, 0.055);

float line_at(float d, float width) {
	float w = fwidth(d) + width;
	return 1.0 - smoothstep(width, w, abs(d));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	vec3 col = deep + vec3(0.02, 0.07, 0.03) * (1.0 - r);
	// Grid and rings.
	vec2 cell = abs(fract(p * 4.0) - 0.5) - 0.5;
	float grid = max(line_at(cell.x, 0.0), line_at(cell.y, 0.0)) * 0.12;
	float rings = 0.0;
	for (int i = 1; i <= 4; i++) {
		rings = max(rings, line_at(r - (float(i) * 0.2 + 0.04), 0.004));
	}
	float cross = max(line_at(p.x, 0.004), line_at(p.y, 0.004));
	float angle = atan(p.y, p.x);
	float tick_mask = step(0.93, r);
	float ticks = line_at(fract(angle / (TAU / 36.0) + 0.5) - 0.5, 0.02) * tick_mask;
	float rim = line_at(r - 0.985, 0.012);
	col += line_color * (grid + rings * 0.55 + cross * 0.45 + ticks * 0.5);
	col += glow * rim;
	// Sweep: bright leading edge with a fading wedge behind it.
	float lead = mod(TIME * sweep_speed, TAU);
	float behind = mod(lead - angle, TAU);
	col += glow * (exp(-behind * 2.6) * 0.45 + line_at(behind, 0.012) * 0.8 * step(behind, 1.0));
	// Blips (a plane-like one and two "UFOs"), lit by the sweep.
	vec2 blips[4] = vec2[](vec2(0.42, -0.35), vec2(-0.5, 0.18), vec2(0.15, 0.55), vec2(-0.25, -0.6));
	for (int i = 0; i < 4; i++) {
		vec2 b = blips[i];
		float since = mod(lead - atan(b.y, b.x), TAU);
		float lit = 0.25 + 0.75 * exp(-since * 0.8);
		col += glow * lit * (1.0 - smoothstep(0.025, 0.045, length(p - b)));
	}
	// Hub.
	col += glow * (1.0 - smoothstep(0.03, 0.045, r));
	ALBEDO = col;
}
