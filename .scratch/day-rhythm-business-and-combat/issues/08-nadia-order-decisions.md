# 08 — Nadia order decisions

**What to build:** Specify the proposed quantity-based introductory order and safe migration before changing Nadia’s progression.

**Blocked by:** None — can start immediately.

**Status:** complete

This ticket authorizes investigation, decision capture and only the explicitly bounded prototype described below. Unresolved rules require human input; ready-for-agent means work can begin, not that proposed mechanics are approved.

- [x] Obtain explicit approval for replacing three transactions with thirty cumulative units of time calc, one delivery or several, continuing into the existing vein-sale request.
- [x] Specify payment, partial deliveries, over-delivery handling, eligibility, time cost and whether previously sold stock counts; do not invent values or hijack unrelated trades.
- [x] Inspect existing save/objective progress and approve how partial qualifying trades transfer; retain completed objectives and prevent repeated rewards.
- [x] Record approved rules and acceptance examples for fresh, partial and completed saves and one versus multiple deliveries.
- [x] Leave production objectives unchanged until approved; ticket completion requires the human decisions.

## Approved rules — 2026-09-13

- Requirement: receive 30 cumulative units of `time` calc. One or many deliveries count equally.
- Eligibility: only a trade made directly through Nadia contributes. Trades through Des, Hakim, Archie, or any other lane remain ordinary trades and do not advance this order.
- Payment: every accepted unit is paid at Nadia's current live Collective sell price (the existing ticker/district/relation-adjusted faction price), including units delivered after the requirement is met.
- Partial and over-delivery: accept the entire selected quantity when the player has the stock. Progress is capped at 30; an over-delivery still pays every unit at the live price and completes the order once the cap is reached.
- Action cost: current Collective trading calls no `TimeSystem` operation and therefore consumes no time block. Preserve that behaviour for the supply action.
- Migration: retain any already-completed Nadia objective exactly as completed; never replay its completion effects. For an incomplete legacy objective, credit its already-recorded qualifying post-activation `time` units (the old Collective-wide counter) into the new order, capped at 30. New deliveries thereafter must be direct Nadia trades only. Old data does not record which Collective door handled a historical sale, so this is a one-time compatibility credit, not a claim that those historic units were Nadia-only.

## Acceptance examples for ticket 09

| Save / delivery | Expected result |
| --- | --- |
| Fresh; Nadia sells 12, then 18 time calc | Paid live price on both trades; Notes shows 18 then 0 remaining; objective completes after the second trade. |
| Fresh; Des or Hakim sells 30 time calc | Paid normally; Nadia order remains 30 remaining. |
| Fresh; Nadia sells 35 time calc once | All 35 units are removed and paid; Notes shows 0 remaining; progress is capped at 30; objective completes once. |
| Partial legacy; old post-activation counter is 12 | Migrates to 12/30; a direct Nadia sale of 18 completes it. |
| Completed legacy objective | Remains complete after load; no completion event, reward, or vein-sale request is granted again. |

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
