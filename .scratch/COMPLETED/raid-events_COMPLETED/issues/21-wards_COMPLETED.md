# 21 — Wards: time ward, generic ward, Prophet's Breath read

**What to build:** Warded veins carry a ward whose type is the owning faction's primary ore, stored on the vein so it can differ later (proposal §1.7). Ward types live in data (name, freeze rounds, trigger effects, fight start, counters), using existing effect ops and fight conditions, so a new ward type is data plus at most one fight condition.

- **Time ward** (Guild): when triggered, the player is frozen. Alert goes to Suspicious, the reinforcement clock gains a tick (or starts), and if a fight follows on that card the player starts frozen for the ward's 2 rounds (player-side start condition from 14).
- **Generic ward** (every other faction, until ticket 30): when triggered, alert goes to Suspicious. Nothing else.
- **Enhancement Powder vs a time ward:** the Powder's combat power for the tier spent ([1,1,2,2,3]) is compared with the freeze. Power ≥ freeze means no trigger and no alert. Lower power still triggers, and the next window card gets the Powder bonus.
- **Prophet's Breath on observation:** an item can be toggled on an observation read. Spending Prophet's Breath on the read guarantees the ward line is revealed (type and effect) whatever the roll. It's spent on commit and Rewind refunds it.

The ward card's other counters (decoy, trick a guard into it, Wormhole bypass, Time Pearl freeze) are authored with existing effect kinds in the events.

**Blocked by:** 14 — Fight presets; 15 — Item options without a roll; 16 — Raid alert level; 20 — Site security profile. (Reinforcement clock tick lands when 23 does; until then the trigger only raises alert.)

**Relevant files:** `data/wards.json` (new), `data/factions.json` (`primaryOre`), `systems/factions.gd` (claim ~L100), `systems/events.gd` (`apply_item_effect()` ~L808, `apply_effects()`), `systems/observation.gd` (`read()` ~L34, `rows()` ~L67), `systems/combat_rounds.gd` (`frozenActions`, Powder power), `scenes/screens/event.gd` (item toggle on an observation read), `tests/test_observation.gd`, `tests/test_event_items.gd`, `CODEMAP.md`, `.scratch/raid-events/raid-variants-proposal.md` §1.7, REFERENCE.md §3.9a, §3.9d Observation, §3.7b Open/Guarded round combat, §3.8 (Powder).

**Status:** ready-for-agent

- [ ] Ward schema and ward types documented in REFERENCE.md
- [ ] Tests (seeded): Guild warded vein gets a time ward, others generic; trigger raises alert to Suspicious and freezes the player in a following fight; Powder T3 passes a 2-round time ward with no alert, T1 triggers it; Prophet's Breath read reveals the ward on a failed roll and is spent; Rewind refunds it
- [ ] CODEMAP updated for `data/wards.json`
- [ ] New UI strings flagged `PROSE-REVIEW:`
- [ ] Human on-device check: the Prophet's Breath toggle on an observation read, and a frozen-start fight
