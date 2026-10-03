# 04 — LodedInnit app: hire an open candidate (tracer)

**What to build:** A new phone app, LodedInnit, unlocks when James joins. It lists the full 8-person roster under a People tab; tapping one opens their profile: name, headline, about, role, level → cap, weekly wage, and **ore-speciality pips for every candidate**. Crafter specialities drive production through ticket 10's rule; cultivator specialities are flavour only for now. The player can hire any candidate whose role room has a free seat. Hiring prepays the first week from pot, then float. If pot + float are short, the player is asked "Top up the float by £X to cover this hire?". On hire the candidate is recruited, their skill set to `startLevel`, they are seated and start working, and they get a business wage entry. In this ticket every candidate is "Open to work".

**Blocked by:** 01 — Role registry; 02 — All staff wages through the business; 03 — Multi-seat role rooms.

**Relevant files:** `data/hiring.json` (candidates, `market`), `data/constants.json` (contacts defaults: roster entries, `skillCaps`, `specialities`), new `systems/hiring.gd`, new `scenes/phone_apps/lodedinnit_app.gd`, `scenes/phone_apps/phone_app_registry.gd`, `systems/phone_apps.gd`, `systems/phone_nav.gd`, `systems/contacts.gd` (`display_name`), `systems/business.gd` (`_draw`, `donate`, `wages`, `_payday`), `systems/rooms.gd` (`producible_recipes`), `autoload/GameData.gd`, `autoload/SaveManager.gd`, `docs/ui-vision.md`, `docs/CONTENT-GUIDE.md`, spec §1 C2/C4/C9/C14, §3, §4.2, §10 R1/R8/R9, REFERENCE.md §2 + §3.10.

**Status:** ready-for-agent

- [ ] Roster seeded `unlocked:false, recruited:false`; old saves backfilled
- [ ] Cultivators carry a `specialities` list (confirmed values in spec R8)
- [ ] App hidden before `bizA1JamesJoined`, visible after
- [ ] Hire refused without a free seat; prepay from pot → float; top-up prompt when short (Yes = donate + hire, No = no hire)
- [ ] Payday does not re-charge the prepaid first week (`paidThroughDay`)
- [ ] A hired crafter produces only recipes within their specialities; a hired cultivator tends veins
- [ ] `hiring.status` state (all open), save shape per spec §9
- [ ] PROSE-REVIEW: candidate profile text
- [ ] REFERENCE + CODEMAP updated
- [ ] Human check: profiles show speciality pips (cultivators and crafters), level→cap, wage; hiring seats them in the HQ room
