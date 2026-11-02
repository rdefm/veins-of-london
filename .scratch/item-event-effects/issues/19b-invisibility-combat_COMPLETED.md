# 19b — Invisibility in combat (player + ally)

**What to build:** A new physics item, Invisibility ("does what it says on the tin", a spray bottle), exists and works in round combat for the player and their allies.

- **Item row** (all numbers placeholders until playtest):
  - id `invisibility`, ingredients `{physics: 6}`, symbol ◌, baseSuccess 0.30, xpReward 30, effectPower `[0,1,1,2,2,3]` (rounds active).
  - eventUsable, shown in the Bag when held, shared placeholder icon (real art comes with ticket 29).
  - Description: PROSE-REVIEW.
  - Consumable price £250. That breaks the xp × 6 rule (£180), so document it as a price exception the way Rejuvenation is.
- **Effect:** sprayed on self or a friendly combatant. For N rounds (by tier), any Strike, Stun or single-target item aimed at the holder misses. `allEnemies` effects (Black Hole, Time Pearl, Heavy Metal and any future area item) still land. Attacking doesn't break it.
- **Enemy targeting:** an enemy whose planned target is invisible switches to a visible target when one exists. If none exists (player alone), it swings and misses, using the existing evade beat.
- **Availability:** player loadout, Dial Complication, ally loadouts (ally item use), guard kit.
- **Visuals:**
  - A status icon on the holder.
  - The holder's sprite drops to partial transparency (alpha ~0.35, value in data) while the status runs, and fades back when it ends.
  - Reduced motion: instant alpha change, no fade.
- Rewind and save carry the status as pure data, like every other combat status.

**Blocked by:** None — can start immediately.

**Relevant files:**
- Data: `data/recipes.json` (recipe + `CONSUMABLE_PRICES`), `data/combat_rounds.json` (`items`, tooltips, coach hints, beat lines), `data/combat_visuals.json` (`statusIcons`, stage fx), `data/constants.json` (loadout/guardKit allowlists).
- Systems: `systems/combat_rounds.gd` (item table, `evade_chance`, `_pick_target`, ally item rules), `systems/combat.gd` (`COMBAT_COMPLICATION_RECIPES`), `systems/loadout.gd`, `systems/guard_kit.gd`, `systems/dial.gd`, `systems/bag.gd`.
- Scenes: `scenes/components/combat_stage.gd`, `scenes/screens/combat_rounds.gd`.
- Tests: `tests/test_combat_rounds.gd`, `tests/test_combat_stage.gd`, `tests/test_loadout.gd`, `tests/test_guard_kit.gd`.
- Docs: `CODEMAP.md`; REFERENCE §1.3 `data/recipes.json`, §3.7b Open/Guarded round combat.

**Status:** ready-for-agent

- [ ] `invisibility` loads at boot with recipe row, £250 price (documented exception), description, placeholder icon; grantable via debug
- [ ] Tested through the combat public API at a low and a high tier: Strike/Stun/single-target item on the holder miss for N rounds, then land again
- [ ] Black Hole / Time Pearl / Heavy Metal still hit an invisible holder
- [ ] Enemies retarget to a visible friendly; a solo invisible player sees swing-and-miss beats
- [ ] Usable on an ally; ally AI can use it from its loadout
- [ ] Present in loadout, Dial and guard-kit allowlists
- [ ] Status icon + translucent sprite shown while active; reduced-motion path is instant
- [ ] Rewind restores pre-use state and refunds the item
- [ ] New strings flagged PROSE-REVIEW; numbers tagged for balance; REFERENCE §1.3/§3.7b and CODEMAP updated
- [ ] Human on-device check: sprite transparency, fade back, status icon
