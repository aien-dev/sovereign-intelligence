#!/bin/sh
# omega-09-adding-a-word: the random host word (Linux getrandom), added to omc as one reviewed change:
# keyword id, lowering, guide row, host gate fixture. Host-only (Linux AArch64). Env: SRC, OMC.
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
M=$SRC/omega-mv

echo "== 1. the guide row in docs/one_layer/OMEGESE.md"
rows=$(grep -c '^| `random A off n flags` |' "$M/docs/one_layer/OMEGESE.md")
echo "OMEGESE.md rows for random: $rows"
want "guide row" "$rows" 1
echo "== 2. the keyword: compute its packed spelling in Omega, then find it in omc.om"
compile kwpack 0
runit kwpack 0
"$T/kwpack" > "$T/kw.txt"
v=$(cat "$T/kw.txt")
grep -n -A1 "^if eq w $v\$" "$M/seed/omc/omc.om"
echo "== 3. the lowering: fn hrand issues Linux syscall 278 (getrandom on arm64)"
awk '/^fn hrand /{p=1} p{print} p&&/^end$/{exit}' "$M/seed/omc/omc.om" | grep -n 'fn hrand\|hsys'
echo "== 4. the host gate fixture, compiled and run as the gate does"
cp "$M/seed/host/tests/random.om" "$T/random.om"
"$OMC" < "$T/random.om" > "$T/random" 2> "$T/random.err"; crc=$?
echo "compile seed/host/tests/random.om rc=$crc"; cat "$T/random.err"
want "fixture compile" "$crc" 0
runit random 0
echo "== 5. negative control: the fixture with a wrong expected count must fail"
sed '0,/^if ne r 8$/s//if ne r 9/' "$T/random.om" > "$T/mutant.om"
"$OMC" < "$T/mutant.om" > "$T/mutant" 2> "$T/mutant.err"; crc=$?
echo "compile mutant rc=$crc"
runit mutant 1
echo "== 6. the refusals the word promises"
compile intotext 20
compile badflags 7
compile asname 16
compile overrun 0
runit overrun 103
finish
