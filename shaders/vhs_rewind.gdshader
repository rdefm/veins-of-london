shader_type canvas_item;

// VHS-rewind look over the combat stage: horizontal tracking wobble, a
// travelling tear band, red/blue colour bleed and scanlines. Parameters come
// from data/combat_visuals.json pacing.rewindEffect via CombatStage.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform vec2 stage_px = vec2(390.0, 362.0);
uniform float scanline_strength = 0.25;
uniform float scanline_period_px = 3.0;
uniform float wobble_px = 2.0;
uniform float tear_px = 14.0;
uniform float tear_speed = 0.9;
uniform float tear_height = 0.12;
uniform float bleed_px = 3.0;
uniform float noise_strength = 0.08;
uniform vec4 tint : source_color = vec4(0.55, 0.65, 1.0, 0.12);
// > 0: the patch fades out past this UV radius (a local rewind); 0 covers the rect.
uniform float vignette_inner = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float y_px = UV.y * stage_px.y;
	float t = TIME;

	float shift = sin(y_px * 0.07 + t * 38.0) * wobble_px;
	float band_y = fract(t * tear_speed);
	float in_band = smoothstep(tear_height, 0.0, abs(UV.y - band_y));
	shift += in_band * tear_px * (hash(vec2(floor(t * 24.0), floor(y_px / 2.0))) - 0.3);

	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 base = uv + vec2(shift * px.x, 0.0);
	float r = texture(screen_tex, base + vec2(bleed_px * px.x, 0.0)).r;
	float g = texture(screen_tex, base).g;
	float b = texture(screen_tex, base - vec2(bleed_px * px.x, 0.0)).b;
	vec3 col = vec3(r, g, b);

	float line = 0.5 + 0.5 * sin(y_px / scanline_period_px * 6.28318);
	col *= 1.0 - scanline_strength * line;
	col += (hash(vec2(UV.x * stage_px.x, y_px) + floor(t * 30.0)) - 0.5) * noise_strength;
	col = mix(col, tint.rgb, tint.a);
	float alpha = 1.0;
	if (vignette_inner > 0.0) {
		alpha = 1.0 - smoothstep(vignette_inner, 0.5, length(UV - vec2(0.5)));
	}
	COLOR = vec4(col, alpha);
}
