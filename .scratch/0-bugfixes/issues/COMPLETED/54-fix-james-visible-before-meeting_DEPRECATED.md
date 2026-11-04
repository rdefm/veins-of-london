# 54 — Fix James visible/offering jobs before meeting event

**What to build:** James's contact card is gated on `contacts.james.unlocked` (`scenes/screens/contacts.gd:30`), which correctly defaults `false` (`GameData.CONTACTS_DEFAULTS`) and is only set `true` by the `james_meeting` event (`data/events/james_meeting.json:33`). But `flags.metJames` — also set by that same event (`james_meeting.json:31`) — is never actually read for gating anywhere; its only consumer is cosmetic todo-list text (`systems/todo.gd:27,29`). Critically, job-offer logic (`systems/jobs.gd:74-94`, `roll_daily_offer`/`_set_offered_job`) has **no unlock check at all** — it can roll and surface a James job offer regardless of `contacts.james.unlocked`. Human confirmed repro on a plain New Game (not debug start): James was visible/offering jobs before meeting him. Root cause is almost certainly the missing unlock check in `jobs.gd` surfacing an offer/notification independent of whether his contact card is shown.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `Jobs.roll_daily_offer()`/`_set_offered_job()` (`systems/jobs.gd`) gated on `contacts.james.unlocked` — no job offer can roll or surface before James is met.
- [ ] Confirm no other James-related surface (notifications, contact list, SMS thread) is reachable before `unlocked` is true, on a plain New Game start.
- [ ] New test: on default new-game state (`james.unlocked == false`), confirm `roll_daily_offer()`/equivalent never produces a James offer.
- [ ] Manual check noted for the human: start a plain New Game, play several days without triggering the James meeting event, confirm no James contact/job offer appears anywhere.
