# Property floorplans — intended behavior

## Scope

- Every property after the Bedsit has an estate-agent-style floorplan. The Flat's approved starting asset is `assets/floorplans/flat.svg`; other property plans need their own designs.
- Each plan has one fixed bedroom. Every other room is a fixed-position selectable slot. The property's existing `maxRooms` value counts selectable slots, not the bedroom. Room positions never change when their uses change.
- This file records interaction behavior. Existing property costs, room costs, bonuses, unlock tiers, and tier order remain canonical in `docs/REFERENCE.md` and `data/home.json`.

## Harrow's and HQ

- Harrow's shows a static, non-interactive plan in each property listing it offers. It does not sell room upgrades.
- After moving in, tapping the HQ noticeboard opens the current property's listing and floorplan. The bedroom is labelled but cannot be selected for upgrades.
- Tapping a selectable room shows its current use, eligible room upgrades, their effects, and full prices. Unavailable choices show why they are locked. A purchase assigns the chosen upgrade to that physical room.
- A room may be changed later. The old upgrade is removed, its effects end, its purchase cost is not refunded, and the new upgrade costs its full listed price. The purchase must respect cash, tier unlocks, and the one-of-each-upgrade rule. Do not remove the old upgrade if the replacement purchase is blocked or cannot complete.
- If a removed room was staffed, its contact is automatically unassigned. The removed room's staffing effects stop.
- The Flat has one selectable room. Under the current unlock table, it can become a Workshop or Home Gym; Library and Safe Room first unlock at Townhouse.

## Moving and saving

- Purchased room upgrades come with the player when they move to the next property. They remain purchased and active, and appear in selectable slots on the new property's plan. The new property adds its additional empty slots. No room upgrade is bought again simply because the player moved.
- The saved game must retain which upgrade occupies each selectable slot. Existing saves with the current room list must continue to load and keep their purchased upgrades. State stays pure data so save, snapshot, and Rewind remain valid.

## Design and implementation boundary

- The SVG contains the Flat's neutral geometry and fixed labels. The game UI supplies the room's current use, selection state, touch target, and purchase controls; these are not baked into the asset.
- This behavior document does not authorize implementation. The approved ticket covers the Flat's complete playable path. Other property plans follow after their assets are designed.
