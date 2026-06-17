# The Doctrine

**VERIFY → CONTROL → LOG → DEGRADE SAFE**

This is the operating model of Machine-Room AI. It applies to any action in a software system
that has real-world consequences.

---

## The premise

A model output is a **proposal**, not a **decision**.

When an AI system produces an output — a score, a classification, an extraction, a suggested
action — that output is information. It is not, by itself, permission to change the world. The
moment a system lets a model output directly trigger a consequential action, it has removed the
control layer that makes the system safe, auditable, and trustworthy.

Machine-Room AI reinserts that layer. Every consequential action passes through a "machine
room" with four stages.

---

## What counts as a consequential action?

An action is consequential if it does any of the following:

- **Changes shared state** that other users can see (publishing, approving, status changes).
- **Exposes previously-private data** (revealing contact details, documents, identities).
- **Moves value or entitlements** (payments, credits, refunds, access grants).
- **Grants or removes access** (roles, permissions, account standing).
- **Affects another user's standing or safety** (bans, suspensions, reports, moderation).
- **Triggers an irreversible or external side effect** (sending money, calling a third-party
  API with effects, deleting data).

Reading data, computing a suggestion, or rendering a preview is **not** consequential. The
distinction matters: you do not need a machine room around a search query. You need one around
the action that search query might lead to.

---

## The four stages

### 1. VERIFY — *Should this even be considered?*

Before anything else, establish the preconditions:

- **Who is acting?** Authenticated identity, not an assumption.
- **Are they allowed?** Role and permission to perform *this* action on *this* target.
- **Is the input valid?** Shape, type, and bounds — reject malformed input.
- **Is the current state eligible?** You cannot approve an already-approved item, or reveal
  contact for a request that was declined. The current state must permit the transition.

If VERIFY fails, the action stops here. Nothing downstream runs.

### 2. CONTROL — *What is allowed to happen?*

Given a verified actor and eligible state, decide what may proceed:

- **Which transitions are legal?** Define the state machine explicitly. `pending → approved`
  may be allowed; `rejected → published` may not be.
- **What requires human approval?** Some actions must not be automated. A human gate is a
  deliberate stop where a person decides.
- **What must be blocked?** Some combinations are never allowed, regardless of role.
- **What must be idempotent?** Retried or duplicated requests (double-clicks, webhook
  re-deliveries) must not apply twice. Use idempotency keys.

CONTROL is where "AI proposes, the system decides" is enforced. The model's suggestion enters
here as input; the allowed transition is what leaves.

### 3. LOG — *Can we reconstruct what happened?*

Every consequential action must be recorded so it can be reconstructed later. A complete log
entry answers:

- **Who** performed it (actor id + role)?
- **What** was affected (target type + id)?
- **What changed** (previous state → new state)?
- **Why** (a reason, especially for negative or discretionary actions)?
- **When** (timestamp)?
- **Under which request** (a request/correlation id tying related effects together)?

Logs should be **append-only** — never updated or deleted in place. An audit trail you can edit
is not an audit trail. (See `audit-logs.md`.)

### 4. DEGRADE SAFE — *What happens when something fails?*

Failure is not optional; it will happen. The question is whether failure causes silent damage.
When a dependency is unavailable, a model errors, or validation is uncertain, the system must
do one of:

- **Block** — refuse the action and surface a clear error (fail closed).
- **Retry safely** — with idempotency, so retries don't double-apply.
- **Escalate** — route to a human or a queue when automation can't safely decide.
- **Fall back** — serve a safe default that does not change consequential state.

The forbidden outcome is **silent damage**: an action that half-succeeds, applies twice, or
publishes something unreviewed because a check failed quietly. *Fail closed, not open.*

A concrete rule of thumb: **if the classifier/model that gates an action is unavailable, the
item stays in its safe pending state — it is never auto-approved.**

---

## The flow

```text
            ┌──────────────────────────────────────────────┐
   model    │                MACHINE ROOM                  │
  proposal  │                                              │
 ─────────▶ │  VERIFY ─▶ CONTROL ─▶ LOG ─▶ DEGRADE SAFE     │ ─▶ effect
            │   │          │         │          │           │   (only if every
            │   ▼          ▼         ▼          ▼           │    stage passes)
            │ actor?    legal      append    on failure:    │
            │ allowed?  transition  record   block / retry  │
            │ valid?    approval?   actor,   / escalate /    │
            │ state     idempotent  reason,  fall back       │
            │ eligible? blocked?    state Δ  (never silent)  │
            └──────────────────────────────────────────────┘
```

An action only takes effect if it passes through all four stages. A failure at any stage stops
the action or routes it to a safe outcome.

---

## Humans decide. AI informs.

This is the one-line summary of the doctrine. The model contributes information — a score, a
classification, an extraction. People (or explicit, deterministic rules) make the consequential
decision. The machine room is what keeps that boundary intact under real-world load, edge
cases, and failure.

The rest of this documentation turns the doctrine into concrete, reusable patterns:

- `governance-patterns.md` — the building blocks (verification, moderation, reveal, abuse, ...)
- `audit-logs.md` — the LOG stage in depth
- `rbac.md` — the VERIFY stage's identity and role model
- `approval-workflows.md` — the CONTROL stage's human gates and safe state transitions
