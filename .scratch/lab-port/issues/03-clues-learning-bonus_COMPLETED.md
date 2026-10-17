# 03 — Clues, learning, re-run bonus and bad-run lines

**What to build:** After Finish, every performed step gets a clue (✓ in band, ~ with a direction, ✗ no effect, "something changed"). An off-book step matching a hidden step becomes a vague hint; three in-band hits on a vague step make it exact — identical to hints from story or debug. A run at or above the best rank rolls a re-run bonus (one of +1 item, half calc refunded, XP ×1.5, picked at random). A really bad run sometimes returns a dry flavour line. Spec: `.scratch/lab-port/spec.md` § Run rules, user stories 17–18, 23–26.

**Blocked by:** 02

**Relevant files:**
- `systems/bench_prototype.gd` (source: `notebook_clues`, `hidden_ideal_steps`, `_book_matches_kept`, `_direction`, `_hint_for_step`, `_learn`, bonus + bad-run handling in `finish_run`)
- `data/bench_prototype.json` (`clueText`, `bonus`, `badRun`, `vagueToExactHits`)
- `systems/lab.gd`, `data/lab.json`, `tests/test_lab.gd`

**Status:** ready-for-agent

- [ ] All four clue kinds produced and tested
- [ ] Off-book match on a hidden step → vague, stored in `lab.known` exactly like a granted vague step
- [ ] Three in-band hits on a vague step → exact (`vagueHits` tracked)
- [ ] Bonus rolls only when rank ≥ best rank, chance from data (30%); all three types reachable with seeded RNG
- [ ] XP multiplier applies to the finished run's XP
- [ ] Bad-run flavour lines in data; flag `PROSE-REVIEW:` for any new lines/direction words
