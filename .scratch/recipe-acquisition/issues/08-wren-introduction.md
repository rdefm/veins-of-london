# 08 — `wren_introduction`

**What to build:** The day after `james_experiment` completes, Wren sends a pending message that opens `wren_introduction`.
- Registrar Wren registers you as a Guild **associate**, not a member.
- She explains what she sells (every recipe that isn't pure time/life), how Guild standing unlocks hints, and that assay commissions build relation.
- Ingram gets one cold line.
- If Wren is already an unlocked contact (from faction messages), one line acknowledges you've met.
- Wren's placeholder `intro` text is replaced with real prose.
- At the end: Wren's recipe shop unlocks, plus the flag that starts assay commissions.

Spec: `.scratch/recipe-acquisition/spec.md` § Implementation Decisions — "Wren introduction"; § User Stories 52–57.

**Blocked by:** 07 — `james_experiment` event.

**Relevant files:**
- new `data/events/wren_introduction.json`; `data/events/james_experiment.json` (queue op at end)
- `data/factions.json` — guild key members (wren ~l.174 placeholder intro, ingram ~l.173)
- messages / pending-message system (`Messages.pending_for`), `systems/calendar.gd` (next-day delivery)
- `scenes/components/contact_cards.gd` (`build_key_member_card`)
- `autoload/GameState.gd` (flags)
- `docs/CONTENT-GUIDE.md`, `docs/writing-guide.md`
- `tests/test_events.gd`
- `CODEMAP.md`; `docs/REFERENCE.md` (flags §)

**Status:** ready-for-agent

- [ ] Wren's message is queued the day after `james_experiment` (not the same day) and opens `wren_introduction`.
- [ ] The event sets its seen flag, Wren's seller unlock flag and the commissions flag.
- [ ] The already-met variant line shows only when Wren was already unlocked.
- [ ] Ingram has exactly one line. Wren reads as a proper character. Placeholder intro gone.
- [ ] Content lint passes. PROSE-REVIEW: whole event + Wren intro.
- [ ] On-device QA block in report.
