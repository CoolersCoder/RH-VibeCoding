---
name: overnight
description: Contract for long or unattended runs (hours, overnight, /loop, /goal) — a checkable finish predicate, an append-only TSV decision log, explicit stop conditions, and an audited morning report.
argument-hint: "<goal + finish condition + what you may/may not change>"
disable-model-invocation: true
---

# Overnight run

## 0. Earn it first

Only run unattended when all hold; otherwise run while the user watches, and say which is missing:
1. The task has been done once by hand (or watched), so good output is known.
2. You have the same tools and signals the user would use (the `verify` skill, profiler, logs).
3. Every stage can prove its work and stop the line when it misses the bar.
4. Recurring failures from earlier transcripts are already tools, skills or checks.

## 1. Contract (first rows of the decision log)

- **Finish predicate** that can pass or fail: "every test in packages/api passes", "zero callers of OldParser and its file deleted", "p95 < 200 ms on bench X". A duration is not a finish condition. In Claude Code, also set it as `/goal <predicate>` (or rely on the project's Stop hook) so the run can't end early.
- **May change / may not change** from `$ARGUMENTS`. Defaults: no public API/schema changes, no dependency changes, no deleting or loosening tests, no pushing, no `--no-verify`.
- **Isolation**: a fresh branch/worktree (`claude -w <name>`) so nothing collides.
- **Stop and write up why** when: a fix needs something on the may-not list; the same failure survives 3 genuine attempts (write down the shared premise and test it first); an irreversible action or a human-only decision is needed.

## 2. Loop

Each iteration: smallest change the evidence justifies → verify against the predicate on the real artifact (`vibe verify --fast`; full `vibe verify` before each commit) → commit if it advanced, revert if it didn't (no "might help" leftovers) → one log row. A plateau means pivot, not stop. Never relax the predicate, game the gate, skip tests, or add `lint:allow` without a real reason. Mid-run side fixes that serve the goal go in their own commits.

## 3. Decision log

`vibe log <phase> <decision> <why> <evidence> <result>` appends a row to `decisions.tsv` (columns `ts phase decision why evidence result`; evidence is a pointer — commit SHA, `file:line`, artifact path — never prose). Append-only: a wrong call gets a superseding row. Log forks, unit results, pivots, reverts, blockers — not every action. Write rows in plain words a teammate understands.

## 4. Morning report

Before handing back: walk the log against what actually happened in this session and add superseding rows for anything missing or wrong. If possible, have an independent reviewer (a subagent that didn't do the work, ideally another model) read the log and flag weak evidence, skipped verification and risky calls.

```text
Status: DONE | PARTIAL | BLOCKED
Finish predicate: <met / not met — evidence>
Commits: <list>      Discarded: <what and why>
Decisions needing review: <the judgment calls>
Attention: <reviewer flags, or "no flags">
```
