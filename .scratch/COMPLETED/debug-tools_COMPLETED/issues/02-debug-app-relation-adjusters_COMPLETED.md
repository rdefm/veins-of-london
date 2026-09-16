# 02 — Debug app: relation adjusters (contacts and factions)

**What to build:** The Debug app screen (ticket 01) gains a Relations section listing every contact and every faction, each with a working control to adjust that relation value — covering both of the game's separate relation systems in one place.

**Confirmed mechanics (from 2026-08-29 grill-me session — no open design questions):**

- **Scope:** both contacts (Archie, James, etc. — `Contacts.award_relation()`) and factions (Guild, Firm, Collective, Network, Conclave — `Factions.adjust_player_relation()`), per explicit confirmation ("both contacts and factions") — these are two distinct systems in the code and both need covering.
- **Listing:** every entry in `state.contacts` and every entry in `state.factions`, regardless of unlock/join state (a debug tool should let the human raise an unmet contact's or unjoined faction's relation to test unlock/join gating itself).
- **Adjustment:** a player-entered delta applied via each system's existing adjuster function — not a hand-mutated raw field write, so any side effects those functions already carry (e.g. relation-threshold-crossing hooks, if any exist) fire normally.
- **Input style, layout:** left to the implementer, same as ticket 01.

**Where:** the Debug app screen from ticket 01, `systems/contacts.gd` (`award_relation()`), `systems/factions.gd` (`adjust_player_relation()`), `state.contacts`, `state.factions`.

**Blocked by:** 01 (needs the Debug app screen to exist).

**Status:** ready-for-agent

- [ ] Debug app screen lists every contact with a working relation-adjust control, calling `Contacts.award_relation()`.
- [ ] Debug app screen lists every faction with a working relation-adjust control, calling `Factions.adjust_player_relation()`.
- [ ] Locked/unjoined contacts and factions are still listed and adjustable.
- [ ] Test coverage: each adjuster calls the correct underlying function with the correct id and delta.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes.
- [ ] Manual check noted for the human: from a debug start, raise an unmet contact's relation past its recruit threshold and confirm recruitment becomes available; raise an unjoined faction's relation past its join threshold and confirm joining becomes available.
