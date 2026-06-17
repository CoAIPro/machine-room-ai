# Doctrine: VERIFY → CONTROL → LOG → DEGRADE SAFE

## Premise

AI should not move directly from prediction to action.

A model output is a proposal, not a decision. When a system lets a proposal become a consequential action with no intervening checks, it inherits every weakness of the model: hallucination, stale context, prompt manipulation, and silent edge cases. The fix is not a better model. The fix is a control layer that every consequential action must pass through.

That control layer is the **machine room**.

## What counts as a consequential action

An action is consequential if it does any of the following:

- Changes the state of a record other users depend on
- Exposes data that was previously private
- Moves money, credits, or entitlements
- Grants, removes, or escalates access
- Affects another user's standing, visibility, or safety
- Triggers an irreversible external side effect

Read-only actions and reversible private actions usually do not need the full machine room. Everything above does.

## The four stages

### 1. VERIFY

Establish that the action is legitimate before anything happens.

- **Who is acting?** Authenticated identity, not a claimed one.
- **Are they allowed?** Role and permission check for this specific action on this specific target.
- **Is the input valid?** Shape, type, range, and referential integrity.
- **Is the current state eligible?** The target must be in a state from which this transition is legal.

If any check fails, the action stops here. It does not reach CONTROL.

Failure mode when skipped: unauthorized actors mutate state, malformed input corrupts records, actions fire against records in impossible states.

### 2. CONTROL

Decide what is allowed to happen, and how.

- **What transitions are allowed?** Define the legal state machine, not an open set of mutations.
- **What requires approval?** High-impact transitions route through a human approval gate.
- **What must be blocked?** Some transitions are never legal and are refused outright.
- **What requires idempotency?** Repeated admin actions must not double-apply.

CONTROL is where policy lives. VERIFY answers "may this actor do this in principle"; CONTROL answers "is this specific transition permitted right now, and under what conditions."

Failure mode when skipped: arbitrary state jumps, approvals bypassed, duplicate effects from retried requests.

### 3. LOG

Make the action reconstructable after the fact.

Every consequential action writes an append-only record containing at minimum:

- Actor identity and role
- Target type and target identifier
- Action taken
- Reason or justification
- Previous state and new state
- Timestamp
- Request ID (for idempotency and tracing)

Logs are append-only. They are never edited or deleted to "clean up." If a record was wrong, a new corrective entry is written.

Failure mode when skipped: incidents cannot be reconstructed, accountability disappears, customers and regulators cannot be answered.

### 4. DEGRADE SAFE

Define what happens when something fails — because something will.

When a dependency, model call, or downstream service fails, the system must choose a safe behavior on purpose:

- **Block** — refuse the action rather than guess
- **Retry safely** — retry with idempotency so retries do not double-apply
- **Escalate** — route to a human or an incident flow
- **Fall back** — degrade to a reduced but correct behavior

The one unacceptable outcome is **silent damage**: an action that half-completes, applies inconsistently, or fails without anyone knowing.

Failure mode when skipped: partial writes, inconsistent state, failures that surface only when a user is harmed.

## The ordering is not arbitrary

The stages are sequential gates. An action that fails VERIFY never reaches CONTROL. An action that passes CONTROL is always logged. A failure at any stage triggers DEGRADE SAFE rather than an undefined outcome. Skipping a stage does not make the system faster; it moves the failure somewhere less visible.

```text
            ┌─────────┐     pass     ┌─────────┐     pass     ┌─────────┐
 proposal ─▶│ VERIFY  │─────────────▶│ CONTROL │─────────────▶│   LOG   │──▶ committed
            └─────────┘              └─────────┘              └─────────┘
                 │ fail                   │ fail                   │ fail
                 ▼                        ▼                        ▼
            ┌─────────────────────────────────────────────────────────────┐
            │                       DEGRADE SAFE                           │
            │           block · retry safely · escalate · fall back        │
            └─────────────────────────────────────────────────────────────┘
```

## A generic example

An actor requests a state change on a shared record through an AI-assisted workflow.

- **VERIFY** — confirm the actor is authenticated, holds the required role, submitted valid input, and that the record is in an eligible state.
- **CONTROL** — confirm the requested transition is legal; because it affects other users, route it to an approval gate; reject it if the transition is not permitted.
- **LOG** — write actor, target, action, reason, previous and new state, timestamp, and request ID.
- **DEGRADE SAFE** — if the approval service is unreachable, hold the record in its current state and surface the failure rather than applying the change optimistically.

The model may have proposed the change. The machine room decided whether it happened.
