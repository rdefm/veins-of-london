# 08 — Combat menu: compact menu on the right, content panel on the left

**What to build:** Restructure the combat command area. The four main options (Fight, Dial, Item, Leg it) become a compact vertical menu on the right-hand side, each with icon and text, taking up a small part of the screen width. The larger left-hand space shows the selected section's contents (Fight moves, Dial, Items). Fight is selected and open by default, and the right-hand menu shows clearly which entry is selected. Tapping Leg it acts immediately on the player's turn and opens no panel. No animation in this ticket: sections swap instantly.

**Blocked by:** 07 — Combat: no text above the scene; narration goes in a bigger play-by-play.

**Relevant files:** `scenes/components/combat_command_dock.gd`, `scenes/components/dial_loadout_menu.gd`, `scenes/screens/combat_rounds.gd` (move/item rows, coach labels), `docs/ui-vision.md`.

**Status:** ready-for-agent

- [ ] The right-hand menu holds Fight, Dial, Item and Leg it with icon and text
- [ ] Fight is open on entry, and its menu entry shows as selected
- [ ] Tapping Dial or Item swaps the left panel and moves the selected marker
- [ ] Leg it queues/acts immediately, with no panel
- [ ] Coach-marked rows (▸) and disabled states still work inside the panels
- [ ] Screens still never mutate state; existing combat tests pass

On-device check: switch between all sections, use Leg it, and play the gym tutorial fight.
