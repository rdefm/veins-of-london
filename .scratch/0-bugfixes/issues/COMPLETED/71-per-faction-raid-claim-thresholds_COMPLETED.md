# 71 — Per-faction relation thresholds for raiding and conquering the player

**What to build:** Every faction should have its own relation thresholds governing (a) whether it will attempt a raid on the player's veins at all, and (b) whether it's willing to go for a full takeover rather than being limited to the loot outcome (from ticket 70). Confirmed for the Collective: no raid attempt of any kind (loot or claim) while relation is -30 or above; below -30, normal raid mechanics apply. The other four factions (Firm, Guild, Network, Conclave) need their own thresholds.

**Blocked by:** 70 (loot/claim outcome split must exist for "willing to conquer" to mean anything distinct from "willing to raid at all").

**Status:** ready-for-agent

- [ ] Collective: zero raid attempts (loot or claim) against the player while relation >= -30; normal raid mechanics (including ticket 70's terroir-scaled claim odds) apply below -30.
- [ ] Each of the other four factions has its own raid-eligibility relation threshold (below which they will attempt raids at all) and, optionally, a separate conquer-eligibility threshold (below which claim becomes possible, vs. being restricted to loot-only even if a raid lands) — **needs balance sign-off**, draft proposal below for the human to adjust:
  - Draft rationale: poorer, less established factions raid more readily (Collective's -30 is the most permissive); wealthier/more established factions (higher `resourceLevel`/`startingResources`) are more patient and need a more hostile relation before raiding at all.
  - Proposed draft raid thresholds: Firm -40, Network -40, Guild -45, Conclave -60 (Collective -30 confirmed). Conquer thresholds default to the same value as each faction's raid threshold (i.e. no extra gate beyond ticket 70's terroir odds) unless the human specifies otherwise.
- [ ] Thresholds are stored as data fields per faction (not hardcoded per-faction branches), consistent with this project's existing relation-threshold pattern.
- [ ] `docs/REFERENCE.md` updated with the per-faction threshold table.
- [ ] Test coverage: a faction below its raid threshold can attempt raids; at or above it, zero raid attempts occur across repeated rolls.
- [ ] Manual check noted for the human: review the draft threshold table and confirm/adjust before considering this ticket's numbers final.
