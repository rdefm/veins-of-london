# 19 — Home raid, debriefs and vein handover: proposal (prose)

**What to build:** A writing-revamp proposal for `home_raid_intro` and both debriefs:
- **3:14 am, someone's inside:** Ambush with the torch (check 50%, +15% Time Pearl equipped, +10% brave; success = raider starts at −30% HP; fail = normal fight) · Shout that you've called the police (check 35%, +15% brave; success = raider bolts, no fight, win debrief; fail = raider acts first) · Stay still (no fight, existing loss rule, loss debrief).
- Raid intro describes your single room (no "flatmates").
- Debriefs talk about what you own (pearls / your stuff); an ore line only if you hold ore.
- Archie's handover says "the crack in the wall I told you about" if the pub "where does it come from?" was asked, else introduces the vein plainly.
- Proposes `at: night` for the raid and labels for debriefs.

Proposal only.

**Blocked by:** 11 — Intro proposal (pub and brave option ids).

**Relevant files:** `data/events/home_raid_intro.json`, `data/events/home_raid_debrief_win.json`, `data/events/home_raid_debrief_loss.json`, `systems/combat.gd` (`_after_home_raid_combat`), `.scratch/writing-revamp/writing-guide.md`, `docs/CONTENT-GUIDE.md`, review §18.4.

**Status:** ready-for-agent

- [ ] Proposal file `.scratch/writing-revamp/home-raid-proposal.md`: cards, option ids, checks, outcomes, debrief branches (ore/no-ore, asked/not-asked; via `requires` or `goto`).
- [ ] Card counts vs current 3 / 12 / 12; art-needing cards listed.
- [ ] Report flags `PROSE-REVIEW:`; stops for owner approval.
