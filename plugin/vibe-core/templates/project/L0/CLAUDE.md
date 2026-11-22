# {{PROJECT_NAME}}

<!-- vibe L0 template ({{DATE}}). Keep under 200 lines. Only write what Claude can't find by reading the repo, or would
     have to re-dig every session. Test for each line: "Could it find this in the code? Would it go look?" — if both yes,
     delete the line. Don't describe architecture or file layout; Claude reads the repo. Delete comments once filled.
     Start small: add lines when a mistake happens twice, not in advance. -->

<!-- One or two sentences: what this is, who it's for, what it is NOT. -->
TODO: purpose.

## Check your work

<!-- The single most useful section. Every command must actually run — copy-paste each one before keeping it. -->
- Gate (run before saying "done"): `vibe verify` · inner loop: `vibe verify --fast`
- See it working: the `verify` skill (launch, drive, capture evidence)
- Single test: `TODO`

## What the repo can't tell you

<!-- Decisions made outside the code, processes in someone's head, env/secrets setup, external constraints, traps.
     Examples — keep the true ones, delete the rest: -->
- TODO: setup that isn't in the repo (e.g. `cp .env.example .env`, which services must run).
- TODO: decisions (e.g. "we chose X over Y because …; don't re-propose Y").
- TODO: external constraints (rate limits, vendor quirks, compliance).
- Never edit generated files in `TODO`; regenerate with `TODO`.

## Working rules

1. Restate non-trivial or ambiguous asks in your own words, and name the smallest change that meets them, before editing.
2. Prove it works: use the `verify` skill and report `VERIFIED` / `NOT VERIFIED` / `INCONCLUSIVE` with the commands and artifacts. Say plainly what you could not verify. Never hand me a check you could run yourself.
3. Fix root causes: reproduce first, form hypotheses and eliminate them with runtime evidence. No retries, sleeps, swallowed errors, skipped tests, or "might help" guards.
4. Plan through code: when the shape is unclear, prototype or sketch two designs (types and signatures) and pick one with evidence; don't polish an abstract plan.
5. Subtract before you add: reuse existing helpers, delete dead code and old APIs in the same change, keep diffs small.
6. Reversible work: proceed and show the result. Irreversible (deploys, data deletion, force-push, messages to people): stop and ask. "No" is an acceptable answer — give your real judgment, not agreement.
7. A mistake corrected twice gets enforced (`/vibe-core:correct`): architecture → types → `.vibe/lint-rules` → test → rule text last.
8. When you change behaviour described here or in `.claude/rules/`, update that text in the same commit. No line counts or history in docs.

## Where things are documented

<!-- Filled at L2: area rules in .claude/rules/ (load by path), skills in .claude/skills/. -->
| Area | File |
|---|---|
| Verification recipe + feature map | `.claude/skills/verify/` |

## Rule → enforced by

<!-- Filled at L3. A rule that only lives in text and gets broken again must move up a level. -->
| Rule | Enforced by |
|---|---|
| Change verified before finishing | `verify` skill + vibe-core Stop hook |
