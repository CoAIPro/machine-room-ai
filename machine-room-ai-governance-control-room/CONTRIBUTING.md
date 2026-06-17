# Contributing to Machine-Room.AI Governance Control Room

## Purpose

This repo collects reusable governance patterns for AI-powered systems where consequential actions must be verified, controlled, logged, and safely degraded. Contributions extend that pattern library so other teams can build governed AI systems without reinventing the same controls.

## What contributions are welcome

- Reusable governance patterns
- Schemas
- Checklists
- Examples
- Diagrams
- Implementation notes
- Safe state transition examples
- Audit logging examples
- Human approval gate examples

## What not to include

- Private customer data
- Credentials
- API keys
- Production URLs
- Proprietary business logic
- Confidential workflows
- Private prompts
- Regulated or legal claims presented as advice
- Product-specific implementation details

## Writing standards

- Keep examples generic
- Use clear, architecture-first language
- Avoid hype
- Avoid vendor marketing
- Explain what is verified, controlled, logged, and safely degraded
- Prefer practical examples over theory

## Pattern submission checklist

Every pattern should answer:

- What action is being governed?
- Who is allowed to perform it?
- What states are allowed?
- What must be logged?
- What happens if the action fails?
- What abuse or failure mode does this prevent?

## Security and privacy rules

- Never include secrets
- Never include real user data
- Never include production logs
- Never include private system URLs
- Anonymize all examples
- Treat audit examples as synthetic

## Pull request guidance

- Keep PRs focused
- Explain the governance problem being solved
- Map the contribution to at least one doctrine pillar: **VERIFY**, **CONTROL**, **LOG**, or **DEGRADE SAFE**
