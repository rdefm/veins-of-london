# Prologue act — "Rent Day"

Implements the Prologue in `docs/story-restructure.md` ("Prologue — Rent Day", "Motivation spine", "Design rules"). That doc is the design source; this file records the decisions made while ticketing it (2026-10-20). Engine dependencies are `.scratch/prologue-features/` 01–12, all landed.

## Decisions

- **Names.** Lieutenant: **Nick**. Gym owner: **Arnie**, real name **Reginald**, revealed later (not in the Prologue); he just thinks "Arnie" suits a gym owner.
- **Arnie.** Belly with muscle under it: he calls it a "dad bod", his waistline disagrees. His calc fighters' gym under a railway arch is **Flip Reverse**, named after the Blazing Squad song. He was a big fan in his youth and proudly recalls getting into a punch-up with some of the band. The "Flip" has fallen off the sign, so it reads "Reverse". He's ex-Firm and trained Nick as a teenager: **neither is hinted in the Prologue**; both are Act 1 reveals.
- **Guided spar (Prologue step 5):** a scripted fight whose Rewind lock and post-Rewind script are optional and which resumes the event on any outcome, plus a `practice: true` flag that applies spar rules (free unlimited Rewinds, no HP carried out, Combat XP + win bonus, move XP, no loot). It doesn't use a free spar session. Chosen over a scripted Spar because the step is event → spar → demo → event, and scripted fights already resume the event.
- **Ending (b):** the first Ticker article on emotion calc prices is a headline **and** a real, timed rise in emotion calc demand. Placeholder +20% for 7 days, TBC at the playtest pass. Archie mentions The Ticker articles and suggests the player keep an eye on it to see what's going on in the calc world.
- **Art:** placeholder sprites for Nick and Arnie for now (reuse existing enemy sprites). Storyboarding later via the `event-storyboard` skill.
- **Legacy saves:** no migration. The old `tut_*` chain is replaced outright.
- **Prose:** one ticket per beat. Every prose ticket follows `docs/writing-guide.md` and `docs/CONTENT-GUIDE.md`, runs the writing-guide audit, and flags new prose with `PROSE-REVIEW:`.
