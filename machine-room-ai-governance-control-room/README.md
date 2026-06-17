# Machine-Room.AI Governance Control Room

A practical open-source framework for building governance control rooms inside AI-powered products.

Modern AI systems do not fail only when models are wrong. They fail when actions are not verified, state transitions are uncontrolled, decisions are not logged, and failures are allowed to happen silently.

The Governance Control Room provides reusable patterns for:

- Admin and owner controls
- Identity and role control
- Verification queues
- Moderation queues
- Human approval gates
- Audit logs
- Abuse reporting
- Role-based access control
- Safe state transitions
- Controlled data reveal workflows
- Safe failure and escalation

## Core doctrine

**VERIFY → CONTROL → LOG → DEGRADE SAFE**

AI should not move directly from prediction to action. Every consequential action passes through a machine room:

- **VERIFY** — Who is acting? Are they allowed? Is the input valid? Is the current state eligible?
- **CONTROL** — What transitions are allowed? What requires approval? What must be blocked?
- **LOG** — Can the action be reconstructed later with actor, target, reason, status change, timestamp, and request ID?
- **DEGRADE SAFE** — If something fails, does the system block, retry safely, escalate, or fall back without silent damage?

## What this is

A control layer for AI-powered systems where risky actions are reviewed, approved, rejected, logged, and safely reversed before they affect real users.

This is not a prompt library. It is an operating pattern for real-world AI products that need admin control, auditability, moderation, approvals, and safe failure behavior.

## What this is not

- Not a model or an inference library
- Not a managed service
- Not stack-specific — the patterns are portable
- Not a replacement for your domain logic — it governs it

## Where it applies

High-trust marketplace workflows, insurance and compliance platforms, AI agents that call tools with side effects, document review pipelines, healthcare administrative workflows, finance and payments workflows, customer support automation, vendor onboarding, procurement approvals, and other regulated workflow systems.

## Core modules (v0.1)

1. Identity & Role Control
2. Admin / Owner Control Panel
3. Verification Queue
4. Moderation Queue
5. Human Approval Gate
6. Audit Logs
7. User-Controlled Data Reveal Workflow
8. Abuse Reporting
9. Safe State Transitions
10. Incident / Escalation Flow

## Repository layout

```text
machine-room-ai-governance-control-room/
  README.md
  LICENSE
  CONTRIBUTING.md
  docs/
    01-doctrine.md
    02-governance-control-room.md
    03-control-room-modules.md
    04-state-transitions.md
    05-audit-logging.md
    06-human-approval-gates.md
    07-safe-degradation.md
    08-implementation-guide.md
  patterns/
    admin-control-room.md
    verification-queue.md
    moderation-queue.md
    user-controlled-data-reveal.md
    abuse-reporting-workflow.md
    audit-log-pattern.md
    role-based-access-control.md
    idempotent-admin-actions.md
    safe-state-transition.md
  schemas/
    audit_logs.sql
    admin_actions.sql
    verification_reviews.sql
    moderation_reviews.sql
    contact_reveal_requests.sql
    abuse_reports.sql
    role_permissions.sql
  checklists/
    governance-control-room-checklist.md
    admin-action-checklist.md
    launch-readiness-checklist.md
    rbac-test-checklist.md
    audit-log-checklist.md
    safe-degradation-checklist.md
  examples/
    marketplace-listing-moderation.md
    entity-verification-example.md
    user-data-reveal-example.md
    abuse-report-resolution-example.md
    ai-agent-tool-approval-example.md
  diagrams/
    governance-control-room-flow.md
    verify-control-log-degrade-safe.md
    human-approval-gate.md
```

## Status

**v0.1** — initial pattern set. The ten files below are the starter set; the remaining files in the layout are placeholders to be filled in subsequent iterations.

Starter set:

| File | Purpose |
|------|---------|
| `README.md` | Entry point, doctrine, modules, layout |
| `docs/01-doctrine.md` | The operating model in full |
| `docs/02-governance-control-room.md` | What a control room is and its modules |
| `patterns/verification-queue.md` | Entity verification pattern |
| `patterns/moderation-queue.md` | Listing moderation pattern |
| `patterns/audit-log-pattern.md` | Append-only audit pattern |
| `patterns/user-controlled-data-reveal.md` | User-controlled data reveal pattern |
| `schemas/audit_logs.sql` | Append-only audit log schema |
| `checklists/governance-control-room-checklist.md` | Per-action governance checklist |
| `examples/marketplace-listing-moderation.md` | End-to-end worked example |

## How to use this framework

1. Read `docs/01-doctrine.md` to understand the operating model.
2. Identify which actions in your system change state, expose data, move value, or affect other users.
3. Route each consequential action through the four doctrine stages using the patterns in `patterns/`.
4. Adopt the schemas in `schemas/` as a starting point and adapt column names to your domain.
5. Run the checklists in `checklists/` before launch and before adding any new admin action.

## Disclaimer

This framework is reference architecture. It is not legal, security, compliance, regulatory, or professional advice. Teams are responsible for validating implementation details for their own domain, jurisdiction, security posture, and risk profile.

## License

See `LICENSE`. This framework is published as reusable reference architecture.

## Contributing

See `CONTRIBUTING.md`. Contributions that add patterns, schemas, checklists, or worked examples are welcome. Keep all examples generic and free of any production data.

---

> Governed AI systems need a control room, not just a model.
