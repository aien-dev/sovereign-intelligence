#!/bin/sh
# omega-04-arrays-and-io: globals, local arrays, a partial-read loop, counts vs negative errno.
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
# runin NAME WANT: as runit, with stdin from the caller.
runin() {
    if [ "$crc" -ne 0 ]; then echo "run $1 NOT_RUN (compile refused)"; fail=1; return; fi
    chmod +x "$T/$1"
    "$T/$1"
    rrc=$?
    echo "run $1 rc=$rrc"
    want "$1 run" "$rrc" "$2"
}

echo "== 1. three short lines on stdin"
compile wc 0
printf 'one\ntwo\nthree\n' | runin wc 0
echo "== 2. 5000 lines of 'abc' through a pipe: many partial reads, one total"
yes abc | head -n 5000 | runin wc 0
echo "== 3. stdin closed: read returns -9 (EBADF), the program exits 9"
runin wc 9 <&-
echo "== 4. negative control: a loop that treats k <= 0 as end of input hides the error"
compile naive 0
runin naive 0 <&-
echo "== 5. trap 3: the slice is checked before the kernel call (exit 103)"
compile slice 0
runin slice 103 < /dev/null
echo "== 6. error 19: a global passed as an argument"
compile global 19
finish
