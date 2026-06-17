# Governance Patterns

This document collects the reusable patterns that implement the doctrine
(`VERIFY → CONTROL → LOG → DEGRADE SAFE`) for common consequential actions. Each pattern is
stack-agnostic: it describes the states, transitions, gates, and logged fields, not a specific
database or framework.

Each pattern answers five questions:

1. **What action is governed?**
2. **Who may perform it?** (VERIFY)
3. **What states/transitions are allowed?** (CONTROL)
4. **What is logged?** (LOG)
5. **What failure mode does it prevent?** (DEGRADE SAFE)

---

## Pattern 1 — Verification Queue

**Governs:** admitting an entity (a vendor, employer, seller, provider) into the system before
it can act.

**Who may perform it:** an admin/reviewer role. The entity cannot verify itself.

**States & transitions:**
```
pending_review ──▶ verified
pending_review ──▶ rejected
pending_review ──▶ needs_more_info ──▶ pending_review
verified ──▶ suspended ──▶ (reinstated) verified
verified ──▶ revoked
```
- New entities **always** start in `pending_review`. There is no auto-verification.
- Only a `verified` entity may perform privileged actions (e.g. publishing).
- Negative/discretionary transitions (`rejected`, `needs_more_info`, `suspended`, `revoked`)
  **require a reason**.

**Logged:** actor, entity id, previous status → new status, reason, timestamp, request id.

**Prevents:** unvetted entities acting on real users; "verified" meaning nothing; silent
reinstatement of a bad actor.

**Signals to capture during review:** mismatches worth surfacing to the reviewer (e.g. an
entity claiming to be a business but using a personal/free email domain; a name that does not
match the domain). The system *flags*; the human *decides*.

---

## Pattern 2 — Moderation Queue

**Governs:** making user-submitted content (a listing, a post, a job) visible to others.

**Who may perform it:** an admin/moderator role. The author may submit but not self-approve.

**States & transitions:**
```
pending_review ──▶ approved
pending_review ──▶ rejected
pending_review ──▶ changes_requested ──▶ pending_review
approved ──▶ unpublished (─▶ pending_review)
rejected ──▶ reopened (─▶ pending_review)
```
- New content **always** starts `pending_review`.
- Content is visible to others **only** when `approved`.
- Risky transitions (`rejected`, `changes_requested`, `unpublished`) **require a reason**.
- **Status-specific actions only**: never offer an action that repeats the current status
  (no "approve" on an already-approved item). The available actions are a function of the
  current state.

**Double gate:** content should be visible only if it is `approved` **and** its author entity
is `verified`. Both conditions, enforced at the data layer, not just the UI.

**Logged:** actor, content id, previous status → new status, reason, timestamp, request id.

**Prevents:** unreviewed content reaching users; spam/abuse slipping through; an approved
listing from an unverified or suspended entity remaining visible.

---

## Pattern 3 — User-Controlled Data Reveal (Consent)

**Governs:** exposing one user's private data (contact details, documents, identity) to
another party.

**Who may perform it:** the **data owner** approves each reveal. No one else — not even an
admin — can release the data without the owner's consent.

**The three visibility layers:**
```
1. Match / discovery   → the subject is visible but REDACTED
                         (private fields stripped from the response)
2. Interest expressed  → a request is recorded; data STILL hidden
3. Reveal approved     → the owner approves THIS request;
                         only now is the private data returned
```
- Private fields are **redacted by default** at the data layer — the API never returns them
  for a non-approved viewer.
- A reveal request is reviewed **individually** by the owner. Approval is per-request, never
  blanket, never automatic.
- The reveal endpoint **checks for an approved request before returning any private field.**

**Logged:** request created (by whom, for whom), owner decision (approved/declined), timestamp,
request id.

**Prevents:** private data leaking before consent; "request" silently behaving like "access";
bulk exposure of user data.

---

## Pattern 4 — Abuse Reporting & Escalation

**Governs:** letting users report content/behavior and routing it to resolution.

**Who may perform it:** any user may file a report; an admin/reviewer resolves it.

**States & transitions:**
```
open ──▶ reviewing ──▶ action_taken
open ──▶ reviewing ──▶ dismissed
```
- Resolution transitions (`dismissed`, `action_taken`) **require a reason/note**.
- A report can trigger a re-review of the reported item (feeding back into the moderation
  queue), independently of the item's current status.

**Logged:** report received (reporter, target, reason), each transition (actor, decision,
note), timestamp, request id.

**Prevents:** reports vanishing without record; resolutions with no accountability; reported
content staying live with no re-review.

---

## Pattern 5 — Role-Based Access Control (RBAC)

**Governs:** which actor may perform which action. This is the VERIFY stage's backbone.

**Core rules:**
- Every user has a **role**, assigned at account creation and stored as the source of truth.
- **Every** privileged endpoint checks the role **before** business logic — server-side, not
  just hidden in the UI.
- **Surface locking**: a user is locked to the surface/portal matching their role on *every*
  entry (page load, OAuth redirect, callback) — not only at login.
- **Cross-role protection**: an account may not act through a surface that doesn't match its
  role.

(See `rbac.md` for the full model.)

**Prevents:** privilege escalation; an actor of one role performing another role's actions;
UI-only checks being bypassed by calling the API directly.

---

## Pattern 6 — Safe State Transitions

**Governs:** every status change in the system. This is the connective tissue under the
queues above.

**Core rules:**
- Define the state machine **explicitly**. Enumerate allowed transitions; everything else is
  denied by default.
- Validate **current state eligibility** before transitioning (VERIFY), then apply only an
  allowed transition (CONTROL).
- Make transitions **idempotent** where retries are possible (idempotency key / event id), so
  a duplicate request does not double-apply.

(See `approval-workflows.md` for human gates layered on top of transitions.)

**Prevents:** illegal jumps (e.g. `rejected → published`); double-application from retries;
inconsistent state from concurrent updates.

---

## Pattern 7 — Audit Logging

**Governs:** the LOG stage for every consequential action.

**Core rules:**
- **Append-only.** Entries are never updated or deleted; enforce this at the data layer.
- Every entry captures: actor id, actor role, target type, target id, previous status, new
  status, reason, timestamp, request id.
- The log is **queryable and human-readable** — a reviewer can reconstruct any action.

(See `audit-logs.md` for the full schema and rationale.)

**Prevents:** unaccountable actions; tampered history; inability to answer "who did this, when,
and why?"

---

## Pattern 8 — Degrade-Safe Architecture

**Governs:** behavior under failure for every consequential action.

**Core rules:**
- **Fail closed.** If a gating check (model, classifier, dependency) is unavailable, the action
  does not proceed to a consequential state — the item stays safely pending.
- **Validate model output** before acting on it; on malformed output, retry a bounded number
  of times, then fall back.
- **Idempotent retries** so transient failures can be retried without double effects.
- **Escalate** to a human/queue when automation cannot safely decide.

**Prevents:** silent damage; auto-publishing unreviewed content when a check fails; crashes that
leave state half-changed.

---

## How the patterns compose

A single real action usually uses several patterns at once. For example, an employer publishing
a job in a marketplace:

- **RBAC** (Pattern 5) verifies the actor is an employer.
- **Verification Queue** (Pattern 1) requires the employer to be `verified` first.
- **Moderation Queue** (Pattern 2) holds the job `pending_review` until an admin approves it.
- **Safe State Transitions** (Pattern 6) governs each status change.
- **Audit Logging** (Pattern 7) records every step.
- **Degrade Safe** (Pattern 8) keeps the job pending if the review step's tooling is down.

See `examples/transferly-example.md` for this exact composition, end to end.
