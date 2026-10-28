shader_type canvas_item;

// VCR-pause look on a Time-Pearl-frozen fighter sprite: whole-sprite field
// shiver, a flicker to the previous animation frame, a tracking band rolling
// feet to head, light desaturation and scanlines. Output alpha is the sampled
// sprite alpha, so nothing paints outside the figure. Parameters come from
// data/combat_visuals.json pacing.freezeFx via CombatStage.

uniform sampler2D prev_tex : filter_nearest;
uniform float shiver_px = 1.0;
uniform float shiver_hz = 8.0;
uniform float flicker_every = 5.0;
uniform float band_period = 1.2;
uniform float band_height = 0.08;
uniform float band_shear_px = 2.5;
uniform float band_brighten = 0.35;
uniform float band_noise = 0.25;
uniform float desaturate = 0.35;
uniform float scanline_strength = 0.18;
uniform float scanline_period_px = 3.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 tex_px = TEXTURE_PIXEL_SIZE;
	float field = floor(TIME * shiver_hz);
	float shiver = (mod(field, 2.0) < 1.0 ? -1.0 : 1.0) * shiver_px;

	// Band rolls from feet (UV.y = 1) to head (UV.y = 0).
	float band_y = 1.0 - fract(TIME / band_period);
	float in_band = smoothstep(band_height, 0.0, abs(UV.y - band_y));
	float shear = in_band * band_shear_px * (hash(vec2(floor(TIME * 30.0), floor(UV.y / tex_px.y / 2.0))) * 2.0 - 1.0);

	vec2 uv = UV + vec2((shiver + shear) * tex_px.x, 0.0);
	bool flicker = mod(field, flicker_every) < 1.0;
	vec4 c = flicker ? texture(prev_tex, uv) : texture(TEXTURE, uv);

	float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(c.rgb, vec3(gray), desaturate);
	float line = 0.5 + 0.5 * sin(UV.y / tex_px.y / scanline_period_px * 6.28318);
	col *= 1.0 - scanline_strength * line;
	float noise = hash(vec2(UV.x / tex_px.x, UV.y / tex_px.y) + floor(TIME * 30.0));
	col += in_band * (band_brighten + (noise - 0.5) * band_noise);
	COLOR = vec4(col, c.a);
}
