# 31 — Grilling: more raid events for more location types

**What to build:** A grilling session (the `grilling` skill) with the human, then a proposal, for further vein-raid events at new location types, following the stage-tree pattern of the Yard, the Arches and the Shop (proposal §1–5). New location suffixes are added to the vein location generator and the suffix → event map (09). No code or prose in this ticket.

The grilling must settle:
- which location types to add (and their suffixes), and whether existing suffixes are re-mapped
- per event: premise, who guards it, what makes it distinct, observations, routes and cards, item effects, alert rules, failure paths (the same fields as the first proposal)
- whether existing veins keep their current suffix or are re-rolled
- whether the calibration targets (§1.4) still hold after playtest of the first three

Output: a proposal in this folder, handed to the human for approval. After approval, one build ticket and one prose ticket per new event (each prose ticket references `docs/writing-guide.md`, flagged `PROSE-REVIEW:`).

**Blocked by:** 10 — The Arches; 11 — The Shop; 19 — Rebuild `vein_raid`; 26–28 — Prose (built and tested first).

**Relevant files:** `.scratch/raid-events/raid-variants-proposal.md`, `systems/cultivating.gd` (`LOCATION_SUFFIXES` ~L19), suffix → event map from 09, `data/events/vein_raid.json`, `data/events/raid_arches.json`, `data/events/raid_shop.json`, `docs/writing-guide.md`, `docs/M1-LONDON.md` (districts), REFERENCE.md §3.12 Vein raiding.

**Status:** ready-for-human

- [ ] Grilling session held; decisions recorded at the top of the proposal
- [ ] Proposal covers each new event with the fields above
- [ ] Human approval recorded in the proposal
- [ ] Not marked `_COMPLETED` before approval
