# Aid Distribution Mantra Design

## Purpose

Create a reusable Agent Skill that prevents code changes from silently breaking high-stakes aid allocation and fulfillment workflows. It must be independent of any single domain, framework, or deployment topology while remaining strict enough for systems where a false confirmation can deny aid, create crowd conflict, expose operators to danger, or create legal/privacy risk.

## Design choice

Use a compact discipline-enforcing `SKILL.md` with seven sequential evidence gates. Move the comprehensive test catalogue and completion report into reference files so agents can load detail when executing a gate without diluting the core process.

Rejected alternatives:

1. A project-specific checklist: strong for one installation but fragile when domains, services, or business rules change.
2. A generic testing guide: portable but too easy to satisfy with unit tests and green CI while missing deployment, state transitions, and human commitments.

## Core workflow

1. Map the entire critical path, actors, targets, sources of truth, and invariants.
2. Design tests that demonstrate failure before implementation and resist semantic bypass.
3. Prove selection, invitations, expiry, capacity, concurrency, and reconciliation.
4. Define and prove the commitment point that creates a durable entitlement.
5. Prove credential generation, invalid paths, identity controls, scanning, and one-time redemption.
6. Verify the exact tested artifact on every runtime target.
7. Challenge the conclusion and issue a constrained evidence verdict.

Each gate requires an aloud statement, named evidence, and a STOP condition. No gate can be skipped because another tool is green.

## Safety and legal boundaries

User-facing confirmation is treated as an operational commitment. Cancellation, sanctions, biometric processing, discrimination risk, and access to essential aid require explicit policy and qualified legal/privacy review. Probabilistic identity matching may flag cases for review but cannot automatically establish guilt or impose adverse action.

## Anti-fragility

The skill forbids hardcoded project domains. Agents discover targets from repository and infrastructure evidence. Contract tests ensure the core skill remains project-neutral and keeps all required gates, verdicts, and anti-bypass concepts.

## Skill evaluation

Pressure scenarios cover stale deployment targets, silent zero invitations, expiry races, oversubscription, QR-only testing, biometric false positives, non-blocking race tests, and unsupported user promises. Future changes add scenarios first, then minimum wording and mechanical contract tests.
