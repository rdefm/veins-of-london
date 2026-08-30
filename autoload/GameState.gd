extends Node

# The entire game state: one pure data tree (Dictionaries/Arrays/primitives
# only — no object references, no Nodes, no Callables). This purity is what
# makes save, snapshot, and Rewind work. Systems read/write `state` directly
# and emit EventBus.state_changed; screens only ever read it. Not one line
# of screen code mutates this directly.

var state: Dictionary = {}


func _ready() -> void:
	reset()


func reset() -> void:
	state = new_game_state()
	# ticket 79: a fresh game boots straight into the tutorial questline's
	# first checkpoint (data/objectives.json's activateFlag: null case) --
	# it must read as active before any of Objectives.refresh()'s other
	# action-boundary callers has ever run.
	Objectives.refresh()


func new_game_state() -> Dictionary:
	return {
		"meta": { "saveVersion": SaveManager.SAVE_VERSION },
		"currentScreen": "title",
		"modal": null,
		"bagDrawerOpen": false,
		"inventoryTab": "ore",
		"mapNav": { "selectedDistrict": null, "selectedSiteId": null },
		# vein-growth-state ticket 09 (spec §6.2): transient nav state for the
		# vein list screen, same "resets on load, not meaningfully persisted"
		# convention as mapNav/phoneNav/benchNav below. districtId null scopes
		# the list to every district (HQ's Vein Station entry point); a
		# district id scopes it to just that one (the district bubble's own
		# "List view" option). originScreen is which of those two opened it,
		# so the list's own Back button returns there.
		"veinListNav": { "districtId": null, "bandFilter": null, "originScreen": "map" },
		# bugfixes-50: pacingMode joined queue/playing here (moved off a
		# MapCanvas-local instance var) so the player's chosen event-playback
		# pace survives close/reopen and save/load — see MapEvents.
		# pacing_mode()/set_pacing_mode().
		"mapEvents": { "queue": [], "playing": false, "pacingMode": MapEvents.DEFAULT_PACING_MODE },
		# collective1-03: selectedContactId drills into a single conversation
		# the same way selectedAxis drills into a single Ticker axis below.
		# 84-contacts-retire-messages-tile: there's no conversation-list view
		# left for null to mean "show" instead -- a conversation is only ever
		# opened via PhoneNav.select_conversation(), which always sets a real
		# id. revealFromIndex is that same function's staged-reveal handoff to
		# the phone screen (screen-local once consumed; see phone.gd's own
		# _reveal_from_index comment) -- null here just means "no conversation
		# opened yet."
		"phoneNav": { "app": "home", "selectedAxis": null, "selectedContactId": null, "confirmingNewGame": false, "revealFromIndex": null },
		# 53-map-auto-focus-and-zoom-persistence: unlike mapNav/phoneNav/
		# benchNav above/below, this DOES survive save/load (see
		# SaveManager._restore_int_types() for scrollX/scrollY) -- the
		# whole point is that the camera the player left the Network map
		# at is still there next time, on this save or a reloaded one.
		# everOpened gates MapCanvas._apply_initial_view()'s one-shot
		# auto-focus (see systems/map_view.gd): false only for a save
		# that has genuinely never had its map opened yet.
		"mapView": { "everOpened": false, "zoom": MapZoom.DEFAULT, "scrollX": 0, "scrollY": 0 },
		# calc-discovery ticket 03: transient Lab nav, same convention as
		# mapNav/phoneNav — resets on load, not meaningfully persisted.
		# Bugfixes ticket 25: "crafting" joined "home"/"picker"/"pairing"/...
		# as one more legal top-level view -- the combined Lab screen's
		# Crafting section (HQ's old Recipes/Workbench cards). Defaulting
		# to "home" (Experimenting) keeps the Lab's existing default
		# landing unchanged; Crafting is reached via the new section tab.
		"benchNav": { "view": "home", "types": [], "approach": null, "result": null },
		# collective1-02: state.objectives[<id>] = { active, complete, progress
		# }, keyed by data/objectives.json ids -- systems/objectives.gd's
		# Objectives.refresh() is the only writer. progress is per-evaluator-
		# type free-form scratch (activatedDay always; traded_with_faction
		# also stashes a baseline snapshot of factions.<id>.oreSold at the
		# moment the objective activates, so its qty/minTransactions params
		# count only trade that happens during the objective's active
		# window, not from before the player ever met that thread's contact).
		"objectives": {},
		"notifications": [],
		# bugfixes-38: Reynard's transaction log -- every direct player.cash
		# mutation across the codebase logs here via systems/bank.gd's
		# Bank.record(), same append-and-evict-from-front shape as
		# `notifications` above (Bank.LOG_CAP mirrors Notify.LOG_CAP).
		"bankLog": [],
		"sellState": {},
		# bugfixes-57: the Lab's crafting batch-quantity picker, keyed by
		# recipe key -> selected batch size. Same "transient, resets on
		# load, not meaningfully persisted" convention as sellState above --
		# not restored by SaveManager, matching sellState's own precedent.
		"craftQty": {},
		# bugfixes-66: faction marketplace row qty steppers (Guild
		# marketplace's Buy/Sell ×N controls), keyed "<factionId>_<kind>_
		# <itemType>" -> selected qty. Same transient, not-restored-on-load
		# convention as sellState/craftQty above.
		"marketplaceQty": {},
		"event": null,

		"player": {
			"cash": 40,
			"hp": 100, "hpMax": 100,
			"attackMin": 5, "attackMax": 12,
			# calc-effect-wiring-02: Shield's absorption pool (no turn cap --
			# drains on incoming damage until it's gone) and Healing Salve's
			# 2-day heal-over-time timer, both outside the combat dict since
			# they persist across combat's teardown-and-rebuild in
			# Combat.exit_combat().
			"shieldPool": 0,
			"healingSalveDaysLeft": 0, "healingSalveDailyAmount": 0,
			"orichalchum": {},
			"veins": [],
			# ticket 64: quantity per quality tier, not a flat count -- see
			# Crafting's "Inventory" section. Empty buckets == zero stock.
			"inventory": { "timePearl": {}, "enhancementPowder": {}, "rewind": {} },
			"equipment": { "weapon": null },
			"items": [],
			# dial-device ticket 07: replaces the old single-slot device system
			# (equipment.device, devicesInProgress, devicesCompleted -- retired
			# outright per the PRD). A pre-Dial save that still carries those
			# three keys keeps them as harmless orphan data (SaveManager.
			# _backfill_new_player_keys only fills keys ABSENT from a loaded
			# save; it never strips extras) -- nothing reads them any more, so
			# they migrate in effect into this null "dial", per PRD user story
			# 32. null until Dial.attempt_seed() succeeds; there is never a
			# second Dial (Dial.attempt_seed() refuses outright once this is
			# non-null). Shape while seeded: { level, xp, currentCharge,
			# maxCharge, rechargeRate, lastRegenDay, combatRegenTurnCounter,
			# capacityMax, movement, loadedComplications, haftId } -- see
			# systems/dial.gd's new_dial(). lastRegenDay (ticket 04) guards
			# Dial.daily_regen() the same lastResetDay way the old
			# devicesCompleted entries used to guard their own reset.
			"dial": null,
			# dial-device ticket 02: crafted-but-unseated Movements ({
			# archetype, oreType, tier }, see Dial._new_movement()) -- a
			# seated Movement (player.dial.movement) is moved out of here on
			# Dial.seat_movement() and back in on Dial.unseat_movement(),
			# never duplicated or destroyed.
			"movementInventory": [],
			"craftingSkill": 1, "craftingXP": 0,
			"cultivatingSkill": 1, "cultivatingXP": 0,
			"stealthSkill": 1, "stealthXP": 0,
			# calc-discovery ticket 03: the Lab's pure-data state. Known
			# approaches are NOT stored here — Approaches.get_known() (ticket
			# 01) already resolves that live from data/approaches.json + owned
			# home rooms, so caching it here would be a second, syncable-out-
			# of-date source of truth. Cells are written lazily; an absent key
			# means "untried" (systems/bench.gd, ticket 04).
			"bench": { "surveyed": {}, "cells": {}, "notes": {} },
		},

		"world": {
			"day": 1, "timeBlock": 0, "timeBlocksDone": [],
			"archieChatUnlockDay": null,
			"currentDistrict": "shoreditch",
			"sites": [],
			"recentEvents": [],  # D5: [{id, day}] — district-deck no-repeat-within-5-days tracking
			# vein-raiding ticket 07: a successful Direction-B raid attempt
			# against an alarmed vein queues here instead of resolving
			# immediately (Raiding._queue_defend_raid) -- each entry is an
			# outcome dict shaped { attackerId, veinId, siteId, success: true },
			# the same shape resolve_raid_outcome() already consumes. Cleared
			# and re-resolved off-screen (ticket 06's default path) at the
			# start of the next daily_tick's raid-resolution step
			# (Raiding._expire_pending_defend_raids) if the player never
			# travelled to the vein's district in the meantime.
			"pendingDefendRaids": [],
			# The one pending entry (above) currently being fought as a
			# "defend_vein" combat, popped off pendingDefendRaids by
			# Raiding.maybe_trigger_defend() when the player travels into its
			# district. Combat.exit_combat() reads this to resolve a loss via
			# Raiding.resolve_defend_outcome(), then clears it back to null.
			"activeDefendRaid": null,
			# 52-map-vein-line-position-drift: per-district monotonic counter,
			# Sites.next_slot_index()'s backing store. Each site (and each
			# claimed site's extra natural-vein stop) is stamped with a
			# slotIndex the moment it's created and keeps it for life --
			# MapLayout.assign_positions() keys off that stamped value rather
			# than a stop's current position in state.world.sites, which is
			# what let an unrelated site's removal (a prospect reroll, a
			# faction vein collapsing) or insertion (a
			# saturated site's natural-vein bonus landing) silently reflow
			# every later stop's slot. 87-map-slot-index-recycling: this
			# counter alone only ever mints new indices; mapSlotFreePool
			# (below) is where a removed stop's slot goes so it can be handed
			# back out here instead of growing this counter unboundedly.
			"mapSlotCounters": {},
			# 87-map-slot-index-recycling: per-district stack of slotIndex
			# values freed by Sites.release_slot_index() when the stop that
			# owned them stops existing (a site deleted outright, or a
			# vein carrying its own stamped slotIndex -- the saturated-site
			# natural-vein bonus -- removed from player.veins). Sites.
			# next_slot_index() drains this before ever minting a fresh value
			# off mapSlotCounters, so a district's live stop count -- not its
			# lifetime churn -- is what the stopSlots siteCap*2 buffer
			# (bugfixes-98) has to cover.
			"mapSlotFreePool": {},
			# collective1-06: relation-accrual daily-cap tracker, keyed by lane
			# id ("collective", "archie") -> relation points already awarded
			# today. RelationAccrual.reset_daily_caps() clears it on daily_tick.
			"relationAwardedToday": {},
		},

		"home": { "tier": "bedsit", "security": [], "rooms": [], "lastRaidDay": 0 },

		"factions": _new_factions_state(),

		# faction-territory-rivalry T01: a separate, internal-only matrix of
		# every faction's relation *toward* every other faction (directional
		# -- state.factionRelations[a][b] is a's relation toward b, and need
		# not equal state.factionRelations[b][a]). Distinct from
		# state.factions[id].relation above, which is the player-facing
		# player<->faction stat and is never read/written by this matrix.
		"factionRelations": _new_faction_relations_state(),

		"barometer": {
			"economic": "stable", "social": "stable", "political": "stable",
			"progress": {},
			"cooldowns": {},
		},

		# collective1-03: state.messages[<contactId>] = [{ from: "them"|
		# "player", text, day, read }], capped at Messages.CAP (see
		# systems/messages.gd), same append-and-evict-from-front convention
		# as notifications/bankLog above. pendingMessages is the generic
		# runtime-delivery road (spec §5.3) -- entries removed once their
		# action-bar button is tapped.
		"messages": {},
		"pendingMessages": [],
		# collective1-09, spec §5.7: a flat dict of pure-data counters --
		# Act 1 writes exactly one key (methodLog.firmFirstContact, S6's
		# choice card). Ordinary state: Events.rewind() restores it like
		# anything else, which is the deliberate decision closing
		# plans/COLLECTIVE-QUESTLINE.md §8.3 -- Rewind erases the log.
		"methodLog": {},

		"contacts": _new_contacts_state(),

		"combat": {
			"active": false, "context": "raid", "veinId": null, "enemies": [],
			"focusedEnemyIndex": 0, "log": [],
			"outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": null, "snapshots": [],
			# 44-archie-combat-ally: allies fighting alongside the player this
			# combat, general-shaped (see Contacts.build_combat_ally) — empty
			# outside vein-defense fights.
			"allies": [],
		},

		"jamesJob": null,
		"pendingSaleCut": 0,
		# bugfixes-95: Archie's own tag-along deal -- the gross-derived 50/50
		# cut, held here across a mugging fight the same way pendingSaleCut
		# holds the player's own sale cut.
		"pendingArchieDealCut": 0,
		"labThresholds": {},
		"veinStationVeins": [],
		# vein-growth-state ticket 06: plain dict of primitives, purity-safe.
		# Companion to veinStationVeins above -- { veinId: int growth target }.
		"veinStationTargets": {},

		"flags": {
			"tutorialStage": "intro",
			"metArchie": false, "metJames": false, "buyerEventSeen": false,
			"craftingUnlocked": false, "archieCraftChatSeen": false,
			"canSellConsumables": false, "consSoldCount": 0,
			"archieMotionPending": false, "archieMotionEventSeen": false,
			# 83-contacts-archie-james-sms-port: idempotency guard for the
			# day>=2/buyer_event day-tick trigger (TimeSystem._apply_tutorial_
			# day_triggers) so the archie_2 SMS content queues exactly once,
			# not on every day tick until the player acts.
			"archieBuyerSmsQueued": false,
			"jamesMotionEventSeen": false, "enhancementUnlocked": false,
			"jamesJobActive": false, "jamesJobAccepted": false,
			# bugfixes-95: gates ArchieDeals.roll_daily_offer() -- true from the
			# moment an offer is queued until it's declined or its accepted
			# deal (including any mugging fight it triggers) resolves.
			"archieDealActive": false,
			"homeRaidEventPending": false, "homeRaidEventSeen": false, "homeRaidWon": false,
			"archiePartnerSeen": false, "homeUnlocked": false, "securityContactUnlocked": false,
			# M1-LONDON D5 — district event one-shot flags/counters.
			"greenwichTipOff": false, "luckyOmen": false, "conclaveNoticed": false, "oddities": 0,
			# M1-LONDON D6 — cultivating tutorial.
			"cultivationTutorialSeen": false,
			# vein-raiding ticket 03: set by the raid event's stealth_check
			# on_success/on_caught branches, read by the loot_raid_vein op's
			# _event_caught() fallback (systems/events.gd) so the shared
			# claim/loot card knows which path got the player there.
			"raidCaught": false,
			# collective1-05, spec §5.6/§10.2: flips true once (ticket 12's S9
			# scene), never false again -- gates VeinList's Sell option
			# (systems/vein_list.gd) on permanently for every vein from then on.
			"veinSaleUnlocked": false,
			# collective1-07, spec §5.5/§10.2: pre-join lane gate -- Des,
			# Nadia and Hakim's Trade action-bar entry (ContactCards.
			# build_trade_action) reads this, not faction membership.
			"collectiveLaneUnlocked": false,
			# dial-device ticket 01: gates Dial.attempt_seed() -- this PRD only
			# reads it, per Implementation Decisions "Gift gate". Set true only
			# by the Collective Act 2 onboarding quest (out of scope here).
			"dialGiftGranted": false,
			# 01-debug-app: gates the Debug phone app's visibility (PhoneApps.
			# apps()) -- true only via DebugStart.apply()'s existing "force
			# every bool flag true" pass below, never settable any other way,
			# so a normally-started game never sees the tile.
			"debugStartUsed": false,
		},

		# collective1-07, spec §10.1: barkCursors backs Collective._next_bark()'s
		# no-repeat-until-exhausted draw per vendor (contactId -> next index
		# into data/collective_barks.json's array for that contact). Later
		# tickets extend this dict (hakimVeinId, hakimIntelLastDay) rather than
		# each carving out their own top-level state key.
		"collective": {
			"barkCursors": {},
			# collective1-13, spec §6.11/§10.3: the vein col_a1_hakim_meet's
			# grant_contact_vein op hands the player, referenced by id both
			# by col_a1_hakim_rescue's objective (veinIdStatePath) and by
			# S12's thread-resolution event. null until S11 fires.
			"hakimVeinId": null,
			# collective1-17, spec §5.8/§10.1: last day (state.world.day) that
			# col_hakim_intel's daily-tick roll actually completed -- the
			# sentinel 0 means "never", so the first roll is eligible as soon
			# as the 3-day minimum gap (day 1 + 3) has passed. Updated only by
			# col_hakim_intel's own on_complete, not at roll time, so the
			# 3-day gap is measured from when the player actually read the
			# text, not from when Hakim happened to hear the tip.
			"hakimIntelLastDay": 0,
		},
	}


