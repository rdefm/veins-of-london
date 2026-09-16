# 03 — Messages app + pendingMessages

**What to build:** A real Messages app — conversation list, per-contact
conversation screen with a pinned action bar, and a generic runtime-delivery
mechanism (`pendingMessages`) that any system can use to text the player
something and offer an action, without a new bespoke screen each time. Full
detail in `.scratch/collective-act1/spec.md` §5.2, §5.3, §10.3 (`push_message`,
`unlock_contact` ops) — read it before starting.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Conversations render most-recent-activity-first with an unread dot per
      conversation; each holds up to 50 messages, evicting from the front.
- [ ] The action bar's Trade entry opens the existing `sell_menu` modal — no
      second trade UI is built.
- [ ] A `pendingMessages` entry appends an unread text to the right
      conversation, badges the Messages app icon, and surfaces an action-bar
      entry that calls `Events.start_event(id, payload)` — the same `context`
      road `systems/raiding.gd` already uses to hand a runtime site id to an
      event. The entry is removed once its action is taken.
- [ ] Archie's and James's existing SMS screens are untouched and do not
      appear in the new Messages app (§5.2 — migrating them is a future
      ticket, out of scope here).
- [ ] Save compatibility: `state.messages` / `state.pendingMessages` are
      seeded by `backfill_defaults()` for old saves, and message `day` int
      types survive a JSON round-trip (`_restore_int_types()`).
