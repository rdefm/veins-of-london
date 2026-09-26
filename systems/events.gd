class_name Events
extends RefCounted

# Event runner (R§3.9, ui-vision.md §11). Cards: {type, label, speaker,
# text}; a "choice" card adds {choices:[{label, effects, result_text}]}.
# Events: {id, cards, on_complete:[effect]}. state.event holds runtime
# progress: {eventId, cardIndex, snapshots, choiceResults}.
#
# Any card (including a choice's own "choices" entries) may carry an optional
# "image" key -- an asset path, or explicit null to clear the event screen's
# persistent image slot. Omitting the key falls back to a convention-named
# asset at that card index; a picked choice's own "image" rides along in
# choiceResults[cardIndex] the same way.

const Preferences := preload("res://systems/preferences.gd")


# context: a raid's target site_id is only known at Raid-button-press time, so
# it's carried here and read back by _event_site_id() below; every other caller omits it.
static func start_event(event_id: String, context: Dictionary = {}) -> void:
	GameState.state["event"] = { "eventId": event_id, "cardIndex": 0, "snapshots": [], "choiceResults": {}, "context": context }
	Nav.go_to("event")


# start_event(), unless a modal flow is open (e.g. a sale confirmation) --
# then the event waits behind it and starts when that flow closes.
static func start_or_defer(event_id: String, context: Dictionary = {}) -> void:
	if GameState.state["modal"] == null:
		start_event(event_id, context)
		return
	Modal.defer_event(event_id, context)


static func _event_def() -> Dictionary:
	var event_state: Dictionary = GameState.state["event"]
	return GameData.EVENTS[event_state["eventId"]]


# The card at the runner's current position -- awaiting a Continue tap, or (for a "choice" card) a pick.
static func current_card() -> Dictionary:
	var event_state: Dictionary = GameState.state["event"]
	var cards: Array = _event_def()["cards"]
	return cards[event_state["cardIndex"]]


# True once the current card is an unresolved "choice" card -- the runner must not advance() past it via Continue.
static func is_awaiting_choice() -> bool:
	var event_state: Dictionary = GameState.state["event"]
	var card: Dictionary = current_card()
	if card["type"] != "choice":
		return false
	return not event_state["choiceResults"].has(str(event_state["cardIndex"]))


# All cards revealed so far (index 0..cardIndex inclusive). A resolved "choice"
# card's result_text is spliced in right after it as a synthetic resolution
# card, without consuming its own cardIndex slot.
static func revealed_cards() -> Array:
	var event_state: Dictionary = GameState.state["event"]
	var cards: Array = _event_def()["cards"]
	var choice_results: Dictionary = event_state["choiceResults"]

	# fillFromContext: card text's {key} placeholders read the event's context.
	var fill: bool = _event_def().get("fillFromContext", false)
	var result: Array = []
	for i in range(event_state["cardIndex"] + 1):
		var card: Dictionary = cards[i]
		if fill:
			card = card.duplicate()
			card["text"] = String(card["text"]).format(event_state.get("context", {}))
		result.append(card)
		if choice_results.has(str(i)):
			var resolution: Dictionary = choice_results[str(i)]
			var resolution_card: Dictionary = { "type": "resolution", "label": null, "speaker": null, "text": resolution["text"] }
			if resolution.has("image"):
				resolution_card["image"] = resolution["image"]
			result.append(resolution_card)
	return result


# Derived state for the event screen's persistent image slot (ui-vision.md §11):
# scans cards up to the current position, sticky until the next image, explicit
# null clears it. Not stored on state.event, so Rewind restores it for free.
static func current_image_path() -> Variant:
	var result: Variant = null
	var event_state: Dictionary = GameState.state["event"]
	var event_id: String = event_state["eventId"]
	var cards: Array = _event_def()["cards"]
	var choice_results: Dictionary = event_state["choiceResults"]
	for i in range(event_state["cardIndex"] + 1):
		var card: Dictionary = cards[i]
		if card.has("image"):
			result = card["image"]
		else:
			var discovered_path: Variant = _convention_image_path(event_id, i + 1)
			if discovered_path != null:
				result = discovered_path
		if choice_results.has(str(i)):
			var resolution: Dictionary = choice_results[str(i)]
			if resolution.has("image"):
				result = resolution["image"]
	return result


