# 14 — Dial complication slots scale with level, drop capacityCost

**What to build:** The Dial's complication capacity grows by dial level
instead of the current uneven `[0, 4, 6, 9, 12, 16]` curve, and each loaded
complication now costs exactly one slot regardless of which recipe it is.
`Dial.capacity_max(level)` returns `[0, 1, 2, 3, 4, 4]` (index = level,
capped at 4 max). `Dial.load_complication`/`unload_complication` and
`Dial.capacity_used` switch from summing each entry's `capacityCost` to
counting loaded entries. `data/recipes.json`'s per-recipe `capacityCost`
field is removed (or left unused if removing it outright touches too many
call sites — but the load/unload budget check must no longer read it).
`docs/REFERENCE.md` §1.4/§3.5 updated to describe the new flat one-slot-per-
complication rule and the new `capacityByLevel` curve.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `Dial.capacity_max(level)` returns `[0, 1, 2, 3, 4, 4]`
- [ ] `Dial.capacity_used(dial)` counts loaded entries, not summed `capacityCost`
- [ ] `Dial.load_complication`/`unload_complication` gate purely on slot count vs `capacityMax`, no per-recipe cost
- [ ] `data/recipes.json`'s `capacityCost` field no longer drives loading (removed, or confirmed dead)
- [ ] `docs/REFERENCE.md` §1.4/§3.5 updated to match
- [ ] `tests/test_dial.gd` covers the new curve and flat-cost loading/unloading
