shader_type canvas_item;

// Black Hole warp: a rect drawn over the backdrop (and under the fighters)
// re-samples what is behind it, pulling the picture toward `centre` (screen
// UV). `strength` is the pull as a fraction of distance from the centre at its
// strongest. Parameters come from data/combat_visuals.json itemFx.removalFx.blackHole
// via CombatStage.play_black_hole.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform vec2 centre = vec2(0.5);
uniform vec2 aspect = vec2(1.0);
uniform float strength = 0.0;

void fragment() {
	vec2 d = SCREEN_UV - centre;
	float falloff = 1.0 - smoothstep(0.0, 0.7, length(d * aspect));
	vec2 uv = clamp(centre + d * (1.0 + strength * falloff), vec2(0.0), vec2(1.0));
	COLOR = vec4(texture(screen_tex, uv).rgb, 1.0);
}
