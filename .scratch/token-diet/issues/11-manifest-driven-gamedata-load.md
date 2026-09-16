# 11 — Manifest-driven GameData load

**What to build:** The data loader is driven by one declarative table — for each table: which file, which JSON key, which loader field, expected type — and a single loop reads, type-checks and assigns them. Bespoke per-table validators remain (they hold real rules) but each takes the loaded table(s) it needs rather than a dozen positional arguments. The snapshot used by tests is derived from the same manifest so the two can't drift. Every table's loaded value is identical to today's.

**Blocked by:** 10 — Events auto-discovered from data/events/.

**Relevant files:** `autoload/GameData.gd`, `data/*.json` (read only), `tests/test_gamedata.gd`, `CODEMAP.md`. Table names and shapes are canonical in `docs/REFERENCE.md` — no renames.

**Status:** ready-for-agent

- [ ] Every public loader field holds exactly the same value after boot as before (snapshot-equality test against a pre-change dump).
- [ ] Load function is a manifest + loop; no validator takes more than a handful of parameters.
- [ ] Missing file / wrong type for any manifest entry reports a load error naming the table (test).
- [ ] Syntax check and full test suite green.
