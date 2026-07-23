---
name: aid-distribution-mantra
description: Use when changing code that may affect high-stakes aid allocation, eligibility, invitations, reservations, capacity, event time, tickets, QR verification, identity checks, audit trails, or deployment across multiple services and environments.
---

# Aid Distribution Mantra

## Overview

High-stakes distribution software can turn a small defect into denied aid, unsafe crowds, legal exposure, or danger to staff. Treat every user-visible confirmation as an operational commitment and every state transition as a safety boundary.

**Core principle:** No critical workflow claim without end-to-end evidence from source of truth to the exact deployed target.

**Violating the letter of this process is violating its spirit.**

## The Iron Law

```text
NO NEXT GATE WITHOUT FRESH, REVIEWABLE EVIDENCE FROM THE PREVIOUS GATE
```

A passing unit test, successful merge, HTTP 200, green deployment job, or UI screenshot is never sufficient by itself.

## When to Use

Use this skill before modifying or approving changes that can influence:

- event date, time, time zone, location, capacity, inventory, or aid type;
- eligibility, ranking, invitations, expiration, acceptance, waiting lists, or reservations;
- tickets, QR/barcode credentials, check-in, redemption, or issuance records;
- identity, duplicate detection, sanctions, biometrics, or appeals;
- queues, cron jobs, caches, APIs, databases, admin panels, user portals, scanners, notifications;
- CI/CD, infrastructure, domains, subdomains, services, workers, or environment-specific deployment.

Do not hardcode a known domain or architecture. Discover the actual targets and boundaries in the current project.

## Required Opening Statement

Before changing code, say aloud and fill in every field:

```text
Critical workflow: <name>
Human harm if wrong: <specific consequence>
Source(s) of truth: <database/config/service>
State path: <creation → selection → invitation → acceptance → ticket → verification → redemption → audit>
Affected actors: <organizer/operator/recipient/other>
Affected targets: <all apps, services, workers, domains, environments>
Capacity/inventory invariant: <exact rule>
Time invariant: <exact date/time/time-zone rule>
Commitment point: <the action after which the system owes the user fulfillment>
Unknowns or conflicts: <none, or list>
```

If any field is unknown, inspect documentation, code, infrastructure, and existing tests. If authoritative sources conflict, STOP and ask the human owner to resolve the conflict. Do not choose a convenient interpretation.

## Gate 1 — Map Impact and Invariants

Identify every component that can read, transform, cache, schedule, display, or enforce the changed data. Include hidden paths: background workers, retries, notification jobs, scanner endpoints, replicas, feature flags, and deployment targets.

For each critical value, state:

- source of truth;
- permitted transformations;
- forbidden outcomes;
- who relies on it;
- what evidence would disprove correctness.

**Say aloud:** “I have mapped the complete workflow and listed the invariants and falsifiers.”

**Evidence:** impact map, state machine, target inventory, source-of-truth table, documentation/code/test conflicts.

**STOP:** No implementation until the map covers the full workflow and every potentially affected target.

## Gate 2 — Design Tests That Can Fail for the Right Reason

Write or identify tests before implementation. Every critical invariant needs:

1. positive test — valid path succeeds;
2. negative test — invalid or unauthorized path fails;
3. boundary test — exact limit, expiry instant, time-zone edge, zero candidates;
4. concurrency/idempotency test — duplicate requests, retries, simultaneous acceptance or redemption;
5. reconciliation test — counters equal authoritative records;
6. end-to-end test — real production route across component boundaries;
7. deployment smoke test — exact deployed build on every required target.

Prove the tests are not decorative:

- observe each new regression test fail before the fix;
- assert durable state and externally observable behavior, not only status codes or mock calls;
- verify tests exercise production wiring, not a parallel test-only implementation;
- reject skipped, quarantined, `allow_failure`, non-blocking, path-filtered, or silently retried critical checks;
- use mutation testing or a deliberate temporary defect when practical to prove the suite detects semantic breakage.

**Say aloud:** “I have shown how each test fails when its invariant is broken.”

**Evidence:** failing outputs, test-to-invariant matrix, CI trigger and blocking-policy review.

**STOP:** A test that has never caught the intended defect is not evidence.

## Gate 3 — Prove Selection, Invitations, Capacity, and Expiry

Trace the authoritative lifecycle, regardless of local naming:

```text
eligible → selected → invited → viewed → declined/ignored/expired → accepted → reserved → ticketed
```

Required invariants:

- expected capacity and available inventory are explicit and consistent;
- zero candidates or too few candidates cannot silently produce a “successful” run;
- fallback or widening rules are documented, tested, audited, and do not change priority secretly;
- invitation counts reflect persisted invitation records, not queued intentions;
- acceptance is atomic and idempotent;
- active reservations/tickets never exceed capacity or inventory;
- invitation expiry cannot invalidate an already accepted reservation;
- UI, API, database, jobs, and notifications agree on status and expiry;
- ranking follows the authoritative specification and cannot change unnoticed.

**Say aloud:** “At maximum contention, the system creates no more and no fewer valid reservations than the rules permit.”

**Evidence:** zero-candidate test, ranking fixtures, expiry boundary tests, oversubscription race test, exact count reconciliation.

**STOP:** If capacity is 100 and no test proves the 101st concurrent acceptance cannot succeed, do not proceed.

## Gate 4 — Prove the Commitment Point

