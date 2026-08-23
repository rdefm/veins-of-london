# 69 — Tutorial: disable raids on the player's vein(s)

**What to build:** Player veins can currently be raided by factions as soon as the player owns one — today this is only incidentally prevented because the player owns zero veins until partway through the tutorial. Add an explicit gate so no faction raid attempts land on player veins while the player is still in the scripted tutorial flow.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] No faction raid attempts (of any kind) roll against player-owned veins while the tutorial is still in progress (i.e. before it reaches its final "free" stage).
- [ ] Raids resume normally the moment the tutorial reaches its final stage.
- [ ] Test coverage: raid roll against a player vein is a guaranteed no-op mid-tutorial; resumes once tutorial is complete.
- [ ] Manual check noted for the human: play through the tutorial with an owned vein, confirm no raid notifications/losses occur until the tutorial finishes.
