class_name Events
extends RefCounted

# Event runner per R§3.9 (event rewind) and M0-T13's card/event schema,
# extended by M1-LONDON D5 with a "choice" card type: { type:"choice",
# label, speaker, text, choices:[{label, effects, result_text}] }. Picking
# a choice (choose()) applies its effects immediately and records
# result_text as a resolution card; the runner then behaves exactly like
# any other resolved card — Continue/advance() moves past it. Cards:
# { type, label, speaker, text }. Events: { id, cards, on_complete:
# [effect] }. state.event holds the runtime progress: { eventId,
# cardIndex, snapshots, choiceResults }.


# context (vein-raiding ticket 03): a raid's target site_id is only known
# at Raid-button-press time (a real site's runtime-generated id, never a
# static literal an event's own JSON could hardcode) -- carried here and
# read back by the raid ops' _event_site_id() below. Every other caller
# omits it; state.event.context is just {} for them, same as always.
static func start_event(event_id: String, context: Dictionary = {}) -> void:
	GameState.state["event"] = { "eventId": event_id, "cardIndex": 0, "snapshots": [], "choiceResults": {}, "context": context }
	Nav.go_to("event")


static func _event_def() -> Dictionary:
	var event_state: Dictionary = GameState.state["event"]
	return GameData.EVENTS[event_state["eventId"]]


# The card at the runner's current position — the one that's either
# awaiting a Continue tap or (for a "choice" card) awaiting a pick.
static func current_card() -> Dictionary:
	var event_state: Dictionary = GameState.state["event"]
	var cards: Array = _event_def()["cards"]
	return cards[event_state["cardIndex"]]


# True once the current card is a "choice" card whose pick hasn't been
# made yet — the runner must not advance() past it via Continue.
static func is_awaiting_choice() -> bool:
	var event_state: Dictionary = GameState.state["event"]
	var card: Dictionary = current_card()
	if card["type"] != "choice":
		return false
	return not event_state["choiceResults"].has(str(event_state["cardIndex"]))


# All cards revealed so far (index 0..cardIndex inclusive) — the event
# screen renders this whole list so new cards push older ones up rather
# than replacing them. A resolved "choice" card gets its picked
# result_text spliced in right after it as a synthetic resolution card,
# without consuming a cardIndex slot of its own.
static func revealed_cards() -> Array:
	var event_state: Dictionary = GameState.state["event"]
	var cards: Array = _event_def()["cards"]
	var choice_results: Dictionary = event_state["choiceResults"]

	var result: Array = []
	for i in range(event_state["cardIndex"] + 1):
		result.append(cards[i])
		if choice_results.has(str(i)):
			result.append({ "type": "resolution", "label": null, "speaker": null, "text": choice_results[str(i)] })
	return result


static func is_last_card() -> bool:
	var event_state: Dictionary = GameState.state["event"]
	var cards: Array = _event_def()["cards"]
	return event_state["cardIndex"] >= cards.size() - 1


static func can_rewind() -> bool:
	var event_state = GameState.state["event"]
	if event_state == null or event_state["snapshots"].is_empty():
		return false
	return Crafting.inventory_qty("rewind") > 0 or _find_equipped_rewind_device_with_charge() != null


# Continue: snapshots full state, then either reveals the next card or
# (on the last card) runs on_complete and clears state.event. rewind()
# below relies on _snapshot_before_mutation()'s emptying trick: it no
# longer trusts a popped snapshot's own (now always-empty)
# `event.snapshots` field, and instead carries the real, already-trimmed
# live stack forward explicitly.
static func advance() -> void:
	if is_awaiting_choice():
		return  # a "choice" card must be resolved via choose() before Continue works

	_snapshot_before_mutation()

	var event_state: Dictionary = GameState.state["event"]
	if is_last_card():
		var on_complete: Array = _event_def().get("on_complete", [])
		GameState.state["event"] = null
		apply_effects(on_complete)
		SaveManager.autosave()  # R§6: autosave on event completion
	else:
		event_state["cardIndex"] += 1
		EventBus.state_changed.emit()


