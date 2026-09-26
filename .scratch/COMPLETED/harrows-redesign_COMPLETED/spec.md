# Harrow's estate agent app redesign

## Approved direction

Reference mockup: [harrows-mockup.html](harrows-mockup.html). Open it and tap **View particulars** on Flat; scroll within the phone to see the floorplan. The Studio particulars demonstrate the no-floorplan case.

Harrow's should read as a conventional mobile estate agent app inside the existing phone frame. Use white listing and particulars surfaces, editorial property typography, thin dividers, and Harrow's deep green with restrained gold from its launcher icon. Keep the existing phone status bar and frame. The app's internal chrome should differ from the other phone apps.

The listing feed retains all seven tiers in canonical ladder order, each with its existing image or placeholder. The current home remains distinguished. Property cards show the existing rent/buy terms, room count, and calculated raid risk without adding search, filters, favourites, viewing requests, or other mechanics.

Particulars show the existing image, estate agent copy, tenure costs, room capacity, raid risk, and Rent/Buy actions. Keep disabled unaffordable buys, utility previews, moving losses, and room/security warnings. Show the existing static floorplan inline below the copy only for tiers with a floorplan; currently this is Flat. Preserve current-home buy-out, arrears, and floorplan information.

This design direction supersedes the older Harrow's dashboard/red-accent guidance in `docs/ui-vision.md`; implementation should reconcile that document. No game implementation has been made for this mockup.

## Proposed ticket breakdown

1. **Estate agent listings and brand chrome** — usable listing feed with Harrow's green/gold header, white property cards, existing listing order/photos/current-home data and actions. No blockers.
2. **Particulars and inline floorplan** — matching detail view with existing purchase/rental behaviour, all warnings and previews, and Flat's inline floorplan. Blocked by 1 for shared chrome.
