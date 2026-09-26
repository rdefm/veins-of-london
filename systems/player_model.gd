class_name PlayerModel
extends RefCounted

# state.player.model (R§2): the player's combat sprite set, one of
# GameData.TERRITORIAL_VARIANTS. Chosen once per save on the title screen's
# picker; Combat keeps that variant off every scrapper. Static funcs only.


# Writes `key` as the player's model. Refuses (returns false, state
# untouched) any key that isn't a discovered territorial variant.
static func set_model(key: String) -> bool:
	if not GameData.TERRITORIAL_VARIANTS.has(key):
		return false
	GameState.state["player"]["model"] = key
	EventBus.state_changed.emit()
	return true
