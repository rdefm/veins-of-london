# 09 — Combat menu panel animations

**What to build:** Animate the left-hand section panels from ticket 08 when the player switches sections. Fight slides in from the left when selected and back out to the left when another section is chosen. Items swipe in from the top and out the top. Dial pops up from the bottom and drops back down. Switching sections plays the outgoing panel's exit and the incoming panel's entry, and a fast double-tap must not leave two panels showing.

**Blocked by:** 08 — Combat menu: compact menu on the right, content panel on the left.

**Relevant files:** `scenes/components/combat_command_dock.gd`, `scenes/components/dial_loadout_menu.gd`, `scenes/screens/combat_rounds.gd`, `data/combat_visuals.json` (durations belong in data, not code).

**Status:** ready-for-agent

- [ ] Fight enters and exits on the left, Items at the top, Dial at the bottom
- [ ] Rapid switching settles on the last-tapped section with only its panel visible
- [ ] Animation durations come from data
- [ ] Inputs aren't accepted on a panel mid-exit

On-device check: switch quickly between all three sections and confirm each direction.
