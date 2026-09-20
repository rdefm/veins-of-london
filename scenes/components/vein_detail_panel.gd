class_name VeinDetailPanel
extends RefCounted

# Larger vein detail panel: opened by tapping the compact map bubble's info
# area (map.gd's mapNav.selectedVeinId) in place of the site sheet's Manage
# view, for a player-owned vein. Shows yield, drift/upkeep, development
# chance, raid risk, and the vein's full action set for the ONE tapped vein.
#
# Earned level, the player's own Cultivating skill, and condition are kept
# in separate, separately-labelled rows -- condition is never called a
# "cultivation level" anywhere here. Reuses VeinBubble's level-segment row,
# condition bar, and eligibility/raid cue row (build_level_row/
# build_condition_column/build_cue_row) so the compact and detail views
# never drift apart on those conventions.
#
# Pure builder, same shape as map.gd's own _build_site_sheet: map.gd
# rebuilds this from _refresh() on every state_changed, so an action button
# here just calls straight into StationBubble/Cultivating/Raiding and lets
# the normal state_changed -> _refresh() loop redraw with the new numbers
# (no local "chooser open" state to track, unlike the compact bubble).


const SHEET_HEIGHT := 560.0


static func build(vein: Dictionary) -> Control:
	var root := Control.new()
	UI.anchor_full_rect(root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	UI.anchor_full_rect(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
			MapNav.close_vein_detail()
	)
	root.add_child(dim)

	var card := PanelContainer.new()
	UI.anchor_bottom_wide(card)
	card.offset_top = -SHEET_HEIGHT
	card.offset_bottom = 0
	root.add_child(card)

	var scroll := UI.scroll_container()
	card.add_child(scroll)
	var content := UI.vbox(10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	content.add_child(_build_header(vein))
	content.add_child(_build_identity_section(vein))
	content.add_child(_build_drift_section(vein))
	content.add_child(_build_development_section(vein))
	content.add_child(_build_raid_section(vein))
	var collapse_row: Variant = _build_collapse_warning(vein)
	if collapse_row != null:
		content.add_child(collapse_row)
	content.add_child(_build_actions_section(vein))
	content.add_child(UI.button("Close", func(): MapNav.close_vein_detail()))

	return root


static func _build_header(vein: Dictionary) -> Control:
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var district: Dictionary = GameData.DISTRICTS[vein["district"]]
	var col := UI.vbox(2)
	col.add_child(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(vein["oreType"]) }, " %s · %s" % [ore["name"], district["name"]]], { "heading_size": 18 }))
	col.add_child(UI.muted_label(vein["location"]))
	return col


# Level (earned, per-vein) and condition reuse VeinBubble's own builders so
# the segments/slim-bar conventions never diverge between the two surfaces;
# the player's Cultivating skill is a separate character stat and gets its
# own row so the three can't be mistaken for one another.
static func _build_identity_section(vein: Dictionary) -> Control:
	var col := UI.vbox(6)
	col.add_child(VeinBubble.build_level_row(vein))
	# PROSE-REVIEW: drafted against CONTENT-GUIDE.md.
	col.add_child(UI.muted_label("Your Cultivating skill: %d (a character stat, not this vein's level)" % GameState.state["player"]["cultivatingSkill"]))
	col.add_child(VeinBubble.build_condition_column(vein))

	var vein_ceiling: int = Cultivating.ceiling(vein)
	if vein_ceiling > GameData.VEIN_GROWTH["ceiling"]:
		# PROSE-REVIEW
		col.add_child(UI.muted_label("Wild-ceiling vein -- condition can run past 100, up to %d." % vein_ceiling))

	var cues: Variant = VeinBubble.build_cue_row(vein)
	if cues != null:
		col.add_child(cues)

	return col


static func _build_drift_section(vein: Dictionary) -> Control:
	var col := UI.vbox(2)
	col.add_child(UI.muted_label("Drift"))
	col.add_child(UI.label(Cultivating.days_to_wall_text(vein)))

	var level: int = vein.get("level", 1)
	var vg: Dictionary = GameData.VEIN_GROWTH
	# PROSE-REVIEW: same "expected drift" range days_to_wall() estimates from -- re-rolled nightly, not a fixed rate.
	col.add_child(UI.muted_label("Moves roughly %d-%d pts/night toward that wall once it's off neutral." % [level + vg["driftRandomMin"], level + vg["driftRandomMax"]]))

	return col


