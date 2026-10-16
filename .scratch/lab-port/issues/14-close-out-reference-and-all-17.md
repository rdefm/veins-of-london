# 14 — Close-out: REFERENCE rewrite and all-17 gate

**What to build:** Docs match the shipped Lab, and the content test enforces that every recipe in the game has a procedure. Spec: `.scratch/lab-port/spec.md` § Docs, user story 37.

**Blocked by:** 06, 07, 08, 10, 11, 12, 13

**Relevant files:**
- `docs/REFERENCE.md` §2 (state), §3.5 Crafting & the Dial, M3 discovery mechanics
- `tests/test_lab_content.gd`
- `CODEMAP.md`, `CONTEXT.md`

**Status:** ready-for-agent

- [ ] REFERENCE §3.5 rewritten: fixed per-recipe calc, no player chance roll, rank = tier, tolerance formula + bonus conversion, re-run bonus, staff tier from staffer level capped at 4; player cost formula retired
- [ ] M3 discovery mechanics retired in REFERENCE
- [ ] `lab` state paths added to §2
- [ ] Content test asserts all 17 recipes have a procedure
- [ ] CODEMAP has no stale bench/prototype/lottery rows; check_all + full suite green
