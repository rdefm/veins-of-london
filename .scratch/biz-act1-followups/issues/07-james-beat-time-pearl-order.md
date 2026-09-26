# 07 — New James beat: Production setup and first recurring item order

**What to build:** A new Business Empire beat between the current Beat 5 (James joins) and Beat 6 (delegation).

- **Trigger:** fires when James is recruited (Beat 5 scene done). A pending text leads into a tutorial scene.
- **Scene:** covers how to assign James to Production (Staff tab) and how Production settings/targets work. It issues the `biz_recurring_time_pearl` recurring offer (5/week).
- **Objective:** completes when **one full period** of that Time Pearl recurring contract is completed. Only then does Beat 6 queue.
- **Beat 6:** now teaches delegation only and no longer introduces the Time Pearl order.
- **Numbering:** beats after the new one are renumbered in docs and ToDo text. Existing flags/ids stay stable for old saves; add new flags for the new beat.
- **Offers:** recurring **item** offers may appear from this beat onward, lifting ticket 04's ore-only gate.

**Blocked by:** 04 — Recurring ore offers from Beat 3 (shares the recurring-issuance gate this lifts).

**Relevant files:** `systems/business_quest.gd`, `systems/objectives.gd`, `data/objectives.json`, `data/offers.json` (`biz_recurring_time_pearl`), `data/events/biz_a1_partnership.json`, `data/events/biz_a1_put_to_work.json` (trim the Time Pearl intro), a new `data/events/biz_a1_*.json` scene, `systems/todo.gd`, `tests/test_business_quest.gd`, `.scratch/biz-act1/spec.md`, REFERENCE.md §3.10 "Business Empire questline (Beats 1–7)", `docs/CONTENT-GUIDE.md`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] James recruited → pending text → scene. The scene explains the Production role and targets and issues the Time Pearl recurring offer.
- [ ] Objective = one completed period of the Time Pearl recurring contract. The ToDo row reflects it.
- [ ] Beat 6 is gated behind the new beat. Beat 6 no longer issues or introduces the Time Pearl offer. The Beat 6 proof rule (2 recurring, ≥1 crafted) still passes, since the Time Pearl contract can count.
- [ ] Old saves: already past Beat 6 → no new beat fires. Mid Beat 5/6 → it's resolved sensibly (document the migration).
- [ ] REFERENCE.md and the spec are updated with the renumbered beats.
- [ ] New scene prose is flagged `PROSE-REVIEW:`. Tests cover the trigger, offer issue, objective completion and the Beat 6 gate.
