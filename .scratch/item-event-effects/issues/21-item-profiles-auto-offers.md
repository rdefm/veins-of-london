# 21 — Item event profiles + automatic offers

**What to build:** Items carry an event profile in their item data (tags, effect kind and payload, label, optional built-in alert change). A tagged check auto-offers a toggle for every item whose profile tags match. Precedence: an authored mod/requires/no-roll entry for that item suppresses its auto-offer, and `excludeItems` blocks it. Toggles you can't pay for, and item-gated options you can't take, show greyed out with the missing item named. Profiles for Enhancement Powder (physical, lasting), Second Impression (social, lasting), Prophet's Breath (discovery, very large add, still clamped at 0.97) and Sod's Law (no tags, authored only, opposition's-luck label). See spec "Item event profiles" and "Automatic offers".

**Blocked by:** 20

**Relevant files:** `systems/event_items.gd`, `systems/events.gd`, `systems/dial.gd`, `systems/rewind.gd`, `data/recipes.json`, `data/constants.json` (eventChecks strings), `scenes/screens/event.gd`, `tests/test_event_items.gd`; REFERENCE §3.9a.

**Status:** ready-for-agent

- [ ] Tagged check auto-offers a matching item: switchable when payable, greyed and refused when not; untagged check offers none
- [ ] Item-gated option shows greyed out (`display: "disable"`) with the missing item named
- [ ] `excludeItems` and authored mods suppress the offer
- [ ] Synthesised toggle spends on commit pass or fail; Rewind refunds; Dial payment identical
- [ ] Second Impression on social; Prophet's Breath clamped at 0.97; Sod's Law only where authored; tier scaling applies
- [ ] Numbers in data, tagged placeholder; new strings PROSE-REVIEW; REFERENCE §3.9a updated
