# 06 — Backdrop picker in setup

**What to build:** The Combat Prototype setup card gets a backdrop choice (fight context and optional location, same lists as the debug combat setup modal). The fight's stage backdrop follows it. The choice is view/setup config passed into the fight and stored in the prototype's own state, never in live combat state.

**Blocked by:** 03.

**Relevant files:** `scenes/screens/combat_prototype.gd` (setup card), `scenes/modals/combat_setup_modal.gd` (context/location lists reference; check actual path), `systems/combat.gd` (`DEBUG_SETUP_CONTEXTS`), `systems/combat_prototype.gd` (`start` config), `scenes/components/combat_stage.gd` (`_sync_backdrop`), `data/combat_visuals.json` (`backdrops`, `locationBackdrops`).

**Status:** ready-for-agent

- [ ] Setup shows context + location pickers; the picks survive setup rebuilds.
- [ ] The stage backdrop matches the pick (screen test checks the context/location handed to the stage).
- [ ] Default (no pick) renders a valid backdrop.
- [ ] On-device QA list in the report.