# Resolves the current "choice" card: applies the picked choice's effects,
# then records its result_text so revealed_cards() shows it as a
# resolution card. Does not itself advance cardIndex — same as any other
# card, the player still taps Continue to move past the resolution.
static func choose(choice_index: int) -> void:
	if not is_awaiting_choice():
		return

	_snapshot_before_mutation()

	var event_state: Dictionary = GameState.state["event"]
	var card: Dictionary = current_card()
	var choice: Dictionary = card["choices"][choice_index]

	event_state["choiceResults"][str(event_state["cardIndex"])] = choice["result_text"]
	apply_effects(choice.get("effects", []))


# Shared by advance() and choose() — see advance()'s original comment
# (still accurate) on why state.event.snapshots must be emptied before
# the deep copy: it lives inside the tree being copied, and left in
# place would embed every prior snapshot inside the new one, compounding
# into exponential blowup across a long event.
static func _snapshot_before_mutation() -> void:
	var event_state: Dictionary = GameState.state["event"]
	var stack: Array = event_state["snapshots"]
	event_state["snapshots"] = []
	var snap: Dictionary = GameState.deep_copy(GameState.state)
	event_state["snapshots"] = stack
	Snapshots.push("event", stack, snap)


static func rewind() -> Dictionary:
	if not can_rewind():
		return { "ok": false, "reason": "No rewind available." }

	var event_state: Dictionary = GameState.state["event"]
	var has_consumable: bool = Crafting.inventory_qty("rewind") > 0
	var device = _find_equipped_rewind_device_with_charge()
	var device_id = device["id"] if device != null else null

	var stack: Array = event_state["snapshots"]
	var snap: Dictionary = Snapshots.pop_newest(stack)
	GameState.state = snap
	# snap's own event.snapshots is always [] (see advance()) — carry the
	# real, already-popped live stack forward instead of trusting that.
	GameState.state["event"]["snapshots"] = stack

	if has_consumable:
		Crafting.inventory_remove("rewind", 1)
	else:
		Devices.activate(device_id)

	Notify.push("⟲ Time unspools. The moment resets. Only you remember.")
	EventBus.state_changed.emit()
	return { "ok": true }


static func _find_equipped_rewind_device_with_charge() -> Variant:
	var player: Dictionary = GameState.state["player"]
	var device_id = player["equipment"]["device"]
	if device_id == null:
		return null
	for d in player["devicesCompleted"]:
		if d["id"] == device_id:
			var dt: Dictionary = GameData.DEVICES[d["type"]]
			if dt["effect"] == "rewind" and d["chargesUsedToday"] < d["chargesPerDay"]:
				return d
			return null
	return null


# ── effect ops ──────────────────────────────────────────────────────────

static func apply_effects(effects: Array) -> void:
	for effect in effects:
		_apply_one(effect)
	EventBus.state_changed.emit()


static func _apply_one(effect: Dictionary) -> void:
	match effect["op"]:
		"set_flag":
			GameState.state["flags"][effect["flag"]] = effect["value"]
		"add":
			_apply_add(effect["path"], effect["value"])
		"add_ore":
			var ore: Dictionary = GameState.state["player"]["orichalchum"]
			ore[effect["type"]] = ore.get(effect["type"], 0) + effect["qty"]
		"add_item":
			# ticket 64: an event-granted item wasn't crafted at any skill/
			# refine tier -- files under the "0" untiered bucket, same as a
			# Guild purchase (Economy.execute_guild_purchase).
			Crafting.inventory_add(effect["item"], 0, effect["qty"])
		"relation":
			Contacts.award_relation(effect["contact"], effect["value"])
		"grant_vein_with_site":
			_grant_vein_with_site(effect["vein"])
		"set_screen":
			# Ticket 12: content authored "home" as the landing screen before
			# that screen was retired -- data/events/*.json now targets "phone"
			# instead, which needs phoneNav reset to its home view too, same as
			# every other route-to-phone-home call site.
			if effect["screen"] == "phone":
				PhoneNav.route_home()
			else:
				Nav.go_to(effect["screen"])
		"notify":
			Notify.push(effect["text"])
		"set_stage":
			GameState.state["flags"]["tutorialStage"] = effect["value"]
		"start_home_raid_combat":
			Combat.start_home_raid_combat()
		"chance":
			if Rng.chance(effect["p"]):
				apply_effects(effect.get("on_success", []))
			else:
				apply_effects(effect.get("on_fail", []))
		"start_street_mugging":
			Combat.start_street_mugging()
		"npc_claim_best_unclaimed_site":
			Sites.npc_claim_best_unclaimed_site(GameState.state["world"]["currentDistrict"])
		"lose_time_block":
			if not TimeSystem.is_time_exhausted():
				TimeSystem.advance_time_block()
		"tutorial_cultivate":
			_tutorial_cultivate()
		"stealth_check":
			_stealth_check(effect)
		"start_raid_combat":
			_start_raid_combat(effect)
		"claim_raid_vein":
			Raiding.claim_vein(_event_site_id(effect))
		"loot_raid_vein":
			Raiding.loot_vein(_event_site_id(effect), _event_caught(effect))


