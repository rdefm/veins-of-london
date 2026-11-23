shader_type canvas_item;

// Re-colours the glass of the shared Lens sprite to one ore: glass pixels
// (keyed by hue/saturation, inside the glass ellipse) are gradient-mapped by
// luminance from a dark floor of the ore colour up to a lifted highlight;
// bezel, specular and shadow pass through. Parameters come from
// data/dial_art.json components.lens_tint via DialMenu.lens_material.

uniform vec3 glass_colour = vec3(0.5, 0.5, 0.5);
uniform float key_hue_min = 0.5;
uniform float key_hue_max = 0.72;
uniform float key_sat_min = 0.25;
uniform vec2 glass_centre = vec2(0.453, 0.383);
uniform vec2 glass_radius = vec2(0.383, 0.289);
uniform float lum_full = 0.75;
uniform float dark_floor = 0.25;
uniform float light_lift = 0.55;

vec3 rgb2hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

void fragment() {
	vec4 src = COLOR;
	vec3 hsv = rgb2hsv(src.rgb);
	bool glass = hsv.y > key_sat_min && hsv.x > key_hue_min && hsv.x < key_hue_max && length((UV - glass_centre) / glass_radius) <= 1.0;
	if (glass) {
		float t = clamp(dot(src.rgb, vec3(0.299, 0.587, 0.114)) / lum_full, 0.0, 1.0);
		vec3 lo = glass_colour * mix(dark_floor, 1.0, clamp(t / 0.5, 0.0, 1.0));
		vec3 hi = mix(glass_colour, vec3(1.0), light_lift * clamp((t - 0.5) / 0.5, 0.0, 1.0));
		src.rgb = t < 0.5 ? lo : hi;
	}
	COLOR = src;
}
