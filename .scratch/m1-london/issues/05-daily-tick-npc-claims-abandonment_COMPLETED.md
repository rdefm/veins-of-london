# 05 — Daily-tick integration: NPC claims, NPC abandonment, King's Cross recharge

**What to build:** daily-tick step ⑤b (NPC site-claiming, per D2's formula) and the new step ⑤c (NPC abandonment — per `docs/adr/0002`, deletes the site outright on hit, freeing a `siteCap` slot; does NOT revert to unclaimed). King's Cross's `rechargeBlocks −1 (min 1)` special, stacking correctly with the "recharge" hospitability bonus.

**Blocked by:** 02 (needs sites to exist and the claim-state fields).

**Status:** ready-for-agent

- [ ] Step ⑤b: `p = 0.03 + 0.02×tierIndex + 0.01×ageDays`, cap 0.25, barren never claimed; sets `npcClaimed=true`, `npcClaimedDay=day`, fires the notification
- [ ] Step ⑤c runs immediately after ⑤b: `p = 0.05 + 0.01×ageDaysSinceNpcClaim`, cap 0.15, flat across tiers; on hit, deletes the site object entirely (not a state revert) and fires the notification
- [ ] King's Cross recharge special applies correctly and stacks (additively, both −1, min 1 overall) with a vein's "recharge" hospitability bonus
- [ ] Tests: NPC-claim curve (probability at various tier/age combos, cap enforcement), NPC-abandonment curve (same), a soak-style test confirming a maxed-out district's `siteCap` never permanently locks out prospecting over N simulated days
- [ ] `godot --headless --check-only --script` clean on all touched files
