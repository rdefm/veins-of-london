# 18 — Player non-violent moves

**What to build:** The player can fight back without raiding: file a complaint, tip off the police, or leak to the Ticker against a faction. Each move costs £ and/or a block and is gated by an intel level on the target. Effects reuse faction-side harassment effects where possible (security freeze on a target vein, a price penalty on its goods, a Ticker push). The moves count as hostile acts for relation and the Truce break rule, and they answer grudges. They don't count towards warmonger.

**Blocked by:** 17 — Grudges; 15; 16

**Relevant files:** `systems/diplomacy.gd` (or a sibling system), `systems/intel.gd` (gating levels), `systems/network_handler.gd` (`security_freeze` prior art), `systems/barometer.gd` (Ticker push), `systems/faction_ai.gd` (hostile act, truce break), the grudge answer hook from 17, `scenes/screens/factions.gd` / `scenes/components/contact_cards.gd` (actions), `data/factions.json` or diplomacy config (costs, gates — TBD), tests: `test_diplomacy`, `test_intel`, `test_grudges`. REFERENCE.md Grudges §, §3.10.

**Status:** ready-for-agent

- [ ] Three moves with cost, intel gate and effect from data
- [ ] Effects land on the target faction (frozen vein / price penalty / Ticker push)
- [ ] Each counts as a hostile act (relation drop, breaks a truce) and answers an open grudge
- [ ] Not logged as a warmonger act (verify once 20 lands; leave a test hook)
- [ ] UI QA list; any new strings flagged `PROSE-REVIEW`
