# 01 — All four apparatus from start

**What to build:** Every approach (heat, grinding, compression, distilling) is known from a fresh save. The press and still are painted into the new bench art, so they must work as soon as the Lab does, with no room gating. The Workshop and Improved Lab rooms keep their other effects (crafting bonus, business-quest beat, objectives); they just stop gating an approach. Existing saves gain both approaches immediately.

**Blocked by:** None — can start immediately

**Relevant files:**
- `data/approaches.json` — `compression` / `distilling` `source` → `{ "type": "start" }`
- `systems/approaches.gd` — `get_known()`, `source_text()` (the "room" branch may become unused; keep or trim per code)
- `tests/test_approaches.gd`, `tests/test_bench.gd`, `tests/test_home.gd` — any assertion that compression/distilling are room-gated
- `scenes/screens/hq_lab_bench.gd` — `_filter_and_label_apparatus_regions()` erases unknown approaches (now a no-op in practice)
- `docs/M3-CALC-DISCOVERY.md` §4 approach table (lines ~110-118)
- `docs/hq-diorama-vision.md` §5.3 Gate column

**Status:** ready-for-agent

- [ ] Fresh save: `Approaches.get_known()` returns all four
- [ ] Workshop / lab rooms unchanged otherwise (bonus, cost, objectives, business quest)
- [ ] Vision + M3 docs' gate tables say "from the start" for all four
- [ ] Tests updated, full suite green
