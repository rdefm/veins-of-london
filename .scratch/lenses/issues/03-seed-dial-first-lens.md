# 03 — Seeding a Dial chooses the first lens

**What to build:** Spec `.scratch/lenses/spec.md` "First lens". `Dial.attempt_seed(haft_id, lens_ore)`: on success the new Dial has a lens of `lens_ore` loaded in slot 1 (tier = crafting skill at seed). Failure gives nothing, as today. The HQ Dial unseeded screen adds the ore choice (five ore glyphs) before Seed. New strings PROSE-REVIEW.

**Blocked by:** 01

**Status:** ready-for-agent

**Relevant files:**
- `systems/dial.gd`
- `scenes/screens/hq_dial.gd`
- `systems/james_dial.gd`
- `tests/test_dial.gd`
- `tests/test_hq_dial.gd`
- `docs/REFERENCE.md` §1.4

**Acceptance:**
- [ ] Seed success loads the chosen-ore lens; failure leaves no Dial and no lens.
- [ ] Seed refused without a valid ore.
- [ ] HQ seeding screen offers the ore choice (human QA).
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.
