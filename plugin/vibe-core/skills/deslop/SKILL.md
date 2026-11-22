---
name: deslop
description: Remove AI-generated slop from the current diff without changing behaviour.
disable-model-invocation: true
---

# Deslop

Look at `git diff main...HEAD` and uncommitted changes. Remove what an AI added that a careful engineer on *this* codebase wouldn't write:

- Comments that narrate the code or restate the obvious, or that clash with local style. **Keep** comments explaining *why* — hard-won lessons, constraints, links.
- Defensive checks, try/catch, null-guards and fallbacks on paths that can't fail; silent fallbacks that hide real errors (returning empty/mock data on failure).
- Casts, `any`, force-unwraps, `# type: ignore` used to dodge a type problem.
- Deep nesting an early return flattens; one-use helpers and pass-through wrappers.
- Unused params/imports/variables; debug prints (keep intentional structured QA/log lines).
- New code that ignores existing helpers, components or tokens in the repo.
- Over-generalisation: config flags, options or abstractions nothing uses yet.

Rules: behaviour stays identical unless something is clearly a bug — then say so instead of silently fixing. Minimal edits. Run `vibe verify` (or the project's checks) afterwards. Finish with a 1–3 sentence summary.