# Development chance uses the CURRENT stored streak (not streak-1): the
# nightly tick advances the streak before rolling (_advance_development_
# streak then _roll_level_up in the same pass), so the roll that would run
# tonight already reads streak+1 -- levelUpChancePerDay * ((streak+1)-1) is
# just levelUpChancePerDay * streak. This is a same estimate framing as
# days_to_wall(): correct if the vein stays eligible until tonight's tick.
static func _build_development_section(vein: Dictionary) -> Control:
	var col := UI.vbox(2)
	col.add_child(UI.muted_label("Development"))

	var cap: int = Cultivating.level_cap(vein)
	var level: int = vein.get("level", 1)
	var threshold: int = GameData.VEIN_GROWTH["developmentThreshold"]

	if level >= cap:
		# PROSE-REVIEW: R§3.4 -- a maxed vein never rolls again, but stays harvestable/raid-exposed.
		col.add_child(UI.label("Max level (%d/%d) -- this vein won't develop any further. Still harvestable, and raid exposure still applies." % [level, cap]))
	elif vein["growth"] < threshold:
		# PROSE-REVIEW
		col.add_child(UI.muted_label("Not developing -- needs condition %d+ to start a streak." % threshold))
	else:
		var streak: int = vein.get("developmentStreak", 0)
		var chance: float = minf(1.0, GameData.VEIN_GROWTH["levelUpChancePerDay"] * streak)
		# PROSE-REVIEW
		col.add_child(UI.label("Developing -- day %d of the streak, about %d%% to level up tonight." % [streak + 1, roundi(chance * 100)]))

	return col


static func _build_raid_section(vein: Dictionary) -> Control:
	var col := UI.vbox(2)
	col.add_child(UI.muted_label("Raid risk"))

	var threshold: int = GameData.VEIN_GROWTH["developmentThreshold"]
	# PROSE-REVIEW
	var exposure_text: String = "Raised -- condition is %d+." % threshold if vein["growth"] >= threshold else "Standard -- condition is below %d." % threshold
	col.add_child(UI.label(exposure_text))
	col.add_child(UI.muted_label("%s -- resist %d" % [Cultivating.security_label(vein), Cultivating.vein_raid_resist(vein)]))

	var vein_id: String = vein["id"]
	if Raiding.has_pending_defend(vein_id):
		# PROSE-REVIEW: matches map.gd's own vein-sheet defend copy.
		col.add_child(UI.tinted_label("Under raid — defend now or lose it at the next tick.", MapStyle.DANGER_COLOUR))
		col.add_child(UI.button("Defend", func(): Raiding.trigger_defend(vein_id)))

	return col


# Distinct from the generic Cultivating.COLLAPSED_VEIN_WARNING text (which
# conflates both cases for the compact surfaces): a level-1 vein at 0 can
# vanish outright tonight (collapseChancePerDay roll), while a vein above
# level 1 just depletes one level and resets to neutral -- never rolls to
# vanish. The two must read as clearly different states.
static func _build_collapse_warning(vein: Dictionary) -> Variant:
	if vein["growth"] > 0:
		return null

	var level: int = vein.get("level", 1)
	if level <= 1:
		var pct: int = roundi(GameData.VEIN_GROWTH["collapseChancePerDay"] * 100)
		# PROSE-REVIEW: drafted against CONTENT-GUIDE.md §3.
		return UI.tinted_label("Empty at level 1 -- about %d%% chance to collapse and vanish tonight. Cultivate it to save it." % pct, MapStyle.DANGER_COLOUR)

	# PROSE-REVIEW
	return UI.tinted_label("Empty -- will deplete to level %d tonight instead of collapsing." % (level - 1), MapStyle.DANGER_COLOUR)


