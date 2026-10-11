# Standalone random events — revised proposals

Eight event drafts for review, using the format of `archie-craft-chat-proposal.md`. The pub quiz has been deleted; the magician remains omitted. No live event JSON or engine code has changed.

| # | Proposal | Why the player is there | Roll / stake |
|---|---|---|---|
| 1 | [Post Office: Parcel Size](post-office-other-proposal.md) | Posting their own packet | Repack it to avoid a higher rate |
| 2 | [The Launderette Minute](launderette-minute-proposal.md) | Recovering their coat from a locked dryer | Release the latch or wait |
| 4 | [The Lift](missing-floor-proposal.md) | Riding a public lift during travel | Free a caught trolley strap or wait |
| 5 | [Location Shoot](location-shoot-proposal.md) | Crossing a street blocked for filming | Do a paid walk-on |
| 6 | [The Double Scan](double-scan-proposal.md) | Buying water at a corner shop | Challenge an extra charge |
| 7 | [Low Tide](low-tide-proposal.md) | Walking past an exposed river wall | Retrieve one concealed calc fragment |
| 8 | [Coffee Machine Incident](coffee-machine-incident-proposal.md) | Buying coffee in a concourse | Reset the cup arm or claim a refund |
| 9 | [Noise Complaint](noise-complaint-proposal.md) | Checking a vibration from the pavement | Trace it to discover an unclaimed vein site |

Every draft gives the player a reason to act, an exit choice, and a rolled branch. Skills and earlier choices modify relevant checks. Items appear only where plausible: optional Prophet's Breath in the site-discovery event; the existing Rewind item remains available through the event runner. Bystanders do not know about calc.

**Implementation decision:** Noise Complaint proposes `discover_event_site` and `requireEventSiteRoom`; details and balance questions are in its file. All odds and amounts elsewhere are draft values.

