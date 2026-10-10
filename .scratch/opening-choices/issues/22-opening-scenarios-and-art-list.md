# 22 — Full opening scenarios, card budget and art list

**What to build:** Scenario tests play the whole opening chain intro → buyer → James → Archie catch-up → home raid → debrief along five paths (cautious, bold-success, bold-fail, bluff, passive) through the Events API, asserting payoffs land and every path reaches the vein handover. The opening's total card count is checked against the ~50 target. A list of new or branched cards needing plates is handed to the event-storyboard process.

**Blocked by:** 21 — Continuity sweep.

**Relevant files:** opening scenario test file (from 12), `tests/test_col_a1_*.gd` (scenario prior art), `data/events/{intro,buyer,james_meeting,archie_craft_chat,home_raid_intro,home_raid_debrief_win,home_raid_debrief_loss,archie_cultivation}.json`, `.scratch/event-art/` (storyboard boards), `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Five chain scenarios green; Rewind-then-same-choice gives same result in at least one.
- [ ] Old save (pre-change) loads mid-opening (test).
- [ ] Card count reported vs ~50 (from ~80).
- [ ] Art list written to `.scratch/event-art/` for the storyboard pass.
- [ ] Full suite + `scripts/check_all.sh` green; human playthrough checklist in report.
