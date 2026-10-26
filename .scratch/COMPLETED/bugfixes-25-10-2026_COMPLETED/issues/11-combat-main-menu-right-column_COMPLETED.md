# 11 — Combat main menu: compact right-hand column with icons and names

**What to build:** Fix the combat command area so it matches ticket 08's intent. The four main options (Fight, Item, Dial, Leg it) are a compact vertical column on the right-hand side, taking about a third of the screen width — not the whole screen. Each entry shows its icon and its name again. The left two-thirds shows the selected section's panel (Fight moves, Items, Dial). Today the main menu spans the full width and overlaps the section panel, so tapping a move (e.g. Strike) brings up the main menu over it and nothing can be selected; once the menu lives in its own right-hand column, taps on panel rows must select those rows.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/combat_command_dock.gd`, `scenes/components/icons.gd`, `scenes/components/dial_loadout_menu.gd`, `scenes/screens/combat_rounds.gd` (move/item rows), `tests/test_combat_command_dock.gd`, `data/combat_visuals.json` (panel animation durations), `docs/ui-vision.md`.

**Status:** ready-for-agent

- [ ] Main menu is a right-hand column ~33% of the width; the section panel fills the left ~67%
- [ ] Each main entry (Fight, Item, Dial, Leg it) shows its icon and name; the selected entry is clearly marked
- [ ] The main menu never overlaps the section panel
- [ ] Tapping a move/item/dial row selects it, without the main menu appearing over it
- [ ] Panel enter/exit animations (ticket 09) play within the left area only; rapid switching still leaves one panel showing
- [ ] Leg it still acts immediately with no panel
- [ ] Coach-marked rows (▸) and disabled states still work; screens never mutate state; existing combat tests pass

On-device check: open each section, pick Strike and confirm it queues, use an item, and play the gym tutorial fight.
