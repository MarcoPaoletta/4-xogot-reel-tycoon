shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.57,0.34,0.17,1.0);
void fragment(){
	float grain=sin(UV.x*95.0+sin(UV.y*8.0)*2.0)*0.022+sin(UV.x*300.0+UV.y*10.0)*0.011;
	float join=1.0-smoothstep(0.005,0.013,abs(fract(UV.x*9.0)-0.5));
	ALBEDO=base_color.rgb*(1.0+grain)-join*0.045;
	ROUGHNESS=0.85;
}
