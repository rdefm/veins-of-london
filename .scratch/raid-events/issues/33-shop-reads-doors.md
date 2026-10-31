# 33 — Shop reads: cellar door, yard, yard door

**What to build:** New per-card observations for `s_lock` (lock type, who has been through it; candidates physics, fate), `s_yard` (the smoker: how long his break runs, what is on his phone; candidates life, time) and `s_door` (hinge pins, paint, the latch; candidates physics, time). Hooks to consider: odds on Pick it quiet / Wait for the smoker / Pose as the delivery / Slide the hinge pins out.

Rules that bite: one new observation id per card (`observe: "<id>"` on the card); 2-3 ores only where narratively fitting, no filler ores; existing observations (`raid`) and their texts are untouched; observation lines describe what is there, never what to do about it; one dry line per threat; a mix of informative, mechanical (an `observed` unlock in `requires`, or an `observed` check mod) and funny reads, with mechanics only where they make narrative sense, never forced. Reuse existing mod values (+0.05 / +0.13) and shapes from this file; if a new number is needed, ask. Choice cards cap at 4 options (`Events.MAX_OPTIONS`), so new options go on the `…2` follow-up card. Prose is drafted against `docs/writing-guide.md` and `docs/CONTENT-GUIDE.md`, building on the edited storyboard draft (see Relevant files) (voice, characters, anchors: build on it, do not replace it). Each new line is listed under `PROSE-REVIEW:` in the report. Observation lint: REFERENCE.md §3.9d (tiers best-first, a `miss` text per block, `atLeast` within tiers).

**Blocked by:** None — can start immediately (tickets 32-36 edit different cards of the same event file; rebase on whatever is live).

**Relevant files:** `data/events/raid_shop.json`, `.scratch/writing-revamp/raid-shop-proposal.md`, `docs/writing-guide.md`, `docs/CONTENT-GUIDE.md`, `docs/REFERENCE.md` §3.9d Observation, `tests/test_raid_shop.gd`, `tests/test_event_content_lint.gd`

**Status:** ready-for-agent

- [ ] New observation ids defined under `observations` and attached via `observe` on the cards above
- [ ] Hooks (unlocks / odds mods) added only where narratively sound; existing option text and observations unchanged
- [ ] A `miss` line on every new block
- [ ] `tests/test_raid_shop.gd` extended for each new gate; `tests/test_event_content_lint.gd` passes
- [ ] Report lists every new line under `PROSE-REVIEW:`
