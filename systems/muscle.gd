class_name Muscle
extends RefCounted

# Hired guards (spec .scratch/muscle/spec.md): individual guard records under
# state.muscle, each with a generated name, level, XP, one or two traits, a
# post and injury/training countdowns. Static funcs only; every number comes
# from GameData.MUSCLE / MUSCLE_TRAITS / MUSCLE_* name pools.

const POST_RESERVE := "reserve"
const POST_HOME := "home"


# state.muscle: pure data. board.cards holds guard-shaped records or null
# (hired slot); former is the FIFO of dismissed/walked guards.
static func new_state() -> Dictionary:
	return { "nextId": 1, "guards": [], "board": { "day": 0, "cards": [] }, "former": [], "responders": {} }


static func guards() -> Array:
	return GameState.state["muscle"]["guards"]


static func guard(id: String) -> Dictionary:
	for g in guards():
		if g["id"] == id:
			return g
	return {}


static func former() -> Array:
	return GameState.state["muscle"]["former"]


# ── level table ───────────────────────────────────────────────────────

static func level_row(level: int) -> Dictionary:
	var rows: Array = GameData.MUSCLE["levels"]
	return rows[clampi(level, 1, rows.size()) - 1]


static func level_weight(level: int) -> float:
	return float(level_row(level)["weight"])


static func level_wage(level: int) -> int:
	return int(level_row(level)["wage"])


# ── guard creation ────────────────────────────────────────────────────

# A new guard record, not yet stored anywhere: unique name, 1-2 traits.
# `level` is clamped to the level table. Draws ids from state.muscle.nextId.
static func create_guard(level: int = 1) -> Dictionary:
	var muscle: Dictionary = GameState.state["muscle"]
	var id := "g%d" % int(muscle["nextId"])
	muscle["nextId"] = int(muscle["nextId"]) + 1
	var name_parts := generate_name()
	return {
		"id": id,
		"name": name_parts["name"],
		"nickname": name_parts["nickname"],
		"level": clampi(level, 1, GameData.MUSCLE["levels"].size()),
		"xp": int(level_row(level)["xpToReach"]),
		"traits": roll_traits(),
		"post": POST_RESERVE,
		"injuredUntilDay": 0,
		"trainingUntilDay": 0,
	}


# { name: "Dee Okafor", nickname: "Spanner" | "" }. The name is unique across
# current guards, former guards and the board's open cards.
static func generate_name() -> Dictionary:
	var used := _used_names()
	var first_pool: Array = GameData.MUSCLE_FIRST_NAMES
	var surname_pool: Array = GameData.MUSCLE_SURNAMES
	var full := ""
	var attempts := 0
	var cap: int = first_pool.size() * surname_pool.size()
	while attempts <= cap:
		var candidate := "%s %s" % [Rng.rand_from(first_pool), Rng.rand_from(surname_pool)]
		if not used.has(candidate):
			full = candidate
			break
		attempts += 1
	assert(full != "", "name pool exhausted")
	var nickname := ""
	if Rng.chance(float(GameData.MUSCLE["nicknameChance"])):
		nickname = Rng.rand_from(GameData.MUSCLE_NICKNAMES)
	return { "name": full, "nickname": nickname }


static func _used_names() -> Dictionary:
	var used := {}
	var muscle: Dictionary = GameState.state["muscle"]
	for list in [muscle["guards"], muscle["former"], muscle["board"]["cards"]]:
		for g in list:
			if g != null:
				used[g["name"]] = true
	return used


# One trait, 25% a second distinct one that isn't blocked against the first.
static func roll_traits() -> Array:
	var ids: Array = GameData.MUSCLE_TRAITS.keys()
	var picked: Array = [Rng.rand_from(ids)]
	if Rng.chance(float(GameData.MUSCLE["secondTraitChance"])):
		var options: Array = ids.filter(func(t): return t != picked[0] and not traits_blocked(picked[0], t))
		if not options.is_empty():
			picked.append(Rng.rand_from(options))
	return picked


static func traits_blocked(a: String, b: String) -> bool:
	for pair in GameData.MUSCLE_BLOCKED_PAIRS:
		if (pair[0] == a and pair[1] == b) or (pair[0] == b and pair[1] == a):
			return true
	return false


# ── trait maths ───────────────────────────────────────────────────────

# Product of a numeric trait param across a guard's traits (1.0 when none set it).
static func trait_mult(g: Dictionary, param: String) -> float:
	var product := 1.0
	for t in g["traits"]:
		product *= float(GameData.MUSCLE_TRAITS[t]["params"].get(param, 1.0))
	return product


