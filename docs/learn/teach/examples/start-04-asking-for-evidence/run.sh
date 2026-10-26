#!/bin/sh
# start-04-asking-for-evidence: compare the evidence word in each claim with the evidence attached; a malformed claim is refused (negative control).
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
build claims 0
printf '\ncolumns: commit named, command given, output given (1 yes, 0 no), gate (P pass, F fail, N not run, - none), claimed word, what\n'
run claims honest.txt 0
run claims report.txt 1
run claims malformed.txt 3

printf '\n'
if [ "$bad" -eq 0 ]; then
    printf 'ALL EXIT STATUSES AS EXPECTED\n'
    exit 0
fi
printf 'STATUS MISMATCH count=%s\n' "$bad"
exit 1