# Generic path+value combine: adds when both the existing value and the
# incoming one are numeric (e.g. player.cash), otherwise assigns outright
# (e.g. contacts.james.unlocked = true, which can't be "added" to a bool).
# world.archieChatUnlockDay is a special case straight from the HTML
# (`gameState.world._archieChatUnlockDay = gameState.world.day + 1`): it
# starts null, so "add" there means "today + value", not "null + value".
static func _apply_add(path: String, value: Variant) -> void:
	var current: Variant = GameState.read_path(path)
	var new_value: Variant
	if _is_number(current) and _is_number(value):
		new_value = current + value
	elif current == null and path == "world.archieChatUnlockDay":
		new_value = GameState.state["world"]["day"] + value
	else:
		new_value = value
	_set_path(path, new_value)


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


static func _set_path(path: String, value: Variant) -> void:
	var parts: PackedStringArray = path.split(".")
	var current: Dictionary = GameState.state
	for i in range(parts.size() - 1):
		current = current[parts[i]]
	current[parts[parts.size() - 1]] = value


# M1-LONDON D7: the home-raid debrief's granted vein needs a matching
# player-claimed site on state.world.sites, or the Map tab shows a
# Whitechapel vein with no site backing it. Site tier/oreType/bonuses are
# derived from the vein template's own hospitability/oreType fields (same
# fields Sites.attempt_seed() would have produced), so the two stay in sync
# by construction rather than by two copies of "fair, no bonuses" agreeing.
static func _grant_vein_with_site(vein_template: Dictionary) -> void:
	var hospitability: Dictionary = vein_template.get("hospitability", { "tier": "fair", "bonuses": [] })
	var day: int = GameState.state["world"]["day"]

	var site: Dictionary = {
		"id": Sites.make_site_id(),
		"district": vein_template["district"],
		"tier": hospitability["tier"],
		"oreType": vein_template["oreType"],
		"bonuses": hospitability["bonuses"],
		"discoveredDay": day,
		"claimed": true,
		"factionVein": null,
		"hasNaturalVein": false,
		"slotIndex": Sites.next_slot_index(vein_template["district"]),
	}
	GameState.state["world"]["sites"].append(site)

	var vein: Dictionary = GameState.deep_copy(vein_template)
	vein["id"] = Cultivating.make_vein_id()
	vein["claimedOnDay"] = day
	vein["siteId"] = site["id"]
	vein["rampantDays"] = 0
	GameState.state["player"]["veins"].append(vein)


# M1-LONDON D6: archie_cultivation's closer — a forced, always-successful
# cultivate on the vein the home-raid debrief granted, at no block cost.
# There's no vein id to reference from static JSON (the debrief creates it
# at runtime), so this looks up "the Whitechapel time vein" directly — safe
# because a fresh tutorial playthrough has exactly one at this point, and
# this event only fires once, right after that debrief.
static func _tutorial_cultivate() -> void:
	var vein = _find_tutorial_cultivation_vein()
	if vein == null:
		return

	var skill: int = GameState.state["player"]["cultivatingSkill"]
	var vein_ceiling: int = Cultivating.ceiling(vein)
	var gain: int = Cultivating.cultivate_gain(skill, vein["growth"], vein_ceiling)
	vein["growth"] = clampi(vein["growth"] + gain, 0, vein_ceiling)


