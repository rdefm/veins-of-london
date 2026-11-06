# 18 — Déjà Vu (implement `reveal` item effect)

**What to build:** A new item-effect kind, `reveal`. Toggling Déjà Vu on a choice card shows the roll every check option on that card will get before commit. Revealed rolls are stored as pure data in the event run state.

**Decided (17):**
- **Scope/cap:** one use reveals the rolls for ALL check options on the current card. One unit consumed per card; stock is the only other cap. Multi-card events can reveal again on a later card with another unit.
- **Live reveal:** the shown roll is `check_roll(i)` for the option's *current* loadout, always equal to the committed roll. The reveal flag must NOT be part of `active_toggles()` / the roll hash key.
- **Loadout changes:** if the player toggles another item on/off for an option and that changes its roll, the displayed roll updates with a "pulse" animation (UI only). No lock, no spend; reveal stays on for the card.
- **Rewind:** a Rewind clears `state.event.revealed` (while `rolled` is kept, per existing rule). Post-Rewind rolls are best-of-two (`check_roll` min of two draws); the player must spend another Déjà Vu to see the new roll. A reveal always shows the final (min) roll.
- **Save/reload:** `revealed` is pure data (`{ "<cardIndex>": true }`), saved; the shown roll is recomputed from `check_roll`, never stored, so reload replays the same value.

**Blocked by:** 17 (done)

**Relevant files:** `systems/events.gd` (`check_roll`, `active_toggles`, `rewind`), `systems/event_items.gd`, `systems/rewind.gd`, `scenes/screens/event.gd`, `tests/test_event_items.gd`; REFERENCE §3.9a.

**Status:** ready-for-agent

- [ ] The revealed roll equals the committed roll for every check option on the card; reveal flag not in the roll hash
- [ ] Toggling another item changes the displayed roll to match the new committed roll (screen pulses it)
- [ ] One unit consumed per card; Rewind clears `revealed`; save/reload keeps it
- [ ] REFERENCE §3.9a documents `reveal`
