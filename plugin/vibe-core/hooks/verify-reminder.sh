#!/usr/bin/env bash
# Stop: remind to run `vibe verify` when watched files changed since the last passing run.
set -u
command -v jq >/dev/null 2>&1 || exit 0
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)" || exit 0
KIT="$(dirname "$HOOK_DIR")"
# shellcheck source=../lib/common.sh
. "$KIT/lib/common.sh" 2>/dev/null || exit 0

INPUT="$(cat 2>/dev/null)" || exit 0
[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ] && exit 0
PROJ="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)}"
[ -n "$PROJ" ] || exit 0

ROOT="$(vibe_find_root verify.conf "$PROJ")" || exit 0
STALE="$(vibe_stale_list "$ROOT" 2>/dev/null | tr '\n' ' ')"
STALE="${STALE% }"
[ -n "$STALE" ] || exit 0

jq -n --arg stale "$STALE" \
    '{decision:"block",reason:("Files under WATCH changed since the last passing '"'"'vibe verify'"'"' (stale: " + $stale + "). Run the verify skill before finishing. If you can'"'"'t or it isn'"'"'t needed (e.g. you'"'"'re waiting on the user, or only docs changed), say so in one line and stop.")}' 2>/dev/null
exit 0
