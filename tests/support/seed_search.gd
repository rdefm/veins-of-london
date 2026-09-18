extends RefCounted

# Shared RNG-seed search for tests that need a specific random outcome.
# Static; use via `const SeedSearch := preload("res://tests/support/seed_search.gd")`.
#   find_seed_for(max_tries, fn) -> int   first seed in [0, max_tries) for which fn() is true, or -1;
#                                         GameState.state is restored after every failed try


static func find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1