# Convention-based event art: one-based card numbers map directly to
# assets/events/<event_id>/<event_id>_card<n>.<extension>. Explicit card image
# keys remain authoritative, including null (clear).
static func _convention_image_path(event_id: String, card_number: int) -> Variant:
	var stem := "res://assets/events/%s/%s_card%d" % [event_id, event_id, card_number]
	for extension in ["png", "jpg", "jpeg", "webp"]:
		var path := "%s.%s" % [stem, extension]
		if ResourceLoader.exists(path):
			return path
	return null


# Decides VN mode once for the whole event from the static definition (not
# revealed_cards(), which grows and would flip the layout mid-event). True iff
# current_image_path() could ever return non-null across the full run: a
# top-level "image" key on any card, or a non-null "image" on any choice
# option, regardless of which is picked.
static func is_vn_mode() -> bool:
	var cards: Array = _event_def()["cards"]
	var event_id: String = GameState.state["event"]["eventId"]
	for i in range(cards.size()):
		var card: Dictionary = cards[i]
		if card.has("image"):
			if card["image"] != null:
				return true
		elif _convention_image_path(event_id, i + 1) != null:
			return true
		if card["type"] == "choice":
			for choice in card["choices"]:
				if choice.get("image") != null:
					return true
	return false


static func is_last_card() -> bool:
	var event_state: Dictionary = GameState.state["event"]
	var cards: Array = _event_def()["cards"]
	return event_state["cardIndex"] >= cards.size() - 1


static func can_rewind() -> bool:
	var event_state = GameState.state["event"]
	if event_state == null or event_state["snapshots"].is_empty():
		return false
	return Crafting.inventory_qty("rewind") > 0 or Dial.find_loaded_rewind_complication_index() >= 0


# Continue: snapshots full state, then either reveals the next card or (on the last card) runs on_complete and clears state.event.
static func advance() -> void:
	if is_awaiting_choice():
		return  # a "choice" card must be resolved via choose() before Continue works

	_snapshot_before_mutation()

	var event_state: Dictionary = GameState.state["event"]
	if is_last_card():
		var on_complete: Array = _event_def().get("on_complete", [])
		# state.event is nulled BEFORE on_complete runs, so a mid-on_complete emit never
		# finds a live EventScreen still rendering a tappable Continue. An on_complete op
		# needing the event's context (e.g. reveal_site) is handed it explicitly instead.
		var context: Dictionary = event_state.get("context", {})
		GameState.state["event"] = null
		apply_effects(on_complete, context)
		# The one path all three Act-1 closer prerequisite flags flow through; a
		# harmless no-op for every other event's completion.
		Collective.maybe_trigger_closer()
		# Act 2's own opener -- same "check after any on_complete" idiom, since
		# colA1Complete only ever flips inside an event's on_complete too.
		Collective.maybe_trigger_act2_intro()
		# T5's scripted vein loss -- same idiom, gated on colA2Stage which T3's
		# on_complete sets.
		Collective.maybe_trigger_a2_contested_vein_setup()
		# T9's checkpoint -- stamps ledgerStartedDay straight after T8's on_complete.
		Collective.maybe_trigger_a2_checkpoint()
		# T14's gate usually crosses on T13's own +15 relation award.
		Collective.maybe_trigger_a2_spine_reward()
		# Beat 1: an event can grant a vein or recruit Archie; the Beat 1
		# scene itself starts Archie's starter chain.
		BusinessQuest.maybe_trigger_proposition()
		BusinessQuest.maybe_issue_starter()
		# Beat 3: prior completions can meet Beat 2 inside the Beat 1 scene.
		BusinessQuest.maybe_trigger_owen_intro()
		BusinessQuest.maybe_trigger_partnership()
		BusinessQuest.maybe_trigger_production()
		BusinessQuest.maybe_trigger_put_to_work()
		BusinessQuest.maybe_trigger_owen_craft()
		SaveManager.autosave()  # R§6: autosave on event completion
	else:
		event_state["cardIndex"] += 1
		EventBus.state_changed.emit()


