shader_type canvas_item;

// Stunned head-bob: the top of the sprite sways side to side, the feet hold.
// Parameters come from data/combat_visuals.json itemFx.removalFx.stun via
// CombatStage.StageSlot.set_stunned_visual.

uniform float shear_px = 3.0;
uniform float period = 0.8;

void vertex() {
	VERTEX.x += sin(TIME * 6.28318 / period) * shear_px * (1.0 - UV.y);
}
