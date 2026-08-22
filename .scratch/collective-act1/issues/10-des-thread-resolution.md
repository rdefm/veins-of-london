# 10 — Des's thread resolution (S7)

**What to build:** Reporting the found ground back to Des, who quietly seeds
both patches for named-but-unidentified Collective members — the scene Arc 3
later re-reads as confession. Full detail in `.scratch/collective-act1/spec.md`
§6.7 and §6.14 (Des's "ages ago" line, inserted here) — read it before
starting. Card text is `PROSE-REVIEW:` draft; §14.3 flags card 4 and Des's
overall characterisation as the highest-stakes prose in the act.

**Blocked by:** 09.

**Status:** ready-for-agent

- [ ] `col_a1_des_report` is enabled on Des's action bar by
      `colA1DesSitesFound`; `on_complete` seeds both reported sites via
      `faction_seed_reported_sites` (owner `collective`, `VEIN_GROWTH.
      seedGrowth`), queues their map events, awards +8 collective relation,
      sets `colA1DesThreadDone`.
- [ ] Des's "ages ago" line (§6.14) is inserted between cards 2 and 3 of this
      event, worded so it never lands in the same scene as the keyring (S1,
      already shipped in ticket 08) or the debt reveal (ticket 15's S13) per
      §4.7 — coordinate placement with whoever picks up ticket 15.
- [ ] Card 4 ("Nobody's ever raided a vein they didn't know about") is
      delivered as a light joke about paperwork, never underlined as a thesis
      statement, per §14.3.
