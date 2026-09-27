# 95 — Archie: proactive "tag along to a deal" offers

**What to build:** Archie occasionally reaches out asking the player to tag along to a sale he's already organised — a deal that doesn't touch the player's own ore/inventory, just a chance to earn a cut and share the risk. Same shape as ticket #30 (James's proactive job offers): a daily-tick roll producing an accept/decline offer on Archie's contact card, chance scaling inversely with the player's cash.

**Confirmed mechanics (from 2026-08-28 grill-me session — no open design questions, only balance numbers to sign off):**

- **Trigger:** daily-tick roll (mirroring `systems/time_system.gd`'s existing daily rolls, same as ticket #30's James-job roll), only when no Archie-deal offer is currently pending or in-progress.
- **Chance curve:** `chance = lerp(1.0, 0.10, clamp(cash / 5000, 0, 1))` — 100% at cash ≤£100, falling linearly to a 10% floor at cash ≥£5000. **Needs balance sign-off** — propose these exact numbers for human review, adjust if they feel off in play.
- **Deal size:** `tier = floor(cash / 5000)`; ore quantity range = `5 * 2^tier` to `25 * 2^tier`. **Needs balance sign-off** — this grows unbounded at high cash; propose a sanity cap (e.g. a max tier) for human review rather than shipping uncapped.
- **Ore type:** one of the 5 canonical ore types (`time`, `physics`, `life`, `fate`, `emotion`), picked at random per deal.
- **Pricing:** standard market formula — `GameData.ORE_TYPES[type].basePrice × Barometer.get_effective_ore_price() × (1 + district priceMod)` — same as any other ore sale. No player ore or cash is deducted for the deal itself; this is Archie's own stock, simulated purely to compute the gross.
- **Offer UI:** accept/decline choice surfaced on Archie's contact card, using the existing pending-message pattern (`systems/messages.gd`'s `queue_pending`, same shape as `archie_motion` and other Archie SMS beats).
- **Accept + win (no mugging, or mugging resolved in the player's favour):** flat 50/50 split of gross between Archie and player — deliberately *not* the relation-scaled `get_archie_cut_ratio()` used for the player's own ore, since this is Archie's deal, not the player's stock. +2 Archie relation (same as `ARCHIE_SALE_RELATION_GAIN`).
- **Decline:** −2 Archie relation.
- **Combat:** the same mugging roll/formula as a normal Archie sale (`MUG_BASE_CHANCE` 0.20 + district `dangerMod`, via `Barometer.get_effective_mug_chance()`). Archie always joins as a combat ally in this fight regardless of the normal recruited/kitted/KO-cooldown gate — same always-ally mechanism ticket #68 built for regular Archie-sale muggings, with an even stronger justification here since it's explicitly his own deal.
- **Loss:** both parties get £0 (no payout), no further penalty — no relation hit, nothing else lost, since no player ore/cash was ever staked beyond the missed payout. Deliberately distinct from a normal Archie-sale mugging loss, where the player's own goods were already deducted before the roll.

**Where:** `systems/time_system.gd` (daily roll, alongside the existing James-job roll — ticket #30), `systems/economy.gd` (`MUG_BASE_CHANCE`, `get_archie_cut_ratio()` for contrast, `ARCHIE_SALE_RELATION_GAIN`), `systems/combat.gd` (`start_mugging`, ticket #68's always-ally mechanism, `_dispatch_on_win`), `scenes/components/contact_cards.gd` (Archie's card, pending-message button pattern), `systems/messages.gd` (`queue_pending`).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Daily tick rolls for an Archie-deal offer using the confirmed chance curve, only when none is currently pending/in-progress.
- [ ] Offer surfaces on Archie's contact card as an accept/decline choice, using the existing pending-message UI pattern.
- [ ] Accepting rolls a random ore type and a quantity in the confirmed tier-scaled range, computes gross via the standard market pricing formula, and rolls the standard Archie-sale mugging chance.
- [ ] No player ore or cash is touched by the deal itself (only by its resolution — split or nothing).
- [ ] On no mugging (or a won mugging): 50/50 flat split paid out, +2 Archie relation.
- [ ] On a lost mugging: £0 paid to either party, no relation change beyond what accepting the offer itself did.
- [ ] Archie always fights as a combat ally in this mugging, regardless of the normal recruited/kitted/KO-cooldown gate.
- [ ] Declining the offer applies −2 Archie relation.
- [ ] Test coverage: chance-curve scaling at a few cash points, deal-size tier scaling at a few cash points, accept/decline relation deltas, win/loss payout math, Archie present as ally even when the normal gate would exclude him, no player ore/cash touched on offer/decline.
- [ ] Manual check noted for the human: trigger an offer at low cash (near-certain chance) and at high cash (near-floor chance) and confirm both the offer frequency and deal size feel right; play through an accept-and-win and an accept-and-lose to confirm payouts and relation match spec.
