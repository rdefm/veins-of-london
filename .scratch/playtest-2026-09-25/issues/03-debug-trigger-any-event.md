# 03 — Debug: trigger any event

**What to build:** A debug tool, available only in a Debug Start game, that lists every event and fires the chosen one immediately. Before firing, it sets up whatever that event needs to run coherently (required flags, veins/sites, contacts, context values), so the event plays out and its effects apply without errors.

**Blocked by:** 02 — Diagnose + fix: collective quests don't fire after debug start.

**Relevant files:** `scenes/phone_apps/debug_app.gd`, `systems/debug_tools.gd`, `systems/debug_start.gd`, `systems/events.gd` (`start_event`, `start_or_defer`), `systems/collective.gd` (trigger preconditions), `data/events/`, `autoload/GameData.gd`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Tool visible only in a Debug Start game
- [ ] Picker lists all events from `data/events/`
- [ ] Firing an event first applies its required setup, then starts it
- [ ] Setup logic lives in a system, not the screen
- [ ] Test: every event can be fired from a Debug Start state without errors
