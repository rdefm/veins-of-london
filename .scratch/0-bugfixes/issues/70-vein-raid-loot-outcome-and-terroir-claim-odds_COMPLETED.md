# 70 — Vein raiding: add a loot outcome + terroir-scaled takeover odds when a faction raids the player

**What to build:** When a faction successfully raids a player-owned vein, the outcome today is binary — full takeover or nothing. The player's own raiding of faction veins already distinguishes "claim" (full takeover) from "loot" (steal some ore, target keeps the vein) — bring that same distinction to raids against the player. Once a raid against the player is resolving, it should usually result in a loot outcome (the vein gets pruned and some of the player's orichalchum stolen, but the vein stays theirs); a full takeover should be the rarer outcome, and should become more likely the richer (higher terroir) the vein is — losing your best veins outright should be a real but occasional risk, not the default result of any successful raid.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A raid against a player vein that succeeds now rolls between two outcomes: **loot** (prune some vein growth + steal a quantity of the player's orichalchum, vein remains player-owned) and **claim** (full takeover, as today).
- [ ] Claim probability scales with the vein's terroir tier: proposed draft 5% at poor terroir up to 75% at saturated terroir, with fair/rich interpolated between (**needs balance sign-off** — draft only).
- [ ] Loot outcome's prune depth and ore-quantity stolen are defined as explicit constants recorded in `docs/REFERENCE.md` (**needs balance sign-off** — propose values in the same spirit as the player's own loot-a-faction-vein constant, e.g. a comparable flat ore quantity and a light-prune-equivalent depth).
- [ ] Notification/toast text distinguishes the two outcomes for the player (a loot notification reads differently from a takeover notification).
- [ ] `docs/REFERENCE.md` updated with the new outcome split and the terroir-claim-odds table as the source of truth.
- [ ] Test coverage: loot outcome leaves the vein with the player at reduced growth and reduced ore stash; claim outcome transfers ownership as before; claim frequency trends with terroir tier across repeated rolls.
- [ ] Manual check noted for the human: trigger raids against veins of different terroir tiers (e.g. via debug) and confirm loot is common, takeover is rare and rarer on poor-terroir veins.
