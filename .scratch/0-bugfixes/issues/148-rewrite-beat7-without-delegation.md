# 148 — Rewrite Beat 7 now that delegation is gone

**What to build:** A design decision (then data/prose changes) for Business Empire Act 1 Beat 7. Today Archie's `biz_a1_put_to_work` scene unlocks delegation (`bizA1DelegationUnlocked`), and the objective `biz_a1_put_to_work` (`recurring_proof`: 2 distinct contracts with a `qualified` settlement, ≥1 requesting a crafted item) counts only periods delegated the whole time and never player-assisted. Beat 8's closing payload quotes the first qualified periods. With delegation removed (ticket 147), the human decides what Beat 7 now teaches and proves (e.g. keep "unattended" = no player assist, or a different proof) and whether the scene's prose changes. Once decided, record it here and flip Status to ready-for-agent.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/business_quest.gd` (~L263-290 proof periods, Beat 8 payload), `systems/objectives.gd` (~L300 `recurring_proof`), `systems/contracts.gd` (`_period_qualifies`, `note_player_*`), `data/objectives.json` (`biz_a1_put_to_work`), the `biz_a1_put_to_work` / `biz_a1_closing` event data, `docs/biz-act1-vision.md`; REFERENCE.md §3.10 "Unattended proof", Beats 7-8.

**Status:** needs-info

- [ ] Human decides the new Beat 7 proof and scene intent
- [ ] Objective, qualification rule and Beat 8 payload updated to match; tested
- [ ] PROSE-REVIEW: rewritten scene text
