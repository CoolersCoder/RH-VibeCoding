---
name: correct
description: Turn a mistake the user keeps correcting into something the repo enforces, so no future session can repeat it.
argument-hint: "<the mistake>"
disable-model-invocation: true
---

# Correct

Assume every future contributor is an agent that sees only the files it opened, copies the nearest example, and takes the shortest path that compiles. Make the right change the easy one and the wrong one fail.

1. **Name the class.** From `$ARGUMENTS`, recent commits/reverts (`git log`), review comments and the rule texts, state the mistake class with evidence (commits, lines). A class counts once it has happened twice.
2. **Fix at the highest level that works:**
   1. **Architecture** — one owner per piece of state, one supported way per task. Delete the old way and any dead code an agent would copy.
   2. **Types** — make the bad state unrepresentable.
   3. **Lint** — add a rule to `.vibe/lint-rules` (create with `vibe init --level 3` if missing): `rule`, `files`, `pattern` or `max_lines`, a `message` that names the fix and where to look, ≥1 `bad:` and ≥1 `ok:`. If the pattern already exists in the tree, fix those sites or mark the legitimate ones `lint:allow <rule> <reason>` first. Too complex for a per-line regex → write it as a rule for the language's own linter and run it in `.vibe/verify.conf`.
   4. **Check** — a test or standalone check for pure logic.
   5. **Text, last** — a path-scoped `.claude/rules/*.md` entry with the failure example. Only for judgment calls nothing can check.
3. **Prove it**: show the check failing on the real past mistake (or a faithful copy), then passing on the fixed code. Run `vibe lint --self-test` and `vibe verify`.
4. **Update the table**: the "Rule → enforced by" table in the root `CLAUDE.md`. If the rule was already there and nothing enforced it, that's a repeat — enforce it now. Remove rules whose mistake can no longer happen.

Reply: the class + evidence, the level chosen, why a higher level didn't work, and the proof output.
