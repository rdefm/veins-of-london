class_name CombatPacing
extends RefCounted

# Persisted pacing toggle for the beat queue director (docs/combat-animation-vision.md §8).
# Lives at GameState.state's top level, not inside state.combat, since
# Combat.exit_combat() resets state.combat every fight and would wipe this.
const MODES: PackedStringArray = ["normal", "quick"]
const DEFAULT_MODE := "normal"


static func pacing_mode() -> String:
	return GameState.state.get("combatPacingMode", DEFAULT_MODE)


static func set_pacing_mode(mode: String) -> void:
	if not MODES.has(mode):
		return
	GameState.state["combatPacingMode"] = mode
	EventBus.state_changed.emit()
