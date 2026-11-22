---
name: verify
description: Verify a change in {{PROJECT_NAME}} with fresh evidence before calling it done or committing — run the vibe gate, then launch and drive the real app to prove the changed behaviour. Returns VERIFIED, NOT VERIFIED, or INCONCLUSIVE.
when_to_use: After changing code, before a commit, or when asked "does it work", "verify this", "prove it", "repro this", "did this fix it".
---

# Verify {{PROJECT_NAME}}

<!-- vibe L1 template. Run /vibe-core:create-verification to replace every TODO with this repo's real recipe and prove it
     end to end; run /vibe-core:maintain-verification regularly to keep it honest. A skill that was never executed is a
     draft. This file is read cold, mid-task, by an agent that has never seen the app: exact commands, no examples. -->

Verification proves or disproves one claim with evidence. "It builds" and "tests pass" are not proof that behaviour changed.

## 0. Claim

One falsifiable sentence: condition → observable result. For a refactor: "behaviour unchanged" plus the checks that cover it.

## 1. Gate

```bash
vibe verify          # .vibe/verify.conf steps; a full pass stamps .vibe/state/verified
vibe verify --fast   # inner loop only; doesn't count
```

Fix failures; never weaken a check. Lint exception = `lint:allow <rule> <reason>` on that line.

## 2. Launch

<!-- The exact command that brings the app to a USABLE state from an empty data dir (migrations, seed data, test user),
     how to tell it's ready (a log line / prompt / health check that means usable, not just "process answers"), and
     isolation: can two instances run side by side (ports, data dirs, profiles)? If not, say so — never double-drive. -->
```bash
TODO
```
Ready when: TODO

## 3. Doctor

<!-- One read-only check: is this instance worth driving? Process up, right build, port owned by us, auth valid. -->
```bash
TODO
```

## 4. Drive

<!-- The harness with REAL handles from this repo: a small control CLI (preferred — e.g. scripts/{{PROJECT_NAME}}ctl
     with doctor / snapshot / screenshot / click / type / send / trace / cleanup), Playwright/CDP for web & Electron,
     tmux/PTY for CLI/TUI, curl for services, simctl/adb for mobile. Stable handles (ARIA labels, data attributes,
     routes, prompt strings) over coordinates. Per-feature journeys live in features/. -->
- TODO

## 5. Evidence

- Capture the action AND the resulting state; check side effects (rows written, files, messages) as well as what's visible.
- Exercise the real user path, not internal setters or test-only endpoints. Mocks only where production already isolates the external system.
- Visual changes: baseline (before) and treatment (after), same inputs, realistic data (real images, long text, empty and error states).
- Artifacts go to: TODO (e.g. `/tmp/{{PROJECT_NAME}}-qa/<claim-slug>/`) and must survive cleanup. Look at screenshots yourself.

## 6. Cleanup

<!-- Kill only what you started (never by process name); remove scratch state; keep the evidence. -->
```bash
TODO
```

## 7. Verdict

```text
VERIFIED | NOT VERIFIED | INCONCLUSIVE
Claim: <falsifiable claim>
Evidence: <command> → <result>; <artifact path> → <what it shows>
Not covered: <device / production / human-only parts>
```

- `VERIFIED`: evidence shows the claimed result on the same surface the bug/feature lives on, no obvious confound.
- `NOT VERIFIED`: unchanged, wrong, or a check fails. Say it plainly.
- `INCONCLUSIVE`: no valid evidence (external service down — quote the log line; no baseline; wrong surface). Inconclusive is not a pass.

When this skill says green but the product is still wrong: observe, diagnose, fix this skill.

<!-- Device-/prod-only behaviour (never claim from a simulator or mocks): TODO -->
