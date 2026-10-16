# 06 — Messages app: texting look + typing indicator

**What to build:** The Messages thread looks like a real texting app. Incoming bubbles sit left in a realistic grey; the player's chosen reply options appear as sent bubbles on the right in a realistic sent colour. Before each incoming reply, a bubble with an animated three-dot "typing" indicator shows for ~1.5–3s (scaled by message length), then the message appears. Tap skips the wait.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/phone_apps/messages_app.gd` (staged bubble reveal, action bar, Owen reply choices), `systems/messages.gd`, `docs/ui-vision.md`

**Status:** ready-for-agent

- [ ] Selected choices persist in the thread as sent bubbles
- [ ] Typing bubble animates (three dots) before each incoming message; duration scales with length within 1.5–3s; values in data, not code
- [ ] Tap skips the typing delay
- [ ] Screen does not mutate state; any persisted sent text goes through the messages system
- [ ] On-device check listed in report
