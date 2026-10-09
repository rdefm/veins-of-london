# BizBrief "Today" card: the daily "what now"

Status: ready-for-agent

Source: `docs/reviews/review-2026-10-09.md` §21 (P4, agreed by the owner 2026-10-09), §5, §3.

## Problem Statement

Each morning BizBrief auto-opens on the Brief tab, but it leads with accounts (closing balance, net change) and a "Needs your attention" list that only knows about raid alarms, guard shortfalls, veins ready to develop and unread messages.

The things that decide whether a day goes well are spread across many apps, or nowhere:
- the current story objective (ToDo)
- a vein drifting toward collapse
- a contract period about to fail
- an offer expiring tomorrow
- rent or wages due with too little cash
- a demand spike on goods the player holds
- staff sitting idle

With 14 apps, three HQ zones and a Map drawer, a player finishing a rest has no single answer to "what should I do with today's three blocks?" Playtest notes already flag ToDo saying "nothing pressing" when there clearly was something to do.

## Solution

A **Today** card sits at the top of BizBrief's Brief tab. It gives a short, ranked, actionable plan for the day in four fixed tiers:

- **Urgent:** something bad happens soon if I do nothing.
- **Story:** the current objective.
- **Opportunity:** something time-limited worth money.
- **Routine:** maintenance, summarised in one line.

Each row says what's at stake and has one button that takes the player straight to the screen where they can act. The card shows today's date and how many time blocks are left. It ticks off items the player has dealt with today, and shows a calm empty state when nothing is pressing. The Phone home badge for BizBrief counts only Urgent and Story items, so the badge means "you should look". The existing accounts, Treasury and Operations sections stay below, collapsed by default.

The card only points; the player acts. Nothing is automated.

## User Stories

1. As a player waking up after Rest, I want BizBrief to open on a short plan for today, so that I know what to do with my three blocks.
2. As a player, I want the plan grouped into Urgent, Story, Opportunity and Routine, always in that order, so that I can scan by importance.
3. As a player, I want each row to say what happens if I ignore it ("collapses in ~2 nights", "short £270 for Monday"), so that I can judge priority myself.
4. As a player, I want each row to have one action button that takes me straight to where I can deal with it, so that I don't hunt through apps.
5. As a player, I want to see today's date and how many time blocks I have left on the card, so that I can plan against the day's time budget.
6. As a player, I want raid alarms (home and vein) to appear as Urgent with a button to the alarm, so that I never miss a defence window.
7. As a player, I want a rent or home-bill shortfall to appear as Urgent when the next bill is within a few days and my cash won't cover it, so that the rent threat is visible.
8. As a player, I want arrears to appear as Urgent with the countdown to the next consequence, so that I know how long I have.
9. As a player, I want a staff wage shortfall or pending wage prompt to appear as Urgent, so that my staff don't walk off unnoticed.
10. As a player, I want a guard wage shortfall with its deadline to appear as Urgent, so that I choose who stays before the game chooses for me.
11. As a player, I want a vein that is low and still sliding toward empty to appear as Urgent, with an estimate of the nights left, so that I cultivate it before I lose it.
12. As a player, I want the vein row's action to take me to that vein on the Map, so that I can cultivate it immediately.
13. As a player, I want an active contract whose period will fail if nothing changes (stock short of what's needed by the period end) to appear as Urgent, so that I protect my income and relations.
14. As a player, I want my current story objective to appear as one Story row with the same wording as ToDo, so that the story always has a visible next step.
15. As a player, I want the Story row's action to take me to the relevant place (a contact's thread, the Map, the unit), or to ToDo when there's no better target, so that I can follow the story without guessing.
16. As a player, I want offers expiring within a day to appear as Opportunity, so that I don't miss good deals.
17. As a player, I want a strong market demand on a good I hold (above a set threshold) to appear as Opportunity with a Sell button, so that The Ticker's news turns into money.
18. As a player, I want an open faction favour request to appear as Opportunity, so that relationship chances aren't lost in Messages.
19. As a player, I want routine upkeep (veins ready to prune, idle staff, production short of ore) collapsed into one Routine summary line that expands on tap, so that maintenance doesn't crowd out what matters.
20. As a player, I want the card to show at most about six rows, with "+N more" to expand the rest, so that it stays a glance, not a wall.
21. As a player, I want items I've acted on today to show as ticked rather than vanish abruptly, so that the list feels like progress.
22. As a player, I want items to drop off once their condition is no longer true (the vein is cultivated, the alarm resolved), so that the card stays honest.
23. As a player, I want a short, in-voice empty state when nothing is pressing, so that a quiet day reads as earned, not broken.
24. As a player, I want the Phone home BizBrief badge to count only Urgent and Story items, so that the badge means something.
25. As a player, I want the accounts, Treasury and Operations sections still available below the Today card, collapsed by default, so that detail is there when I want it.
26. As a player, I want the Today card available even before the business pot opens (early game), so that it guides me from day one.
27. As a player in the tutorial, I want the Story row to explain how to move time forward when that's what the objective needs (e.g. "Rest at HQ to wait for Archie's text"), so that I'm never stuck.
28. As a player, I want the Today card to update live while BizBrief is open (e.g. after I resolve an alarm elsewhere and come back), so that it never shows stale state.
29. As a player with reduced motion on, I want ticks and expansion to appear without animation, so that my preference is respected.
30. As a player, I want the Today card's look to match BizBrief's navy chrome and existing section style, so that it feels native to the app.
31. As a content/design owner, I want tier rules, thresholds (days-ahead windows, demand threshold, row cap) and row wording to live in data, so that tuning needs no code change.
32. As a content/design owner, I want every row label and consequence line to be a template flagged for prose review, so that the voice stays consistent.
33. As a developer, I want the plan to come from one pure projection over game state, so that it's testable without UI and can't mutate state.
34. As a developer, I want each row's action to be a plain data description of a destination (app, sub-view, vein, contact, modal) routed by existing navigation, so that the projection stays free of Nodes and Callables.
35. As a developer, I want the existing "Needs your attention" sources folded into the projection rather than duplicated, so that there's one source of truth for "what needs me".
36. As a developer, I want the "ticked today" record kept as pure state that resets at rollover and survives save/load, so that it's consistent with the state-tree rules.
37. As a developer, I want ToDo's "nothing pressing" state to agree with the Today card's Story tier, so that the two apps never contradict each other.

