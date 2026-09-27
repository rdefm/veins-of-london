# 38 — Bank app (cash balance + transaction log)

**What to build:** A new phone app, `"bank"`, added to `PhoneApps.apps()` and rendered by a new `phone.gd::_build_bank()`, showing the player's current cash (`GameState.state["player"]["cash"]`, already exists) and a list of their most recent cash-affecting transactions (in and out) — which does **not** exist as data anywhere yet. This app is purely informational: no new banking mechanics (no interest, loans, transfers) — just a balance readout and a history log, per human decision.

PROSE-REVIEW: this ticket needs a bank name + fox logo concept, drafted against `docs/CONTENT-GUIDE.md`'s tone bible (dry, administrative, "magic is stock," no whimsy — a real London high-street bank parody, not a cute mascot). Candidates for the human to pick between or reject:
1. **"Reynard's"** — surname-brand cadence matching Lloyds/Barclays/Coutts. Reynard is the trickster fox of medieval fable; reads as an old, slightly untrustworthy institution without winking at the player.
2. **"The Brush"** — "brush" is the real English word for a fox's tail. Reads like an old City institution name (in the register of "the Monument," "the Exchange"), obscure enough that a player who doesn't know the word just reads it as a place name.
3. **"Cub & Crown"** — pub-sign cadence, heraldic (fox cub + crown, in the manner of a bank's shield crest, not a cartoon).

Logo concept for whichever name is picked: a fox's head or brush inside a plain roundel/shield, in the dry heraldic register of a real bank mark (Lloyds' black horse, NatWest's cube) — not a cartoon fox, no whimsy, per tone bible rule 4.

## Transaction log (new state — does not exist today)

`player.cash` is mutated directly at roughly a dozen call sites spread across `systems/economy.gd` (Archie sales, mugged-sale payout, Guild purchase/sale), `systems/home.gd` (HQ tier/security/room upgrades), `systems/jobs.gd` (James job payouts), `systems/cultivating.gd` (vein security upgrade, alarm), and `systems/barometer.gd` (Ticker manual push/pull) — with zero history recorded today. Per human decision, **every** cash mutation gets instrumented — the log must be a complete, accurate record from turn one, not a partial one. Re-grep for direct `cash` mutations at implementation time rather than trusting any list written here, since call sites drift; a mutation added after this ticket was written and missed by that grep is a bug.

Add a single logging entry point (e.g. a new `systems/bank.gd`'s `Bank.record(amount: int, label: String) -> void`, or fold into an existing autoload — implementing agent's call on placement) and call it alongside the cash mutation at every site found, with a signed amount (+in/−out) and a short label naming the source (Archie sale, Guild purchase, HQ upgrade, James job, vein upgrade, Ticker push/pull, etc.). Labels should match whatever in-fiction voice reads best next to the bank name chosen above (e.g. if "Reynard's" ships, transaction labels might read like a real statement line) — final copy, not placeholder.

Store the log as a capped array (mirror `Notify`'s existing `GameState.state["notifications"]` / `Notify.LOG_CAP` pattern exactly — same append-and-evict-from-front shape) — the state path and cap constant are the implementing agent's call, but must be added to `docs/REFERENCE.md` §2 per `CLAUDE.md`'s "any number, table, schema lives in REFERENCE.md" rule, since this is new canonical state shape.

**Blocked by:** 36 (app tile placeholder frame) — the bank app's grid tile needs a frame to render inside, same as every other app.

**Status:** ready-for-agent

- [ ] Bank name + logo concept picked by human from the candidates above (or a replacement supplied by human).
- [ ] New `"bank"` entry in `PhoneApps.apps()`, icon falls back to placeholder frame (ticket 36) since no real art exists yet.
- [ ] `phone.gd::_build_bank()` shows current cash and the transaction log, newest first (same ordering convention `_build_notifications()` already uses).
- [ ] Every direct `cash` mutation in the codebase (Archie sales, mugged-sale payout, Guild purchase/sale, HQ tier/security/room upgrades, James job payouts, vein security/alarm upgrades, Ticker push/pull, and any other found by grep) logs a transaction alongside its existing cash mutation, with a signed amount (+in/−out) and a label.
- [ ] Transaction log is capped (mirror `Notify.LOG_CAP`'s exact mechanism) and its new state shape is documented in `docs/REFERENCE.md` §2.
- [ ] No new banking mechanics (interest, loans, transfers) — display only.
- [ ] Tests cover: log records on a representative sample of mutation sites across each system touched, cap eviction behaviour, bank screen renders balance + log correctly with an empty log and a populated one.

**Human should check on-device:** the Bank app opens from the home grid, shows the right cash figure, and a sale/purchase/job payout shows up in the transaction list afterward.
