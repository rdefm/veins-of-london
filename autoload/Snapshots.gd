extends Node

# Generic bounded snapshot-stack helper (R§3.9). Stacks live INSIDE
# GameState.state (e.g. state.combat.snapshots, state.event.snapshots) —
# this just owns the push/trim/pop discipline shared by combat rewind
# (T08) and event rewind (T13). Never holds data itself; state stays a
# pure tree, which is what makes it save/load-safe.

const MAX_SIZES := {
	"combat": 2,
	"event": 8,
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


# LIFO pop: removes and returns the most recently pushed snapshot, leaving
# earlier frames in place. Event rewind uses this (unlike combat rewind,
# which restores the oldest frame and clears the whole stack) so multiple
# rewind charges can step back one card at a time.
func pop_newest(stack: Array) -> Variant:
	if stack.is_empty():
		return null
	return stack.pop_back()
