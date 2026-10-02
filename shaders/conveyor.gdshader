shader_type spatial;
render_mode cull_back;
uniform vec4 belt_color : source_color = vec4(0.04,0.22,0.25,1.0);
uniform float travel = 0.0;
uniform float running = 0.0;
void fragment() {
	float tread = step(0.76,fract(UV.y*17.0-travel*3.5));
	float rim = step(0.96,abs(UV.x-0.5)*2.0);
	ALBEDO = mix(belt_color.rgb,belt_color.rgb+vec3(0.12,0.19,0.18),tread*0.65);
	ALBEDO = mix(ALBEDO,vec3(0.83,0.91,0.88),rim);
	ROUGHNESS = 0.72;
	EMISSION = vec3(0.05,0.23,0.19)*running*tread*0.15;
}
