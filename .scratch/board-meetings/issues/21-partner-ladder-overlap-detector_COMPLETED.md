# 21 — Partner ladder + overlap detector + rival-move / Partner beats

**What to build:** one **overlap detector** (veins in a faction's district, crafting what they produce, producing what they consume, share approaching provocation) that feeds the **Partner** ladder: spot a real synergy with a faction and ask the player to raise the relationship. Also the unordered Act 2 beats that land here: the rival's first visible move (arrives live as a text explaining relation levers once the player passes the share threshold — never a Monday item) and reaching Partner stance. Detector thresholds settled in this slice.

**Blocked by:** 06 — Market share ladder (Archie) + pinned Act 2 share beat; slice 1 (01–14) playtested and tuned

**Relevant files:**
- `systems/factions.gd`, `systems/faction_ai.gd`, `systems/partners.gd`, `systems/diplomacy.gd`, `systems/warmonger.gd`, `systems/shares.gd`
- `systems/contact_texts.gd`, `systems/messages.gd` (live text)
- `systems/objectives.gd` (relation/stance condition), `systems/board_meetings.gd`, `data/board.json`
- `.scratch/biz-empire-act2/spec.md` (systems stories)
- Spec: stories 56, 58, 65–66, §"Act 2 spine rules"

**Status:** needs-triage

- [ ] Detector returns overlaps from real state; tests per overlap kind
- [ ] Partner card premise true; stance condition tests
- [ ] Rival first move fires live once; spine beats complete in any order
