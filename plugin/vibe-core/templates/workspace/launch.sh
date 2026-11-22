#!/usr/bin/env bash
# Start Claude Code in this workspace hub with every repo attached.
# --add-dir gives file access and loads each repo's skills; the env var also loads their CLAUDE.md and .claude/rules/.
# (The `additionalDirectories` setting would give file access only — no CLAUDE.md, no skills.)
set -u
cd "$(dirname "$0")" || exit 1

REPOS='{{REPOS}}'

args=()
for r in $REPOS; do
  if [ -d "$r" ]; then
    args+=(--add-dir "$r")
  else
    echo "warning: repo not found: $r" >&2
  fi
done

# ${args[@]+…}: an empty array is an unbound-variable error under `set -u` in macOS's bash 3.2.
CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 exec claude ${args[@]+"${args[@]}"} "$@"
