class_name CombatPacing
extends RefCounted

# combat-presentation ticket 04, docs/combat-animation-vision.md §8: the beat
# queue director's own persisted pacing toggle -- same split as
# MapEvents.pacing_mode()/set_pacing_mode() (systems own the GameState-backed
# schema, scene components own visual-only duration constants), per that
# file's own class comment and the vision doc's explicit "reuse
# map_canvas.gd's pattern, don't invent a second one."
#
# Lives at the top level of GameState.state rather than inside
# state.combat -- Combat.exit_combat() tears combat down to fresh defaults on
# every fight's end, which would silently reset a player's pacing choice
# after every single fight if it lived there instead.
const MODES: PackedStringArray = ["normal", "quick"]
const DEFAULT_MODE := "normal"


static func pacing_mode() -> String:
	return GameState.state.get("combatPacingMode", DEFAULT_MODE)


static func set_pacing_mode(mode: String) -> void:
	if not MODES.has(mode):
		return
	GameState.state["combatPacingMode"] = mode
	EventBus.state_changed.emit()
