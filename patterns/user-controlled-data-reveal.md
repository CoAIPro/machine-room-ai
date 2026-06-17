# Pattern: User-Controlled Data Reveal Workflow

## Intent

Keep sensitive data private by default and expose it only after the user who controls it explicitly approves access. Implements **user-controlled data reveal**.

## Problem

Some data is sensitive enough that it must not be visible just because another party wants it. Exposing it automatically removes the controlling user's agency and creates a privacy and trust failure. The decision to reveal must belong to the data's owner, must be explicit, and must be reversible.

## Solution

Treat reveal as a governed action, not a database read. A requester asks for access; the controlling user approves or denies; on approval the data is exposed under recorded consent; the consent can expire and can be revoked. Every step is logged.

## Actors

- **Requester** — the party who wants access to the data.
- **Controlling user** — the party who owns the data and decides. (**User approves data access.**)
- **System** — enforces that access is impossible without a recorded, current approval.

## States

```text
requested  ──▶  approved  ──▶  revealed (access active)
    │              │                  │
    │              │                  ├──▶  expired
    │              │                  │
    │              │                  └──▶  revoked
    │              │
    │              └──(no approval)
    │
    └──────────▶  denied
```

| State | Access? | Meaning |
|-------|---------|---------|
| `requested` | No | Requester has asked; awaiting the controlling user |
| `approved` | Pending | Controlling user consented; access is being granted |
| `revealed` | Yes | Access is active under recorded consent |
| `denied` | No | Controlling user declined |
| `expired` | No | Consent reached its time limit |
| `revoked` | No | Controlling user withdrew consent |

## Doctrine mapping

- **VERIFY** — Confirm the requester is authenticated and eligible to request. Confirm the approver is the actual controlling user, not a third party. Confirm the request is in a state eligible for the transition.
- **CONTROL** — Access is impossible without a current `approved`/`revealed` consent. Approval authority belongs only to the controlling user. Support expiry and revocation as first-class transitions.
- **LOG** — Record the request, the approval or denial, each actual access under consent, and any expiry or revocation, with actor, target, reason, state change, timestamp, and request ID. Store the *fact* of reveal, never a duplicate copy of the sensitive data.
- **DEGRADE SAFE** — If consent state cannot be confirmed, deny access. Uncertainty resolves to *not revealed*, never to *revealed*.

## Consent properties

- **Explicit.** Silence is not consent; access requires an affirmative approval.
- **Scoped.** Consent covers a specific requester and a specific data scope, not blanket access.
- **Time-bounded.** Consent can expire; expired consent stops granting access automatically.
- **Revocable.** The controlling user can revoke at any time; revocation takes effect immediately.

## Workflow

1. Requester submits a reveal request → `requested` (logged).
2. Controlling user is notified and approves or denies (logged with the user as actor).
3. On approval, access becomes active → `revealed` (logged); each access under that consent is recorded.
4. Consent ends by `expired` or `revoked`; access stops (logged).

## Schema reference

See `schemas/contact_reveal_requests.sql` for the request and consent record, and `schemas/audit_logs.sql` for access and consent history.

## Anti-patterns

- **Reveal-by-default.** Sensitive data visible without the owner's approval.
- **Third-party approval.** Anyone other than the controlling user granting access.
- **Irrevocable consent.** No way to withdraw once granted.
- **Duplicating the data into logs.** Logging the revealed payload instead of the fact of reveal.
- **Fail-open on consent checks.** Granting access when consent state is unknown.

## Checklist

- [ ] Sensitive data is private by default
- [ ] Access requires an explicit, current approval from the controlling user
- [ ] Only the controlling user can approve
- [ ] Consent supports expiry and immediate revocation
- [ ] Each access under consent is logged
- [ ] Unknown consent state resolves to "not revealed"
- [ ] Logs store the fact of reveal, not a copy of the data
