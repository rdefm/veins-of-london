# 02 — Security Office room, hire board, Guards tab

**What to build:** The player can buy a **Security Office** (`securityOffice`) room at townhouse or above (£2,500, uses a room slot, one optional officer seat, no seat upgrades). Owning it makes `Muscle.can_manage()` true and adds a Security Office tile in HQ that opens a new **Security** screen. This ticket ships the screen's **Guards** tab: a person-centric list (short name, level, wage, traits, post), a guard detail sheet (full name, level, XP and next threshold, wage, traits with tap-to-explain, Dismiss with confirm), and a **Hire** sheet showing the weekly board.

Board: 4 cards, rolled every Monday; each card rolls its level independently from fixed odds (no L5; HQ tier irrelevant); 10% of cards are a former guard (if any) returning as they left with injuries cleared and tagged "Worked for you before". A hired card's slot stays empty until the next Monday roll — no re-roll, no quick-hire. Hiring pays that guard's prorated advance and puts them in Reserve. Dismiss is immediate, no severance or refund, allowed while injured, and moves the guard to former (cap 20, oldest dropped). The Monday wage bill becomes the sum of each guard's own wage (Reserve guards paid). Posting is not in this ticket — hired guards sit in Reserve.

Buying the room sets the intro-event trigger flag (the event itself is ticket 14); re-buying never re-sets it.

**Blocked by:** 01 — Muscle seam and data.

**Relevant files:**
- `data/home.json` (`rooms`: new `securityOffice`)
- `systems/rooms.gd`, `systems/home.gd` (`room_carryover`, `room_paid`), `systems/muscle.gd` (`board`, `roll_board`, `hire`, `dismiss`, `can_manage`), `systems/guard_upkeep.gd` (`hire_advance`, `pay_hire_advance`, `pay_monday_bill`, `next_monday_bill`)
- `systems/time_system.gd` / daily-tick order (Monday board roll)
- `scenes/screens/hq.gd`, `scenes/screens/hq_floorplan.gd`, `scenes/components/hq_diorama.gd` (room tile), new Security screen under `scenes/screens/`, `systems/nav.gd` (screen id)
- Prior art: `systems/hiring.gd`, `tests/test_hiring.gd` (board-like hire, prepay)
- Tests: `tests/test_muscle.gd`, `tests/test_guard_upkeep.gd`, `tests/test_rooms.gd`, `tests/test_home.gd`
- `.scratch/security-officer/spec.md` (seat shape); muscle spec §Security Office, §Hiring
- REFERENCE.md §1.6 (upkeep), daily-tick order; CONTEXT.md **Security Office**; CODEMAP.md

**Status:** ready-for-agent

- [ ] Security Office appears in the HQ room list only at townhouse+, costs £2,500 and a room slot
- [ ] `can_manage()` false without the room, true with it
- [ ] Board rolls 4 cards on Monday; level odds respected over a seeded run (50/30/15/5/0); never L5
- [ ] Former-guard path: ~10% of cards when former is non-empty, record restored as left with injuries cleared and the "Worked for you before" tag
- [ ] Hire charges the prorated advance for that guard's wage, empties the slot until next Monday, guard lands in Reserve
- [ ] Dismiss confirms, moves guard to former, no refund; former capped at 20 FIFO
- [ ] Monday bill = Σ per-guard wage; grace day behaviour unchanged
- [ ] Buying the room sets the intro trigger once; re-buying never re-sets it
- [ ] Screen code only reads state and calls `Muscle`/`GuardUpkeep`
- [ ] PROSE-REVIEW flagged: Security screen, board and hire strings
- [ ] On-device check listed in report: room purchase, Security tile, Guards list, detail sheet, trait tap, Hire board, empty hired slot, Dismiss confirm
