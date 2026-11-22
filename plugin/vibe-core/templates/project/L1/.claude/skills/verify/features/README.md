# Feature map — {{PROJECT_NAME}}

<!-- vibe L1 template. One file per user-facing feature (start with the top 3–5; /vibe-core:create-verification seeds
     them). This is the repo's maintained verification source: agents trust it, so keep it current — update the entry in
     the same PR that changes the feature, and run /vibe-core:maintain-verification regularly. -->

| Feature | File | Proven by |
|---|---|---|
| TODO | `TODO.md` | TODO (observable end state) |

Each feature file uses exactly these sections:

```markdown
# <Feature>

## Sub-features
## How to get to it (user POV)
## Driving it with <harness>
## Gotchas
```

If seed data lacks a precondition a journey needs, the journey reports a failure and the reason goes in `Gotchas`. Never weaken a journey to make it pass.
