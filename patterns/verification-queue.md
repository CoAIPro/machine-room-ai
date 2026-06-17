# Pattern: Verification Queue

## Intent

Hold an entity in a pending state until a permitted reviewer makes an explicit trust decision. Used for **entity verification** — confirming that an actor is who they claim to be before they are granted elevated trust in the system.

## Problem

Some actors must be trusted before they can act (for example, before their submissions are believed or their access is widened). Granting that trust automatically on signup is unsafe: the claim has not been checked. Granting it manually with no structure is unauditable and inconsistent.

## Solution

Place new entities into a verification queue with an explicit lifecycle. A reviewer works the queue and moves each entity to a terminal trust state. Every transition is logged.

## States

```text
pending  ──▶  in_review  ──▶  verified
   │              │
   │              ├────────▶  rejected
   │              │
   │              └────────▶  needs_more_info  ──▶  in_review
   │
   └──(withdrawn by submitter)──▶  withdrawn
```

| State | Meaning |
|-------|---------|
| `pending` | Submitted, awaiting a reviewer |
| `in_review` | A reviewer has claimed the item |
| `verified` | Trust granted (terminal) |
| `rejected` | Trust denied (terminal) |
| `needs_more_info` | Returned to submitter for additional evidence |
| `withdrawn` | Submitter withdrew before a decision (terminal) |

Only declared transitions are legal. A `pending` item cannot jump directly to `verified`; it must pass through `in_review` so that a responsible reviewer is recorded.

## Doctrine mapping

- **VERIFY** — Confirm the reviewer is authenticated and holds a reviewer role. Confirm the entity is in a state eligible for the requested transition.
- **CONTROL** — Allow only declared transitions. Block direct `pending → verified`. Require a reviewer identity on every decision.
- **LOG** — Write reviewer, entity, decision, reason, previous and new state, timestamp, and request ID on every transition.
- **DEGRADE SAFE** — If a decision cannot be committed (storage or downstream failure), leave the entity in its prior state and surface the failure. Never leave it in an ambiguous half-decided state.

## Reviewer workflow

1. Reviewer opens the queue filtered to `pending`.
2. Reviewer claims an item; state moves `pending → in_review` (logged, reviewer recorded).
3. Reviewer evaluates the submitted evidence.
4. Reviewer commits one of `verified`, `rejected`, or `needs_more_info` (logged with reason).
5. If `needs_more_info`, the submitter supplies more evidence and the item returns to `in_review`.

## Schema reference

See `schemas/verification_reviews.sql`. At minimum, a verification review records the entity reference, current state, assigned reviewer, decision reason, and timestamps. The decision history lives in `schemas/audit_logs.sql`.

## Anti-patterns

- **Auto-verify on signup.** Defeats the purpose; trust is granted without a check.
- **No reviewer recorded.** A decision with no accountable reviewer cannot be defended later.
- **Editing the queue row in place with no log.** The current state is visible but the decision history is lost.
- **Implicit transitions in application code.** If the legal transitions are not declared, illegal ones will eventually happen.

## Checklist

- [ ] New entities default to `pending`, never to a trusted state
- [ ] Direct `pending → verified` is impossible
- [ ] Every decision records an accountable reviewer
- [ ] Every transition is written to the audit log
- [ ] `needs_more_info` returns the item to the queue cleanly
- [ ] A failed commit leaves the entity in its prior state
