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
		# collective1-17: state.event is nulled BEFORE on_complete runs (not
		# after -- see the comment on this deliberately, a state_changed emit
		# mid-on_complete must never find a live event.gd EventScreen still
		# rendering a tappable Continue for an on_complete that hasn't
		# finished), so an on_complete op that needs the delivery context
		# (col_hakim_intel's "reveal_site", reading the pendingMessages
		# payload's site_id) can't fall back to GameState.state["event"]
		# .context the way a live choice-card effect can -- it has to be
		# handed the context explicitly instead.
		var context: Dictionary = event_state.get("context", {})
		GameState.state["event"] = null
		apply_effects(on_complete, context)
		# collective1-16, spec §6.15/§10.4: the closer's three prerequisite
		# flags are each set by a different event's own on_complete
		# (col_a1_des_report/col_a1_nadia_done/col_a1_hakim_done) -- this is
		# the one code path all three actually flow through, so the check
		# lives here rather than duplicated at each of their three call
		# sites. Harmless no-op for every other event's completion.
		Collective.maybe_trigger_closer()
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

static func apply_effects(effects: Array, context: Dictionary = {}) -> void:
	for effect in effects:
		_apply_one(effect, context)
	# ticket 79: boundary #6 -- every tutorial checkpoint flag (metArchie,
	# buyerEventSeen, ...) is set exclusively via this function's set_flag
	# op, same as several Collective flags already are, so this is where a
	# flag-driven questline's objectives actually need to catch up, same as
	# the 5 boundaries objectives.gd's own doc lists (Sites.prospect(),
	# Economy sale completion, VeinTrade.sell_to_faction(), Cultivating.
	# cultivate()/prune(), TimeSystem.daily_tick()).
	Objectives.refresh()
	EventBus.state_changed.emit()


