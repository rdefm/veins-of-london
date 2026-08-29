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
	var list: Array[Dictionary] = [
		{ "id": "notes", "label": "Notes", "locked": unlocked },
		{ "id": "factions", "label": "Factions", "locked": unlocked },
		{ "id": "ticker", "label": "The Ticker", "locked": unlocked },
		{ "id": "profile", "label": "Profile", "locked": unlocked },
		{ "id": "saveload", "label": "Save/Load", "locked": unlocked },
		{ "id": "notifications", "label": "Notifications", "locked": unlocked },
		# bugfixes-38: display-only cash balance + transaction log, branded
		# in-fiction as "Reynard's" (human-picked from the ticket's PROSE-
		# REVIEW candidates) -- the tile label doubles as the in-app heading,
		# same convention "ticker"/"The Ticker" already uses.
		{ "id": "bank", "label": "Reynard's", "locked": unlocked },
		# 84-contacts-retire-messages-tile: no top-level "messages" entry
		# here any more -- every contact (Archie/James included, since
		# 83-contacts-archie-james-sms-port) has its own thread reachable
		# from the `contacts` tile below via ContactCards.build_messages_
		# button(), so the conversation-list app this tile used to open is
		# gone rather than duplicating what Contacts already does.
		# bugfixes-78: restores the only entry point into the standalone
		# `contacts` screen (Archie/James's bespoke SMS threads + James's
		# job offers) -- the ticket-11 dock restructure and ticket-07
		# phone grid replaced the old card-list navigation without
		# carrying one forward, leaving contacts.gd unreachable from a
		# live game (its only inbound navigation was archie_motion.json/
		# james_motion.json's own on_complete, which points back at
		# itself). Unlocked from game start, same as every other non-vfl
		# tile -- metArchie flips true immediately post-intro, before the
		# grid is ever shown, and contacts.gd has no flag gate on
		# rendering Archie's card (only James's card is conditional).
		{ "id": "contacts", "label": "Contacts", "locked": unlocked },
		# bugfixes-39: cosmetic rebrand of the dock's Map entry point, not a
		# real app -- tapping it navigates straight to Nav.go_to("map")
		# (scenes/screens/phone.gd's _on_app_tile_pressed special-cases
		# "vfl" the same way NavBar._on_tile_pressed special-cases its own
		# Map slot) rather than opening as a PhoneNav app, so this tile has
		# no in-app heading to double as. "VfL" is the fictional transit
		# authority's brand initialism (parodying TfL); PROSE-REVIEW: the
		# spelled-out full name for flavour text/tooltips elsewhere is
		# pending human sign-off, candidate "Veins for London" per the
		# ticket. Locked predicate mirrors NavBar._map_locked() exactly --
		# same flag, same source of truth, since this dock lock is enforced
		# at the UI layer only and Nav.go_to("map") itself has no gate.
		{ "id": "vfl", "label": "VfL", "locked": func(): return not GameState.state["flags"]["archiePartnerSeen"] },
	]

	# 01-debug-app: only present on a save started via the title screen's
	# Debug Start button -- never merely locked (a locked tile still renders
	# with its padlock overlay), genuinely absent from the grid on a normal
	# New Game, per the ticket's visibility gate.
	if GameState.state["flags"]["debugStartUsed"]:
		list.append({ "id": "debug", "label": "Debug", "locked": unlocked })

	return list


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