func _new_factions_state() -> Dictionary:
	var factions := {}
	for faction_id in GameData.FACTIONS.keys():
		factions[faction_id] = {
			"relation": 0,
			"joined": false,
			# faction-resource-economy T01: a real ledger balance (income/spend
			# land in later tickets — this only seeds the baseline), distinct
			# from data/factions.json's existing `resourceLevel` (a security-roll
			# opulence input, Factions._security_opulence()). resourceLevel ties
			# Guild to Firm/Network at 2, which doesn't read "Guild richer" per
			# its flavour text, so `startingResources` is its own tiered field:
			# Collective scrappiest, Firm/Network mid, Guild/Conclave richest.
			"resources": GameData.FACTIONS[faction_id].get("startingResources", 0),
			# collective1-02: lifetime cumulative ore sold TO this faction by
			# the player through Economy.execute_faction_sale(), keyed by ore
			# type -- { "<oreType>": { "units": int, "transactions": int } }.
			# Absent ore types read as zero (Objectives' traded_with_faction
			# evaluator uses .get() defaults). Not the same thing as
			# tradeProgress (relation-accrual's £-denominated counter,
			# collective1-06) -- this is unit/transaction-denominated and
			# exists purely for objective evaluation.
			"oreSold": {},
			# collective1-06, spec §8.4: the accumulating £-denominated
			# counter RelationAccrual converts into relation points, carrying
			# any remainder below the lane's rate across trades. Present on
			# every faction for schema uniformity; only "collective" has a
			# configured rate in Act 1 (RelationAccrual.LANES), so it's the
			# only one that ever moves.
			"tradeProgress": 0,
		}
	return factions


