# Aid Distribution Mantra Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish a reusable, evidence-gated Agent Skill for high-stakes aid-distribution code changes.

**Architecture:** Keep the sequential control process in `SKILL.md`; place the exhaustive test catalogue and evidence template in references. Validate structure and project neutrality with dependency-free Python contract tests in GitHub Actions.

**Tech Stack:** Agent Skills Markdown/YAML frontmatter, Python 3.12 `unittest`, GitHub Actions.

## Global Constraints

- No hardcoded project domains or service names in the core skill.
- Every gate includes an aloud checkpoint, evidence requirement, and STOP condition.
- Completion verdict is restricted to PASS, BLOCKED, or FAIL forms.
- Critical tests cannot be treated as non-blocking or satisfied by status codes alone.

---

### Task 1: Define pressure tests and behavior contract

**Files:**
- Create: `tests/pressure-scenarios.md`
- Create: `docs/superpowers/specs/2026-07-23-aid-distribution-mantra-design.md`

- [ ] Add scenarios for stale deployment, zero invitations, expiry race, oversubscription, QR chain, biometric review, flaky bypass, and unsupported reservation promise.
- [ ] Record the required stop-and-evidence behavior for each scenario.
- [ ] Commit the design and scenarios.

### Task 2: Implement the core skill and references

**Files:**
- Create: `skills/aid-distribution-mantra/SKILL.md`
- Create: `skills/aid-distribution-mantra/references/test-matrix.md`
- Create: `skills/aid-distribution-mantra/references/evidence-report.md`

- [ ] Add valid frontmatter and discovery triggers.
- [ ] Implement seven sequential gates with spoken statements, evidence, and STOP conditions.
- [ ] Add anti-bypass CI requirements, rationalization counters, legal/privacy boundary, and project-neutral target discovery.
- [ ] Add the comprehensive test matrix and completion evidence report.

### Task 3: Add mechanical validation

**Files:**
- Create: `tests/test_skill.py`
- Create: `.github/workflows/validate-skill.yml`

- [ ] Test required files and frontmatter.
- [ ] Test absence of project-specific domain tokens.
- [ ] Test all seven gates and their required checkpoint fields.
- [ ] Test required safety phrases and reference links.
- [ ] Run `python -m unittest discover -s tests -p 'test_*.py' -v`; expect all tests to pass.

### Task 4: Publish usage documentation

**Files:**
- Create: `README.md`
- Create: `LICENSE`

- [ ] Document installation, invocation, repository validation, file layout, and evaluated improvement loop.
- [ ] Add MIT license.
- [ ] Fetch the committed files from GitHub and rerun the local contract tests against identical content.
