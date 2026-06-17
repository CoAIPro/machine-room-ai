# Pattern: Moderation Queue

## Intent

Prevent submitted content from becoming publicly visible until it passes a publish decision. Used for **listing moderation** — when an actor submits a listing and the system must decide whether it may go live.

## Problem

When **an actor submits a listing**, publishing it immediately exposes every user to unreviewed content: spam, abuse, policy violations, or unsafe material. Reviewing everything by hand does not scale; publishing everything blindly is unsafe.

## Solution

Route every new submission into a moderation queue. Submissions default to `pending_review` and are not publicly visible. An automated check, a human reviewer, or both decide whether each item is published, rejected, or escalated.

## States

```text
pending_review  ──▶  approved (published)
       │
       ├──────────▶  rejected
       │
       └──────────▶  escalated  ──▶  approved
                         │
                         └────────▶  rejected
```

| State | Visible publicly? | Meaning |
|-------|-------------------|---------|
| `pending_review` | No | Default for new submissions |
| `approved` | Yes | Passed moderation, published |
| `rejected` | No | Failed moderation |
| `escalated` | No | Requires a senior reviewer or incident flow |

**New submissions always default to `pending_review`.** Visibility is a privilege granted by moderation, not the default state of a submission.

## Automated and human moderation

Moderation can combine layers without changing the state machine:

- **Automated pre-check.** A classifier or rule set may auto-approve clearly safe items and route risky items to human review. The classifier *proposes*; the queue *decides*.
- **Human review.** A reviewer makes the publish decision on items the automation did not clear.
- **Escalation.** Items that are ambiguous, high-impact, or repeatedly reported route to a senior reviewer or the incident flow.

Confidence-banded routing is a useful refinement: high-confidence-safe auto-approves, mid-confidence routes to human review, low-confidence-or-flagged escalates. The decision authority always remains the queue, never the classifier alone.

## Doctrine mapping

- **VERIFY** — Confirm the submitter is authenticated and permitted to submit. Validate the submission shape. Confirm the item is in `pending_review` before any moderation transition.
- **CONTROL** — Default new submissions to `pending_review`. Allow only declared transitions. Keep `rejected` and `escalated` items non-visible.
- **LOG** — Record the moderator (human or automated), the item, the decision, the reason, previous and new state, timestamp, and request ID.
- **DEGRADE SAFE** — If moderation cannot run (classifier down, reviewer unavailable, storage failure), the item stays `pending_review` and non-visible. Failure must never default to "publish."

## Reviewer workflow

1. New submission is created in `pending_review` (logged).
2. Optional automated pre-check proposes a disposition.
3. Reviewer (or auto-approve) commits `approved`, `rejected`, or `escalated` (logged with reason).
4. `approved` items become publicly visible; all other states remain hidden.

## Schema reference

See `schemas/moderation_reviews.sql` for the moderation record and `schemas/audit_logs.sql` for the decision history.

## Anti-patterns

- **Publish-by-default.** New submissions visible before review. The single most common moderation failure.
- **Fail-open.** When moderation errors, the item is published anyway.
- **Classifier as final authority.** An automated score commits the publish decision with no record of an accountable decision.
- **Silent escalation.** Items routed to escalation with no one notified and no incident record.

## Checklist

- [ ] New submissions default to `pending_review` and are not visible
- [ ] Moderation failure keeps items hidden (fail-closed)
- [ ] Automated decisions are logged with the same fields as human decisions
- [ ] `rejected` and `escalated` items are never publicly visible
- [ ] Every transition is written to the audit log
- [ ] Escalation notifies someone and creates an incident record
