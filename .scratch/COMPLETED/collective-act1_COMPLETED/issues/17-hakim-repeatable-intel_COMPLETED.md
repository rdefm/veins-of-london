# 17 — Hakim's repeatable intel

**What to build:** Hakim occasionally, unprompted, texting the player a free
lead on unclaimed ground — the gift the Arc 2 handler later replaces with an
invoice. Full detail in `.scratch/collective-act1/spec.md` §5.8, §6.16 — read
it before starting. Card text is `PROSE-REVIEW:` draft.

**Blocked by:** 14, 03.

**Status:** ready-for-agent

- [ ] Daily-tick roll: 15% chance, minimum 3 days since the last text
      (`state.collective.hakimIntelLastDay`); suppressed if both Shoreditch
      and Whitechapel are at `siteCap` (7 each).
- [ ] Creates an unclaimed site in Shoreditch or Whitechapel at tier `fair` or
      better, then pushes a `pendingMessages` entry (`col_hakim_intel`)
      carrying its `siteId`.
- [ ] Free every time — no cash cost, no favour, no cooldown purchase; no raid
      tips (held for Arc 2).
- [ ] `on_complete` reveals the already-created site, clears the pending
      message, updates `state.collective.hakimIntelLastDay`.
