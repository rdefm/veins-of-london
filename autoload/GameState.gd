extends Node

# The entire game state: one pure data tree (Dictionaries/Arrays/primitives
# only — no object references, no Nodes, no Callables). This purity is what
# makes save, snapshot, and Rewind work. Systems read/write `state` directly
# and emit EventBus.state_changed; screens only ever read it. Not one line
# of screen code mutates this directly.

var state: Dictionary = {}


func _ready() -> void:
	EventBus.shared_stock_increased.connect(_on_shared_stock_increased)
	reset()


func _on_shared_stock_increased() -> void:
	# Deferred script lookup avoids a Contracts <-> Crafting compile cycle:
	# Contracts consumes crafted stock, while crafting emits this stock-change
	# boundary after a successful addition.
	var contracts_script: GDScript = load("res://systems/contracts.gd")
	contracts_script.shared_stock_increased()


func reset() -> void:
	state = new_game_state()
	# A fresh game boots straight into the tutorial questline's first
	# checkpoint (data/objectives.json's activateFlag: null case) -- it must
	# read as active before any other action-boundary caller has run.
	Objectives.refresh()


func new_game_state() -> Dictionary:
	return {
		"meta": { "saveVersion": SaveManager.SAVE_VERSION },
		"currentScreen": "title",
		"modal": null,
		"bagDrawerOpen": false,
		"inventoryTab": "ore",
		"mapNav": { "selectedDistrict": null, "selectedSiteId": null },
		# Transient nav state for the vein list screen, resets on load like
		# mapNav/phoneNav/labBenchNav. districtId null scopes the list to
		# every district (HQ's Vein Station entry point); a district id
		# scopes it to just that one (the district bubble's "List view").
		# originScreen is which of those opened it, for the Back button.
		"veinListNav": { "districtId": null, "bandFilter": null, "originScreen": "map" },
		# pacingMode lives here (not a MapCanvas-local var) so the player's
		# chosen event-playback pace survives close/reopen and save/load --
		# see MapEvents.pacing_mode()/set_pacing_mode().
		"mapEvents": { "queue": [], "playing": false, "pacingMode": MapEvents.DEFAULT_PACING_MODE },
		# selectedContactId drills into a single conversation the same way
		# selectedAxis drills into a single Ticker axis below; a conversation
		# is only ever opened via PhoneNav.select_conversation(), which
		# always sets a real id. revealFromIndex is that function's
		# staged-reveal handoff to the phone screen (screen-local once
		# consumed) -- null means "no conversation opened yet."
		"phoneNav": { "app": "home", "selectedAxis": null, "selectedContactId": null, "confirmingNewGame": false, "revealFromIndex": null },
		# Unlike mapNav/phoneNav/labBenchNav, this DOES survive save/load
		# (see SaveManager._restore_int_types() for scrollX/scrollY) -- the
		# camera the player left the Network map at is still there next time.
		# everOpened gates MapCanvas._apply_initial_view()'s one-shot
		# auto-focus (systems/map_view.gd): false only for a save that has
		# genuinely never had its map opened yet.
		"mapView": { "everOpened": false, "zoom": MapZoom.DEFAULT, "scrollX": 0, "scrollY": 0 },
		# The diegetic Lab bench's own nav state (docs/hq-diorama-vision.md
		# §5), resets on load like mapNav/phoneNav above. stop is which focal
		# stop (systems/lab_bench_nav.gd's STOPS) is in frame; mode is which
		# notebook ("recipes"/"experiments") is held open, or null at the
		# fork -- unlike stop, mode is NOT reset by LabBenchNav.open(), so
		# re-entering the bench keeps the player's last-chosen mode.
		# selectedOre is up to 2 ore-type ids picked at the ore stop (§5.4),
		# reset by LabBenchNav.open() (unlike mode) so re-entering never
		# opens on a stale pairing.
		"labBenchNav": { "stop": "books_ore", "mode": null, "selectedOre": [] },
		# state.objectives[<id>] = { active, complete, progress }, keyed by
		# data/objectives.json ids -- systems/objectives.gd's Objectives.
		# refresh() is the only writer. progress is per-evaluator-type
		# free-form scratch (activatedDay always; traded_with_faction also
		# stashes a baseline snapshot of factions.<id>.oreSold at activation,
		# so its qty/minTransactions params count only trade during the
		# objective's active window).
		"objectives": {},
		"notifications": [],
		# Reynard's transaction log -- every direct player.cash mutation logs
		# here via systems/bank.gd's Bank.record(), same append-and-evict-
		# from-front shape as `notifications` above.
		"bankLog": [],
		# latest is the compact account captured from one completed daily
		# tick; autoOpenedDay is the once-only presentation receipt. Both
		# persist so reopening never reruns daily processing.
		"morningAccounts": { "latest": null, "autoOpenedDay": 0 },
		"sellState": {},
		# Serializable pending-offer and accepted-contract ledger.
		"sales": { "pendingOffers": [], "activeContracts": [], "priorityOrder": [], "contractHistory": [], "settlements": [], "nextOfferId": 1, "nextContractId": 1, "nextPeriodId": 1, "nextSettlementId": 1 },
		# The "default-then-review" payroll model (R§3.10): no mid-tick
		# blocking pause exists, so there's nothing to resume on reload;
		# paidToday (room id -> bool) is recomputed fresh by Payroll.
		# pay_wages() every rollover. lastSummary is the persisted record of
		# the most recent rollover's result -- { day, entries: [{room,
		# contactId, wage, paid}] } -- overwritten next rollover.
		"payroll": { "paidToday": {}, "lastSummary": null },
		# The Lab's crafting batch-quantity picker, keyed by recipe key ->
		# selected batch size. Transient, not restored by SaveManager, same
		# convention as sellState above.
		"craftQty": {},
		# Faction marketplace row qty steppers (Guild marketplace's Buy/Sell
		# ×N controls), keyed "<factionId>_<kind>_<itemType>" -> selected
		# qty. Same transient convention as sellState/craftQty above.
		"marketplaceQty": {},
		# Personal-stash move-qty stepper, keyed "ore_<oreType>" /
		# "item_<recipeKey>" -- one shared qty per row for both the stash and
		# unstash button on that row. Transient, not restored on load.
		"stashQty": {},
		"event": null,

		"player": {
			"cash": 40,
			"hp": 100, "hpMax": 100,
			"attackMin": 5, "attackMax": 12,
			# Shield's absorption pool (no turn cap -- drains on incoming
			# damage until it's gone) and Healing Salve's 2-day heal-over-time
			# timer, both outside the combat dict since they persist across
			# combat's teardown-and-rebuild in Combat.exit_combat().
			"shieldPool": 0,
			"healingSalveDaysLeft": 0, "healingSalveDailyAmount": 0,
			"orichalchum": {},
			"veins": [],
			# Quantity per quality tier, not a flat count -- see Crafting's
			# "Inventory" section. Empty buckets == zero stock.
			"inventory": { "timePearl": {}, "enhancementPowder": {}, "rewind": {} },
			# The personal stash -- a second ore/crafted-item pool no business
			# system (contracts, Sales, Production, Procurement) can touch. A
			# stashed unit is subtracted from orichalchum/inventory above the
			# moment it moves in (systems/stash.gd), so it's a transfer
			# destination, not a second view. Same shapes as the pools above:
			# flat oreType->qty, and tier-bucketed recipeKey->{tier:qty}.
			"stash": { "orichalchum": {}, "inventory": {} },
			"equipment": { "weapon": null },
			"items": [],
			# null until Dial.attempt_seed() succeeds; there is never a second
			# Dial (attempt_seed() refuses outright once this is non-null).
			# Shape while seeded: { level, xp, currentCharge, maxCharge,
			# rechargeRate, lastRegenDay, combatRegenTurnCounter, capacityMax,
			# movement, loadedComplications, haftId } -- see systems/dial.gd's
			# new_dial(). lastRegenDay guards Dial.daily_regen() the same
			# lastResetDay way other daily-reset fields guard their own reset.
			"dial": null,
			# Crafted-but-unseated Movements ({ archetype, oreType, tier },
			# see Dial._new_movement()) -- a seated Movement (player.dial.
			# movement) is moved out of here on Dial.seat_movement() and back
			# in on Dial.unseat_movement(), never duplicated or destroyed.
			"movementInventory": [],
			"craftingSkill": 1, "craftingXP": 0,
			"cultivatingSkill": 1, "cultivatingXP": 0,
			"stealthSkill": 1, "stealthXP": 0,
			# Attack bonus + turn-order speed, both level-indexed
			# (GameData.COMBAT_ATTACK_BONUS_BY_LEVEL/COMBAT_SPEED_BY_LEVEL,
			# R§3.7a) — leveled via the same Progression.award_xp() mechanism
			# as craftingSkill/cultivatingSkill above.
			"combatSkill": 1, "combatXP": 0,
			# The Lab's pure-data state. Known approaches are NOT stored here
			# — Approaches.get_known() already resolves that live from
			# data/approaches.json + owned home rooms, so caching it here
			# would be a second, syncable-out-of-date source of truth. Cells
			# are written lazily; an absent key means "untried".
			"bench": { "surveyed": {}, "cells": {}, "notes": {} },
		},

		"world": {
			"day": 1, "timeBlock": 0, "timeBlocksDone": [],
			"archieChatUnlockDay": null,
			"currentDistrict": "shoreditch",
			"sites": [],
			"recentEvents": [],  # D5: [{id, day}] — district-deck no-repeat-within-5-days tracking
			# A successful raid attempt against an alarmed vein (R§3.12) queues
			# here instead of resolving immediately (Raiding._queue_defend_raid)
			# -- each entry is an outcome dict shaped { attackerId, veinId,
			# siteId, success: true }, the shape resolve_raid_outcome() consumes.
			# Cleared and re-resolved off-screen at the start of the next
			# daily_tick's raid-resolution step (Raiding.
			# _expire_pending_defend_raids) if the player never travelled to
			# the vein's district in the meantime.
			"pendingDefendRaids": [],
			# The one pending entry (above) currently being fought as a
			# "defend_vein" combat, popped off pendingDefendRaids by
			# Raiding.maybe_trigger_defend() when the player travels into its
			# district. Combat.exit_combat() reads this to resolve a loss via
			# Raiding.resolve_defend_outcome(), then clears it back to null.
			"activeDefendRaid": null,
			# Per-district monotonic counter, Sites.next_slot_index()'s
			# backing store. Each site (and each claimed site's extra
			# natural-vein stop) is stamped with a slotIndex the moment it's
			# created and keeps it for life -- MapLayout.assign_positions()
			# keys off that stamped value rather than a stop's current
			# position in state.world.sites, so an unrelated site's removal or
			# insertion never reflows a later stop's slot. This counter only
			# mints new indices; mapSlotFreePool (below) is where a vacated
			# stop's slot goes so it can be handed back out here instead of
			# growing this counter unboundedly.
			"mapSlotCounters": {},
			# Per-district stack of slotIndex values freed by Sites.
			# release_slot_index() when the stop that owned them stops
			# existing. Sites.next_slot_index() drains this before minting a
			# fresh value off mapSlotCounters, so a district's live stop
			# count -- not its lifetime churn -- is what the stopSlots
			# siteCap*2 buffer has to cover.
			"mapSlotFreePool": {},
			# Relation-accrual daily-cap tracker, keyed by lane id
			# ("collective", "archie") -> relation points already awarded
			# today. RelationAccrual.reset_daily_caps() clears it on daily_tick.
			"relationAwardedToday": {},
		},

		# A successful daily raid attempt against an alarmed HQ queues here
		# instead of resolving immediately (Home._queue_pending_raid) --
		# mirrors world.pendingDefendRaids/activeDefendRaid, just collapsed
		# to a single flag since HQ has exactly one raid slot, not one per
		# vein. pendingRaidNotificationId is the queued warning's own Notify
		# id, so a stale already-resolved warning sitting in the (capped, not
		# cleared) log can't reactivate its Defend button once HQ is raided
		# again later. guardCount is the Hired Guard security upgrade's
		# stack count -- unlike every other id in "security" (boolean
		# membership), "guard" is never appended there; see Home.
		# GUARD_SECURITY_ID.
		"home": { "tier": "bedsit", "security": [], "rooms": [], "lastRaidDay": 0, "pendingRaid": false, "pendingRaidNotificationId": null, "guardCount": 0 },

		"factions": _new_factions_state(),

		# A separate, internal-only matrix of every faction's relation
		# *toward* every other faction (directional -- state.
		# factionRelations[a][b] is a's relation toward b, and need not equal
		# [b][a]). Distinct from state.factions[id].relation above, which is
		# the player-facing player<->faction stat.
		"factionRelations": _new_faction_relations_state(),

		"barometer": {
			"economic": "stable", "social": "stable", "political": "stable",
			"progress": {},
			"cooldowns": {},
		},

		# state.messages[<contactId>] = [{ from: "them"|"player", text, day,
		# read }], capped at Messages.CAP (systems/messages.gd), same
		# append-and-evict-from-front convention as notifications/bankLog
		# above. pendingMessages is the generic runtime-delivery road --
		# entries clear once their action-bar button is tapped.
		"messages": {},
		"pendingMessages": [],
		# A flat dict of pure-data counters -- Act 1 writes exactly one key
		# (methodLog.firmFirstContact). Ordinary state: Events.rewind()
		# restores it like anything else (plans/COLLECTIVE-QUESTLINE.md
		# §8.3's deliberate decision that Rewind erases the log).
		"methodLog": {},

		"contacts": _new_contacts_state(),

		"combat": {
			"active": false, "context": "raid", "veinId": null, "enemies": [],
			"focusedEnemyIndex": 0, "log": [],
			"outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": null, "snapshots": [], "beatsSinceSnapshot": [],
			# Allies fighting alongside the player this combat, general-shaped
			# (see Contacts.build_combat_ally) — empty outside vein-defense fights.
			"allies": [],
		},
		# Outside state.combat itself since exit_combat() resets that dict to
		# fresh defaults on every fight's end -- see systems/
		# combat_pacing.gd's own comment.
		"combatPacingMode": CombatPacing.DEFAULT_MODE,

		# The bounded solo combat prototype's own state tree, fully separate
		# from "combat" above so nothing here can touch production combat
		# state -- see systems/combat_prototype.gd's top comment. Resets on
		# load, not meaningfully persisted (same convention as mapNav/
		# veinListNav above): a prototype fight mid-flight at save time isn't
		# worth resurrecting.
		"combatPrototype": {
			"active": false, "encounterId": "", "wave": 0, "totalWaves": 1, "round": 0, "outcome": null, "log": [],
			"player": { "hp": 0, "hpMax": 0, "committedAction": null, "committedTarget": null, "committedItem": null, "exhaustedNextTurn": false, "stanceTriggered": false, "shieldPool": 0 },
			"enemies": [],
			"frozenTurns": 0, "motionTurns": 0, "motionPower": 0, "blastFleeBoost": false,
			"snapshots": [], "beatsSinceSnapshot": [],
			"_pending": null, "_waveCleared": false,
		},

		"jamesJob": null,
		"pendingSaleCut": 0,
		# Archie's own tag-along deal -- the gross-derived 50/50 cut, held
		# here across a mugging fight the same way pendingSaleCut holds the
		# player's own sale cut.
		"pendingArchieDealCut": 0,
		"labThresholds": {},
		# Per-recipe opt-in, { recipeKey: bool }. When true, Production's
		# effective target for that recipe adds undelivered active-contract
		# need on top of labThresholds -- see Rooms.effective_lab_target/
		# production_reserved_qty.
		"labCoverContracts": {},
		"veinStationVeins": [],
		# Plain dict of primitives, purity-safe. Companion to
		# veinStationVeins above -- { veinId: int growth target }.
		"veinStationTargets": {},

		"flags": {
			"tutorialStage": "intro",
			"metArchie": false, "metJames": false, "buyerEventSeen": false,
			"craftingUnlocked": false, "archieCraftChatSeen": false,
			"canSellConsumables": false, "consSoldCount": 0,
			"archieMotionPending": false, "archieMotionEventSeen": false,
			# Idempotency guard for the day>=2/buyer_event day-tick trigger
			# (TimeSystem._apply_tutorial_day_triggers) so the archie_2 SMS
			# content queues exactly once, not on every tick until the player acts.
			"archieBuyerSmsQueued": false,
			"jamesMotionEventSeen": false, "enhancementUnlocked": false,
			"jamesJobActive": false, "jamesJobAccepted": false,
			# Gates ArchieDeals.roll_daily_offer() -- true from the moment an
			# offer is queued until it's declined or its accepted deal
			# (including any mugging fight it triggers) resolves.
			"archieDealActive": false,
			"homeRaidEventPending": false, "homeRaidEventSeen": false, "homeRaidWon": false,
			"archiePartnerSeen": false, "homeUnlocked": false, "securityContactUnlocked": false,
			# M1-LONDON D5 — district event one-shot flags/counters.
			"greenwichTipOff": false, "luckyOmen": false, "conclaveNoticed": false, "oddities": 0,
			# M1-LONDON D6 — cultivating tutorial.
			"cultivationTutorialSeen": false,
			# Set by the raid event's stealth_check on_success/on_caught
			# branches, read by loot_raid_vein's _event_caught() fallback
			# (systems/events.gd) so the shared claim/loot card knows which
			# path got the player there.
			"raidCaught": false,
			# Flips true once, never false again -- gates VeinList's Sell
			# option (systems/vein_list.gd) on permanently for every vein
			# from then on.
			"veinSaleUnlocked": false,
			# Pre-join lane gate -- Des, Nadia and Hakim's Trade action-bar
			# entry (ContactCards.build_trade_action) reads this, not
			# faction membership.
			"collectiveLaneUnlocked": false,
			# Gates Dial.attempt_seed() (R§3.5's Gift gate). Set true only by
			# the Collective Act 2 onboarding quest (out of scope here).
			"dialGiftGranted": false,
			# Gates the Debug phone app's visibility (PhoneApps.apps()) --
			# true only via DebugStart.apply()'s "force every bool flag true"
			# pass below, never settable any other way, so a normally-started
			# game never sees the tile.
			"debugStartUsed": false,
		},

		# barkCursors backs Collective._next_bark()'s no-repeat-until-
		# exhausted draw per vendor (contactId -> next index into data/
		# collective_barks.json's array for that contact). Later additions
		# extend this dict rather than each carving out their own top-level
		# state key.
		"collective": {
			"barkCursors": {},
			# The vein col_a1_hakim_meet's grant_contact_vein op hands the
			# player, referenced by id both by col_a1_hakim_rescue's
			# objective (veinIdStatePath) and by the thread-resolution event.
			# null until that event fires.
			"hakimVeinId": null,
			# Last day (state.world.day) that col_hakim_intel's daily-tick
			# roll actually completed -- the sentinel 0 means "never", so the
			# first roll is eligible once the 3-day minimum gap has passed.
			# Updated only by col_hakim_intel's own on_complete, not at roll
			# time, so the gap is measured from when the player actually read
			# the text, not from when Hakim heard the tip.
			"hakimIntelLastDay": 0,
		},
	}


