# 36 — Shop reads: vein room and getaway

**What to build:** New per-card observations for `s_room` (guard layout, the vein itself under the floor; candidates life, physics, emotion) and `s_getaway` (the exit through the shop, who is still at the till; candidates emotion, life, time). Hooks to consider: Bluff past odds, Out through the shop odds. A callback to the till worker is welcome, not required.

Rules that bite: one new observation id per card (`observe: "<id>"` on the card); 2-3 ores only where narratively fitting, no filler ores; existing observations (`raid`) and their texts are untouched; observation lines describe what is there, never what to do about it; one dry line per threat; a mix of informative, mechanical (an `observed` unlock in `requires`, or an `observed` check mod) and funny reads, with mechanics only where they make narrative sense, never forced. Reuse existing mod values (+0.05 / +0.13) and shapes from this file; if a new number is needed, ask. Choice cards cap at 4 options (`Events.MAX_OPTIONS`), so new options go on the `…2` follow-up card. Prose is drafted against `docs/writing-guide.md` and `docs/CONTENT-GUIDE.md`, building on the edited storyboard draft (see Relevant files) (voice, characters, anchors: build on it, do not replace it). Each new line is listed under `PROSE-REVIEW:` in the report. Observation lint: REFERENCE.md §3.9d (tiers best-first, a `miss` text per block, `atLeast` within tiers).

**Blocked by:** None — can start immediately (tickets 32-36 edit different cards of the same event file; rebase on whatever is live).

**Relevant files:** `data/events/raid_shop.json`, `.scratch/writing-revamp/raid-shop-proposal.md`, `docs/writing-guide.md`, `docs/CONTENT-GUIDE.md`, `docs/REFERENCE.md` §3.9d Observation, `tests/test_raid_shop.gd`, `tests/test_event_content_lint.gd`

**Status:** ready-for-agent

- [ ] New observation ids defined under `observations` and attached via `observe` on the cards above
- [ ] Hooks (unlocks / odds mods) added only where narratively sound; existing option text and observations unchanged
- [ ] A `miss` line on every new block
- [ ] `tests/test_raid_shop.gd` extended for each new gate; `tests/test_event_content_lint.gd` passes
- [ ] Report lists every new line under `PROSE-REVIEW:`