## Implementation Decisions

- **New system: DailyBrief.** A static, pure projection that returns the ranked plan for the current state. It neither writes state nor touches Nodes.
- **Interface.**
  - `items()` returns an ordered list of row dictionaries.
  - `badge_count()` returns the Urgent + Story count.
  - `summary()` returns date label, blocks left and per-tier counts.
  - A function to mark an item acted-on today (the only writer, a system call).
- **Row shape** (pure data):

  ```jsonc
  {
    "key": "vein_collapse:<veinId>",     // stable per subject, used for ticks + de-duplication
    "tier": "urgent" | "story" | "opportunity" | "routine",
    "kind": "alarm" | "bill" | "arrears" | "wages" | "guardShortfall" | "veinAtRisk" | "contractAtRisk" | "objective" | "offerExpiring" | "demandSpike" | "favour" | "routineSummary",
    "label": "Time vein, Whitechapel · Barren (12)",
    "consequence": "collapses in ~2 nights",
    "action": { "to": "map_vein", "veinId": "v3" },   // destination descriptor, no Callables
    "actionLabel": "Cultivate",
    "done": false,
    "sort": 0                            // within-tier urgency (lower = sooner/more severe)
  }
  ```

- **Sources (read through existing system APIs, never raw duplication):**
  - **Urgent:**
    - raid alarms (home, vein); guard shortfall; wage prompts and owed wages (the same sources "Needs your attention" uses today);
    - the home bill due within N days with cash below it, and arrears with their countdown (the Home system's bill and arrears reads);
    - veins in a low band and leaning down, with an estimated nights-to-collapse from the vein's level-driven drift (expected value, no RNG). Nights-to-collapse ≤ a threshold is Urgent; otherwise the vein goes to Routine;
    - active contracts whose current period can't be met by end of period from stock plus reserved production.
  - **Story:** the first active objective from the Objectives/ToDo sections, using the same text. Tutorial objectives that need time to pass get a data-driven action pointing to HQ Rest.
  - **Opportunity:**
    - pending offers expiring within 1 day;
    - goods held by the player whose current demand modifier is ≥ the data threshold (default +25%);
    - open faction favour requests.
  - **Routine:** one summary row aggregating veins ready to prune, idle staff and production short of ore. It expands to individual rows in the UI.
- **Unread messages** are no longer standalone rows. Messages tied to a Story or Opportunity surface through those rows; general unread counts stay on the Messages badge. This removes the current duplication with the Messages app.
- **Ordering.** Fixed tier order, then `sort` within a tier. Cap the visible rows (data, default 6). The Routine summary always occupies at most one row.
- **Ticks.** "Acted on today" keys live in state under the morning-accounts area as a per-day list, cleared at rollover and backfilled on load. A row is `done` if its key is ticked and its condition is still true. Rows whose condition cleared simply disappear. Ticks are set when the player taps the row's action, via a system call from the screen.
- **Thresholds and wording** live in a data table: day windows, the demand threshold, the collapse-nights threshold, the row cap, per-kind label/consequence templates, action labels, the empty-state line and the per-block clock labels. Templates are flagged `PROSE-REVIEW:`.
- **Navigation.** The BizBrief screen maps `action.to` values onto existing navigation (phone app/sub-view deep links, Map drill-down to a vein, opening the Trade sheet or a Sales offer, a contact's Messages thread, an HQ zone). No new navigation system.
- **Badge.** The phone-app badge configuration for BizBrief reads `badge_count()`.
- **Brief tab layout.** The Today card is first. The accounts hero, Treasury and Operations feed move below it into collapsible sections, collapsed by default. Expansion state is session-only presentation.
- **Auto-open.** The existing after-Rest auto-open is unchanged and lands on the Today card.
- **Attention items.** The existing projection becomes an internal source for DailyBrief, or is retired if nothing else reads it. Any other callers are updated so there's one source of truth.
- **CODEMAP** gains rows for the new system and data table.

## Testing Decisions

- **What a good test looks like here.** Tests set up GameState (fixtures/builders), call the DailyBrief projection, and assert on the returned rows: which kinds and tiers appear, their order, consequence values (e.g. nights-to-collapse, shortfall amount), action descriptors, the cap/"+N more", ticks, and badge count. They don't test helper internals.
- **Seam (agreed with the owner).** `DailyBrief.items()` (plus `badge_count()` and `summary()`), one seam.
- **Cases:**
  - each source produces its row in the right tier and drops off when resolved;
  - tier ordering and within-tier ordering;
  - the row cap and the always-one-row Routine summary;
  - the empty state;
  - ticks persist through save/load and clear at rollover;
  - the badge counts only Urgent + Story;
  - the bill/arrears shortfall maths agrees with the Home system's countdown;
  - the vein estimate agrees with the drift rule for a given level and growth;
  - the contract at-risk rule;
  - the demand threshold;
  - the tutorial Story row points at Rest when the objective needs time to pass;
  - ToDo and DailyBrief agree on whether there's an active objective;
  - the projection never mutates state (state deep-equal before and after).
- **Screen.** Phone BizBrief tests are extended only to confirm the Today card renders rows from the projection, tapping an action routes to the expected destination and records the tick, and the lower sections start collapsed.
- **Prior art.** The morning-accounts tests (attention items, rollover capture), the ToDo tests (questline sections), the phone BizBrief and phone-nav tests (rendering, deep links), and the phone-apps tests (badge configuration).

## Out of Scope

- Any automation ("do it for me" buttons, auto-cultivate, auto-sell).
- New consequences for poverty or arrears (review §20). The card only surfaces existing countdowns.
- Changing how alarms, contracts, offers or wages work.
- Redesigning other BizBrief tabs (Manage, Staff, Stats).
- Push notifications or OS-level reminders.
- Travel-time planning (deferred).

## Further Notes

- **Shared work with the opening spec.** The block pips and date label should use the same Calendar/block display as the opening spec's phone-clock work (`.scratch/opening-choices/spec.md`), so the two don't diverge. Whichever lands second reuses the first's helper.
- **Vein estimate.** Nights-to-collapse is an estimate. Phrase it as "~N nights" and never promise exact timing.
- **Expected interaction with poverty teeth.** If the arrears ladder from review §20 lands later, its steps become new Urgent sources with no card changes.
- **Ticket order.** Suggested breakdown: projection skeleton + Urgent sources already in attention items → bills/arrears + vein + contract sources → Story source (with tutorial Rest pointer) and ToDo agreement → Opportunity sources → Routine summary + cap → ticks state + rollover reset + save backfill → BizBrief screen layout + navigation mapping → badge → data table + prose review.
