# 08a — Market insight `!` + Fate gut feeling

**What to build:** Replaces the spec's "tomorrow's market direction" (`.scratch/lenses/spec.md` "Fate: roll range", market part) with a gut-feeling read, plus a shared per-row insight slot that later sources (08c Prophet's Breath, anything added later) plug into.

- **Projection (shared, read-only):** per good, tomorrow's quote *if the player does nothing more today* — today's planned flow (`_plan_day` path: stock, Independents, nameless demand, recorded supply/demand including the player's trades already made today) → target → smoothed, clamped price, mirroring the reprice step (items before ores, ore derived demand from items' post-flow stocks). Never writes state. Known limitation, accepted: it can't see rollover steps before the reprice (Ticker tick, faction trades, auto-sell, Conclave moves), so it can miss.
- **Insight slot:** each market row has one `!` icon. Sources each return zero or more lines for a good, plus whether the good is "notable" (projected move ≥ 5% of today's quote, threshold in data). No source trumps another; tapping shows every source's lines together in a small bubble.
- **Icon states (this ticket):** grey and not tappable when no source has anything; bright red + pulsing when any source flags the good as notable. (Light red "Breath active" state lands in 08c.) Colours from `docs/ui-vision.md` palette, not hand-picked.
- **Fate source:** requires a loaded Fate Lens and Sense ≥ `senseGates.world` (2). Uses the same projection as Breath (just vaguer wording), only speaks on notable moves:
  - Goods the player holds (anything the player owns, anywhere): projected drop → "sell soon" feeling; projected rise → "hold onto it" feeling.
  - Goods the player doesn't hold: a feeling on the N with the biggest projected |move|, N by lens tier (placeholder `[0, 1, 1, 2, 2, 3]` in `data/dial.json`).
  - Direction only, never numbers. Silent if it turns out wrong (no next-morning callback).
  - Strings in data; PROSE-REVIEW.
- Accepted quirk: selling a held good can strengthen its own "sell soon" (your sale deepens the drop).

**Open question (ask before building UI):** which market screen(s) carry the `!` — Ticker app Stock Market list, Trade sheet rows, or both.

**Blocked by:** None — can start immediately (01 done).

**Relevant files:**
- `systems/market.gd` (`_plan_day`, `daily_reprice`, `target_price`, `derived_ore_demand`)
- `systems/lenses.gd` (`tier_for`, `sense_unlocked`)
- `systems/time_system.gd` (`daily_tick` step order, for the limitation note)
- `data/dial.json` (`senseGates`, lens effect strings), `data/market.json`
- `scenes/phone_apps/ticker_app.gd` (Stock Market rows), `scenes/modals/sell_menu_view.gd` (Trade rows), `scenes/components/price_move.gd`
- `tests/test_market.gd`, `tests/test_lenses.gd`
- `docs/ui-vision.md` (palette), `docs/CONTENT-GUIDE.md`
- REFERENCE §3.13 London market, §1.4 `data/dial.json` (Lenses)
- `.scratch/lenses/spec.md` (Fate row + "Fate — roll range")

**Status:** ready-for-agent

- [ ] Projection equals the next `daily_reprice()` result when no other rollover step trades (test over several days, items and ores).
- [ ] Projection reads state only (state deep-equal before/after).
- [ ] Fate lines hidden without a Fate Lens / below Sense 2; held-good sell/hold and N unowned reads by tier correct.
- [ ] `!` grey/untappable with nothing to say; pulsing when any source is notable (≥ 5%).
- [ ] Spec Fate row, REFERENCE §3.13/§1.4 and CODEMAP updated; syntax check clean, tests pass; strings flagged PROSE-REVIEW.
