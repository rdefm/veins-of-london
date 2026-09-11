# 07 — T9: Checkpoint "it's working"

**What to build:** The Phase 1 → Phase 2 hinge scene — real numbers, Nadia
satisfied, Des not saying no. Full detail in `.scratch/collective-act2/spec.md`
§6.9 — read it before starting.

**Blocked by:** 06 (Nadia's three missions must exist and be completable).

**Status:** ready-for-agent

- [ ] `col_a2_checkpoint` fires once all three T8 missions
      (`col_a2_nadia_defend`, `col_a2_nadia_reseed`, `col_a2_nadia_supplies`)
      are complete, OR a day threshold passes since `colA2LedgerStarted` —
      whichever first (a player who completes two of three should still see
      this beat; do not gate on 100% completion alone).
- [ ] Cards per §6.9's beat outline (numbers stated plainly, Nadia satisfied,
      Des's "it's working" not "it's fine" line).
- [ ] `on_complete`: `colA2CheckpointSeen true`.
- [ ] Event id added to `GameData.EVENT_IDS`; `data/events/col_a2_checkpoint.json`.
- [ ] PROSE-REVIEW flag raised (Des's line, per §11.3's tone note).
