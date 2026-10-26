#!/bin/sh
# agents-07-failure-patterns: tally PASS/FAIL/NOT_RUN against the expected case count; shrunk, NOT_RUN and uncounted logs fail (negative controls).
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
"$OMC" < "$here/tally.om" > "$work/tally" 2> "$work/err"
rc=$?
printf 'compile tally.om rc=%s\n' "$rc"
cat "$work/err"
if [ "$rc" -ne 0 ]; then
    exit "$rc"
fi
chmod +x "$work/tally" || exit 2
bad=0
run() {
    printf '\n--- input %s\n' "$1"
    cat "$here/$1"
    printf -- '--- output\n'
    "$work/tally" < "$here/$1"
    rc=$?
    printf 'run rc=%s (expected %s)\n' "$rc" "$2"
    if [ "$rc" -ne "$2" ]; then
        bad=$((bad + 1))
    fi
}
printf '\nnaive reading first: count FAIL lines and call zero a green run\n'
for f in full.log shrunk.log notrun.log noexpect.log; do
    printf '%s: FAIL lines=%s\n' "$f" "$(grep -c '^FAIL ' "$here/$f")"
done
run full.log 0
run shrunk.log 1
run notrun.log 1
run noexpect.log 3
printf '\n'
if [ "$bad" -eq 0 ]; then
    printf 'ALL EXIT STATUSES AS EXPECTED\n'
    exit 0
fi
printf 'STATUS MISMATCH count=%s\n' "$bad"
exit 1