# Sum of a numeric trait param across a guard's traits (0.0 when none set it).
static func trait_sum(g: Dictionary, param: String) -> float:
	var total := 0.0
	for t in g["traits"]:
		total += float(GameData.MUSCLE_TRAITS[t]["params"].get(param, 0.0))
	return total


# ── weights and wage ──────────────────────────────────────────────────

static func weight(g: Dictionary) -> float:
	return level_weight(int(g["level"]))


# Level weight plus the guard's repel-only trait modifiers.
static func repel_weight(g: Dictionary) -> float:
	return weight(g) + trait_sum(g, "repelWeightMod")


# Weekly wage: level wage x every trait's wage multiplier, rounded to £.
static func wage(g: Dictionary) -> int:
	return int(round(level_wage(int(g["level"])) * trait_mult(g, "wageMult")))


# ── names ─────────────────────────────────────────────────────────────

# "Dee O." -- first name and surname initial.
static func short_name(g: Dictionary) -> String:
	var parts: PackedStringArray = String(g["name"]).split(" ")
	return "%s %s." % [parts[0], parts[parts.size() - 1].left(1)]


# "Dee O." or, with a nickname, "Dee \"Spanner\" O.".
static func full_name(g: Dictionary) -> String:
	var parts: PackedStringArray = String(g["name"]).split(" ")
	var initial := parts[parts.size() - 1].left(1)
	if String(g["nickname"]).is_empty():
		return "%s %s." % [parts[0], initial]
	return "%s \"%s\" %s." % [parts[0], g["nickname"], initial]


# ── Security Office ───────────────────────────────────────────────────

const SECURITY_OFFICE := "securityOffice"
# Set once on the first purchase and never cleared; the intro event reads it.
const FLAG_OFFICE_BOUGHT := "securityOfficeBought"


# Guard management (hire, dismiss, posting) needs the Security Office.
static func can_manage() -> bool:
	return Home.has_room(SECURITY_OFFICE)


# Called when the room is bought: sets the intro trigger on the first purchase
# only, and stocks an empty board so the first visit isn't an empty week.
static func on_room_bought() -> void:
	var flags: Dictionary = GameState.state["flags"]
	if not bool(flags.get(FLAG_OFFICE_BOUGHT, false)):
		flags[FLAG_OFFICE_BOUGHT] = true
	if GameState.state["muscle"]["board"]["cards"].is_empty():
		roll_board()


# ── posting ───────────────────────────────────────────────────────────

# Guards whose post is `post_id` (HQ, a vein id or Reserve), injured or not.
static func guards_at(post_id: String) -> Array:
	return guards().filter(func(g): return g["post"] == post_id)


static func reserve() -> Array:
	return guards_at(POST_RESERVE)


# Not injured and not in training: only these count as bodies at a post.
static func is_available(id: String) -> bool:
	var g := guard(id)
	if g.is_empty():
		return false
	var day: int = GameState.state["world"]["day"]
	return int(g["injuredUntilDay"]) <= day and int(g["trainingUntilDay"]) <= day


# Available guards posted at `post_id`: the bodies that resist, repel and carry kit.
static func available_at(post_id: String) -> Array:
	return guards_at(post_id).filter(func(g): return is_available(g["id"]))


# Σ level weight of the available guards posted at `post_id`.
static func post_weight_sum(post_id: String) -> float:
	var total := 0.0
	for g in available_at(post_id):
		total += weight(g)
	return total


# Σ repel weight (level weight plus repel-only trait mods) of the available
# guards posted at `post_id`.
static func post_repel_weight_sum(post_id: String) -> float:
	var total := 0.0
	for g in available_at(post_id):
		total += repel_weight(g)
	return total


# ── Security score ────────────────────────────────────────────────────

# 0-100 readout (spec §Security score): hardware share plus repel share.
# `hardware` / `max_hardware` are the place's lock/ward resist or installed
# HQ raidReduction; `repel` is the pre-kit repel chance.
static func security_score(hardware: float, max_hardware: float, repel: float) -> int:
	var cfg: Dictionary = GameData.MUSCLE["score"]
	var hw_share := clampf(hardware / max_hardware, 0.0, 1.0) if max_hardware > 0.0 else 0.0
	var repel_share := minf(1.0, repel / float(cfg["repelFull"]))
	return roundi(float(cfg["hardwareWeight"]) * hw_share + float(cfg["repelWeight"]) * repel_share)