# Resolves the current "choice" card: applies the picked choice's effects, then
# records its result_text so revealed_cards() shows it as a resolution card.
# Doesn't advance cardIndex -- Continue still moves past the resolution.
static func choose(choice_index: int) -> void:
	if not is_awaiting_choice():
		return

	_snapshot_before_mutation()

	var event_state: Dictionary = GameState.state["event"]
	var card: Dictionary = current_card()
	var choice: Dictionary = card["choices"][choice_index]

	var resolution: Dictionary = { "text": choice["result_text"] }
	if choice.has("image"):
		resolution["image"] = choice["image"]
	event_state["choiceResults"][str(event_state["cardIndex"])] = resolution
	apply_effects(choice.get("effects", []))


# Shared by advance()/choose(). event.snapshots must be emptied before the deep
# copy -- it lives inside the tree being copied, and left in place would embed
# every prior snapshot into the new one, compounding across a long event.
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
	var rewind_index: int = Dial.find_loaded_rewind_complication_index()

	var stack: Array = event_state["snapshots"]
	var snap: Dictionary = Snapshots.pop_newest(stack)
	var live_meta: Dictionary = GameState.state["meta"].duplicate()
	GameState.state = snap
	Preferences.carry_forward(live_meta)
	# snap's own event.snapshots is always [] (see advance()) -- carry the real,
	# already-popped live stack forward instead of trusting that.
	GameState.state["event"]["snapshots"] = stack

	if has_consumable:
		Crafting.inventory_remove("rewind", 1)
	else:
		Dial.cast_complication(rewind_index)

	Notify.push("⟲ Time unspools. The moment resets. Only you remember.")
	EventBus.state_changed.emit()
	return { "ok": true }


# ── effect ops ──────────────────────────────────────────────────────────

static func apply_effects(effects: Array, context: Dictionary = {}) -> void:
	for effect in effects:
		_apply_one(effect, context)
	# Every tutorial checkpoint flag is set exclusively via the set_flag op below,
	# same as several Collective flags, so this is one of the boundaries objectives.gd's own doc lists.
	Objectives.refresh()
	EventBus.state_changed.emit()


