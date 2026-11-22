---
name: create-verification
description: Generate this repo's verification skill (.claude/skills/verify/) that launches, drives and observes the real app like a user — any stack — plus a small control CLI and a feature map, then prove it end to end.
disable-model-invocation: true
---

# Create the verification skill

Verification is the limiting step of agent work: an agent that can launch the real app, drive it and see the result closes its own loop; one that can't makes the human the bottleneck. Treat the output as critical infrastructure, written for an agent that reads it cold, mid-task, having never seen the app.

## 1. Interview the repo, not the user

Answer from the codebase; ask the user only what you cannot observe.

- **Surface**: what a user actually touches — web UI, desktop (Electron), CLI/TUI, API, mobile, library. Pick the primary one; note the rest.
- **Run**: the repo's own dev command (scripts, Makefile, README). Ports, env vars, seed data, auth/test users.
- **Drive**: existing harnesses first (Playwright/Cypress, expect scripts, curl-able endpoints, debug ports, simulator tooling). Otherwise: CDP for web/Electron, tmux/PTY for CLI/TUI, HTTP for services, `simctl`/`adb` for mobile. A thin runtime → build the missing debug tool; say so.
- **Observe**: screenshots, accessibility snapshots, transcripts, response bodies, logs (add prefixed QA log lines on key paths if needed), exit codes, DB state, traces.
- **Isolate**: can two instances run side by side (ports, data dirs, profiles, worktrees)? If not, the skill must refuse to double-drive.

If the checkout doesn't build or start, fix that first (or report it precisely). A skill written against a broken base teaches wrong steps.

## 2. Build the lever: a small control CLI

Write `scripts/<app>ctl` (any language the repo already uses) with a few composable commands that each do real work: `doctor`, `launch`, `snapshot`, `screenshot <path>`, the main interactions (`click`, `type`, `send`, `open <route>`…), `trace`/`profile` if relevant, `wait-settle`, `cleanup`. Rules: non-interactive flags, `--help` with examples, errors that say what to do, `--dry-run` on anything destructive, machine-readable output where useful, safe to rerun. Do one journey by hand first, then encode it.

## 3. Write `.claude/skills/verify/SKILL.md`

Keep `name: verify` (Claude Code runs a project skill named `verify` before commits). Fill every section of the template with real commands and handles — no placeholders left:

- **Launch**: reaches a *usable* state from an empty data dir (migrations, seed, test user); the ready signal; teardown. For short-lived CLIs: build once, run each drive in its own PTY.
- **Doctor**: one read-only "is this instance worth driving?" check.
- **Drive**: the CLI/harness with stable handles (ARIA labels, data attributes, routes, prompt strings), not coordinates.
- **Evidence**: the real user path (no internal setters or test-only endpoints); action + resulting state + side effects; where artifacts go (they survive cleanup). Dry-run modes: verify what they actually skip by observation.
- **Cleanup**: kill only what this run started; keep the evidence.

## 4. Seed the feature map

`.claude/skills/verify/features/README.md` (index) plus one file per top user-facing feature (3–5 to start, from routes, commands, menus, docs), each with exactly: `## Sub-features`, `## How to get to it (user POV)`, `## Driving it with <harness>`, `## Gotchas`. A journey whose precondition the seed data lacks reports a failure and records why in Gotchas — never weaken the journey.

## 5. Prove it before handing over

Follow the skill's own instructions end to end once: launch → doctor → drive ONE mapped feature → capture evidence → cleanup → confirm the evidence still exists. Run cleanup after every failed attempt too. A skill that was never executed is a draft. If you proved it in a stand-in (local instead of CI, container instead of device), list the steps the real target will do differently as unverified.

**Reply:** surface + harness chosen and why, the CLI commands, the features mapped, the end-to-end proof (commands + artifact paths), what's still unverified. Suggest running `/vibe-core:maintain-verification` on a schedule.
