# 19 — Rebuild `vein_raid` as the Yard stage tree (placeholder prose)

**What to build:** `vein_raid` is rebuilt to the approved proposal (§3, the Yard): a fenced depot yard. Three routes (front gate, back window, roof via fire escape on seeded sites) diverge after the perimeter and meet at the vein room, plus the shared cards (windows, alarm, guard post, reinforcements, ward, camera, vein room, claim/loot, getaway). Uses observation gates and security-profile text variants, item effects (rolled and no-roll), alert raises and cover rolls, mid-raid fights from fight presets, Back out / Run for it, per-route calibration from §1.4, and key links. The one-shot item approach rows from the earlier tickets (Wormhole, Pan's Rapture, Panic, Pandemonium, Powder) are folded into the cards where the proposal puts them. New and changed prose is placeholder (real prose: ticket 26). Existing prose the proposal keeps (intro, observation texts, claim/loot) is carried over unchanged.

**Blocked by:** 08 — Proposal (approved); 13 — Card links by key; 14 — Fight presets; 15 — Item options without a roll; 16 — Raid alert level; 17 — Cover roll on alert; 18 — Mid-raid guard bookkeeping; 20 — Site security profile; 21 — Wards; 22 — Item tier scaling; 23 — Reinforcement clock; 24 — siteWary; 25 — Observation text variants.

**Relevant files:** `.scratch/raid-events/raid-variants-proposal.md` §1–3, `data/events/vein_raid.json`, `.scratch/writing-revamp/vein-raid-proposal.md` (storyboard draft, keep in sync or retire), `tests/test_raiding.gd`, `tests/test_event_items.gd`, `tests/test_event_content_lint.gd`, `CODEMAP.md`, REFERENCE.md §3.9a Event choice checks, §3.9d Observation, §3.7b Open/Guarded round combat, §3.12 Vein raiding.

**Status:** ready-for-agent

- [ ] Event matches proposal §3: routes, cards, gates, item effects, alert rules
- [ ] Content lint passes; all links are key links
- [ ] Tests (seeded): each route reaches claim/loot on a clean run; the roof route exists only on fire-escape sites; each item path reaches its outcome; an alert raise changes later odds/options; a mid-raid fight win continues with fewer guards; a loss ends the raid
- [ ] CODEMAP row for `vein_raid.json` updated
- [ ] Human on-device check: play each route clean and noisy via debug start
