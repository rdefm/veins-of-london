# 28 — Stop pair relations running to −100; restore the warning → market → raid ladder

**What to build:** Two tuning fixes, both checked with the faction-economy sim.

1. **Pair runaway.** With rivalry on, faction–faction relations still fall to −100 within ~30 days (e.g. Firm–Guild, Guild–Conclave, Network–Conclave), and most pairs end Hostile. That happens even with halved pressure weights and a daily cap of 2. The main driver is relation hits from faction-vs-faction raids (vein and stockpile) on top of drift. Producer ore shares (40–73%) also run above the spec's 30–40% target, which inflates pair threat. Find the real driver in the sim output and fix it. Possible fixes include smaller relation hits from raids, recovery/decay toward the starting stance relation, or truce reset dynamics. Pairs should still sour and go to war, but they shouldn't all pin at −100. Stay within this feature's knobs. Don't retune sub-spec 2 shares unless the human OKs it.
2. **Escalation ladder.** Ticket 27 set warning below −18 and market below −30. Market below now sits at or above every raid threshold except the Collective's (−40). The Firm and Guild (−30) and the Network and Conclave (−20) therefore skip the market band, the range where a faction makes only market moves. They go from warning straight to the raid band. Re-pin the bands so every faction gives the player a warning period, then market moves while relation sinks further, and only then raids. The raid thresholds are human-confirmed except the Firm's, which was moved to −30 in 27. Any change to a raid threshold needs the human's OK, so prefer moving the escalation bands. The Firm feel target must still hold: a player at ~25% of physics with no contracts gets a warning in ~2 weeks and a first market move in ~3.

**Blocked by:** 27 — Tuning tool + pin placeholders (done).

**Relevant files:** `scripts/sim_faction_economy.gd` and `scripts/sim_faction_economy_impl.gd` (usage: `-- days=120 seed=N player=0 every=10`; `player=160 playerOre=physics` for the Firm target; rivalry is on by default). Also `data/constants.json` (`factionPressure`, `factionEscalation`, `factionWar`, `stockpileRaid.relationHit`, `factionStances`), `data/factions.json` (`raidThreshold`/`conquerThreshold`, `weariness`), and `systems/faction_ai.gd` (`band`, `_escalate`, `apply_pressure`, `note_hostile_act`, raid relation hits). Docs: `docs/REFERENCE.md` §1.8 "Raid/conquer eligibility thresholds", §1.11 "Faction stances", "Faction pressure", "Faction escalation", "Faction war", "Stockpile raid", and §3.1 "Pressure", "Escalation". Tests that hard-code bands and weights: `tests/test_faction_ai.gd`, `tests/test_faction_sim.gd`, `tests/test_network_intel_menu.gd`, `tests/fixtures/gamedata_pre_manifest_snapshot.gdvar`.

**Status:** ready-for-agent

- [ ] Sim, 120 days, seeds 1–6, rivalry on: no faction pair sits at −100 for long. Report the pair-relation timeline and the share of pairs that end Hostile.
- [ ] Every faction's bands are ordered warning > market > raid, so each one has a non-empty market band. If a raid threshold has to change, the human OKs it first.
- [ ] Firm feel target still met: warning ~day 14, first market move ~day 21, across seeds 1–4.
- [ ] Earlier targets still hold: wars end in truce more often than in collapse, and no faction reaches 0 veins in 120 days.
- [ ] REFERENCE.md and tests updated. Full suite and `check_all` are clean. Sim output is summarised in the report.
