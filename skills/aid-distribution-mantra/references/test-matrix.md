# Critical Workflow Test Matrix

Select tests by invariant and risk, not by framework convenience. Every selected test must name the authoritative state it asserts.

## 1. Event and Configuration Integrity

- Create, read, update, copy, import, cancel, and restore an event.
- Preserve aid type, quantity, capacity, location, date, local time, time zone, eligibility, invitation window, and redemption policy.
- Round-trip database → API → UI → API without semantic drift.
- Test missing/invalid time zones, daylight-saving transitions, server-zone changes, locale formatting, and UTC date rollover.
- Verify every actor sees the same meaning, not merely the same string.

## 2. Eligibility and Ranking

- Exact documented priority order with stable tie-breaking.
- Zero eligible candidates, insufficient candidates, and excess candidates.
- Fallback/widening thresholds and audit records.
- Deterministic output independent of database row order.
- Missing, stale, conflicting, or partially verified data.
- Protection against hidden manual overrides and unauthorized rating changes.
- Documentation, implementation, and test fixtures agree.

## 3. Invitation Creation and Delivery

- Persisted invitation count equals reported count.
- Queue retry, duplicate delivery, partial batch failure, and worker restart.
- Invitation visible and backend-acceptable during the same window.
- Exact expiry instant before/at/after boundary.
- Mass expiry cannot occur due to time zone, cron, deployment, or config drift.
- Decline, ignore, expire, revoke, resend, and next-wave behavior.
- Alert when intended recipients > 0 but persisted invitations = 0.

## 4. Acceptance, Reservation, and Capacity

- Acceptance validates current invitation and eligibility.
- Double-click, retry, replay, and duplicate message are idempotent.
- N seats produce exactly N active reservations under N+1, 2N, and burst concurrency.
- Capacity and inventory reservation commit atomically.
- Failure between steps rolls back completely or resumes safely.
- Accepted reservation survives invitation expiry, re-ranking, cache clearing, worker rerun, and application restart.
- Oversubscription, undersubscription, waiting-list, cancellation, and release rules reconcile.

## 5. Ticket and Entitlement

- One accepted reservation maps to one durable entitlement.
- Ticket binds correct actor, event, aid type, quantity, and status.
- Repeated generation returns the same entitlement or a controlled rotation, never a duplicate right.
- Cross-account, cross-event, and cross-tenant access is denied.
- Revocation requires explicit authorization, reason, audit, and notification.
- User confirmation wording matches actual operational commitment.

## 6. Credential and Scanner

- Valid QR/barcode/token succeeds through the real scanner endpoint.
- Malformed, tampered, forged, expired, wrong-event, wrong-user, revoked, and replayed credentials fail.
- Credential rotation and temporary-code windows behave at exact boundaries.
- Two scanners racing on one credential produce one redemption.
- Offline/timeout/retry behavior does not create double issue or ambiguous state.
- Scanner validates server-side state and displays sufficient identity/entitlement context.
- Camera denied, unreadable code, poor light, damaged code, and manual fallback are handled safely.

## 7. Redemption and Audit

- Redemption is atomic, idempotent, and one-time.
- Operator identity, device, target, timestamp, event, recipient, entitlement, and outcome are logged.
- Failed scans are distinguishable from successful redemption.
- Reconciliation explains selected, invited, accepted, reserved, ticketed, checked-in, redeemed, cancelled, and expired counts.
- Audit cannot be silently rewritten by normal application users.
- Recovery from crash after physical issuance but before acknowledgement has an explicit procedure.

## 8. Duplicate and Identity Controls

- Exact duplicates after normalization of case, whitespace, punctuation, script variants, and document formatting.
- Near duplicates: one-character changes, transposed fields, reused phone/email/document across accounts.
- Concurrent duplicate registration.
- False-positive and false-negative datasets for probabilistic matching.
- Human review, evidence display, authorization, adverse-action audit, notification, correction, and appeal.
- Biometric data consent/legal basis, access control, encryption, retention, deletion, and breach handling.
- No automatic sanction solely from a similarity score.

## 9. Security and Abuse

- Authorization for event creation, invitation, override, ticket access, scan, redemption, revocation, and audit.
- CSRF, replay, IDOR, enumeration, privilege escalation, mass assignment, and forged callback tests.
- Rate limiting that does not deny legitimate high-load acceptance unfairly.
- Secret/key rotation without invalidating legitimate entitlements unexpectedly.
- PII minimization in logs, QR payloads, analytics, and operator screens.

## 10. Deployment and Runtime

- Enumerate all services, workers, jobs, domains, subdomains, regions, and environments affected.
- Tested commit/build/artifact equals deployed artifact on every target.
- Database migrations, config, feature flags, queues, cron, caches, CDN, and assets are current.
- Contract and smoke tests run against each actual target.
- Mixed-version deployment and rollback compatibility.
- Alert on stale target, version mismatch, zero invitations, mass expiry, stalled acceptance, ticket/reservation mismatch, scan failures, and reconciliation drift.

## 11. Anti-Bypass CI Checks

- Required jobs trigger on every relevant path and branch/event.
- No critical job uses `continue-on-error`, allowed failure, unconditional skip, or silent quarantine.
- Branch protection requires the exact checks.
- Test selection cannot exclude changed critical modules through stale path filters.
- Production code coverage is not replaced by mocks or a test-only route.
- New regression tests are observed failing before the fix.
- Mutation or deliberate-defect checks demonstrate semantic sensitivity.
- Test reports, logs, and artifacts are retained long enough for review.

## 12. Operational and Crowd-Safety Readiness

- Forecast confirmed attendance versus capacity and inventory.
- Alert and escalation thresholds for zero/low acceptance, mass expiry, oversubscription, and scanner outage.
- Safe manual fallback has authorization, duplicate prevention, later reconciliation, and staff instructions.
- Incident communications do not promise unavailable aid.
- Staff can identify authoritative status during partial outage.
- Cancellation or rescheduling flows notify all actors consistently.
