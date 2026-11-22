#!/usr/bin/env bash
# SessionStart: if the project is vibe-enabled (.vibe/ exists), inject a one-line status.
set -u
command -v jq >/dev/null 2>&1 || exit 0
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)" || exit 0
KIT="$(dirname "$HOOK_DIR")"

INPUT="$(cat 2>/dev/null)" || exit 0
PROJ="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)}"
[ -n "$PROJ" ] && [ -d "$PROJ/.vibe" ] || exit 0

BRIEF="$(bash "$KIT/bin/vibe" doctor -C "$PROJ" --brief 2>/dev/null)" || exit 0
[ -n "$BRIEF" ] || exit 0
BRANCH="$(git -C "$PROJ" rev-parse --abbrev-ref HEAD 2>/dev/null)"

jq -n --arg ctx "$BRIEF; branch ${BRANCH:-none}" \
    '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}' 2>/dev/null
exit 0
