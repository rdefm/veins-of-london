# 12 — Losing or reclaiming a vein clears its harassment rows

**What to build:** When a vein changes hands (faction raid, forced loss, player reclaim), freeze / work-ban / other harassment rows and queued harassment messages keyed to that vein id are dropped, so a reclaimed vein can be cultivated again straight away. Diagnosis: ticket 10 `## Comments` §2 — best hypothesis, not confirmed on device; first confirm by checking whether the affected save has `harassment.active` rows on that vein, and stop and report if not.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/raiding.gd` (`transfer_player_vein_to_faction`, `claim_vein`), `systems/harassment.gd` (`tick`, `clear_where`, `vein_gate`, `_rows`), `systems/cultivating.gd` (`cultivate`), `systems/collective.gd` (`force_vein_loss`), `tests/test_raiding.gd`, `tests/test_harassment.gd`.

**Status:** ready-for-agent

- [ ] Test: freeze + workBan rows on a vein; faction raid claims it; player reclaims same day → `Cultivating.cultivate` returns ok, growth rises, `vein_cultivated` emitted
- [ ] Rows and queued/pending harassment messages for the vein id are gone after the transfer
- [ ] Rows on other veins untouched
- [ ] Hypothesis confirmed or refuted against the save; if refuted, report instead of fixing
