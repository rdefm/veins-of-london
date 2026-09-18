class_name PhoneApps
extends RefCounted

# Roster-agnostic app registry for the phone home grid. Adding an app is
# adding one entry to apps() below — the grid derives its fixed slot
# count/order from this list, never from which apps happen to be unlocked,
# so a slot never reflows when something unlocks. Every entry's locked
# Callable is a constant false except "vfl"; the lock mechanism itself is
# proven by tests/test_phone_apps.gd against a synthetic locked entry.
# Icon art is looked up from id (res://assets/icons/apps/<id>.png), so
# there's no separate icon field to fall out of sync.

static func apps() -> Array[Dictionary]:
	var unlocked := func(): return false
	var list: Array[Dictionary] = [
		{ "id": "alarms", "label": "Alarms", "locked": unlocked },
		# PROSE-REVIEW: BizBrief / Morning Brief.
		{ "id": "bizbrief", "label": "BizBrief", "locked": unlocked },
		{ "id": "notes", "label": "Notes", "locked": unlocked },
		{ "id": "factions", "label": "Factions", "locked": unlocked },
		{ "id": "ticker", "label": "The Ticker", "locked": unlocked },
		{ "id": "profile", "label": "Profile", "locked": unlocked },
		{ "id": "saveload", "label": "Save/Load", "locked": unlocked },
		{ "id": "notifications", "label": "Notifications", "locked": unlocked },
		# Display-only cash balance + transaction log; brand name doubles as
		# the in-app heading, same convention as "ticker"/"The Ticker".
		{ "id": "bank", "label": "Reynard's", "locked": unlocked },
		# HQ tier stats/upgrade, a parody property portal (docs/hq-diorama-vision.md §7).
		# PROSE-REVIEW: "Harrow's" pending human sign-off.
		{ "id": "property", "label": "Harrow's", "locked": unlocked },
		# Entry point into the standalone `contacts` screen (Archie/James's
		# SMS threads + James's job offers). Unlocked from game start, like
		# every other non-vfl tile — metArchie flips true immediately
		# post-intro, before the grid is ever shown.
		{ "id": "contacts", "label": "Contacts", "locked": unlocked },
		# Cosmetic rebrand of the dock's Map entry point, not a real app —
		# tapping it navigates straight to Nav.go_to("map") instead of
		# opening as a PhoneNav app. "VfL" parodies TfL; PROSE-REVIEW: the
		# spelled-out full name is pending human sign-off. Locked predicate
		# mirrors NavBar._map_locked(); Nav.go_to("map") itself has no gate.
		{ "id": "vfl", "label": "VfL", "locked": func(): return not GameState.state["flags"]["archiePartnerSeen"] },
	]

	# Only present on a save started via Debug Start — never merely locked,
	# genuinely absent from the grid on a normal New Game.
	if GameState.state["flags"]["debugStartUsed"]:
		list.append({ "id": "debug", "label": "Debug", "locked": unlocked })

	return list


# Pure transform: registry entries -> AppTile.configure()-ready dicts, in
# the same fixed order as `apps`. `badge_for` (app_id -> bool) is injected
# rather than read from GameState, so this is testable with a synthetic
# roster and a stub predicate.
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
