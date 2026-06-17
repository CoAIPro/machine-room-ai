# Pattern: Audit Log

## Intent

Make every consequential action reconstructable after the fact through an append-only record of who did what, to what, when, why, and with what result.

## Problem

When something goes wrong — a wrong decision, a disputed action, an incident, a regulatory question — the system must be able to explain what happened. If the explanation depends on mutable status fields, scattered application logs, or memory, the answer is unreliable or unavailable. Mutable records can be changed after the fact, which is exactly when they matter most.

## Solution

Write an append-only audit entry for every consequential action. Each entry is complete enough to reconstruct the action on its own. Entries are never updated or deleted. Corrections are made by appending a new entry, not by editing an old one.

## Required fields

Every entry captures at minimum:

| Field | Purpose |
|-------|---------|
| `id` | Unique entry identifier |
| `actor_id` | Who performed the action (authenticated identity) |
| `actor_role` | The role under which they acted |
| `target_type` | The kind of thing acted upon |
| `target_id` | The specific thing acted upon |
| `action` | What was done |
| `reason` | Justification or context for the action |
| `previous_state` | State before the action |
| `new_state` | State after the action |
| `request_id` | Correlation and idempotency key |
| `created_at` | When it happened |

`actor`, `target`, `action`, `reason`, `previous_state → new_state`, `request_id`, and `created_at` are the reconstruction minimum. If you cannot answer "who changed what from what to what, when, and why" from a single entry, the entry is incomplete.

## Append-only is the whole point

An audit log that can be edited is not an audit log. Enforce immutability at the storage layer, not by convention:

- Revoke `UPDATE` and `DELETE` on the audit table from application roles.
- Permit `INSERT` only.
- Make corrections by appending a new, reason-bearing entry that references the original.

If the platform supports it, additionally protect the table with a trigger or policy that rejects update and delete attempts outright. See `schemas/audit_logs.sql`.

## What to log

Log every consequential action: state transitions, approvals and rejections, suspensions, data reveals, role and permission changes, and abuse-report resolutions. Read-only access generally does not need an audit entry unless the read itself is sensitive (for example, viewing data that was revealed under a consent workflow).

## What not to put in the log

- **Secrets and credentials.** Never log keys, tokens, or passwords.
- **Unnecessary sensitive data.** Log references and state changes, not full sensitive payloads. Store the *fact* that data was revealed, not a second copy of the data.
- **Free-form blobs in place of structure.** Keep the required fields structured; use a metadata field for the rest.

## Doctrine mapping

This pattern *is* the LOG stage. It also enables the other three: VERIFY and CONTROL decisions are only trustworthy if their outcomes are recorded, and DEGRADE SAFE relies on the log to make failures visible and reconstructable.

## Anti-patterns

- **Mutable audit rows.** Status updated in place with no history.
- **Logs that omit the actor or the reason.** "Something changed" is not an audit trail.
- **Application logs as the only record.** Ephemeral, unstructured, and easy to lose.
- **Logging on success only.** Failures and refusals are often the most important entries.

## Checklist

- [ ] Every consequential action writes an entry
- [ ] Each entry alone answers who / what / to what / from what / to what / when / why
- [ ] `UPDATE` and `DELETE` are revoked on the audit table
- [ ] Corrections append a new entry referencing the original
- [ ] No secrets or unnecessary sensitive payloads are stored
- [ ] Failures and refusals are logged, not only successes
