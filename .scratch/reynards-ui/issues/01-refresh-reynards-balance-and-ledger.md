# 01 — Refresh Reynard's balance and ledger

**What to build:** Reynard's reads like a contemporary banking app within the existing phone frame. A prominent balance panel leads into a compact, day-grouped transaction ledger. The screen remains a read-only view of the same cash balance and transaction history.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `.scratch/reynards-ui/reynards-mockup.html` (visual direction, not a pixel-exact specification), `scenes/phone_apps/bank_app.gd`, `scenes/phone_apps/phone_app.gd`, `scenes/components/ui.gd`, `scenes/screens/phone.gd`, `docs/ui-vision.md` §10 “App-content shell” and “Per-app layout conventions”, `docs/REFERENCE.md` §2 `bankLog` and § “Phone home”, `CODEMAP.md`.

- [ ] Show the current `player.cash` balance as the dominant figure in a single restrained dashboard panel; use `calc_gold` only for currency values.
- [ ] Show every `bankLog` entry newest first, grouped under its existing day, with its original label and correctly signed amount. Render entries as compact rows with hairline dividers instead of one bordered card per transaction.
- [ ] Keep the existing phone back navigation, dark app shell, external status board, and Phone/Map/HQ dock. Add no banking actions, new calculations, or ledger data.
- [ ] Preserve a clear empty-history state and readable wrapping for long transaction labels and amounts on a narrow phone viewport.
- [ ] Run Godot 4.7 syntax checks on every touched GDScript file and the full headless test suite. Include a focused verification of ledger order, day grouping, amount signs, and empty state; request on-device visual QA for spacing, scrolling, and text legibility.
