# 138 — Messages app: proper inbox rows + per-contact clear

**What to build:** The Messages contact list is currently a stack of full-width red placeholder buttons. Preview text wraps and spills into the next row (Owen's row draws two texts on top of each other), and the unread count floats mid-row. Rebuild it as a normal phone inbox list styled per ui-vision's phone family: contact name (bold), one-line latest-message preview cut off with `…`, unread count pill, fixed row height, dividers; tap a row → its thread. Add a clear button at the right of each row: it marks that thread read and drops that contact's queued ticker notifications. It only shows when there's something to clear.

**Blocked by:** 137 — Owen texts notify (notifications tagged by contact).

**Relevant files:** `scenes/phone_apps/messages_app.gd`, `systems/messages.gd` (`unread_count`, `has_unread`), `systems/notify.gd`, `scenes/components/top_bar.gd` / `scenes/components/notification_ticker.gd` (queued lines), `scenes/components/map_card_style.gd`, `docs/ui-vision.md`.

**Status:** ready-for-agent

- [ ] System-level clear for a contact (mark read + drop that contact's queued notifications); tested
- [ ] Rows never overlap at any preview length; long previews end in `…`
- [ ] Clear button hidden when there's nothing to clear
- [ ] Human on-device: list with 5 contacts incl. long previews; tap clear on one row; tapping a row opens the thread
