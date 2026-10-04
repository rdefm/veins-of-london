# 09 — Dial level scales Complication casts

**What to build:** Every loaded Complication cast, in combat or an event, scales with its owner Dial's level. Numeric magnitudes (damage, healing, shield absorption) use `1 + 0.25 × level`, combined multiplicatively with Impact's Movement bonus and rounded once at the end with the established integer rule. Time Pearl freeze and Prophet's Breath evade add one turn per Dial level instead of the multiplier, once per cast after Spread. Black Hole damage uses the multiplier; its base freeze is derived without that multiplier, plus one turn at level 3 and another at level 5, once per cast after Spread. Enhancement Powder applies the multiplier before its extra-turn thresholds. Fixed-effect semantics, targeting, charge and turn costs are unchanged. Timed Complications show their level-based turn bonus in the UI. Applies to the player's Dial now; written owner-generic so 10 extends it to allies.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/dial.gd`, `systems/combat.gd`, `systems/event_items.gd`, `data/dial.json`, `scenes/components/dial_widget.gd`, `scenes/screens/hq_dial.gd`, `tests/test_dial.gd`, `tests/test_combat.gd`, `tests/test_event_items.gd`. Update REFERENCE §1.4, §3.5, §3.7 with the change.

**Status:** ready-for-agent

- [ ] Multipliers 1.25/1.5/1.75/2/2.25 for levels 1–5, single rounding, Impact composition tested
- [ ] Time Pearl / Prophet's Breath +level turns, applied once after Spread
- [ ] Black Hole +1 freeze at L3, +2 at L5; base freeze unaffected by multiplier
- [ ] Enhancement Powder thresholds evaluated on multiplied power
- [ ] Event casts scale too
- [ ] Turn bonus visible on timed Complications
