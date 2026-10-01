# 21 — Partners

**What to build:** Partner stance pays both ways. The player can ask a partner for a better price at a relation cost. A partner in trouble (low holdings or cash) asks the player for a discount, and accepting raises relation. At very high relation (≥ +80) the partner warns of another faction's planned move against the player, but only when the partner's own relation with the aggressor is at least the Neutral band; the warning explains how it knows. The partner also occasionally sends help into a vein defence through the existing ally path, and leaks intel. Factions that are Partners do the same for each other.

**Blocked by:** 04 — Escalation framework + raid rung; 14 — Intel meters.

**Relevant files:** `systems/faction_ai.gd`, `systems/faction_sim.gd` / shop pricing, `systems/raiding.gd` (`begin_raid` `ally_ids`), `systems/intel.gd`, pending-message mechanism, `scenes/phone_apps/factions_app.gd`, `tests/test_faction_ai.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 76–81, §Partners. REFERENCE.md §3.6a.

**Status:** ready-for-agent

- [ ] Test: a player price-favour ask discounts the partner's shop price and costs relation.
- [ ] Rollover test: a partner in trouble sends an actionable discount request, and accepting raises relation.
- [ ] Rollover test: a partner warning fires only with ≥ +80 player relation AND partner→aggressor relation ≥ Neutral band.
- [ ] Test (seeded): defence help adds the partner to a vein-defence fight.
- [ ] Partner factions help each other in faction raids. REFERENCE and CODEMAP updated. `PROSE-REVIEW:` for partner lines.
