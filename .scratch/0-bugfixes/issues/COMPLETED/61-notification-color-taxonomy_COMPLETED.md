# 61 — Notification color taxonomy

**What to build:** `Notify.push(text)` entries (`systems/notify.gd:17-27`) are currently `{ id, text, seen, day }` only — no severity/type field — and `notification_toast.gd:75-82` renders every entry as a plain default-styled `Button`, so all notifications look identical (and, per the human, are easy to mis-tap since they're indistinguishable from each other and sit near top-bar buttons). Add an Info/Success/Warning/Danger taxonomy: a category at push time, styled with a distinct colour per category. Categorize existing notification call sites (e.g. "Archie texted" → Info, craft/sale succeeded → Success, low cash/low HP → Warning, raided/device broken → Danger) rather than leaving them all defaulted to one bucket.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `Notify.push()` gains a `category` param (`info`/`success`/`warning`/`danger`), defaulting sensibly if omitted, stored on the notification entry.
- [ ] `notification_toast.gd` styles each entry's colour by category instead of uniform default styling.
- [ ] Existing `Notify.push()` call sites across `systems/` audited and given an appropriate category (not left all-default) — at minimum, raid/device-break → danger, craft/sale success → success, low-cash/low-HP warnings → warning.
- [ ] Test confirming category is stored and retrievable on pushed notifications.
- [ ] Manual check noted for the human: trigger a few different notification types and confirm they render in visibly different colours.
