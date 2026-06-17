# Example: Marketplace Listing Moderation

A worked, generic example showing the Governance Control Room applied end to end to a **high-trust marketplace workflow**. It uses the **listing moderation** and **abuse reporting** patterns and the **audit log**. No production system, data, or business logic is referenced; everything below is illustrative.

## Scenario

A marketplace lets verified actors publish listings that other users browse and act on. Because users rely on listings being legitimate, no listing may become publicly visible until it passes moderation, and any live listing may be reported and re-reviewed.

Entities involved:

- **Actor** — a participant who submits listings (**actor submits listing**).
- **Reviewer** — a privileged user who works the moderation queue.
- **Reporter** — any user who flags a live listing (**abuse report on target**).
- **Control room** — the governance layer enforcing the rules below.

## State machine

```text
            submit
actor  ─────────────▶  pending_review
                            │
            auto pre-check  │  (proposes; does not decide)
                            ▼
                   ┌──────────────────┐
                   │  reviewer / auto  │
                   └──────────────────┘
                       │     │     │
                approved  rejected  escalated
                   │                   │
              (published)         senior review
                                       │
                                approved / rejected
```

A new submission is **always** created in `pending_review` and is not visible. Visibility is granted only by an `approved` decision.

## Walkthrough

### 1. Submission — VERIFY + CONTROL + LOG

An actor submits a listing.

- **VERIFY** — The actor is authenticated; their role permits submitting; the listing payload is valid; no eligibility precondition is violated.
- **CONTROL** — The listing is created in `pending_review`. It is not publicly visible.
- **LOG** — An audit entry records: actor, target = the new listing, action = `submit`, previous_state = null, new_state = `pending_review`, reason = "actor submission", request_id, timestamp.

### 2. Automated pre-check — CONTROL (proposal only)

An optional classifier evaluates the listing and proposes a disposition using confidence bands:

- High-confidence-safe → propose `approved`
- Mid-confidence → route to human review
- Low-confidence or policy-flagged → propose `escalated`

The classifier **proposes**. The queue **decides**. Whatever the classifier returns, the committed transition is logged as an action taken by the automated moderator identity, with the score in `metadata`.

### 3. Human decision — CONTROL + LOG

A reviewer opens the queue and commits a decision on items the automation did not clear.

- **CONTROL** — Only declared transitions are allowed: `pending_review → approved`, `→ rejected`, or `→ escalated`. The reviewer's role is checked.
- **LOG** — The decision records reviewer, listing, action, reason, previous and new state, request_id, timestamp.

An `approved` listing becomes publicly visible. `rejected` and `escalated` listings remain hidden.

### 4. Abuse report on a live listing — CONTROL + escalation + LOG

A reporter flags a published listing.

- **VERIFY** — The reporter is authenticated; the target listing exists and is live.
- **CONTROL** — An abuse report is created and routed to the moderation queue. Depending on policy and report volume, the listing may be moved back to a non-visible review state pending re-review.
- **LOG** — The report is recorded with reporter, target, reason, timestamp, request_id.

### 5. Resolution — CONTROL + LOG

A reviewer resolves the report through a defined disposition (for example: upheld → listing `rejected`; dismissed → listing remains `approved`).

- **CONTROL** — The resolution applies only legal transitions.
- **LOG** — The resolution records reviewer, report, disposition, resulting listing state, reason, timestamp, request_id.

## DEGRADE SAFE behavior

What happens when something fails, on purpose:

| Failure | Safe behavior |
|---------|---------------|
| Classifier unavailable | Listing stays `pending_review`; routed to human review. Never auto-published. |
| Storage write fails on a decision | Listing stays in its prior state; failure surfaced; reviewer retries with the same request_id (idempotent). |
| Reviewer capacity exhausted | Listings remain hidden in `pending_review`; backlog is visible, not bypassed. |
| Report resolution fails to commit | Report stays open; listing keeps its current state; no half-applied disposition. |

The unacceptable outcome — a listing that becomes visible because moderation failed — cannot happen, because failure is fail-closed.

## What the audit log lets you answer later

From the append-only log alone, the system can answer:

- Who submitted this listing, and when?
- Who approved it, under what role, and for what reason?
- Did the classifier propose this, or did a human decide?
- Who reported it, and how was the report resolved?
- What was the exact state sequence from submission to its current state?

If any of these questions cannot be answered from the log, the LOG stage is incomplete.

## Public-safe note

This example uses only generic roles (actor, reviewer, reporter) and generic entities (listing, report). It contains no production routes, credentials, schemas beyond the published reference schemas, private matching logic, or business-specific workflow. Adapt the role and entity names to your own domain.
