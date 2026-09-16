# 16 — Closer (S14)

**What to build:** The act's ending — all three threads converge, Hakim's
found ground gets seeded in-scene by Des, and the player is told, in so many
words, why the Collective keeps no list. Full detail in
`.scratch/collective-act1/spec.md` §6.15, §8.6 — read it before starting. Card
text is `PROSE-REVIEW:` draft; §14.3 flags card 10 as the act's hinge line.

**Blocked by:** 10, 12, 14.

**Status:** ready-for-agent

- [ ] `col_a1_closer` fires as a Hakim text once `colA1DesThreadDone`,
      `colA1NadiaThreadDone`, `colA1HakimThreadDone` are all set and
      `state.factions.collective.relation >= 25`.
- [ ] The site is created by the event (Whitechapel, tier `rich`,
      `oreType: life`) via `scripted_seed` regardless of Whitechapel's
      `siteCap` — document this exception (the cap governs prospecting
      discovery, not scripted creation).
- [ ] The seed always succeeds and never touches `state.player.orichalchum` —
      one atomic effect creates the site, creates the vein, and claims it.
- [ ] The "I'm in" / "Not yet" choice is the **only** path to
      `Factions.join("collective")` — the generic Join button is suppressed
      for the Collective everywhere else (`ContactCards.build_faction_card`).
      "Not yet" sets `colA1DeferredJoin` and leaves a permanent "Ask Des about
      joining" entry in Des's action bar that grants membership later via a
      short two-card event.
- [ ] `data/factions.json` `collective.joinRelation` changed 20→25 (§13
      amendment).
- [ ] `docs/VISION.md` §14 amended: the Collective is exempt from the
      join-locks-rivals-storylines rule, because it isn't a formal
      organisation (§13 amendment).
      `plans/COLLECTIVE-QUESTLINE.md` §8.1 marked resolved per spec.md §8.6,
      and §9 open questions 1 (names) and 2 (spine reward) marked closed —
      question 2 is closed by the cumulative +27 favour total across tickets
      08/10/12/14, verified end to end by this ticket's tests.