static func _apply_one(effect: Dictionary, context: Dictionary = {}) -> void:
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
			# Guild purchase (Economy.execute_faction_purchase).
			Crafting.inventory_add(effect["item"], 0, effect["qty"])
		"relation":
			Contacts.award_relation(effect["contact"], effect["value"])
		"grant_vein_with_site":
			_grant_vein_with_site(effect["vein"])
		# collective1-13, spec §6.11/§10.3: grant_vein_with_site's contact-
		# handoff cousin -- same site+vein creation, but also records the new
		# vein's id at a named state path (col_a1_hakim_meet's "collective.
		# hakimVeinId") so a later objective (col_a1_hakim_rescue's
		# veinIdStatePath) and thread-resolution event can find it again.
		"grant_contact_vein":
			_set_path(effect["statePath"], _grant_vein_with_site(effect["vein"]))
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
				apply_effects(effect.get("on_success", []), context)
			else:
				apply_effects(effect.get("on_fail", []), context)
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
		"unlock_contact":
			GameState.state["contacts"][effect["contact"]]["unlocked"] = true
		"push_message":
			Messages.append(effect["contact"], "them", effect["text"])
		# collective1-08: queue_pending_message is push_message's follow-up-
		# action cousin -- a real Messages.queue_pending() call (unread text +
		# a pendingMessages entry an action bar can surface), for authored
		# content that wants a runtime "text arrives, tap it to start an
		# event" beat rather than a plain notification-only line.
		"queue_pending_message":
			Messages.queue_pending(effect["contact"], effect["kind"], effect["text"], effect.get("payload", {}))
		# collective1-08: the "relation" op above is contact-only
		# (Contacts.award_relation) -- this is its faction-facing twin, over
		# the same Factions.adjust_player_relation() vein-raiding ticket 02
		# already added for Raiding's claim/loot relation hits.
		"faction_relation":
			Factions.adjust_player_relation(effect["faction"], effect["value"])
		# collective1-09, spec §5.7/§10.3: writes state.methodLog[key] =
		# value -- S6's choice card is the only Act 1 caller. Ordinary
		# state, so Events.rewind() restores it like anything else.
		"log_method":
			GameState.state["methodLog"][effect["key"]] = effect["value"]
		# collective1-10, spec §6.7/§10.3: S7's on_complete -- seeds a
		# named faction the two sites recorded on the named objective's
		# progress (see Objectives._eval_sites_discovered_matching()).
		"faction_seed_reported_sites":
			_faction_seed_reported_sites(effect["objective"], effect["faction"])
		# collective1-14, spec §6.12/§10.3: S12's handback -- resolves a
		# contact-granted vein's id (grant_contact_vein's statePath, e.g.
		# col_a1_hakim_meet's "collective.hakimVeinId") and reuses
		# VeinTrade.sell_to_faction() at a forced price, same "no separate
		# mechanism" instruction as the ticket. See sell_to_faction()'s own
		# comment for why a forced price also marks the transfer as not a
		# real market sale (soldByPlayer false), keeping it from tripping
		# an unrelated vein_sold_to_faction objective (e.g. col_a1_nadia_vein).
		"sell_contact_vein_to_faction":
			VeinTrade.sell_to_faction(GameState.read_path(effect["veinIdStatePath"]), effect["faction"], effect["price"])
		# collective1-15, spec section 6.13: S13's "Push" choice must continue
		# straight into the debt reveal (cards 4-8) without the "Leave it"
		# branch ever seeing them. advance()'s cardIndex has no branching of
		# its own, so the two lengths live as two separate events, and this
		# op (fired from the choice's own effects, same timing as set_flag
		# above) hands off to the second immediately.
		"start_event":
			start_event(effect["event"])
		# collective1-16, spec §6.15/§10.3: S14's on_complete seed -- creates
		# the site+vein+claim directly (see _scripted_seed() below) rather
		# than routing 40 ore through player.orichalchum and calling
		# Sites.attempt_seed(), so the calc never touches inventory and the
		# seed can't roll a failure.
		"scripted_seed":
			_scripted_seed(effect["district"], effect["tier"], effect["oreType"])
		# collective1-16, spec §6.15/§8.6: S14's "I'm in" choice -- the only
		# remaining path to Factions.join("collective"), now that
		# ContactCards.build_faction_card() suppresses the generic Join
		# button for that faction.
		"join_faction":
			Factions.join(effect["faction"])
		# collective1-17, spec §6.16/§10.3: col_hakim_intel's on_complete --
		# the site was already created at roll time (Collective.
		# maybe_trigger_hakim_intel()); this just queues its discover map
		# event, same as a fresh player prospect would, reusing
		# _event_site_id()'s payload/context fallback rather than a literal
		# "site_id" in the JSON. state.event is already null by the time
		# on_complete runs (see advance()'s own comment), so the fallback
		# reads advance()'s explicitly-threaded context, not live event state.
		"reveal_site":
			_reveal_site(_event_site_id(effect, context))
		"set_hakim_intel_day":
			GameState.state["collective"]["hakimIntelLastDay"] = GameState.state["world"]["day"]


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


# Shared claimed-site dict shape between _grant_vein_with_site() and
# _scripted_seed() below -- both fabricate a site from scratch (no
# prospecting roll) and immediately claim it, appending to state.world.sites
# and handing back the new site for its caller's vein to reference by id.
static func _append_claimed_site(district: String, tier: String, ore_type: String, bonuses: Array) -> Dictionary:
	var site: Dictionary = {
		"id": Sites.make_site_id(),
		"district": district,
		"tier": tier,
		"oreType": ore_type,
		"bonuses": bonuses,
		"discoveredDay": GameState.state["world"]["day"],
		"claimed": true,
		"factionVein": null,
		"hasNaturalVein": false,
		"slotIndex": Sites.next_slot_index(district),
	}
	GameState.state["world"]["sites"].append(site)
	return site


# M1-LONDON D7: the home-raid debrief's granted vein needs a matching
# player-claimed site on state.world.sites, or the Map tab shows a
# Whitechapel vein with no site backing it. Site tier/oreType/bonuses are
# derived from the vein template's own hospitability/oreType fields (same
# fields Sites.attempt_seed() would have produced), so the two stay in sync
# by construction rather than by two copies of "fair, no bonuses" agreeing.
static func _grant_vein_with_site(vein_template: Dictionary) -> String:
	var hospitability: Dictionary = vein_template.get("hospitability", { "tier": "fair", "bonuses": [] })
	var day: int = GameState.state["world"]["day"]

	var site: Dictionary = _append_claimed_site(vein_template["district"], hospitability["tier"], vein_template["oreType"], hospitability["bonuses"])

	var vein: Dictionary = GameState.deep_copy(vein_template)
	vein["id"] = Cultivating.make_vein_id()
	vein["claimedOnDay"] = day
	vein["siteId"] = site["id"]
	vein["rampantDays"] = 0
	GameState.state["player"]["veins"].append(vein)
	return vein["id"]


