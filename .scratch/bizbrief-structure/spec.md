# BizBrief structure refresh

Status: approved for tickets (2026-10-11)

## Direction

Use the **Focused Brief (A)** layout in the [throwaway prototype](../bizbrief-structure-prototype/index.html) as the structural reference. The prototype's figures and examples are illustrative; all live values and gameplay rules continue to come from the canonical data and systems.

Keep BizBrief's approved navy, paper-white, serif and signal-red visual language, phone frame, and four top tabs: **Brief**, **Manage**, **Staff**, **Stats**. Brief and Manage remain available from the start; Staff and Stats retain their current unlock gates. The refresh changes hierarchy, navigation, density and presentation, not economy rules.

## Player experience

### Brief

- Compress the app header to the brand, back route and live day/block. Keep the phone status bar and tab underline.
- Open after Rest on a concise **Today** view. Show date and blocks left; keep fixed Urgent → Story → Opportunity → Routine order, clear tier headings, consequence text, done ticks, and a calm empty state.
- Make each Today item a compact, full-width row with one clear route. An item must open its actual destination or subject, including a specific contract or offer.
- Group simultaneous demand spikes into one opportunity summary. Its detail lists each held good with its demand signal and Sell route. Preserve the underlying demand checks and the BizBrief badge's Urgent + Story meaning.
- Represent pending wage and staff poach decisions in the Today priority area, with the decision controls available at their destination. Do not repeat the same alert below Today.
- Below Today show one compact **Yesterday** summary and links to **Morning report**, **Business money**, and **Market position**. The Morning report contains the existing full overnight account, payday and operations details. Business money contains pot, float and transfer controls. Market position contains faction moves, war/weariness, London share and supplier share. Keep these pages accessible before or after pot activation as appropriate.

### Manage

- Make Manage a short workstream index with **Sales**, **Production**, and **Procurement**. Show one actionable status per workstream; suppress repeated empty statements.
- Sales holds offers, active contracts, delivery priority, buy-missing-calc control, details, cancellation and history. Preserve all current actions. Open a targeted contract or offer from Today.
- Production holds targets, contract coverage controls and production log. Put the target/status summary before detailed controls.
- Procurement lists assigned veins per cultivator and a single **Assign vein** chooser. Do not repeat every available vein under every cultivator. Preserve target and unassign controls.

### Staff and Stats

- Staff shows one concise roster row per person; person detail holds role, skills, pay and assignments. Pending pay/poach routes land on the relevant person and decision. Preserve founder role rules and payroll controls.
- Stats retains every existing measure, chart, ore-source toggle and Guard Costs route. State the completed-day window plainly on each chart or chart group and use clear metric labels.

## Constraints and acceptance

- All new copy follows the content guide and is reported with `PROSE-REVIEW:`.
- No state mutation in screens; systems keep pure-state and event-flow boundaries. No new business formulas or game actions.
- Update the prior Today and visual-direction specs where this hierarchy supersedes them. Preserve their unchanged mechanics, tier order, unlocks, badge semantics, and accessibility behaviour.
- Each ticket is a runnable vertical slice with focused headless checks using Godot 4.7. The human checks phone layout, scroll, touch targets and legibility on-device.

## Tickets

1. [Compact shell and Sales workstream](issues/01-shell-manage-sales.md)
2. [Production workstream](issues/02-production-workstream.md)
3. [Procurement workstream](issues/03-procurement-workstream.md)
4. [Staff roster and details](issues/04-staff-roster-details.md)
5. [Focused Today](issues/05-focused-today.md)
6. [Pay and poach decisions](issues/06-pay-poach-today.md)
7. [Grouped demand opportunities](issues/07-group-demand-opportunities.md)
8. [Morning report and money](issues/08-morning-money-details.md)
9. [Market position detail](issues/09-market-position-detail.md)
10. [Stats labels and periods](issues/10-stats-labels-periods.md)
