class_name DebugTools
extends RefCounted

# Static funcs backing the Debug phone app (scenes/phone_apps/debug_app.gd's
# build()). Screens never mutate state directly, so these one-line
# writes exist as systems. Only reachable once flags.debugStartUsed is set
# (gated in PhoneApps.apps()), so nothing here re-checks that flag.


static func add_cash(amount: int) -> void:
	GameState.state["player"]["cash"] += amount
	EventBus.state_changed.emit()


static func add_calc(ore_type: String, amount: int) -> void:
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	orichalchum[ore_type] = orichalchum.get(ore_type, 0) + amount
	EventBus.state_changed.emit()
