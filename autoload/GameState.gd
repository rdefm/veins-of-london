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
		# mapNav/veinListNav/phoneNav/labBenchNav are transient nav state,
		# reset on load -- mapView below is the one exception.
		"mapNav": { "selectedDistrict": null, "selectedSiteId": null, "selectedVeinId": null },
		# districtId null scopes to every district (HQ's Vein Station
		# entry); a district id scopes to just that one (a district
		# bubble's "List view"). originScreen is which opened it, for Back.
		"veinListNav": { "districtId": null, "bandFilter": null, "originScreen": "map" },
		# pacingMode lives here (not MapCanvas-local) so the player's chosen
		# event-playback pace survives close/reopen and save/load.
		"mapEvents": { "queue": [], "playing": false, "pacingMode": MapEvents.DEFAULT_PACING_MODE },
		# selectedContactId drills into one conversation, set only via
		# PhoneNav.select_conversation() (always a real id), same way
		# selectedAxis drills into a Ticker axis. revealFromIndex is that
		# function's staged-reveal handoff; null = unopened.
		"phoneNav": { "app": "home", "selectedAxis": null, "selectedContactId": null, "confirmingNewGame": false, "revealFromIndex": null },
		# The one exception above: survives save/load (SaveManager restores
		# scrollX/scrollY as ints), so camera position persists. everOpened
		# gates MapCanvas's one-shot auto-focus, false until first map open.
		"mapView": { "everOpened": false, "zoom": MapZoom.DEFAULT, "scrollX": 0, "scrollY": 0 },
		# Lab bench nav (docs/hq-diorama-vision.md §5). stop is the focal
		# stop in frame; mode (the held-open notebook) persists across
		# re-entry, unlike selectedOre (up to 2 ids, §5.4), which
		# open() always resets so re-entry never opens on a stale pairing.
		"labBenchNav": { "stop": "books_ore", "mode": null, "selectedOre": [] },
		# state.objectives[<id>] = { active, complete, progress }, keyed by
		# data/objectives.json ids; Objectives.refresh() is the only writer.
		# progress is per-evaluator scratch data -- e.g. traded_with_faction
		# baselines factions.<id>.oreSold at activation so qty/
		# minTransactions count only trade during the active window.
		"objectives": {},
		"notifications": [],
		# Reynard's transaction log -- every player.cash mutation logs here
		# via Bank.record(), same evict-from-front shape as notifications.
		"bankLog": [],
		# latest is one completed daily tick's compact account;
		# autoOpenedDay is the once-only presentation receipt -- both
		# persist so reopening never reruns daily processing.
		# blockProduction accumulates today's staff block output until the
		# next rollover folds it into latest.
		"morningAccounts": { "latest": null, "autoOpenedDay": 0, "blockProduction": { "ore": {}, "items": {}, "oreMovement": {} } },
		"sellState": {},
		# Serializable pending-offer and accepted-contract ledger.
		"sales": { "pendingOffers": [], "activeContracts": [], "priorityOrder": [], "contractHistory": [], "settlements": [], "nextOfferId": 1, "nextContractId": 1, "nextPeriodId": 1, "nextSettlementId": 1 },
		# "Default-then-review" payroll (R§3.10): no mid-tick blocking
		# pause, so nothing to resume on reload. paidToday (room id -> bool)
		# is recomputed fresh every rollover; lastSummary is the last
		# rollover's result ({ day, entries: [{room, contactId, wage,
		# paid}] }), overwritten next rollover.
		"payroll": { "paidToday": {}, "lastSummary": null },
		# Business pot (R§3.10 "Business pot and payday"): while potActive,
		# contract settlements pay into pot; payday splits it every
		# paydayIntervalDays. wages keys a waged contact id -> { weekly, owed,
		# unpaid, hiredDay, daysWorked, promptPending }; ledger holds one
		# record per payday.
		"business": {
			"potActive": false, "pot": 0,
			"week": { "startDay": 1, "receipts": 0, "expenses": [] },
			"partners": [], "wages": {}, "ledger": [], "nextPaydayId": 1,
		},
		# Archie's Beat 2 starter-offer chain (systems/business_quest.gd):
		# which starter template is next, and the day it may be (re)issued
		# (null = as soon as none is outstanding).
		"businessQuest": { "starterIndex": 0, "starterReissueDay": null },
		# Transient UI qty-steppers, not restored by SaveManager (same
		# convention as sellState): craftQty keys recipe key -> batch size;
		# marketplaceQty keys "<factionId>_<kind>_<itemType>" -> qty; stashQty
		# keys "ore_<oreType>"/"item_<recipeKey>" -> qty, shared by a row's
		# stash/unstash buttons.
		"craftQty": {},
		"marketplaceQty": {},
		"stashQty": {},
		"event": null,

		"player": {
			"cash": 40,
			# Playable protagonist -- a data/combat_visuals.json templates key.
			"model": "protagonist2",
			"hp": 100, "hpMax": 100,
			"attackMin": 5, "attackMax": 12,
			# Shield absorption pool (no turn cap) and Healing Salve's
			# 2-day heal-over-time timer -- both persist across
			# Combat.exit_combat()'s teardown/rebuild.
			"shieldPool": 0,
			"healingSalveDaysLeft": 0, "healingSalveDailyAmount": 0,
			"orichalchum": {},
			"veins": [],
			# Quantity per quality tier, not a flat count. Empty buckets ==
			# zero stock.
			"inventory": { "timePearl": {}, "enhancementPowder": {}, "rewind": {} },
			# Lifetime successful-craft count per recipeKey, flat, never
			# decremented -- backs Objectives' items_crafted_set evaluator.
			"craftedCounts": {},
			# Second pool no business system (contracts, Sales, Production,
			# Procurement) can touch -- systems/stash.gd subtracts a stashed
			# unit from orichalchum/inventory the moment it moves in, so
			# this is a transfer destination, not a second view.
			"stash": { "orichalchum": {}, "inventory": {} },
			"equipment": { "weapon": null },
			"items": [],
			# null until Dial.attempt_seed() succeeds (refuses outright
			# once non-null). Seeded shape: { level, xp, currentCharge,
			# maxCharge, rechargeRate, lastRegenDay, combatRegenTurnCounter,
			# capacityMax, movement, loadedComplications, haftId }.
			"dial": null,
			# Crafted-but-unseated Movements ({ archetype, oreType, tier }) --
			# moved out on Dial.seat_movement(), back in on unseat_movement().
			"movementInventory": [],
			"craftingSkill": 1, "craftingXP": 0,
			"cultivatingSkill": 1, "cultivatingXP": 0,
			"stealthSkill": 1, "stealthXP": 0,
			# Attack bonus + turn-order speed, level-indexed (GameData.
			# COMBAT_ATTACK_BONUS_BY_LEVEL/COMBAT_SPEED_BY_LEVEL, R§3.7a).
			"combatSkill": 1, "combatXP": 0,
			# Lab's pure-data state. Known approaches are NOT stored here --
			# Approaches.get_known() resolves that live, so caching here
			# would be a second, driftable source of truth. Cells write
			# lazily; absent key means "untried".
			"bench": { "surveyed": {}, "cells": {}, "notes": {} },
		},

		"world": {
			"day": 1, "timeBlock": 0, "timeBlocksDone": [],
			"archieChatUnlockDay": null,
			"currentDistrict": "shoreditch",
			"sites": [],
			"recentEvents": [],  # D5: [{id, day}] — district-deck no-repeat-within-5-days tracking
			# A successful raid on an alarmed vein (R§3.12) queues here
			# instead of resolving immediately; each entry is { attackerId,
			# veinId, siteId, success: true }. Any still-pending entry
			# resolves off-screen at the next daily_tick if the player
			# never travelled to that district.
			"pendingDefendRaids": [],
			# The pendingDefendRaids entry currently fought as a
			# "defend_vein" combat -- popped on travel into its district,
			# cleared back to null when Combat.exit_combat() resolves it.
			"activeDefendRaid": null,
			# Per-district monotonic counter for stop slotIndex stamps,
			# minted for life the moment a stop is created; MapLayout.
			# assign_positions() keys off the stamp, not a stop's position
			# in state.world.sites, so removing/inserting an unrelated site
			# never reflows another's slot. Mints new indices only --
			# mapSlotFreePool below recycles vacated ones.
			"mapSlotCounters": {},
			# Per-district stack of slotIndex values freed when their stop
			# stops existing, drained before minting fresh off
			# mapSlotCounters.
			"mapSlotFreePool": {},
			# Relation-accrual daily-cap tracker, keyed by lane id
			# ("collective", "archie") -> points already awarded today,
			# cleared on daily_tick. Also holds Collective.A2_DEFEND_AWARD_KEY
			# (Act 2's alarm-defend award cap, spec §7.3).
			"relationAwardedToday": {},
		},

		# A successful raid on alarmed HQ queues here instead of resolving
		# immediately -- mirrors world.pendingDefendRaids/activeDefendRaid,
		# collapsed to one flag since HQ has one raid slot.
		# pendingRaidNotificationId is that warning's Notify id, so a stale
		# resolved warning can't reactivate its Defend button. guardCount is
		# the Hired Guard stack count -- unlike other security ids (boolean
		# membership), "guard" is never appended to `security`.
		# tenure is "rented"/"owned" (ADR 0006); arrears is unpaid bill £, arrearsDays the consecutive rollovers in arrears.
		"home": { "tier": "bedsit", "tenure": "rented", "arrears": 0, "arrearsDays": 0, "security": [], "rooms": [], "lastRaidDay": 0, "pendingRaid": false, "pendingRaidNotificationId": null, "guardCount": 0 },

		"factions": _new_factions_state(),

		# Internal-only directional matrix: factionRelations[a][b] is a's
		# relation toward b (need not equal [b][a]) -- distinct from
		# state.factions[id].relation, the player<->faction stat.
		"factionRelations": _new_faction_relations_state(),

		"barometer": {
			"economic": "stable", "social": "stable", "political": "stable",
			"progress": {},
			"cooldowns": {},
		},

		# state.messages[<contactId>] = [{ from: "them"|"player", text, day,
		# read }], capped at Messages.CAP, same evict-from-front convention
		# as notifications/bankLog. pendingMessages is the runtime-delivery
		# queue, cleared as each entry's action-bar button is tapped.
		"messages": {},
		"pendingMessages": [],
		# Flat dict of pure-data counters -- Act 1 writes exactly one key
		# (methodLog.firmFirstContact). Rewind erases it deliberately, like
		# any other state (plans/COLLECTIVE-QUESTLINE.md §8.3).
		"methodLog": {},

		"contacts": _new_contacts_state(),

		"combat": {
			"active": false, "context": "raid", "veinId": null, "enemies": [],
			# R§2: backdrop location key, set by Combat._start_combat().
			"locationKey": "",
			"selection": { "type": "enemy", "index": 0 }, "log": [],
			"outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": null, "snapshots": [], "beatsSinceSnapshot": [],
			# Allies fighting alongside the player this combat (see
			# Contacts.build_combat_ally) — empty outside vein-defense fights.
			"allies": [],
			# R§3.7a resumable-progression cursor; reset fresh by
			# Combat._start_combat()/exit_combat(), never carried between fights.
			"turnCursor": { "queue": [], "index": 0, "round": 0 },
		},
		# Outside state.combat itself since exit_combat() resets that dict
		# to fresh defaults on every fight's end.
		"combatPacingMode": CombatPacing.DEFAULT_MODE,

		# Bounded solo combat prototype's own state tree, fully separate
		# from "combat" above. Resets on load like mapNav/veinListNav -- a
		# fight mid-flight at save time isn't resurrected.
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
		# Archie's tag-along deal -- the gross-derived 50/50 cut, held
		# across a mugging fight the same way pendingSaleCut is.
		"pendingArchieDealCut": 0,
		"labThresholds": {},
		# Per-recipe opt-in { recipeKey: bool }; when true, Production adds
		# undelivered active-contract need to labThresholds for that recipe.
		"labCoverContracts": {},
		# { contactId: [veinId] } -- each cultivator's own vein list; a vein
		# is on at most one list (R§3.10 "Staff roles").
		"cultivatorVeins": {},
		# { veinId: int growth target }, whichever cultivator holds the vein.
		"veinStationTargets": {},

		"flags": {
			"tutorialStage": "intro",
			"metArchie": false, "metJames": false, "buyerEventSeen": false,
			"craftingUnlocked": false, "archieCraftChatSeen": false,
			"canSellConsumables": false, "consSoldCount": 0,
			"archieMotionPending": false, "archieMotionEventSeen": false,
			# Idempotency guard: archie_2 SMS queues exactly once, not on
			# every tick until the player acts.
			"archieBuyerSmsQueued": false,
			"jamesMotionEventSeen": false, "enhancementUnlocked": false,
			"jamesJobActive": false, "jamesJobAccepted": false,
			# Gates ArchieDeals.roll_daily_offer() true from offer-queued
			# until declined or its accepted deal (incl. any mugging fight) resolves.
			"archieDealActive": false,
			"homeRaidEventPending": false, "homeRaidEventSeen": false, "homeRaidWon": false,
			# Business Act 1 founder role unlocks (constants.json contacts.<id>.roleFlags).
			"bizArchieSalesRole": false, "bizJamesProductionRole": false,
			"bizOwenCultivationRole": false, "bizOwenProductionRole": false,
			# business_empire questline (systems/business_quest.gd).
			"bizA1Proposed": false, "bizA1PropositionSeen": false, "bizA1MarketProven": false,
			"bizA1OwenIntroQueued": false, "bizA1OwenJoined": false,
			"bizA1ApprenticeReady": false, "bizA1PartnershipQueued": false, "bizA1JamesJoined": false,
			# Set by Beat 3; shows BizBrief's Staff tab.
			"bizStaffTabOpen": false,
			"archiePartnerSeen": false, "homeUnlocked": false, "securityContactUnlocked": false,
			# M1-LONDON D5 — district event one-shot flags/counters.
			"greenwichTipOff": false, "luckyOmen": false, "conclaveNoticed": false, "oddities": 0,
			# M1-LONDON D6 — cultivating tutorial.
			"cultivationTutorialSeen": false,
			# Set by the raid event's stealth_check success/caught branches;
			# read by loot_raid_vein so the shared loot card knows which
			# path got the player there.
			"raidCaught": false,
			# Flips true once, never false again -- permanently gates
			# VeinList's Sell option for every vein from then on.
			"veinSaleUnlocked": false,
			# Pre-join lane gate: Des/Nadia/Hakim's Trade action-bar entry
			# reads this, not faction membership.
			"collectiveLaneUnlocked": false,
			# Gates Dial.attempt_seed() (R§3.5's Gift gate). Set true only
			# by the Collective Act 2 onboarding quest.
			"dialGiftGranted": false,
			# Gates Debug phone app visibility -- true only via
			# DebugStart.apply()'s force-all-flags pass.
			"debugStartUsed": false,
			# collective-act2 T13 (spec §6.13): the Hakim-card retake action
			# opens once Targets intel is bought on his Firm-held vein
			# (Collective.note_targets_purchase()), and closes on the retake.
			"colA2HakimIntelBought": false, "colA2HakimRetaken": false,
			# collective-act2 T14/T15 (spec §6.14/§6.15): colA2SpineReward
			# is set once the §7.4 gate is met and opens Hakim's weak-vein
			# intel; colA2Complete is col_a2_closer's on_complete.
			"colA2SpineReward": false, "colA2Complete": false,
		},

		# barkCursors backs Collective._next_bark()'s no-repeat-until-
		# exhausted draw per vendor (contactId -> next index into data/
		# collective_barks.json). Later state extends this dict, not new
		# top-level keys.
		"collective": {
			"barkCursors": {},
			# The vein col_a1_hakim_meet's grant_contact_vein op hands the
			# player, referenced by col_a1_hakim_rescue. null pre-event.
			"hakimVeinId": null,
			# Last state.world.day col_hakim_intel's roll completed; 0 =
			# never. Updated only on_complete (not at roll time), so the
			# 3-day gap is measured from when the player read it, not when
			# Hakim heard it.
			"hakimIntelLastDay": 0,
			# Act 2 T5 (spec §6.5): the site Collective.maybe_trigger_
			# a2_contested_vein_setup() scripts as "a Collective vein the
			# Firm has taken since T3". null until Phase 1 opens.
			"contestedVeinSiteId": null,
			# Act 2 T8a (spec §6.8a): the player vein col_a2_nadia_defend is
			# currently watching, picked by Collective.pick_nadia_defend_vein()
			# and re-picked by maybe_retarget_nadia_defend_vein() if lost
			# before being defended. null until T8a fires.
			"nadiaDefendVeinId": null,
			# Act 2 T9 (spec §6.9): state.world.day colA2LedgerStarted was
			# first seen true, stamped by Collective.maybe_trigger_a2_
			# checkpoint(). null until T8 resolves.
			"ledgerStartedDay": null,
			# Network handler Targets intel (spec §5.3), siteId -> { expiresDay,
			# effect: "claim_bonus"|"security_freeze", magnitude }. Active while
			# state.world.day < expiresDay; pruned by NetworkHandler.expire_intel().
			"networkIntel": {},
			# Act 2 T7 "make an example" (spec §6.7): { multiplier, expiresDay }
			# scaling the Firm's target weight on Collective veins while
			# state.world.day < expiresDay. null when not provoked.
			"firmProvocation": null,
			# Act 2 relation award table (spec §7.3): T8 mission objective
			# ids that have already paid their +4.
			"a2MissionsAwarded": [],
		},
	}


