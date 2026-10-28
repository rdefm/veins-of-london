# 10 — Prophet's Breath

**What to build:** Gaining sight has a visible payoff: hidden enemy plans flip into view (proposal §3.7):

- **Launch:** `cast`; a pale cyan ribbon (a wobbling 1-px line, no sheet) drifts from the actor across to the enemy band.
- **`sightGiven`** (an ally gives the player sight): the ribbon goes ally → player first, then out to the enemies.
- **Land:** each enemy whose plans were just revealed gets a quick 2-px cyan outline sweep (top → bottom, ~200ms).
- **The payoff:** every `?` strip card that becomes read flips like a departure-board flap to its real intent, staggered ~40ms per card.
- **Carry-in** (fight starts under sight): the flip runs once after the intro deal-in.
- Sight's ongoing status is ticket 01's eye icon; nothing lingers on sprites.

**Blocked by:** 01 — Status icon row

**Relevant files:**
- `scenes/screens/combat_rounds.gd` (`beat_cues()` sight/sightGiven; strip entry building `_position_text()`, `actionUnread`; intro)
- `scenes/components/turn_order_strip.gd` (card text change → flap flip; `deal_in()`)
- `scenes/components/combat_stage.gd` (outline sweep)
- `data/combat_visuals.json`
- `tests/test_combat_rounds.gd`, `tests/test_combat_stage.gd`
- REFERENCE.md §3.7b Fog, Items (prophetsBreath), Carry-in effects, Table 5 (guard-kit Prophet's Breath)

**Status:** ready-for-agent

- [ ] Ribbon on `sight`; ally → player → enemies on `sightGiven`
- [ ] Outline sweep only on enemies with newly read plans
- [ ] `?` cards flip to real intents, staggered
- [ ] Carry-in flip after the intro
- [ ] Rewind shows restored cards with no flip; quick pacing halves; reduced motion swaps the flip for an instant change
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: player Prophet's Breath with several `?` cards; an ally's; a carry-in fight
