# 03 — Morning accounts

**What to build:** After the overnight transition, players receive one compact Morning Brief inside BizBrief, a standalone phone app that grows into the home for business operations.

**Blocked by:** 02 — London time transitions.

**Status:** ready-for-agent

- [ ] Add the standalone Phone-OS app **BizBrief** using the existing app registry and icon contract. Its app id is `bizbrief`; its 128×128 full-bleed app icon is the only new raster asset required. Use existing Phone-OS vector chrome and existing ore, warning and message glyphs inside the app.
- [ ] Auto-open BizBrief's **Morning Brief** exactly once after an Evening→Morning transition completes. Action outcome/acknowledgement remains first, then the time animation, then the brief. Loading, reopening or rerendering cannot replay it.
- [ ] Build the brief from a stored account of effects that actually ran during that rollover; never estimate changes, diff unrelated saves, or rerun daily processing. Attribute every brief to its resulting day.
- [ ] Show a **Reynard's** block with opening balance, closing balance, actual income and actual expenses, plus navigation to Reynard's full transaction history. Keep detailed banking records owned by Reynard's rather than duplicating its ledger.
- [ ] Show an **Operations** block with actual ore-stock movement, production, sales, losses and exceptions. This is the first vertical slice of BizBrief as the future home for business management; this ticket adds reporting, not new production, sales, contract or staff mechanics.
- [ ] Show an **Attention** block derived from current unresolved alarm records and unread contact messages. Alarm rows navigate to the detailed alarm flow; message rows navigate to the relevant contact conversation. Do not copy ephemeral notification prose into a competing source of truth.
- [ ] Distinguish what changed overnight from what still needs attention. Unresolved urgency remains visible even when it originated earlier; routine successes stay compact and quiet sections are omitted.
- [ ] Emphasise cash pressure early and existing business output/exceptions later, solely from available state. Introduce no new unlock thresholds, prioritisation formulas or economic rules.
- [ ] Save/load or reopening cannot duplicate transactions or misattribute changes to another day.
- [ ] Test representative income/expense, stock, production, sale, loss, alarm, unread-message and quiet-day cases through daily operations; test once-only auto-open, navigation and save/load attribution. Device QA checks the 390px portrait layout and transition-to-brief handoff.
- [ ] PROSE-REVIEW: **BizBrief**, **Morning Brief**, **Reynard's**, **Operations** and **Attention**, plus any new quiet-day or summary copy.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

## Implementation — 2026-09-13

Added BizBrief and an exact persisted Morning Brief account captured around the existing daily operation order. Evening→Morning/Rest presentation opens the resulting day's brief once, after the outcome and transition. Reynard's totals come from new ledger entries; Operations records actual stock, production, sales, losses and exceptions; Attention remains a live view of unresolved raid records and unread messages.

Verification: Godot 4.7 full suite **2318 passed, 0 failed**; autoload-aware sweep **231 project scripts clean**. The user also approved repair of eight pre-existing blockers: Collective Act I's debt prose now matches its £420 canonical spec, KO rotation uses tolerant float comparison, Debug tests ignore Godot 4.7 dropdown search fields, and generated Android instrumentation is excluded from the project-source syntax sweep.

PROSE-REVIEW: BizBrief, Morning Brief, Reynard's, Operations, Attention, overnight summary/exception/empty-state copy.

ART-REVIEW/device QA: confirm `bizbrief.png` at app-grid size; 390px portrait card fit/scrolling; outcome → transition → brief ordering; Morning Brief, Reynard's history, alarm and message navigation; quiet and busy rollover layouts.
