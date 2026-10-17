# 07 — `james_experiment` event (replaces `james_motion`)

**What to build:** Archie's motion beat now leads to James's rewritten event, `james_experiment`.
- Opening: the current assistant/overflow exchange, trimmed (no free Enhancement Powder).
- Lesson: James says your pearls are mediocre and explains ranks. He gives one vague Time Pearl Hint I, then opens the lesson session (06) on his calc, with the goal of a timePearl manual run at rank ≥ 3. Escalation lines come at 3 and 6 fails.
- On success: you ask about other recipes. He says he only knows time and life calc and will sell those; he'll write to a Guild contact about the rest; practise. He hints that he wants you good enough for something of his (the Dial's Movement), without explaining it.
- At the end: James's recipe shop unlocks.

**Variant:** if the player already owns timePearl Hint I, the event plays the same (the lesson still runs), but James's lines change: he doesn't believe you know it already and wants to see it done before trusting you with overflow work.

Renames: the pending-message kind and every reference to it; `jamesMotionEventSeen` → `jamesExperimentSeen`. `enhancementUnlocked` is removed everywhere; James's overflow jobs unlock when the player knows Enhancement Powder.

Spec: `.scratch/recipe-acquisition/spec.md` § Implementation Decisions — "Event rename and rewrite", "Seller unlock flags"; § User Stories 1–17, 65–66.

**Blocked by:** 02 — Sellers, gates, prices and buying knowledge; 06 — Locked lesson bench session.

**Relevant files:**
- `data/events/james_motion.json` → `data/events/james_experiment.json` (prose quarry for trimmed lines)
- `data/events/archie_motion.json` (l.15 `queue_pending_message` kind)
- `autoload/GameState.gd` (flags ~l.344), `autoload/SaveManager.gd`
- `systems/jobs.gd` (l.33 `enhancementUnlocked`, l.74 flag gate), `systems/archie_deals.gd` (l.41)
- `scenes/components/contact_cards.gd` (l.348)
- `docs/CONTENT-GUIDE.md`, `docs/writing-guide.md`, `docs/REFERENCE.md` (flags §), `docs/M0-PORT.md`
- tests: `test_events.gd`, `test_jobs.gd`, `test_playthrough.gd`, `test_rooms.gd`, `test_savemanager.gd`, `test_time_system.gd`, `test_contact_cards.gd`
- `CODEMAP.md` (event + data rows)

**Status:** ready-for-agent

- [ ] Archie's motion event queues the renamed James pending message, which plays `james_experiment`.
- [ ] Event grants timePearl Hint I vague, runs the lesson session with goal rank 3, and resumes on success into the recipe conversation.
- [ ] Owns-Hint-I variant plays the disbelieving lines; the flow is otherwise identical.
- [ ] Event sets `jamesExperimentSeen` and James's seller unlock flag. No `jamesMotion*` or `enhancementUnlocked` left in code, data or tests (grep clean, excluding `.scratch/` history).
- [ ] Jobs gate on knowing `enhancementPowder`; jobs tests updated.
- [ ] Content lint passes. James stays grudging and dry, never warm.
- [ ] PROSE-REVIEW: every line beyond the trimmed existing exchange.
- [ ] On-device QA block in report.
