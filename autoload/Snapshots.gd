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
