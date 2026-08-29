class_name DebugTools
extends RefCounted

# 01-debug-app: static funcs backing the Debug phone app (scenes/screens/
# phone.gd's _build_debug()). Screens never mutate state directly, so these
# two adjusters exist as systems even though each is a one-line write --
# same SCREENS/SYSTEMS split every other phone app in this file follows.
# The app itself is only ever reachable on a save started via the title
# screen's Debug Start button (flags.debugStartUsed, gated in PhoneApps.
# apps()), so nothing here re-checks that flag.


static func add_cash(amount: int) -> void:
	GameState.state["player"]["cash"] += amount
	EventBus.state_changed.emit()


static func add_calc(ore_type: String, amount: int) -> void:
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	orichalchum[ore_type] = orichalchum.get(ore_type, 0) + amount
	EventBus.state_changed.emit()
