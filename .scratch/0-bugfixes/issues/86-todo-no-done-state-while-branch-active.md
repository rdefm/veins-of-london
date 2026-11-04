# 86 — ToDo: no DONE state while a quest branch is active

**What to build:** A questline page in the ToDo app reads as done (DONE stamp, desaturated banner, collapsed Done styling) only when its done flag is set AND no objective in that questline is still active and undone. If any branch of the questline has an active undone goal, the page stays active and shows those goals. Seen on Business Empire: the closing event sets the done flag while other goals are still open. Check Tutorial and Collective too.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/todo.gd` (`get_questline_sections`), `data/todo.json`, `data/objectives.json`, `data/events/biz_a1_closing.json`, `scenes/phone_apps/todo_app.gd`, `tests/test_todo.gd`, `tests/test_phone_todo.gd`

**Status:** ready-for-agent

- [ ] Flag set + undone active objective in the questline: page status is active, no stamp
- [ ] Flag set + all objectives done: page is done, stamped
- [ ] Group ordering (finished pages last) follows the corrected status
- [ ] Tests cover both cases for at least Business Empire
