shader_type spatial;
render_mode cull_disabled;
uniform vec4 shallow_color : source_color = vec4(0.10, 0.72, 0.72, 1.0);
uniform vec4 deep_color : source_color = vec4(0.025, 0.42, 0.58, 1.0);
uniform float motion_amount = 1.0;
void vertex() {
	VERTEX.y += sin(VERTEX.x * 0.6 + TIME * 0.8 * motion_amount) * cos(VERTEX.z * 0.7 + TIME * 0.5 * motion_amount) * 0.035;
}
void fragment() {
    float t = TIME * motion_amount;
    float a = sin((UV.x + UV.y * 0.15) * 340.0 + sin(UV.y * 150.0 + t * 0.3) * 2.5 + sin(UV.x * 50.0 - UV.y * 80.0) * 2.0);
    float b = sin((UV.y - UV.x * 0.2) * 320.0 + sin(UV.x * 130.0 - t * 0.2) * 2.0 + sin(UV.x * 60.0 + UV.y * 20.0) * 2.0);
    float caustic = smoothstep(0.90, 0.99, a) * 0.45 + smoothstep(0.92, 1.0, b) * 0.35;
    float wave = sin(UV.y * 80.0 + TIME * 0.5 * motion_amount) * 0.06;
    ALBEDO = mix(deep_color.rgb, shallow_color.rgb, 0.7 + wave) + vec3(caustic * 0.07);
    ROUGHNESS = 0.4;
    METALLIC = 0.08;
}
