---
name: maintain-verification
description: Audit and repair the repo's verification skill and feature map against the current app — read each mapped feature's source, then drive every feature live. Ends clean, changed, or blocked. Never edits product code.
disable-model-invocation: true
---

# Maintain the verification skill

The feature map is materialised memory that agents trust, so drift is dangerous. Run this regularly (daily via `/schedule` or `/loop`, or after big merges).

1. **Doctor the harness**: run the skill's Launch and Doctor. If they fail, fix the skill (or the CLI in `scripts/`) first — that is in scope.
2. **Source pass** (parallel subagents, read-only, one per feature file): does the feature still exist, are the routes/handles/commands in the file still in the code, are there user-facing features in the code missing from the map?
3. **Live pass** (one agent, sequential): drive every mapped journey with the skill's own instructions and capture evidence.
4. **Classify each discrepancy**:
   - The *skill* is wrong (stale selector, renamed command, new feature unmapped) → fix the skill/CLI/map.
   - The *product* regressed (journey worked before, behaviour is now broken) → report it as a regression with evidence. Never "fix" it by editing the map.
5. **Outcome — exactly one**:
   - `clean`: full coverage, nothing to change.
   - `changed`: one commit/PR of proven corrections, confined to `.claude/skills/verify/` and the control CLI.
   - `blocked`: name the blocker (can't launch, missing credentials…).

**Reply:** the outcome, each correction with its evidence, any product regressions found (with artifacts), coverage (features mapped vs found).
