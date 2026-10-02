shader_type spatial;
render_mode cull_disabled;
uniform float motion_amount = 1.0;
uniform float shore_z = -2.45;
uniform float foam_width : hint_range(0.1,2.0) = 0.78;
uniform vec4 shallow_color : source_color = vec4(0.15,0.79,0.86,1.0);
uniform vec4 deep_color : source_color = vec4(0.025,0.52,0.73,1.0);
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	float t=TIME*motion_amount;
	float a=world_pos.x*0.74+world_pos.z*0.45+t*1.15;
	float b=world_pos.z*1.1-world_pos.x*0.30-t*0.85;
	VERTEX.y+=sin(a)*0.042+sin(b)*0.018;
	NORMAL=normalize(vec3(-cos(a)*0.031+cos(b)*0.0054,1.0,-cos(a)*0.019-cos(b)*0.0198));
}
void fragment() {
	vec2 p=world_pos.xz;
	float t=TIME*motion_amount;
	float distance_to_shore=max(0.0,shore_z-p.y);
	float depth=smoothstep(0.0,13.0,distance_to_shore);
	vec3 water=mix(shallow_color.rgb,deep_color.rgb,depth);
	// Broad traveling cel bands and soft curling highlights, not a static checkerboard.
	vec2 flow=p*0.62+vec2(t*0.25,-t*0.19);
	flow+=vec2(sin(p.y*0.44+t*0.32),cos(p.x*0.28-t*0.25))*0.65;
	float band=sin(flow.y+sin(flow.x)*0.55);
	water+=vec3(0.025,0.045,0.047)*smoothstep(-0.35,0.15,band);
	float crest=abs(sin(flow.y+sin(flow.x*0.7)*0.45));
	float highlight=(1.0-smoothstep(0.025,0.075,crest))*smoothstep(0.15,0.65,sin(flow.x*1.45+cos(flow.y)*0.4));
	water=mix(water,vec3(0.63,0.94,0.94),highlight*0.12);
	float scallop=sin(p.x*2.9+t*0.65)*0.12+sin(p.x*6.2-t*0.48)*0.065;
	float width=foam_width+scallop+sin(t*0.9)*0.12;
	float foam=1.0-smoothstep(width-0.055,width+0.055,distance_to_shore);
	float wash=1.0-smoothstep(width,width+0.47,distance_to_shore);
	water=mix(water,vec3(0.60,0.91,0.92),wash*0.5);
	float outer=1.0-smoothstep(0.045,0.095,abs(distance_to_shore-width-0.38-sin(p.x*1.7+t*0.5)*0.065));
	ALBEDO=mix(water,vec3(0.95,1.0,0.94),max(foam*0.96,outer*0.26));
	ROUGHNESS=0.72;
	METALLIC=0.0;
	SPECULAR=0.1;
}
