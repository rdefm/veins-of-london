# 08 — Free-action spend in Prospect, Prune and Seed

**What to build:** Route the remaining block-spending Mind/Soul actions through ticket 07's spend function:
- Prospect (Mind);
- Prune light/hard (Soul);
- vein Seed (Soul).

When the spend is free, each action's result modal or notification prints the perk line. Study, Meditate and Train never go through it.

Lab craft, Movement craft and Dial winding spend no block and are out of scope here (see 09).

**Blocked by:** 07 — Free-action spend core.

**Relevant files:**
- `systems/sites.gd:236-253` (`prospect`; keep the defend-raid check before the spend)
- `systems/cultivating.gd:352-367` (`prune`)
- `systems/sites.gd:395-417` (`attempt_seed`)
- callers' result UI: map site sheet, station bubble
- `systems/ambush.gd`, if the spend gates an ambush roll

**Status:** ready-for-agent

- [ ] Per action: a forced-free result leaves the block unchanged and the result carries the reason
- [ ] Per action: a non-free result advances 1 block as today
- [ ] Exhausted time → refused as today
- [ ] On-device: the free-action line shows after Prospect/Prune/Seed
