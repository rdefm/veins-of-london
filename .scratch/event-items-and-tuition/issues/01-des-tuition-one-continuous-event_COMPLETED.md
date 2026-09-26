# 01 — Des tuition plays as one continuous event

**What to build:** Once Archie's pending message starts the Collective Act 1 intro, the whole Des tuition plays as one unbroken sequence: intro → prospecting → seeding → hub, each starting the moment the previous one ends. The player never gets sent back to the map, phone or contacts in between. The prospecting and seeding map pins and phone shortcuts go, as do Des's "three things" pending message and the intro's "Check the map" notify. The only screen change is hub's final one. The end state matches today's post-hub state: Des, Nadia and Hakim unlocked, collective lane unlocked, relation awarded, all tuition/hub flags set, and the player lands on Phone. The tuition objectives (prospecting, seeding, hub reached) are deleted because the chain now finishes in one sitting and nothing else uses them.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `data/events/col_a1_intro.json`; `data/events/col_a1_prospecting.json`; `data/events/col_a1_seeding.json`; `data/events/col_a1_hub.json`; `data/objectives.json`; `systems/events.gd` (`start_event`, `advance` — on_complete nulls state.event before running effects; see existing chains in `data/events/col_a2_intro.json`, `col_a2_shop.json`); `systems/map_pins.gd`; `tests/test_col_a1_tuition.gd`; `docs/REFERENCE.md` §3.11; `CODEMAP.md` if file responsibilities change.

- [ ] Finishing col_a1_intro starts col_a1_prospecting straight away; finishing that starts col_a1_seeding; finishing that starts col_a1_hub. Intro, prospecting and seeding have no set_screen ops between them.
- [ ] Prospecting and seeding have no `pin` block, so no map pin or phone shortcut appears for them.
- [ ] Seeding no longer queues the Des `col_a1_hub` pending message, and intro no longer sends the "Check the map" notify.
- [ ] Every flag, unlock and relation effect the four events applied before still gets applied, and the chain ends on the Phone screen.
- [ ] Objectives `col_a1_prospecting`, `col_a1_seeding` and `col_a1_hub_reached` are removed from objectives data, and no code or test references them.
- [ ] Rewind inside the chained events can't strand the player outside the sequence.
- [ ] Tuition tests are updated for the single-sequence flow, with the pin/phone-shortcut/pending-message tests removed or replaced by a test that plays intro to hub end to end. Syntax check clean, full suite passes.
- [ ] Report on-device check: meet Des, then tap Continue through all four events without leaving the event screen.
