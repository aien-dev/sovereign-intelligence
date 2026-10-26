#!/bin/sh
# omega-02-values-and-types: prefix words, explicit types, checked conversions, errors 7 and 11.
# Host-only (Linux AArch64). Env: SRC (pinned clones), OMC (pinned compiler).
set -u
here=$(cd "$(dirname "$0")" && pwd)
SRC=${SRC:?set SRC to a directory holding the clones in docs/learn/teach/PINS}
OMC=${OMC:-$SRC/omega-mv/seed/out/omc}
PIN=befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
got=$(sha256sum "$OMC" 2>/dev/null | cut -d' ' -f1)
[ "$got" = "$PIN" ] || { echo "omc sha256 mismatch (wanted $PIN)"; exit 90; }
echo "omc sha256 $PIN"
T=$(mktemp -d) || exit 2
trap 'rm -rf "$T"' EXIT HUP INT TERM
fail=0
# compile NAME WANT: compile NAME.om into $T/NAME, print status and stderr, check the status.
compile() {
    "$OMC" < "$here/$1.om" > "$T/$1" 2> "$T/$1.err"
    crc=$?
    echo "compile $1.om rc=$crc"
    cat "$T/$1.err"
    want "$1 compile" "$crc" "$2"
}
# runit NAME WANT: run a program that compiled with 0 (never a refused one), check its status.
runit() {
    if [ "$crc" -ne 0 ]; then echo "run $1 NOT_RUN (compile refused)"; fail=1; return; fi
    chmod +x "$T/$1"
    "$T/$1"
    rrc=$?
    echo "run $1 rc=$rrc"
    want "$1 run" "$rrc" "$2"
}
want() { [ "$2" = "$3" ] || { echo "UNEXPECTED $1: got $2, wanted $3"; fail=1; }; }
finish() { [ "$fail" -eq 0 ] && echo "RESULT PASS" || echo "RESULT FAIL"; exit "$fail"; }

echo "== 1. values: exit status is the computed value b = 53"
compile values 0
runit values 53
echo "== 2. trap 5: a conversion whose value does not fit (exit 100 + 5)"
compile narrow 0
runit narrow 105
echo "== 3. error 7: no implicit conversion between uint and long"
compile mixed 7
echo "== 4. error 11: a bare number with no type"
compile bare 11
echo "== 5. the fix: say every type; 8 + 5 = 13"
compile fixed 0
runit fixed 13
finish
