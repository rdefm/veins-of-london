# 03 — Explore event effects for the other event-usable consumables

**What to build:** A design pass, not code. Decide which of the other consumables and Dial complications should be usable from the event Item button, what each does in an event, and when each counts as eligible. Candidates: the recipes marked `eventUsable: true` besides Rewind (Prophet's Breath, Be a Lady, Pan's Prank, Failsafe, Wormhole) and any Dial complications. One example to settle: Be a Lady on a choice whose outcome rolls a `chance` or `stealth_check` — a flat bonus scaled by effectPower, or a guaranteed success? The output is an agreed spec, with numbers added to REFERENCE.md once the human approves them, plus follow-up implementation tickets that plug into ticket 02's registry. Requires human decisions; the agent proposes options and does not invent mechanics.

**Blocked by:** 02 — Event Item button replaces Rewind; choices fit or stack.

**Status:** needs-triage

**Relevant files:** `data/recipes.json`; `data/dial.json`; `systems/events.gd` (`chance`, `stealth_check` ops); `systems/raiding.gd` (`consumable_bonus`); `data/events/camden_shakedown.json`; `data/events/city_suit.json`; `data/events/vein_raid.json`; `docs/REFERENCE.md` §1.3, §1.4, §3.5 Crafting & the Dial, §3.9 Snapshots & Rewind.

- [ ] Every `eventUsable` consumable and relevant Dial complication has a human-approved decision: in or out of events, its effect, eligibility rule and spend rule.
- [ ] Approved numbers and rules are recorded in REFERENCE.md.
- [ ] Implementation tickets are filed for each approved item, each blocked by 02.
