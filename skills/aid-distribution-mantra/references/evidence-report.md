# Critical Workflow Evidence Report

Complete this report before claiming completion.

## 1. Change and Risk

- Change/commit:
- Critical workflow:
- Human harm if wrong:
- Legal/privacy review required: yes/no — reason:
- Highest-risk invariant:

## 2. Impact Map

| Component/target | Role in workflow | Affected? | Evidence |
|---|---|---:|---|

## 3. Sources of Truth and Invariants

| Value/state | Source of truth | Required invariant | Falsifier attempted | Result |
|---|---|---|---|---|

## 4. State Path

```text
<authoritative lifecycle here>
```

- Commitment point:
- Expiry semantics:
- Capacity/inventory semantics:
- Revocation semantics:

## 5. Test Evidence

| Invariant | Positive | Negative | Boundary | Concurrency/idempotency | E2E | Result/artifact |
|---|---:|---:|---:|---:|---:|---|

### Anti-bypass review

- New regression test observed failing before fix:
- Deliberate defect or mutation detected:
- Critical checks blocking in CI:
- Skips/allowed failures/path-filter gaps:

## 6. Count Reconciliation

| selected | invited | accepted | reserved | ticketed | checked-in | redeemed | cancelled | expired |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|

Explain every non-obvious difference:

## 7. Deployment Evidence

| Target | Expected artifact | Actual artifact | Config/migration/cache | Smoke/E2E evidence | Result |
|---|---|---|---|---|---|

## 8. Credential and Redemption Proof

- Valid credential:
- Invalid/tampered credential:
- Wrong event/person:
- Expired/revoked credential:
- Replay/double-scan race:
- Network timeout/retry:
- One-time redemption audit:

## 9. Identity/Duplicate Controls

- Deterministic duplicate tests:
- Probabilistic matcher metrics, if used:
- Human review and appeal:
- Privacy/security evidence:

## 10. Challenge the Conclusion

- What would disprove correctness?
- What was done to produce that failure?
- Result:
- Remaining uncertainty:

## 11. Verdict

Choose exactly one:

- `PASS — evidence complete`
- `BLOCKED — missing evidence: ...`
- `FAIL — invariant violated: ...`