static func score_band(score: int) -> String:
	var label := ""
	for band in GameData.MUSCLE["score"]["bands"]:
		if score >= int(band["min"]):
			label = String(band["label"])
	return label


# Security score of a player vein: ward/lock resist against the best tier.
static func vein_security_score(vein: Dictionary) -> int:
	var max_hw := 0.0
	for tier_id in GameData.VEIN_SECURITY:
		max_hw = maxf(max_hw, float(GameData.VEIN_SECURITY[tier_id]["raidResist"]))
	var repel := Raiding.guard_repel_chance(post_repel_weight_sum(vein["id"]))
	return security_score(float(Cultivating.vein_tier_resist(vein)), max_hw, repel)


# Security score of HQ: installed hardware raidReduction (guards excluded).
static func hq_security_score() -> int:
	var have := 0.0
	var max_hw := 0.0
	for id in GameData.HOME_SECURITY:
		if id == "guard":
			continue
		var r := float(GameData.HOME_SECURITY[id]["raidReduction"])
		max_hw += r
		if GameState.state["home"]["security"].has(id):
			have += r
	return security_score(have, max_hw, Home.guard_repel_chance(Home.get_guard_weight_repel()))


# "52 · Solid" for a vein or HQ post; "" for Reserve.
static func score_text(post_id: String) -> String:
	var score := 0
	if post_id == POST_RESERVE:
		return ""
	if post_id == POST_HOME:
		score = hq_security_score()
	else:
		var vein: Variant = Cultivating.find_vein(post_id)
		if vein == null:
			return ""
		score = vein_security_score(vein)
	return "%d · %s" % [score, score_band(score)]


# A guard walks off: the lowest-level available guard posted at `post_id`
# goes to the former list. False when nobody's posted there.
static func walk_from(post_id: String) -> bool:
	var pick: Dictionary = {}
	for g in available_at(post_id):
		if pick.is_empty() or int(g["level"]) <= int(pick["level"]):
			pick = g
	if pick.is_empty():
		return false
	guards().erase(pick)
	add_former(pick)
	return true


# Guard `id` walks off, available or not: they go to the former list. False
# when no such guard.
static func walk(id: String) -> bool:
	var g := guard(id)
	if g.is_empty():
		return false
	guards().erase(g)
	add_former(g)
	return true


# Guard slots at a post: the HQ / vein cap, or -1 for uncapped Reserve.
static func cap(post_id: String) -> int:
	if post_id == POST_RESERVE:
		return -1
	var caps: Dictionary = GameData.MUSCLE["postCaps"]
	return int(caps["home"]) if post_id == POST_HOME else int(caps["vein"])


# Whether `post_id` is Reserve, HQ or one of the player's veins.
static func is_post(post_id: String) -> bool:
	return post_id == POST_RESERVE or post_id == POST_HOME or Cultivating.find_vein(post_id) != null


# Why guard `id` can't be moved to `post_id`, or "". The one rule behind every
# posting entry point.
static func post_block_reason(id: String, post_id: String) -> String:
	if not can_manage():
		return "Needs a Security Office."
	if guard(id).is_empty():
		return "No such guard."
	if not is_post(post_id):
		return "No such post."
	if not is_available(id):
		return "Not available."
	if guard(id)["post"] != post_id and post_id != POST_RESERVE and guards_at(post_id).size() >= cap(post_id):
		return "That post is full."
	return ""


# Moves guard `id` to `post_id`: instant, free, any time block. Returns { ok }
# or { ok: false, reason }.
static func post(id: String, post_id: String) -> Dictionary:
	var reason := post_block_reason(id, post_id)
	if reason != "":
		return { "ok": false, "reason": reason }
	var g := guard(id)
	if g["post"] != post_id:
		g["post"] = post_id
		EventBus.mark_changed()
	return { "ok": true }


# ── hiring board ──────────────────────────────────────────────────────

# The weekly board: slots of guard-shaped cards, null where hired.
static func board() -> Array:
	return GameState.state["muscle"]["board"]["cards"]


# Rollover step: a fresh board on the first Monday it hasn't rolled for, with
# the room owned.
static func roll_board_if_due() -> void:
	var day: int = GameState.state["world"]["day"]
	if can_manage() and Calendar.is_monday(day) and int(GameState.state["muscle"]["board"]["day"]) != day:
		roll_board()