# Cultivate/Prune gating and dispatch go through StationBubble -- the same
# decision layer the compact bubble and site sheet both use -- so the three
# surfaces can never quietly disagree on when an action is disabled.
static func _build_actions_section(vein: Dictionary) -> Control:
	var stop: Dictionary = { "kind": "vein", "vein": vein, "owner": "player", "site": { "id": vein.get("siteId") } }
	var options: Array = StationBubble.station_options(stop)

	var col := UI.vbox(6)
	col.add_child(UI.muted_label("Actions"))

	var cultivate_opt: Dictionary = _find_option(options, StationBubble.CULTIVATE_ID)
	col.add_child(UI.action_button(_cultivate_label(vein, cultivate_opt["disabled"]), func(): StationBubble.apply_option(StationBubble.CULTIVATE_ID, stop), cultivate_opt["disabled"], cultivate_opt["reason"]))

	var light_opt: Dictionary = _find_option(options, StationBubble.PRUNE_LIGHT_ID)
	col.add_child(UI.action_button(_harvest_label("Harvest (light)", vein, GameData.VEIN_GROWTH["pruneLightDepth"], not light_opt["disabled"]), func(): StationBubble.apply_option(StationBubble.PRUNE_LIGHT_ID, stop), light_opt["disabled"], light_opt["reason"]))

	var hard_opt: Dictionary = _find_option(options, StationBubble.PRUNE_HARD_ID)
	col.add_child(UI.action_button(_harvest_label("Harvest (hard)", vein, GameData.VEIN_GROWTH["pruneHardDepth"], not hard_opt["disabled"]), func(): StationBubble.apply_option(StationBubble.PRUNE_HARD_ID, stop), hard_opt["disabled"], hard_opt["reason"]))

	col.add_child(_build_security_button(vein))
	col.add_child(_build_alarm_button(vein))

	return col


static func _find_option(options: Array, id: String) -> Dictionary:
	for opt in options:
		if opt["id"] == id:
			return opt
	return { "disabled": true, "reason": "" }


static func _cultivate_label(vein: Dictionary, disabled: bool) -> String:
	if vein["growth"] >= Cultivating.ceiling(vein):
		return "Cultivate -- vein at ceiling"
	var skill: int = GameState.state["player"]["cultivatingSkill"]
	# PROSE-REVIEW: an estimate range, same framing as the compact bubble's harvest preview.
	var base: String = "Cultivate -- roughly +%d to +%d condition (skill %d)" % [Cultivating.cultivate_min_gain(skill), Cultivating.cultivate_max_gain(skill), skill]
	return UI.format_block_cost_label(base, 1, not disabled)


static func _harvest_label(label_text: String, vein: Dictionary, depth: int, available: bool) -> String:
	var projected_yield: int = Cultivating.prune_yield(vein, depth)
	var resulting: int = Cultivating.prune_resulting_growth(vein, depth)
	var base: String = "%s -- %d ore, %d→%d" % [label_text, projected_yield, vein["growth"], resulting]
	return UI.format_block_cost_label(base, 1, available)


static func _build_security_button(vein: Dictionary) -> Control:
	var upgrade: Dictionary = Cultivating.next_security_upgrade(vein)
	var player: Dictionary = GameState.state["player"]
	var vein_id: String = vein["id"]

	var label_text: String = upgrade["label"] if upgrade["tierId"] == null else "Upgrade to %s" % upgrade["label"]
	var cost := { "label": label_text, "resource": "cash", "amount": upgrade["cost"] }

	var b := UI.button(UI.format_cost_label(cost, { "cash": player["cash"] }), func(): Cultivating.upgrade_vein_security(vein_id))
	b.disabled = player["cash"] < upgrade["cost"]
	return b


static func _build_alarm_button(vein: Dictionary) -> Control:
	var alarm_data: Dictionary = GameData.VEIN_ALARM[Cultivating.ALARM_UPGRADE_ID]
	if vein["alarmUpgrades"].has(Cultivating.ALARM_UPGRADE_ID):
		return UI.muted_label("%s: installed" % alarm_data["label"])

	var player: Dictionary = GameState.state["player"]
	var cost := { "label": "Install %s" % alarm_data["label"], "resource": "cash", "amount": alarm_data["cost"] }
	var vein_id: String = vein["id"]

	var b := UI.button(UI.format_cost_label(cost, { "cash": player["cash"] }), func(): Cultivating.add_alarm(vein_id))
	b.disabled = player["cash"] < alarm_data["cost"]
	return b