static func _apply_one(effect: Dictionary, context: Dictionary = {}) -> void:
	match effect["op"]:
		"set_flag":
			var flags: Dictionary = GameState.state["flags"]
			var flag_name: String = effect["flag"]
			var value: Variant = effect["value"]
			# Ore stock rolls fresh the instant this flag first flips true, guarded on
			# the pre-update flag value so a future re-set can't re-roll a live stock.
			if flag_name == "collectiveLaneUnlocked" and value and not flags.get(flag_name, false):
				Factions.restock_ore("collective")
			flags[flag_name] = value
		"add":
			_apply_add(effect["path"], effect["value"])
		"add_ore":
			var ore: Dictionary = GameState.state["player"]["orichalchum"]
			ore[effect["type"]] = ore.get(effect["type"], 0) + effect["qty"]
			if effect["qty"] > 0:
				EventBus.shared_stock_increased.emit()
		"add_item":
			# Event-granted items aren't crafted at any tier -- filed under the untiered "0" bucket, same as a Guild purchase.
			Crafting.inventory_add(effect["item"], 0, effect["qty"])
		"relation":
			Contacts.award_relation(effect["contact"], effect["value"])
		"grant_vein_with_site":
			_grant_vein_with_site(effect["vein"])
		# grant_vein_with_site's contact-handoff cousin -- same site+vein creation, but
		# also records the new vein's id at a named state path so a later objective can find it again.
		"grant_contact_vein":
			_set_path(effect["statePath"], _grant_vein_with_site(effect["vein"]))
		"set_screen":
			# Routing to "phone" also resets phoneNav to its home view, same as every other route-to-phone-home call site.
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
		# Contested-vein choice ops (col_a2_contested_vein, spec §6.5): both
		# resolve a site id from a named state path (no per-raid context to
		# thread, since a map pin's tap carries none) rather than reusing
		# claim_raid_vein's context-threaded site_id. veinIdStatePath instead
		# names the faction vein itself (col_a2_hakim_retake, spec §6.13).
		"claim_faction_vein":
			Raiding.claim_vein(_state_path_site_id(effect))
		"buy_faction_vein":
			_buy_faction_vein(effect)
		"unlock_contact":
			GameState.state["contacts"][effect["contact"]]["unlocked"] = true
		"recruit_contact":
			Contacts.force_recruit(effect["contact"])
		"activate_business":
			Business.activate()
		"set_james_crafting_skill":
			BusinessQuest.set_james_crafting_skill()
		"issue_recurring_offers":
			BusinessQuest.maybe_issue_recurring()
		"push_message":
			# Optional "from" lets an authored SMS thread replay its own outgoing "player" lines verbatim; defaults to "them" when omitted.
			Messages.append(effect["contact"], effect.get("from", "them"), effect["text"])
		# push_message's follow-up-action cousin: queues unread text plus a pendingMessages
		# entry an action bar can surface, for a "tap to start an event" beat.
		"queue_pending_message":
			Messages.queue_pending(effect["contact"], effect["kind"], effect["text"], effect.get("payload", {}))
		# Faction-facing twin of the "relation" op above (which is contact-only).
		"faction_relation":
			Factions.adjust_player_relation(effect["faction"], effect["value"])
		"log_method":
			GameState.state["methodLog"][effect["key"]] = effect["value"]
		# col_a2_nadia_defend_brief (T8a, spec §6.8a): no per-raid context to
		# resolve a site from, unlike claim_faction_vein/loot_raid_vein above --
		# Collective.pick_nadia_defend_vein() picks and writes the target itself.
		"col_a2_pick_nadia_defend_vein":
			Collective.pick_nadia_defend_vein()
		"col_a2_provoke_firm":
			Collective.provoke_firm(float(effect["multiplier"]), int(effect["days"]))
		# Act 2 T10/T11 (spec §5.4): unrolled ownership transfer. veinIdStatePath
		# names the vein (T10, Hakim's); without it, Collective picks T11's target.
		"col_a2_force_vein_loss":
			var target: Variant = GameState.read_path(effect["veinIdStatePath"]) if effect.has("veinIdStatePath") else Collective.second_loss_target_id()
			Collective.force_vein_loss(target, effect["faction"])
		# T13 (spec §5.4): runs right after the retake's claim/buy op.
		"col_a2_ruin_site":
			Collective.ruin_hakim_site()
		"network_reveal_vulnerable_vein":
			NetworkHandler.reveal_vulnerable_vein(_event_site_id(effect, context), effect["effect"])
		"network_reveal_site":
			NetworkHandler.reveal_site(effect["oreType"], effect["minTier"])
		"faction_seed_reported_sites":
			_faction_seed_reported_sites(effect["objective"], effect["faction"])
		# Resolves a contact-granted vein's id via veinIdStatePath and sells it at a forced
		# price. See VeinTrade.sell_to_faction() for why a forced price also marks the sale as not a real market transaction.
		# The state path is re-pointed at the new faction vein's id, so it keeps naming that vein after the handover.
		"sell_contact_vein_to_faction":
			var sale := VeinTrade.sell_to_faction(GameState.read_path(effect["veinIdStatePath"]), effect["faction"], effect["price"])
			if sale.get("ok", false):
				_set_path(effect["veinIdStatePath"], sale["factionVeinId"])
		# Chains straight into a second event from a choice's own effects -- advance()'s
		# cardIndex has no branching, so two divergent card sequences live as two separate events instead.
		"start_event":
			start_event(effect["event"])
		# Creates the site+vein+claim directly (see _scripted_seed() below) rather than
		# spending calc through Sites.attempt_seed(), so this seed can't roll a failure.
		"scripted_seed":
			_scripted_seed(effect["district"], effect["tier"], effect["oreType"])
		# The only remaining path to Factions.join("collective") -- ContactCards.build_faction_card() suppresses the generic Join button for that faction.
		"join_faction":
			Factions.join(effect["faction"])
		# The site was already created at roll time (Collective.maybe_trigger_hakim_intel())
		# -- this just queues its discover map event. Runs post on_complete, so
		# _event_site_id() falls back to advance()'s explicitly-threaded context rather than live event state.
		"reveal_site":
			_reveal_site(_event_site_id(effect, context))
		"set_hakim_intel_day":
			GameState.state["collective"]["hakimIntelLastDay"] = GameState.state["world"]["day"]


