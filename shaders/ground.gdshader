shader_type spatial;
varying vec3 wp;
uniform vec4 grass_a : source_color = vec4(0.14, 0.36, 0.05, 1.0);
uniform vec4 grass_b : source_color = vec4(0.28, 0.52, 0.09, 1.0);
uniform vec4 path_color : source_color = vec4(0.71, 0.54, 0.32, 1.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa=p-a; vec2 ba=b-a; return length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0));
}
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 p=wp.xz;
	float n=noise(p*0.55)*0.7+noise(p*3.0)*0.3;
	float d=min(segment(p,vec2(-5,-1.5),vec2(-5,5.2)),segment(p,vec2(-9,5.2),vec2(8.6,5.2)));
	float flecks = step(0.80,noise(p*13.0));
	float trail=1.0-smoothstep(0.55,0.9,d+(n-0.5)*0.2);
	ALBEDO=mix(mix(grass_a.rgb,grass_b.rgb,n)*mix(0.96,1.04,flecks),path_color.rgb*(0.93+n*0.12),trail);
	ROUGHNESS=1.0;
}
