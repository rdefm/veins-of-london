# 06 — Combat sprites 1.5× bigger

**What to build:** Every sprite in the combat view — player, allies, enemies — is drawn at 1.5× its current size.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/combat_stage.gd`, `scenes/screens/combat.gd`, `scenes/modals/combat_setup_modal.gd` (debug setup for checking max enemy counts), `scripts/debug_combat_*_screenshot.gd`.

**Status:** ready-for-agent

- [ ] All combat sprites render at 1.5× current size
- [ ] Scale factor lives in data/config, not a magic number
- [ ] Layout still fits phone width at max enemy count (checked via debug combat setup)
