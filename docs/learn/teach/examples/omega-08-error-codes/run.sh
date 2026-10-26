#!/bin/sh
# omega-08-error-codes: real refusals (12, 9, 13, 16), their fixes, and gate15 run in a disposable copy.
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

echo "== 1. error 12: the 16-register pool runs out"
compile blend 12
echo "== 2. the fix: split the work into helpers"
compile split 0
runit split 0
echo "== 2b. negative control: a wrong split (xor d f made and d f in mixes) fails the reference check"
sed "s/^ret add add add a c add b d add xor c e xor d f\$/ret add add add a c add b d add xor c e and d f/" "$here/split.om" > "$T/badsplit.om"
"$OMC" < "$T/badsplit.om" > "$T/badsplit" 2> "$T/badsplit.err"; crc=$?
echo "compile badsplit rc=$crc"; cat "$T/badsplit.err"
runit badsplit 3
echo "== 3. error 9: new inside a loop"
compile inblock 9
echo "== 4. the fix: hoist the array to the outermost block"
compile hoisted 0
runit hoisted 16
echo "== 5. error 13: a 9-character variable name"
compile longname 13
echo "== 6. error 16: an array parameter without its length"
compile nolength 16
echo "== 7. the fix: state the length"
compile withlen 0
runit withlen 20
echo "== 8. the whole table: seed/omc/gate15.sh, one minimal refusal per code, in a disposable copy"
mkdir -p "$T/g/seed/omc" "$T/g/seed/out"
cp "$SRC/omega-mv/seed/omc/gate15.sh" "$T/g/seed/omc/gate15.sh"
cp "$OMC" "$T/g/seed/out/omc"
chmod +x "$T/g/seed/out/omc"
sh "$T/g/seed/omc/gate15.sh"
grc=$?
echo "gate15 rc=$grc"
want "gate15" "$grc" 0
finish
