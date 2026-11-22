---
name: garden
description: Gardener pass over recent merged work — spot recurring smells, queue them in .vibe/weeds.md, group by root cause, and change the bed (architecture, types, lint) so the same weed can't grow back.
argument-hint: "[since, default 7 days]"
disable-model-invocation: true
---

# Garden

Every weed you pull becomes a rule, so it can't grow back. The codebase is the example every future agent copies — a bad pattern left in place is an instruction.

1. **Sample** merged work since `${ARGUMENTS:-7 days ago}`: `git log --no-merges --since=…`, read a sample of diffs closely (you can't taste every dish — pick the biggest and the most agent-written).
2. **Spot smells**: the same helper re-invented again, new lint suppressions or `any`/casts, timers/retries/sleeps working around a design mismatch, comments justifying a workaround, logic leaking across a boundary, dead code, files growing past ~800 lines, duplicated implementations "kept in sync".
3. **Queue, don't fix**: append each to `.vibe/weeds.md` (date, where, smell, seen before?). Fixing on sight hides patterns.
4. **Group** the queue (including older entries) by root cause. A cause seen twice or more is a class; one-offs need no action.
5. **Change the bed** for each class via `/vibe-core:correct`: eliminate it in architecture/data structures (e.g. directory boundaries + an import check), else types, else a `.vibe/lint-rules` rule whose message names the fix, else a test; text rules last. Prove each new check fails on a real past instance.
6. Mark handled entries `→ fixed by <commit/rule>`.

**Reply:** smells found (with `path:line`), classes and the bed change chosen for each (with proof), entries left queued.