# faction-territory-rivalry T01: seeds every ordered pair of the 5 canonical
# factions to a neutral baseline (0). The PRD leaves the exact seed values as
# an open question and only tickets 03/04 (rivalry odds + resolution) ever
# read or write this matrix, so a flat neutral start is the simplest
# defensible choice here -- it makes the day-1 rivalry odds this matrix will
# eventually feed into depend purely on resource/security disparity (ticket
# 03's other two inputs), not on an arbitrary industries-overlap guess this
# ticket has no gameplay evidence to justify. Every relationship still drifts
# from here per ticket 04's "grudges compound" feedback loop.
func _new_faction_relations_state() -> Dictionary:
	var relations := {}
	for a in GameData.FACTIONS.keys():
		var row := {}
		for b in GameData.FACTIONS.keys():
			if b != a:
				row[b] = 0
		relations[a] = row
	return relations


func _new_contacts_state() -> Dictionary:
	var contacts := {}
	for contact_id in GameData.CONTACTS_DEFAULTS.keys():
		var defaults: Dictionary = GameData.CONTACTS_DEFAULTS[contact_id]
		# combat* fields (44-archie-combat-ally): a generic ally-combat block
		# every contact carries, not an archie-only schema addition — a
		# contact whose constants.json entry omits them (james, for now)
		# gets combatHpMax 0, which Contacts.can_join_combat() reads as
		# "this contact has no combat kit, never eligible to join a fight".
		contacts[contact_id] = {
			"relation": defaults.get("startRelation", 0),
			"unlocked": defaults.get("unlocked", false),
			"recruited": false,
			"recruitThreshold": defaults.get("recruitThreshold", 0),
			# collective1-07, spec §7.1/§9.3: defaults true so archie/james
			# (whose constants.json entries now set it explicitly, but any
			# future contact that omits it) render their existing recruit row
			# unchanged -- false suppresses the row entirely (not shown-disabled)
			# for des/nadia/hakim, and gates Contacts.can_recruit() itself so
			# there's no back door to recruiting a "not recruitable, ever"
			# contact even without a UI button for it.
			"recruitable": defaults.get("recruitable", true),
			# 45-archie-raid-assist: a second, higher relation gate on top of
			# recruitThreshold -- can_assist_raid() reads relation against this
			# rather than recruitThreshold, so a contact can be recruited (and
			# combat-eligible via can_join_combat()) well before they're
			# trusted enough to be asked along on an offensive raid. Defaults
			# to 0 for any contact whose constants.json entry omits it
			# (james, for now) -- harmless since can_join_combat()'s own
			# combatHpMax gate already excludes them from ever joining a fight.
			"raidAssistThreshold": defaults.get("raidAssistThreshold", 0),
			"craftingSkill": 1, "craftingXP": 0,
			"cultivatingSkill": 1, "cultivatingXP": 0,
			"stealthSkill": 1, "stealthXP": 0,
			"assignedRoom": null,
			"combatHpMax": defaults.get("combatHpMax", 0),
			"combatHp": defaults.get("combatHpMax", 0),
			"combatAttackMin": defaults.get("combatAttackMin", 0),
			"combatAttackMax": defaults.get("combatAttackMax", 0),
			"combatStashMax": defaults.get("combatStashMax", 0),
			"combatStash": defaults.get("combatStashMax", 0),
			"combatHealAmount": defaults.get("combatHealAmount", 0),
			# squad-combat ticket 02: fixed, authored per-contact turn-order
			# value (not trainable, unlike the player's Combat Skill-driven
			# speed) -- Contacts.build_combat_ally() copies it into the
			# combat.allies entry Combat.build_turn_queue() sorts on.
			"combatSpeed": defaults.get("combatSpeed", 0),
			"koCooldownDays": defaults.get("koCooldownDays", 0),
			"koCooldownUntilDay": null,
			# collective1-06, spec §8.4: same £-denominated accrual counter as
			# state.factions[id].tradeProgress above, but for Archie -- he has
			# no faction, he *is* the lane, so his accumulator lives here.
			# Present on every contact for schema uniformity; only "archie"
			# has a configured rate (RelationAccrual.LANES).
			"tradeProgress": 0,
		}
	return contacts


