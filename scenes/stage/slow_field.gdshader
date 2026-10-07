shader_type canvas_item;

// Slow field: a tinted dome standing on the floor that ripples whatever is
// behind it by whole pixels. UV.x spans the dome's width, UV.y its height
// (floor at UV.y = 1). With motion off the ripple stops: a static tint.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec4 tint : source_color = vec4(0.62, 0.78, 1.0, 0.2);
uniform vec4 rim : source_color = vec4(0.85, 0.93, 1.0, 0.45);
uniform vec2 size_px = vec2(120.0, 150.0);
uniform float grow = 1.0;
uniform float time = 0.0;
uniform float motion = 1.0;

void fragment() {
	vec2 n = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y);
	float d = length(n);
	if (d > grow) {
		COLOR = vec4(0.0);
	} else {
		float row = floor(UV.y * size_px.y);
		float shift = round(sin(row * 0.45 - time * 2.4 + n.x * 3.0) * motion);
		vec4 behind = texture(screen_tex, SCREEN_UV + vec2(shift * SCREEN_PIXEL_SIZE.x, 0.0));
		vec3 colour = mix(behind.rgb, tint.rgb, tint.a);
		float edge = step(grow - 2.0 / size_px.x, d);
		colour = mix(colour, rim.rgb, rim.a * edge);
		COLOR = vec4(colour, 1.0);
	}
}
