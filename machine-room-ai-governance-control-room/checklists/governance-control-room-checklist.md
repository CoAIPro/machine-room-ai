# Governance Control Room Checklist

Use this checklist to assess whether a system's consequential actions are governed. Work through it per action, then across the system as a whole. The four sections map to **VERIFY → CONTROL → LOG → DEGRADE SAFE**.

A consequential action is one that changes shared state, exposes private data, moves value or entitlements, grants or escalates access, affects another user, or triggers an irreversible side effect.

## 0. Inventory

- [ ] Every consequential action in the system is written down
- [ ] Each action has a named owner module in the control room
- [ ] Read-only and reversible-private actions are explicitly marked as out of scope

## 1. VERIFY

For each consequential action:

- [ ] The actor is authenticated (identity is established, not claimed)
- [ ] The actor's role and permissions are checked for this action on this target
- [ ] Input is validated for shape, type, range, and referential integrity
- [ ] The target's current state is confirmed eligible for the requested transition
- [ ] A failed verification stops the action before CONTROL

## 2. CONTROL

- [ ] Legal state transitions are declared explicitly, not implied by code paths
- [ ] Illegal transitions are refused outright
- [ ] High-impact transitions route through a human approval gate
- [ ] New submissions and new entities default to a non-trusted, non-visible state
- [ ] Repeatable admin actions are idempotent (a retry does not double-apply)
- [ ] The decision authority is the control room, never a classifier score alone

## 3. LOG

- [ ] Every consequential action writes an audit entry
- [ ] Each entry alone answers: who / what / to what / from-state / to-state / when / why
- [ ] The audit store is append-only (`UPDATE` / `DELETE` revoked)
- [ ] Corrections append a new entry referencing the original
- [ ] Failures and refusals are logged, not only successes
- [ ] No secrets or unnecessary sensitive payloads are written to logs

## 4. DEGRADE SAFE

- [ ] Every consequential action has a defined behavior when a dependency fails
- [ ] The failure behavior is one of: block, retry safely, escalate, fall back
- [ ] Moderation and reveal failures fail closed (hidden / not revealed), never open
- [ ] Retries are idempotent and cannot double-apply
- [ ] Failures are surfaced, never silent
- [ ] An incident / escalation path exists and names who is notified

## 5. Cross-cutting

- [ ] Identity & role control underpins every other module
- [ ] The admin control panel's own actions are governed and logged
- [ ] Abuse reports route to a queue and resolve through a recorded disposition
- [ ] State machines are small, explicit, and documented per entity
- [ ] The system can reconstruct any past incident from the audit log alone

## Sign-off

- [ ] Each unchecked box has a tracked remediation item or a documented accepted risk
- [ ] This checklist was reviewed before launch and is re-run when any new consequential action is added