# Dot-path convenience reader, e.g. read_path("player.cash"). Named
# read_path (not get_path) because Node already declares a native
# get_path() -> NodePath — GameState is an autoload extending Node, so
# reusing that name silently overrides the engine's method instead of
# declaring a new one, which Godot 4.4 now treats as a hard parse error.
# Not a replacement for direct dict access (systems should still
# read/write `state` directly) — just a small helper for tests/
# notifications that want a value without knowing which layer holds it.
func read_path(path: String, default: Variant = null) -> Variant:
	var current: Variant = state
	for part in path.split("."):
		if current is Dictionary and current.has(part):
			current = current[part]
		else:
			return default
	return current


# Recursive deep copy of a pure data value (Dictionary/Array/primitive).
# What Snapshots.gd and SaveManager.gd build on.
static func deep_copy(value: Variant) -> Variant:
	if value is Dictionary:
		var copy := {}
		for key in value.keys():
			copy[key] = deep_copy(value[key])
		return copy
	elif value is Array:
		var copy := []
		for item in value:
			copy.append(deep_copy(item))
		return copy
	else:
		return value


# round() with a tiny epsilon safety margin. Use this (never plain round())
# anywhere a price/cost/etc. is rounded from a computed multiplier — IEEE-754
# double precision means e.g. 90 * (1 - 0.35 + 0.5) evaluates to
# 103.49999999999999, not exactly 103.5, so a literal round() lands on 103
# where the intended math (and REFERENCE.md's worked examples) says 104.
static func round_epsilon(value: float) -> int:
	return int(round(value + 0.000000001))
