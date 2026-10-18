class_name ActiveEffects
extends RefCounted

# Timed out-of-combat item effects: state.player.activeEffects is a list of
# { item, level, expiresAtBlock } (R§2). expiresAtBlock is an absolute block
# index (day × blocks-per-day + timeBlock); an effect holds while the current
# absolute block is below it. Durations by item level and the usable item
# list live in data/constants.json activeEffects.

const LADY := "beALady"
const PROPHETS_BREATH := "prophetsBreath"
# PROSE-REVIEW: preview tag on a max-rolled cultivate/harvest figure.
const LADY_TAG := "(Lady)"


static func absolute_block() -> int:
	var world: Dictionary = GameState.state["world"]
	return int(world["day"]) * TimeSystem.BLOCKS_PER_DAY + int(world["timeBlock"])


static func duration_for_level(level: int) -> int:
	var table: Array = GameData.ACTIVE_EFFECTS["durationByLevel"]
	return int(table[clampi(level, 1, table.size() - 1)])


static func usable_items() -> Array:
	return GameData.ACTIVE_EFFECTS["items"]


static func effects() -> Array:
	return GameState.state["player"]["activeEffects"]


static func find(item: String) -> Variant:
	for effect in effects():
		if effect["item"] == item and int(effect["expiresAtBlock"]) > absolute_block():
			return effect
	return null


static func is_active(item: String) -> bool:
	return find(item) != null


# One-line "what it does" for an effect item, from recipes.json effectText.
static func effect_text(item: String) -> String:
	return str(GameData.RECIPES.get(item, {}).get("effectText", ""))


static func blocks_left(effect: Dictionary) -> int:
	return maxi(0, int(effect["expiresAtBlock"]) - absolute_block())


static func lady_active() -> bool:
	return is_active(LADY)


# The running Be a Lady's level (its unit's tier), 0 when none runs.
static func lady_level() -> int:
	var effect = find(LADY)
	return int(effect["level"]) if effect != null else 0


static func prophets_breath_active() -> bool:
	return is_active(PROPHETS_BREATH)


# Consumes one unit (lowest level first) and starts the effect, or refreshes
# it to that unit's level and full duration if already running.
static func use(item: String) -> Dictionary:
	if not usable_items().has(item):
		return { "ok": false, "reason": "Can't use that here." }
	if Crafting.inventory_qty(item) <= 0:
		return { "ok": false, "reason": "None left." }
	var taken: Array = Crafting.inventory_remove(item, 1)
	var level: int = int(taken[0]["tier"]) if not taken.is_empty() else 1
	var expires: int = absolute_block() + duration_for_level(level)
	var list: Array = effects()
	for i in range(list.size() - 1, -1, -1):
		if list[i]["item"] == item:
			list.remove_at(i)
	list.append({ "item": item, "level": level, "expiresAtBlock": expires })
	var name: String = GameData.RECIPES[item]["name"]
	var blocks: int = duration_for_level(level)
	# PROSE-REVIEW: active-effect start notification.
	Notify.push("%s taken. %d block%s." % [name, blocks, "" if blocks == 1 else "s"], Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	return { "ok": true, "level": level, "expiresAtBlock": expires }


# Drops every effect whose expiry block has been reached. TimeSystem calls
# this whenever the clock moves.
static func expire() -> void:
	var now := absolute_block()
	var list: Array = effects()
	for i in range(list.size() - 1, -1, -1):
		if int(list[i]["expiresAtBlock"]) <= now:
			list.remove_at(i)
