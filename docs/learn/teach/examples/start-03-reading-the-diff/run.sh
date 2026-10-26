#!/bin/sh
# start-03-reading-the-diff: an agent asked to fix a typo also changes a setting and deletes a test; git diff shows it and scope.om flags it.
# Host-only (Linux AArch64): no GPU, no network, no live service.
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
bad=0
build() {
    "$OMC" < "$here/$1.om" > "$work/$1" 2> "$work/err"
    rc=$?
    printf 'compile %s.om rc=%s (expected %s)\n' "$1" "$rc" "$2"
    cat "$work/err"
    if [ "$rc" -ne "$2" ]; then
        bad=$((bad + 1))
    fi
    chmod +x "$work/$1" || exit 2
}
run() {
    printf '\n--- input %s\n' "$2"
    cat "$here/$2"
    printf -- '--- output\n'
    "$work/$1" < "$here/$2"
    rc=$?
    printf 'run rc=%s (expected %s)\n' "$rc" "$3"
    if [ "$rc" -ne "$3" ]; then
        bad=$((bad + 1))
    fi
}
build scope 0
HOME=$work/home
GIT_CONFIG_NOSYSTEM=1
GIT_CONFIG_GLOBAL=/dev/null
GIT_AUTHOR_NAME=Agent GIT_AUTHOR_EMAIL=agent@example.invalid
GIT_COMMITTER_NAME=Agent GIT_COMMITTER_EMAIL=agent@example.invalid
GIT_AUTHOR_DATE='2026-10-26T00:00:00Z' GIT_COMMITTER_DATE='2026-10-26T00:00:00Z'
export HOME GIT_CONFIG_NOSYSTEM GIT_CONFIG_GLOBAL GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL
export GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GIT_AUTHOR_DATE GIT_COMMITTER_DATE
mkdir -p "$HOME" || exit 2
repo=$work/repo
q() { "$@" > "$work/log" 2>&1; }
git init -q -b main "$repo" || exit 2
printf '# Photo uploader\nUpload your phtos to the family album.\n' > "$repo/README.md"
printf 'max_upload_mb = 10\n' > "$repo/settings.txt"
printf 'a 12 MB photo is refused\n' > "$repo/test_upload.txt"
q git -C "$repo" add -A && q git -C "$repo" commit -m start || exit 2

printf '\nwhat you asked the agent: fix the typo in README.md\n'
q git -C "$repo" checkout -b agent-a
printf '# Photo uploader\nUpload your photos to the family album.\n' > "$repo/README.md"
printf 'max_upload_mb = 100\n' > "$repo/settings.txt"
rm "$repo/test_upload.txt"
q git -C "$repo" add -A && q git -C "$repo" commit -m 'Fix typo'
printf 'agent A says: "Fixed the typo." commit rc=%s\n' "$?"
printf '\n== git diff --stat main agent-a\n'
git -C "$repo" diff --stat main agent-a
printf '\n== git diff main agent-a\n'
git -C "$repo" diff main agent-a
{ printf 'allow README.md\n'; git -C "$repo" diff --name-only main agent-a | sed 's/^/changed /'; } > "$work/a.txt"
run_scope() {
    printf '\n--- scope.om input\n'
    cat "$work/$1"
    printf -- '--- output\n'
    "$work/scope" < "$work/$1"
    rc=$?
    printf 'run rc=%s (expected %s)\n' "$rc" "$2"
    if [ "$rc" -ne "$2" ]; then
        bad=$((bad + 1))
    fi
}
run_scope a.txt 1

printf '\nsame request to agent B\n'
q git -C "$repo" checkout main
q git -C "$repo" checkout -b agent-b
printf '# Photo uploader\nUpload your photos to the family album.\n' > "$repo/README.md"
q git -C "$repo" commit -am 'Fix typo'
printf 'agent B says: "Fixed the typo." commit rc=%s\n' "$?"
printf '\n== git diff --stat main agent-b\n'
git -C "$repo" diff --stat main agent-b
{ printf 'allow README.md\n'; git -C "$repo" diff --name-only main agent-b | sed 's/^/changed /'; } > "$work/b.txt"
run_scope b.txt 0

printf 'allow README.md\nREADME.md\n' > "$work/bad.txt"
run_scope bad.txt 3

printf '\n'
if [ "$bad" -eq 0 ]; then
    printf 'ALL EXIT STATUSES AS EXPECTED\n'
    exit 0
fi
printf 'STATUS MISMATCH count=%s\n' "$bad"
exit 1
