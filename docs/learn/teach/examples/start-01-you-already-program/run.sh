#!/bin/sh
# start-01-you-already-program: a plain-English request as a program that runs, and the compiler refusing a loosely written start (negative control).
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
build todo 0
run todo notes.txt 0
printf '\n--- the same idea written loosely\n'
cat "$here/vague.om"
build vague 11

printf '\n'
if [ "$bad" -eq 0 ]; then
    printf 'ALL EXIT STATUSES AS EXPECTED\n'
    exit 0
fi
printf 'STATUS MISMATCH count=%s\n' "$bad"
exit 1
