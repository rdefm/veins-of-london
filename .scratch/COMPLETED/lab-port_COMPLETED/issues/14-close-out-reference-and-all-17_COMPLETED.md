# 14 — Close-out: REFERENCE rewrite and all-17 gate

**What to build:** Docs match the shipped Lab, and the content test enforces that every recipe in the game has a procedure. Spec: `.scratch/lab-port/spec.md` § Docs, user story 37.

**Blocked by:** 06, 07, 08, 10, 11, 12, 13

**Relevant files:**
- `docs/REFERENCE.md` §2 (state, ~L432 `craftQty`), §3.5 Crafting & the Dial, M3 discovery mechanics, Perks (~L392), Contracts unattended proof (~L904)
- `docs/ui-vision.md` (~L784), `docs/M3-CALC-DISCOVERY.md`
- `tests/test_lab_content.gd`
- `CODEMAP.md`, `CONTEXT.md`

**Status:** ready-for-agent

- [ ] REFERENCE §3.5 rewritten: fixed per-recipe calc, no player chance roll, rank = tier, tolerance formula + bonus conversion, re-run bonus, staff tier from staffer level capped at 4; player cost formula retired
- [ ] M3 discovery mechanics retired in REFERENCE
- [ ] `lab` state paths added to §2
- [ ] §2 `craftQty` entry removed (state key dropped in save v12)
- [ ] REFERENCE Perks `craftChanceBonus`: applied via `Lab.bench_bonus`, not `Crafting.attempt_craft`
- [ ] REFERENCE Contracts `playerAssisted`: set by `Crafting.file_crafted`, not `Crafting.attempt_craft()`
- [ ] `docs/ui-vision.md` Recipes notebook font note points at `hq_lab_bench.gd`, not the deleted `lab_bench_recipe_book_modal.gd`
- [ ] `docs/M3-CALC-DISCOVERY.md` marked superseded by the Lab port (or retired) — ask the human which
- [ ] Content test asserts all 17 recipes have a procedure
- [ ] CODEMAP has no stale bench/prototype/lottery rows; check_all + full suite green