# collective1-16, spec §6.15/§10.3: S14's guaranteed seed. Distinct from
# _grant_vein_with_site() above (which copies a static vein template
# untouched) -- this rolls no ore/skill/travel and doesn't queue a
# Modal.open("seed_result") popup, because it isn't a player action to react
# to: it fabricates the site fresh, at an explicit district/tier/oreType, and
# claims it exactly as a successful Sites.attempt_seed() would (map events
# included), so Whitechapel's own scripted rich life vein is guaranteed
# present regardless of the district's siteCap -- the cap governs prospecting
# discovery, not this scripted creation, per the ticket's explicit exception.
static func _scripted_seed(district: String, tier: String, ore_type: String) -> void:
	var site: Dictionary = _append_claimed_site(district, tier, ore_type, [])

	var hospitability := { "tier": tier, "bonuses": [] }
	var vein := Cultivating.make_vein(ore_type, GameData.VEIN_GROWTH["seedGrowth"], district, site["id"], hospitability)
	GameState.state["player"]["veins"].append(vein)
	MapEvents.queue_seed_claim(district, vein["id"], "player")
	MapEvents.queue_join_line(district, vein["id"], "player")


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
#
# collective1-17: a live choice-card effect (raiding's own callers) still
# reads GameState.state["event"].context, since state.event is still set
# at that point. An on_complete effect (col_hakim_intel's "reveal_site")
# can't -- state.event is already null by the time on_complete runs (see
# advance()'s own comment) -- so it reads the explicitly-threaded
# fallback_context (advance()'s captured copy of that same context)
# instead.
static func _event_site_id(effect: Dictionary, fallback_context: Dictionary = {}) -> String:
	if effect.has("site_id"):
		return effect["site_id"]
	var event_state: Variant = GameState.state.get("event")
	if event_state != null:
		var from_live_context: String = event_state.get("context", {}).get("site_id", "")
		if from_live_context != "":
			return from_live_context
	return fallback_context.get("site_id", "")


# collective1-17, spec §6.16/§10.3: col_hakim_intel's "reveal_site" op --
# the site itself was already appended to state.world.sites at roll time
# (Collective.maybe_trigger_hakim_intel()), so all that's left is queuing
# its discover map event, same as Sites._create_site() does for a fresh
# player prospect. A no-op if the site is somehow already gone.
static func _reveal_site(site_id: String) -> void:
	var site: Variant = Sites.find_site(site_id)
	if site == null:
		return
	MapEvents.queue_discover(site["district"], site_id)


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


# collective1-10, spec §6.7/§10.3: seeds `faction_id` a faction vein on each
# site recorded in `objective_id`'s progress["matchedSiteIds"] (Objectives.
# _eval_sites_discovered_matching() stamps those in the moment the objective
# completes, and never touches them again), via Sites.seed_faction_vein() --
# the same instant-vein shape Sites.npc_claim_best_unclaimed_site() uses for
# an NPC claim. A site that's since been claimed (player or another faction)
# between the objective completing and the player tapping "Tell Des about
# the ground" is silently skipped rather than overwritten -- same defensive
# shape _stealth_check()/_start_raid_combat() use for a stale site_id.
static func _faction_seed_reported_sites(objective_id: String, faction_id: String) -> void:
	var progress: Dictionary = GameState.state["objectives"][objective_id]["progress"]
	var matched: Dictionary = progress.get("matchedSiteIds", {})
	for site_id in matched.values():
		var site: Variant = Sites.find_site(site_id)
		if site == null or site["claimed"] or site["factionVein"] != null:
			continue
		Sites.seed_faction_vein(site, faction_id)