static func _find_tutorial_cultivation_vein() -> Variant:
	for vein in GameState.state["player"]["veins"]:
		if vein["district"] == "whitechapel" and vein["oreType"] == "time":
			return vein
	return null


# vein-raiding ticket 03: a raid's target site_id is a real, runtime-
# generated site (Sites.make_site_id()), never a value static event JSON
# could hardcode -- Raiding.begin_raid() passes it as start_event()'s
# context instead. Effects that supply a literal "site_id" (ticket 02's own
# direct apply_effects() tests) still take that literal; only the authored
# raid card, which omits it, falls back to the active event's context.
static func _event_site_id(effect: Dictionary) -> String:
	if effect.has("site_id"):
		return effect["site_id"]
	var event_state: Variant = GameState.state.get("event")
	if event_state == null:
		return ""
	return event_state.get("context", {}).get("site_id", "")


# 45-archie-raid-assist: mirrors _event_site_id() above -- the raid-assist
# ally list (currently ever just ["archie"], or []) is only known at
# Raid-button-press time (Raiding.begin_raid()'s caller reads it off the map
# sheet's toggle), so it's carried the same way through start_event()'s
# context rather than baked into the authored vein_raid card's own JSON.
static func _event_ally_ids(effect: Dictionary) -> Array:
	if effect.has("ally_ids"):
		return effect["ally_ids"]
	var event_state: Variant = GameState.state.get("event")
	if event_state == null:
		return []
	return event_state.get("context", {}).get("ally_ids", [])


# vein-raiding ticket 03: "caught" drives loot_raid_vein's relation hit, but
# the authored raid card's clean-stealth and caught-then-combat-win paths
# both resume at the same shared claim/loot card (exit_combat()'s event_raid
# case resumes cardIndex as-is, so there's exactly one "next card" either
# way) -- flags.raidCaught, set by the stealth_check branch that ran
# earlier in this same event via the plain "set_flag" op, is what tells the
# shared card which path got it here. Effects that supply a literal
# "caught" (ticket 02's own direct apply_effects() tests) still take that
# literal.
static func _event_caught(effect: Dictionary) -> bool:
	if effect.has("caught"):
		return effect["caught"]
	return GameState.state["flags"].get("raidCaught", false)


# vein-raiding ticket 02: pure op-dispatch shims into Raiding, mirroring the
# "relation" op's dispatch into Contacts.award_relation() above. `effect`
# names its target by `site_id` (Sites.find_site()) rather than embedding a
# vein template inline the way grant_vein_with_site does, since the target here is an
# existing runtime faction-owned vein, not static event content. Both are a
# silent no-op if the site has no factionVein -- same defensive shape
# Raiding.claim_vein()/loot_vein() already use, so a stale or bad site_id
# never crashes an event mid-flight.
static func _stealth_check(effect: Dictionary) -> void:
	var site: Variant = Sites.find_site(_event_site_id(effect))
	if site == null or site["factionVein"] == null:
		return

	var consumable_bonus: float = effect.get("consumable_bonus", 0.0)
	var success: bool = Raiding.resolve_stealth_check(site["factionVein"], consumable_bonus)
	if success:
		apply_effects(effect.get("on_success", []))
	else:
		apply_effects(effect.get("on_caught", []))


# Branches into Combat.start_raid() with context "event_raid" (see
# systems/combat.gd's exit_combat()) so a win resumes this same event rather
# than routing to inventory. `guards`/`template` are the authoring event
# card's call (per-vein flavour), defaulting to a single guard on the
# catch-all enemy template.
static func _start_raid_combat(effect: Dictionary) -> void:
	var site: Variant = Sites.find_site(_event_site_id(effect))
	if site == null or site["factionVein"] == null:
		return

	var vein: Dictionary = site["factionVein"]
	Combat.start_raid(vein["id"], Cultivating.value_tier(vein), effect.get("guards", 1), effect.get("template", ""), Combat.CONTEXT_EVENT_RAID, _event_ally_ids(effect))
