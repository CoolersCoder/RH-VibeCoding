#!/usr/bin/env bash
# PreToolUse (Bash): deny catastrophic commands, ask before risky ones. Silent otherwise.
set -u
command -v jq >/dev/null 2>&1 || exit 0
INPUT="$(cat 2>/dev/null)" || exit 0
CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)" || exit 0
[ -n "$CMD" ] || exit 0
PROJ="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)}"
[ -n "$PROJ" ] || PROJ="."

emit() {
    jq -n --arg d "$1" --arg r "$2" \
        '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}' 2>/dev/null
    exit 0
}

current_branch() { git -C "$PROJ" rev-parse --abbrev-ref HEAD 2>/dev/null; }
is_protected() { case "$1" in main|master) return 0 ;; esac; return 1; }

# first matching "rm" segments
check_rm() {
    local seg t tt rec force danger
    while IFS= read -r seg; do
        [ -n "$seg" ] || continue
        seg="${seg#"${seg%%rm*}"}"
        set -f
        set -- $seg
        set +f
        shift
        rec=0; force=0; danger=""
        for t in "$@"; do
            case "$t" in
                --recursive) rec=1 ;;
                --force) force=1 ;;
                --) ;;
                --*) ;;
                -*)
                    case "$t" in *[rR]*) rec=1 ;; esac
                    case "$t" in *f*) force=1 ;; esac
                    ;;
                *)
                    tt="${t//\"/}"; tt="${tt//\'/}"
                    case "$tt" in
                        "/"|"/*"|"~"|"~/"|"~/*"|'$HOME'|'$HOME/'|'$HOME/*'|'${HOME}'|'${HOME}/'|'${HOME}/*'|"*"|".."|"../"|"../*"|"./*"|"$HOME"|"$HOME/")
                            danger="$tt" ;;
                    esac
                    ;;
            esac
        done
        if [ "$rec" = 1 ] && [ "$force" = 1 ] && [ -n "$danger" ]; then
            emit deny "rm -rf on '$danger' would destroy the home directory, the filesystem root, the whole working tree or the parent directory. Name the specific files/directories to delete (e.g. rm -rf build/ dist/)."
        fi
    done <<EOF
$(printf '%s\n' "$CMD" | grep -oE '(^|[^[:alnum:]_./-])rm[[:space:]][^;&|]*')
EOF
}

check_push() {
    local seg t force npos ref branch protected P0 P1
    while IFS= read -r seg; do
        [ -n "$seg" ] || continue
        seg="${seg#"${seg%%git*}"}"
        set -f
        set -- $seg
        set +f
        shift 2
        force=0; npos=0; P0=""; P1=""
        for t in "$@"; do
            case "$t" in
                --force|--force-with-lease*|--force-if-includes) force=1 ;;
                --*) ;;
                -*) case "$t" in *f*) force=1 ;; esac ;;
                *)
                    case "$t" in +*) force=1 ;; esac
                    npos=$((npos + 1))
                    [ "$npos" = 1 ] && P0="$t"
                    [ "$npos" = 2 ] && P1="$t"
                    ;;
            esac
        done
        [ "$force" = 1 ] || continue
        if [ "$npos" -ge 2 ]; then
            ref="${P1#+}"; ref="${ref##*:}"; ref="${ref#refs/heads/}"
            branch="$ref"
        else
            branch="$(current_branch)"
        fi
        if is_protected "$branch"; then
            emit deny "force-pushing to '$branch' rewrites shared history. Push a feature branch and open a PR, or add a new commit that reverts the change."
        else
            emit ask "git push --force on '${branch:-the current branch}' overwrites remote history. Prefer --force-with-lease on a branch only you use; confirm if intended."
        fi
    done <<EOF
$(printf '%s\n' "$CMD" | grep -oE '(^|[^[:alnum:]_./-])git[[:space:]]+push[^;&|]*')
EOF
}

# ── DENY ──
check_rm

if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+(commit|push)[^;&|]*--no-verify|git[[:space:]]+commit[^;&|]*[[:space:]]-[a-zA-Z]*n([[:space:]]|$)'; then
    emit deny "--no-verify skips the repo's git hooks (lint/tests). Fix what the hook reports instead; if a hook is genuinely broken, ask the user."
fi

if printf '%s' "$CMD" | grep -qE 'chmod[[:space:]]+(-[a-zA-Z]*R[a-zA-Z]*[[:space:]]+)+0?777|chmod[[:space:]]+0?777[[:space:]]+(-R|--recursive)'; then
    emit deny "chmod -R 777 makes everything world-writable. Grant only the specific permission needed (e.g. chmod +x script.sh)."
fi

if printf '%s' "$CMD" | grep -qE '(curl|wget)[^|;&]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|da)?sh([[:space:]]|$)'; then
    emit deny "piping a download straight into a shell runs unreviewed code. Download to a file, read it, then run it."
fi

check_push

# ── ASK ──
LOWER="$(printf '%s' "$CMD" | tr '[:upper:]' '[:lower:]')"

if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+reset[[:space:]]+[^;&|]*--hard'; then
    emit ask "git reset --hard discards uncommitted work irrecoverably. Use git stash, or confirm if intended."
fi
if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+clean[^;&|]*[[:space:]]-[a-zA-Z]*f|git[[:space:]]+clean[^;&|]*--force'; then
    emit ask "git clean -f deletes untracked files irrecoverably. Run git clean -n first to preview, or confirm if intended."
fi
if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+(checkout[[:space:]]+(--[[:space:]]+)?|restore[[:space:]]+)\.([[:space:]]|$)'; then
    emit ask "this discards all uncommitted changes in the working tree. Use git stash, or confirm if intended."
fi
if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+branch[^;&|]*[[:space:]]-[a-zA-Z]*D'; then
    emit ask "git branch -D deletes a branch even if unmerged. Use -d (safe delete), or confirm if intended."
fi
if printf '%s' "$LOWER" | grep -qE 'drop[[:space:]]+(table|database)|truncate[[:space:]]+table|truncate[[:space:]]+[a-z_."`]+[[:space:]]*(;|$|"|'"'"')'; then
    emit ask "this SQL destroys data (DROP/TRUNCATE). Confirm the target database and that a backup exists."
fi
if printf '%s' "$CMD" | grep -qE 'docker[[:space:]]+system[[:space:]]+prune'; then
    emit ask "docker system prune removes stopped containers, networks and images. Confirm if intended."
fi
if printf '%s' "$CMD" | grep -qE 'kubectl[[:space:]]+delete'; then
    emit ask "kubectl delete removes cluster resources. Confirm the context/namespace (kubectl config current-context)."
fi
if printf '%s' "$CMD" | grep -qE 'terraform[[:space:]]+destroy'; then
    emit ask "terraform destroy tears down real infrastructure. Run terraform plan -destroy first and confirm."
fi
exit 0
