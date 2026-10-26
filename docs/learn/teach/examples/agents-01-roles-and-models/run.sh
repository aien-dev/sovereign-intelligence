#!/bin/sh
# agents-01-roles-and-models: decide WORK alone, CONSULT one, or CONSULT two per situation; a malformed line is refused (negative control).
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
"$OMC" < "$here/consult.om" > "$work/consult" 2> "$work/err"
rc=$?
printf 'compile consult.om rc=%s\n' "$rc"
cat "$work/err"
if [ "$rc" -ne 0 ]; then
    exit "$rc"
fi
chmod +x "$work/consult" || exit 2
bad=0
run() {
    printf '\n--- input %s\n' "$1"
    cat "$here/$1"
    printf -- '--- output\n'
    "$work/consult" < "$here/$1"
    rc=$?
    printf 'run rc=%s (expected %s)\n' "$rc" "$2"
    if [ "$rc" -ne "$2" ]; then
        bad=$((bad + 1))
    fi
}
run cases.txt 0
run malformed.txt 3
printf '\n'
if [ "$bad" -eq 0 ]; then
    printf 'ALL EXIT STATUSES AS EXPECTED\n'
    exit 0
fi
printf 'STATUS MISMATCH count=%s\n' "$bad"
exit 1
