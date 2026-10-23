# 08 — One hired cultivator allowed without a Cultivation Station

**What to build:** Right now the player can't hire a cultivator until they've built the Vein Cultivation Station. Change it so, without the station, the player can hire one cultivator on top of Owen. Owen holds a room-free role and doesn't take a seat. Hiring any more cultivators needs the station. Its seats stack on top of the station-free cultivator, so the cap is the allowance plus the station's seats. The hire-block text explains the new limit. The number of station-free cultivators is data, not code.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/hiring.gd` (`has_free_seat`, hire block reason, `hire`), `systems/contacts.gd` (`assign_to_room`, `room_seats_used`), `systems/home.gd` (`has_room`, `room_seats`), `systems/rooms.gd` (cultivator step), `data/hiring.json` (`roles.cultivation`), `data/home.json` (`veinStation`, `roomSeats`), `tests/test_hiring.gd`; REFERENCE.md §3.10 Contacts, rooms, jobs ("Staff roles"), §3.3 "Room seats".

**Status:** ready-for-agent

- [ ] No station: exactly one cultivator can be hired; a second is blocked with a clear reason
- [ ] The allowance stacks: with the station, the cap is the station-free allowance + station seats (e.g. 1 + 1 = 2 with a base station)
- [ ] The hired cultivator works veins (`cultivatorVeins`) with or without the station
- [ ] Owen is unaffected and doesn't count toward the allowance
- [ ] Allowance lives in data; REFERENCE.md §3.10 updated
- [ ] Save fix-up is not needed or is added (a cultivator seated without a station loads fine)
- [ ] Headless tests: hire with no station succeeds once; second blocked; station path unchanged