# Replaces the board with `board.size` fresh cards. Each card is, with
# `formerChance`, a former guard returning as they left (injuries cleared,
# tagged "returning"), else a new guard at a level from `boardOdds`.
static func roll_board() -> void:
	var muscle: Dictionary = GameState.state["muscle"]
	var cards: Array = []
	muscle["board"]["cards"] = cards
	muscle["board"]["day"] = GameState.state["world"]["day"]
	var settings: Dictionary = GameData.MUSCLE["board"]
	for i in int(settings["size"]):
		var card: Dictionary = {}
		if not muscle["former"].is_empty() and Rng.chance(float(settings["formerChance"])):
			card = _returning_card(cards)
		if card.is_empty():
			card = create_guard(roll_board_level())
		cards.append(card)
	EventBus.mark_changed()


# A copy of a random former guard not already on the board, or {}.
static func _returning_card(cards: Array) -> Dictionary:
	var options: Array = former().filter(func(f): return not cards.any(func(c): return c["id"] == f["id"]))
	if options.is_empty():
		return {}
	var card: Dictionary = (Rng.rand_from(options) as Dictionary).duplicate(true)
	card["injuredUntilDay"] = 0
	card["trainingUntilDay"] = 0
	card["post"] = POST_RESERVE
	card["returning"] = true
	return card


# A level drawn by `boardOdds`; a level with 0 odds never comes up.
static func roll_board_level() -> int:
	var rows: Array = GameData.MUSCLE["levels"]
	var total := 0
	for row in rows:
		total += int(row["boardOdds"])
	var roll := Rng.randi_range(1, total)
	for row in rows:
		roll -= int(row["boardOdds"])
		if roll <= 0 and int(row["boardOdds"]) > 0:
			return int(row["level"])
	return 1


# "" when card `index` can be hired, else why not.
static func hire_block_reason(index: int) -> String:
	if not can_manage():
		return "Needs a Security Office."
	if index < 0 or index >= board().size() or board()[index] == null:
		return "No one there."
	if int(GameState.state["player"]["cash"]) < GuardUpkeep.guard_hire_advance(board()[index]):
		return "Not enough cash."
	return ""


# Hires board card `index`: pays that guard's prorated advance, lands them in
# Reserve and leaves the slot empty until the next Monday roll. Returns
# { ok, guard } or { ok: false, reason }.
static func hire(index: int) -> Dictionary:
	var reason := hire_block_reason(index)
	if reason != "":
		return { "ok": false, "reason": reason }
	var card: Dictionary = board()[index]
	var paid := GuardUpkeep.pay_hire_advance(POST_RESERVE, wage(card))
	if not paid["ok"]:
		return paid
	var record: Dictionary = card.duplicate(true)
	record.erase("returning")
	record["post"] = POST_RESERVE
	guards().append(record)
	board()[index] = null
	var former_list: Array = former()
	for i in former_list.size():
		if former_list[i]["id"] == record["id"]:
			former_list.remove_at(i)
			break
	Notify.push("Hired %s." % short_name(record), Notify.CATEGORY_SUCCESS)
	EventBus.mark_changed()
	return { "ok": true, "guard": record }


# Dismisses a guard at once: no severance, no refund, injured or not. They
# join the former list (cap `formerCap`, oldest dropped).
static func dismiss(id: String) -> Dictionary:
	if not can_manage():
		return { "ok": false, "reason": "Needs a Security Office." }
	var list: Array = guards()
	for i in list.size():
		if list[i]["id"] == id:
			var gone: Dictionary = list[i]
			list.remove_at(i)
			add_former(gone)
			EventBus.mark_changed()
			return { "ok": true }
	return { "ok": false, "reason": "No such guard." }


# Appends to the former list, dropping the oldest past the cap.
static func add_former(g: Dictionary) -> void:
	var former_list: Array = former()
	former_list.append(g)
	while former_list.size() > int(GameData.MUSCLE["board"]["formerCap"]):
		former_list.remove_at(0)


# A guard's XP floor for their next level, or -1 at the top level.
static func next_level_xp(g: Dictionary) -> int:
	var rows: Array = GameData.MUSCLE["levels"]
	if int(g["level"]) >= rows.size():
		return -1
	return int(rows[int(g["level"])]["xpToReach"])


# ── XP, levels, training ──────────────────────────────────────────────

const XP_PASSIVE := "passive"
const XP_REPEL := "repel"
const XP_DEFEND := "defend"
const XP_TRAINING := "training"


# Base XP for a source id, from MUSCLE.xp / MUSCLE.training.
static func xp_base(source: String) -> int:
	var cfg: Dictionary = GameData.MUSCLE["xp"]
	match source:
		XP_PASSIVE:
			return int(cfg["passivePerDay"])
		XP_REPEL:
			return int(cfg["perRepel"])
		XP_DEFEND:
			return int(cfg["perDefendFight"])
		XP_TRAINING:
			return int(GameData.MUSCLE["training"]["xp"])
	return 0


