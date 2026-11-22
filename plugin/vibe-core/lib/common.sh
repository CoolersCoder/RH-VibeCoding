#!/usr/bin/env bash
# Shared helpers for bin/vibe and the hooks. Source this file; bash 3.2 compatible.

vibe_abs_dir() { (cd "$1" 2>/dev/null && pwd -P); }

vibe_git_top() { git -C "$1" rev-parse --show-toplevel 2>/dev/null; }

# vibe_find_root <file-under-.vibe> <start-dir>
# Nearest ancestor (inclusive) containing .vibe/<file>, stopping at the git toplevel.
vibe_find_root() {
    local name="$1" d top
    d="$(vibe_abs_dir "$2")" || return 1
    top="$(vibe_git_top "$d")"
    [ -n "$top" ] && top="$(vibe_abs_dir "$top")"
    while :; do
        if [ -f "$d/.vibe/$name" ]; then printf '%s\n' "$d"; return 0; fi
        [ -n "$top" ] && [ "$d" = "$top" ] && return 1
        [ "$d" = "/" ] && return 1
        d="$(dirname "$d")"
    done
}

# vibe_load_conf <dir> — sets STEPS FAST_STEPS WATCH PACKAGES REPOS and step_* from <dir>/.vibe/verify.conf
vibe_load_conf() {
    local v
    STEPS=''; FAST_STEPS=''; WATCH=''; PACKAGES=''; REPOS=''
    for v in $(compgen -A variable step_); do unset "$v"; done
    if [ ! -f "$1/.vibe/verify.conf" ]; then WATCH='.'; return 1; fi
    # shellcheck disable=SC1090,SC1091
    . "$1/.vibe/verify.conf"
    [ -n "$FAST_STEPS" ] || FAST_STEPS="$STEPS"
    [ -n "$WATCH" ] || WATCH='.'
    return 0
}

vibe_sha() {
    if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi | awk '{print $1}'
}

vibe_stamp_path() { printf '%s/.vibe/state/verified\n' "$1"; }

# vibe_state_hash <dir> — "clean" or a sha256 of the changes under WATCH
vibe_state_hash() {
    local dir="$1" base diff untracked f
    local -a specs
    vibe_load_conf "$dir" || true
    git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || { echo clean; return 0; }
    if git -C "$dir" rev-parse --verify -q HEAD >/dev/null 2>&1; then
        base=HEAD
    else
        base=4b825dc642cb6eb9a060e54bf8d69288fbd1ec6d
    fi
    set -f
    specs=($WATCH)
    set +f
    diff="$(git -C "$dir" diff "$base" -- "${specs[@]}" ':(exclude).vibe/state' 2>/dev/null)"
    untracked="$(git -C "$dir" ls-files --others --exclude-standard -- "${specs[@]}" ':(exclude).vibe/state' 2>/dev/null)"
    if [ -z "$diff" ] && [ -z "$untracked" ]; then
        echo clean
        return 0
    fi
    {
        printf '%s\n' "$diff"
        while IFS= read -r f; do
            [ -n "$f" ] || continue
            printf '== %s\n' "$f"
            cat "$dir/$f" 2>/dev/null
        done <<EOF
$untracked
EOF
    } | vibe_sha
}

vibe_write_stamp() {
    local dir="$1" h
    h="$(vibe_state_hash "$dir")"
    mkdir -p "$dir/.vibe/state"
    printf '%s\n' "$h" > "$(vibe_stamp_path "$dir")"
}

# true (0) when <dir> has watched changes not covered by its stamp
vibe_dir_stale() {
    local dir="$1" h stamp
    h="$(vibe_state_hash "$dir")"
    [ "$h" = clean ] && return 1
    stamp="$(cat "$(vibe_stamp_path "$dir")" 2>/dev/null)"
    [ "$h" = "$stamp" ] && return 1
    return 0
}

# true (0) when <pkg> (relative to the git repo at <root>) has changes vs HEAD or vs the main merge-base
vibe_pkg_affected() {
    local root="$1" pkg="$2" mb="" ref
    [ -n "$(git -C "$root" status --porcelain -- "$pkg" 2>/dev/null)" ] && return 0
    for ref in origin/main main; do
        mb="$(git -C "$root" merge-base HEAD "$ref" 2>/dev/null)"
        [ -n "$mb" ] && break
    done
    [ -n "$mb" ] || return 1
    [ -n "$(git -C "$root" diff --name-only "$mb" -- "$pkg" 2>/dev/null)" ]
}

# vibe_stale_list <root> — one label per line for every unit that needs re-verification
vibe_stale_list() {
    local root="$1" pkgs repos own r p d
    vibe_load_conf "$root" || return 0
    pkgs="$PACKAGES"; repos="$REPOS"; own="$STEPS"
    set -f
    if [ -n "$repos" ]; then
        for r in $repos; do
            d="$root/$r"
            [ -f "$d/.vibe/verify.conf" ] || continue
            if vibe_dir_stale "$d"; then echo "$r"; fi
        done
    elif [ -n "$pkgs" ]; then
        for p in $pkgs; do
            [ -f "$root/$p/.vibe/verify.conf" ] || continue
            if vibe_pkg_affected "$root" "$p" && vibe_dir_stale "$root/$p"; then echo "$p"; fi
        done
        if [ -n "$own" ] && vibe_dir_stale "$root"; then echo "."; fi
    else
        if vibe_dir_stale "$root"; then echo "."; fi
    fi
    set +f
    return 0
}

# vibe_freshness <root> — fresh | stale | never
vibe_freshness() {
    local root="$1" pkgs repos r p any=0
    vibe_load_conf "$root" || { echo never; return 0; }
    pkgs="$PACKAGES"; repos="$REPOS"
    set -f
    if [ -n "$repos" ]; then
        for r in $repos; do [ -f "$root/$r/.vibe/state/verified" ] && any=1; done
    elif [ -n "$pkgs" ]; then
        for p in $pkgs; do [ -f "$root/$p/.vibe/state/verified" ] && any=1; done
        [ -f "$root/.vibe/state/verified" ] && any=1
    else
        [ -f "$root/.vibe/state/verified" ] && any=1
    fi
    set +f
    if [ "$any" = 0 ]; then echo never; return 0; fi
    if [ -n "$(vibe_stale_list "$root")" ]; then echo stale; else echo fresh; fi
}
