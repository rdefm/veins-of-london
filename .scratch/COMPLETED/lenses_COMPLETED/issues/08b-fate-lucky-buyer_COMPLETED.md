# 08b — Fate lucky buyer

**What to build:** A loaded Fate Lens nudges the player's own trades. With a Fate Lens and Sense ≥ `senseGates.world` (2), every player-initiated sale **or** buy with a contact or marketplace (Soho, Archie, faction shops/contacts) rolls once per trade (not per unit). On a hit the trade gets a flat better price: sale +5%, buy −5% (placeholder, in `data/dial.json`).

- Hit chance by lens tier, placeholder `[0, 0.05, 0.08, 0.11, 0.14, 0.18]`; the Fate all-rolls bonus (`fate_all_rolls_bonus`) stacks onto it before the clamp.
- Excluded: contracts (fixed price), auto-sell (staff, not the player's Dial).
- Accepted: two hits on a buy-then-sell-back at Soho's top rung net ~1% — rare and tiny.
- Feedback: one line on the post-sale/review modal, e.g. "They gave you a better price as they were in a rush - must be your lucky day!" Strings in data; PROSE-REVIEW.
- Roll uses the game's normal roll path so it's deterministic under tests and Rewind-safe (no state purity breaks).

**Blocked by:** None — can start immediately (01, 05 done).

**Relevant files:**
- `systems/soho.gd` (`trade`, `fee_rows`)
- `systems/economy.gd` (`sell_from_sell_state`, `sell_to_faction_from_sell_state`, faction buy lanes)
- `systems/lenses.gd` (`tier_for`, `sense_unlocked`, `fate_all_rolls_bonus`)
- `data/dial.json`
- `scenes/modals/sell_menu_view.gd` (review / result)
- `tests/test_soho.gd`, `tests/test_economy.gd`, `tests/test_lenses.gd`
- `docs/CONTENT-GUIDE.md`
- REFERENCE §3.13 London market, §1.4 `data/dial.json` (Lenses)
- `.scratch/lenses/spec.md` (Fate row)

**Status:** ready-for-agent

- [ ] Hit adds 5% to a sale's / removes 5% from a buy's £ total, on every covered lane; miss leaves it unchanged.
- [ ] No roll without a Fate Lens, below Sense 2, on contracts or auto-sell.
- [ ] Chance follows tier curve + all-rolls bonus (forced-roll tests both sides of the threshold).
- [ ] Lucky line shows on the result only on a hit.
- [ ] Spec, REFERENCE §3.13/§1.4, CODEMAP updated; syntax check clean, tests pass; strings flagged PROSE-REVIEW.
