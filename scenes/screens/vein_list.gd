class_name VeinListScreen
extends Control

# vein-growth-state ticket 09 (spec §6.2): the vein-portfolio list, reachable
# two ways -- scoped to a district from the Map tab's district bubble ("List
# view", systems/district_bubble.gd's LIST_ID), and scoped to every district
# from HQ's Vein Station room ("View all veins", scenes/screens/hq.gd).
# state.veinListNav (GameState.gd) carries which of those two opened it, plus
# an optional band filter; this screen only ever reads it and calls
# VeinList's system functions (systems/vein_list.gd) -- same one-way-data-flow
# split every other vein-facing surface in this feature already draws (the
# Map tab's site/vein sheet, station_bubble.gd's bubble).
#
# Deviates from the PRD's §6.2 default proposal (a standalone Phone app) --
# confirmed in review: the district bubble + HQ Vein Station room already
# cover "reachable from where the player already is" without a third nav
# surface, so this screen carries no PhoneNav.APPS entry.

var _content: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	var nav: Dictionary = GameState.state["veinListNav"]
	var district_id: Variant = nav.get("districtId")
	var band_filter: Variant = nav.get("bandFilter")

	_content.add_child(UI.back_button(nav.get("originScreen", "map")))
	_content.add_child(UI.heading(_title(district_id)))
	_content.add_child(_build_band_filter_row(band_filter))

	var veins := VeinList.veins(district_id, band_filter)
	if veins.is_empty():
		_content.add_child(UI.muted_label("No veins match this filter." if band_filter != null else "No veins here yet."))
		return

	for vein in veins:
		_content.add_child(_build_vein_row(vein))


func _title(district_id: Variant) -> String:
	if district_id == null:
		return "All veins"
	return GameData.DISTRICTS[district_id]["name"]


# Sort/filter, minimum band (ticket 09) -- one tap narrows the list to a
# single band ("what needs me this week"), a second tap on the highlighted
# (disabled) button has no effect, matching map_controls.gd's own
# _build_filter_list disabled-means-active convention.
func _build_band_filter_row(active_band: Variant) -> Control:
	var row := UI.hflow()

	var all_button := UI.button("All", func(): VeinListNav.set_band_filter(null))
	all_button.disabled = active_band == null
	row.add_child(all_button)

	for band in GameData.VEIN_GROWTH["bands"]:
		var band_id: String = band["id"]
		var b := UI.button(band["label"], func(): VeinListNav.set_band_filter(band_id))
		b.disabled = active_band == band_id
		row.add_child(b)

	return row


func _build_vein_row(vein: Dictionary) -> Control:
	var c := UI.card()
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var district: Dictionary = GameData.DISTRICTS[vein["district"]]
	var tier: String = vein.get("hospitability", {}).get("tier", "fair")
	var band: Dictionary = Cultivating.growth_band(vein)
	var vein_ceiling: int = Cultivating.ceiling(vein)
	var collapsed: bool = band["id"] == "collapsed"

	c["content"].add_child(UI.symbol_row(["%s — " % district["name"], { "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(vein["oreType"]) }, " %s" % ore["name"]], { "heading_size": 14 }))
	c["content"].add_child(UI.muted_label("%s terroir · 🔒 %s" % [String(tier).capitalize(), Cultivating.security_label(vein)]))

	c["content"].add_child(UI.muted_label("Growth: %d/%d — %s" % [vein["growth"], vein_ceiling, band["label"]]))
	c["content"].add_child(UI.bar(vein["growth"], vein_ceiling))

	# Same danger-coloured, never-doing-badly-confused treatment as the map
	# sheet's own _build_vein_action_card -- see Cultivating.
	# COLLAPSED_VEIN_WARNING's own comment for why this text lives there once
	# instead of being redrafted per screen.
	if collapsed:
		c["content"].add_child(UI.tinted_label(Cultivating.COLLAPSED_VEIN_WARNING, MapStyle.DANGER_COLOUR))
	else:
		c["content"].add_child(UI.muted_label(Cultivating.days_to_wall_text(vein)))

	# vein-growth-state ticket 06/09: read-only summary of the vein's Vein
	# Station assignment/target, if any (ticket 09's own row-content checklist
	# item) -- Rooms.vein_station_target_text() is shared with the map sheet's
	# own assignment row (scenes/screens/map.gd) so the two can't drift on the
	# same lookup. The +5/-5/Unassign controls stay on the map sheet (Rooms'
	# "wherever assignment currently happens" surface); this list only shows
	# what's currently set, same split the station bubble draws for its own
	# Manage label.
	var station_text: Variant = Rooms.vein_station_target_text(vein["id"])
	if station_text != null:
		c["content"].add_child(UI.muted_label(String(station_text)))

	c["content"].add_child(_build_actions_row(vein))

	return c["panel"]


# One row per VeinList.actions_for(vein) entry -- Cultivate / Prune (light) /
# Prune (hard) / Manage, in that order, gated exactly as VeinList.actions_for
# computes it (never recomputed here) so this list can't drift from the
# system layer's own rule.
func _build_actions_row(vein: Dictionary) -> Control:
	var actions := UI.hflow()
	for gate in VeinList.actions_for(vein):
		actions.add_child(_build_action_button(vein, gate))
	return actions


func _build_action_button(vein: Dictionary, gate: Dictionary) -> Control:
	var vein_id: String = vein["id"]
	var option_id: String = gate["id"]

	match option_id:
		VeinList.CULTIVATE_ID:
			var at_ceiling: bool = vein["growth"] >= Cultivating.ceiling(vein)
			var label := "Vein at ceiling" if at_ceiling else UI.format_block_cost_label("Cultivate", 1)
			return UI.action_button(label, func(): VeinList.apply_option(option_id, vein_id), gate["disabled"], gate["reason"])
		VeinList.PRUNE_LIGHT_ID:
			return _build_prune_button("Prune (light)", vein, GameData.VEIN_GROWTH["pruneLightDepth"], gate)
		VeinList.PRUNE_HARD_ID:
			return _build_prune_button("Prune (hard)", vein, GameData.VEIN_GROWTH["pruneHardDepth"], gate)
		VeinList.SELL_ID:
			var price: int = VeinTrade.quote(vein)
			return UI.button("Sell — £%d" % price, func(): VeinList.apply_option(option_id, vein_id))
		_:  # MANAGE_ID
			return UI.button("Manage", func(): VeinList.apply_option(option_id, vein_id))


# Ticket 08's rule, reused verbatim: the projected yield is shown on the
# button before it's pressed (Cultivating.prune_yield), same as the map
# sheet's own _build_prune_button and the station bubble's prune labels.
func _build_prune_button(action_label: String, vein: Dictionary, depth: int, gate: Dictionary) -> Control:
	var vein_id: String = vein["id"]
	var option_id: String = gate["id"]
	var projected: int = Cultivating.prune_yield(vein, depth)
	var label_text := "%s · %d ore" % [UI.format_block_cost_label(action_label, 1), projected]
	return UI.action_button(label_text, func(): VeinList.apply_option(option_id, vein_id), gate["disabled"], gate["reason"])
