# 137 — Owen texts notify

**What to build:** When Owen sends a text, the player gets the same notification as for other contacts' incoming texts: a ticker toast plus an unread dot/count on the Messages app and Owen's thread. Today Owen's texts land silently in Messages. Tag the notification with the contact id (138's per-contact clear needs it).

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/owen_texts.gd` (~L50 `Messages.append`), `systems/messages.gd`, `systems/notify.gd`, how other contacts' pending texts notify (grep `Notify.push` next to `Messages.append`); REFERENCE.md §3.10 "Owen's texts".

**Status:** ready-for-agent

- [ ] An Owen text coming due pushes a notification with contact metadata and marks the thread unread; tested
- [ ] Owen's answers to the player's replies don't double-notify
- [ ] PROSE-REVIEW if a new toast line is written
