---
name: blast-radius
description: Find what a change could break outside its diff, and prove the one fact it's safe because of by running real code — for "what could this break" or a small diff you don't trust.
argument-hint: "[diff range or PR, default the current diff]"
disable-model-invocation: true
---

# Blast radius

Listing callers is not the job (grep does that in a second). The job is the breakage grep won't show. A convincing writeup is worthless on its own — it reads the same whether or not it's true.

1. **Read the change**: the diff, the symbols added/changed/deleted, and what now behaves differently — including what the diff doesn't spell out.
2. **Find the one fact it's safe because of** (e.g. "this only drops entries that are already dead"). Most risky-looking changes hinge on one such fact; if it holds, most risks clear at once. Spend your time here.
3. **Look where grep stops**: the pinned library's source and local patches; timing (async ordering, teardown, retries); data crossing boundaries (API JSON, DB columns, wire formats, another language reading the same bytes, feature flags, code three hops downstream).
4. **Get the fact as far down this ladder as is cheap**, and say where it stopped: (1) asserted → (2) pointed at the `file:line` → (3) walked the failure and showed it can't happen → (4) ran a script/test against the real code that fails loudly if wrong → (5) reproduced in the running app.
5. For a big or wide change, ask independent reviewers (other models) the same question and merge.

**Reply:** what it does (incl. the non-obvious part) · the safety fact, its ladder level and the proof output (or "unproven") · confirmed risks (how it breaks, `file:line`, likelihood × cost, how to check) · cleared risks · the cheapest test that would catch the real bug before merge.