func _new_factions_state() -> Dictionary:
	var factions := {}
	for faction_id in GameData.FACTIONS.keys():
		factions[faction_id] = {
			"relation": 0,
			"joined": false,
			# A real ledger balance, distinct from data/factions.json's
			# `resourceLevel` (a security-roll opulence input, Factions.
			# _security_opulence()). resourceLevel ties Guild to Firm/Network
			# at 2, which doesn't read "Guild richer" per its flavour text, so
			# `startingResources` is its own tiered field: Collective
			# scrappiest, Firm/Network mid, Guild/Conclave richest.
			"resources": GameData.FACTIONS[faction_id].get("startingResources", 0),
			# Lifetime cumulative ore sold TO this faction by the player
			# through Economy.execute_faction_sale(), keyed by ore type --
			# { "<oreType>": { "units": int, "transactions": int } }. Absent
			# ore types read as zero. Not the same as tradeProgress
			# (relation-accrual's £-denominated counter below) -- this is
			# unit/transaction-denominated and exists purely for objective
			# evaluation.
			"oreSold": {},
			# The accumulating £-denominated counter RelationAccrual converts
			# into relation points, carrying any remainder below the lane's
			# rate across trades. Present on every faction for schema
			# uniformity; only "collective" has a configured rate in Act 1
			# (RelationAccrual.LANES), so it's the only one that ever moves.
			"tradeProgress": 0,
			# A limited, independently-scarce stock per ore type (systems/
			# factions.gd's Factions.restock_ore()/maybe_restock_ore()),
			# which the buy lane draws against -- { "<oreType>": int },
			# absent types read as 0. Present on every faction for schema
			# uniformity, but only ever rolled/read for "collective" in this
			# milestone. Independent of relation -- relation only narrows
			# Economy.get_faction_buy_spread/get_faction_sell_spread's price,
			# never this quantity ceiling.
			"oreStock": {},
		}
	return factions


