class_name PhoneApps
extends RefCounted

# 11-phone-os-shell ticket 07: roster-agnostic app registry for the phone
# home grid. Adding an app is adding one entry to apps() below -- the grid
# derives its fixed slot count/order directly from this list, never from
# which apps happen to be unlocked, so a slot never reflows when something
# unlocks (spec story 8).
#
# Seven apps exist today (ticket 09 added Save/Load, ticket 10 added
# Notifications). Any lock-gated app (e.g. Map, if it ever joins the grid)
# lands with its own ticket and the spec's separate "final app roster"
# ticket (Out of Scope: "final app roster ... decided in a later ticket").
# Every entry's locked Callable is a constant false for that reason -- the
# lock mechanism itself is proven by tests/test_phone_apps.gd exercising
# build_tile_configs() against a synthetic locked entry, independent of
# today's real (all-unlocked) roster.
#
# icon art is looked up from id via AppTile's ticket-02 asset contract
# (res://assets/icons/apps/<id>.png) -- id doubles as the icon reference,
# so there's no separate icon field here to fall out of sync with it.

static func apps() -> Array[Dictionary]:
	var unlocked := func(): return false
	return [
		{ "id": "messages", "label": "Messages", "locked": unlocked },
		{ "id": "notes", "label": "Notes", "locked": unlocked },
		{ "id": "factions", "label": "Factions", "locked": unlocked },
		{ "id": "ticker", "label": "The Ticker", "locked": unlocked },
		{ "id": "profile", "label": "Profile", "locked": unlocked },
		{ "id": "saveload", "label": "Save/Load", "locked": unlocked },
		{ "id": "notifications", "label": "Notifications", "locked": unlocked },
	]


# Pure transform: registry entries -> AppTile.configure()-ready dicts, in
# the same fixed order as `apps`. `badge_for` is injected (app_id -> bool)
# rather than read from GameState directly, so this is testable with a
# synthetic roster and a stub predicate, same standalone-component reasoning
# tests/test_app_tile.gd documents for AppTile itself.
static func build_tile_configs(apps_list: Array[Dictionary], badge_for: Callable) -> Array[Dictionary]:
	var configs: Array[Dictionary] = []
	for app in apps_list:
		var app_id: String = app["id"]
		var locked_check: Callable = app["locked"]
		configs.append({
			"id": app_id,
			"label": app["label"],
			"locked": locked_check.call(),
			"badge": badge_for.call(app_id),
		})
	return configs
