#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): lint the edited file with the nearest .vibe/lint-rules; block on violations.
set -u
command -v jq >/dev/null 2>&1 || exit 0
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)" || exit 0
KIT="$(dirname "$HOOK_DIR")"
# shellcheck source=../lib/common.sh
. "$KIT/lib/common.sh" 2>/dev/null || exit 0

INPUT="$(cat 2>/dev/null)" || exit 0
FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)" || exit 0
[ -n "$FILE" ] && [ -f "$FILE" ] || exit 0

ROOT="$(vibe_find_root lint-rules "$(dirname "$FILE")")" || exit 0
OUT="$(bash "$KIT/bin/vibe" lint -C "$ROOT" "$FILE" 2>/dev/null)"
RC=$?
[ "$RC" -eq 1 ] && [ -n "$OUT" ] || exit 0

jq -n --arg out "$OUT" \
    '{decision:"block",reason:($out + "\nFix these now. If one is a verified exception, add '"'"'lint:allow <rule> <reason>'"'"' on that line.")}' 2>/dev/null
exit 0
