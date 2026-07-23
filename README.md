# Aid Distribution Mantra

A strict Agent Skill for testing and approving changes to high-stakes aid-distribution workflows: event configuration, eligibility, ranking, invitations, reservations, capacity, tickets, QR verification, identity controls, one-time redemption, audit, and multi-target deployment.

The skill is deliberately project-agnostic. It discovers the current system's services, domains, workers, environments, sources of truth, and state transitions instead of relying on hardcoded project names.

## Install

```bash
npx skills add vaoferi/aid-distribution-mantra --skill aid-distribution-mantra
```

Manual locations commonly used by compatible agents:

```text
Codex:          .codex/skills/aid-distribution-mantra/
GitHub Copilot: .github/skills/aid-distribution-mantra/
Claude Code:    .claude/skills/aid-distribution-mantra/
```

Copy the folder `skills/aid-distribution-mantra` into the appropriate location.

## Invoke

Ask the agent to use `aid-distribution-mantra` before changing or approving code that can affect a critical allocation or fulfillment workflow.

Example:

```text
Use aid-distribution-mantra to review this change. Do not declare completion until every gate has fresh evidence.
```

## What it enforces

1. Complete impact map and explicit invariants.
2. Tests that are observed failing for the intended defect.
3. Selection, invitation, expiry, capacity, and concurrency proof.
4. A durable commitment point before showing confirmation.
5. End-to-end credential, scanner, identity, and one-time redemption proof.
6. Exact tested artifact verified on every runtime target.
7. Count reconciliation, falsification attempt, and evidence-based verdict.

## Repository validation

```bash
python -m unittest discover -s tests -p 'test_*.py' -v
```

The repository CI runs the same contract tests on every push and pull request.

## Files

- `skills/aid-distribution-mantra/SKILL.md` — mandatory gates and stop conditions.
- `skills/aid-distribution-mantra/references/test-matrix.md` — comprehensive test families.
- `skills/aid-distribution-mantra/references/evidence-report.md` — completion evidence contract.
- `tests/pressure-scenarios.md` — evaluation scenarios that tempt an agent to bypass the process.
- `tests/test_skill.py` — structural and anti-fragility checks for the skill itself.

## Improvement loop

Changes to the skill should follow RED → GREEN → REFACTOR:

1. Add a pressure scenario that exposes a real agent rationalization.
2. Observe the agent violate or misunderstand the desired rule without the new wording.
3. Change the minimum necessary skill text.
4. Re-run the scenario with the skill and verify compliance.
5. Add a contract test when the requirement is mechanically checkable.

This is deliberate skill optimization through evaluated behavior, not self-modification based on unreviewed agent feedback.

## License

MIT