# Adds when both the existing and incoming values are numeric (e.g. player.cash),
# otherwise assigns outright (e.g. contacts.james.unlocked).
# world.archieChatUnlockDay starts null, so "add" there means "today + value".
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


# Shared by _grant_vein_with_site()/_scripted_seed(): fabricates and claims a site with no prospecting roll, appending to state.world.sites.
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


# A granted vein needs a matching claimed site on state.world.sites, or the Map
# tab shows it with no site backing it. Tier/oreType/bonuses are derived from
# the vein template's own hospitability fields, so they stay in sync by construction.
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


# A guaranteed, scripted seed -- unlike _grant_vein_with_site() (copies a static
# template), this fabricates a fresh site at an explicit district/tier/oreType
# and claims it exactly as a successful Sites.attempt_seed() would, ignoring
# the district's siteCap (which only governs prospecting discovery).
static func _scripted_seed(district: String, tier: String, ore_type: String) -> void:
	var site: Dictionary = _append_claimed_site(district, tier, ore_type, [])

	var hospitability := { "tier": tier, "bonuses": [] }
	var vein := Cultivating.make_vein(ore_type, GameData.VEIN_GROWTH["seedGrowth"], district, site["id"], hospitability)
	GameState.state["player"]["veins"].append(vein)
	MapEvents.queue_seed_claim(district, vein["id"], "player")
	MapEvents.queue_join_line(district, vein["id"], "player")


# Forced, always-successful cultivate on the vein the home-raid debrief granted,
# at no block cost. No vein id exists in static JSON (created at runtime), so
# this looks up "the Whitechapel time vein" directly -- safe since a fresh
# playthrough has exactly one, and this fires only once, right after that debrief.
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


# A raid's site_id is runtime-generated, never hardcoded in event JSON --
# Raiding.begin_raid() passes it via start_event()'s context instead. A live
# choice-card effect reads GameState.state["event"].context directly; an
# on_complete effect (state.event already null by then) falls back to the explicitly-threaded fallback_context.
static func _event_site_id(effect: Dictionary, fallback_context: Dictionary = {}) -> String:
	if effect.has("site_id"):
		return effect["site_id"]
	var event_state: Variant = GameState.state.get("event")
	if event_state != null:
		var from_live_context: String = event_state.get("context", {}).get("site_id", "")
		if from_live_context != "":
			return from_live_context
	return fallback_context.get("site_id", "")