# Seeds every ordered pair of the 5 canonical factions to a neutral
# baseline (0) -- a flat start keeps the rivalry odds this matrix feeds into
# dependent purely on resource/security disparity, not an unjustified
# industries-overlap guess. Every relationship still drifts from here via
# the "grudges compound" feedback loop.
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
		# combat* fields: a generic ally-combat block every contact carries,
		# not an archie-only schema addition — a contact whose constants.json
		# entry omits them (james, for now) gets combatHpMax 0, which
		# Contacts.can_join_combat() reads as "no combat kit, never eligible".
		contacts[contact_id] = {
			"relation": defaults.get("startRelation", 0),
			"unlocked": defaults.get("unlocked", false),
			"recruited": false,
			"recruitThreshold": defaults.get("recruitThreshold", 0),
			# Defaults true so contacts whose constants.json entry omits it
			# render their recruit row unchanged -- false suppresses the row
			# entirely (not shown-disabled) and gates Contacts.can_recruit()
			# itself, so there's no back door to recruiting a "not
			# recruitable, ever" contact even without a UI button for it.
			"recruitable": defaults.get("recruitable", true),
			# A second, higher relation gate on top of recruitThreshold --
			# can_assist_raid() reads relation against this rather than
			# recruitThreshold, so a contact can be recruited (and combat-
			# eligible via can_join_combat()) well before they're trusted
			# enough to be asked along on an offensive raid. Defaults to 0
			# for any contact whose entry omits it -- harmless since
			# can_join_combat()'s own combatHpMax gate already excludes them.
			"raidAssistThreshold": defaults.get("raidAssistThreshold", 0),
			"craftingSkill": 1, "craftingXP": 0,
			"cultivatingSkill": 1, "cultivatingXP": 0,
			"stealthSkill": 1, "stealthXP": 0,
			# Same skill-threshold-ladder mechanism as craftingSkill/
			# cultivatingSkill above (Contacts.award_contact_xp(), GameData.
			# SALES_XP_LEVELS) -- gated by the Operations Room via the same
			# assignedRoom mechanism below, not a parallel state model.
			"salesSkill": 1, "salesXP": 0,
			"assignedRoom": null,
			"combatHpMax": defaults.get("combatHpMax", 0),
			"combatHp": defaults.get("combatHpMax", 0),
			"combatAttackMin": defaults.get("combatAttackMin", 0),
			"combatAttackMax": defaults.get("combatAttackMax", 0),
			"combatStashMax": defaults.get("combatStashMax", 0),
			"combatStash": defaults.get("combatStashMax", 0),
			"combatHealAmount": defaults.get("combatHealAmount", 0),
			# Fixed, authored per-contact turn-order value (not trainable,
			# unlike the player's Combat Skill-driven speed) -- Contacts.
			# build_combat_ally() copies it into the combat.allies entry
			# Combat.build_turn_queue() sorts on.
			"combatSpeed": defaults.get("combatSpeed", 0),
			"koCooldownDays": defaults.get("koCooldownDays", 0),
			"koCooldownUntilDay": null,
			# Same £-denominated accrual counter as state.factions[id].
			# tradeProgress above, but for Archie -- he has no faction, he
			# *is* the lane, so his accumulator lives here. Present on every
			# contact for schema uniformity; only "archie" has a configured
			# rate (RelationAccrual.LANES).
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
