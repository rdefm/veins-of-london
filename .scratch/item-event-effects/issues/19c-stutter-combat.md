# 19c — Stutter in combat (player + ally)

**What to build:** A new time+physics item, Stutter (extremely short-range teleport: you're suddenly behind them), exists and works in round combat for the player and their allies.

- **Item row** (all numbers placeholders until playtest):
  - id `stutter`, ingredients `{time: 5, physics: 5}`, symbol ⌁, baseSuccess 0.20, xpReward 40, effectPower `[0,15,20,25,30,40]` (crit bonus %).
  - eventUsable, shown in the Bag when held, shared placeholder icon (art via ticket 29).
  - Description: PROSE-REVIEW.
  - Price £240 (xp × 6).
- **Effect:** one action. The user Strikes a chosen enemy from behind: the Strike ignores the target's Guard (full damage, no chip), and the user's crit chance gains +X% by tier. Then, for the rest of the current round, the user has guaranteed evasion: any Strike, Stun or single-target item aimed at them misses. `allEnemies` effects still land. Evasion ends at round end.
- **Availability:** player loadout, Dial Complication, ally loadouts (ally item use). Not the guard kit.
- **Animation:**
  1. The user blinks out of existence.
  2. They blink in behind the target.
  3. The strike animation plays.
  4. They blink back to their original slot.
  - Timings in data, halved under quick pacing. Reduced motion: instant cuts, no blink fades.
  - Allies use the same animation.
- Evasion state is pure data; Rewind and save carry it.

**Blocked by:** None — can start immediately. It shares files with 19b, so do it after 19b to avoid conflicts. If 19b has landed, reuse its "aimed-at-holder misses, area still hits" check rather than writing a second one.

**Relevant files:**
- Data: `data/recipes.json`, `data/combat_rounds.json` (`items`, tooltips, coach hints, beat lines, `moveFx.strike` for crit), `data/combat_visuals.json`, `data/constants.json`.
- Systems: `systems/combat_rounds.gd` (Strike resolution incl. guard/chip and crit around `crit_chance`, `evade_chance`, ally item rules), `systems/combat.gd` (`COMBAT_COMPLICATION_RECIPES`), `systems/loadout.gd`, `systems/dial.gd`, `systems/bag.gd`.
- Scenes: `scenes/components/combat_stage.gd`, `scenes/screens/combat_rounds.gd`.
- Tests: `tests/test_combat_rounds.gd`, `tests/test_combat_stage.gd`, `tests/test_loadout.gd`.
- Docs: `CODEMAP.md`; REFERENCE §1.3, §3.7b Open/Guarded round combat (Damage, Evade).

**Status:** ready-for-agent

- [ ] `stutter` loads at boot with recipe row, £240 price, description, placeholder icon; grantable via debug
- [ ] Tested through the combat public API at a low and a high tier: the Stutter Strike ignores Guard and carries the tier's crit bonus
- [ ] For the rest of that round, Strike/Stun/single-target items on the user miss; area effects still hit; the next round they land again
- [ ] Ally AI can use it from its loadout; not in the guard-kit allowlist
- [ ] Blink-out → blink-behind → strike → blink-back plays for player and allies; reduced-motion path is instant cuts
- [ ] Rewind restores pre-use state and refunds the item
- [ ] New strings flagged PROSE-REVIEW; numbers tagged for balance; REFERENCE §1.3/§3.7b and CODEMAP updated
- [ ] Human on-device check: blink sequence reads clearly at normal and quick pacing