# buy_faction_vein's helper: resolves a site's current factionVein id from
# effect["siteIdStatePath"] and reuses VeinTrade.buy_from_faction() at its
# normal quote() price. A silent no-op if the site or its faction vein is
# already gone (e.g. bought from the Map screen before this event ran).
static func _buy_faction_vein(effect: Dictionary) -> void:
	var site: Variant = Sites.find_site(_state_path_site_id(effect))
	if site == null or site["factionVein"] == null:
		return
	VeinTrade.buy_from_faction(site["factionVein"]["id"], effect["faction"])


# claim_faction_vein/buy_faction_vein's site: siteIdStatePath directly, or the
# site holding the faction vein veinIdStatePath names ("" once no site does).
static func _state_path_site_id(effect: Dictionary) -> String:
	if effect.has("siteIdStatePath"):
		var site_id: Variant = GameState.read_path(effect["siteIdStatePath"])
		return site_id if site_id != null else ""
	var vein_id: Variant = GameState.read_path(effect["veinIdStatePath"])
	for site in GameState.state["world"]["sites"]:
		if site["factionVein"] != null and site["factionVein"]["id"] == vein_id:
			return site["id"]
	return ""


# The site was already appended to state.world.sites at roll time -- this just
# queues its discover map event, same as Sites._create_site() does for a fresh
# prospect. No-op if the site is already gone.
static func _reveal_site(site_id: String) -> void:
	var site: Variant = Sites.find_site(site_id)
	if site == null:
		return
	MapEvents.queue_discover(site["district"], site_id)


# Mirrors _event_site_id(): the raid-assist ally list is only known at
# Raid-button-press time, so it's carried through start_event()'s context rather than baked into the authored card's JSON.
static func _event_ally_ids(effect: Dictionary) -> Array:
	if effect.has("ally_ids"):
		return effect["ally_ids"]
	var event_state: Variant = GameState.state.get("event")
	if event_state == null:
		return []
	return event_state.get("context", {}).get("ally_ids", [])


# "caught" drives loot_raid_vein's relation hit. Clean-stealth and
# caught-then-combat-win both resume at the same shared claim/loot card, so
# flags.raidCaught (set earlier by the stealth_check branch) is what tells it which path got here.
static func _event_caught(effect: Dictionary) -> bool:
	if effect.has("caught"):
		return effect["caught"]
	return GameState.state["flags"].get("raidCaught", false)


# Dispatches into Raiding, targeting an existing runtime faction-owned vein by
# site_id. Silent no-op if the site has no factionVein, so a stale site_id never crashes an event mid-flight.
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


# Branches into Combat.start_raid() with context "event_raid" (see combat.gd's
# exit_combat()) so a win resumes this same event. guards/template come from
# the authoring card, defaulting to a single guard on the catch-all template.
static func _start_raid_combat(effect: Dictionary) -> void:
	var site: Variant = Sites.find_site(_event_site_id(effect))
	if site == null or site["factionVein"] == null:
		return

	var vein: Dictionary = site["factionVein"]
	Combat.start_raid(vein["id"], Cultivating.combined_magnitude(vein), effect.get("guards", 1), effect.get("template", ""), Combat.CONTEXT_EVENT_RAID, _event_ally_ids(effect))


# Seeds `faction_id` a faction vein on each site recorded in `objective_id`'s
# progress["matchedSiteIds"] (Sites.seed_faction_vein()). A site already
# claimed or vein-occupied is silently skipped. Currently inert for
# col_a1_des_sites, whose own evaluator reports/converts sites individually and
# never populates matchedSiteIds -- kept for any future objective using this "convert everything at once" shape.
static func _faction_seed_reported_sites(objective_id: String, faction_id: String) -> void:
	var progress: Dictionary = GameState.state["objectives"][objective_id]["progress"]
	var matched: Dictionary = progress.get("matchedSiteIds", {})
	for site_id in matched.values():
		var site: Variant = Sites.find_site(site_id)
		if site == null or site["claimed"] or site["factionVein"] != null:
			continue
		Sites.seed_faction_vein(site, faction_id)
