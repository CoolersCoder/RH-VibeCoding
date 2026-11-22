---
name: review
description: Strict two-pass review of the current branch or a commit range — correctness (high-confidence bugs only) then structure (simpler shapes, file size, scattered special cases). Read-only unless asked to fix.
argument-hint: "[base-ref or range, default main...HEAD]"
disable-model-invocation: true
---

# Review

Review `git diff ${ARGUMENTS:-main...HEAD}` plus uncommitted changes; read `git log` for intent and the surrounding code before judging. Read the project's `CLAUDE.md` and the `.claude/rules/` that match the changed paths — project rules override generic taste. Don't edit files unless asked.

The reviewer must not be the author. If you wrote this change in this session, don't review it yourself: hand it to the `reviewer` subagent or Claude Code's `/code-review` (a fresh context that never saw the reasoning), ideally also a different model, and report what they find. A reviewer asked to find problems always finds something — skip style, and keep only findings you can defend from the code (or prove with a run).

## Pass 1 — correctness (report only what you can defend)

1. Logic errors, edge cases (empty, nil/null, zero, max, unicode, time zones), off-by-one.
2. Concurrency: races, results applied after the user/request moved on, tasks never cancelled, blocking work on the UI/main thread or event loop.
3. Data: persisted shapes still readable by older versions, migrations reversible/idempotent, cache keys/invalidation, nothing stored that shouldn't be (empty results, secrets).
4. Contracts: public APIs, schemas, events, cross-repo interfaces — breaking changes called out with a migration path.
5. Security: injection, authz checks on every new entry point, secrets in code/logs, unsafe deserialization, SSRF.
6. Resource leaks: listeners, timers, connections, file handles, subscriptions.
7. Honest state: errors surfaced to the user; nothing shown as done/saved/synced when it isn't; no silent fallback to fake data.
8. Tests/verification: does the evidence actually exercise the change?

Pre-existing bugs found on the way count — list them separately. No speculation.

## Pass 2 — structure (be demanding, be concrete)

- **Code judo**: is there a reframing that makes branches, helpers, modes or layers disappear? Propose it concretely.
- A file pushed past ~1000 lines, or a function past what fits on a screen → propose the split.
- New ad-hoc `if`s in unrelated flows → missing model/policy object.
- Logic in the wrong layer (I/O in views, feature logic in shared code), bespoke helpers duplicating existing ones, thin wrappers that add indirection.
- Two implementations of one thing that must be "kept in sync" → merge them.
- Dead code left behind; docs/rules not updated for changed behaviour.

## Output

```text
High
- path:line — problem — why it matters — fix
Medium
- …
Structure
- one line per proposal
Pre-existing
- …
Not checked
- device-only / prod-only behaviour, missing access
```

If nothing significant: say so in one line. No nit padding.

If the change is going to a PR, also check the PR is fit for a human: small enough to review, the author has verified it (evidence attached — commands, screenshots, video), and the description is ≤ 40 lines under `## Why`, `## What changed`, `## Scope`, `## Tradeoffs`, `## Blast Radius`, `## Verification` (empty ones dropped; long logs linked, not pasted). Unreviewed agent code dumped on a colleague is the anti-pattern.
