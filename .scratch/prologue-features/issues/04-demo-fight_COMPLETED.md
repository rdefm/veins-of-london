# 04 — Scripted demo fight (NPC vs NPC, auto-resolve)

**What to build:** An event can play a watch-only fight between two named characters at set move levels, e.g. the gym owner (Feint L5) spars Archie for 1–2 rounds. The player sees autoguard turn a Strike into a chip, then a retaliate, in the normal stage and transcript. Then it returns to the event. Source: `docs/story-restructure.md` Prologue step 5, "Features to build" item 2.

**Blocked by:** 02 — Scripted fights.

**Relevant files:** `systems/combat.gd`, `systems/combat_rounds.gd` (Feint autoguard/retaliate), `systems/move_levels.gd`, `scenes/components/combat_director.gd`, `combat_transcript.gd`, `systems/events.gd`. REFERENCE §3.7b "Move levels", "Move-level effects".

**Status:** ready-for-agent

- [ ] Data sets the two fighters, their move levels and round count, plus optional forced outcomes so the showcased effect is guaranteed to fire.
- [ ] No player input is accepted, and no player XP, HP or items change.
- [ ] The showcased beats (autoguard, retaliate) appear in the transcript and the stage animation.
- [ ] Returns to the named event card. Test fixture asserts the beats fire.
