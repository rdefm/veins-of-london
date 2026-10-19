# 06 — Gym practice rack

**What to build:** Before a spar, the player can fill their loadout from the gym's **practice rack**: every loadout-allowlisted item at T1, free. Rack units only exist in the spar: they never enter the player's inventory, can't be stashed or sold, and vanish when the fight ends. This lets the player try every item and find a playstyle before crafting anything (the Arc B "find your playstyle" quest relies on it). Source: `docs/story-restructure.md` "Early Act 1 beats", "Features to build" item 3.

**Blocked by:** 05 — Gym location + Spar.

**Relevant files:** `systems/loadout.gd`, `systems/combat_prep.gd`, `scenes/screens/combat_prep.gd`, `systems/combat.gd` (exit). REFERENCE §3.7 "Player loadout".

**Status:** ready-for-agent

- [ ] The spar prep screen offers rack items alongside the player's own, clearly marked as practice.
- [ ] Rack units are used in the fight like normal T1 units, and neither the player's inventory nor their real loadout slots change before or after.
- [ ] The player's own equipped items are untouched by a spar that used rack items. Using their own items in a spar spends them as normal.
- [ ] Tests cover inventory/slots before = after for rack-only spars.
