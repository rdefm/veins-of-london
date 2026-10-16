# 10 — Active effects: Be A Lady in the world + indicator

**What to build:** Players can use items outside combat to start a timed effect, and can always see what they're under the influence of. Generic system; Be A Lady is the first wired effect.

- State: `state.player.activeEffects` — list of `{ item, level, expiresAtBlock }` (pure data; saves, loads, Rewinds).
- Duration by item level: lvl 1–2 = 1 time block, lvl 3–4 = 2, lvl 5 = 3. Values in data.
- Bag: "Use" button on Be A Lady outside combat (consumes one, starts/refreshes the effect).
- Be A Lady: the player's own cultivate gain and harvest yield always roll the max of their range. Staff/faction rolls unaffected. With Lady active, the cultivate/harvest preview shows the max only, tagged with Lady.
- Top bar: chip row of active effects (item icon); tap opens a sheet listing each effect + blocks left.
- Effects expire on block advance.

**Blocked by:** 09 — Harvest yield roll.

**Relevant files:** `autoload/GameState.gd`, `autoload/SaveManager.gd` (backfill), new `systems/active_effects.gd`, `scenes/components/bag_drawer.gd`, `systems/bag.gd`, `scenes/components/top_bar.gd`, `systems/cultivating.gd`, `systems/time_system.gd`, `scenes/components/item_icons.gd`, `scenes/components/vein_bubble.gd`, `data/constants.json`, `docs/REFERENCE.md` §2 STATE SCHEMA, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Use from Bag outside combat starts the effect with the correct duration for its level
- [ ] Cultivate and harvest roll max while Lady is active (player only)
- [ ] Chip row + sheet show effects and blocks left; they disappear on expiry
- [ ] Save/load and Rewind preserve effects; old saves backfill an empty list
- [ ] REFERENCE.md §2 and CODEMAP updated
- [ ] Tests: duration table, expiry, Lady max roll, save backfill
- [ ] PROSE-REVIEW: new UI strings flagged