func _new_factions_state() -> Dictionary:
	var factions := {}
	for faction_id in GameData.FACTIONS.keys():
		factions[faction_id] = {
			"relation": 0,
			"joined": false,
			# Ledger balance, distinct from factions.json's `resourceLevel`
			# (security-roll opulence input); startingResources tiers
			# scrappiest to richest: Collective < Firm/Network < Guild/Conclave.
			"resources": GameData.FACTIONS[faction_id].get("startingResources", 0),
			# Lifetime ore sold TO this faction, keyed by ore type --
			# { units, transactions }, absent = zero. Unlike tradeProgress
			# (£-denominated) below, unit/transaction-based, used only for
			# objective evaluation.
			"oreSold": {},
			# £-denominated counter RelationAccrual converts to relation
			# points, remainder carried across trades. Only "collective"
			# has a configured rate in Act 1; present elsewhere for schema
			# uniformity.
			"tradeProgress": 0,
			# Independently-scarce per-ore stock the buy lane draws against
			# -- { oreType: int }, absent = 0. Only rolled for "collective"
			# this milestone; independent of relation, which narrows
			# buy/sell spread, never this ceiling.
			"oreStock": {},
		}
	return factions


# Seeds every ordered pair of the 5 canonical factions to a neutral
# baseline (0) -- a flat start keeps the rivalry odds this matrix feeds
# into dependent purely on resource/security disparity, not an
# unjustified industries-overlap guess.
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
		# Generic ally-combat block every contact carries, not archie-only
		# -- a contact whose constants.json entry omits these fields gets
		# combatHpMax 0, which Contacts.can_join_combat() reads as ineligible.
		contacts[contact_id] = {
			"relation": defaults.get("startRelation", 0),
			"unlocked": defaults.get("unlocked", false),
			"recruited": false,
			"recruitThreshold": defaults.get("recruitThreshold", 0),
			# Defaults true (omitted entries render their recruit row
			# unchanged). false suppresses the row entirely and gates
			# Contacts.can_recruit() itself -- no UI-less back door to
			# recruiting a "never" contact.
			"recruitable": defaults.get("recruitable", true),
			# Higher relation gate than recruitThreshold: can_assist_raid()
			# reads against this, so a contact can be recruit/combat-
			# eligible well before trusted for an offensive raid. Defaults
			# 0 for entries that omit it -- harmless since combatHpMax
			# already excludes them.
			"raidAssistThreshold": defaults.get("raidAssistThreshold", 0),
			"craftingSkill": 1, "craftingXP": 0,
			"cultivatingSkill": 1, "cultivatingXP": 0,
			"stealthSkill": 1, "stealthXP": 0,
			# Same skill-threshold-ladder as craftingSkill/cultivatingSkill,
			# gated by the Operations Room via assignedRoom.
			"salesSkill": 1, "salesXP": 0,
			"assignedRoom": null,
			# Founder-only room-free staff role (null|"sales"|"cultivation"|
			# "production"), exclusive with assignedRoom -- R§3.10.
			"assignedRole": null,
			"combatHpMax": defaults.get("combatHpMax", 0),
			"combatHp": defaults.get("combatHpMax", 0),
			"combatAttackMin": defaults.get("combatAttackMin", 0),
			"combatAttackMax": defaults.get("combatAttackMax", 0),
			"combatStashMax": defaults.get("combatStashMax", 0),
			"combatStash": defaults.get("combatStashMax", 0),
			"combatHealAmount": defaults.get("combatHealAmount", 0),
			# Fixed authored turn-order value (not trainable, unlike the
			# player's Combat Skill-driven speed) -- copied into
			# combat.allies, which Combat.build_turn_queue() sorts on.
			"combatSpeed": defaults.get("combatSpeed", 0),
			"koCooldownDays": defaults.get("koCooldownDays", 0),
			"koCooldownUntilDay": null,
			# Ally Dial casts left today; refilled by Contacts.daily_dial_regen().
			# The loadout itself (complications/tier) stays in constants.json's combatDial.
			"dialCharges": defaults.get("combatDial", {}).get("chargesPerDay", 0),
			# Same £-denominated accrual as state.factions[id].tradeProgress,
			# but for Archie -- he has no faction, he *is* the lane.
			"tradeProgress": 0,
		}
	return contacts


# Dot-path convenience reader, e.g. read_path("player.cash"). Named
# read_path, not get_path -- Node already declares a native get_path() ->
# NodePath, and reusing that name is a hard parse error in Godot 4.4. Not
# a replacement for direct dict access -- just a small helper for tests/
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
