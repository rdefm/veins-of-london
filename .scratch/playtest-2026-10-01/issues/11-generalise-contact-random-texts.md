# 11 — Generalise Owen's random texts into a per-contact system (prefactor)

**What to build:** Turn the Owen-only random text system into a contact-agnostic one: per-contact text pools, per-contact scheduler config (interval, availability gate), templating, reply choices with optional small rewards (XP / relation / cash / item), notifications. Owen migrates onto it with identical behaviour. No new prose.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/owen_texts.gd`, `data/owen_texts.json`, `systems/messages.gd`, `scenes/phone_apps/messages_app.gd` (Owen reply bar), `systems/time_system.gd` (rollover hook), `autoload/SaveManager.gd` (state key migration), `tests/test_owen_texts.gd`, CODEMAP.

**Status:** ready-for-agent

- [ ] Owen's behaviour unchanged on the new system; tests pass
- [ ] Adding a contact = data only (pool + config)
- [ ] Old saves migrate Owen's text state
- [ ] CODEMAP rows updated