# Adds `source` XP to guard `id`, scaled by the guard's xpMult traits (XP may
# be fractional). Each level crossed pushes one notification; the new wage
# shows from the next Monday bill. Returns the XP gained.
static func award_xp(id: String, source: String) -> float:
	var g := guard(id)
	if g.is_empty():
		return 0.0
	var gained := float(xp_base(source)) * trait_mult(g, "xpMult")
	g["xp"] = float(g["xp"]) + gained
	var rows: Array = GameData.MUSCLE["levels"]
	while int(g["level"]) < rows.size() and float(g["xp"]) >= float(rows[int(g["level"])]["xpToReach"]):
		g["level"] = int(g["level"]) + 1
		Notify.push("%s is now level %d." % [short_name(g), int(g["level"])], Notify.CATEGORY_SUCCESS)
	EventBus.mark_changed()
	return gained


# A successful repel at `post_id`: repel XP for each available guard posted
# there (the guards whose weight counted).
static func award_repel_xp(post_id: String, responder_ids: Array = []) -> void:
	for g in available_at(post_id):
		award_xp(g["id"], XP_REPEL)
	for id in responder_ids:
		award_xp(str(id), XP_REPEL)


# ── Reserve responders ────────────────────────────────────────────────

# "day:block" key for the current time block.
static func block_key() -> String:
	var world: Dictionary = GameState.state["world"]
	return "%d:%d" % [int(world["day"]), int(world["timeBlock"])]


# Places with a live alarm in answer order: HQ, then player veins most
# valuable first. `extra` (a place being resolved right now) is included even
# if its pending flag is already cleared.
static func alarm_places(extra: String = "") -> Array:
	var veins: Array = []
	for outcome in GameState.state["world"].get("pendingDefendRaids", []):
		var vein: Variant = Cultivating.find_vein(outcome.get("veinId", ""))
		if vein != null and not veins.has(vein):
			veins.append(vein)
	if extra != "" and extra != POST_HOME:
		var extra_vein: Variant = Cultivating.find_vein(extra)
		if extra_vein != null and not veins.has(extra_vein):
			veins.append(extra_vein)
	veins.sort_custom(Cultivating.value_order)
	var places: Array = []
	if Home.has_pending_raid() or extra == POST_HOME:
		places.append(POST_HOME)
	for vein in veins:
		places.append(vein["id"])
	return places


# This block's committed claims: { place: [guard ids] }. Claims from earlier
# blocks are dropped.
static func _claims(write: bool = false) -> Dictionary:
	var ledger: Dictionary = GameState.state["muscle"]["responders"]
	var key := block_key()
	if not write:
		return ledger.get(key, {})
	for k in ledger.keys():
		if k != key:
			ledger.erase(k)
	if not ledger.has(key):
		ledger[key] = {}
	return ledger[key]


# Who would answer each place this block: committed claims stand; the
# remaining free Reserve guards (highest level first) go to uncommitted places
# in priority order, `defending` first. Returns { place: [guard ids] }.
static func responder_plan(extra: String = "", defending: String = "") -> Dictionary:
	var claims := _claims()
	var plan: Dictionary = {}
	var taken: Dictionary = {}
	for place in claims:
		plan[place] = claims[place]
		for id in claims[place]:
			taken[id] = true
	var free: Array = reserve().filter(func(g): return is_available(g["id"]) and not taken.has(g["id"]))
	free.sort_custom(func(a, b): return int(a["level"]) > int(b["level"]) or (int(a["level"]) == int(b["level"]) and str(a["id"]) < str(b["id"])))
	var order: Array = alarm_places(extra if extra != "" else defending)
	if defending != "":
		order.erase(defending)
		order.push_front(defending)
	var cap := int(GameData.MUSCLE["reserveResponders"])
	for place in order:
		if plan.has(place):
			continue
		var picked: Array = []
		while picked.size() < cap and not free.is_empty():
			picked.append(free.pop_front()["id"])
		plan[place] = picked
	return plan


# Commits and returns the Reserve guard ids answering `place` this block (up
# to reserveResponders, highest level first, never one already committed
# elsewhere this block). `defending`: the player is fighting there, so it
# outranks every other alarm. `block` is the block key (block_key()).
static func claim_responders(place: String, block: String = "", defending: bool = false) -> Array:
	if block != "" and block != block_key():
		return []
	var claims := _claims(true)
	if claims.has(place):
		return claims[place].duplicate()
	var plan := responder_plan(place, place if defending else "")
	var ids: Array = plan.get(place, [])
	claims[place] = ids.duplicate()
	return ids.duplicate()


