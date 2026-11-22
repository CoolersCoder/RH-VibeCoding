---
# vibe L2 template. Copy this file to area-<name>.md per module, point `paths` at real globs, delete this example.
# Loads only when Claude works with a matching file. Keep each rule file under ~200 lines.
paths:
  - "TODO/example-area/**"
---

# <Area name>

<!-- What a contributor must know before touching this area that the code doesn't say. Delete sections you don't need. -->

## Responsibilities

- What this area owns; what it must NOT do (e.g. "no network calls from views").

## Contracts

- Public interfaces other areas rely on and who consumes them (changing these needs: …).

## Traps

<!-- Format: symptom → cause → correct pattern. Promote to a .vibe/lint-rules rule if it can be checked. -->
- **<symptom>** — <cause>. Do <correct pattern> instead.

## Unreferenced leftovers

- Files nobody uses — delete rather than extend.
