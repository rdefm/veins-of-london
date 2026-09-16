extends Node

# Bounded snapshot-stack helper (R§3.9). Stacks live inside GameState.state
# (e.g. state.combat.snapshots), so state stays a pure, save/load-safe tree.
#
# CAUTION: a caller building `snapshot` via GameState.deep_copy(GameState.state)
# must empty this stack first, or each push embeds the whole stack recursively,
# roughly doubling data size per push. See systems/events.gd's advance()/rewind().

const MAX_SIZES := {
	"combat": 2,
	"event": 8,
	"combatPrototype": 2,  # systems/combat_prototype.gd; same cap as "combat".
}


func push(stack_id: String, stack: Array, snapshot: Variant) -> void:
	stack.append(GameState.deep_copy(snapshot))
	var max_size: int = MAX_SIZES.get(stack_id, 999999)
	while stack.size() > max_size:
		stack.remove_at(0)


func oldest(stack: Array) -> Variant:
	if stack.is_empty():
		return null
	return stack[0]


func clear(stack: Array) -> void:
	stack.clear()


# LIFO pop, leaving earlier frames in place. Event rewind uses this (combat
# rewind instead restores the oldest frame and clears the whole stack) so
# multiple rewind charges can step back one card at a time.
func pop_newest(stack: Array) -> Variant:
	if stack.is_empty():
		return null
	return stack.pop_back()
