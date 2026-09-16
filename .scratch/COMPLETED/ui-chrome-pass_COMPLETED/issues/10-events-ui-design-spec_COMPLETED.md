# 10 — Events UI design spec

**What to build:** `scenes/screens/event.gd` (the generic event-card
screen driven by `state.event`, covering district events and story-beat
events alike) hardcodes its own `AMBER_COLOR`/`AMBER_BG`/`DANGER_COLOR`
constants — the old placeholder look, never touched by any Family 1-4
reskin pass. `docs/ui-vision.md` doesn't assign events to any of the 4
families at all — this is an undecided design gap, not just unbuilt work.

Write a short design note (same shape as the Family 4 session) deciding
how event/dialogue cards should look — narration/speaker/tension/
resolution/craft/choice card types per `systems/events.gd`'s card schema —
and which family (or bespoke treatment) they belong to. Output should be a
doc update (new `ui-vision.md` section or sibling doc), not code.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] Design note picks a family (existing 1-4) or defines a new bespoke treatment for event cards, with rationale
- [ ] Covers all card types the event schema supports (narration/speaker/tension/resolution/craft/choice) plus the action bar (Continue/Rewind/choice buttons)
- [ ] Reconciled against §6 (accent reservations) and §7 (one shared UI sans)
- [ ] Reviewed/confirmed by a human before ticket 11 starts
