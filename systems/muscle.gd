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
		if tier_id != Cultivating.GUARDED_TIER_ID:
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
static func award_repel_xp(post_id: String) -> void:
	for g in available_at(post_id):
		award_xp(g["id"], XP_REPEL)


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
	g["trainingUntilDay"] = int(GameState.state["world"]["day"]) + int(GameData.MUSCLE["training"]["days"])
	award_xp(id, XP_TRAINING)
	Notify.push("%s is away training for a day." % short_name(g), Notify.CATEGORY_INFO)
	EventBus.mark_changed()
	return { "ok": true, "cost": cost }


# Muscle daily tick (R§3.1 ⑥.5j4): passive XP for every available guard on a
# post (Reserve, Lazy, injured and training guards earn none), and clears
# finished training countdowns.
static func daily_tick() -> void:
	var day: int = GameState.state["world"]["day"]
	for g in guards():
		if int(g["trainingUntilDay"]) != 0 and int(g["trainingUntilDay"]) <= day:
			g["trainingUntilDay"] = 0
		if g["post"] == POST_RESERVE or not is_available(g["id"]) or _no_passive_xp(g):
			continue
		award_xp(g["id"], XP_PASSIVE)


static func _no_passive_xp(g: Dictionary) -> bool:
	for t in g["traits"]:
		if bool(GameData.MUSCLE_TRAITS[t]["params"].get("noPassiveXp", false)):
			return true
	return false
