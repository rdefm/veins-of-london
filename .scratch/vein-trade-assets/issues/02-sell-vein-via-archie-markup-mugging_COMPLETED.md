# 02 — Sell a vein through Archie's lane (markup + escalated mugging)

**What to build:** Wire Archie's Assets section (scaffolded but inert after
ticket 01) live. Selling a vein through Archie prices it at a markup over
the straight quote price used everywhere else — high enough that routing a
vein sale through Archie's cut-and-risk lane is a genuine alternative to the
safe, no-cut faction-direct sale, not strictly worse. Propose a specific
multiplier and flag it in your PR/report for human review rather than
treating any particular number as spec'd.

Archie's existing cut still applies to a vein's sale price, same as it does
for ore/items today.

Archie's existing mugging check still rolls on a trade that includes a vein,
but with two adjustments specific to that case: a lower base mugging chance
than the normal rate, and a harder mugger encounter (more and/or stronger
enemies) than the default encounter ore/item sales roll. Propose concrete
numbers for both and flag them for review — don't guess and bake them in as
if confirmed.

Mirror the existing behaviour ore/consumables already have in this lane
deliberately: goods leave the player's hands as part of executing the sale,
before the mugging outcome is known, and cash only lands if the fight is
won. Folding a vein into this same lane means the vein transfers away
immediately as part of the batched sale, and a lost mugging fight pays out
nothing for it — same shape the lane already has, just with a vein at
stake instead of ore. This is intended, not a gap — call it out explicitly
in your implementation notes so it doesn't read as an oversight in review.

**Blocked by:** 01 — needs the Assets section and cart-toggle plumbing it
builds.

**Status:** ready-for-agent

- [ ] Archie's Assets section lists player-owned veins as 0/1 toggle rows,
      same visibility gate as the faction lane's.
- [ ] A vein's sale price through Archie is quote price plus a proposed
      markup (documented, flagged for review), before his cut is applied.
- [ ] Archie's existing cut ratio applies to a vein's marked-up price the
      same way it applies to ore/item sale proceeds.
- [ ] A trade including a vein rolls a mugging chance lower than the normal
      base rate, against a harder-than-default mugger encounter — both
      values documented and flagged for review.
- [ ] The vein leaves the player's ownership as part of executing the sale,
      regardless of the mugging outcome; the cash payout is still
      contingent on winning the fight, matching ore/item behaviour.
- [ ] A trade with no vein selected behaves exactly as it did before this
      ticket — no regression to plain ore/item sales through Archie.
