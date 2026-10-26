#!/bin/sh
# agents-09-keeping-guides-current: a throwaway git repo holds code and the guides that describe it.
# Three changes are checked by guides.om: compiler change without its guide (stale), compiler change
# with its guide (current), a typo fix that no guide describes (none affected).
# Host-only (Linux AArch64): no GPU, no network, no live service. git is glue, guides.om decides.
# Env: SRC = directory of the pinned clones, OMC = pinned omc (sha256 checked, exit 90 on mismatch).
here=$(cd "$(dirname "$0")" && pwd)
SRC=${SRC:?set SRC to a directory holding the clones in docs/learn/teach/PINS}
OMC=${OMC:-$SRC/omega-mv/seed/out/omc}
PIN=befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
got=$(sha256sum "$OMC" 2>/dev/null | cut -d ' ' -f 1)
if [ "$got" != "$PIN" ]; then
    printf 'omc sha256 does not match the pin, refusing to run\n'
    exit 90
fi
printf 'omc sha256 %s (matches pin)\n' "$PIN"
work=$(mktemp -d) || exit 2
trap 'rm -rf "$work"' EXIT
"$OMC" < "$here/guides.om" > "$work/guides" 2> "$work/err"
rc=$?
printf 'compile guides.om rc=%s\n' "$rc"
cat "$work/err"
if [ "$rc" -ne 0 ]; then
    exit "$rc"
fi
chmod +x "$work/guides" || exit 2

# Isolated git: no user or system configuration, fixed identity and dates.
HOME=$work/home
GIT_CONFIG_NOSYSTEM=1
GIT_CONFIG_GLOBAL=/dev/null
GIT_AUTHOR_NAME=Lane GIT_AUTHOR_EMAIL=lane@example.invalid
GIT_COMMITTER_NAME=Lane GIT_COMMITTER_EMAIL=lane@example.invalid
GIT_AUTHOR_DATE='2026-10-26T00:00:00Z' GIT_COMMITTER_DATE='2026-10-26T00:00:00Z'
export HOME GIT_CONFIG_NOSYSTEM GIT_CONFIG_GLOBAL GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL
export GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GIT_AUTHOR_DATE GIT_COMMITTER_DATE
mkdir -p "$HOME" || exit 2
repo=$work/repo
git init -q -b main "$repo" || exit 2
mkdir -p "$repo/compiler" "$repo/docs" "$repo/skills/omega-encoding" || exit 2
printf 'fn lower to void\nend\n' > "$repo/compiler/lower.om"
printf 'Error 12 means the register pool is exhausted.\n' > "$repo/skills/omega-encoding/SKILL.md"
printf 'Welcom to the project.\n' > "$repo/docs/intro.md"
git -C "$repo" add -A && git -C "$repo" commit -q -m base || exit 2

bad=0
check() {
    printf '\n--- change: %s\n' "$1"
    git -C "$repo" add -A || exit 2
    git -C "$repo" commit -q -m "$1" || exit 2
    git -C "$repo" diff --name-only HEAD~1 HEAD > "$work/changed" || exit 2
    printf 'changed paths:\n'
    cat "$work/changed"
    printf -- '--- guides.om says\n'
    "$work/guides" < "$work/changed"
    rc=$?
    printf 'run rc=%s (expected %s)\n' "$rc" "$2"
    if [ "$rc" -ne "$2" ]; then
        bad=$((bad + 1))
    fi
}

printf 'fn lower to void\nnote now splits long functions\nend\n' > "$repo/compiler/lower.om"
check 'compiler change, guide left alone' 1

printf 'fn lower to void\nnote splits long functions at 10 live names\nend\n' > "$repo/compiler/lower.om"
printf 'Error 12 means the register pool is exhausted; the compiler now splits at 10 live names.\n' > "$repo/skills/omega-encoding/SKILL.md"
check 'compiler change with its guide' 0

printf 'Welcome to the project.\n' > "$repo/docs/intro.md"
check 'typo fix in docs' 0

printf '\n'
if [ "$bad" -eq 0 ]; then
    printf 'ALL EXIT STATUSES AS EXPECTED\n'
    exit 0
fi
printf 'STATUS MISMATCH count=%s\n' "$bad"
exit 1
