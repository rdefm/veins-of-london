# 10 — Nightly schedule on the user's Windows machine

**Status:** needs-info. Blocked by the agreement gate (see 05). Set the caps before the first unattended run.

**What to build:** A script that registers (and unregisters) a Windows scheduled task that runs the whole-queue `run` nightly against the local repo with `--yes`. The run writes its output to a log file in the art workspace. Before generating, it checks that the Claude CLI is logged in, because the art judge runs headless through it. If not logged in, the run exits early with a clear line in the log and spends nothing. API keys come from the user's environment, never from the task definition or the repo.

**Blocked by:** 04 — Whole-queue run, filters, resume; 05 — Real image backend adapters.

**Relevant files:**
- `tools/storyboard_server.cmd` (existing Windows launcher precedent)
- `tools/make_phone_app_icons.ps1` (PowerShell script precedent)
- `.scratch/art-autogen/spec.md` (story 18; "Scheduling" decision)

- [ ] Register and unregister scripts are idempotent
- [ ] With the Claude CLI logged out, the run exits before any image call and logs why
- [ ] No key appears in the task definition, the scripts or the logs
- [ ] One real overnight run completes and its summary is readable in the morning (human)