# Σ repel weight of the guards with these ids.
static func responder_repel_weight(ids: Array) -> float:
	var total := 0.0
	for id in ids:
		var g := guard(str(id))
		if not g.is_empty():
			total += repel_weight(g)
	return total


static func train_cost(g: Dictionary) -> int:
	return int(GameData.MUSCLE["training"]["costPerLevel"]) * int(g["level"])


# "" when guard `id` can be trained now, else why not.
static func train_block_reason(id: String) -> String:
	if not can_manage():
		return "Needs a Security Office."
	var g := guard(id)
	if g.is_empty():
		return "No such guard."
	if not is_available(id):
		return "Not available."
	if int(GameState.state["player"]["cash"]) < train_cost(g):
		return "Not enough cash."
	return ""


# Pays for a training session: training XP, and the guard is away (off post,
# uncounted) for `training.days` days, then back on their post. No time block.
# Returns { ok, cost } or { ok: false, reason }.
static func train(id: String) -> Dictionary:
	var reason := train_block_reason(id)
	if reason != "":
		return { "ok": false, "reason": reason }
	var g := guard(id)
	var cost := train_cost(g)
	GameState.state["player"]["cash"] -= cost
	Bank.record(-cost, "Guard training")
	BusinessStats.record_expense(cost, BusinessStats.EXPENSE_GUARD)
	GuardUpkeep.record_history(GuardUpkeep.TRAINING_PLACE_ID, cost)
	g["trainingUntilDay"] = int(GameState.state["world"]["day"]) + int(GameData.MUSCLE["training"]["days"])
	award_xp(id, XP_TRAINING)
	Notify.push("%s is away training for a day." % short_name(g), Notify.CATEGORY_INFO)
	EventBus.mark_changed()
	return { "ok": true, "cost": cost }


# Days a KO'd guard is out: injuryDays, or the shortest any trait sets.
static func injury_days(g: Dictionary) -> int:
	var days := int(GameData.MUSCLE["injuryDays"])
	for t in g["traits"]:
		days = mini(days, int(GameData.MUSCLE_TRAITS[t]["params"].get("injuryDays", days)))
	return days


# Days of injury left (0 when fit).
static func injury_days_left(g: Dictionary) -> int:
	return maxi(0, int(g["injuredUntilDay"]) - int(GameState.state["world"]["day"]))


# Knocks guard `id` out for their injury days: dropped to Reserve (unpostable,
# untrainable, still on the wage bill).
static func injure(id: String) -> void:
	var g := guard(id)
	if g.is_empty():
		return
	g["injuredUntilDay"] = int(GameState.state["world"]["day"]) + injury_days(g)
	g["post"] = POST_RESERVE
	EventBus.mark_changed()


# Muscle daily tick (R§3.1 ⑥.5j4): passive XP for every available guard on a
# post (Reserve, Lazy, injured and training guards earn none), and clears
# finished injury and training countdowns.
static func daily_tick() -> void:
	var day: int = GameState.state["world"]["day"]
	if Calendar.is_monday(day):
		_roll_kit_losses()
	for g in guards():
		if int(g["injuredUntilDay"]) != 0 and int(g["injuredUntilDay"]) <= day:
			g["injuredUntilDay"] = 0
		if int(g["trainingUntilDay"]) != 0 and int(g["trainingUntilDay"]) <= day:
			g["trainingUntilDay"] = 0
		if g["post"] == POST_RESERVE or not is_available(g["id"]) or _no_passive_xp(g):
			continue
		award_xp(g["id"], XP_PASSIVE)


# Monday roll: each Light-fingered guard on a post, kitLossChance, takes 1 unit
# from that post's kit (HQ kit or the vein's guardKit).
static func _roll_kit_losses() -> void:
	for g in guards().duplicate():
		if g["post"] == POST_RESERVE:
			continue
		var chance := trait_sum(g, "kitLossChance")
		if chance <= 0.0 or not Rng.chance(chance):
			continue
		var kit := _post_kit(g["post"])
		var units: Array = []
		for recipe_key in kit:
			for tier_key in kit[recipe_key]:
				for i in int(kit[recipe_key][tier_key]):
					units.append([recipe_key, tier_key])
		if units.is_empty():
			continue
		var lost: Array = Rng.rand_from(units)
		GuardKit.remove_units(kit, { lost[0]: { lost[1]: 1 } })
		EventBus.mark_changed()


