# 03 — player.bench state shape + Rewind round-trip

**What to build:** The pure-data state tree the Lab reads and writes, with no logic yet attached — just the shape, its defaults, and proof it survives save/load and the game's Rewind (snapshot) feature untouched. This unblocks `bench.gd` from being written against a state shape that doesn't yet exist.

**Blocked by:** 02 — Recipe ingredients schema migration.

**Status:** ready-for-agent

- [ ] `state.player.bench` added with the shape: `approaches` (array), `surveyed` (dict, type-set key → int), `cells` (dict, `"<typeset>|<approach>"` key → `{state, misses, refine}`), `notes` (dict, type-set key → capped array of `{day, approach, outcome}` enums).
- [ ] Absent cell keys resolve to `untried` by default — cells are written lazily, not pre-populated for all 15 pairings.
- [ ] Transient `state.benchNav: { view: "home", types: [], approach: null }` added at the top level of `state` alongside `mapNav`/`phoneNav`; resets to default on load, not meaningfully persisted across sessions.
- [ ] `player.bench` included correctly in save/load round-trip.
- [ ] `tests/test_snapshots.gd` extended: explicit case asserting `player.bench` round-trips through a snapshot/Rewind unchanged — an already-discovered effect (`state: "found"`) does not revert to `untried` or `hot` after a Rewind.
- [ ] Syntax check clean on all touched `.gd` files.
