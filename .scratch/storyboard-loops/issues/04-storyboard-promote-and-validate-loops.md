# 04 — Storyboard: promote and validate loop events

**What to build:** Promote turns a draft containing hub loops into a flat live event with backward gotos and `reselectable` flags. It refuses a hub that has no forward exit (every option back-edges or is hidden after use). `implement-storyboard-event` handles loop drafts. Demo: a small "ask questions" hub event promoted and played headless.

**Blocked by:** 01, 02, 03.

**Relevant files:** `tools/storyboard.html` (Promote ~1991, `findCycle` check ~1999, flat->draft import ~1070), `.claude/skills/implement-storyboard-event`, `data/events/` (demo event), `tests/` event data validation, `docs/writing-guide.md` (document the hub-loop pattern), `CODEMAP.md`. PROSE-REVIEW needed for demo prose.

**Status:** ready-for-agent

- [ ] Promote lays out a draft with back-edges as a valid flat event
- [ ] Promote refuses a hub with no forward exit, naming the card
- [ ] Round trip: flat loop event -> draft -> flat is lossless
- [ ] Demo hub event runs headless: ask A, ask B, "No more questions" advances the branch
- [ ] `scripts/run_tests.sh` and `scripts/check_all.sh` clean