# The kit dict stocked at a post ({} for Reserve or an unknown post).
static func _post_kit(post_id: String) -> Dictionary:
	if post_id == POST_HOME:
		return GameState.state["home"].get("guardKit", {})
	var vein = Cultivating.find_vein(post_id)
	if vein == null:
		return {}
	return vein.get("guardKit", {})


# A player vein left the player's hands (taken, sold, collapsed): its posted
# guards go to Reserve unhurt. Guards never travel with a vein.
static func on_vein_lost(vein_id: String) -> void:
	for g in guards_at(vein_id):
		g["post"] = POST_RESERVE
	EventBus.mark_changed()


# The Security Office left the HQ (tier move, no free slot, or replaced). Guards
# stay employed and paid; below townhouse the HQ posts drop to Reserve. One
# notification.
static func on_room_lost() -> void:
	if _hq_below_office_tier():
		for g in guards_at(POST_HOME):
			g["post"] = POST_RESERVE
	if not guards().is_empty():
		# PROSE-REVIEW: room-loss notification.
		Notify.push("The Security Office is gone. Your guards hold their posts but can't take new orders.", Notify.CATEGORY_WARNING)
	EventBus.mark_changed()


static func _hq_below_office_tier() -> bool:
	var order: Array = GameData.HOME_TIER_ORDER
	return order.find(GameState.state["home"]["tier"]) < order.find(GameData.HOME_ROOMS[SECURITY_OFFICE]["minTier"])


# ── faction muscle: counts by level ───────────────────────────────────
# A faction vein / stockpile holds `guards: [n1..n5]`; the faction's Reserve
# and injured list sit under state.factions[id].muscle. No XP, no training.

static func empty_counts() -> Array:
	var counts := []
	counts.resize(GameData.MUSCLE["levels"].size())
	counts.fill(0)
	return counts


static func counts_total(counts: Array) -> int:
	var total := 0
	for n in counts:
		total += int(n)
	return total


# Σ count × level weight (also the repel weight: factions carry no officer or traits).
static func counts_weight(counts: Array) -> float:
	var total := 0.0
	for i in counts.size():
		total += float(counts[i]) * level_weight(i + 1)
	return total


# What an observer reads of a post's guards: the average weight per guard as a
# word (muscle.strength.words); "" with no guards. The Reserve is never read.
static func strength_word(counts: Array) -> String:
	var total := counts_total(counts)
	if total <= 0:
		return ""
	var average := counts_weight(counts) / float(total)
	var words: Array = GameData.MUSCLE["strength"]["words"]
	for row in words:
		if average < float(row["below"]):
			return String(row["word"])
	return String(words[words.size() - 1]["word"])


static func counts_wage(counts: Array) -> int:
	var total := 0
	for i in counts.size():
		total += int(counts[i]) * level_wage(i + 1)
	return total


# A faction vein's or stockpile's level counts, created empty when absent.
static func faction_guards_at(holder: Dictionary) -> Array:
	if not holder.has("guards") or not (holder["guards"] is Array):
		holder["guards"] = empty_counts()
	return holder["guards"]


static func faction_state(faction_id: String) -> Dictionary:
	var faction: Dictionary = GameState.state["factions"][faction_id]
	if not faction.has("muscle"):
		faction["muscle"] = new_faction_state()
	return faction["muscle"]


static func new_faction_state() -> Dictionary:
	return { "reserve": empty_counts(), "injured": [], "respondersBlock": "" }


static func faction_reserve(faction_id: String) -> Array:
	return faction_state(faction_id)["reserve"]


# Every guard the faction pays: its veins' posts, stockpile and Reserve.
static func faction_total(faction_id: String) -> int:
	return counts_total(faction_all_counts(faction_id))


# Level counts across every place the faction keeps guards.
static func faction_all_counts(faction_id: String) -> Array:
	var all := empty_counts()
	for counts in _faction_places(faction_id):
		for i in counts.size():
			all[i] += int(counts[i])
	for entry in faction_state(faction_id)["injured"]:
		all[int(entry["level"]) - 1] += 1
	return all


# Drop-order places: vein posts (least valuable vein first), stockpile, Reserve.
static func _faction_places(faction_id: String) -> Array:
	var places := []
	for vein in faction_veins_low_to_high(faction_id):
		places.append(faction_guards_at(vein))
	places.append(faction_guards_at(GameState.state["factions"][faction_id]["stockpile"]))
	places.append(faction_reserve(faction_id))
	return places


