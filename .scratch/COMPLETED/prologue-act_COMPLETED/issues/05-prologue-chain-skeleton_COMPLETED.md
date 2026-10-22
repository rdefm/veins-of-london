# 05 — Prologue chain skeleton

**What to build:** A new game plays through all 9 Prologue beats in the new order, using existing events where they exist and one-card placeholder events for the new beats, so the chain is playable end to end before prose lands. Each prose ticket (06–14) then fills one beat in place.

Order (`docs/story-restructure.md` Prologue):
1. Cold open (new event, from `intro` cards 1–10)
2. Pub (`intro` cards 11–16, as its own event)
3. First sale (`buyer`)
4. First craft (`james_meeting`)
5. Gym (new event; sets `gymUnlocked`)
6. Archie sells your pearls (new event)
7. Flat raid (`home_raid_intro` + debriefs)
8. First vein (`archie_cultivation`)
9. Pay rent + ending (new event, after the Monday bill is paid in full)

One ToDo objective per beat, each verifying its verb (Design rules). Objective titles are short UI strings: flag `PROSE-REVIEW:`. The rent goal row is on from beat 1 until beat 9. Retire `archie_craft_chat`, `tut_archie_partner` and the flags only they used; check the existing events' completion ops still make sense in the new order. Legacy saves: no migration. Fix or remove tests that pinned the old chain.

**Blocked by:** 02 — Rent goal row + rent-paid flag.

**Relevant files:** `data/objectives.json`, `data/events/intro.json`, `buyer.json`, `james_meeting.json`, `archie_craft_chat.json`, `home_raid_intro.json`, `home_raid_debrief_win.json`, `home_raid_debrief_loss.json`, `archie_cultivation.json`, `data/contact_texts.json`, `autoload/GameState.gd` (~L316 `tutorialStage`), `systems/time_system.gd` (~L334–350 stage triggers), `systems/events.gd` (`set_stage`), `systems/debug_start.gd`, tests touching `tut_*` / `metArchie` / `buyerEventSeen`. REFERENCE §2 (flags), §3.8, §3.9b. Update `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] New game runs headless through all 9 beats in order.
- [ ] ToDo shows exactly one current Prologue objective at a time.
- [ ] Retired events/objectives/flags gone from data and code; content lint clean.
- [ ] Full suite + `scripts/check_all.sh` pass.
