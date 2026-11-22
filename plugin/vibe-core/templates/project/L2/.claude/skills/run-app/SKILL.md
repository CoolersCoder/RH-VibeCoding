---
name: run-app
description: Start {{PROJECT_NAME}} locally and drive it to a given screen, endpoint or state to see a change working. Use when asked to run, launch, demo, screenshot or reproduce something in the app.
---

# Run {{PROJECT_NAME}}

<!-- vibe L2 template: record the recipe that actually worked from a clean checkout. Re-record when the build/launch changes.
     Tip: Claude Code's /run-skill-generator can record this for you. -->

## Prerequisites

- TODO: runtimes/versions, env file (`cp .env.example .env`), services (DB, queues) and how to start them.

## Start

```bash
TODO
```

Ready when: TODO (log line / URL / health endpoint).

## Reach a state without clicking

<!-- Debug-only flags, URLs, seed scripts or test accounts that jump straight to a screen or state. Only in debug builds. -->
| Goal | How |
|---|---|
| TODO | TODO |

## Capture evidence

- Screenshot: TODO (→ `/tmp/{{PROJECT_NAME}}-qa/<name>.png`)
- Logs: TODO (which prefixed lines prove what)

## Reset

```bash
TODO
```

## Gotchas

- TODO (e.g. "release builds compile out the debug flags — never measure with them").