static func faction_veins_low_to_high(faction_id: String) -> Array:
	var veins := []
	for site in GameState.state["world"]["sites"]:
		var vein: Variant = site.get("factionVein")
		if vein != null and vein["factionId"] == faction_id:
			veins.append(vein)
	veins.sort_custom(Cultivating.value_order)
	veins.reverse()
	return veins


# A level drawn by the faction's `muscleOdds`; a level with 0 odds never comes up.
static func faction_roll_level(faction_id: String) -> int:
	var odds: Array = GameData.FACTIONS[faction_id]["muscleOdds"]
	var total := 0
	for o in odds:
		total += int(o)
	var roll := Rng.randi_range(1, maxi(1, total))
	for i in odds.size():
		roll -= int(odds[i])
		if roll <= 0 and int(odds[i]) > 0:
			return i + 1
	return 1


# Adds a guard to `counts` (a vein, stockpile or Reserve count array) at
# `level`, or at a level rolled from `muscleOdds` when 0. Returns the level.
static func faction_hire(faction_id: String, counts: Array, level: int = 0) -> int:
	if level <= 0:
		level = faction_roll_level(faction_id)
	counts[level - 1] = int(counts[level - 1]) + 1
	return level


# Takes the lowest-level guard out of `counts`; its level, 0 if empty.
static func counts_drop_lowest(counts: Array) -> int:
	for i in counts.size():
		if int(counts[i]) > 0:
			counts[i] = int(counts[i]) - 1
			return i + 1
	return 0


# Takes one guard of `level` out of `counts`; false when there is none.
static func counts_take(counts: Array, level: int) -> bool:
	if level < 1 or level > counts.size() or int(counts[level - 1]) <= 0:
		return false
	counts[level - 1] = int(counts[level - 1]) - 1
	return true


# One entry per guard in `counts`, lowest level first.
static func counts_to_levels(counts: Array) -> Array:
	var levels := []
	for i in counts.size():
		for _n in int(counts[i]):
			levels.append(i + 1)
	return levels


# `counts` as a fight roster: lowest `down` guards sit out; a negative `down`
# adds that many guards at level 0 (the fight's own default level).
static func posted_levels(counts: Array, down: int) -> Array:
	var levels := counts_to_levels(counts)
	if down > 0:
		return levels.slice(mini(down, levels.size()))
	for _n in -down:
		levels.append(0)
	return levels


# A faction guard of `level` is out for injuryDays, then back in the Reserve.
# `from` is the place it leaves (a vein, stockpile or Reserve count array);
# [] when it has already left.
static func faction_injure(faction_id: String, level: int, from: Array = []) -> void:
	if not from.is_empty():
		counts_take(from, level)
	var back_day := int(GameState.state["world"]["day"]) + int(GameData.MUSCLE["injuryDays"])
	faction_state(faction_id)["injured"].append({ "level": level, "backDay": back_day })


# Rivalry loss: the lowest-level guard in `counts` is injured; false when empty.
static func faction_injure_lowest(faction_id: String, counts: Array) -> bool:
	var level := counts_drop_lowest(counts)
	if level == 0:
		return false
	faction_injure(faction_id, level)
	return true


# Injured faction guards whose days are up return to their Reserve.
static func faction_daily_tick() -> void:
	var day := int(GameState.state["world"]["day"])
	for faction_id in GameState.state["factions"].keys():
		var state := faction_state(faction_id)
		var reserve: Array = state["reserve"]
		var still_out := []
		for entry in state["injured"]:
			if int(entry["backDay"]) <= day:
				reserve[int(entry["level"]) - 1] = int(reserve[int(entry["level"]) - 1]) + 1
			else:
				still_out.append(entry)
		state["injured"] = still_out


# Levels of the Reserve guards (up to reserveResponders, highest first) that
# answer an alarm now; [] when the Reserve is empty or already answered this
# time block. Nothing leaves the Reserve until one of them falls.
static func faction_draw_reinforcements(faction_id: String) -> Array:
	var state := faction_state(faction_id)
	var key := block_key()
	if state["respondersBlock"] == key:
		return []
	var levels := counts_to_levels(state["reserve"])
	levels.reverse()
	levels = levels.slice(0, int(GameData.MUSCLE["reserveResponders"]))
	if not levels.is_empty():
		state["respondersBlock"] = key
	return levels


static func _no_passive_xp(g: Dictionary) -> bool:
	for t in g["traits"]:
		if bool(GameData.MUSCLE_TRAITS[t]["params"].get("noPassiveXp", false)):
			return true
	return false
