# 01 — Refresh Reynard's balance and ledger

**What to build:** Reynard's reads like a contemporary banking app within the existing phone frame, with its own oxblood-and-cream identity taken from `assets/phone/logo-reynards.png`. A prominent branded balance panel leads into a compact, day-grouped transaction ledger. The screen remains a read-only view of the same cash balance and transaction history.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `assets/phone/logo-reynards.png` (brand-colour source), `assets/icons/apps/bank.png` (runtime app icon), `.scratch/reynards-ui/reynards-mockup.html` (visual direction, not a pixel-exact specification), `scenes/phone_apps/bank_app.gd`, `scenes/phone_apps/phone_app.gd`, `scenes/components/ui.gd`, `scenes/screens/phone.gd`, `docs/ui-vision.md` §6 and §10 “App-content shell” and “Per-app layout conventions”, `docs/REFERENCE.md` §2 `bankLog` and § “Phone home”, `CODEMAP.md`.

**Visual scope:** This Reynard's brand treatment is the specific exception to §10's generic opened-app chrome. Shared phone chrome, action colour, and `calc_gold` meaning remain as specified there.

- [ ] Give the balance panel Reynard's icon-derived deep oxblood gradient (approximately `#720e13` to `#51090e`), with warm cream supporting text (approximately `#f5da9f`) and readable contrast. Use the existing Reynard's app icon at a small size in the header's top-right position, replacing the placeholder R tile; retain the warm cream wordmark. Keep the surrounding opened-app shell cool near-black and the ledger rows neutral. These are Reynard's local brand surfaces, not new shared action or currency accents.
- [ ] Show the current `player.cash` balance as the dominant figure in that panel. Keep `calc_gold` for currency figures only, including ledger amounts; do not recolour actions, the external dock, or other apps with Reynard's palette.
- [ ] Show every `bankLog` entry newest first, grouped under its existing day, with its original label and correctly signed amount. Render entries as compact rows with hairline dividers instead of one bordered card per transaction.
- [ ] Keep the existing phone back navigation, dark app shell, external status board, and Phone/Map/HQ dock. Add no banking actions, new calculations, or ledger data.
- [ ] Preserve a clear empty-history state and readable wrapping for long transaction labels and amounts on a narrow phone viewport.
- [ ] Run Godot 4.7 syntax checks on every touched GDScript file and the full headless test suite. Include a focused verification of ledger order, day grouping, amount signs, and empty state; request on-device visual QA for spacing, scrolling, and text legibility.
