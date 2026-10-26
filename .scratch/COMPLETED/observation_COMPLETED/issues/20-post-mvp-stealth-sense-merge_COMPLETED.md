# 20 — Stealth → Sense merge

**Phase:** Post-MVP

**What to build:** Stealth folds into Sense. Migrate existing stealth XP into Sense on load, then remove `stealth_check`, `stealthSkill`, `stealthXpLevels` and `Raiding.stealth_success_chance()`. Migration rule (e.g. add XP vs. take max) to be decided by the human.

**Blocked by:** MVP playtest sign-off by the human — **APPROVED by the human**; 18, 19.

**Relevant files:** `systems/raiding.gd`, `systems/events.gd`, `data/stealth.json`, save migration code, `tests/test_raiding.gd`; REFERENCE.md §2 STATE SCHEMA, §6 SAVE FORMAT; CONTEXT.md; CODEMAP.md.

**Status:** needs-triage

- [ ] Old saves load with stealth XP migrated per agreed rule
- [ ] No reference to `stealth_check` / `stealthSkill` / `stealthXpLevels` in code or data
- [ ] Lint rejects `stealth_check`
- [ ] REFERENCE / CONTEXT / CODEMAP updated
