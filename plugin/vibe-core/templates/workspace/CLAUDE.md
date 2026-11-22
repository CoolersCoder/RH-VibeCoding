# {{PROJECT_NAME}} — multi-repo workspace hub

<!-- vibe workspace template ({{DATE}}). This hub coordinates separate git repositories. Start cross-repo sessions here
     with ./launch.sh (it adds every repo with --add-dir and loads their CLAUDE.md files). For single-repo work, start
     Claude inside that repo instead — smaller context. Keep this file under 200 lines; delete comments once filled. -->

Repos: {{REPOS}}

## Map

| Repo | What it is | Stack | Run locally | Owner |
|---|---|---|---|---|
| TODO | | | | |

## Contracts

<!-- Where each cross-repo interface is defined, which repo is the source of truth, who consumes it, how consumers regenerate. -->
| Interface | Source of truth | Consumers | Regenerate / check |
|---|---|---|---|
| TODO (e.g. OpenAPI `api/openapi.yaml`) | api | web, mobile | `TODO` |

## Cross-repo change order

<!-- The safe sequence for a change that spans repos. Example: -->
1. Change the contract in the source repo, backwards-compatible (add, don't rename/remove).
2. Implement + `vibe verify` in the source repo; merge/release.
3. Update each consumer (regenerate types, adapt) + `vibe verify` in each.
4. Remove the old field/endpoint only after every consumer has shipped.

Each repo gets its own branch, commits and PR; link the PRs to each other.

## Local wiring

- TODO: how consumers point at a local instance of the provider (env vars, ports, proxy).

## Verify

- `vibe verify` here runs `vibe verify` in every repo listed in `.vibe/verify.conf`.
- Contract changed → also run: TODO (e.g. regenerate client in web, then its typecheck).
