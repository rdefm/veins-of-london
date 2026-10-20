# 16 — Active-effects sheet: actually show each effect's text

**What to build:** Tapping the top-bar effect chips opens the "Under the influence" sheet. Each entry should have a smaller, muted line under it saying what the effect does. Ticket 06 added the effect text to data (`effectText` per item in recipes) and a reader in the active-effects system, but the sheet never renders it, so the player still only sees name · level · blocks left. Render the line under every entry, and make sure every current and future timed effect has text.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/modals/active_effects_modal.gd`, `systems/active_effects.gd`, `data/recipes.json` (`effectText`), `data/constants.json` (`activeEffects.items`), `tests/test_active_effects.gd`

**Status:** ready-for-agent

- [ ] Each running effect in the sheet shows its effect text under the name/level/blocks row, in smaller muted text
- [ ] Test: every item in `activeEffects.items` has non-empty effect text, and the sheet builds a line for it
- [ ] Human on-device: open the sheet with Be a Lady and Prophet's Breath running and check that both lines show
