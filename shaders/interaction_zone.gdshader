shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;
uniform vec2 zone_size = vec2(2.3, 1.95);
uniform vec4 accent : source_color = vec4(0.20, 0.72, 0.58, 1.0);
uniform sampler2D icon : source_color, filter_linear_mipmap;
uniform float purchase = 0.0;
uniform float active : hint_range(0.0, 1.0) = 0.0;
uniform float ready : hint_range(0.0, 1.0) = 0.0;
uniform float complete : hint_range(0.0, 1.0) = 0.0;
uniform float progress : hint_range(-1.0, 1.0) = -1.0;
float round_box(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + radius;
	return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - radius;
}
void fragment() {
	vec2 p = (UV - 0.5) * zone_size;
	float d = round_box(p, zone_size * 0.5 - 0.09, 0.22);
	float inside = 1.0 - smoothstep(-0.01, 0.02, d);
	float line = 1.0 - smoothstep(0.026, 0.045, abs(d));
	float shadow = 1.0 - smoothstep(0.045, 0.066, abs(d));
	float dash = smoothstep(0.14, 0.20, fract((abs(p.x) + abs(p.y)) * 3.4));
	float corner = step(zone_size.x*0.29,abs(p.x)) * step(zone_size.y*0.27,abs(p.y));
	dash = mix(dash,corner,purchase);
	vec3 highlight = mix(vec3(0.98, 1.0, 0.92), accent.rgb, max(active, ready * 0.18));
	vec3 color = mix(accent.rgb, vec3(0.08, 0.21, 0.23), shadow * dash);
	color = mix(color, highlight, line * dash);
	float alpha = inside * (0.08 + active * 0.16) * (1.0 - complete * 0.65);
	alpha = max(alpha, shadow * dash * (1.0 - complete * 0.5));
	vec2 icon_uv = (p - vec2(0.0,-purchase*0.38)) / mix(0.63,0.80,purchase) + 0.5;
	if (purchase < 0.5 && all(greaterThanEqual(icon_uv, vec2(0.0))) && all(lessThanEqual(icon_uv, vec2(1.0)))) {
		vec4 stamp = texture(icon, icon_uv);
		color = mix(color, stamp.rgb, stamp.a);
		alpha = max(alpha, stamp.a * (1.0 - complete * 0.45));
	}
	// Whole-pad green reveal is dwell feedback, not partial investment.
	if (purchase > 0.5 && progress >= 0.0) {
		float reveal = inside * (1.0 - smoothstep(progress - 0.018, progress + 0.018, 1.0 - UV.y));
		color = mix(color, vec3(0.15, 0.80, 0.39), reveal);
		alpha = max(alpha, reveal * 0.78);
	}
	if (progress >= 0.0) {
		vec2 bar = p - vec2(0.0, zone_size.y * 0.39);
		float track = 1.0 - smoothstep(-0.004, 0.012, round_box(bar, vec2(zone_size.x * 0.32, 0.045), 0.035));
		float fill = step(bar.x, -zone_size.x * 0.32 + zone_size.x * 0.64 * progress);
		color = mix(color, mix(vec3(0.11, 0.25, 0.26), accent.rgb, fill), track);
		alpha = max(alpha, track);
	}
	ALBEDO = color;
	ALPHA = alpha;
}
