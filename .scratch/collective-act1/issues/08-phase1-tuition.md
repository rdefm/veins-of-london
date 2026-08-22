# 08 — Phase 1: Tuition (S1–S4)

**What to build:** The mandatory, linear opening — Archie hands the player to
Des, Des teaches prospecting and seeding (doubling as the game's only tutorial
for both), then hands out three parallel favours. Full detail in
`.scratch/collective-act1/spec.md` §6.1–§6.4, §4, §4.2 — read it before
starting. All card text in these events is `PROSE-REVIEW:` draft.

**Blocked by:** 02, 03, 04, 07.

**Status:** ready-for-agent

- [ ] S1 (`col_a1_intro`) fires the moment `flags.cultivationTutorialSeen`
      becomes true; `on_complete` unlocks contact `des`, sets
      `colA1DesMet`/`collectiveLaneUnlocked`, awards +3 collective relation,
      sets `colA1Stage "tuition"`.
- [ ] S2 (`col_a1_prospecting`) and S3 (`col_a1_seeding`) are map pins in
      Shoreditch, gated exactly per §6.2/§6.3 (S3's `minDay` = S2's day + 1);
      neither forces a prospect/seed action to actually complete — the tutorial
      teaches, it doesn't require.
- [ ] S4 (`col_a1_hub`) unlocks contacts `nadia` and `hakim`, activates all
      three §9.2 objectives (`col_a1_des_sites`, `col_a1_nadia_supply`,
      `col_a1_hakim_rescue`), sets `colA1Stage "hub"` and
      `colA1ArchiePryAvailable`.
- [ ] A player who completes S4 and does nothing further keeps the trading
      lane and the tutorial knowledge, and Collective relation never moves
      further — verified by a test.
- [ ] `sms_archie.gd` gets the minimal touch needed to surface S1's
      `pendingMessages` entry despite Archie's screen not otherwise migrating
      to the new Messages app — S1 is specced as an "Archie text
      (pendingMessages)" delivery (§6.1) even though §5.2 keeps Archie's
      conversation off the new app; flag to the human if this needs a design
      call rather than guessing.
- [ ] `docs/VISION.md` §13 amended: the Collective's selling lane unlocks
      pre-join in Act 1, not at M5 as currently documented (§13 amendment).
      `plans/COLLECTIVE-QUESTLINE.md` §5 marked superseded by spec.md §4/§6.
