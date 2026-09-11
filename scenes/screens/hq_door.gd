class_name HqDoorScreen
extends Control

# hq-diorama ticket 05, docs/hq-diorama-vision.md §8: the front door zone's
# diegetic destination -- installed/empty security slots (lock, cameras,
# reinforcedDoor, alarm, guard, ward -- GameData.HOME_SECURITY, generic, no
# hardcoded roster, same reasoning hq_floorplan.gd gives for rooms).
# Reached from hq.gd's "security" zone tap; Back returns to "hq" specifically.
#
# §3.3: full-bleed, same as hq_floorplan.gd -- registered in scenes/Main.gd's
# NAV_HIDDEN_SCREENS (the bottom dock only; the persistent TopBar/
# notification board stays up here too, per §3.3's field-kit-chrome ticket
# 02 amendment).
#
# §3.1 groups the door with the floorplan/bench as "diegetic", explicitly
# against "list-style panels" (Train, vein list) -- same as hq_floorplan.gd's
# own comment records for Rooms, a first pass here was a single-column card
# list (the old hq_security_list modal's own shape, just full-bleed), and a
# review pass flagged it the same way ticket 04's own first pass was flagged:
# reading like the list-style bucket §3.1 says the door is unlike. Rendered
# instead as the same 2-column GRID of slot tiles hq_floorplan.gd settled on
# -- side-by-side fixture points rather than a stacked settings list -- still
# with zero baked art: no hq_visuals.json manifest entry exists for this view,
# because the slot roster is data-driven off GameData.HOME_SECURITY rather
# than a fixed pixel-art layout. TILE_MIN_WIDTH/TILE_LABEL_MAX_WIDTH mirror
# hq_floorplan.gd's own constants for the same reason theirs exist: keep each
# tile's text wrapping inside its own column instead of UI.label()'s normal
# full-text-width reservation forcing the grid wider than the 390px screen.
#
# Content (security slots + Home.add_security() calls) is moved verbatim
# from modal_layer.gd's deleted "hq_security_list" modal (hq-diorama ticket
# 02) -- every system call unchanged, per the vision doc's §2 "Out" list.
# Only the rendering shape (grid of tiles vs. single-column modal cards) and
# chrome (full-bleed screen + Back button instead of a modal card + Close)
# are new.
#
# Hostile-door state (§8's "while a raid is pending, the door goes hostile
# and tapping it opens Defend rather than the security list") is entirely
# hq.gd's own job: it never navigates here while Home.has_pending_raid() is
# true (see hq.gd's _on_zone_tapped()), so this screen has no raid-aware
# branching of its own to test.
#
# PROSE-REVIEW: "Security" heading is new copy; everything else (security
# names/descriptions, "Installed"/"Locked") carries over unchanged from the
# old modal.

const GRID_COLUMNS := 2

# Screen is 390px logical wide; margin(16)*2 + grid h_separation(8) leaves
# 350px for 2 columns -- 160 each plus a little slack to expand into. Same
# figure hq_floorplan.gd's own TILE_MIN_WIDTH uses, for the same reason.
const TILE_MIN_WIDTH := 160.0

# Narrower than UI.label()'s own MAX_LABEL_TEXT_WIDTH (220) -- a security
# description at that width alone would force a grid column wider than the
# tile has room for. Labels autowrap word-smart regardless of their
# reserved minimum, so clamping this down just makes long text wrap onto
# more lines instead of blowing out the column.
const TILE_LABEL_MAX_WIDTH := 130.0


# "guard" is never appended to home["security"] (Home.add_security()'s own
# special case for it), so it wouldn't otherwise count towards "installed"
# totals once bought -- this adds it back in exactly once, whatever the
# stack count.
static func _installed_count(home: Dictionary) -> int:
	var count: int = home["security"].size()
	if Home.get_guard_count() > 0:
		count += 1
	return count


func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in get_children():
		child.queue_free()

	var sc := UI.scroll_container()
	add_child(sc)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	# field-kit-chrome ticket 02 made the persistent TopBar/notification
	# board visible on this screen too without adding UI.top_bar_clearance()
	# back into this margin -- the board now overlays this heading rather
	# than the heading reserving room for it; repositioning is left to a
	# follow-up, same deferral hq_floorplan.gd's own margin notes.
	margin.add_theme_constant_override("margin_top", int(UI.safe_area_top_inset()) + 16)
	margin.add_theme_constant_override("margin_bottom", int(UI.safe_area_bottom_inset()) + 16)
	sc.add_child(margin)

	var content := UI.vbox(8)
	margin.add_child(content)

	content.add_child(UI.back_button("hq"))

	var home: Dictionary = GameState.state["home"]
	content.add_child(UI.heading("Security (%d/%d)" % [_installed_count(home), GameData.HOME_SECURITY.size()]))

	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)

	for security_id in GameData.HOME_SECURITY.keys():
		grid.add_child(_build_security_slot(security_id))


# A narrow-width label for use inside a grid tile -- see TILE_LABEL_MAX_WIDTH
# above for why this clamps rather than using UI.label()/muted_label() bare.
func _tile_label(text: String, muted: bool = false) -> Label:
	var l: Label = UI.muted_label(text) if muted else UI.label(text)
	l.custom_minimum_size.x = minf(l.custom_minimum_size.x, TILE_LABEL_MAX_WIDTH)
	return l


# "guard" stacks with no upper limit (Home.add_security() never blocks it on
# "already installed" -- see Home.GUARD_SECURITY_ID), so unlike every other
# slot here its buy button stays live past the first purchase, with a ×N
# count in place of the static "Installed" line.
func _build_security_slot(security_id: String) -> Control:
	var home: Dictionary = GameState.state["home"]
	var sec: Dictionary = GameData.HOME_SECURITY[security_id]
	var order: Array = GameData.HOME_TIER_ORDER
	var available: bool = order.find(home["tier"]) >= order.find(sec["minTier"])

	var discount: float = 0.7 if GameState.state["flags"]["securityContactUnlocked"] else 1.0
	var adj_cost: int = GameState.round_epsilon(sec["cost"] * discount)

	var stackable: bool = security_id == Home.GUARD_SECURITY_ID
	var count: int = Home.get_guard_count() if stackable else 0
	var installed: bool = count > 0 if stackable else home["security"].has(security_id)
	var label: String = sec["name"] if count == 0 else "%s ×%d" % [sec["name"], count]

	var c := UI.card()
	c["panel"].custom_minimum_size.x = TILE_MIN_WIDTH
	c["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var prefix := "✅ " if installed else ("🔒 " if not available else "")
	c["content"].add_child(_tile_label(prefix + label))
	var desc: String = sec["description"]
	if not available:
		desc += " Requires %s." % GameData.HOME_TIERS[sec["minTier"]]["name"]
	c["content"].add_child(_tile_label(desc, true))

	if not available:
		c["content"].add_child(_tile_label("Locked", true))
	elif installed and not stackable:
		c["content"].add_child(_tile_label("Installed", true))
	else:
		var b := UI.button("£%d" % adj_cost, func(): Home.add_security(security_id))
		b.disabled = GameState.state["player"]["cash"] < adj_cost
		c["content"].add_child(b)

	return c["panel"]