Define the exact user action after which the system has promised fulfillment. The success response must be emitted only after one atomic operation has:

- validated invitation and eligibility;
- reserved capacity and inventory;
- created a durable ticket/entitlement;
- bound it to the correct actor and event;
- written an audit record.

After this point, ordinary expiry jobs, re-ranking, cache clearing, retries, deployments, or recalculation must not silently revoke the entitlement.

Cancellation or revocation requires an explicit policy, authorization, reason, audit trail, user communication, and—where relevant—legal review.

**Say aloud:** “A displayed confirmation corresponds to a durable, auditable entitlement, not an optimistic UI state.”

**Evidence:** transaction test, retry test, persistence-after-restart test, cross-device test, revocation-policy test.

**STOP:** If the user can see “confirmed” without a durable entitlement, classify it as a critical incident.

## Gate 5 — Prove Credential, Identity, and One-Time Redemption

Test the entire credential chain:

```text
accepted → ticket created → credential generated → credential displayed → scanner reads → server validates → operator sees correct entitlement → redemption commits once → audit reconciles
```

Required proof includes:

- valid credential succeeds for the correct event, person, entitlement, and validity window;
- malformed, forged, expired, wrong-event, wrong-person, revoked, and replayed credentials fail safely;
- two scanners cannot redeem one entitlement twice;
- network timeout or retry cannot create ambiguous “issued or not issued” state;
- scanner trusts server-side current state, not merely decoded client data;
- operator UI presents enough information to prevent mistaken issuance without exposing unnecessary personal data.

Duplicate and identity systems are decision support, not automatic guilt engines. No automatic sanction solely from a similarity score. Document normalization rules and test exact and near duplicates. Face similarity or other biometric matching must be measured for false positives/negatives, require authorized human review for adverse action, preserve auditability and appeal, and receive privacy/legal review.

**Say aloud:** “I proved both the valid path and the anti-paths: invalid credentials fail, replay fails, and the correct entitlement redeems exactly once.”

**Evidence:** E2E scanner run, replay race test, forged credential tests, identity decision audit tests.

**STOP:** A generated QR image is not proof that redemption works.

## Gate 6 — Prove Delivery to Every Runtime Target

Discover targets from repository and infrastructure evidence: workflows, manifests, service maps, environment configs, routing, DNS, container/task definitions, worker configs, and deployment scripts.

For every affected target, record:

- expected commit/build/artifact identity;
- actual deployed identity;
- migration/config/cache status;
- target-specific smoke result;
- relevant logs or traces.

Tested SHA must equal deployed SHA. Main-domain success does not imply portal, admin, scanner, worker, API, or another environment was updated.

**Say aloud:** “The exact tested artifact is running and verified on every required target.”

**Evidence:** deployment matrix, build identifiers, target-by-target smoke output, logs/traces.

**STOP:** Any missing, stale, unknown, or unverified target means the change is not complete.

## Gate 7 — Reconcile, Challenge, and Declare a Verdict

Reconcile authoritative counts across the full path:

```text
selected / invited / accepted / reserved / ticketed / checked-in / redeemed / cancelled
```

Explain every difference. Run the highest-risk scenario again on the deployed system. State what would disprove the conclusion and attempt that disproof.

Finish with exactly one verdict:

- `PASS — evidence complete`
- `BLOCKED — missing evidence: ...`
- `FAIL — invariant violated: ...`

Use the report format in `references/evidence-report.md`.

**Say aloud:** “My verdict follows the evidence; green tooling does not overrule a violated invariant.”

**Evidence:** completed evidence report, reconciled counts, deployed-system rerun, attempted falsifier, remaining uncertainty.

**STOP:** Never use “done”, “fixed”, “safe”, or “deployed” without the completed evidence report.

## Minimum Test Families

Read `references/test-matrix.md` and select every applicable family. Omitting a family requires a written, project-specific reason and human approval. “Not enough time” is not a reason.

## Red Flags — Stop and Return to the Last Gate

- “The unit tests pass, so the flow is safe.”
- “The UI shows the right count.”
- “It only fails at an unlikely concurrency level.”
- “The invitation is visible, so it must be active.”
- “The QR renders, so scanning works.”
- “The deploy job was green.”
- “The main domain works.”
- “We can correct affected users manually.”
- “This check is flaky, so mark it non-blocking.”
- “The biometric score is high enough to punish automatically.”
- “We can test the full path after release.”

All mean: STOP. Produce evidence or block the change.

## Rationalizations and Reality

| Rationalization | Reality |
|---|---|
| “This change is far from the critical path.” | Map transitive dependencies; distance is not proof of isolation. |
| “Existing tests cover it.” | Name the invariant and show the test fail when it breaks. |
| “Only one request happens at a time.” | Production concurrency is an input, not a hope. |
| “The queue reported success.” | Reconcile persisted results with intended work. |
| “Expiry is obvious.” | Test exact instants, time zones, jobs, and accepted-state immunity. |
| “A rollback can fix it.” | A rollback cannot unpromise aid or undo crowd risk. |
| “Manual review will catch duplicates.” | Prove the review path, audit, permissions, and appeal. |

## Legal and Human-Safety Boundary

This skill does not determine legal rights. It requires qualified review when changes affect user-facing promises, cancellation, sanctions, identity/biometric processing, data retention, discrimination risk, or access to essential aid. Technical success cannot waive legal or operational obligations.
