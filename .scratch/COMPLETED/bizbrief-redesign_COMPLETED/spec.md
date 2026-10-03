# BizBrief visual redesign

## Approved target

`selected-direction.html` is the target design and aesthetic for BizBrief. Its four phone views are static examples with illustrative values. Implement its navy surfaces, restrained signal red, editorial serif headings and figures, compact rows/cards, brand header, and underline tab navigation inside the existing phone frame and status bar. Keep live values, current gates, and existing gameplay rules. The other Phone apps retain their own styling.

`docs/ui-vision.md` should permit distinct aesthetics within Phone apps and document BizBrief's approved exception to the shared phone-app chrome and typography rules. BizBrief's related Short Pay, Guard Costs, and contract-cancel surfaces use the same aesthetic.

## Existing content and interactions

The mockup is a visual hierarchy, not an exhaustive content inventory. Preserve every current BizBrief feature and empty/locked state. On Brief, place payday, wage prompts, faction moves, war, London share, and supplier share below the mockup's lead sections, using compact navy cards and rows. Keep urgent live attention prominent even before a morning account exists. Keep full account and operations details available.

Mockup links such as **Full brief**, **History**, **Details**, and **Log** reveal or jump to existing content within the current tab. They do not create new game data or mechanics. Existing external routes and deep links still go to their current destinations. Preserve Manage's offers, contracts, drag priority, production controls/log, and procurement; Staff's roles, skills, pay; and Stats' complete metric set, ore toggle, and Guard Costs entry.

Use the mockup's visual language for any content it omits. Derive all displayed counts, totals, dates, and status from current state/systems. Do not hardcode the mockup's sample values. Any new UI prose must be flagged `PROSE-REVIEW:` in the implementation report.

## Verification

Each ticket keeps its current action paths and updates focused headless UI tests. Run the Godot 4.7 syntax check on every touched `.gd` file immediately after editing, then `scripts/run_tests.sh` with the specified 4.7 console binary. The human checks phone layout, legibility, scroll, touch targets, and visual fidelity on-device.
