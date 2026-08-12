# 01 — Approaches data + unlock resolution + Lab room rename

**What to build:** The engine-level truth of which physical approaches (Heat, Grinding, Compression, Distilling) a player knows, and when a new one is learned. Heat and Grinding are known from game start; Compression and Distilling unlock via specific home rooms. The existing `lab` home room's player-facing name changes to "Improved Lab" so it stops colliding with the bench's in-fiction name "The Lab" — its internal id/key is untouched.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `data/approaches.json` created: one entry per approach (`heat`, `grinding`, `compression`, `distilling`) with `name`, `symbol`, `source` (`{"type":"start"}` or `{"type":"room","id":"..."}`; schema also tolerates `contact`/`faction`/`device` source types even though nothing uses them yet).
- [ ] A resolution function reports which approaches a given player state currently knows (start-known ones always included; room-gated ones included iff the room is owned).
- [ ] `data/home.json`'s `lab` room entry: `name` field changed to "Improved Lab"; `id` and every other field unchanged.
- [ ] `REFERENCE.md` updated to reflect the room rename.
- [ ] `tests/test_home.gd` / `tests/test_rooms.gd` extended: approach-unlock resolution correctly tied to room ownership (owned → unlocked, not owned → locked, start approaches always unlocked regardless of rooms owned); existing room lookups by id (`"lab"`) still resolve correctly after the rename.
- [ ] Syntax check clean on all touched `.gd` files (`scripts/check_runner.gd`).
