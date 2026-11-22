---
name: vibe-setup
description: Make the current repo more agent-ready by moving it up one vibe level (L0 bootstrap → L1 verify loop → L2 on-demand knowledge → L3 enforcement → L4 autonomy → L5 multi-repo). Use when asked to set up, bootstrap, onboard, or level up a project for AI coding.
argument-hint: "[target level, default: next]"
disable-model-invocation: true
---

# vibe-setup

Goal: take this repo exactly one level up (or to `$ARGUMENTS` if given), with evidence, without overwriting anyone's work.

## 1. Where are we?

Run `vibe doctor`. Read `CLAUDE.md`, `.claude/`, `.vibe/` if present. Detect the topology: single repo, monorepo (workspace files like `pnpm-workspace.yaml`, `go.work`, `turbo.json`, `nx.json`, Cargo `[workspace]`), or a multi-repo workspace hub. If the user wants several separate repos worked on together, that is the workspace topology — confirm the repo paths with the user.

## 2. Do the next level

Run `vibe init --level <N> [--topology …]` (it never overwrites; read its `create`/`skip` lines). Then do the level's manual work — templates are only scaffolding:

- **L0**: Start small. Fill `CLAUDE.md` only with what Claude can't find by reading the repo: purpose, the commands that check work (run each one; keep only those that work), setup that isn't in the repo, decisions, external constraints, traps. No architecture or file-layout description. ≤ 200 lines, ideally far less. Personal/local details go to `CLAUDE.local.md`. Don't pre-install skills or rules — add them when a failure repeats.
- **L1**: The verification skill is critical infrastructure. Map every step in `.vibe/verify.conf` to the project's real commands; run `vibe verify` until green; make `vibe verify --fast` < 10 s. Then run `/vibe-core:create-verification` so `.claude/skills/verify/` gets a real Launch / Doctor / Drive / Evidence / Cleanup recipe, a small control CLI under `scripts/`, and a feature map — proven end to end once. Suggest scheduling `/vibe-core:maintain-verification`.
- **L2**: Move area-specific content out of `CLAUDE.md` into `.claude/rules/area-<name>.md` with `paths:` frontmatter; known traps into topic rules (symptom → cause → correct pattern); repeated procedures into `.claude/skills/`. Add `permissions.deny` Read rules for generated/vendored output. Add a "where things are documented" table to `CLAUDE.md`. Never put docs inside directories that get bundled into build output.
- **L3**: Prefer structure over text: directory boundaries with an import check, stronger types, compiler diagnostics. Start `.vibe/lint-rules` from the stack template and `.vibe/weeds.md` as the gardener queue; add rules for mistakes that already happened twice (ask the user / read `git log` for reverts and fix commits). Every rule needs `bad:`/`ok:` examples and a message that names the fix. `vibe lint` must be clean on the tree (fix or `lint:allow` with reason first) and `vibe lint --self-test` must pass. Add the "Rule → enforced by" table to `CLAUDE.md`.
- **L4**: Check the four "earn trust first" conditions in `/vibe-core:overnight` before any unattended run. Add lever scripts (seed/reset data, perf traces), document parallel work in worktrees (`claude -w`, `.worktreeinclude`), and show the user `/vibe-core:overnight`, `/vibe-core:architect`, `/vibe-core:blast-radius` and the `reviewer`/`advisor` agents. Independent review: the author never judges its own change.
- **L5**: Gardener loop (`/vibe-core:garden` on a schedule, `.vibe/weeds.md`), `/vibe-core:reflect` after sessions that taught something, and an outer loop if reports flow in (triage → repro → fix → verify; every stage can stop the line and hands over evidence). For multi-repo, create the hub with `vibe init <hub> --topology workspace --repos "…"` and fill its `CLAUDE.md` (map, contracts, change order, local wiring). For teams, host this plugin's marketplace in git.

## 3. Prove it

Re-run `vibe doctor` (level should increase) and `vibe verify`. Report:

```text
Level: <before> → <after>
Changed: <files>
Evidence: vibe doctor → …; vibe verify → …
Needs you: <decisions or facts only the user knows>
```

Never: overwrite or delete existing config without asking; invent commands you didn't run; jump more than one level unless asked.
